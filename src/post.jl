"""
    post(url; <keyword arguments>) -> Request

Perform http post request and return [`Request`](@ref) object.
For supported arguments see [`request`](@ref) function.

# Example

## Successful registration
```julia
url = "https://reqres.in/api/register/"
headers = ["User-Agent" => "http-julia", "Content-Type" => "application/json"]
body = \"\"\"{
    "email": "eve.holt@reqres.in",
    "password": "pistol"
}\"\"\"
request = HttpClient.post(url; headers, body)

@test request.status == 200
@test request.response == "{\\"id\\":4,\\"token\\":\\"QpwL5tke4Pnpja7X4\\"}"
```

## Unsuccessful registration
```julia
url = "https://reqres.in/api/register/"
headers = ["User-Agent" => "http-julia", "Content-Type" => "application/json"]
body = \"\"\"{
    "email": "eve.holt@reqres.in"
}\"\"\" # remove password field
request = HttpClient.post(url; headers, body)

@test request.status == 400
@test request.response == "{\\"error\\":\\"Missing password\\"}"
```

## Clickhouse
```julia
url = "https://play.clickhouse.com/"
query = Dict("user" => "explorer")
headers = Dict("Content-Type" => "application/json", "User-Agent" => "http-julia")
body = "show databases"
request = HttpClient.post(url; query, headers, body)

@test request.status == 200
```
```julia-repl
julia> print(request.response)
blogs
default
git_clickhouse
mgbench
system
```
"""
post(
    url::AbstractString;
    headers = Pair{String, String}[],
    query = nothing,
    body = nothing,
    connect_timeout::Real = 60,
    read_timeout::Real = 300,
    interface::Union{String,Nothing} = nothing,
    proxy::Union{String,Nothing} = nothing,
    retries::Int64 = 1,
    status_exception::Bool = true,
    accept_encoding::String = "gzip",
    ssl_verifypeer::Bool = true,
) = request(
    "post",
    url;
    headers,
    query,
    body,
    connect_timeout,
    read_timeout,
    interface,
    proxy,
    retries,
    status_exception,
    accept_encoding,
    ssl_verifypeer
)