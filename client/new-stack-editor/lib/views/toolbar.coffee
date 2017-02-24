debug = (require 'debug') 'nse:toolbar'

kd = require 'kd'
JView = require 'app/jview'

Events = require '../events'
Banner = require './banner'


module.exports = class Toolbar extends JView


  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'toolbar', options.cssClass
    data ?= { title: '', accessLevel: 'private', _initial: yes }

    super options, data

    @actionButton = new kd.ButtonView
      cssClass : 'action-button solid green compact'
      title    : 'Initialize'
      loader   : yes
      icon     : yes
      callback : =>
        @emit Events.InitializeRequested, @getData()._id

    @expandButton = new kd.ButtonView
      cssClass: 'expand'
      callback: ->
        kd.singletons.mainView.toggleSidebar()

    @menuIcon = new kd.CustomHTMLView
      tagName  : 'span'
      cssClass : 'menu-icon'
      click    : @bound 'handleMenu'

    @banner = new Banner
    @banner.on Events.Banner.Close, =>
      @unsetClass 'has-message'
      kd.utils.wait 500, @banner.bound 'hide'
    @forwardEvent @banner, Events.Action


  setBanner: (data) ->

    debug 'handling banner message', data.message, data.action

    @banner.setData data
    @banner.show()
    @setClass 'has-message'


  click: (event) ->

    if event.target.classList.contains 'credential'
      @emit Events.Action, Events.ToggleSideView, 'credentials'
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

    super { _id, accessLevel, credentials, title }


  handleMenu: (event) ->

    menu = new kd.ContextMenu {
      event               : event
      delegate            : @menuIcon
      cssClass            : 'stack-menu'
    }, {
      'Test'              :
        action            : Events.Menu.Test
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
    {cite.stack{}} {h3{#(title)}} {{> @menuIcon}}
    {.tag.level{#(accessLevel)}} {div.tag.credential{#(credentials)}} {cite.credential{}}
    {div.controls{> @expandButton}} {{> @actionButton}}
    {{> @banner}}
    '''
