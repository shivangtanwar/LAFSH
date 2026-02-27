function ts = get_timestamp()
% GET_TIMESTAMP  Return current Unix timestamp as integer (seconds).

    ts = round(posixtime(datetime('now', 'TimeZone', 'UTC')));
end
