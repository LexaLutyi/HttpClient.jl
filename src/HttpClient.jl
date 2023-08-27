module HttpClient

using LibCURL2
# using LibCURL_jll

include("curl_error.jl")
include("request.jl")
include("response.jl")

include("header.jl")
include("query.jl")
include("interface.jl")
include("timeout.jl")
include("data.jl")
include("ssl.jl")

include("get.jl")
include("post.jl")
include("delete.jl")
include("put.jl")

end
