ShareLink = require './sharelink'


module.exports = class FacebookShareLink extends ShareLink
  constructor: (options = {}, data) ->
    options.provider = 'facebook'
    super options, data

  getUrl: ->
    "https://www.facebook.com/sharer/sharer.php?u=#{encodeURIComponent @getOptions().url}"
