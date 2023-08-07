using Clang.Generators
# using libcurl_jll

cd(@__DIR__)
include_dir = normpath(, "include")

# wrapper generator options
options = load_options(joinpath(@__DIR__, "generator.toml"))

# add compiler flags, e.g. "-DXXXXXXXXX"
args = get_default_args()
push!(args, "-I$include_dir")

# only wrap libclang headers in include/clang-c
header_dir = joinpath(include_dir, "curl")
headers = [joinpath(header_dir, header) for header in readdir(header_dir) if endswith(header, "curl.h")]
# headers = detect_headers(header_dir, args)
# create context
ctx = create_context(headers, args, options)

# run generator
# build!(ctx)