function set_body(curl, body)
    @curlok curl_easy_setopt(curl, CURLOPT_POSTFIELDS, body)
end