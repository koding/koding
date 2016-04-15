routeHandler   = require 'app/util/routeHandler'


module.exports = ->

  options =
    name      : 'stacks'
    title     : 'Stacks'
    homeRoute : '/Stacks/My-Stacks'

  routeHandler options
