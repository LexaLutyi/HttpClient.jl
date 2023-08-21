function extract_c_headers(curl)
    prev = Ptr{curl_header}(0)
    headers = curl_header[]
    header_ptr = curl_easy_nextheader(curl, CURLH_HEADER, 0, prev)
    while header_ptr != C_NULL
        header = unsafe_load(header_ptr)
        push!(headers, header)
        prev = header_ptr
        header_ptr = curl_easy_nextheader(curl, CURLH_HEADER, 0, prev)
    end
    headers
end


function name_and_value(header)
    name = header.name |> unsafe_string
    value = header.value |> unsafe_string
    name => value
end


function extract_headers(curl)
    c_headers = extract_c_headers(curl)
    c_headers .|> name_and_value |> Dict
end


function add_headers(curl, headers)
    list = Ptr{Cvoid}(0)
    for (key, value) in headers
        list = curl_slist_append(list, "$(key): $(value)")
    end
    curl_easy_setopt(curl, CURLOPT_HTTPHEADER, list)
end
