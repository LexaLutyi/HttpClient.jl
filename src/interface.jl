function set_interface(curl, interface)
    @curlok curl_easy_setopt(curl, CURLOPT_INTERFACE, interface)
end