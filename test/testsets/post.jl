@testset "Post" begin
    
    @testset "200" begin
        url = "https://reqbin.com/echo/post/json"
        headers = [
            "Content-Type" => "application/json", 
            "User-Agent" => "http-julia"
        ]
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
        headers = [
            "Content-Type" => "application/json", 
            "User-Agent" => "http-julia"
        ]
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
                reqres_test.read_timeout,
                reqres_test.retries,
                body = reqres_test.body,
                status_exception = false
            )
    
            @test request.status == reqres_test.status
            if name == "post_create: body is nothing"
                continue
            end
            A = JSON.parse(request.response)
            B = JSON.parse(reqres_test.response)
            for key in keys(B)
                if key == "createdAt"
                    @test A[key] >= B[key]
                elseif key == "id"
                    nothing
                else
                    @test A[key] == B[key]
                end
            end
        end
    end
    
end # Post