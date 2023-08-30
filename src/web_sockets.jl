"""
    Connection

active connection using web sockets

see also [`send`](@ref), [`recv`](@ref), [`isopen`](@ref)

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
mutable struct Connection
    curl::Ptr{CURL}
    isopen::Bool
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
        @error "Connection is not open"
        return
    end
    sent = Ref{Csize_t}(0)
    @curlok curl_ws_send(c.curl, pointer(""), 0, sent, 0, CURLWS_CLOSE)
    curl_easy_cleanup(c.curl)
    c.isopen = false
    return
end


set_connect_only(curl) = @curlok curl_easy_setopt(curl, CURLOPT_CONNECT_ONLY, 2)


"""
    open_connection(url; headers, query, interface, timeout, retries) -> Connection

Connect to a web socket server.
"""
function open_connection(url; 
    headers = Dict{String, String}(), 
    query = Dict{String, String}(), 
    interface = "", 
    timeout = 0, 
    retries = 0
    )
    curl = curl_easy_init()

    set_url(curl, url, query)
    set_headers(curl, headers)
    set_interface(curl, interface)
    set_timeout(curl, timeout)
    set_ssl(curl)

    set_connect_only(curl)

    @curlok curl_easy_perform(curl)
    
    # @show http_code = get_http_code(curl)
    # @show headers = get_headers(curl)

    Connection(curl, true)
end


"""
    websocket(url; headers, query, interface, timeout, retries) -> Connection

Connect to a web socket server, run `f` on connection, then close connection.
"""
function websocket(f, url; 
    headers = Dict{String, String}(), 
    query = Dict{String, String}(), 
    interface = "", 
    timeout = 0, 
    retries = 0
    )
    connection = open_connection(url; headers, query, interface, timeout, retries)
    f(connection)
    close(connection)
end


"""
    send(connection, message)

Send `message` to web socket.
Close `connection` on error.
"""
function send(connection, message)
    sent = Ref{Csize_t}(0)
    curl = connection.curl
    result = curl_ws_send(curl, pointer(message), length(message), sent, 0, CURLWS_TEXT)
    if result != CURLE_OK
        connection.isopen = false
        error(curl_code_to_string(result))
    end
    return result
end


function recv_one_frame(connection)
    curl = connection.curl
    received = Ref{Csize_t}(0)
    meta_ptr = [Ptr{curl_ws_frame}(0)]
    buffer_size = 256
    buffer = zeros(UInt8, buffer_size)
    result = curl_ws_recv(curl, buffer, buffer_size, received, meta_ptr)

    if result != CURLE_OK
        connection.isopen = false
        @error curl_code_to_string(result)
    end
    message = GC.@preserve buffer unsafe_string(pointer(buffer), received[])
    frame = unsafe_load(meta_ptr[1], 1)
    LibCURL2.curl_ws_frame
    result, message, frame
end


"""
    recv(connection) -> data

Receive message from web socket. Close `connection` on error.
"""
function recv(connection)
    result, full_message, frame = recv_one_frame(connection)
    while frame.bytesleft > 0
        result, message, frame = recv_one_frame(connection)
        full_message *= message
    end
    full_message
end