function [auth_result, device, fog] = device_login(device, fog, sim_time)
% DEVICE_LOGIN  Mutual authentication + session key establishment (Phase 2).
%   [auth_result, device, fog] = device_login(device, fog)
%   [auth_result, device, fog] = device_login(device, fog, sim_time)
%
%   Protocol:
%     D1: Device computes Auth1 = H(DID || A_device || N1 || T1)
%     D2: Device sends M1 = {DID, fingerprint, N1, T1, Auth1}
%     F1: Fog checks timestamp freshness |now - T1| < delta
%     F2: Fog checks fingerprint (device cloning detection)
%     F3: Fog recomputes Auth1' and verifies Auth1 == Auth1'
%     F4: Fog computes Auth2 = H(FID || A || N1 || N2 || T2)
%     F5: Fog computes SK = H(N1 || N2 || A || DID || FID)
%     F6: Fog sends M2 = {FID, N2, T2, Auth2, H(SK)}
%     D3: Device verifies Auth2
%     D4: Device derives SK

    tic;

    if nargin < 3, sim_time = get_timestamp(); end

    DID = device.id;
    auth_result = struct();

    % --- Precondition: device must be registered ---
    if ~device.registered
        auth_result.success = false;
        auth_result.failure_reason = 'Device not registered';
        auth_result.latency_ms = toc * 1000;
        return;
    end

    % === DEVICE SIDE (Step D1-D2) ===
    A_device = device.credentials.A_device;
    N1 = generate_nonce(128);
    T1 = num2str(sim_time);

    Auth1 = sha256_hash([DID '||' A_device '||' N1 '||' T1]);

    % M1 message
    M1.DID = DID;
    M1.fingerprint = device.fingerprint;
    M1.N1 = N1;
    M1.T1 = T1;
    M1.Auth1 = Auth1;

    m1_bytes = length(DID) + 32 + 16 + 4 + 32;  % ~100 bytes

    % === FOG SIDE (Step F1-F6) ===

    % F1: Timestamp freshness check
    current_time = sim_time;  % In real system, fog's own clock
    time_diff = abs(current_time - str2double(M1.T1));
    if time_diff > fog.clock_delta
        auth_result.success = false;
        auth_result.failure_reason = sprintf('Timestamp expired (diff=%ds, delta=%ds)', ...
                                             time_diff, fog.clock_delta);
        auth_result.latency_ms = toc * 1000;
        auth_result.bytes_exchanged = m1_bytes;
        fog.audit_log{end+1} = struct('timestamp', current_time, ...
            'event', 'AUTH_FAIL', 'device_id', DID, ...
            'reason', 'TIMESTAMP_EXPIRED', 'status', 'BLOCKED');
        fprintf('[AUTH] FAILED: %s - Timestamp expired\n', DID);
        return;
    end

    % F2: Device lookup
    if ~fog.device_registry.isKey(DID)
        auth_result.success = false;
        auth_result.failure_reason = 'Device not found in registry';
        auth_result.latency_ms = toc * 1000;
        auth_result.bytes_exchanged = m1_bytes;
        fprintf('[AUTH] FAILED: %s - Not in registry\n', DID);
        return;
    end

    record = fog.device_registry(DID);

    % F2b: Fingerprint verification (device cloning detection)
    if ~strcmp(M1.fingerprint, record.fingerprint)
        auth_result.success = false;
        auth_result.failure_reason = 'DEVICE CLONING DETECTED - fingerprint mismatch';
        auth_result.latency_ms = toc * 1000;
        auth_result.bytes_exchanged = m1_bytes;
        fog.audit_log{end+1} = struct('timestamp', current_time, ...
            'event', 'SECURITY_ALERT', 'device_id', DID, ...
            'reason', 'DEVICE_CLONING', 'status', 'BLOCKED');
        fprintf('[AUTH] ALERT: %s - Device cloning detected!\n', DID);
        return;
    end

    % F3: Verify Auth1
    A = record.anchor_key;
    Auth1_expected = sha256_hash([DID '||' A '||' M1.N1 '||' M1.T1]);

    if ~strcmp(M1.Auth1, Auth1_expected)
        auth_result.success = false;
        auth_result.failure_reason = 'Auth1 verification failed - invalid credentials';
        auth_result.latency_ms = toc * 1000;
        auth_result.bytes_exchanged = m1_bytes;

        % Track failed attempts
        if fog.failed_attempts.isKey(DID)
            fog.failed_attempts(DID) = fog.failed_attempts(DID) + 1;
        else
            fog.failed_attempts(DID) = int32(1);
        end

        fog.audit_log{end+1} = struct('timestamp', current_time, ...
            'event', 'AUTH_FAIL', 'device_id', DID, ...
            'reason', 'INVALID_CREDENTIALS', 'status', 'BLOCKED');
        fprintf('[AUTH] FAILED: %s - Invalid credentials\n', DID);
        return;
    end

    % --- Device authenticated to Fog! ---

    % F4: Fog computes Auth2 (for mutual authentication)
    N2 = generate_nonce(128);
    T2 = num2str(sim_time + 1);  % Slight offset for response

    Auth2 = sha256_hash([fog.id '||' A '||' M1.N1 '||' N2 '||' T2]);

    % F5: Session key
    SK = sha256_hash([M1.N1 '||' N2 '||' A '||' DID '||' fog.id]);

    % F6: Build M2
    M2.FID = fog.id;
    M2.N2 = N2;
    M2.T2 = T2;
    M2.Auth2 = Auth2;
    M2.SK_hash = sha256_hash(SK);

    m2_bytes = length(fog.id) + 16 + 4 + 32 + 32;  % ~100 bytes

    % === DEVICE SIDE (Step D3-D4) ===

    % D3: Verify Auth2
    Auth2_expected = sha256_hash([M2.FID '||' A_device '||' N1 '||' M2.N2 '||' M2.T2]);

    if ~strcmp(M2.Auth2, Auth2_expected)
        auth_result.success = false;
        auth_result.failure_reason = 'Auth2 verification failed - fog node impersonation';
        auth_result.latency_ms = toc * 1000;
        auth_result.bytes_exchanged = m1_bytes + m2_bytes;
        fprintf('[AUTH] FAILED: %s - Fog impersonation detected\n', DID);
        return;
    end

    % --- Fog authenticated to Device! (Mutual auth complete) ---

    % D4: Device derives session key
    SK_device = sha256_hash([N1 '||' M2.N2 '||' A_device '||' DID '||' M2.FID]);

    % Verify SK matches
    if ~strcmp(sha256_hash(SK_device), M2.SK_hash)
        auth_result.success = false;
        auth_result.failure_reason = 'Session key mismatch';
        auth_result.latency_ms = toc * 1000;
        auth_result.bytes_exchanged = m1_bytes + m2_bytes;
        return;
    end

    % === SUCCESS: Store session ===
    session.session_key = SK;
    session.created_at = current_time;
    session.expires_at = current_time + fog.session_timeout;
    session.role = record.role;
    session.device_type = record.device_type;
    session.totp_verified = false;  % Needs Phase 3 for user roles

    fog.active_sessions(DID) = session;
    device.authenticated = true;
    device.session_key = SK_device;

    % Reset failed attempts
    if fog.failed_attempts.isKey(DID)
        fog.failed_attempts(DID) = int32(0);
    end

    fog.audit_log{end+1} = struct('timestamp', current_time, ...
        'event', 'AUTH_SUCCESS', 'device_id', DID, ...
        'role', record.role, 'status', 'SUCCESS');

    latency = toc * 1000;

    % Result
    auth_result.success = true;
    auth_result.session_key = SK_device;
    auth_result.failure_reason = '';
    auth_result.latency_ms = latency;
    auth_result.bytes_exchanged = m1_bytes + m2_bytes;
    auth_result.hash_operations = 8;  % Auth1 + lookup + Auth1' + Auth2 + SK + Auth2' + SK' + SK_hash
    auth_result.needs_totp = strcmp(record.role, 'Admin') || strcmp(record.role, 'Resident');

    fprintf('[AUTH] SUCCESS: %s (%s) mutually authenticated (%.2f ms, %d bytes)\n', ...
            DID, record.role, latency, m1_bytes + m2_bytes);
end
