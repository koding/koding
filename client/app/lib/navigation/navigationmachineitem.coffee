kd                           = require 'kd'
globals                      = require 'globals'
htmlencode                   = require 'htmlencode'

JView                        = require 'app/jview'
KDCustomHTMLView             = kd.CustomHTMLView
KDProgressBarView            = kd.ProgressBarView

nick                         = require 'app/util/nick'
Machine                      = require 'app/providers/machine'
isKoding                     = require 'app/util/isKoding'
groupifyLink                 = require 'app/util/groupifyLink'
isMachineSettingsIconEnabled = require 'app/util/isMachineSettingsIconEnabled'
userEnvironmentDataProvider  = require 'app/userenvironmentdataprovider'

MachineSettingsModal         = require 'app/providers/machinesettingsmodal'
SidebarMachineSharePopup     = require 'app/activity/sidebar/sidebarmachinesharepopup'
SidebarMachineConnectedPopup = require 'app/activity/sidebar/sidebarmachineconnectedpopup'


module.exports = class NavigationMachineItem extends JView

  {Running, Stopped} = Machine.State

  stateClasses  = 'reconnecting '
  stateClasses += "#{state.toLowerCase()} " for state in Object.keys Machine.State


  constructor: (options = {}, data) ->

    { machine, workspaces } = data

    @alias           = machine.slug or machine.label
    machineOwner     = machine.getOwner()
    reassigned       = machine.jMachine.meta?.oldOwner?
    oldOwner         = machine.jMachine.meta?.oldOwner ? machineOwner
    isMyMachine      = machine.isMine()
    machineRoutes    =
      own            : "/IDE/#{@alias}"
      collaboration  : "/IDE/#{@getChannelId data}"
      permanentShare : "/IDE/#{machine.uid}"
      reassigned     : "/IDE/#{machine.uid}"

    machineType = 'own'

    if reassigned
      machineType = 'reassigned'
    else if not isMyMachine
      machineType = if machine.isPermanent() then 'permanentShare' else 'collaboration'

    @machineRoute = groupifyLink machineRoutes[machineType]

    options.tagName    = 'a'
    options.cssClass   = "vm #{machine.status.state.toLowerCase()} #{machine.provider}"
    options.attributes =
      href             : '#'
      title            : "Open IDE for #{@alias}"

    unless isMyMachine
      options.attributes.title += " (shared by @#{htmlencode.htmlDecode machineOwner})"

    super options, data

    { computeController } = kd.singletons

    { @machine } = @getData()
    labelPartial = machine.label or @alias

    if not isMyMachine or reassigned
      labelPartial = """
        #{labelPartial}
        <cite class='shared-by'>
          (@#{htmlencode.htmlDecode oldOwner})
        </cite>
      """

    @label     = new KDCustomHTMLView
      partial  : labelPartial

    @progress  = new KDProgressBarView
      cssClass : 'hidden'

    @createSettingsIcon()

    computeController
      .on "reconnecting-#{@machine.uid}", =>
        @setState 'reconnecting'

      .on "public-#{@machine._id}", (event) =>
        @handleMachineEvent event

    computeController.ready =>

      if stack = computeController.findStackFromMachineId @machine._id
        computeController.on "public-#{stack._id}", (event) =>
          @handleMachineEvent event

    if not @machine.isMine() and not @machine.isApproved()
      @showSharePopup()

    @subscribeMachineShareEvent()


  createSettingsIcon: ->

    isMine     = @machine.isMine()
    isApproved = @machine.isApproved()
    cssClass   = if (isMine or isApproved) and @settingsEnabled() then '' else 'hidden'

    @settingsIcon = new KDCustomHTMLView
      tagName     : 'span'
      cssClass    : cssClass
      click       : (e) =>
        kd.utils.stopDOMEvent e

        return  unless @settingsEnabled()

        if @machine.isMine() then @handleMachineSettingsClick()
        else if @machine.isApproved() then @showSharePopup()


  moveSettingsIconLeft : ->

    @settingsIcon.setClass 'move-left'


  resetSettingsIconPosition : ->

    @settingsIcon.unsetClass 'move-left'


  settingsEnabled: -> isMachineSettingsIconEnabled @machine


  handleMachineSettingsClick: ->

    return  if not @settingsEnabled()

    new MachineSettingsModal {}, @machine


  getPopupPosition: (extraTop = 0) ->

    bounds   = @getBounds()
    position =
      top    : Math.max(bounds.y - 38, 0) + extraTop
      left   : bounds.x + bounds.w + 16

    return position


  handleMachineEvent: (event) ->

    { percentage, status } = event

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


  popups = {}

  ###

  This function determines what sort of machine share popup should be
  displayed based on given options and registered invitations in
  `MachineShareManager`.

  If an invitation found for machine given to `NavigationMachineItem`
  instance then share popup is displayed in invitation type for the
  shared workspace attached in invitation object.

  Default behavior of `SidebarMachineSharePopup` instance satisfies
  `shared machine` invitations.

  If an invitation is not found then state of invitations deduced by
  checking related properties.

  If user is a permanent user then approve state of `JMachine`
  determines type of share popup.

  If user is not a permanent user then share popup type is set to
  `collaboration`.  If a workspace identifier is given in options then
  associated `JWorkspace` is found.  Channel identifier is set from
  matching workspace object.

  Collaboration invitation is displayed if user is not a participant
  of associated channel.

  ###
  showSharePopup: (options = {}) ->

    show = (options) =>
      kd.utils.wait 733, =>
        options.position = @getPopupPosition 20
        popup = popups[@machine.uid]
        kd.utils.defer -> popup?.destroy()
        popups[@machine.uid] = new SidebarMachineSharePopup options, @machine

    {machineShareManager} = kd.singletons

    if invitation = machineShareManager.get @machine.uid
      {type} = invitation

      options.type = type

      switch type
        when 'collaboration'
          options.isApproved = no

          return userEnvironmentDataProvider.fetchMachineByUId @machine.uid, (machine, workspaces) ->
            for workspace in workspaces when workspace.getId() is invitation.workspaceId
              break

            options.channelId = workspace.channelId
            show options

      return show options

    else if @machine.isPermanent()
      options.type = 'shared machine'
      options.isApproved = @machine.isApproved()
      show options

    else if not @machine.isPermanent()
      options.type = 'collaboration'

      return userEnvironmentDataProvider.fetchMachineByUId @machine.uid, (machine, workspaces) ->
        for workspace in workspaces
          if options.workspaceId and workspace.getId() isnt options.workspaceId
            continue
          else if not options.workspaceId and not workspace.channelId
            continue

          {channelId} = workspace
          break

        return  unless options.channelId = channelId
        kd.singletons.socialapi.channel.byId id: channelId, (err, channel) ->
          return console.error err  if err
          options.isApproved = channel.isParticipant
          show options


  showMachineConnectedPopup: (params) ->

    slug = "#{@machine.uid}ConnectedPopup"

    options    =
      position : @getPopupPosition 13
      provider : params.providerName

    popup = popups[slug]
    kd.utils.defer -> popup?.destroy()

    popups[slug] = new SidebarMachineConnectedPopup options, @machine


  subscribeMachineShareEvent: ->

    {machineShareManager} = kd.singletons
    machineShareManager.subscribe @machine.uid, @bound 'showSharePopup'

    @once 'KDObjectWillBeDestroyed', =>
      machineShareManager.unsubscribe @machine.uid, @bound 'showSharePopup'


  click: (e) ->

    m = @machine

    if not m.isMine() and not m.isApproved()
      kd.utils.stopDOMEvent e
      @showSharePopup()

    super


  pistachio: ->

    return """
      <figure></figure>
      {{> @label}}
      {{> @settingsIcon}}
      {{> @progress}}
    """
