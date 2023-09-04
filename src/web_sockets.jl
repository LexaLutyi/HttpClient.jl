"""
    Connection

active connection using web sockets

see also [`send`](@ref), [`receive`](@ref), [`isopen`](@ref)

# Usage
```julia
connection = open_connection(url; ...)
# your code
close(connection)

websocket(url; ...) do connection
    # your code
end
```
"""
@kwdef mutable struct Connection
    pointers::RequestPointers = RequestPointers()
    full_url::String = ""
    isopen::Bool = false
end


"""
    isopen(c::Connection) -> Bool
"""
Base.isopen(c::Connection) = c.isopen


"""
    close(c::Connection)

Close connection and cleanup.
"""
function Base.close(c::Connection)
    if !isopen(c)
        return
    end
    sent = Ref{Csize_t}(0)
    @curlok curl_ws_send(c.pointers.easy_handle, pointer(""), 0, sent, 0, CURLWS_CLOSE)
    # curl_easy_cleanup(c.pointers.easy_handle)
    c.isopen = false
    return
end


set_connect_only(easy_handle) = @curlok curl_easy_setopt(easy_handle, CURLOPT_CONNECT_ONLY, 2)


"""
    open_connection(url; headers, query, interface, timeout, retries) -> Connection

Connect to a web socket server.
"""
function open_connection(url; 
    headers = Dict{String, String}(), 
    query = Dict{String, String}(), 
    interface = "", 
    connect_timeout = 60, 
    retries = 300,
    proxy = nothing
    )
    rp = RequestPointers()
    easy_init(rp)

    full_url = set_url(rp, url, query)
    set_headers(rp.easy_handle, headers)
    set_interface(rp.easy_handle, interface)
    set_timeout(rp.easy_handle, connect_timeout)
    set_ssl(rp.easy_handle)

    set_connect_only(rp.easy_handle)

    # perform(rp, connect_timeout, retries)
    @curlok curl_easy_perform(rp.easy_handle)
    Connection(rp, full_url, true)
end


"""
    websocket(url; headers, query, interface, timeout, retries) -> Connection

Connect to a web socket server, run `handle` on connection, then close connection.

# Arguments
* `handle`: function to call on open connection
* `url`: a string containing url
* `headers`: an iterable container of `Pair{String, String}`
* `query`: an iterable container of `Pair{String, String}`
* `connect_timeout`: abort request after `read_timeout` seconds
* `read_timeout`: unsupported
* `interface`: outgoing network interface. Interface name, an IP address, or a host name.
* `proxy`: unsupported

# Example
```
websocket(url; ...) do connection
    # your code
end
```

"""
function websocket(handle, url; 
    headers = Dict{String, String}(), 
    query = Dict{String, String}(), 
    interface = "", 
    connect_timeout = 60, 
    read_timeout = 300, 
    retries = 0,
    proxy = nothing
    )
    connection = open_connection(url; headers, query, interface, connect_timeout, retries)
    handle(connection)
    close(connection)
end


"""
    send(connection, message)

Send `message` to web socket.
Close `connection` on error.
"""
function send(connection, message)
    sent = Ref{Csize_t}(0)
    easy_handle = connection.pointers.easy_handle
    result = curl_ws_send(easy_handle, pointer(message), length(message), sent, 0, CURLWS_TEXT)
    if result != CURLE_OK
        connection.isopen = false
        error(curl_code_to_string(result))
    end
    return result
end


function recv_one_frame(connection)
    easy_handle = connection.pointers.easy_handle
    received = Ref{Csize_t}(0)
    meta_ptr = [Ptr{curl_ws_frame}(0)]
    buffer_size = 256
    buffer = zeros(UInt8, buffer_size)
    result = curl_ws_recv(easy_handle, buffer, buffer_size, received, meta_ptr)

    if result != CURLE_OK
        connection.isopen = false
        @error "Connection is closed: " * curl_code_to_string(result)
    end
    
    message = GC.@preserve buffer unsafe_string(pointer(buffer), received[])
    
    if meta_ptr[1] != C_NULL
        frame = unsafe_load(meta_ptr[1], 1)
        if (frame.flags & CURLWS_BINARY) != 0
            @warn "received binary data"
        end
    else
        frame = curl_ws_frame(0, 0, 0, 0, 0)
    end
    
    result, message, frame
end


"""
    receive(connection) -> data

Receive message from web socket. Close `connection` on error.
"""
function receive(connection)
    result, full_message, frame = recv_one_frame(connection)
    while (frame.bytesleft > 0) && isopen(connection)
        result, message, frame = recv_one_frame(connection)
        full_message *= message
    end
    full_message
end