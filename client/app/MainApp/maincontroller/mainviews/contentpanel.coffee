class ContentPanel extends KDView

  constructor:(options, data)->

    super options, data

    @registerSingleton "contentPanel", @, yes
    @bindTransitionEnd()
    @listenWindowResize()
    @state = 'full'
    @windowController or= @getSingleton 'windowController'

    @navOpenedOnce = if KD.isLoggedIn() then yes else no

    mainViewController = @getSingleton "mainViewController"
    mainViewController.on "UILayoutNeedsToChange", @bound "changeLayout"
    mainViewController.on "browseRequested", @bound "browseRequested"

  typeMap =
    full    : 'adjustForFullWidth'
    develop : 'adjustForDevelop'
    social  : 'adjustForSocial'

  nameMap =
    Home    : 'adjustForFullWidth'

  browseRequested:->
    @navOpenedOnce = yes
    @adjustForSocial()
    @getSingleton("mainView").mainTabView.changeLayout hideTabs : no

  changeLayout:(options)->

    {type, hideTabs, name}    = options

    @unsetClass 'full develop social'
    @adjustShadow hideTabs
    @navOpenedOnce = yes unless name in ["Home", "Activity"]

    @adjustLayoutHelper name, type

  adjustShadow:(hideTabs)->
    @[if hideTabs then 'setClass' else 'unsetClass'] "no-shadow"

  adjustLayoutHelper:(name, type)->
    if KD.isLoggedIn() or @navOpenedOnce
    then @[nameMap[name] or typeMap[type] or typeMap[@state]]?()
    else @adjustForFullWidth()

  adjustForFullWidth:->
    @setX 0
    @setWidth @windowController.winWidth
    @setClass 'full'
    @state = 'full'

  adjustForDevelop:->
    @setX 260
    @setWidth @windowController.winWidth - 260
    @setClass 'develop'
    @state = 'develop'

  adjustForSocial:->
    @setX 0
    @setWidth @windowController.winWidth - 160
    @setClass 'social'
    @state = 'social'

  _windowDidResize: @::adjustLayoutHelper
