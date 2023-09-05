to_query(q::AbstractString) = q
to_query(q::Pair) = String(q.first) * "=" * String(q.second)

decode_query(::Nothing) = []
decode_query(q::String) = [q]
decode_query(q::AbstractArray) = q .|> to_query
decode_query(q::AbstractDict) = q |> collect .|> to_query

function make_curl_url(url, query)
    c_url = curl_url()
    if c_url == C_NULL
        @error("HttpClient: Error initializing curl url")
    end
    @curlok return_code = curl_url_set(c_url, CURLUPART_URL, url, CURLU_DEFAULT_SCHEME | CURLU_URLENCODE)
    for pair in query
        @curlok curl_url_set(c_url, CURLUPART_QUERY, pair, CURLU_APPENDQUERY | CURLU_URLENCODE)
    end
    c_url
end


function set_url(rp, url, user_query)
    query = decode_query(user_query)
    rp.curl_url = make_curl_url(url, query)
9
    c_full_url = [Ptr{UInt8}(0)]
    @curlok curl_url_get(rp.curl_url, CURLUPART_URL, c_full_url, 0)
    full_url = unsafe_string(c_full_url[1])
    curl_free(c_full_url[1])

    @curlok curl_easy_setopt(rp.easy_handle, CURLOPT_CURLU, rp.curl_url)
    full_url
end