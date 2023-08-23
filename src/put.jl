function set_put(curl)
    @curlok curl_easy_setopt(curl, CURLOPT_CUSTOMREQUEST, "PUT")
end


function put(url; 
    headers = Dict{String, String}(), 
    query = Dict{String, String}(),
    data = "", 
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
    set_data(curl, data)
    set_put(curl)

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