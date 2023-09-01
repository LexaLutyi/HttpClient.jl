function set_delete(curl, what)
    what = isnothing(what) ? "" : what
    request = strip("DELETE $(what)")
    @curlok curl_easy_setopt(curl, CURLOPT_CUSTOMREQUEST, request)
end


"""
    delete(url; headers, query, interface, timeout, retries, what) -> Request

Perform http delete request and return [`Request`](@ref) object.

# Example
```julia
url = "https://reqres.in/api/users/2"
headers = ["User-Agent" => "http-julia", "Content-Type" => "application/json"]
request = HttpClient.post(url; headers)

@test request.status == 204
@test request.response == ""
```
"""
delete(
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
    "delete",
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