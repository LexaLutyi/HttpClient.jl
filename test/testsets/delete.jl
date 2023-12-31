@testset "Delete" begin

    @testset "reqbin.com" begin
        url = "https://reqbin.com/echo/delete/json"
        headers = [
            "Content-Type" => "application/json", 
            "User-Agent" => "http-julia"
        ]
        request = HttpClient.delete(url; headers)
        @test request.status == 200
        @test request.response == "{\"success\":\"true\"}\n"
    end

    @testset "play.clickhouse.com" begin
        url = "https://play.clickhouse.com/"
        headers = [
            "Content-Type" => "application/json", 
            "User-Agent" => "http-julia"
        ]
        request = HttpClient.delete(url; 
            headers, 
            body = "play",
            status_exception = false
        )
        @test request.status == 501
        @test request.response == ""
    end

    for (name, reqres_test) in reqres_test_delete
        @testset "$name" begin
            request = HttpClient.delete(
                reqres_test.url;
                reqres_test.headers,
                reqres_test.query,
                reqres_test.interface,
                reqres_test.read_timeout,
                reqres_test.retries,
                body = reqres_test.what_to_delete,
                status_exception = false
            )
    
            @test request.status == reqres_test.status
            @test request.response == reqres_test.response
        end
    end

end # Delete