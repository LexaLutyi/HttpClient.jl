"Support redirection."
function set_follow_location(easy_handle)
    @curlok curl_easy_setopt(easy_handle, CURLOPT_FOLLOWLOCATION, 1)
    return nothing
end


"Use for post or put request. Body is `String`, `Vector{UInt8}` or `Nothing`."
function set_body(easy_handle, body::String)
    @curlok curl_easy_setopt(easy_handle, CURLOPT_POSTFIELDS, body)
    return nothing
end


function set_body(easy_handle, body::Vector{UInt8})
    @curlok curl_easy_setopt(easy_handle, CURLOPT_POSTFIELDS, body)
    @curlok curl_easy_setopt(easy_handle, CURLOPT_POSTFIELDSIZE, length(body))
    return nothing
end


set_body(easy_handle, ::Nothing) = set_body(easy_handle, "")


"Create vector of bytes and set it as error buffer."
function set_error_buffer(easy_handle)
    error_buffer = zeros(UInt8, CURL_ERROR_SIZE)
    @curlok curl_easy_setopt(easy_handle, CURLOPT_ERRORBUFFER, error_buffer)
    return error_buffer
end


"Remove link to error buffer. Therefore buffer may be safely deleted now."
function remove_error_buffer(easy_handle)
    @curlok curl_easy_setopt(easy_handle, CURLOPT_ERRORBUFFER, C_NULL)
    return nothing
end


"Use for delete request."
function set_delete(easy_handle, ::Nothing)
    @curlok curl_easy_setopt(easy_handle, CURLOPT_CUSTOMREQUEST, "DELETE")
    return nothing
end


function set_delete(easy_handle, what::String)
    request = strip("DELETE $(what)")
    @curlok curl_easy_setopt(easy_handle, CURLOPT_CUSTOMREQUEST, request)
    return nothing
end

"Use for put requests."
function set_put(easy_handle)
    @curlok curl_easy_setopt(easy_handle, CURLOPT_CUSTOMREQUEST, "PUT")
    return nothing
end


"Return pointer, which must be manually freed."
function set_headers(easy_handle, headers::Vector{Header})
    list = Ptr{curl_slist}(0)
    for (key, value) in headers
        temp = curl_slist_append(list, "$(key): $(value)")
        if temp == C_NULL
            curl_slist_free_all(list)
            error("HttpClient: Error appending headers")
        else
            list = temp
        end
    end
    @curlok curl_easy_setopt(easy_handle, CURLOPT_HTTPHEADER, list)
    return list
end


"Use nothing over empty string."
function set_interface(easy_handle, interface::String)
    @curlok curl_easy_setopt(easy_handle, CURLOPT_INTERFACE, interface)
    return nothing
end

function set_interface(easy_handle, ::Nothing)
    @curlok curl_easy_setopt(easy_handle, CURLOPT_INTERFACE, Ptr{UInt8}(0))
    return nothing
end


"""
    set_url(easy_handle, url, query) -> curl_url, full_url

Make full url from url and query, then set it to easy handle.
`curl_url` must be freed after perform.
"""
function set_url(easy_handle, url, user_query)
    query = decode_query(user_query)
    c_url = make_curl_url(url, query)

    c_full_url = [Ptr{UInt8}(0)]
    @curlok curl_url_get(c_url, CURLUPART_URL, c_full_url, 0)
    full_url = unsafe_string(c_full_url[1])
    curl_free(c_full_url[1])

    @curlok curl_easy_setopt(easy_handle, CURLOPT_CURLU, c_url)

    return c_url, full_url
end


"Initialize callback and buffer for response message."
function set_response(easy_handle)
    response = Response()
    c_curl_write_cb = @cfunction(
        curl_write_cb,
        Csize_t,
        (Ptr{Cvoid}, Csize_t, Csize_t, Ptr{Cvoid})
    )
    @curlok curl_easy_setopt(easy_handle, CURLOPT_WRITEFUNCTION, c_curl_write_cb)
    @curlok curl_easy_setopt(easy_handle, CURLOPT_WRITEDATA, Ref(response))
    return response
end


function set_ssl(easy_handle)
    @curlok curl_easy_setopt(easy_handle, CURLOPT_USE_SSL, CURLUSESSL_ALL)
    @curlok curl_easy_setopt(easy_handle, CURLOPT_SSL_VERIFYHOST, 2)
    @curlok curl_easy_setopt(easy_handle, CURLOPT_SSL_VERIFYPEER, 1)
    @curlok curl_easy_setopt(easy_handle, CURLOPT_CAINFO, LibCURL2.cacert)
    return nothing
end


function set_timeout(easy_handle, timeout::Integer)
    @curlok curl_easy_setopt(easy_handle, CURLOPT_TIMEOUT, timeout)
    return nothing
end


function set_timeout(easy_handle, timeout::AbstractFloat)
    ms = round(Int, 1000 * timeout)
    @curlok curl_easy_setopt(easy_handle, CURLOPT_TIMEOUT_MS, ms)
    return nothing
end


"Must be set for web socket."
function set_connect_only(easy_handle)
    @curlok curl_easy_setopt(easy_handle, CURLOPT_CONNECT_ONLY, 2)
    return nothing
end


function set_verbose(easy_handle, isverbose)
    @curlok curl_easy_setopt(easy_handle, CURLOPT_VERBOSE, isverbose ? 1 : 0)
    return nothing
end
