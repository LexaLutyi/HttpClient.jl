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


function raise_curl_error(code, error_buffer::String)
    error_base = curl_code_to_string(code)
    error(join([error_base, error_buffer], ": "))
end

function raise_curl_error(code, error_buffer::Vector{UInt8})
    str = GC.@preserve error_buffer unsafe_string(pointer(error_buffer))
    raise_curl_error(code, str)
end


function set_error_buffer(easy_handle)
    error_buffer = zeros(UInt8, CURL_ERROR_SIZE)
    @curlok curl_easy_setopt(easy_handle, CURLOPT_ERRORBUFFER, error_buffer)
    error_buffer
end


function remove_error_buffer(easy_handle)
    @curlok curl_easy_setopt(easy_handle, CURLOPT_ERRORBUFFER, C_NULL)
end