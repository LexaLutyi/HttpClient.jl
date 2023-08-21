module HttpClient

using LibCURL2
using LibCURL_jll

include("request.jl")
include("header.jl")
include("query.jl")
include("get.jl")

end
