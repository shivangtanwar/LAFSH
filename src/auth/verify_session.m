function valid = verify_session(device_id, fog, current_time)
% VERIFY_SESSION  Check if a device has a valid, non-expired session.
%   valid = verify_session('LOCK_001', fog)

    if nargin < 3, current_time = get_timestamp(); end

    valid = false;

    if ~fog.active_sessions.isKey(device_id)
        return;
    end

    session = fog.active_sessions(device_id);

    if current_time > session.expires_at
        % Session expired, clean up
        fog.active_sessions.remove(device_id);
        return;
    end

    valid = true;
end
