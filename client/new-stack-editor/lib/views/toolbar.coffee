debug = (require 'debug') 'nse:toolbar'

$ = require 'jquery'
_ = require 'lodash'
kd = require 'kd'


Events = require '../events'
Banner = require './banner'

EnvironmentFlux = require 'app/flux/environment'


module.exports = class Toolbar extends kd.View


  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'toolbar', options.cssClass
    data ?= { title: '', accessLevel: 'private', _initial: yes }

    super options, data

    @templateTitle = new kd.HitEnterInputView
      type         : 'text'
      autogrow     : yes
      cssClass     : 'title-input'
      placeholder  : ''
      defaultValue : ''
      disabled     : yes
      attributes   :
        spellcheck : no

      callback     : (value) =>
        debug 'hit enter on title input', value
        @emit Events.Action, Events.TemplateTitleChangeRequested, value
        kd.utils.defer @templateTitle.bound 'makeDisabled'

      keyup        : _.debounce (e) ->
        EnvironmentFlux.actions
          .changeTemplateTitle @getData()._id, e.target.value
      , 100

    @actionButton = new kd.ButtonView
      cssClass : 'action-button solid green compact'
      title    : 'Initialize'
      loader   : yes
      icon     : yes
      callback : =>
        @emit Events.Action, Events.Menu.Initialize, @getData()._id

    @expandButton = new kd.ButtonView
      cssClass: 'expand'
      callback: ->
        kd.singletons.mainView.toggleSidebar()

    @menuIcon = new kd.CustomHTMLView
      tagName  : 'span'
      cssClass : 'menu-icon'
      click    : @bound 'handleMenu'

    { docsView } = @getOptions()
    docs = docsView.listController

    @docSearchInput = input = new kd.InputView
      type         : 'text'
      cssClass     : 'doc-search-input'
      placeholder  : 'search in stack documentation'
      attributes   :
        spellcheck : no
      keydown      : docs.bound 'handleKeyDown'
      focus        : =>
        if input.getValue() isnt ''
          @emit Events.Action, Events.ShowSideView, 'docs', { expanded: yes }
      keyup        : (event) =>
        value = input.getValue()
        if value is ''
          @emit Events.Action, Events.HideSideView
        else if docs.filterStates.query.search isnt value
          docs.filterStates.query.search = value
          docs.loadItems()
          @emit Events.Action, Events.ShowSideView, 'docs'

    @banner = new Banner
    @banner.on Events.Banner.Close, =>
      if sticky = @banner.isSticky()
        sticky.sticky = yes
        @banner.setData sticky
      else
        @hideBanner()

    @forwardEvent @banner, Events.Action

    @on Events.Action, (event) =>
      if event is Events.Menu.Rename
        @templateTitle.makeEnabled()
        @templateTitle.setFocus()


  setTitle: (data) ->

    @templateTitle.setData data

    { title } = data
    @templateTitle.setPlaceholder title
    @templateTitle.setValue title

    @templateTitle.resize()


  getCloneTitle: (clonedFrom) ->

    cc = kd.singletons.computeController
    (cc.storage.templates.get clonedFrom)?.title ? clonedFrom


  setCloneData: (data) ->

    if clonedFrom = data.config.clonedFrom
      @setClass 'clone'
      title = @getCloneTitle clonedFrom
      return "Clone of #{title}"

    else
      @unsetClass 'clone'
      return 'n/a'


  setBanner: (data) ->

    debug 'handling banner message', data.message, data.action

    data.message ?= ''

    if data.showlogs
      data.action   ?=
        title : 'Show Logs'
        event : Events.Menu.Logs
      data.autohide ?= 2500

    @banner.setData data

    if data.sticky is no
      @hideBanner()
    else
      @banner.show()
      @setClass 'has-message'


  hideBanner: ->
    @unsetClass 'has-message'
    kd.utils.wait 500, @banner.bound 'hide'


  click: (event) ->

    target = $(event.target)

    if target.is '.tag.credential'
      @emit Events.Action, Events.ShowSideView, 'credentials', { expanded: no }
      kd.utils.stopDOMEvent event

    else if target.is '.tag.clone'
      @emit Events.Action, Events.LoadClonedFrom
      kd.utils.stopDOMEvent event


  setData: (data) ->

    { _id, accessLevel, credentials, title } = data

    accessLevel = 'team'  if data.accessLevel is 'group'
    count = data.getCredentialIdentifiers?().length ? 0

    credentials = if count
    then "#{count} credential#{if count > 1 then 's' else ''}"
    else 'select credentials'

    if data._initial
      credentials = '-'
      accessLevel = '-'
      clonedFrom  = '-'

    else
      @setTitle data
      clonedFrom = @setCloneData data

    super { _id, accessLevel, credentials, title, clonedFrom }


  handleMenu: (event) ->

    menu = new kd.ContextMenu {
      event               : event
      delegate            : @menuIcon
      cssClass            : 'stack-menu'
    }, {
      'Initialize'        :
        action            : Events.Menu.Initialize
      'Make Team Default' :
        action            : Events.Menu.MakeTeamDefault
      'Rename Stack'      :
        action            : Events.Menu.Rename
      'Clone Stack'       :
        action            : Events.Menu.Clone
      'Credentials'       :
        action            : Events.Menu.Credentials
      'Logs'              :
        action            : Events.Menu.Logs
        separator         : yes
      'Delete'            :
        action            : Events.Menu.Delete
    }

    menu.on 'ContextMenuItemReceivedClick', (menuItem) =>
      debug 'menu item clicked', menuItem
      @emit Events.Action, menuItem.getData().action
      kd.utils.defer menu.bound 'destroy'


  render: ->

    super

    if @getData().accessLevel is 'team'
    then @setClass   'team'
    else @unsetClass 'team'

    @unsetClass 'has-message'


  pistachio: ->

    '''
    {cite.stack{}} {{> @templateTitle}} {{> @menuIcon}}
    {.tag.level{#(accessLevel)}}
    {div.tag.credential{#(credentials)}} {cite.credential{}}
    {div.tag.clone{#(clonedFrom)}}
    {div.controls{> @expandButton}} {{> @docSearchInput}} {{> @actionButton}}
    {{> @banner}}
    '''
