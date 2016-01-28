globals              = require 'globals'
kd                   = require 'kd'
remote               = require('./remote').getInstance()
isLoggedIn           = require './util/isLoggedIn'
showError            = require './util/showError'
isGroup              = require './util/isGroup'
KodingAppsController = require './kodingappscontroller'


module.exports = class KodingRouter extends kd.Router

  constructor: (@defaultRoute) ->

    @breadcrumb = []
    @defaultRoute or= global.location.pathname + global.location.search
    @openRoutes     = {}
    @openRoutesById = {}

    super()

    @on 'AlreadyHere', -> kd.log "You're already here!"


  listen: ->

    super

    return  if @userRoute

    kd.utils.defer =>
      @handleRoute @defaultRoute,
        shouldPushState : yes
        replaceState    : yes
        entryPoint      : globals.config.entryPoint


  handleRoute: (route, options = {}) ->

    @breadcrumb.push route

    entryPoint = options.entryPoint or globals.config.entryPoint
    route      = route.replace /\/+/g, '/'
    frags      = route.split('?')[0].split '/'

    [_root, _slug, _content, _extra] = frags

    if _slug is entryPoint?.slug
      name = if _content is 'Apps' and _extra? then _extra else _content
    else
      name = _slug

    appManager = kd.getSingleton 'appManager'
    if appManager.shouldLoadApp name
      return KodingAppsController.loadInternalApp name, (err, res) =>
        return kd.warn err  if err
        kd.utils.defer => @handleRoute route, options

    return @handleRoute @getDefaultRoute()  if /<|>/.test route
    super route, options


  openSection: (app, group, query) ->

    {appManager} = kd.singletons
    handleQuery = appManager.tell.bind appManager, app, "handleQuery", query

    appManager.once "AppCreated", handleQuery  unless appWasOpen = appManager.get app
    appManager.open app

    handleQuery()  if appWasOpen

  handleNotFound: (route) ->

    status_404 = kd.Router::handleNotFound.bind this, route

    status_301 = (redirectTarget)=>
      @handleRoute "/#{redirectTarget}", replaceState: yes

    remote.api.JUrlAlias.resolve route, (err, target)->
      if err or not target?
      then status_404()
      else status_301 target


  getDefaultRoute: ->

    {groupsController} = kd.singletons
    currentGroup       = groupsController.getCurrentGroup()

    # For koding default route still is /IDE always, for others if there is
    # stack template defined for the active group, it goes again to /IDE but if
    # there is no stack template defined for the current group it goes /Activity
    # directly.
    #
    # This doesn't effect the routes direct accesses. ~ GG

    if not currentGroup or currentGroup.slug is 'koding'
      return '/IDE'

    if groupsController.currentGroupHasStack()
    then return '/IDE'
    else
      if groupsController.currentGroupIsNew()
      then return '/Welcome'
      else return '/Activity'



  setPageTitle: (title = 'Koding') -> kd.singletons.pageTitle.update title

  openContent : (name, section, models, route, query, passOptions=no) ->
    method   = 'createContentDisplay'
    [models] = models  if Array.isArray models

    # HK: with passOptions false an application only gets the information
    # 'hey open content' with this model. But some applications require
    # more information such as the route. Unfortunately we would need to
    # refactor a lot legacy. For now we do this new thing opt-in
    if passOptions
      method += 'WithOptions'
      options = {model:models, route, query}

    callback = ({ name, section, models, route, query, passOptions, options, method }) =>
      kd.getSingleton("appManager").tell section, method, options ? models, (contentDisplay) =>
        unless contentDisplay
          console.warn 'no content display'
          return
        routeWithoutParams = route.split('?')[0]
        @openRoutes[routeWithoutParams] = contentDisplay
        @openRoutesById[contentDisplay.id] = routeWithoutParams
        contentDisplay.emit 'handleQuery', query

    groupsController = kd.getSingleton('groupsController')
    currentGroup = groupsController.getCurrentGroup()

    # change group if necessary
    unless currentGroup
      groupName = if section is "Groups" then name else "koding"
      groupsController.changeGroup groupName, (err) =>
        showError err if err
        callback {
          name, section, models, route,
          query, passOptions, options, method
        }
    else
      callback {
        name, section, models, route,
        query, passOptions, options, method
      }

  loadContent: (name, section, slug, route, query, passOptions) ->

    routeWithoutParams = route.split('?')[0]

    groupName = if section is "Groups" then name else "koding"
    kd.getSingleton('groupsController').changeGroup groupName, (err) =>
      showError err if err
      onSuccess = (models)=>
        @openContent name, section, models, route, query, passOptions
      onError   = (err)=>
        showError err
        @handleNotFound route

      if name and not slug
        remote.cacheable name, (err, models)=>
          if models?
          then onSuccess models
          else onError err
      else
        # TEMP FIX: getting rid of the leading slash for the post slugs
        slashlessSlug = routeWithoutParams.slice(1)
        remote.api.JName.one { name: slashlessSlug }, (err, jName)=>
          if err then onError err
          else if jName?
            models = []
            jName.slugs.forEach (aSlug, i)=>
              {constructorName, usedAsPath} = aSlug
              selector = {}
              konstructor = remote.api[constructorName]
              selector[usedAsPath] = aSlug.slug
              selector.group = aSlug.group if aSlug.group
              konstructor?.one selector, (err, model)=>
                return onError err if err? or not model
                models[i] = model
                if models.length is jName.slugs.length
                  onSuccess models
                else onError()
          else onError()


  clear: (route = '/', replaceState = yes) ->

    super route, replaceState
