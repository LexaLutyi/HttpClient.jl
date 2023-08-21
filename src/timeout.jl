function set_timeout(curl, timeout)
    @curlok curl_easy_setopt(curl, CURLOPT_TIMEOUT, timeout)
end