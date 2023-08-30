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