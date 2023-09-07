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
    error_buffer::Vector{UInt8} = zeros(UInt8, CURL_ERROR_SIZE)
    isdeflate::Bool = false
end


"""
    isopen(c::Connection) -> Bool
"""
Base.isopen(c::Connection) = c.isopen


"""
    close(c::Connection)

Close connection and cleanup.
"""
function Base.close(c::Connection, message="close")
    if !isopen(c)
        return
    end
    send(c, message, flags=CURLWS_CLOSE)
    c.isopen = false
    return
end


set_connect_only(easy_handle) = @curlok curl_easy_setopt(easy_handle, CURLOPT_CONNECT_ONLY, 2)
set_verbose(easy_handle, verbose) = @curlok curl_easy_setopt(easy_handle, CURLOPT_VERBOSE, verbose ? 1 : 0)

function set_error_buffer(easy_handle)
    error_buffer = zeros(UInt8, CURL_ERROR_SIZE)
    @curlok curl_easy_setopt(easy_handle, CURLOPT_ERRORBUFFER, error_buffer)
    error_buffer
end


function ispermessage_deflate(headers)
    for (key, value) in headers
        if lowercase(key) == "sec-websocket-extensions" && lowercase(value) == "permessage-deflate"
            return true
        end
    end
    return false
end


"""
    open_connection(url; headers, query, interface, timeout, retries) -> Connection

Connect to a web socket server.
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
    rp = RequestPointers()
    easy_init(rp)

    full_url = set_url(rp, url, query)
    set_headers(rp.easy_handle, headers)
    set_interface(rp.easy_handle, interface)
    set_timeout(rp.easy_handle, connect_timeout)
    set_ssl(rp.easy_handle)
    set_verbose(rp.easy_handle, verbose)
    error_buffer = set_error_buffer(rp.easy_handle)

    set_connect_only(rp.easy_handle)

    # perform(rp, connect_timeout, retries)
    result = curl_easy_perform(rp.easy_handle)
    result != CURLE_OK && print_curl_error(result, error_buffer)

    # if not reset, then connection will be broken after connect_timeout seconds
    set_timeout(rp.easy_handle, 0)

    if !isdeflate && ispermessage_deflate(headers)
        @info "Setting isdeflate=true. Set it manually via keyword argument to suppress this message."
        isdeflate = true
    end

    Connection(rp, full_url, true, error_buffer, isdeflate)
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
function websocket(handle, url::AbstractString; 
    headers = Header[], 
    query = nothing, 
    interface::Union{String,Nothing} = nothing, 
    connect_timeout = 60, 
    proxy::Union{String,Nothing} = nothing,
    verbose = false,
    isdeflate = false
    )
    connection = open_connection(url; headers, query, interface, connect_timeout, proxy, verbose, isdeflate)
    handle(connection)
    close(connection, "close")
end


"""
    send(connection, message)

Send `message` to web socket.
Close `connection` on error.
"""
function send(connection, message::Vector{UInt8}=UInt8[]; flags = CURLWS_TEXT)
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
        print_curl_error(result, connection.error_buffer)
    end
    return true
end


send(connection, message::AbstractString; flags=CURLWS_TEXT) = 
    send(connection, Vector{UInt8}(message); flags)


function recv_one_frame(connection)
    easy_handle = connection.pointers.easy_handle
    received = Ref{Csize_t}(0)
    meta_ptr = [Ptr{curl_ws_frame}(0)]
    buffer_size = 256
    buffer = zeros(UInt8, buffer_size)
    result = curl_ws_recv(easy_handle, buffer, buffer_size, received, meta_ptr)

    if result != CURLE_OK
        message = ""
        frame = curl_ws_frame(0, 0, 0, 0, 0)
        error_message = curl_code_to_string(result)
        error_message2 = connection.error_buffer |> pointer |> unsafe_string
        @error "curl_ws_recv" error_message error_message2
        return result, message, frame
    end
    
    message = GC.@preserve buffer unsafe_string(pointer(buffer), received[])
    frame = unsafe_load(meta_ptr[1], 1)
    return result, message, frame
end


function receive_any(connection)
    result, full_message, frame = recv_one_frame(connection)
    while result == CURLE_OK && frame.bytesleft > 0
        result, message, frame = recv_one_frame(connection)
        full_message *= message
    end

    if result == CURLE_AGAIN
        error_str = curl_code_to_string(result)
        sleep_time = 1
        warn_str = error_str * ": retry in $sleep_time second"
        @warn warn_str full_message
        sleep(sleep_time)
        return receive_any(connection)
    elseif result != CURLE_OK
        connection.isopen = false
    end

    if (frame.flags & CURLWS_PING) != 0
        message_type = "ping"
    elseif (frame.flags & CURLWS_PONG) != 0
        message_type = "pong"
    elseif (frame.flags & CURLWS_TEXT) != 0
        message_type = "text"
    elseif (frame.flags & CURLWS_BINARY) != 0
        message_type = "binary"
    elseif (frame.flags & CURLWS_CLOSE) != 0
        message_type = "close"
    else
        message_type = "missing"
    end
    full_message, message_type
end


"""
    receive(connection) -> data

Receive message from web socket. Close `connection` on error.
"""
function receive(connection)
    message, message_type = receive_any(connection)
    if message_type ∉ ("text", "binary")
        @debug "receive $message_type message"
        return receive(connection)
    end
    if connection.isdeflate
        message = decompress(message)
    end
    return message
end


function send_ping(connection, message = "foo")
    send(connection, message; flags = CURLWS_PING)
end


function send_pong(connection, message = "foo")
    send(connection, message; flags = CURLWS_PONG)
end


function receive_pong(connection, message = "foo")
    data, message_type = receive_any(connection)
    if message_type != "pong"
        @warn "receive_pong: receive data"
        return false, data
    end
    if data != message
        error("HttpClient.pong: server return wrong message. Expected $(message), got $(data)")
    end
    true, data
end