@testset "web sockets" begin

url_socketsbay = "wss://socketsbay.com/wss/v2/1/d5da93e90d8b8fb64d42d3e65b8fd68d/"

@testset "Two way" begin
    ws1 = HttpClient.open_connection(url_socketsbay, connect_timeout=10)
    ws2 = HttpClient.open_connection(url_socketsbay, connect_timeout=10)

    short_message = "Hello, Rory!"
    HttpClient.send_ping(ws2)
    HttpClient.send(ws1, short_message)
    @test HttpClient.receive(ws2) == short_message

    long_message = "a"^1000
    HttpClient.send(ws2, long_message)
    @test HttpClient.receive(ws1) == long_message

    very_long_message = "a"^10000
    HttpClient.send(ws1, very_long_message)
    message, message_type = HttpClient.receive_any(ws2)
    @test message == very_long_message
    @test message_type == "text"

    close(ws1)
    close(ws2)
end

@testset "Ping pong" begin
    sleep(1)
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

@testset "connect_timeout" begin
    HttpClient.websocket(url_socketsbay, connect_timeout=5) do connection
        sleep(10)
        @test HttpClient.send_ping(connection, "test")
    end
end

@testset "receive pong" begin
    HttpClient.websocket(url_socketsbay) do connection
        message, message_type = HttpClient.receive_any(connection)
        @test message_type == "pong"
    end
end

@testset "Public interface" begin
    headers = Dict("User-Agent" => "http-julia")
    handle = c -> nothing
    @test_throws "TypeError" HttpClient.websocket(handle, url_socketsbay; headers)

    headers = ["User-Agent" => "http-julia"]
    HttpClient.websocket(
        handle,
        url_socketsbay;
        headers,
        query = [],
        connect_timeout = 10.,
        read_timeout = 20.,
        interface = "0.0.0.0",
        proxy = ""
    )
end

@testset "Read timeout" begin
    timer = Timer(10)
    HttpClient.websocket(url_socketsbay; read_timeout=5) do connection
        @test_throws "Read timeout" HttpClient.receive(connection)
    end
    @test isopen(timer)
end

end # testset web sockets
