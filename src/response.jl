mutable struct Response
    txt::Ptr{UInt8}
    allocated::Csize_t
    len::Csize_t
    function Response(txt, allocated, len)
        x = new(txt, allocated, len)
        finalizer(x) do x
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
    return Response(txt, allocated, len)
end

"callback function to receive data"
function curl_write_cb(curlbuf::Ptr{Cvoid}, s::Csize_t, n::Csize_t, p_ctxt::Ptr{Cvoid})
    response = unsafe_pointer_to_objref(p_ctxt)

    # Check if there is enough memory.
    sz = s * n
    if sz + response.len + 1 > response.allocated
        response.allocated += CURL_MAX_WRITE_SIZE
        response.txt = Libc.realloc(response.txt, response.allocated)
        if response.txt == C_NULL
            error(Libc.strerror())
        end
    end
    # Append curlbuf to response.txt
    text_end = response.txt + response.len
    ccall(:memcpy, Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}, UInt64), text_end, curlbuf, sz)
    response.len += sz
    unsafe_store!(response.txt, 0, response.len + 1)

    return sz::Csize_t
end

response_as_string(response) = GC.@preserve response unsafe_string(response.txt)
