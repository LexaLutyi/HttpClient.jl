function set_interface(curl, interface)
    if interface == ""
        interface = Ptr{UInt8}(0)
    end
    @curlok curl_easy_setopt(curl, CURLOPT_INTERFACE, interface)
end