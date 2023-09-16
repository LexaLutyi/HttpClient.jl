"""
```
struct Request
    full_url::String
    response::String
    status::Int
    headers::Dict{String, String}
end
```
Store full_url, status, response and headers of successful http request.

Example
```julia-repl
julia> request = HttpClient.get("https://example.com");

julia> request.status
200
julia> typeof(request.response)
String
julia> length(request.response)
1256
julia> request.headers
Dict{String, String} with 11 entries:
  "Expires"        => "Fri, 01 Sep 2023 13:15:35 GMT"
  "Etag"           => "\"3147526947+gzip+ident\""
  "Content-Length" => "1256"
  "Last-Modified"  => "Thu, 17 Oct 2019 07:18:26 GMT"
  "Date"           => "Fri, 25 Aug 2023 13:15:35 GMT"
  "Age"            => "215050"
  "Vary"           => "Accept-Encoding"
  "X-Cache"        => "HIT"
  "Cache-Control"  => "max-age=604800"
  "Content-Type"   => "text/html; charset=UTF-8"
  "Server"         => "ECS (dcb/7F83)"
```
"""
struct Request
    full_url::String
    response::String
    status::Int
    headers::Dict{String, String}
end


function Base.show(io::IO, r::Request)
    println(io, "HttpClient.Request")
    println(io, "  url = $(r.full_url)")
    println(io, "  status = $(r.status)")
    println(io, "  response = \"\"\"\n$(r.response)\n\"\"\"")
    println(io, "  headers = $(r.headers)")
end


"""
    request(method::AbstractString, url::AbstractString, <keyword arguments>) -> Request
Send a HTTP Request Message and receive a HTTP Response Message.
For shortcuts see [`get`](@ref), [`post`](@ref), [`delete`](@ref), [`put`](@ref).

# Example
```julia
HttpClient.request("get", "https://example.com")
HttpClient.get("https://example.com")
```
# Arguments
* `method`: get, post, put, delete
* `url`: default scheme is https
* `headers::Vector{Pair{String, String}} = []`
* `query = nothing`: a full query string or container of key-value pairs
* `body`: `nothing` or `String`
* `connect_timeout`: unsupported
* `read_timeout`: abort request after `read_timeout` seconds
* `interface`: outgoing network interface. Interface name, an IP address, or a host name.
* `proxy`: unsupported
* `retries`: number of tries to perform
* `status_exception`: raise an error if request status >= 300
* `accept_encoding`: unsupported
* `ssl_verifypeer`: unsupported
"""
function request(
    method::AbstractString,
    url::AbstractString;
    headers::Vector{Header} = Header[],
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
)
    rp = RequestPointers()

    easy_init(rp)

    full_url = set_url(rp, url, query)
    response = set_response(rp.easy_handle)
    set_headers(rp, headers)
    set_interface(rp.easy_handle, interface)
    set_timeout(rp.easy_handle, read_timeout)
    set_ssl(rp.easy_handle)
    set_follow_location(rp.easy_handle)

    if lowercase(method) == "post"
        set_body(rp.easy_handle, body)
    elseif lowercase(method) == "put"
        set_body(rp.easy_handle, body)
        set_put(rp.easy_handle)
    elseif lowercase(method)== "delete"
        set_delete(rp.easy_handle, body)
    elseif lowercase(method) == "get"
        # nothing
    else
        error("HttpClient: unsupported method")
    end

    perform(rp, read_timeout, retries)

    http_code = get_http_code(rp.easy_handle)
    response_string = response_as_string(response)

    if status_exception && http_code >= 300
        error(
            "StatusError: ", http_code, 
            ". Full url: ", full_url,
            ". Response: ", response_string
        )
    end

    headers = get_headers(rp.easy_handle)

    Request(full_url, response_string, http_code, headers)
end