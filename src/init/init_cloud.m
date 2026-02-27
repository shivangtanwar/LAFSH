function cloud = init_cloud(master_secret)
% INIT_CLOUD  Initialize the Cloud Server.
%   cloud = init_cloud()               % auto-generate secret
%   cloud = init_cloud('my_secret')    % custom secret

    if nargin < 1
        master_secret = generate_nonce(256);
    end

    cloud.id = 'CLOUD_01';
    cloud.master_secret = master_secret;
    cloud.fog_registry = containers.Map('KeyType', 'char', 'ValueType', 'any');
    cloud.audit_log = {};
    cloud.global_policy.max_session_duration = 3600;  % 1 hour
    cloud.global_policy.max_failed_attempts = 5;
    cloud.global_policy.totp_enabled = true;

    fprintf('[CLOUD] Cloud server initialized (ID: %s)\n', cloud.id);
end
