var documenterSearchIndex = {"docs":
[{"location":"websockets/","page":"Web Sockets","title":"Web Sockets","text":"CurrentModule = HttpClient","category":"page"},{"location":"websockets/#Web-sockets","page":"Web Sockets","title":"Web sockets","text":"","category":"section"},{"location":"websockets/","page":"Web Sockets","title":"Web Sockets","text":"Pages = [\"websockets.md\"]","category":"page"},{"location":"websockets/","page":"Web Sockets","title":"Web Sockets","text":"Modules = [HttpClient]\nPages = [\"web_sockets.jl\"]","category":"page"},{"location":"websockets/#HttpClient.Connection","page":"Web Sockets","title":"HttpClient.Connection","text":"Connection\n\nactive connection using web sockets\n\nsee also send, receive, isopen\n\nUsage\n\nconnection = open_connection(url; ...)\n# your code\nclose(connection)\n\nwebsocket(url; ...) do connection\n    # your code\nend\n\n\n\n\n\n","category":"type"},{"location":"websockets/#Base.close-Tuple{HttpClient.Connection}","page":"Web Sockets","title":"Base.close","text":"close(c::Connection)\n\nClose connection and cleanup.\n\n\n\n\n\n","category":"method"},{"location":"websockets/#Base.isopen-Tuple{HttpClient.Connection}","page":"Web Sockets","title":"Base.isopen","text":"isopen(c::Connection) -> Bool\n\n\n\n\n\n","category":"method"},{"location":"websockets/#HttpClient.open_connection-Tuple{Any}","page":"Web Sockets","title":"HttpClient.open_connection","text":"open_connection(url; headers, query, interface, timeout, retries) -> Connection\n\nConnect to a web socket server.\n\n\n\n\n\n","category":"method"},{"location":"websockets/#HttpClient.receive-Tuple{Any}","page":"Web Sockets","title":"HttpClient.receive","text":"receive(connection) -> data\n\nReceive message from web socket. Close connection on error.\n\n\n\n\n\n","category":"method"},{"location":"websockets/#HttpClient.send-Tuple{Any, Any}","page":"Web Sockets","title":"HttpClient.send","text":"send(connection, message)\n\nSend message to web socket. Close connection on error.\n\n\n\n\n\n","category":"method"},{"location":"websockets/#HttpClient.websocket-Tuple{Any, Any}","page":"Web Sockets","title":"HttpClient.websocket","text":"websocket(url; headers, query, interface, timeout, retries) -> Connection\n\nConnect to a web socket server, run handle on connection, then close connection.\n\nArguments\n\nhandle: function to call on open connection\nurl: a string containing url\nheaders: an iterable container of Pair{String, String}\nquery: an iterable container of Pair{String, String}\nconnect_timeout: abort request after read_timeout seconds\nread_timeout: unsupported\ninterface: outgoing network interface. Interface name, an IP address, or a host name.\nproxy: unsupported\n\nExample\n\nwebsocket(url; ...) do connection\n    # your code\nend\n\n\n\n\n\n","category":"method"},{"location":"http/","page":"HTTP requests","title":"HTTP requests","text":"CurrentModule = HttpClient","category":"page"},{"location":"http/#HTTP-requests","page":"HTTP requests","title":"HTTP requests","text":"","category":"section"},{"location":"http/","page":"HTTP requests","title":"HTTP requests","text":"Pages = [\"http.md\"]","category":"page"},{"location":"http/","page":"HTTP requests","title":"HTTP requests","text":"Modules = [HttpClient]\nPages = [\"get.jl\", \"post.jl\", \"delete.jl\", \"put.jl\", \"request.jl\"]","category":"page"},{"location":"http/#HttpClient.get-Tuple{AbstractString}","page":"HTTP requests","title":"HttpClient.get","text":"get(url; <keyword arguments>) -> Request\n\nPerform http get request and return Request object. For supported arguments see request function.\n\nExample\n\nreqbin.com\n\nheaders = [\n    \"Content-Type\" => \"application/json\", \n    \"User-Agent\" => \"http-julia\"\n]\nrequest = HttpClient.get(\"https://reqbin.com/echo/get/json\"; headers)\n@test request.status == 200\n@test request.response == \"{\\\"success\\\":\\\"true\\\"}\\n\"\n\nhttpbin.org\n\nquery = Dict{String,Any}(\"echo\" => \"你好嗎\")\nheaders = [\n    \"User-Agent\" => \"http-julia\",\n    \"Content-Type\" => \"application/json\",\n]\ninterface = \"0.0.0.0\"\nrequest = HttpClient.get(\"httpbin.org/get\"; \n    query, headers, interface, connect_timeout=30, retries=10)\n@test request.status == 200\n\n\n\n\n\n","category":"method"},{"location":"http/#HttpClient.post-Tuple{AbstractString}","page":"HTTP requests","title":"HttpClient.post","text":"post(url; <keyword arguments>) -> Request\n\nPerform http post request and return Request object. For supported arguments see request function.\n\nExample\n\nSuccessful registration\n\nurl = \"https://reqres.in/api/register/\"\nheaders = [\"User-Agent\" => \"http-julia\", \"Content-Type\" => \"application/json\"]\nbody = \"\"\"{\n    \"email\": \"eve.holt@reqres.in\",\n    \"password\": \"pistol\"\n}\"\"\"\nrequest = HttpClient.post(url; headers, body)\n\n@test request.status == 200\n@test request.response == \"{\\\"id\\\":4,\\\"token\\\":\\\"QpwL5tke4Pnpja7X4\\\"}\"\n\nUnsuccessful registration\n\nurl = \"https://reqres.in/api/register/\"\nheaders = [\"User-Agent\" => \"http-julia\", \"Content-Type\" => \"application/json\"]\nbody = \"\"\"{\n    \"email\": \"eve.holt@reqres.in\"\n}\"\"\" # remove password field\nrequest = HttpClient.post(url; headers, body)\n\n@test request.status == 400\n@test request.response == \"{\\\"error\\\":\\\"Missing password\\\"}\"\n\nClickhouse\n\nurl = \"https://play.clickhouse.com/\"\nquery = Dict(\"user\" => \"explorer\")\nheaders = Dict(\"Content-Type\" => \"application/json\", \"User-Agent\" => \"http-julia\")\nbody = \"show databases\"\nrequest = HttpClient.post(url; query, headers, body)\n\n@test request.status == 200\n\njulia> print(request.response)\nblogs\ndefault\ngit_clickhouse\nmgbench\nsystem\n\n\n\n\n\n","category":"method"},{"location":"http/#HttpClient.delete-Tuple{AbstractString}","page":"HTTP requests","title":"HttpClient.delete","text":"delete(url; <keyword arguments>) -> Request\n\nPerform http delete request and return Request object. For supported arguments see request function. \n\nExample\n\nurl = \"https://reqres.in/api/users/2\"\nheaders = [\"User-Agent\" => \"http-julia\", \"Content-Type\" => \"application/json\"]\nrequest = HttpClient.post(url; headers)\n\n@test request.status == 204\n@test request.response == \"\"\n\n\n\n\n\n","category":"method"},{"location":"http/#HttpClient.put-Tuple{AbstractString}","page":"HTTP requests","title":"HttpClient.put","text":"put(url; <keyword arguments>) -> Request\n\nPerform http put request and return Request object. For supported arguments see request function.\n\nExample\n\nurl = \"https://reqres.in/api/users/2\"\nheaders = [\"User-Agent\" => \"http-julia\", \"Content-Type\" => \"application/json\"]\nbody = \"\"\"{\n    \"name\": \"morpheus\",\n    \"job\": \"zion resident\"\n}\"\"\"\nrequest = HttpClient.put(url; headers, body)\n\n@test request.status == 200\n\njulia> print(request.response)\n{\"name\":\"morpheus\",\"job\":\"zion resident\",\"updatedAt\":\"2023-08-25T12:17:32.283Z\"}\n\n\n\n\n\n","category":"method"},{"location":"http/#HttpClient.Request","page":"HTTP requests","title":"HttpClient.Request","text":"struct Request\n    full_url::String\n    response::String\n    status::Int\n    headers::Dict{String, String}\nend\n\nStore full_url, status, response and headers of successful http request.\n\nExample\n\njulia> request = HttpClient.get(\"https://example.com\");\n\njulia> request.status\n200\njulia> typeof(request.response)\nString\njulia> length(request.response)\n1256\njulia> request.headers\nDict{String, String} with 11 entries:\n  \"Expires\"        => \"Fri, 01 Sep 2023 13:15:35 GMT\"\n  \"Etag\"           => \"\"3147526947+gzip+ident\"\"\n  \"Content-Length\" => \"1256\"\n  \"Last-Modified\"  => \"Thu, 17 Oct 2019 07:18:26 GMT\"\n  \"Date\"           => \"Fri, 25 Aug 2023 13:15:35 GMT\"\n  \"Age\"            => \"215050\"\n  \"Vary\"           => \"Accept-Encoding\"\n  \"X-Cache\"        => \"HIT\"\n  \"Cache-Control\"  => \"max-age=604800\"\n  \"Content-Type\"   => \"text/html; charset=UTF-8\"\n  \"Server\"         => \"ECS (dcb/7F83)\"\n\n\n\n\n\n","category":"type"},{"location":"http/#HttpClient.request-Tuple{AbstractString, AbstractString}","page":"HTTP requests","title":"HttpClient.request","text":"request(method::AbstractString, url::AbstractString, <keyword arguments>) -> Request\n\nSend a HTTP Request Message and receive a HTTP Response Message. For shortcuts see get, post, delete, put.\n\nExample\n\nHttpClient.request(\"get\", \"https://example.com\")\nHttpClient.get(\"https://example.com\")\n\nArguments\n\nmethod: get, post, put, delete\nurl: if no scheme, then https\nheaders: iterable container of Pair{String, String}\nquery: iterable container of Pair{String, String}\nbody: nothing or String\nconnect_timeout: unsupported\nread_timeout: abort request after read_timeout seconds\ninterface: outgoing network interface. Interface name, an IP address, or a host name.\nproxy: unsupported\nretries: number of tries to perform\nstatus_exception: raise an error if request status >= 300\naccept_encoding: unsupported\nssl_verifypeer: unsupported\n\n\n\n\n\n","category":"method"},{"location":"","page":"Home","title":"Home","text":"CurrentModule = HttpClient","category":"page"},{"location":"#HttpClient","page":"Home","title":"HttpClient","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Documentation for HttpClient.","category":"page"},{"location":"","page":"Home","title":"Home","text":"Pages = [\n    \"http.md\",\n    \"websockets.md\"\n]","category":"page"}]
}
