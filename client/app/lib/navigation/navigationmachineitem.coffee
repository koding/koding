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
SidebarMachineSharePopup = require 'app/activity/sidebar/sidebarmachinesharepopup'


module.exports = class NavigationMachineItem extends JView

  {Running, Stopped} = Machine.State

  stateClasses  = ''
  stateClasses += "#{state.toLowerCase()} " for state in Object.keys Machine.State


  constructor: (options = {}, data) ->

    { machine, workspaces } = data

    @alias           = machine.slug or machine.label
    machineOwner     = machine.getOwner()
    isMyMachine      = machine.isMine()
    machineRoutes    =
      own            : "/IDE/#{@alias}"
      collaboration  : "/IDE/#{workspaces.first?.channelId}"
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

    isMine      = @machine.isMine()
    isPermanent = @machine.isPermanent() and @machine.isApproved()

    if isMine or isPermanent
      if @settingsEnabled()
        @settingsIcon = new KDCustomHTMLView
          tagName     : 'span'
          click       : (e) =>
            if isMine then @handleMachineSettingsClick e
            else if isPermanent then @showSidebarSharePopup()
    else
      @settingsIcon = new KDCustomHTMLView cssClass: 'hidden'

    kd.singletons.computeController.on "public-#{@machine._id}", (event)=>
      @handleMachineEvent event


  settingsEnabled: ->

    { status: { state } } = @machine
    { NotInitialized, Running, Stopped, Terminated, Unknown } = Machine.State

    return state in [ NotInitialized, Running, Stopped, Terminated, Unknown ]


  handleMachineSettingsClick: (event) ->

    return  if not @settingsEnabled()

    kd.utils.stopDOMEvent event

    new MachineSettingsPopup { position: @getPopupPosition() }, @machine


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


  showSidebarSharePopup: (options = {}) ->

    options.position = @getPopupPosition 20

    new SidebarMachineSharePopup options, @machine


  click: (e) ->

    m = @machine

    if not m.isMine() and m.isPermanent() and not m.isApproved()
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
