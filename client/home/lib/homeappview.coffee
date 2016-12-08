$                 = require 'jquery'
kd                = require 'kd'
globals           = require 'globals'
HomeAppAvatarView = require './commons/homeappavatarview'
HomeTabHandle     = require './commons/hometabhandle'
isGroupDisabled   = require 'app/util/isGroupDisabled'

isDefaultEnv = -> globals.config.environment is 'default'

module.exports = class HomeAppView extends kd.ModalView

  constructor: (options = {}, data) ->

    options.testPath         = 'dashboard'
    options.checkRoles      ?= yes
    options.cssClass       or= kd.utils.curry 'HomeAppView', options.cssClass
    options.width           ?= 1000
    options.height          ?= '90%'
    options.overlay         ?= yes

    super options, data

    { router, mainView } = kd.singletons

    router.on 'RouteInfoHandled', (routeInfo) =>
      if routeInfo.path.indexOf('/Home') is -1
        @destroy()

    @addSubView @nav = new kd.TabHandleContainer { cssClass: 'HomeAppView-Nav' }

    @avatarArea = new HomeAppAvatarView
    @title      = new kd.CustomHTMLView
      tagName    : 'h3'
      cssClass   : 'HomeAppView-Nav--Title'
      partial    : 'Dashboard'

    @nav.addSubView @title, null, yes
    @nav.addSubView @avatarArea, null, yes

    @addSubView @tabs = new kd.TabView
      maxHandleWidth     : 245
      cssClass           : 'HomeAppView-TabView'
      tabHandleContainer : @nav
      tabHandleClass     : HomeTabHandle
    , data

    @tabs.unsetClass 'kdscrollview'
    @nav.unsetClass 'kdtabhandlecontainer'

    @setListeners()

    @once 'viewAppended', => kd.singletons.mainController.ready @bound 'createTabs'


  setListeners: ->

    @listenWindowResize()

    @on 'groupSettingsUpdated', (group) ->
      @setData group
      @createTabs()

    @tabs.on 'PaneAdded', (pane) ->
      { tabHandle } = pane
      tabHandle.setClass 'HomeAppView-Nav--Item'
      tabHandle.setClass 'beta'  if pane._beta
      tabHandle.unsetClass 'kdtabhandle'


  createTabs: ->

    group                     = @getData()
    { tabData, checkRoles }   = @getOptions()

    items   = []
    myRoles = _globals.userRoles

    group = kd.singletons.groupsController.getCurrentGroup()

    for item in tabData.items

      role = if item.role? then item.role else 'admin'

      if checkRoles and role not in myRoles
        continue

      if isDefaultEnv() and item.hideOnDefault
        continue

      if isGroupDisabled(group) and not item.showOnDisabled
        continue

      items.push item

      if item.subTabs
        for subTab in item.subTabs
          subTab.parentTabTitle = item.title
          items.push subTab


    @tabs.on 'PaneDidShow', (pane) =>
      return  if pane._isViewAdded

      slug       = kd.utils.slugify pane.getOption 'title'
      action     = pane.getOption 'action'
      identifier = pane.getOption 'identifier'
      targetItem = { viewClass: kd.CustomHTMLView }

      for item in items
        if item.action is action
          targetItem = item
          break
        else if slug is kd.utils.slugify item.title
          targetItem = item
          break

      { viewClass } = targetItem

      pane._isViewAdded = yes
      view = new viewClass
        cssClass : slug or action
        delegate : this
        action   : action
      , group
      view.once 'ModalDestroyRequested', @bound 'onDestroyRequested'
      pane.setMainView view

    items.forEach (item, i) =>

      { title, action } = item
      slug              = kd.utils.slugify title
      name              = title or action
      hiddenHandle      = !!action
      parentTabTitle    = item.parentTabTitle or null

      pane = new kd.TabPaneView { name, slug, action, hiddenHandle, title, parentTabTitle }
      pane._beta = item.beta

      @tabs.addPane pane, i is 0

    @emit 'ready'


  setDomElement: (cssClass) ->

    @domElement = $ """
      <div class='kdmodal #{cssClass}'>
        <span class='close-icon closeModal' title='Close [ESC]'></span>
      </div>
      """

  addSubView: kd.View::addSubView

  _windowDidResize: ->

    height = if window.innerHeight < 600 then 100 else 90
    @setHeight height, '%'
    @setPositions()


  onDestroyRequested: (dontChangeRoute) ->

    @dontChangeRoute = yes  if dontChangeRoute
    @destroy()
