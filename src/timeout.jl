function set_timeout(curl, timeout::Integer)
    @curlok curl_easy_setopt(curl, CURLOPT_TIMEOUT, timeout)
end


function set_timeout(curl, timeout::AbstractFloat)
    ms = round(Int, 1000 * timeout)
    @curlok curl_easy_setopt(curl, CURLOPT_TIMEOUT_MS, ms)
end