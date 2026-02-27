function [permitted, reason, fog] = check_permission(device_id, operation, fog, sim_time)
% CHECK_PERMISSION  RBAC policy enforcement at the fog layer.
%   [permitted, reason, fog] = check_permission('LOCK_001', 'unlock', fog)
%
%   Checks:
%     1. Valid session exists and not expired
%     2. TOTP verified (for Admin/Resident roles)
%     3. Role has permission for the operation
%     4. Time-window restriction for Guests
%     5. Logs the access decision

    if nargin < 4, sim_time = get_timestamp(); end

    rbac = fog.rbac;

    % 1. Session check
    if ~fog.active_sessions.isKey(device_id)
        permitted = false;
        reason = 'No active session';
        fog = log_access(fog, device_id, 'Unknown', operation, permitted, reason, sim_time);
        return;
    end

    session = fog.active_sessions(device_id);

    if sim_time > session.expires_at
        permitted = false;
        reason = 'Session expired';
        fog.active_sessions.remove(device_id);
        fog = log_access(fog, device_id, session.role, operation, permitted, reason, sim_time);
        return;
    end

    % 2. TOTP check for user roles
    if (strcmp(session.role, 'Admin') || strcmp(session.role, 'Resident')) ...
            && ~session.totp_verified
        permitted = false;
        reason = '2FA not completed - TOTP verification required';
        fog = log_access(fog, device_id, session.role, operation, permitted, reason, sim_time);
        return;
    end

    % 3. RBAC matrix check
    if ~rbac.role_index.isKey(session.role)
        permitted = false;
        reason = sprintf('Unknown role: %s', session.role);
        fog = log_access(fog, device_id, session.role, operation, permitted, reason, sim_time);
        return;
    end

    if ~rbac.op_index.isKey(operation)
        permitted = false;
        reason = sprintf('Unknown operation: %s', operation);
        fog = log_access(fog, device_id, session.role, operation, permitted, reason, sim_time);
        return;
    end

    role_idx = rbac.role_index(session.role);
    op_idx = rbac.op_index(operation);

    if rbac.permission_matrix(role_idx, op_idx) == 0
        permitted = false;
        reason = sprintf('Role "%s" denied operation "%s"', session.role, operation);
        fog = log_access(fog, device_id, session.role, operation, permitted, reason, sim_time);
        return;
    end

    % 4. Guest time-window restriction
    if strcmp(session.role, 'Guest')
        current_hour = mod(floor(sim_time / 3600), 24);
        if current_hour < rbac.guest_window.start_hour || ...
           current_hour >= rbac.guest_window.end_hour
            permitted = false;
            reason = sprintf('Guest access denied outside hours %d:00-%d:00', ...
                            rbac.guest_window.start_hour, rbac.guest_window.end_hour);
            fog = log_access(fog, device_id, session.role, operation, permitted, reason, sim_time);
            return;
        end
    end

    % 5. PERMITTED
    permitted = true;
    reason = sprintf('ALLOWED: %s -> %s', session.role, operation);
    fog = log_access(fog, device_id, session.role, operation, permitted, reason, sim_time);
end

function fog = log_access(fog, device_id, role, operation, permitted, reason, timestamp)
    if permitted
        status = 'PERMIT';
    else
        status = 'DENY';
    end
    fog.audit_log{end+1} = struct('timestamp', timestamp, ...
        'event', 'ACCESS_CHECK', 'device_id', device_id, ...
        'role', role, 'operation', operation, ...
        'status', status, 'reason', reason);
    fprintf('[RBAC] %s: %s (%s) -> %s | %s\n', status, device_id, role, operation, reason);
end
