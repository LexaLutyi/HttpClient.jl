function get_http_code(curl)
    http_code = Array{Clong}(undef, 1)
    @curlok curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, http_code)
    http_code[1]
end


"""
    get(url; headers, query, interface, timeout, retries) -> Request

Perform http get request and return [`Request`](@ref) object.

# Example
```julia
headers = [
    "Content-Type" => "application/json", 
    "User-Agent" => "http-julia"
]
request = HttpClient.get("https://reqbin.com/echo/get/json"; headers)
@test request.status == 200
@test request.response == "{\\"success\\":\\"true\\"}\\n"
```
"""
function get(url; 
    headers = Dict{String, String}(), 
    query = Dict{String, String}(), 
    interface = "", 
    timeout = 0, 
    retries = 0
    )
    
    curl = curl_easy_init()
    full_url = set_url(curl, url, query)

    # ! How to test this?
    # curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1)

    response = set_response(curl)
    set_headers(curl, headers)
    set_interface(curl, interface)
    set_timeout(curl, timeout)
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

    Request(full_url, response_string, http_code, headers)
end