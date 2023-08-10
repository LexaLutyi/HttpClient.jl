struct CurlHeader
    name::Ptr{UInt8}
    value::Ptr{UInt8}
    amount::Csize_t
    index::Csize_t
    origin::UInt32
    anchor::Ptr{Cvoid}
end


const CURLH_HEADER = UInt32(1)

function curl_easy_nextheader(curl, origin, request, prev)
    @ccall libcurl.curl_easy_nextheader(curl::Ptr{CURL}, origin::UInt32, request::Int32, prev::Ptr{CurlHeader})::Ptr{CurlHeader}
end


function extract_c_headers(curl)
    prev = Ptr{CurlHeader}(0)
    headers = CurlHeader[]
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