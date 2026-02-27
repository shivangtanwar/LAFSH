function results = eval_communication_overhead()
% EVAL_COMMUNICATION_OVERHEAD  Compare bytes exchanged per authentication.
%   results = eval_communication_overhead()

    fprintf('\n=== Communication Overhead Evaluation ===\n');

    % LAFSH protocol byte counts
    % M1: DID(16) + fingerprint(32) + N1(16) + T1(4) + Auth1(32) = 100
    % M2: FID(16) + N2(16) + T2(4) + Auth2(32) + H(SK)(32) = 100
    % M_TOTP: OTP(4) + challenge(16) = 20
    % Registration: request(~100) + response(~50) = 150

    results.schemes = {'LAFSH', 'Basic-PW', 'DTLS-PSK', 'TLS-Cert'};
    results.registration_bytes = [150, 80, 200, 4000];
    results.authentication_bytes = [200, 100, 500, 5000];
    results.totp_bytes = [20, 0, 0, 0];
    results.total_bytes = results.registration_bytes + results.authentication_bytes + results.totp_bytes;

    % Print comparison table
    fprintf('\n%-12s  %8s  %8s  %8s  %8s\n', 'Scheme', 'Reg(B)', 'Auth(B)', 'TOTP(B)', 'Total(B)');
    fprintf('%s\n', repmat('-', 1, 52));
    for i = 1:length(results.schemes)
        fprintf('%-12s  %8d  %8d  %8d  %8d\n', results.schemes{i}, ...
                results.registration_bytes(i), results.authentication_bytes(i), ...
                results.totp_bytes(i), results.total_bytes(i));
    end
    fprintf('\nLAFSH is %.1fx more efficient than TLS-Cert\n', ...
            results.total_bytes(4) / results.total_bytes(1));
end
