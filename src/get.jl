"""
    get(url; <keyword arguments>) -> Request

Perform http get request and return [`Request`](@ref) object.
For supported arguments see [`request`](@ref) function.

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
    query, headers, interface, connect_timeout=30, retries=10)
@test request.status == 200
```
"""
function get(
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
    )
    req = request(
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
    return req
end