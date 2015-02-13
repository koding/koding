htmlencode = require 'htmlencode'
globals = require 'globals'
groupifyLink = require '../util/groupifyLink'
nick = require '../util/nick'
kd = require 'kd'
KDCustomHTMLView = kd.CustomHTMLView
KDProgressBarView = kd.ProgressBarView
JView = require '../jview'
Machine = require '../providers/machine'


module.exports = class NavigationMachineItem extends JView

  {Running, Stopped} = Machine.State

  stateClasses  = ''
  stateClasses += "#{state.toLowerCase()} " for state in Object.keys Machine.State


  constructor: (options = {}, data) ->

    machine      = data
    @alias       = machine.slug or machine.label
    ideRoute     = "/IDE/#{@alias}/my-workspace"
    machineOwner = machine.getOwner()
    isMyMachine  = machine.isMine()
    channelId    = ''

    if not isMyMachine and globals.userWorkspaces
      globals.userWorkspaces.forEach (ws) ->
        return if channelId

        if ws.machineUId is machine.uid and ws.channelId
          channelId = ws.channelId

      ideRoute = "/IDE/#{channelId}"

    options.tagName    = 'a'
    options.cssClass   = "vm #{machine.status.state.toLowerCase()} #{machine.provider}"
    options.attributes =
      href             : groupifyLink ideRoute
      title            : "Open IDE for #{@alias}"

    unless machineOwner is nick()
      options.attributes.title += " (shared by @#{htmlencode.htmlDecode machineOwner})"

    super options, data

    @machine   = @getData()

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


  pistachio:->

    return """
      <figure></figure>
      {{> @label}}
      <span></span>
      {{> @progress}}
    """


