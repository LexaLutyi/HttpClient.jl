function set_delete(curl, what)
    request = strip("DELETE $(what)")
    @curlok curl_easy_setopt(curl, CURLOPT_CUSTOMREQUEST, request)
end


"""
    delete(url; headers, query, interface, timeout, retires, what) -> Request

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
function delete(url;
    headers = Dict{String, String}(), 
    query = Dict{String, String}(), 
    interface = "", 
    timeout = 0, 
    retries = 0,
    what = ""
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
    set_delete(curl, what)
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