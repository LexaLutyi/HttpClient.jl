function decompress(deflate_message::AbstractVector{UInt8})
    # add some magic bytes, taken from WebSockets.jl
    append!(deflate_message, [0x00, 0x00, 0xff, 0xff, 0x03, 0x00])
    return transcode(DeflateDecompressor, deflate_message)
end

decompress(deflate_message::AbstractString) = decompress(Vector{UInt8}(deflate_message))
