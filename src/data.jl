function set_data(curl, data)
    @curlok curl_easy_setopt(curl, CURLOPT_POSTFIELDS, data)
end