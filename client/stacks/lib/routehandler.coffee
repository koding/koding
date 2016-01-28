routeHandler   = require 'app/util/routeHandler'


module.exports = ->

  options =
    name      : 'stacks'
    title     : 'Stacks'
    homeRoute : '/Stacks/Your-Stacks'

  routeHandler options
