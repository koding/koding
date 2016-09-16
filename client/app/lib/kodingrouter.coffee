globals              = require 'globals'
kd                   = require 'kd'
remote               = require('./remote')
showError            = require './util/showError'
KodingAppsController = require './kodingappscontroller'
HomeGetters          = require 'home/flux/getters'
LocalStorage = require 'app/localstorage'
isGroupDisabled = require './util/isGroupDisabled'
getRole = require './util/getRole'

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

    group = kd.singletons.groupsController.getCurrentGroup()

    if isGroupDisabled(group) and not @isRouteAllowed route
      return @handleRoute @getGroupDisabledRoute route

    return @handleRoute @getDefaultRoute()  if /<|>/.test route
    super route, options


  openSection: (app, group, query) ->

    { appManager } = kd.singletons
    handleQuery    = appManager.tell.bind appManager, app, 'handleQuery', query

    appManager.once 'AppCreated', handleQuery  unless appWasOpen = appManager.get app
    appManager.open app

    handleQuery()  if appWasOpen

  handleNotFound: (route) ->

    status_404 = kd.Router::handleNotFound.bind this, route

    status_301 = (redirectTarget) =>
      @handleRoute "/#{redirectTarget}", { replaceState: yes }

    remote.api.JUrlAlias.resolve route, (err, target) ->
      if err or not target?
      then status_404()
      else status_301 target


  getDefaultRoute: ->

    { groupsController } = kd.singletons
    currentGroup         = groupsController.getCurrentGroup()

    if not currentGroup or currentGroup.slug is 'koding'
      return '/IDE'

    areStepsFinished = kd.singletons.reactor.evaluate(HomeGetters.areStepsFinished)

    if areStepsFinished
    then return '/IDE'
    else
      storage = new LocalStorage 'Koding', '1.0'
      storage.setValue 'landedOnWelcome', yes
      return '/Welcome'


  isRouteAllowed: (route) ->

    allowedRoutes =
      admin: [
        '/Home/team-billing'
        '/Disabled/Admin'
      ]
      member: [
        '/Disabled/Member'
        '/Disabled/Member/notify-success'
      ]

    return route in allowedRoutes[getRole()]


  getGroupDisabledRoute: -> "/Disabled/#{getRole().capitalize()}"


  setPageTitle: (title = 'Koding') -> kd.singletons.pageTitle.update title


  openContent : (name, section, models, route, query, passOptions = no) ->
    method   = 'createContentDisplay'
    [models] = models  if Array.isArray models

    # HK: with passOptions false an application only gets the information
    # 'hey open content' with this model. But some applications require
    # more information such as the route. Unfortunately we would need to
    # refactor a lot legacy. For now we do this new thing opt-in
    if passOptions
      method += 'WithOptions'
      options = { model:models, route, query }

    callback = ({ name, section, models, route, query, passOptions, options, method }) =>
      kd.getSingleton('appManager').tell section, method, options ? models, (contentDisplay) =>
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
      groupName = if section is 'Groups' then name else 'koding'
      groupsController.changeGroup groupName, (err) ->
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

    groupName = if section is 'Groups' then name else 'koding'
    kd.getSingleton('groupsController').changeGroup groupName, (err) =>
      showError err if err
      onSuccess = (models) =>
        @openContent name, section, models, route, query, passOptions
      onError   = (err) =>
        showError err
        @handleNotFound route

      if name and not slug
        remote.cacheable name, (err, models) ->
          if models?
          then onSuccess models
          else onError err
      else
        # TEMP FIX: getting rid of the leading slash for the post slugs
        slashlessSlug = routeWithoutParams.slice(1)
        remote.api.JName.one { name: slashlessSlug }, (err, jName) ->
          if err then onError err
          else if jName?
            models = []
            jName.slugs.forEach (aSlug, i) ->
              { constructorName, usedAsPath } = aSlug
              selector = {}
              konstructor = remote.api[constructorName]
              selector[usedAsPath] = aSlug.slug
              selector.group = aSlug.group if aSlug.group
              konstructor?.one selector, (err, model) ->
                return onError err if err? or not model
                models[i] = model
                if models.length is jName.slugs.length
                  onSuccess models
                else onError()
          else onError()


  clear: (route = '/', replaceState = yes) ->

    super route, replaceState
