struct CurlMultiMessage
    msg::CURLMSG
    easy_handle::Ptr{CURL}
    result::CURLcode
end


function perform(rp, timeout, retries)
    multi_init(rp)
    @curlok curl_multi_add_handle(rp.multi_handle, rp.easy_handle)

    still_running = Ref{Cint}(1)
    @curlok curl_multi_perform(rp.multi_handle, still_running)
    while still_running[] > 0
        sleep(0.5)
        # ! I don't know why, but it blocks @async
        # numfds = Ref{Cint}(0)
        # @time @curlok curl_multi_poll(rp.multi_handle, C_NULL, 0, 1000, numfds)
        # @info "curl_multi_perform loop" still_running[]
        @curlok curl_multi_perform(rp.multi_handle, still_running)
    end

    
    msgs_in_queue = Ref{Cint}(1)
    while msgs_in_queue[] > 0
        message_ptr = curl_multi_info_read(rp.multi_handle, msgs_in_queue)
        if message_ptr == C_NULL
            error("No messages")
        end
        message = unsafe_load(Ptr{CurlMultiMessage}(message_ptr), 1)
        @curlok message.result
    end

    @curlok curl_multi_remove_handle(rp.multi_handle, rp.easy_handle)

    # rp.multi_handle
    # retry(
    #     curl -> HttpClient.@curlok(curl_easy_perform(curl)); 
    #     delays=fill(timeout, retries)
    # )(curl)
end