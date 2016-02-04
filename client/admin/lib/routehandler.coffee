routeHandler   = require 'app/util/routeHandler'


module.exports = ->

  options =
    name      : 'admin'
    title     : 'Admin'
    homeRoute : '/Admin/General'

  routeHandler options
