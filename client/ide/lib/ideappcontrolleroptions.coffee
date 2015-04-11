kd                    = require 'kd'
isLoggedIn            = require 'app/util/isLoggedIn'

module.exports =

  name        : 'IDE'
  behavior    : 'application'
  multiple    : yes
  dependencies: [ 'Ace', 'Finder' ]