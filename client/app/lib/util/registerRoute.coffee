kd = require 'kd'

module.exports = (appName, route, handler) ->

  slug   = if 'string' is typeof route then route else route.slug
  route  =
    slug    : slug ? '/'
    handler : handler or route.handler or null

  if route.slug isnt '/' or appName is 'App'

    { slug, handler } = route

    cb = ->
      router = kd.getSingleton 'router'
      handler ?= ({ params: { name }, query }) -> router.openSection appName, name, query

      router.addRoute slug, handler

    if router = kd.singletons.router then cb()
    else kd.Router.on 'RouterIsReady', cb
