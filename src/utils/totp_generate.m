function otp = totp_generate(secret_hex, unix_time)
% TOTP_GENERATE  Generate a 6-digit TOTP code (RFC 6238 simplified).
%   otp = totp_generate(secret_hex, unix_time)
%
%   secret_hex - 32-char hex string (128-bit shared secret)
%   unix_time  - Unix timestamp (uses 30-second time steps)

    if nargin < 2, unix_time = get_timestamp(); end
    time_step = floor(unix_time / 30);
    % Simulated HMAC: H(secret || time_step_str)
    hmac_input = [secret_hex '||' num2str(time_step)];
    hash_hex = sha256_hash(hmac_input);
    % Truncate: take last 8 hex chars -> 32-bit integer -> mod 10^6
    trunc_hex = hash_hex(end-7:end);
    trunc_int = hex2dec(trunc_hex);
    otp = mod(trunc_int, 1000000);
end
