struct Request
    response::String
    status::Int
    headers::Dict{String, String}
end


function Base.show(io::IO, r::Request)
    println(io, "HttpClient.Request")
    println(io, "  status = $(r.status)")
    println(io, "  response = \"\"\"$(r.response)\"\"\"")
    println(io, "  headers = $(r.headers)")
end