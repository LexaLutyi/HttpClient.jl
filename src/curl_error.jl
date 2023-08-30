curl_code_to_string(code) = unsafe_string(curl_easy_strerror(code))


macro curlok(exp)
    quote
        local rc = $(esc(exp))
        if rc != CURLE_OK
            curl_error = curl_code_to_string(rc)
            error(curl_error)
        end
        rc
    end
end