kd             = require 'kd'
KDRouter       = kd.Router
KDModalView    = kd.ModalView

remote         = require('./remote').getInstance()
globals        = require 'globals'

lazyrouter     = require './lazyrouter'
trackEvent     = require './util/trackEvent'
registerRoutes = require './util/registerRoutes'


getAction = (formName) -> switch formName
  when 'login'    then 'log in'
  when 'register' then 'register'

handleRoot = ->
  # don't load the root content when we're just consuming a hash fragment
  return if global.location.hash.length > 0

  {router}     = kd.singletons
  {entryPoint} = globals.config
  replaceState = yes

  router.handleRoute router.getDefaultRoute(), {entryPoint}


routerReady = (fn) ->
  {router} = kd.singletons
  if router then fn() else KDRouter.on 'RouterIsReady', fn


createSectionHandler = (sec) ->
  routerReady ->
    ({params:{name, slug}, query}) ->
      {router} = kd.singletons
      router.openSection slug or sec, name, query


createContentDisplayHandler = (section, passOptions = no) ->

  ({params:{name, slug}, query}, models, route)->

    {router} = kd.singletons
    route = name unless route

    if models?
      router.openContent name, section, models, route, query, passOptions
    else
      router.loadContent name, section, slug, route, query, passOptions


module.exports = -> lazyrouter.bind 'app', (type, info, state, path, ctx) ->

  switch type
    when 'members'
      {params, query} = info
      (createContentDisplayHandler 'Members') info, state, path

    when 'logout'
      kd.singletons.mainController.doLogout()

    when 'login', 'register'
      {query:{redirectTo}} = info
      if redirectTo
        redirectTo = "/#{redirectTo}"  unless redirectTo[0] is '/'
        kd.singletons.router.handleRoute redirectTo
      else handleRoot()

    when 'referrer'
      {params:{username}} = info
      trackEvent "Visit referrer url, success", {username}
      # give a notification to tell that this is a referral link here - SY
      handleRoot()

    when 'home' then handleRoot()

    when 'name'
      open = (routeInfo, model) ->
        switch model?.bongo_?.constructorName
          when 'JAccount'
            (createContentDisplayHandler 'Members') routeInfo, [model]
          when 'JGroup'
            (createSectionHandler 'Activity') routeInfo, model
          else
            ctx.handleNotFound routeInfo.params.name
      # (routeInfo, state, route)->

      if state? then open.call this, info, state
      else
        remote.cacheable info.params.name, (err, models, name) =>
          if models?
          then open.call this, info, models.first
          else ctx.handleNotFound info.params.name
