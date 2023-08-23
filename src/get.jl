# setup the callback function to recv data
function curl_write_cb(curlbuf::Ptr{Cvoid}, s::Csize_t, n::Csize_t, p_ctxt::Ptr{Cvoid})
    sz = s * n

    ccall(:memcpy, Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}, UInt64), p_ctxt, curlbuf, sz)

    sz::Csize_t
end


function set_response(curl)
    response = zeros(UInt8, CURL_MAX_WRITE_SIZE)
    c_curl_write_cb = @cfunction(curl_write_cb, Csize_t, (Ptr{Cvoid}, Csize_t, Csize_t, Ptr{Cvoid}))
    @curlok curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, c_curl_write_cb)
    @curlok curl_easy_setopt(curl, CURLOPT_WRITEDATA, response)
    response
end


function get_http_code(curl)
    http_code = Array{Clong}(undef, 1)
    @curlok curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, http_code)
    http_code[1]
end


"""
    get(url; headers, query, interface, timeout, retires)

Perform http get request and return `Request` object.
"""
function get(url; 
    headers = Dict{String, String}(), 
    query = Dict{String, String}(), 
    interface = "", 
    timeout = 0, 
    retries = 0
    )
    
    c_url = set_query(url, query)
    curl = curl_easy_init()
    @curlok curl_easy_setopt(curl, CURLOPT_CURLU, c_url)

    # ! How to test this?
    # curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1)

    response = set_response(curl)
    set_headers(curl, headers)
    set_interface(curl, interface)
    set_timeout(curl, timeout)
    set_ssl(curl)

    retry(
        curl -> HttpClient.@curlok(curl_easy_perform(curl)); 
        delays=fill(timeout, retries)
    )(curl)

    http_code = get_http_code(curl)
    response_string = GC.@preserve response unsafe_string(pointer(response))
    headers = get_headers(curl)

    # ! How to test this?
    # curl_easy_cleanup(curl)

    Request(response_string, http_code, headers)
end