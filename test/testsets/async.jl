@testset "Optional interface" begin
    query = Dict{String,Any}(
        "echo" => "你好嗎"
    )

    headers = Pair{String,String}[
        "User-Agent" => "HttpClient.jl",
        "Content-Type" => "application/json",
    ]

    listener = Sockets.listen(IPv4("127.0.0.1"), 1234)

    @async while true
        body = """
        HTTP/1.1 200 OK
        Server: nginx
        Date: Wed, 10 Aug 2022 22:00:01 GMT
        Content-Type: text/html; charset=utf-8
        Connection: keep-alive
        Set-Cookie: key=1234-1234-1234-1234-1234; SameSite=Strict; HttpOnly; path=/
        Referrer-Policy: origin-when-cross-origin

        <h1>Hello</h1>
        """

        connection = accept(listener)

        @async while isopen(connection)
            echo = Sockets.readavailable(connection)
            # println(String(echo))
            write(connection, body)
            close(connection)
        end
    end

    sleep(2.0)

    @test_throws "Failed binding local connection end" HttpClient.get(
        "http://127.0.0.1:1234",
        headers = headers,
        query = query,
        interface = "10.10.10.10",
        read_timeout = 30,
    )

    req = HttpClient.get(
        "http://127.0.0.1:1234",
        headers = headers,
        query = query,
        interface = "0.0.0.0",
        read_timeout = 30,
        retries = 10,
    )

    @test req.status == 200
    @test String(req.response) == "<h1>Hello</h1>\n"

    close(listener)
end