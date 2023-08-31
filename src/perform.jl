struct CurlMultiMessage
    msg::CURLMSG
    easy_handle::Ptr{CURL}
    result::CURLcode
end


function perform(curl, timeout, retries)
    multi_handle = curl_multi_init()
    if multi_handle == C_NULL
        error("HttpClient: Error initializing multi-handle")
    end
    @curlok curl_multi_add_handle(multi_handle, curl)

    still_running = Ref{Cint}(1)
    while still_running[] > 0
        @curlok curl_multi_perform(multi_handle, still_running)
    end

    
    msgs_in_queue = Ref{Cint}(1)
    while msgs_in_queue[] > 0
        message_ptr = curl_multi_info_read(multi_handle, msgs_in_queue)
        if message_ptr == C_NULL
            error("No messages")
        end
        message = unsafe_load(Ptr{CurlMultiMessage}(message_ptr), 1)
        @curlok message.result
    end

    @curlok curl_multi_remove_handle(multi_handle, curl)

    multi_handle
    # retry(
    #     curl -> HttpClient.@curlok(curl_easy_perform(curl)); 
    #     delays=fill(timeout, retries)
    # )(curl)
end