kd = require 'kd'
registerRoutes = require 'app/util/registerRoutes'

module.exports = ->

  handler = (group, callback)->
    kd.getSingleton('groupsController').ready ->
      kd.singleton('appManager').open 'Dashboard', callback

  registerRoutes 'Dashboard',
    "/:name?/Dashboard"          : ({params : {section,name}})->
      handler name, (app)-> app.loadSection title : "Settings"
    "/:name?/Dashboard/:section" : ({params : {section,name}})->
      handler name, (app)-> app.loadSection title : decodeURIComponent section
