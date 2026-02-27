function results = eval_energy_estimation(num_devices_range)
% EVAL_ENERGY_ESTIMATION  Estimate energy consumption for authentication.
%   results = eval_energy_estimation([50 100 200 500])
%
%   Energy model constants (from IoT literature):
%     SHA-256 on Cortex-M0: 0.3 microjoules
%     XOR (256-bit):        0.001 microjoules
%     BLE TX:               0.5 microjoules/byte
%     BLE RX:               0.3 microjoules/byte
%     RSA-2048 sign:        900,000 microjoules

    if nargin < 1, num_devices_range = [50, 100, 200, 300, 500]; end

    fprintf('\n=== Energy Consumption Estimation ===\n');

    % Energy constants (microjoules)
    E_hash = 0.3;       % SHA-256
    E_xor = 0.001;      % 256-bit XOR
    E_tx_byte = 0.5;    % BLE transmission per byte
    E_rx_byte = 0.3;    % BLE reception per byte
    E_rsa = 900000;     % RSA-2048 signing

    % LAFSH per device: 8 hashes, 2 XORs, 200 bytes TX, 200 bytes RX
    lafsh_comp = 8 * E_hash + 2 * E_xor;
    lafsh_comm = 200 * E_tx_byte + 200 * E_rx_byte;
    lafsh_total = lafsh_comp + lafsh_comm;

    % PKI per device: 2 RSA, ~3500 bytes TX
    pki_comp = 2 * E_rsa;
    pki_comm = 3500 * E_tx_byte + 3500 * E_rx_byte;
    pki_total = pki_comp + pki_comm;

    % TLS per device: 1 RSA + AES, ~5000 bytes
    tls_comp = E_rsa + 50;  % RSA + AES overhead
    tls_comm = 5000 * E_tx_byte + 5000 * E_rx_byte;
    tls_total = tls_comp + tls_comm;

    results.num_devices = num_devices_range;
    results.lafsh_per_device = lafsh_total;
    results.pki_per_device = pki_total;
    results.tls_per_device = tls_total;
    results.lafsh_total = lafsh_total * num_devices_range;
    results.pki_total = pki_total * num_devices_range;
    results.tls_total = tls_total * num_devices_range;
    results.lafsh_breakdown = [lafsh_comp, lafsh_comm];
    results.pki_breakdown = [pki_comp, pki_comm];

    fprintf('\nPer-device energy (microjoules):\n');
    fprintf('  LAFSH:    %.2f uJ (comp=%.2f, comm=%.2f)\n', lafsh_total, lafsh_comp, lafsh_comm);
    fprintf('  TLS:      %.2f uJ\n', tls_total);
    fprintf('  PKI:      %.2f uJ\n', pki_total);
    fprintf('\nLAFSH is %.0fx more energy-efficient than PKI\n', pki_total/lafsh_total);
end
