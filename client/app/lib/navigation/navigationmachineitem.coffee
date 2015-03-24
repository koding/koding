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

    if @machine.isMine()
      @settingsIcon = new KDCustomHTMLView
        tagName     : 'span'
        click       : @bound 'handleMachineSettingsClick'
    else
      @settingsIcon = new KDCustomHTMLView cssClass: 'hidden'

    kd.singletons.computeController

      .on "public-#{@machine._id}", (event)=>
        @handleMachineEvent event

      # These are updating machine data on this instance indivudally
      # but since we have more data to update, I'm updating all machines
      # for now.
      #
      # .on "revive-#{@machine._id}", (machine)=>
      #   @machine = machine

      #   @label.updatePartial @machine.label
      #   @alias   = @machine.slug or @label
      #   newPath  = groupifyLink "/IDE/#{@alias}/my-workspace"

      #   @setAttributes
      #     href   : newPath
      #     title  : "Open IDE for #{@alias}"


  handleMachineSettingsClick: (event) ->

    { status } = @machine
    { Building, Running } = Machine.State

    kd.utils.stopDOMEvent event

    return  unless status?.state is Running

    @openMachineSettingsPopup()


  openMachineSettingsPopup: ->

    bounds   = @getBounds()
    position =
      top    : Math.max   bounds.y - 38, 0
      left   : bounds.x + bounds.w + 16

    new MachineSettingsPopup { position }, @machine


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


  pistachio: ->

    return """
      <figure></figure>
      {{> @label}}
      {{> @settingsIcon}}
      {{> @progress}}
    """
