@testset "Put" begin
    
    for (name, reqres_test) in reqres_test_put
        @testset "$name" begin
            request = HttpClient.put(
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
            @test request.response >= reqres_test.response
        end
    end

end # Put