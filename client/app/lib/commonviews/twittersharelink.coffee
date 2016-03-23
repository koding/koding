ShareLink = require './sharelink'


module.exports = class TwitterShareLink extends ShareLink
  constructor: (options = {}, data) ->
    options.provider = 'twitter'
    super options, data

  getUrl: ->
    { url } = @getOptions()
    text    = "Koding is giving away 100TB this week - my link gets you a 5GB VM! #{url} @koding is AWESOME! #Crazy100TBWeek"
    return "https://twitter.com/intent/tweet?text=#{encodeURIComponent text}&source=koding"
