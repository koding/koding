$       = require 'jquery'
globals = require 'globals'

module.exports = shortenUrl = (longUrl, callback) ->

  { apiKey } = globals.config.google

  apiUrl = "https://www.googleapis.com/urlshortener/v1/url?key=#{apiKey}"

  request = $.ajax
    url         : apiUrl
    type        : 'POST'
    contentType : 'application/json'
    data        : JSON.stringify { longUrl }
    dataType    : 'json'
    timeout     : 4000

  request.done (data) ->
    callback data?.id or longUrl, data

  request.fail ({ status, statusText, responseText }) ->
    console.error 'URL shortener error', status, statusText, responseText
    callback longUrl
