kd    = require 'kd'
JView = require '../../jview'

ACCOUNT_MENU  = null


module.exports = class TeamName extends kd.CustomHTMLView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.cssClass   = 'team-name'
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
      cssClass : 'TeamAccountMenu'
      x        : 36
      y        : 36
    ,
      'My Account' : { callback }
      'Dashboard'  : { callback }
      'Support'    : { callback }
      'Logout'     : { callback }

    ACCOUNT_MENU.once 'KDObjectWillBeDestroyed', -> kd.utils.wait 50, -> ACCOUNT_MENU = null


  handleMenuClick: (item, event) ->

    { title } = item.getData()
    ACCOUNT_MENU.destroy()

    @["handle#{title.replace(' ','')}"] item, event


  handleMyAccount: ->

    kd.singletons.router.handleRoute '/Home/My-Account'


  handleDashboard: ->

    kd.singletons.router.handleRoute '/Home/Welcome'


  handleLogout: ->

    kd.singletons.router.handleRoute '/Logout'


  handleSupport: ->

    unless window._chatlio
      new kd.NotificationView { title: 'Support isn\'t enabled by your team admin!' }
      return

    window._chatlio.show { expanded: yes }

    # hide completely when close icon clicked
    # default behavior is to minify
    kd.utils.wait 100, ->
      closeIcon = document.querySelectorAll('.chatlio-icon-cross2')[0]
      closeIcon?.addEventListener 'click', -> _chatlio.hide()



  pistachio: -> '{{ #(title)}}'
