$ = require 'jquery'
kd = require 'kd'

module.exports = shortenUrl = (url, callback)->
  request = $.ajax "https://www.googleapis.com/urlshortener/v1/url",
    type        : "POST"
    contentType : "application/json"
    data        : JSON.stringify {longUrl: url}
    timeout     : 4000
    dataType    : "json"

  request.done (data)=>
    callback data?.id or url, data

  request.error ({status, statusText, responseText})->
    kd.log "URL shorten error, returning self as fallback.", status, statusText, responseText
    callback url
