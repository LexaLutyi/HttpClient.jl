macro curlok(exp)
    quote
        local rc = $(esc(exp))
        if rc != CURLE_OK
            curl_error = unsafe_string(curl_easy_strerror(rc))
            error(curl_error)
        end
        rc
    end
end