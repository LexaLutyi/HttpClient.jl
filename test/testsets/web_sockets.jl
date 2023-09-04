@testset "connection" begin
    url = "wss://stream.binance.com:9443/stream?streams=adausdt@depth20@100ms/btcusdt@depth20@100ms"
    headers = [
        # "sec-websocket-extensions" => "permessage-deflate",
        "User-Agent" => "http-julia"
    ]
    connection = HttpClient.open_connection(url; headers)
    @test isopen(connection)
    @test connection.full_url == "wss://stream.binance.com:9443/stream?streams=adausdt@depth20@100ms/btcusdt@depth20@100ms"
    close(connection)
    @test isopen(connection) == false
end


@testset "websocket" begin
    buffer = []

    url = "wss://stream.binance.com:9443/stream?streams=adausdt@depth20@100ms/btcusdt@depth20@100ms"
    headers = [
        # "sec-websocket-extensions" => "permessage-deflate",
        "User-Agent" => "http-julia"
    ]
    # url = "wss://socketsbay.com/wss/v2/1/d5da93e90d8b8fb64d42d3e65b8fd68d/"

    HttpClient.websocket(url; headers, connect_timeout=10) do connection
        push!(buffer, "function is called")
        push!(buffer, connection)
        @test isopen(connection)
        @test connection.full_url == "wss://stream.binance.com:9443/stream?streams=adausdt@depth20@100ms/btcusdt@depth20@100ms"
        @test connection.pointers.easy_handle != C_NULL

        HttpClient.send(connection, "Hello binance")
        @test isopen(connection)

        data = HttpClient.receive(connection)
        # @show String(data)
        @test typeof(JSON.parse(data))<:Dict
        @test isopen(connection)
    end

    @test buffer[1] == "function is called"
    @test isopen(buffer[2]) == false
end