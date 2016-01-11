urlGrabber = require 'app/util/urlGrabber'
regexps    = require 'app/util/regexps'
Encoder    = require 'htmlencode'

extractUrl = (text) ->

  urls = urlGrabber text
  url  = urls.first

  return  unless url

  url = "http://#{url}"  unless regexps.hasProtocol.test url
  return url


createMessagePayload = (embedlyResponse) ->

  return  unless embedlyResponse

  filteredData = {}

  desiredFields = [
    'title', 'description',
    'url', 'safe', 'type', 'provider_name', 'error_type',
    'error_message', 'safe_type', 'safe_message', 'images'
    'media'
  ]

  for key in desiredFields
    if 'string' is typeof value = embedlyResponse[key]
    then filteredData[key] = Encoder.htmlDecode value
    else filteredData[key] = value

  { images } = filteredData
  if images?.length > 0
    image = images.first
    delete image.colors
    filteredData.images = [ image ]

  return { link_url : embedlyResponse.url, link_embed : filteredData }


module.exports = {
  extractUrl
  createMessagePayload
}
