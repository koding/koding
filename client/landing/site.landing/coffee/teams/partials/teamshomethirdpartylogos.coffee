kd = require 'kd.js'
module.exports = class TeamsHomeThirdPartyLogos extends kd.View


  IMAGEPATH = '/a/site.landing/images/teams/'
  LOGOS     = [
    { logo : 'dropbox.png',     url : '' }
    { logo : 'airbnb.png',      url : '' }
    { logo : 'pinterest.png',   url : '' }
    { logo : 'slack.png',       url : '' }
  ]


  constructor: (options = {}, data) ->

    options.cssClass = 'third-party'

    super options, data

    @prepareLogos()


  prepareLogos: ->

    logoItems = ''

    for item in LOGOS

      logoItems += "<a href='#{item.url}'><img src='#{IMAGEPATH}/#{item.logo}' alt='' /></a>"

    @setPartial logoItems
