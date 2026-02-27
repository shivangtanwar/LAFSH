function fog = logout_device(device_id, fog)
% LOGOUT_DEVICE  Invalidate a device session.
%   fog = logout_device('LOCK_001', fog)

    if fog.active_sessions.isKey(device_id)
        fog.active_sessions.remove(device_id);
        fog.audit_log{end+1} = struct('timestamp', get_timestamp(), ...
            'event', 'LOGOUT', 'device_id', device_id, ...
            'reason', 'USER_INITIATED', 'status', 'SUCCESS');
        fprintf('[SESSION] Device %s logged out\n', device_id);
    else
        fprintf('[SESSION] Device %s has no active session\n', device_id);
    end
end
