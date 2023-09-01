mutable struct Response
    txt::Ptr{UInt8}
    allocated::Csize_t
    len::Csize_t
    function Response(txt, allocated, len)
        x = new(txt, allocated, len)
        finalizer(x) do x
            # @async println("Finalizing $x.")
            if x.txt != C_NULL
                Libc.free(x.txt)
            end
        end
    end
end


function Response()
    allocated = CURL_MAX_WRITE_SIZE + 1    
    txt = Libc.malloc(allocated) |> Ptr{UInt8}
    if txt == C_NULL
        error(Libc.strerror())
    end
    len = 0
    unsafe_store!(txt, 0, len + 1)
    Response(txt, allocated, len)
end


# setup the callback function to recv data
function curl_write_cb(curlbuf::Ptr{Cvoid}, s::Csize_t, n::Csize_t, p_ctxt::Ptr{Cvoid})
    response = unsafe_pointer_to_objref(p_ctxt)

    sz = s * n
    if sz + response.len + 1 > response.allocated
        response.allocated += CURL_MAX_WRITE_SIZE
        response.txt = Libc.realloc(response.txt, response.allocated)
        if response.txt == C_NULL
            error(Libc.strerror())
        end
    end

    text_end = response.txt + response.len
    ccall(:memcpy, Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}, UInt64), text_end, curlbuf, sz)
    response.len += sz
    unsafe_store!(response.txt, 0, response.len + 1)

    sz::Csize_t
end


function set_response(curl)
    response = Response()
    c_curl_write_cb = @cfunction(curl_write_cb, Csize_t, (Ptr{Cvoid}, Csize_t, Csize_t, Ptr{Cvoid}))
    @curlok curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, c_curl_write_cb)
    @curlok curl_easy_setopt(curl, CURLOPT_WRITEDATA, Ref(response))
    response
end


response_as_string(response) = GC.@preserve response unsafe_string(response.txt)