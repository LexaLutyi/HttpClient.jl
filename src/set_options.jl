function set_follow_location(easy_handle)
    @curlok curl_easy_setopt(easy_handle, CURLOPT_FOLLOWLOCATION, 1)
end