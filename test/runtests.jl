using HttpClient
using JSON
using Sockets
using Test

# ENV["JULIA_DEBUG"] = "HttpClient"

function caseless_key_check(dict, key, value)
    for (k, v) in dict
        if lowercase(k) == lowercase(key) && lowercase(v) == lowercase(value)
            return true
        end
    end
    return false
end

@testset "HttpClient.jl" begin

    include("reqres_tests.jl")

    include("testsets/get.jl")
    include("testsets/post.jl")
    include("testsets/delete.jl")
    include("testsets/put.jl")
    include("testsets/async.jl")

    # ! Binance tests don't work in git CI.
    # include("testsets/web_sockets.jl")
end
