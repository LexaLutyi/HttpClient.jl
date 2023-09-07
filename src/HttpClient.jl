module HttpClient

using CodecZlib
using LibCURL2

include("curl_error.jl")
include("request.jl")
include("response.jl")

include("header.jl")
include("query.jl")
include("interface.jl")
include("timeout.jl")
include("body.jl")
include("ssl.jl")
include("perform.jl")

include("get.jl")
include("post.jl")
include("delete.jl")
include("put.jl")

include("compression.jl")
include("web_sockets.jl")

function __init__()
    @curlok curl_global_init(CURL_GLOBAL_ALL)
end

end
