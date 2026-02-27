function [totp_result, fog] = totp_auth(device, fog, submitted_otp, sim_time)
% TOTP_AUTH  Two-Factor Authentication via TOTP (Phase 3).
%   [totp_result, fog] = totp_auth(device, fog, otp)
%
%   Only for Admin/Resident roles. Must be called AFTER device_login.

    if nargin < 4, sim_time = get_timestamp(); end

    tic;
    DID = device.id;
    totp_result = struct();

    % Check session exists
    if ~fog.active_sessions.isKey(DID)
        totp_result.success = false;
        totp_result.reason = 'No active session - authenticate first';
        totp_result.latency_ms = toc * 1000;
        return;
    end

    session = fog.active_sessions(DID);

    % Check role requires TOTP
    if ~strcmp(session.role, 'Admin') && ~strcmp(session.role, 'Resident')
        totp_result.success = true;
        totp_result.reason = 'TOTP not required for this role';
        totp_result.latency_ms = toc * 1000;
        return;
    end

    % Get TOTP secret from registry
    record = fog.device_registry(DID);

    if isempty(record.totp_secret)
        totp_result.success = false;
        totp_result.reason = 'No TOTP secret configured';
        totp_result.latency_ms = toc * 1000;
        return;
    end

    % Verify OTP
    valid = totp_verify(record.totp_secret, submitted_otp, sim_time);

    if valid
        session.totp_verified = true;
        fog.active_sessions(DID) = session;

        fog.audit_log{end+1} = struct('timestamp', sim_time, ...
            'event', 'TOTP_SUCCESS', 'device_id', DID, ...
            'role', session.role, 'status', 'SUCCESS');

        totp_result.success = true;
        totp_result.reason = 'TOTP verified successfully';

        fprintf('[2FA] SUCCESS: %s (%s) TOTP verified\n', DID, session.role);
    else
        fog.audit_log{end+1} = struct('timestamp', sim_time, ...
            'event', 'TOTP_FAIL', 'device_id', DID, ...
            'role', session.role, 'status', 'BLOCKED');

        totp_result.success = false;
        totp_result.reason = 'Invalid TOTP code';

        fprintf('[2FA] FAILED: %s - Invalid TOTP code\n', DID);
    end

    totp_result.latency_ms = toc * 1000;
    totp_result.expected_otp = totp_generate(record.totp_secret, sim_time);
end
