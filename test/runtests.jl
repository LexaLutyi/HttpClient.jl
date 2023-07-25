using HttpClient
using Test

@testset "HttpClient.jl" begin
    t = @ccall clock()::Int32
    @show t
end
