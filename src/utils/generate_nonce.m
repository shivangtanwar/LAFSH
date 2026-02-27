function nonce = generate_nonce(len_bits)
% GENERATE_NONCE  Generate a random hex nonce.
%   nonce = generate_nonce()       % 128-bit default
%   nonce = generate_nonce(256)    % 256-bit

    if nargin < 1, len_bits = 128; end
    num_bytes = len_bits / 8;
    rand_bytes = randi([0 255], 1, num_bytes);
    nonce = lower(reshape(dec2hex(rand_bytes, 2)', 1, []));
end
