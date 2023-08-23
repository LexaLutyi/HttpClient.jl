function set_ssl(curl)
    @curlok curl_easy_setopt(curl, CURLOPT_USE_SSL, CURLUSESSL_ALL)
    @curlok curl_easy_setopt(curl, CURLOPT_SSL_VERIFYHOST, 2)
    @curlok curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, 1)
    @curlok curl_easy_setopt(curl, CURLOPT_CAINFO, LibCURL2.cacert)
end