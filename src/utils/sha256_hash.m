function hash_hex = sha256_hash(input_str)
% SHA256_HASH  Compute SHA-256 hash using Java's MessageDigest.
%   hash_hex = sha256_hash('hello')
%   Returns a 64-character lowercase hex string.
%   Works in MATLAB Online (Java runtime always available).

    import java.security.MessageDigest
    import java.math.BigInteger

    md = MessageDigest.getInstance('SHA-256');
    hash_bytes = md.digest(uint8(input_str));
    bi = BigInteger(1, hash_bytes);
    hash_hex = char(bi.toString(16));
    % Pad leading zeros if dropped
    hash_hex = [repmat('0', 1, 64 - length(hash_hex)), hash_hex];
end
