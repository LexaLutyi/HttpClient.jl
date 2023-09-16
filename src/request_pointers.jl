@kwdef mutable struct RequestPointers
    easy_handle::Ptr{CURL} = C_NULL
    multi_handle::Ptr{CURLM} = C_NULL
    curl_url::Ptr{CURLU} = C_NULL
    slist::Ptr{curl_slist} = C_NULL
    function RequestPointers(easy_handle, multi_handle, curl_url, slist)
        x = new(easy_handle, multi_handle, curl_url, slist)
        finalizer(x) do x
            curl_easy_cleanup(x.easy_handle)
            curl_url_cleanup(x.curl_url)
            curl_multi_cleanup(x.multi_handle)
            curl_slist_free_all(x.slist)
        end
    end
end


function easy_init(rp::RequestPointers)
    rp.easy_handle = curl_easy_init()
    if rp.easy_handle == C_NULL
        error("HttpClient: Error initializing easy-handle")
    end
end


function multi_init(rp::RequestPointers)
    rp.multi_handle = curl_multi_init()
    if rp.multi_handle == C_NULL
        error("HttpClient: Error initializing multi-handle")
    end
end