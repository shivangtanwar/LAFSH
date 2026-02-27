function results = eval_security_comparison()
% EVAL_SECURITY_COMPARISON  Security feature comparison across schemes.
%   results = eval_security_comparison()
%
%   Scoring: 0=None, 1=Partial, 2=Good, 3=Full

    fprintf('\n=== Security Feature Comparison ===\n');

    results.schemes = {'LAFSH', 'Basic-PW', 'TLS', 'Wazid2020'};
    results.features = {'Mutual Auth', 'Replay Protection', 'MITM Resistance', ...
                        'Device Fingerprint', 'Two-Factor Auth', 'Forward Secrecy', ...
                        'Computation Cost', 'Communication Cost'};

    % Scores: [LAFSH, Basic-PW, TLS, Wazid2020]
    results.scores = [
        3, 0, 2, 3;   % Mutual Auth
        3, 0, 3, 3;   % Replay Protection
        3, 1, 3, 3;   % MITM Resistance
        3, 0, 0, 1;   % Device Fingerprint
        3, 0, 0, 0;   % Two-Factor Auth
        2, 0, 3, 2;   % Forward Secrecy
        3, 3, 1, 3;   % Computation Cost (3=low cost = good)
        3, 2, 0, 2;   % Communication Cost (3=low cost = good)
    ];

    % Print table
    fprintf('\n%-22s', 'Feature');
    for s = 1:length(results.schemes)
        fprintf(' %10s', results.schemes{s});
    end
    fprintf('\n%s\n', repmat('-', 1, 65));
    for f = 1:length(results.features)
        fprintf('%-22s', results.features{f});
        for s = 1:length(results.schemes)
            score = results.scores(f, s);
            labels = {'None', 'Partial', 'Good', 'Full'};
            fprintf(' %10s', labels{score+1});
        end
        fprintf('\n');
    end

    results.totals = sum(results.scores, 1);
    fprintf('\n%-22s', 'TOTAL (out of 24)');
    for s = 1:length(results.schemes)
        fprintf(' %10d', results.totals(s));
    end
    fprintf('\n');
end
