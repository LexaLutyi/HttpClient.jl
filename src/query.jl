to_query(q::AbstractString) = String(q)
to_query(q::Pair) = String(q.first) * "=" * String(q.second)


decode_query(::Nothing) = String[]
decode_query(q::String) = [q]
decode_query(q::AbstractArray) = length(q) > 0 ? to_query.(q) : String[]
decode_query(q::AbstractDict) = q |> collect .|> to_query


function make_curl_url(url, query::Vector{String})
    c_url = curl_url()
    if c_url == C_NULL
        @error("HttpClient: Error initializing curl url")
    end
    @curlok curl_url_set(
        c_url,
        CURLUPART_URL,
        url,
        CURLU_DEFAULT_SCHEME | CURLU_URLENCODE
    )
    for pair in query
        @curlok curl_url_set(
            c_url,
            CURLUPART_QUERY,
            pair,
            CURLU_APPENDQUERY | CURLU_URLENCODE
        )
    end
    return c_url
end
