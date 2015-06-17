$ = require 'jquery'
kd = require 'kd'

module.exports = shortenUrl = (longUrl, callback) ->

  apiUrl = 'https://www.googleapis.com/urlshortener/v1/url'

  request = $.ajax
    url         : apiUrl
    type        : 'POST'
    contentType : 'application/json'
    data        : JSON.stringify {longUrl}
    dataType    : 'json'
    timeout     : 4000

  request.done (data) ->
    callback data?.id or longUrl, data

  request.error ({status, statusText, responseText}) ->
    console.error 'URL shortener error', status, statusText, responseText
    callback longUrl
