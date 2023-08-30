@testset "connection" begin
    url = "wss://stream.binance.com:9443/stream?streams=adausdt@depth20@100ms/btcusdt@depth20@100ms"

    connection = HttpClient.open_connection(url)
    @test isopen(connection)
    close(connection)
    @test isopen(connection) == false
end


@testset "websocket" begin
    buffer = []

    url = "wss://stream.binance.com:9443/stream?streams=adausdt@depth20@100ms/btcusdt@depth20@100ms"
    # headers = [
    #     "sec-websocket-extensions" => "permessage-deflate"
    # ]
    # url = "wss://socketsbay.com/wss/v2/1/d5da93e90d8b8fb64d42d3e65b8fd68d/"
    headers = []

    HttpClient.websocket(url; headers, timeout=10) do connection
        push!(buffer, "function is called")
        push!(buffer, connection)
        @test isopen(connection)
        @test connection.curl != C_NULL

        HttpClient.send(connection, "Hello binance")
        @test isopen(connection)

        data = HttpClient.recv(connection)
        @test typeof(JSON.parse(data))<:Dict
        @test isopen(connection)
    end

    @test buffer[1] == "function is called"
    @test isopen(buffer[2]) == false
end