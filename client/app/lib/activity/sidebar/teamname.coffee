kd    = require 'kd'
JView = require '../../jview'
showError = require 'app/util/showError'
whoami = require 'app/util/whoami'
AvatarStaticView = require 'app/commonviews/avatarviews/avatarstaticview'
ChangeTeamView = require 'app/changeteam'
JCustomHTMLView  = require 'app/jcustomhtmlview'
globals = require 'globals'
intercomSupport = require 'app/util/intercomSupport'
ACCOUNT_MENU  = null


module.exports = class TeamName extends kd.CustomHTMLView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.cssClass   = kd.utils.curry 'team-name', options.cssClass
    options.tagName    = 'a'
    options.attributes = { href: '#' }

    super options, data

    { groupsController } = kd.singletons

    groupsController.ready =>
      @setData groupsController.getCurrentGroup()


  click: (event) ->

    kd.utils.stopDOMEvent event

    lastLayer = kd.singletons.windowController.layers?.first

    return  if ACCOUNT_MENU

    account = whoami()

    avatar = new AvatarStaticView
      cssClass   : 'HomeAppView-Nav--avatar'
      size       : { width: 38, height: 38 }
    , account

    @avatar_wrapper = new kd.CustomHTMLView
      cssClass : 'HomeAppView-Nav--avatar-wrapper'
      click    : ->
        ACCOUNT_MENU.destroy()
        kd.singletons.router.handleRoute '/Home/my-account'

    { profile } = account

    pistachio = if profile.firstName is '' and profile.lastName is ''
    then '{{#(profile.nickname)}}'
    else "{{#(profile.firstName)+' '+#(profile.lastName)}}"

    profileName = new JCustomHTMLView
      cssClass   : 'HomeAppView-Nav--fullname'
      pistachio  : pistachio
    , account

    roles =  globals.userRoles
    hasOwner = 'owner' in roles
    hasAdmin = 'admin' in roles
    userRole = if hasOwner then 'owner' else if hasAdmin then 'admin' else 'member'

    role = new kd.CustomHTMLView
      tagName : 'div'
      cssClass : 'HomeAppView-Nav--role'
      partial : userRole.capitalize()


    fullnameAndRoleWrapper = new kd.CustomHTMLView
      tagName : 'div'
      cssClass : 'HomeAppView-Nav--fullname-role'

    @avatar_wrapper.addSubView avatar
    fullnameAndRoleWrapper.addSubView profileName
    fullnameAndRoleWrapper.addSubView role
    @avatar_wrapper.addSubView fullnameAndRoleWrapper

    @getMenuItems (menuItems) ->

      ACCOUNT_MENU = new kd.ContextMenu
        cssClass : 'SidebarMenu'
        x        : 36
        y        : 40
      , menuItems

      ACCOUNT_MENU.once 'KDObjectWillBeDestroyed', -> kd.utils.wait 50, -> ACCOUNT_MENU = null


  getMenuItems: (kallback) ->

    callback = @bound 'handleMenuClick'

    menuItems = {
      'customView'  : @avatar_wrapper
      'Dashboard'   : { callback }
      'Change Team' : { callback }
    }

    intercomSupport (isSupported) =>
      menuItems['Support'] = if isSupported then { callback }
      else { callback: @bound 'mailToSupport' }

      menuItems['Logout'] = { callback }

      kallback menuItems


  mailToSupport: ->

    window.location.href = 'mailto:support@koding.com'


  handleMenuClick: (item, event) ->

    { title } = item.getData()
    ACCOUNT_MENU.destroy()

    this["handle#{title.replace(' ', '')}"] item, event


  handleDashboard: ->

    kd.singletons.router.handleRoute '/Home/stacks'


  handleLogout: ->

    kd.singletons.router.handleRoute '/Logout'


  handleSupport: ->

    { mainController, groupsController } = kd.singletons

    if groupsController.canEditGroup()
      return Intercom?('show')

    mainController.tellChatlioWidget 'show', { expanded: yes }, (err, result) ->
      showError err  if err


  handleChangeTeam: -> new ChangeTeamView()


  pistachio: -> '{{ #(title)}}'
