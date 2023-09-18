curl_code_to_string(code) = unsafe_string(curl_easy_strerror(code))

"""
    curlok(exp)

Raise error, if result of `exp` is not CURLE_OK.
"""
macro curlok(exp)
    quote
        local return_code = $(esc(exp))
        if return_code != CURLE_OK
            curl_error = curl_code_to_string(return_code)
            error(curl_error)
        end
        return_code
    end
end

"""
    join_messages(code, error_buffer)

Join message associated with `code` and specific message from `error_buffer`.
"""
function join_messages(code, error_buffer)
    error_first = curl_code_to_string(code)
    error_second = String(error_buffer)
    return join([error_first, error_second], ": ")
end
