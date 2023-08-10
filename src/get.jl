# setup the callback function to recv data
function curl_write_cb(curlbuf::Ptr{Cvoid}, s::Csize_t, n::Csize_t, p_ctxt::Ptr{Cvoid})
    sz = s * n

    ccall(:memcpy, Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}, UInt64), p_ctxt, curlbuf, sz)

    sz::Csize_t
end


function get(url)
    curl = curl_easy_init()

    curl_easy_setopt(curl, CURLOPT_URL, url)
    #! curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1)

    response = zeros(UInt8, CURL_MAX_WRITE_SIZE)
    c_curl_write_cb = @cfunction(curl_write_cb, Csize_t, (Ptr{Cvoid}, Csize_t, Csize_t, Ptr{Cvoid}))

    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, c_curl_write_cb)
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, response)

    res = curl_easy_perform(curl)
    if res != CURLE_OK
        curl_error = unsafe_string(curl_easy_strerror(res))
        error(curl_error)
    end

    # retrieve HTTP code
    http_code = Array{Clong}(undef, 1)
    curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, http_code)

    # convert to julia string
    response_string = GC.@preserve response unsafe_string(pointer(response))
    
    #! curl_easy_cleanup(curl)

    headers = extract_headers(curl)

    return Request(response_string, http_code[1], headers)
end