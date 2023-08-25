function set_put(curl)
    @curlok curl_easy_setopt(curl, CURLOPT_CUSTOMREQUEST, "PUT")
end


"""
    put(url; headers, query, interface, timeout, retires, body) -> Request

Perform http put request and return [`Request`](@ref) object.

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
function put(url; 
    headers = Dict{String, String}(), 
    query = Dict{String, String}(),
    body = "", 
    interface = "", 
    timeout = 0, 
    retries = 0
    )
    
    c_url = set_query(url, query)
    curl = curl_easy_init()
    @curlok curl_easy_setopt(curl, CURLOPT_CURLU, c_url)

    # ! How to test this?
    # curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1)

    response = set_response(curl)
    set_headers(curl, headers)
    set_interface(curl, interface)
    set_timeout(curl, timeout)
    set_data(curl, body)
    set_put(curl)
    set_ssl(curl)

    retry(
        curl -> HttpClient.@curlok(curl_easy_perform(curl)); 
        delays=fill(timeout, retries)
    )(curl)

    http_code = get_http_code(curl)
    response_string = response_as_string(response)
    headers = get_headers(curl)

    # ! How to test this?
    # curl_easy_cleanup(curl)

    Request(response_string, http_code, headers)
end