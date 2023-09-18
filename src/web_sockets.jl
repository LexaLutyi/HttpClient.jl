"""
    Connection

A connection to server via web socket protocol.

See also [`send`](@ref), [`receive`](@ref), [`isopen`](@ref)

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
    error_buffer::Vector{UInt8} = zeros(UInt8, CURL_ERROR_SIZE)
    isdeflate::Bool = false
end

"""
    isopen(c::Connection) -> Bool
"""
Base.isopen(c::Connection) = c.isopen

"""
    close(c::Connection)
"""
function Base.close(c::Connection, message="close")
    if !isopen(c)
        return nothing
    end
    send(c, message, flags=CURLWS_CLOSE)
    c.isopen = false
    return nothing
end

function ispermessage_deflate(headers)
    for (key, value) in headers
        A = lowercase(key) == "sec-websocket-extensions"
        B = lowercase(value) == "permessage-deflate"
        if A && B
            return true
        end
    end
    return false
end

"""
    open_connection(url; <keyword arguments>) -> Connection

Connect to a web socket server.

# Keyword Arguments
* `headers = Pair{String, String}[]`. Any iterable container of `Pair{String, String}`.
* `query = nothing`. A string or pairs of strings. Automatic url encoding.
* `interface = nothing`. Outgoing network interface. Interface name, an IP address, or a host name.
* `connect_timeout = 60`. Abort initial request after timeout is reached.
* `proxy = nothing`. Unsupported.
* `verbose = false`. Show libcurl verbose messages.
* `isdeflate = false`. Decompress messages from server using deflate protocol.
"""
function open_connection(url::AbstractString;
    headers = Header[],
    query = nothing,
    interface::Union{String,Nothing} = nothing,
    connect_timeout = 60,
    proxy::Union{String,Nothing} = nothing,
    verbose = false,
    isdeflate = false
    )
    if !isdeflate && ispermessage_deflate(headers)
        info_message = "Setting isdeflate=true. " *
            "Set it manually via keyword argument to suppress this message."
        @info info_message
        isdeflate = true
    end

    rp = RequestPointers()
    easy_init(rp)

    rp.curl_url, full_url = set_url(rp.easy_handle, url, query)
    rp.slist = set_headers(rp.easy_handle, headers)
    error_buffer = set_error_buffer(rp.easy_handle)
    set_interface(rp.easy_handle, interface)
    set_timeout(rp.easy_handle, connect_timeout)
    set_ssl(rp.easy_handle)
    set_verbose(rp.easy_handle, verbose)
    set_connect_only(rp.easy_handle)

    result = curl_easy_perform(rp.easy_handle)
    result != CURLE_OK && error(join_messages(result, error_buffer))

    # if not reset, then connection will be broken after connect_timeout seconds
    set_timeout(rp.easy_handle, 0)

    return Connection(rp, full_url, true, error_buffer, isdeflate)
end

"""
    websocket([handle,] url; <keyword arguments>) -> Connection

Connect to a web socket server, run `handle` on connection, then close connection.

# Keyword Arguments
* `headers = Pair{String, String}[]`. Any iterable container of `Pair{String, String}`.
* `query = nothing`. A string or pairs of strings. Automatic url encoding.
* `interface = nothing`. Outgoing network interface.
Interface name, an IP address, or a host name.
* `connect_timeout = 60`. Abort initial request after timeout is reached.
* `proxy = nothing`. Unsupported.
* `verbose = false`. Show libcurl verbose messages.
* `isdeflate = false`. Decompress messages from server using deflate protocol.

# Example
```
websocket(url; ...) do connection
    # your code
end

f(connection) = # your code
websocket(f, url; ...)
```
"""
function websocket(handle, url::AbstractString;
    headers::Vector{Header} = Header[],
    query = nothing,
    interface::Union{String,Nothing} = nothing,
    connect_timeout::Real = 60,
    read_timeout::Real = 300,
    proxy::Union{String,Nothing} = nothing,
    verbose::Bool = false,
    isdeflate::Bool = false
    )
    connection = open_connection(url;
        headers,
        query,
        interface,
        connect_timeout,
        proxy,
        verbose,
        isdeflate
    )
    ping_timer = Timer(0; interval = 60) do timer
        send_ping(connection)
    end
    wait(ping_timer)

    handle(connection)

    close(ping_timer)
    close(connection, "close")
    return nothing
end

"""
    send(connection, message; flags)

Send `message` to web socket.
Close `connection` on error.

Use `String` as message for text and `Vector{UInt8}` for binary data.
`flags` are set automatically based on message type.
See [curl docs](https://curl.se/libcurl/c/curl_ws_send.html) for possible values.

# Example
```julia
HttpClient.send(connection, "Hello!")
```
"""
function send(connection, message::Vector{UInt8}=UInt8[]; flags = CURLWS_BINARY)
    easy_handle = connection.pointers.easy_handle

    sent = Ref{Csize_t}(0)
    result = curl_ws_send(
        easy_handle,
        length(message) == 0 ? C_NULL : message,
        length(message),
        sent,
        0,
        flags
    )

    if result != CURLE_OK
        connection.isopen = false
        raise_curl_error(result, connection.error_buffer)
    end
    return true
end

function send(connection, message::AbstractString; flags=CURLWS_TEXT)
    return send(connection, Vector{UInt8}(message); flags)
end

function recv_one_frame(connection)
    easy_handle = connection.pointers.easy_handle

    received = Ref{Csize_t}(0)
    meta_ptr = [Ptr{curl_ws_frame}(0)]
    buffer_size = 256
    buffer = zeros(UInt8, buffer_size)
    result = curl_ws_recv(easy_handle, buffer, buffer_size, received, meta_ptr)

    # Socket not ready for send/recv. Try again.
    if result == CURLE_AGAIN
        sleep_dt = 0.01
        @debug curl_code_to_string(result) sleep_dt
        sleep(sleep_dt)
        return recv_one_frame(connection)
    end

    if result != CURLE_OK
        connection.isopen = false
        raise_curl_error(result, connection.error_buffer)
    end

    message = GC.@preserve buffer unsafe_string(pointer(buffer), received[])
    frame = unsafe_load(meta_ptr[1], 1)
    return message, frame
end

"""
    receive_any(connection) -> message, message_type

Receive any message from server and don't perform any control actions.
Possible message types are text, binary, ping, pong, close, missing.

User is responsible for handling control messages.
"""
function receive_any(connection)
    yield()
    full_message, frame = recv_one_frame(connection)
    while frame.bytesleft > 0
        message, frame = recv_one_frame(connection)
        full_message *= message
    end

    flags = frame.flags
    message_type = if (flags & CURLWS_PING) != 0
        "ping"
    elseif (flags & CURLWS_PONG) != 0
        "pong"
    elseif (flags & CURLWS_TEXT) != 0
        "text"
    elseif (flags & CURLWS_BINARY) != 0
        "binary"
    elseif (flags & CURLWS_CLOSE) != 0
        "close"
    else
        "missing"
    end

    return full_message, message_type
end

"""
    receive(connection) -> message

Receive message from web socket while handling all control messages.
Close `connection` on error.

To monitor control messages,
you can display debug messages via `ENV["JULIA_DEBUG"] = "HttpClient"`
"""
function receive(connection)
    message, message_type = receive_any(connection)
    if message_type ∉ ("text", "binary")
        control_message_handler(message, message_type, connection)
        if !isopen(connection) # Connection was closed without error.
            return message
        end
        return receive(connection) # User get only text or binary messages.
    end

    if connection.isdeflate
        message = decompress(message)
    end

    return message
end

function control_message_handler(message, message_type, connection)
    if message_type == "ping"
        @debug "Received ping message, send pong message"
        send_pong(connection, message)
    elseif message_type == "pong"
        @debug "Received pong message"
    elseif message_type == "close"
        @debug "Server closed connection"
        close(connection)
    elseif message_type == "missing"
        @warn "Received unknown message type, skipping"
    else
        error("Unsupported message type")
    end
    return nothing
end

"""
    send_ping(connection, message = "foo")

Send ping message to a server.

*WARNING* empty message may close connection.
"""
function send_ping(connection, message = "foo")
    return send(connection, message; flags = CURLWS_PING)
end

"""
    send_pong(connection, message = "foo")

Send pong message to a server.

*WARNING* empty message may close connection.
"""
function send_pong(connection, message = "foo")
    return send(connection, message; flags = CURLWS_PONG)
end

"""
    receive_pong(connection, message = "foo") -> ispong, data

Try to receive pong message.
Warning if received message is not pong.
Error if received wrong pong message.
"""
function receive_pong(connection, message = "foo")
    data, message_type = receive_any(connection)
    if message_type != "pong"
        @warn "receive_pong: expected pong, but received data"
        return false, data
    end

    if data != message
        error("Server return wrong pong message. Expected $(message), got $(data).")
    end

    return true, data
end
