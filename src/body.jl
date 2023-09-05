function set_body(curl, body)
    body = isnothing(body) ? Vector{UInt8}() : body
    @curlok curl_easy_setopt(curl, CURLOPT_POSTFIELDS, body)
end