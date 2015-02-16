isLoggedIn = require './isLoggedIn'

module.exports = ->
  not isLoggedIn()
