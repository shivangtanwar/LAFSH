function valid = totp_verify(secret_hex, submitted_otp, unix_time)
% TOTP_VERIFY  Verify a submitted OTP with 90-second grace window.
%   valid = totp_verify(secret_hex, submitted_otp, unix_time)
%   Accepts time steps T-1, T, and T+1.

    if nargin < 3, unix_time = get_timestamp(); end
    time_step = floor(unix_time / 30);

    valid = false;
    for offset = -1:1
        expected = totp_generate(secret_hex, (time_step + offset) * 30);
        if submitted_otp == expected
            valid = true;
            return;
        end
    end
end
