function fog = init_fog_node(fog_id, cloud, rbac, x, y)
% INIT_FOG_NODE  Initialize a Fog Node (smart home gateway).
%   fog = init_fog_node('FOG_01', cloud, rbac, 100, 100)
%
%   The fog node is the trust anchor: authenticates devices, enforces RBAC,
%   manages sessions, and verifies TOTP.

    if nargin < 4, x = 100; y = 100; end

    % Derive delegated secret from cloud master secret
    fog_secret = sha256_hash([cloud.master_secret '||' fog_id]);

    fog.id = fog_id;
    fog.secret = fog_secret;
    fog.x = x;
    fog.y = y;

    % Device registry: DID -> {A, C, role, fingerprint, totp_secret, ...}
    fog.device_registry = containers.Map('KeyType', 'char', 'ValueType', 'any');

    % Active sessions: DID -> {session_key, expiry, role, ...}
    fog.active_sessions = containers.Map('KeyType', 'char', 'ValueType', 'any');

    % RBAC policy
    fog.rbac = rbac;

    % Audit log
    fog.audit_log = {};

    % Timing parameters
    fog.clock_delta = 120;          % Max timestamp skew (seconds)
    fog.session_timeout = 3600;     % Session expiry (seconds)

    % Security counters
    fog.failed_attempts = containers.Map('KeyType', 'char', 'ValueType', 'int32');

    % Energy (fog node has mains power, effectively infinite)
    fog.residual_energy = Inf;
    fog.comm_range = Inf;

    fprintf('[FOG] Fog node initialized (ID: %s) at position (%.0f, %.0f)\n', ...
            fog.id, fog.x, fog.y);
end
