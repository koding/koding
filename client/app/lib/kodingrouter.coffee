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
    { pathname, search, hash } = global.location
    @defaultRoute or= "#{pathname}#{search}#{hash}"
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


  handleRoute: (route = '', options = {}) ->

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

    # make sure that the team is routed to the disabled route when
    # it's disabled.
    if isGroupDisabled(group) and not @isRouteAllowed route
      return @handleRoute @getGroupDisabledRoute route

    # make sure that disabled route is not being shown to not disabled
    # teams.
    if not isGroupDisabled(group) and @isDisabledRoute route
      return location.replace @getDefaultRoute()

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
        '/Home/stacks'
        '/Home/team-billing'
        '/Disabled/Admin'
        '/Logout'
      ]
      member: [
        '/Disabled/Member'
        '/Disabled/Member/notify-success'
        '/Disabled/Member/upgrade-notify-success'
        '/Disabled/Member/suspended-notify-success'
        '/Logout'
      ]

    return route in allowedRoutes[getRole()]


  getGroupDisabledRoute: -> "/Disabled/#{getRole().capitalize()}"


  isDisabledRoute: (route) -> new RegExp(@getGroupDisabledRoute()).test route


  setPageTitle: (title = 'Koding') -> kd.singletons.pageTitle.update title


  clear: (route = '/', replaceState = yes) -> super route, replaceState
