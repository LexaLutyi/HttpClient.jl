function set_query(url, query)
    c_url = curl_url()
    @curlok return_code = curl_url_set(c_url, CURLUPART_URL, url, CURLU_DEFAULT_SCHEME)
    for (key, value) in query
        # pair = "(key=$(value)"
        pair = String(key) * "=" * String(value)
        @curlok curl_url_set(c_url, CURLUPART_QUERY, pair, CURLU_APPENDQUERY | CURLU_URLENCODE)
    end
    c_url
end


function set_url(curl, url, query)
    c_url = set_query(url, query)
    @curlok curl_easy_setopt(curl, CURLOPT_CURLU, c_url)
end