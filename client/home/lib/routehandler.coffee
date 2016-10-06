routeHandler = require 'app/util/routeHandler'


module.exports = ->

  options =
    name      : 'home'
    title     : 'Home'
    homeRoute : '/Home/stacks'

  routeHandler options
