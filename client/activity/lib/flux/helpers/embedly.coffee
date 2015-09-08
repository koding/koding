urlGrabber = require 'app/util/urlGrabber'
regexps    = require 'app/util/regexps'

extractUrl = (text) ->

  urls = urlGrabber text
  url = urls.first

  return  unless url

  url = "http://#{url}"  unless regexps.hasProtocol.test url
  return url


module.exports = {
  extractUrl
}

