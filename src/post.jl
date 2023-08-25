"""
    post(url; headers, query, interface, timeout, retires, body) -> Request

Perform http post request and return [`Request`](@ref) object.

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
function post(url; 
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