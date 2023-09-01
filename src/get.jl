function get_http_code(curl)
    http_code = Array{Clong}(undef, 1)
    @curlok curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, http_code)
    http_code[1]
end


"""
    get(url; headers, query, interface, timeout, retries) -> Request

Perform http get request and return [`Request`](@ref) object.

# Example 
## reqbin.com
```julia
headers = [
    "Content-Type" => "application/json", 
    "User-Agent" => "http-julia"
]
request = HttpClient.get("https://reqbin.com/echo/get/json"; headers)
@test request.status == 200
@test request.response == "{\\"success\\":\\"true\\"}\\n"
```
## httpbin.org
```julia
query = Dict{String,Any}("echo" => "你好嗎")
headers = [
    "User-Agent" => "http-julia",
    "Content-Type" => "application/json",
]
interface = "0.0.0.0"
request = HttpClient.get("httpbin.org/get"; 
    query, headers, interface, timeout=30, retries=10)
@test request.status == 200
```
"""
get(
    url::AbstractString;
    headers = Pair{String, String}[],
    query = nothing,
    connect_timeout::Real = 60,
    read_timeout::Real = 300,
    interface::Union{String,Nothing} = nothing,
    proxy::Union{String,Nothing} = nothing,
    retries::Int64 = 1,
    status_exception::Bool = true,
    accept_encoding::String = "gzip",
    ssl_verifypeer::Bool = true,
) = request(
    "get",
    url;
    headers,
    query,
    connect_timeout,
    read_timeout,
    interface,
    proxy,
    retries,
    status_exception,
    accept_encoding,
    ssl_verifypeer
)