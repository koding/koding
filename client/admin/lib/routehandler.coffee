kd = require 'kd'
registerRoutes = require 'app/util/registerRoutes'
lazyrouter = require 'app/lazyrouter'

handleSection = (callback)->
  kd.getSingleton('groupsController').ready ->
    kd.singleton('appManager').open 'Admin', callback

handle = ({params:{section}}) ->
  handleSection (app) ->
    app.loadSection title: section

module.exports = -> lazyrouter.bind 'admin', (type, info, state, path, ctx) ->

  switch type
    when 'home'
      info.params.section = 'Settings'

  handle info
