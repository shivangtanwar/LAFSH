function [energy_cost, success] = communicate(sender, receiver, data_bytes, distance)
% COMMUNICATE  Model energy cost of communication between two nodes.
%   [energy_cost, success] = communicate(sender, receiver, data_bytes)
%
%   Uses the first-order radio energy model (Heinzelman et al.):
%     E_tx = E_elec * k + E_amp * k * d^2   (free space, d < d0)
%     E_tx = E_elec * k + E_amp * k * d^4   (multipath, d >= d0)
%     E_rx = E_elec * k
%
%   Where:
%     E_elec = 50 nJ/bit   (electronic circuitry)
%     E_fs   = 10 pJ/bit/m^2  (free space amplifier)
%     E_mp   = 0.0013 pJ/bit/m^4  (multipath amplifier)
%     d0     = sqrt(E_fs / E_mp)  (~87m threshold)
%     k      = data_bytes * 8  (bits)
%
%   Returns:
%     energy_cost - [tx_cost, rx_cost] in Joules
%     success     - boolean (false if sender lacks energy or out of range)

    if nargin < 4
        distance = sqrt((sender.x - receiver.x)^2 + (sender.y - receiver.y)^2);
    end

    % Radio energy model parameters
    E_elec = 50e-9;       % 50 nJ/bit
    E_fs   = 10e-12;      % 10 pJ/bit/m^2 (free space)
    E_mp   = 0.0013e-12;  % 0.0013 pJ/bit/m^4 (multipath)
    d0     = sqrt(E_fs / E_mp);  % ~87.7m crossover distance

    k = data_bytes * 8;  % bits

    % Transmission energy
    if distance < d0
        E_tx = E_elec * k + E_fs * k * distance^2;
    else
        E_tx = E_elec * k + E_mp * k * distance^4;
    end

    % Reception energy
    E_rx = E_elec * k;

    % Check feasibility
    if sender.residual_energy < E_tx || receiver.residual_energy < E_rx
        energy_cost = [E_tx, E_rx];
        success = false;
        return;
    end

    % Check range (use sender's comm_range)
    if distance > sender.comm_range * 3  % Allow multi-hop relay factor
        energy_cost = [E_tx, E_rx];
        success = false;
        return;
    end

    energy_cost = [E_tx, E_rx];
    success = true;
end
