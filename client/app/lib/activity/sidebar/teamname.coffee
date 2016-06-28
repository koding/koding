kd    = require 'kd'
JView = require '../../jview'
showError = require 'app/util/showError'

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

    callback = @bound 'handleMenuClick'

    ACCOUNT_MENU = new kd.ContextMenu
      cssClass : 'SidebarMenu'
      x        : 36
      y        : 36
    ,
      'Dashboard'  : { callback }
      'Support'    : { callback }
      'Logout'     : { callback }

    ACCOUNT_MENU.once 'KDObjectWillBeDestroyed', -> kd.utils.wait 50, -> ACCOUNT_MENU = null


  handleMenuClick: (item, event) ->

    { title } = item.getData()
    ACCOUNT_MENU.destroy()

    this["handle#{title.replace(' ', '')}"] item, event


  handleDashboard: ->

    kd.singletons.router.handleRoute '/Home/Welcome'


  handleLogout: ->

    kd.singletons.router.handleRoute '/Logout'


  handleSupport: ->

    { mainController, groupsController } = kd.singletons

    if groupsController.canEditGroup()
      return Intercom?('show')

    mainController.tellChatlioWidget 'show', { expanded: yes }, (err, result) ->
      showError err  if err

  pistachio: -> '{{ #(title)}}'
