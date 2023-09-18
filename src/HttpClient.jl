module HttpClient

using CodecZlib
using LibCURL2

const Header = Pair{String,String}

include("curl_error.jl")

include("request_pointers.jl")
include("response.jl")
include("query.jl")

include("set_options.jl")
include("get_options.jl")

include("perform.jl")

include("request.jl")
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
