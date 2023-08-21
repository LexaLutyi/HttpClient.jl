using HttpClient
using LibCURL2
using Test

@testset "Get" begin

@testset "200" begin
    url = "https://example.com"
    url_bkp = deepcopy(url)
    request = HttpClient.get(url)

    @test typeof(request.response) == String
    @test length(request.response) > 0

    @test request.status == 200

    @test request.headers["Content-Type"] == "text/html; charset=UTF-8"

    @test url == url_bkp
end


@testset "404" begin
    url = "https://www.google.com/404"
    url_bkp = deepcopy(url)
    request = HttpClient.get(url)

    @test typeof(request.response) == String
    @test length(request.response) > 0

    @test request.status == 404

    @test request.headers["Content-Type"] == "text/html; charset=UTF-8"

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
    @test request.headers["Content-Type"] == "application/json"

    request = HttpClient.get(url)
    @test request.headers["Content-Type"] == "text/html; charset=UTF-8"
end


@testset "Query" begin
    url = "https://api.crossref.org/members"
    query = Dict("rows" => "0")
    url_with_query = "https://api.crossref.org/members?rows=0"

    request1 = HttpClient.get(url; query)
    request2 = HttpClient.get(url_with_query)

    @test request1.response == request2.response
end

# ! long and unstable results
# @testset "Get with query: httpbin.org" begin
#     url = "https://httpbin.org/get?echo=%E4%BD%A0%E5%A5%BD%E5%97%8E"
#     headers = Dict(
#         "Accept" => "application/json",
#         "User-Agent" => "http-julia"
#     )
#     request = HttpClient.get(url; headers)
#     @test request.headers["Content-Type"] == "application/json"

#     url2 = "https://httpbin.org/get"
#     query = Dict(
#         "echo" => "你好嗎"
#     )
#     request2 = HttpClient.get(url2; headers, query)
#     @test request == request2
# end


@testset "Interface" begin
    interface = "0.0.0.0"
    url = "https://example.com"

    request = HttpClient.get(url; interface)
    @test request.status == 200
end

@testset "Timeout" begin
    url = "https://httpbin.org/get"
    timeout = 1
    request_time = @elapsed try
        request = HttpClient.get(url; timeout)
    catch e
        if e != ErrorException("Timeout was reached")
            error(e)
        end
    end
    @test request_time <= timeout + 1
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
    @test request.headers["Content-Type"] == "application/json"
    @test request.headers["Content-Length"] == "19"
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

end # Post