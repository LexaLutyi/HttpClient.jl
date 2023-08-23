include("reqres_responses.jl")

@kwdef struct ReqresTest
    url::String
    headers::Dict{String, String} = Dict()
    query::Dict{String, String} = Dict()
    interface::String = ""
    timeout::Int = 0
    retries::Int = 0
    body::String = ""
    what_to_delete = ""

    status::Int
    response::String
end

headers = Dict(
    "Content-Type" => "application/json",
    "User-Agent" => "http-julia"
)

reqres_test_get = Dict{String, ReqresTest}()

reqres_test_get["get_list_users"] = ReqresTest(;
    url = "https://reqres.in/api/users",
    query = Dict("page" => "2"),
    headers,
    status = 200,
    response = get_list_users
)


reqres_test_get["get_single_user"] = ReqresTest(;
    url = "https://reqres.in/api/users/2",
    headers,
    status = 200,
    response = get_single_user
)


reqres_test_get["get_single_user_not_found"] = ReqresTest(;
    url = "https://reqres.in/api/users/23",
    headers,
    status = 404,
    response = get_single_user_not_found
)


reqres_test_get["get_list_resource"] = ReqresTest(;
    url = "https://reqres.in/api/unknown",
    headers,
    status = 200,
    response = get_list_resource
)


reqres_test_get["get_single_resource"] = ReqresTest(;
    url = "https://reqres.in/api/unknown/2",
    headers,
    status = 200,
    response = get_single_resource
)


reqres_test_get["get_single_resource_not_found"] = ReqresTest(;
    url = "https://reqres.in/api/unknown/23",
    headers,
    status = 404,
    response = get_single_resource_not_found
)


reqres_test_get["get_delayed_response"] = ReqresTest(;
    url = "https://reqres.in/api/users",
    headers,
    query = Dict("delay" => "3"),
    status = 200,
    response = get_delayed_response
)


reqres_test_post = Dict{String, ReqresTest}()

reqres_test_post["post_create"] = ReqresTest(;
    url = "https://reqres.in/api/users",
    headers,
    status = 201,
    response = post_create_response,
    body = post_create_body
)

reqres_test_post["post_register_successful"] = ReqresTest(;
    url = "https://reqres.in/api/register",
    headers,
    status = 200,
    response = post_register_successful_response,
    body = post_register_successful_body
)

reqres_test_post["post_register_unsuccessful"] = ReqresTest(;
    url = "https://reqres.in/api/register",
    headers,
    status = 400,
    response = post_register_unsuccessful_response,
    body = post_register_unsuccessful_body
)

reqres_test_post["post_login_successful"] = ReqresTest(;
    url = "https://reqres.in/api/login",
    headers,
    status = 200,
    response = post_login_successful_response,
    body = post_login_successful_body
)

reqres_test_post["post_login_unsuccessful"] = ReqresTest(;
    url = "https://reqres.in/api/login",
    headers,
    status = 400,
    response = post_login_unsuccessful_response,
    body = post_login_unsuccessful_body
)


reqres_test_delete = Dict{String, ReqresTest}()

reqres_test_delete["delete_user"] = ReqresTest(;
    url = "https://reqres.in/api/users/2",
    what_to_delete = "",
    headers,
    status = 204,
    response = ""
)

reqres_test_put = Dict{String, ReqresTest}()

reqres_test_put["put_update"] = ReqresTest(;
    url = "https://reqres.in/api/users/2",
    headers,
    status = 200,
    response = put_update_response,
    body = put_update_body
)