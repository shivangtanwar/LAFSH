function [device, fog, reg_stats] = device_register(device, fog)
% DEVICE_REGISTER  Execute the device registration protocol (Phase 1).
%   [device, fog, reg_stats] = device_register(device, fog)
%
%   Protocol:
%     1. Device computes RPW = H(DID || PW || r)
%     2. Device sends {DID, H(PW), r, fingerprint, role} to Fog
%     3. Fog computes anchor key A = H(DID || fog.secret)
%     4. Fog computes credential C = H(DID || A || fingerprint)
%     5. Fog stores {A, C, role, fingerprint, totp_secret} in registry
%     6. Fog returns {C, FID} to device
%     7. Device stores credentials
%
%   For user-role devices (Admin/Resident), a TOTP secret is also generated.

    tic;

    DID = device.id;
    PW = device.password;

    % --- Device side ---
    r = generate_nonce(128);  % 16-byte registration nonce
    RPW = sha256_hash([DID '||' PW '||' r]);

    % Device fingerprint (already computed in deploy_nodes)
    fp = device.fingerprint;

    % Registration request (bytes counted for overhead)
    reg_request_bytes = length(DID) + 32 + 16 + 32 + length(device.role);  % DID + H(PW) + r + fp + role

    % --- Fog side ---
    % Check if device already registered
    if fog.device_registry.isKey(DID)
        reg_stats.success = false;
        reg_stats.reason = 'Device already registered';
        reg_stats.latency_ms = toc * 1000;
        return;
    end

    % Compute anchor key
    A = sha256_hash([DID '||' fog.secret]);

    % Compute credential certificate
    C = sha256_hash([DID '||' A '||' fp]);

    % Generate TOTP secret for user-role devices
    totp_secret = '';
    if strcmp(device.role, 'Admin') || strcmp(device.role, 'Resident')
        totp_secret = generate_nonce(128);  % 128-bit TOTP secret
    end

    % Store in fog registry
    record.anchor_key = A;
    record.credential = C;
    record.role = device.role;
    record.fingerprint = fp;
    record.totp_secret = totp_secret;
    record.registered_at = get_timestamp();
    record.device_type = device.type;

    fog.device_registry(DID) = record;

    % Registration response
    reg_response_bytes = 32 + length(fog.id);  % C + FID

    % --- Device stores credentials ---
    device.credentials.RPW = RPW;
    device.credentials.C = C;
    device.credentials.FID = fog.id;
    device.credentials.r = r;
    device.credentials.A_device = A;  % Device also knows A for mutual auth
    device.totp_secret = totp_secret;
    device.registered = true;

    % Log
    fog.audit_log{end+1} = struct('timestamp', get_timestamp(), ...
        'event', 'REGISTRATION', 'device_id', DID, ...
        'role', device.role, 'status', 'SUCCESS');

    latency = toc * 1000;

    % Stats
    reg_stats.success = true;
    reg_stats.reason = 'Registration successful';
    reg_stats.latency_ms = latency;
    reg_stats.bytes_exchanged = reg_request_bytes + reg_response_bytes;
    reg_stats.hash_operations = 3;  % RPW + A + C
    reg_stats.totp_enabled = ~isempty(totp_secret);

    fprintf('[REG] Device %s (%s, role=%s) registered successfully (%.2f ms)\n', ...
            DID, device.type, device.role, latency);
end
