function devices = deploy_nodes(num_nodes, area_size)
% DEPLOY_NODES  Deploy heterogeneous IoT nodes in a smart home/neighborhood.
%   devices = deploy_nodes(500)        % 500 nodes in 200x200m area
%   devices = deploy_nodes(500, 300)   % 500 nodes in 300x300m area
%
%   Deploys a heterogeneous mix of smart home IoT devices:
%     - Smart Lights    (~30%)  : Low energy, low capability
%     - Thermostats     (~20%)  : Medium energy, sensor+actuator
%     - IP Cameras      (~15%)  : High energy, high bandwidth
%     - Smart Locks     (~15%)  : Medium energy, critical security
%     - Motion Sensors  (~10%)  : Low energy, event-driven
%     - Smart Plugs     (~10%)  : Low energy, basic actuator
%
%   Each node gets: position, type, energy, capability, MAC, firmware,
%   fingerprint, role, and communication range.
%
%   Returns: struct array of device nodes.

    if nargin < 2, area_size = 200; end

    % --- Device type distribution ---
    types = {'light', 'thermostat', 'camera', 'lock', 'motion_sensor', 'smart_plug'};
    ratios = [0.30, 0.20, 0.15, 0.15, 0.10, 0.10];

    % Energy levels (Joules) per device type [initial_min, initial_max]
    energy_ranges = [0.3 0.5;   % light: low
                     0.5 1.0;   % thermostat: medium
                     1.0 2.0;   % camera: high
                     0.5 1.0;   % lock: medium
                     0.2 0.4;   % motion_sensor: very low
                     0.3 0.5];  % smart_plug: low

    % Communication range (meters) per type
    comm_ranges = [15, 25, 30, 20, 10, 15];

    % Data rate (bytes/sec) per type
    data_rates = [10, 50, 500, 20, 5, 10];

    % Capability bitmask per type
    %   bit0=on/off, bit1=read_sensor, bit2=write_actuator,
    %   bit3=stream, bit4=critical_security
    cap_masks = [0b00001,   % light: on/off
                 0b00111,   % thermostat: on/off + read + write
                 0b01011,   % camera: on/off + read + stream
                 0b10101,   % lock: on/off + write + critical
                 0b00010,   % motion_sensor: read only
                 0b00001];  % smart_plug: on/off

    % Firmware versions per type
    fw_versions = {'1.2.0', '2.1.3', '3.0.1', '2.5.0', '1.0.4', '1.1.2'};

    % --- Assign types to nodes ---
    counts = round(ratios * num_nodes);
    % Fix rounding to match exact total
    counts(end) = num_nodes - sum(counts(1:end-1));

    type_indices = [];
    for t = 1:length(types)
        type_indices = [type_indices, repmat(t, 1, counts(t))]; %#ok<AGROW>
    end
    % Shuffle
    type_indices = type_indices(randperm(length(type_indices)));

    % --- Build device struct array ---
    devices = struct();
    for i = 1:num_nodes
        ti = type_indices(i);

        devices(i).id = sprintf('%s_%04d', upper(types{ti}), i);
        devices(i).type = types{ti};
        devices(i).type_index = ti;

        % Random position in 2D area
        devices(i).x = rand() * area_size;
        devices(i).y = rand() * area_size;

        % Energy (heterogeneous within type)
        e_min = energy_ranges(ti, 1);
        e_max = energy_ranges(ti, 2);
        devices(i).initial_energy = e_min + rand() * (e_max - e_min);
        devices(i).residual_energy = devices(i).initial_energy;

        % Communication range
        devices(i).comm_range = comm_ranges(ti) + (rand()-0.5)*5;  % +/- 2.5m variation

        % Data rate
        devices(i).data_rate = data_rates(ti);

        % Capability
        devices(i).capability_mask = cap_masks(ti);

        % Simulated MAC address
        mac_bytes = randi([0 255], 1, 6);
        devices(i).mac_address = strjoin(arrayfun(@(b) dec2hex(b,2), mac_bytes, 'UniformOutput', false), ':');

        % Firmware
        devices(i).firmware_version = fw_versions{ti};

        % Registration timestamp
        devices(i).reg_timestamp = get_timestamp() + i;

        % Device fingerprint = H(type || MAC || firmware || cap_mask || reg_ts)
        fp_input = [devices(i).type '||' devices(i).mac_address '||' ...
                    devices(i).firmware_version '||' ...
                    num2str(devices(i).capability_mask) '||' ...
                    num2str(devices(i).reg_timestamp)];
        devices(i).fingerprint = sha256_hash(fp_input);

        % Default role (all IoT devices get 'Device' role)
        devices(i).role = 'Device';

        % Auth state
        devices(i).registered = false;
        devices(i).authenticated = false;
        devices(i).session_key = '';
        devices(i).password = generate_nonce(64);  % 8-byte random password
        devices(i).totp_secret = '';
        devices(i).credentials = struct();

        % Cluster state (populated by clustering algorithm)
        devices(i).cluster_id = -1;
        devices(i).is_cluster_head = false;
    end

    fprintf('[DEPLOY] %d heterogeneous nodes deployed in %dx%d area\n', num_nodes, area_size, area_size);
    fprintf('         Distribution: ');
    for t = 1:length(types)
        fprintf('%s=%d ', types{t}, counts(t));
    end
    fprintf('\n');
end
