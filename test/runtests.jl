using HttpClient
using LibCURL
using Test

function setup_curl_for_reading(url = "https://example.com")
    curl = curl_easy_init()
    curl_easy_setopt(curl, CURLOPT_URL, url)
    res = curl_easy_perform(curl)
    if res != CURLE_OK
        curl_error = unsafe_string(curl_easy_strerror(res))
        error(curl_error)
    end
    curl
end

@testset begin


@testset "Get: example.com" begin
    url = "https://example.com"
    url_bkp = deepcopy(url)
    request = HttpClient.get(url)

    @test typeof(request.response) == String
    @test length(request.response) > 0

    @test request.status == 200

    @test request.headers["Content-Type"] == "text/html; charset=UTF-8"

    @test url == url_bkp
end


@testset "Get: 404" begin
    url = "https://www.google.com/404"
    url_bkp = deepcopy(url)
    request = HttpClient.get(url)

    @test typeof(request.response) == String
    @test length(request.response) > 0

    @test request.status == 404

    @show request.headers["Content-Type"] == "text/html; charset=UTF-8"

    @test url == url_bkp
end


@testset "Get: url doesn't exist" begin
    url = "https://example.co"
    @test_throws "Couldn't resolve host name" HttpClient.get(url)
end


@testset "Get: typo in protocol" begin
    url = "htps://example.com"
    @test_throws "Unsupported protocol" HttpClient.get(url)
end


@testset "Headers" begin
    prev = Ptr{HttpClient.CurlHeader}(0)
    @test prev == C_NULL
    curl = setup_curl_for_reading()
    next_header_ptr = HttpClient.curl_easy_nextheader(curl, HttpClient.CURLH_HEADER, 0, prev)
    @test next_header_ptr != C_NULL
    next_header = unsafe_load(next_header_ptr)
    @test typeof(next_header) == HttpClient.CurlHeader

    c_headers = HttpClient.extract_c_headers(curl)
    @test typeof(c_headers) == Vector{HttpClient.CurlHeader}
    @test length(c_headers) > 0

    headers = c_headers .|> HttpClient.name_and_value |> Dict
    @test headers["Content-Type"] == "text/html; charset=UTF-8"
    @test headers["Content-Length"] == "1256"

    @test headers == HttpClient.extract_headers(curl)
end


end