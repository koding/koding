class ContentPanel extends KDView

  constructor:(options, data)->

    super options, data

    @registerSingleton "contentPanel", @, yes
    @bindTransitionEnd()
    @listenWindowResize()
    @state = 'full'
    @chatMargin = 0
    @windowController or= KD.getSingleton 'windowController'

    @navOpenedOnce = yes #if KD.isLoggedIn() then yes else no

    mainViewController = KD.getSingleton "mainViewController"
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
    KD.getSingleton("mainView").mainTabView.changeLayout hideTabs : no

  changeLayout:(options)->

    {type, hideTabs, name}    = options

    @unsetClass 'full develop social'
    @adjustShadow hideTabs
    @navOpenedOnce = yes unless name in ["Home", "Activity"]

    @adjustLayoutHelper name, type

  resetToCurrentState:->
    switch @state
      when 'develop' then @adjustForDevelop()
      when 'social'  then @adjustForSocial()
      when 'full'    then @adjustForFullWidth()

  adjustShadow:(hideTabs)->
    @[if hideTabs then 'setClass' else 'unsetClass'] "no-shadow"

  adjustLayoutHelper:(name, type)->
    if @navOpenedOnce # KD.isLoggedIn() or
    then @[nameMap[name] or typeMap[type] or typeMap[@state]]?()
    else @adjustForFullWidth()

  adjustForFullWidth:->
    @setX 0
    @setWidth @windowController.winWidth - @chatMargin
    @setClass 'full'
    @state = 'full'

  adjustForDevelop:->
    @setX 260
    @setWidth @windowController.winWidth - 260 - @chatMargin
    @setClass 'develop'
    @state = 'develop'

  adjustForSocial:->
    offset = if @windowController.winWidth < 768 then 50 else 160
    @setWidth @windowController.winWidth - offset - @chatMargin
    @setClass 'social'
    @state = 'social'

  _windowDidResize: @::adjustLayoutHelper
