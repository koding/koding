kd = require 'kd'
lazyrouter = require 'app/lazyrouter'

handleSection = (callback) ->
  kd.getSingleton('groupsController').ready ->
    kd.singleton('appManager').open 'Dashboard', callback

handle = ({ params:{ section } }) ->
  handleSection (app) ->
    app.loadSection { title: section }

module.exports = -> lazyrouter.bind 'dashboard', (type, info, state, path, ctx) ->

  switch type
    when 'home'
      info.params.section = 'Settings'

  handle info
