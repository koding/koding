isKoding = require './isKoding'

module.exports = ->

  return yes  unless isKoding()

  {
    userAccount: {profile: { nickname }}
   } = require 'globals'

  return nickname.indexOf('feed-enabled') is 0
