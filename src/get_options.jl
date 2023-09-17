"Use after perform"
function get_http_code(easy_handle)
    http_code = Ref{Clong}(0)
    @curlok curl_easy_getinfo(easy_handle, CURLINFO_RESPONSE_CODE, http_code)
    return http_code[]
end


function raw_headers(easy_handle)
    prev = Ptr{curl_header}(0)
    headers = curl_header[]
    header_ptr = curl_easy_nextheader(easy_handle, CURLH_HEADER, 0, prev)
    while header_ptr != C_NULL
        header = unsafe_load(header_ptr)
        push!(headers, header)
        prev = header_ptr
        header_ptr = curl_easy_nextheader(easy_handle, CURLH_HEADER, 0, prev)
    end
    return headers
end


function load_pairs(header)
    name = header.name |> unsafe_string
    value = header.value |> unsafe_string
    return name => value
end


"Use after perform"
function get_headers(easy_handle)
    c_headers = raw_headers(easy_handle)
    return c_headers .|> load_pairs |> Dict
end