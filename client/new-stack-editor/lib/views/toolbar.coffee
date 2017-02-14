debug = (require 'debug') 'nse:toolbar'

kd = require 'kd'
JView = require 'app/jview'

Events = require '../events'


module.exports = class Toolbar extends JView


  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'toolbar', options.cssClass
    data ?= { title: '', accessLevel: 'private', _initial: yes }

    super options, data

    @actionButton = new kd.ButtonView
      cssClass : 'action-button solid green compact'
      title    : 'Initialize'
      icon     : yes
      callback : => @emit Events.InitializeRequested, @getData()._id

    @expandButton = new kd.ButtonView
      cssClass: 'expand'
      callback: ->
        kd.singletons.mainView.toggleSidebar()

    @menuIcon = new kd.CustomHTMLView
      tagName  : 'span'
      cssClass : 'menu-icon'
      click    : @bound 'handleMenu'


  showMissingCredentialWarning: ->

    @unsetClass 'missing-credential'
    kd.utils.defer =>
      @setClass 'missing-credential'


  click: (event) ->

    if event.target.classList.contains 'credential'
      @emit Events.ToggleCredentials
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
      @emit Events.MenuAction, menuItem.getData().action
      kd.utils.defer menu.bound 'destroy'


  render: ->

    super

    if @getData().accessLevel is 'team'
    then @setClass   'team'
    else @unsetClass 'team'


  pistachio: ->

    '''
    {cite.stack{}} {h3{#(title)}} {{> @menuIcon}}
    {.tag.level{#(accessLevel)}} {div.tag.credential{#(credentials)}} {cite.credential{}}
    {div.controls{> @expandButton}} {{> @actionButton}}
    '''
