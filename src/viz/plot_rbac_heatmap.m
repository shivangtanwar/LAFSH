function plot_rbac_heatmap(rbac)
% PLOT_RBAC_HEATMAP  Heatmap of the RBAC permission matrix.
%   plot_rbac_heatmap(rbac)  % rbac from init_rbac()

    figure('Name', 'RBAC Permission Matrix', 'Position', [100 100 800 400]);

    imagesc(rbac.permission_matrix);
    colormap([0.9 0.2 0.2; 0.2 0.8 0.2]);  % Red=denied, Green=allowed

    set(gca, 'XTick', 1:length(rbac.operations), ...
             'XTickLabel', rbac.operations, ...
             'XTickLabelRotation', 45, ...
             'YTick', 1:length(rbac.roles), ...
             'YTickLabel', rbac.roles, ...
             'FontSize', 11);

    title('RBAC Permission Matrix (Green=Allow, Red=Deny)', 'FontSize', 14);

    % Add text labels in each cell
    for r = 1:size(rbac.permission_matrix, 1)
        for c = 1:size(rbac.permission_matrix, 2)
            if rbac.permission_matrix(r, c)
                txt = 'Y';
                clr = 'w';
            else
                txt = 'N';
                clr = 'w';
            end
            text(c, r, txt, 'HorizontalAlignment', 'center', ...
                 'FontSize', 12, 'FontWeight', 'bold', 'Color', clr);
        end
    end

    saveas(gcf, fullfile('figures', 'rbac_heatmap.png'));
    fprintf('[VIZ] RBAC heatmap saved to figures/rbac_heatmap.png\n');
end
