using HttpClient
using Test
using JSON

include("reqres_tests.jl")


function caseless_key_check(dict, key, value)
    for (k, v) in dict
        if lowercase(k) == lowercase(key) && lowercase(v) == lowercase(value)
            return true
        end
    end
    return false
end


@testset "Get" begin

@testset "200" begin
    url = "https://example.com"
    url_bkp = deepcopy(url)
    request = HttpClient.get(url)

    @test typeof(request.response) == String
    @test length(request.response) > 0

    @test request.status == 200

    # @test request.headers["Content-Type"] == "text/html; charset=UTF-8"
    @test caseless_key_check(request.headers, "Content-Type", "text/html; charset=UTF-8")

    @test url == url_bkp
end


@testset "404" begin
    url = "https://www.google.com/404"
    url_bkp = deepcopy(url)
    request = HttpClient.get(url)

    @test typeof(request.response) == String
    @test length(request.response) > 0

    @test request.status == 404

    # @test request.headers["Content-Type"] == "text/html; charset=UTF-8"
    @test caseless_key_check(request.headers, "Content-Type", "text/html; charset=UTF-8")

    @test url == url_bkp
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
    # TODO should work without protocol or raise meaningful error
    @test_throws "Out of memory" HttpClient.get(url)
end


@testset "Headers" begin
    url = "https://reqbin.com/echo/get/json"
    headers = Dict(
        "Content-Type" => "application/json",
        "User-Agent" => "http-julia"
    )
    request = HttpClient.get(url; headers)
    @test caseless_key_check(request.headers, "Content-Type", "application/json")
    # @test request.headers["Content-Type"] == "application/json"

    request = HttpClient.get(url)
    @test caseless_key_check(request.headers, "Content-Type", "text/html; charset=UTF-8")
    # @test request.headers["Content-Type"] == "text/html; charset=UTF-8"
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
        timeout = 1,
        retries = 0
    )

    request = HttpClient.get(
        reqres_test.url;
        reqres_test.headers,
        reqres_test.query,
        reqres_test.interface,
        timeout = 4,
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
            reqres_test.timeout,
            reqres_test.retries
        )

        @test request.status == reqres_test.status
        @test JSON.parse(request.response) == JSON.parse(reqres_test.response)
    end
end


# @testset "Retries" begin
#     url = "https://httpbin.org/get"
#     timeout = 1
#     retries = 2
#     t = @elapsed @test_throws "Timeout was reached" HttpClient.get(url; timeout, retries)
#     @test timeout * (retries) < t < 2 * timeout * (retries + 1)
# end

end # Get


@testset "Post" begin
    
@testset "200" begin
    url = "https://reqbin.com/echo/post/json"
    headers = Dict("Content-Type" => "application/json", "User-Agent" => "http-julia")
    data = """
    {
        "Id": 12345,
        "Customer": "John Smith",
        "Quantity": 1,
        "Price": 10.00
    }
    """
    request = HttpClient.post(url; headers, data)
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
    data = "show databases"

    databases = """
blogs
default
git_clickhouse
mgbench
system
"""

    request = HttpClient.post(url; query, headers, data)
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
            data = reqres_test.body
        )

        @test request.status == reqres_test.status
        if name != "post_create"
            @test JSON.parse(request.response) == JSON.parse(reqres_test.response)
        end
    end
end

end # Post


@testset "Delete" begin

    @testset "reqbin.com" begin
        url = "https://reqbin.com/echo/delete/json"
        headers = Dict("Content-Type" => "application/json", "User-Agent" => "http-julia")
        request = HttpClient.delete(url; headers)
        @test request.status == 200
        @test request.response == "{\"success\":\"true\"}\n"
    end

    @testset "play.clickhouse.com" begin
        url = "https://play.clickhouse.com/"
        headers = Dict("Content-Type" => "application/json", "User-Agent" => "http-julia")
        request = HttpClient.delete(url; headers, what = "play")
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
                reqres_test.timeout,
                reqres_test.retries,
                what = reqres_test.what_to_delete
            )
    
            @test request.status == reqres_test.status
            @test request.response == reqres_test.response
        end
    end

end # Delete


@testset "Put" begin
    
    for (name, reqres_test) in reqres_test_put
        @testset "$name" begin
            request = HttpClient.put(
                reqres_test.url;
                reqres_test.headers,
                reqres_test.query,
                reqres_test.interface,
                reqres_test.timeout,
                reqres_test.retries,
                data = reqres_test.body
            )
    
            @test request.status == reqres_test.status
            @test request.response >= reqres_test.response
        end
    end

end # Put