@testset "Post" begin
    
    @testset "200" begin
        url = "https://reqbin.com/echo/post/json"
        headers = Dict("Content-Type" => "application/json", "User-Agent" => "http-julia")
        body = """
        {
            "Id": 12345,
            "Customer": "John Smith",
            "Quantity": 1,
            "Price": 10.00
        }
        """
        request = HttpClient.post(url; headers, body)
        @test request.status == 200
        @test request.response == "{\"success\":\"true\"}\n"
        # @test request.headers["Content-Type"] == "application/json"
        @test caseless_key_check(request.headers, "Content-Type", "application/json")
        # @test request.headers["Content-Length"] == "19"
        @test caseless_key_check(request.headers, "Content-Length", "19")
    end
    
    @testset "clickhouse" begin
        url = "https://play.clickhouse.com/"
        query = Dict("user" => "explorer")
        headers = Dict("Content-Type" => "application/json", "User-Agent" => "http-julia")
        body = "show databases"
    
        databases = """
    blogs
    default
    git_clickhouse
    mgbench
    system
    """
    
        request = HttpClient.post(url; query, headers, body)
        @test request.status == 200
        @test request.response == databases
    end
    
    for (name, reqres_test) in reqres_test_post
        @testset "$name" begin
            request = HttpClient.post(
                reqres_test.url;
                reqres_test.headers,
                reqres_test.query,
                reqres_test.interface,
                reqres_test.timeout,
                reqres_test.retries,
                body = reqres_test.body
            )
    
            @test request.status == reqres_test.status
            if name != "post_create"
                @test JSON.parse(request.response) == JSON.parse(reqres_test.response)
            end
        end
    end
    
end # Post