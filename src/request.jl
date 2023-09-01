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


@kwdef mutable struct RequestPointers
    easy_handle::Ptr{CURL} = C_NULL
    multi_handle::Ptr{CURLM} = C_NULL
    curl_url::Ptr{CURLU} = C_NULL
    function RequestPointers(easy_handle, multi_handle, curl_url)
        x = new(easy_handle, multi_handle, curl_url)
        finalizer(x) do x
            # ccall(:jl_safe_printf, Cvoid, (Cstring, Cstring), "Finalizing %s.\n", repr(x))
            if x.easy_handle != C_NULL
                curl_easy_cleanup(x.easy_handle)
            end
            if x.curl_url != C_NULL
                curl_url_cleanup(x.curl_url)
            end
            if x.multi_handle != C_NULL
                curl_multi_cleanup(x.multi_handle)
            end
        end
    end
end


function easy_init(rp::RequestPointers)
    rp.easy_handle = curl_easy_init()
    if rp.easy_handle == C_NULL
        error("HttpClient: Error initializing easy-handle")
    end
end


function multi_init(rp::RequestPointers)
    rp.multi_handle = curl_multi_init()
    if rp.multi_handle == C_NULL
        error("HttpClient: Error initializing multi-handle")
    end
end


function request(
    method::AbstractString,
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
)
    rp = RequestPointers()

    easy_init(rp)

    full_url = set_url(rp, url, query)
    response = set_response(rp.easy_handle)
    set_headers(rp.easy_handle, headers)
    set_interface(rp.easy_handle, interface)
    set_timeout(rp.easy_handle, connect_timeout)
    set_ssl(rp.easy_handle)

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

    perform(rp, connect_timeout, retries)

    http_code = get_http_code(rp.easy_handle)
    response_string = response_as_string(response)
    headers = get_headers(rp.easy_handle)

    Request(full_url, response_string, http_code, headers)
end