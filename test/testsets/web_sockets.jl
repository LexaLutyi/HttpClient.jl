@testset "web sockets" begin

url_socketsbay = "wss://socketsbay.com/wss/v2/1/d5da93e90d8b8fb64d42d3e65b8fd68d/"
url_binance_stream = "wss://stream.binance.com:9443/stream?streams=adausdt@depth20@100ms/btcusdt@depth20@100ms"
url_binance = "wss://ws-api.binance.com:443/ws-api/v3"



ping_body = """{  "id": "922bcc6e-9de8-440d-9e84-7c80933a8d0d",  "method": "ping"}"""


@testset "open and close" begin
    connection = HttpClient.open_connection(url_binance; headers)
    @test isopen(connection)
    @test connection.full_url == url_binance
    close(connection)
    @test isopen(connection) == false
end


@testset "websocket low level" begin
    buffer = []

    headers = ["User-Agent" => "http-julia"]

    HttpClient.websocket(url_binance; headers, connect_timeout=10) do connection
        push!(buffer, "function is called")
        push!(buffer, connection)
        @test isopen(connection)
        @test connection.full_url == url_binance
        @test connection.pointers.easy_handle != C_NULL

        HttpClient.send(connection, "Hello binance")
        @test isopen(connection)

        data = HttpClient.receive(connection)
        @test typeof(JSON.parse(data)) <: Dict
        @test isopen(connection)
    end

    @test buffer[1] == "function is called"
    @test isopen(buffer[2]) == false
end


@testset "Two way" begin
    ws1 = HttpClient.open_connection(url_socketsbay, connect_timeout=10)
    ws2 = HttpClient.open_connection(url_socketsbay, connect_timeout=10)

    HttpClient.send_ping(ws2)
    sleep(1)
    HttpClient.send(ws1, "Hello, Rory!")

    @test HttpClient.receive(ws2) == "Hello, Rory!"

    HttpClient.send(ws2, "Hello, Yuki!")
    @test HttpClient.receive(ws1) == "Hello, Yuki!"

    HttpClient.send(ws1, "xyz")
    message, message_type = HttpClient.receive_any(ws2)
    @test message == "xyz"
    @test message_type == "text"

    close(ws1)
    close(ws2)
end


@testset "Ping pong" begin
    HttpClient.websocket(url_socketsbay, connect_timeout=10) do connection
        message, message_type = HttpClient.receive_any(connection)
        @test message == "foo"
        @test message_type == "pong"

        @test HttpClient.send_ping(connection, "test2")
        @test HttpClient.receive_pong(connection, "test2")[1]

        @test HttpClient.send_ping(connection, "1")
        @test HttpClient.receive_pong(connection, "1")[1]

        @test HttpClient.send_ping(connection)
        @test HttpClient.receive_pong(connection)[1]
    end
end


@testset "send_pong binance" begin
    headers = ["User-Agent" => "http-julia"]

    HttpClient.websocket(url_binance; headers, connect_timeout=10) do connection
        HttpClient.send_pong(connection)

        data, message_type = HttpClient.receive_any(connection)
        @test message_type == "pong"
        @test data == "foo"
        
        sleep(1)
        HttpClient.send(connection, ping_body)
        data, message_type = HttpClient.receive_any(connection)
        @test message_type == "text"
    end
end


@testset "per message deflate" begin
    headers = [
        "User-Agent" => "http-julia", 
        "sec-websocket-extensions" => "permessage-deflate"
    ]
    HttpClient.websocket(
        url_binance;
        headers,
    ) do connection
        message, message_type = HttpClient.receive_any(connection)
        @test message == "foo"
        @test message_type == "pong"

        HttpClient.send(connection, ping_body)
        deflate_message, _ = HttpClient.receive_any(connection)
        message = HttpClient.decompress(deflate_message)
        @test typeof(JSON.parse(String(message))) <: Dict
    end


    HttpClient.websocket(
        url_binance;
        headers,
        isdeflate = true
    ) do connection
        HttpClient.send(connection, ping_body)
        message = HttpClient.receive(connection)
        @test typeof(JSON.parse(String(message))) <: Dict
    end
end


@testset "connect_timeout" begin
    HttpClient.websocket(url_socketsbay, connect_timeout=5) do connection
        sleep(10)
        @test HttpClient.send_ping(connection, "test")
    end
end


@testset "close connection" begin
    HttpClient.websocket(url_binance_stream) do connection
        while isopen(connection)
            HttpClient.send_ping(connection)
            HttpClient.receive(connection)
        end
    end
end


@testset "receive pong" begin
    HttpClient.websocket(url_binance) do connection
        message, message_type = HttpClient.receive_any(connection)
        @test message_type == "pong"
    end
end

end # testset web sockets