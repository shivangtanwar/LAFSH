function rbac = init_rbac()
% INIT_RBAC  Build the RBAC permission matrix and policy.
%   rbac = init_rbac()
%
%   Roles: Admin(1), Resident(2), Guest(3), Device(4)
%   Operations: lock, unlock, cam_live, cam_rec, thermo_set, thermo_read,
%               lights, add_device, view_logs, firmware, sensor_report

    rbac.roles = {'Admin', 'Resident', 'Guest', 'Device'};
    rbac.operations = {'lock', 'unlock', 'cam_live', 'cam_rec', ...
                       'thermo_set', 'thermo_read', 'lights', ...
                       'add_device', 'view_logs', 'firmware', 'sensor_report'};

    % Permission matrix: rows=roles, cols=operations (1=allow, 0=deny)
    rbac.permission_matrix = [
    %  lock unlk c_lv c_rc t_st t_rd lght addD vlog firm snsr
        1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1;  % Admin
        1,   1,   1,   0,   1,   1,   1,   0,   1,   0,   1;  % Resident
        0,   0,   1,   0,   0,   1,   1,   0,   0,   0,   1;  % Guest
        0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   1;  % Device
    ];

    % Role -> row index map
    rbac.role_index = containers.Map(rbac.roles, num2cell(1:4));

    % Operation -> col index map
    rbac.op_index = containers.Map(rbac.operations, num2cell(1:11));

    % Guest time restrictions (hours in 24h format)
    rbac.guest_window.start_hour = 9;   % 09:00
    rbac.guest_window.end_hour = 22;    % 22:00

    fprintf('[RBAC] Access control initialized: %d roles x %d operations\n', ...
            length(rbac.roles), length(rbac.operations));
end
