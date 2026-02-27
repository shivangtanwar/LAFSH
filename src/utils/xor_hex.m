function result = xor_hex(a, b)
% XOR_HEX  Bitwise XOR of two equal-length hex strings.
%   result = xor_hex(hex_a, hex_b)
%   Both inputs must be the same length (typically 64 chars for SHA-256).

    bytes_a = hex2dec(reshape(a, 2, [])');
    bytes_b = hex2dec(reshape(b, 2, [])');
    xored = bitxor(bytes_a, bytes_b);
    result = lower(reshape(dec2hex(xored, 2)', 1, []));
end
