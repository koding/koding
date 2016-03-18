ShareLink = require './sharelink'


module.exports = class LinkedInShareLink extends ShareLink
  constructor: (options = {}, data) ->
    options.provider = 'linkedin'
    super options, data

  getUrl: ->
    { url } = @getOptions()
    text  = "Koding is giving away 100TB this week - my link gets you a 5GB VM! #{url} @koding is AWESOME! #Crazy100TBWeek"
    return "http://www.linkedin.com/shareArticle?mini=true&url=#{encodeURIComponent url}&title=#{encodeURIComponent @title}&summary=#{encodeURIComponent text}&source=#{global.location.origin}"

  title: 'Join me @koding!'
