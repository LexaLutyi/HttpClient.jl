@testset "Get" begin

    @testset "200" begin
        url = "https://example.com"
        url_bkp = deepcopy(url)
        request = HttpClient.get(url)
    
        @test typeof(request.response) == String
        @test length(request.response) > 0
    
        @test request.status == 200
    
        @test caseless_key_check(request.headers, "Content-Type", "text/html; charset=UTF-8")
    
        @test url == url_bkp
    end
    
    
    @testset "404" begin
        url = "https://www.google.com/404"
        request = HttpClient.get(url; status_exception = false)
   
        @test request.status == 404
    
        @test caseless_key_check(request.headers, "Content-Type", "text/html; charset=UTF-8")

        @test_throws "StatusError: 404" HttpClient.get(url)
    end
    
    
    @testset "Couldn't resolve host name" begin
        url = "https://example.co"
        @test_throws "Couldn't resolve host name" HttpClient.get(url)
    end
    
    
    @testset "Typo in protocol" begin
        url = "htps://example.com"
        # Strange error if 
        # @test_throws "Unsupported protocol" HttpClient.get(url)
        @test_throws "Couldn't resolve proxy name" HttpClient.get(url)
    end
    
    
    @testset "No protocol" begin
        url = "example.com"
        @test HttpClient.get(url).status == 200
    end
    
    
    @testset "Headers" begin
        url = "https://reqbin.com/echo/get/json"
        headers = [
            "Content-Type" => "application/json",
            "User-Agent" => "http-julia"
        ]
        request = HttpClient.get(url; headers)
        @test caseless_key_check(request.headers, "Content-Type", "application/json")
    
        request = HttpClient.get(url; status_exception=false)
        @test caseless_key_check(request.headers, "Content-Type", "text/html; charset=UTF-8")
    end
    
    
    @testset "Query" begin
        url = "https://api.crossref.org/members"
        query = Dict("rows" => "0")
        url_with_query = "https://api.crossref.org/members?rows=0"
    
        request1 = HttpClient.get(url; query)
        request2 = HttpClient.get(url_with_query)
    
        @test request1.response == request2.response
    end
    
    
    @testset "Interface" begin
        interface = "0.0.0.0"
        url = "https://example.com"
    
        request = HttpClient.get(url; interface)
        @test request.status == 200
    end
    
    @testset "Timeout" begin
        reqres_test = reqres_test_get["get_delayed_response"]
        @test_throws "Timeout was reached" HttpClient.get(
            reqres_test.url;
            reqres_test.headers,
            reqres_test.query,
            reqres_test.interface,
            read_timeout = 1,
            retries = 0
        )
    
        request = HttpClient.get(
            reqres_test.url;
            reqres_test.headers,
            reqres_test.query,
            reqres_test.interface,
            read_timeout = 6,
            retries = 0
        )
        @test request.status == reqres_test.status
        @test JSON.parse(request.response) == JSON.parse(reqres_test.response)
    end
    
    
    for (name, reqres_test) in reqres_test_get
        @testset "$name" begin
            request = HttpClient.get(
                reqres_test.url;
                reqres_test.headers,
                reqres_test.query,
                reqres_test.interface,
                reqres_test.read_timeout,
                reqres_test.retries,
                status_exception=false
            )
    
            @test request.status == reqres_test.status
            @test JSON.parse(request.response) == JSON.parse(reqres_test.response)
        end
    end
    
    
    @testset "Large response" begin
        url = "https://play.clickhouse.com/play"
        request = HttpClient.get(url)
        @test length(request.response) > 10000
        @test request.status == 200
    end
    
    
    # @testset "Retries" begin
    #     url = "https://httpbin.org/get"
    #     read_timeout = 1
    #     retries = 2
    #     t = @elapsed @test_throws "read_timeout was reached" HttpClient.get(url; read_timeout, retries)
    #     @test read_timeout * (retries) < t < 2 * read_timeout * (retries + 1)
    # end
    
    @testset "Interface" begin
        @test_throws "TypeError" HttpClient.request(
            "get",
            "https://api.crossref.org/members";
            headers = Dict("User-Agent" => "http-julia")
        )

        headers = ["User-Agent" => "http-julia"]
        req = HttpClient.request("Get", "https://api.crossref.org/members";
            headers,
            query = ["rows=0"],
            body = nothing,
            connect_timeout = 10.2,
            read_timeout = 300.,
            interface = "0.0.0.0",
            proxy = "",
            retries = 10,
            status_exception = true,
            accept_encoding = "gzip",
            ssl_verifypeer = true
        )
        @test req.status == 200
    end

    @testset "Redirection" begin
        request = HttpClient.get("google.co")
        @test request.status == 200
    end

end # Get