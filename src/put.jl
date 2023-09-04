function set_put(curl)
    @curlok curl_easy_setopt(curl, CURLOPT_CUSTOMREQUEST, "PUT")
end


"""
    put(url; <keyword arguments>) -> Request

Perform http put request and return [`Request`](@ref) object.
For supported arguments see [`request`](@ref) function.

# Example

```julia
url = "https://reqres.in/api/users/2"
headers = ["User-Agent" => "http-julia", "Content-Type" => "application/json"]
body = \"\"\"{
    "name": "morpheus",
    "job": "zion resident"
}\"\"\"
request = HttpClient.put(url; headers, body)

@test request.status == 200
```
```julia-repl
julia> print(request.response)
{"name":"morpheus","job":"zion resident","updatedAt":"2023-08-25T12:17:32.283Z"}
```
"""
put(
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
    "put",
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