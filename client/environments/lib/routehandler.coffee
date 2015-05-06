kd             = require 'kd'

lazyrouter     = require 'app/lazyrouter'
registerRoutes = require 'app/util/registerRoutes'


handleSection = (callback)->
  kd.getSingleton('groupsController').ready ->
    kd.singleton('appManager').open 'Environments', callback

handle = ({params:{section}}) ->
  handleSection (app) ->
    # Reference for future requirements. ~ GG
    # app.loadSection title: section

module.exports = -> lazyrouter.bind 'environments', (type, info, state, path, ctx) ->

  switch type
    when 'home'
      info.params.section = 'Settings'

  handle info
