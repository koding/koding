htmlencode = require 'htmlencode'
globals = require 'globals'
groupifyLink = require '../util/groupifyLink'
nick = require '../util/nick'
kd = require 'kd'
KDCustomHTMLView = kd.CustomHTMLView
KDProgressBarView = kd.ProgressBarView
JView = require '../jview'
Machine = require '../providers/machine'
MachineSettingsPopup = require '../providers/machinesettingspopup'
MachineSettingsModal = require '../providers/machinesettingsmodal'
SidebarMachineSharePopup = require 'app/activity/sidebar/sidebarmachinesharepopup'


module.exports = class NavigationMachineItem extends JView

  {Running, Stopped} = Machine.State

  stateClasses  = 'reconnecting '
  stateClasses += "#{state.toLowerCase()} " for state in Object.keys Machine.State


  constructor: (options = {}, data) ->

    { machine, workspaces } = data

    @alias           = machine.slug or machine.label
    machineOwner     = machine.getOwner()
    isMyMachine      = machine.isMine()
    machineRoutes    =
      own            : "/IDE/#{@alias}"
      collaboration  : "/IDE/#{@getChannelId data}"
      permanentShare : "/IDE/#{machine.uid}"

    machineType = 'own'

    unless isMyMachine
      machineType = if machine.isPermanent() then 'permanentShare' else 'collaboration'

    options.tagName    = 'a'
    options.cssClass   = "vm #{machine.status.state.toLowerCase()} #{machine.provider}"
    options.attributes =
      href             : groupifyLink machineRoutes[machineType]
      title            : "Open IDE for #{@alias}"

    unless isMyMachine
      options.attributes.title += " (shared by @#{htmlencode.htmlDecode machineOwner})"

    super options, data

    { @machine } = @getData()
    labelPartial = machine.label or @alias

    unless isMyMachine
      labelPartial = """
        #{labelPartial}
        <cite class='shared-by'>
          (@#{htmlencode.htmlDecode machineOwner})
        </cite>
      """

    @label     = new KDCustomHTMLView
      partial  : labelPartial

    @progress  = new KDProgressBarView
      cssClass : 'hidden'

    isMine     = @machine.isMine()
    isApproved = @machine.isApproved()

    if (isMine or isApproved) and @settingsEnabled()
    then @createSettingsIcon()
    else @createSettingsIconPlaceholder()

    kd.singletons.computeController
      .on "reconnecting-#{@machine.uid}", =>
        @setState 'reconnecting'

      .on "public-#{@machine._id}", (event)=>
        @handleMachineEvent event


  createSettingsIcon: ->

    @settingsIcon = new KDCustomHTMLView
      tagName     : 'span'
      click       : (e) =>
        if @machine.isMine() then @handleMachineSettingsClick e
        else if @machine.isApproved() then @showSidebarSharePopup()


  createSettingsIconPlaceholder: ->

    @settingsIcon = new KDCustomHTMLView cssClass: 'hidden'


  settingsEnabled: ->

    { status: { state } } = @machine
    { NotInitialized, Running, Stopped, Terminated, Unknown } = Machine.State

    return state in [ NotInitialized, Running, Stopped, Terminated, Unknown ]


  handleMachineSettingsClick: (event) ->

    return  if not @settingsEnabled()

    kd.utils.stopDOMEvent event

    new MachineSettingsModal {}, @machine


  getPopupPosition: (extraTop = 0) ->

    bounds   = @getBounds()
    position =
      top    : Math.max(bounds.y - 38, 0) + extraTop
      left   : bounds.x + bounds.w + 16

    return position


  handleMachineEvent: (event) ->

    {percentage, status} = event

    # switch status
    #   when Machine.State.Terminated then @destroy()
    #  else @setState status

    @setState status

    if percentage?
      @updateProgressBar percentage


  setState: (state) ->

    return  unless state

    @unsetClass stateClasses
    @setClass state.toLowerCase()


  updateProgressBar: (percentage) ->

    return @progress.hide()  unless percentage

    @progress.show()
    @progress.updateBar percentage

    if percentage is 100
      kd.utils.wait 1000, @progress.bound 'hide'


  # passing data is required because this method is called before super call.
  getChannelId: (data) ->

    return data.workspaces.first?.channelId


  showSidebarSharePopup: (options = {}) ->

    options.position  = @getPopupPosition 20
    options.channelId = @getChannelId @getData()

    new SidebarMachineSharePopup options, @machine


  click: (e) ->

    m = @machine

    if not m.isMine() and not m.isApproved()
      kd.utils.stopDOMEvent e
      @showSidebarSharePopup()

    super


  pistachio: ->

    return """
      <figure></figure>
      {{> @label}}
      {{> @settingsIcon}}
      {{> @progress}}
    """
