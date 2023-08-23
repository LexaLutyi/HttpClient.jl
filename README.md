# HttpClient

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://LexaLutyi.github.io/HttpClient.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://LexaLutyi.github.io/HttpClient.jl/dev/)
[![Build Status](https://github.com/LexaLutyi/HttpClient.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/LexaLutyi/HttpClient.jl/actions/workflows/CI.yml?query=branch%3Amain)

### Быстрый старт

  - ~~[Atom IDE](https://atom.io/) + [Juno](https://junolab.org/)~~ or [VS Code](https://www.julia-vscode.org/)
  - [Julia Download](https://julialang.org/downloads/)
  - [Julia Documentation](https://docs.julialang.org/en/v1/)
  - [Julia Packages](https://juliapackages.com/)
  - [Blue Style](https://github.com/invenia/BlueStyle) 

### Описание

Выберите небольшую клиентскую HTTP-библиотеку, написанную на языке C, и оберните ее на языке Julia, чтобы она поддерживала использование основных методов HTTP (GET, POST, DELETE, PUT) для выполнения запросов к веб-серверам HTTP, а также вебсокетный протокол для передачи и приема сообщений. Примеры интерфейса приведены ниже

### Требования к документации

1. Описание функций, включая список параметров, возвращаемое значение и возможные ошибки
2. Примеры использования функций с описанием входных и выходных данных
3. Установку и настройку библиотеки

### Тестирование

1. Соответствие стандартам HTTP
2. Функциональное тестирование
3. Тестирование производительности
4. Покрытие тестами не ниже 30%

##### Пример юзер API, для GET, POST запросов

```julia
using JSON
using LibCHTTP

# query: Query parameters
# headers: Array of key-value pairs representing HTTP headers
# body: Request body data
# interface: The network interface to use for making the request
# read_timeout: The maximum time to wait for a response from the server
# retries: The number of times to retry the request in case of a failure
# status_exception: Boolean indicating whether to raise an exception for non-200 status codes

query = Dict{String,Any}(
    "echo" => "你好嗎"
)

headers = Pair{String,String}[
    "User-Agent" => "http-julia",
    "Content-Type" => "application/json",
]

body = JSON.json(Dict{String,Any}(
    "echo" => "hi"
))

interface = "0.0.0.0"

# POST
req = LibCHTTP.request("POST", "httpbin.org/post", body = JSON.json(body), query = query,
    headers = headers, interface = interface, read_timeout = 5, retries = 10)

req.status
String(req.body)

# GET
req = LibCHTTP.request("GET", "httpbin.org/get", query = "echo=你好嗎",
    headers = headers, interface = interface, read_timeout = 30, retries = 10)

julia> req.status
200

julia> String(req.body)
{
  "args": {
    "echo": "你好嗎"
  }, 
  "headers": {
    "Accept": "*/*", 
    "Content-Type": "application/json", 
    "Host": "httpbin.org", 
    "User-Agent": "http-julia", 
    "X-Amzn-Trace-Id": "Root=1-6478428f-4790f09856daac6d73ebf5c0"
  }, 
  "origin": "100.187.179.40", 
  "url": "http://httpbin.org/get?echo=你好嗎"
}

# Bad Request

julia> req = LibCHTTP.request("GET", "httpbin.org/status/400", query = query,
    headers = headers, interface = interface, read_timeout = 10.5, retries = 10)
ERROR: LibCHTTP.StatusError("Bad Request", HTTP Status: 400)

req = LibCHTTP.request("GET", "httpbin.org/status/400", query = query,
    headers = headers, interface = interface, read_timeout = 10.5, retries = 10, status_exception = false)

julia> req.status
502
```

##### Пример юзер API, для WebSocket

```julia
using JSON
using LibCHTTP

LibCHTTP.WebSockets.open(
    "wss://stream.binance.com:9443/stream?streams=adausdt@depth20@100ms/btcusdt@depth20@100ms",
    headers = [
        "sec-websocket-extensions" => "permessage-deflate"
    ],
    read_timeout = 60,
) do connection
    LibCHTTP.WebSockets.send(connection, "Hello Binance!")

    while isopen(connection)
        data = LibCHTTP.WebSockets.recv(connection)
        data |> String |> JSON.parse |> println
    end
end

{
  "stream": "btcusdt@depth20@100ms",
  "data": {
    "lastUpdateId": 37084267997,
    "asks": [
      [
        "26803.16000000",
        "2.83684000"
      ],
      [
        "26803.17000000",
        "0.09562000"
      ],
      [
        "26803.19000000",
        "1.46067000"
      ],
      [
        "26803.23000000",
        "0.14172000"
      ],
      ...
    ],
    "bids": [
      [
        "26803.15000000",
        "10.51675000"
      ],
      [
        "26803.09000000",
        "0.01658000"
      ],
      [
        "26803.03000000",
        "0.01851000"
      ],
      ...
    ]
  }
}
```

##### Пример юзер API, для HTTP сервера

```julia
function handle(connection::Connection{Socket})
    while !eof(connection)
        try
            msg::Vector{UInt8} = recv(connection)
            # handle message 
            send(connection, "hi")
        catch e
            #...
        end 
    end
end

function handle(connection::Connection{Http})
    try
        msg::Vector{UInt8} = http_recv(connection)
        # handle message 
        http_status(connection, 300)
        http_header(connection, "300")
        http_send(connection, "referrer-policy", "origin-when-cross-origin")
    catch e
        #...
    end
end

LibCHTTP.server(server_host, server_port) do http_message
    if LibCHTTP.WebSockets.isupgrade(http_message)
        try
            LibCHTTP.WebSockets.upgrade(http_message) do websocket
                return handle(Connection{Socket}(websocket))
            end
        catch e
            @error "reading websocket client stream failed" exception =
                (e, stacktrace(catch_backtrace()))
        end
    else
        handle(Connection{Http}(http_message))
    end
end
```
