function set_body(curl, body::Vector{UInt8})
    @curlok curl_easy_setopt(curl, CURLOPT_POSTFIELDS, body)
    @curlok curl_easy_setopt(curl, CURLOPT_POSTFIELDSIZE, length(body))
end


function set_body(curl, ::Nothing)
    set_body(curl, "")
end


function set_body(curl, body::AbstractString)
    @curlok curl_easy_setopt(curl, CURLOPT_POSTFIELDS, body)
end