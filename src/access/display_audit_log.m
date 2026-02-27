function display_audit_log(fog, filter_device)
% DISPLAY_AUDIT_LOG  Pretty-print the fog node's audit log.
%   display_audit_log(fog)                % show all entries
%   display_audit_log(fog, 'LOCK_001')    % filter by device

    if nargin < 2, filter_device = ''; end

    log = fog.audit_log;
    if isempty(log)
        fprintf('Audit log is empty.\n');
        return;
    end

    fprintf('\n==================== AUDIT LOG ====================\n');
    fprintf('%-12s %-16s %-14s %-12s %-8s %s\n', ...
            'TIMESTAMP', 'EVENT', 'DEVICE', 'ROLE/OP', 'STATUS', 'DETAIL');
    fprintf('%s\n', repmat('-', 1, 80));

    for i = 1:length(log)
        entry = log{i};
        if ~isempty(filter_device) && ~strcmp(entry.device_id, filter_device)
            continue;
        end

        ts_str = num2str(entry.timestamp);
        role_op = '';
        if isfield(entry, 'role'), role_op = entry.role; end
        if isfield(entry, 'operation'), role_op = entry.operation; end

        detail = '';
        if isfield(entry, 'reason'), detail = entry.reason; end

        fprintf('%-12s %-16s %-14s %-12s %-8s %s\n', ...
                ts_str, entry.event, entry.device_id, role_op, entry.status, detail);
    end
    fprintf('===================================================\n');
    fprintf('Total entries: %d\n\n', length(log));
end
