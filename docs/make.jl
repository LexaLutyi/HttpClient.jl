using HttpClient
using Documenter

DocMeta.setdocmeta!(HttpClient, :DocTestSetup, :(using HttpClient); recursive=true)

makedocs(;
    modules=[HttpClient],
    authors="Samarin Aleksei <liotbiu1@gmail.com> and contributors",
    repo="https://github.com/LexaLutyi/HttpClient.jl/blob/{commit}{path}#{line}",
    sitename="HttpClient.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://LexaLutyi.github.io/HttpClient.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/LexaLutyi/HttpClient.jl",
    devbranch="main",
)
