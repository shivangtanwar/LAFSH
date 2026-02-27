function results = eval_auth_latency(num_devices_range, num_trials)
% EVAL_AUTH_LATENCY  Measure authentication latency vs number of devices.
%   results = eval_auth_latency([50 100 200 500], 5)

    if nargin < 1, num_devices_range = [50, 100, 200, 300, 500]; end
    if nargin < 2, num_trials = 5; end

    results.num_devices = num_devices_range;
    results.avg_reg_ms = zeros(size(num_devices_range));
    results.avg_auth_ms = zeros(size(num_devices_range));
    results.std_reg_ms = zeros(size(num_devices_range));
    results.std_auth_ms = zeros(size(num_devices_range));

    fprintf('\n=== Authentication Latency Evaluation ===\n');

    for ni = 1:length(num_devices_range)
        N = num_devices_range(ni);
        reg_times = zeros(num_trials, 1);
        auth_times = zeros(num_trials, 1);

        for trial = 1:num_trials
            % Fresh setup per trial
            cloud = init_cloud();
            rbac = init_rbac();
            fog = init_fog_node('FOG_EVAL', cloud, rbac);

            devices = deploy_nodes(N, 200);

            % Measure registration latency
            tic;
            for d = 1:N
                [devices(d), fog, ~] = device_register(devices(d), fog);
            end
            reg_times(trial) = toc * 1000 / N;  % Per-device avg

            % Measure authentication latency
            tic;
            for d = 1:N
                [~, devices(d), fog] = device_login(devices(d), fog);
            end
            auth_times(trial) = toc * 1000 / N;  % Per-device avg

            fprintf('  N=%d, trial=%d: reg=%.3f ms/dev, auth=%.3f ms/dev\n', ...
                    N, trial, reg_times(trial), auth_times(trial));
        end

        results.avg_reg_ms(ni) = mean(reg_times);
        results.avg_auth_ms(ni) = mean(auth_times);
        results.std_reg_ms(ni) = std(reg_times);
        results.std_auth_ms(ni) = std(auth_times);
    end

    fprintf('=== Evaluation complete ===\n\n');
end
