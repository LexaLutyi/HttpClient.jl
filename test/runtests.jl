using HttpClient
using Test
using JSON
using Sockets
using WebSockets

# ENV["JULIA_DEBUG"] = "HttpClient"

include("reqres_tests.jl")


function caseless_key_check(dict, key, value)
    for (k, v) in dict
        if lowercase(k) == lowercase(key) && lowercase(v) == lowercase(value)
            return true
        end
    end
    return false
end

@testset "HttpClient.jl" begin
    

include("testsets/get.jl")
include("testsets/post.jl")
include("testsets/delete.jl")
include("testsets/put.jl")
include("testsets/async.jl")

# ! Don't work in git CI
# include("testsets/web_sockets.jl")

# ! Don't work in test environment

end
