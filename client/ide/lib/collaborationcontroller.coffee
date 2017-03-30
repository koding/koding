debug                         = (require 'debug') 'ide:collaborationcontroller'
_                             = require 'lodash'
kd                            = require 'kd'
FSFile                        = require 'app/util/fs/fsfile'
nick                          = require 'app/util/nick'
showError                     = require 'app/util/showError'
whoami                        = require 'app/util/whoami'
RealtimeManager               = require './realtimemanager'
IDEMetrics                    = require './idemetrics'
doXhrRequest                  = require 'app/util/doXhrRequest'
realtimeHelpers               = require './collaboration/helpers/realtime'
socialHelpers                 = require './collaboration/helpers/social'
envHelpers                    = require './collaboration/helpers/environment'
CollaborationStateMachine     = require './collaboration/collaborationstatemachine'
IDELayoutManager              = require './workspace/idelayoutmanager'
BaseModalView                 = require 'app/providers/views/basemodalview'
actionTypes                   = require 'app/flux/environment/actiontypes'
generateCollaborationLink     = require 'app/util/generateCollaborationLink'
Tracker                       = require 'app/util/tracker'
IDEHelpers                    = require 'ide/idehelpers'
ContentModal                  = require 'app/components/contentModal'

{ warn } = kd

# Attn!!
#
# This object is designed to be a mixin for IDEAppController.
#
# @see `IDEAppController`

module.exports = CollaborationController =

  # social related

  setSocialChannel: (channel) ->

    @socialChannel = channel
    @bindSocialChannelEvents()
    machine = @getMachine()

    return  unless machine.isMine()

    machine.setChannelId { channelId: channel.id }, (err) ->
      console.warn 'Failed to set channelId', err  if err


  fetchSocialChannel: (callback) ->

    debug 'fetchSocialChannel', @socialChannel

    if @socialChannel
      return callback null, @socialChannel

    unless id = @getSocialChannelId()
      return callback()

    machine = @getMachine()

    socialHelpers.fetchChannel id, (err, channel) =>

      # if channel couldn't fetch clear channel id from machine ~ GG
      if err and machine.getChannelId()
        return machine.setChannelId {}, -> callback err

      return callback err  if err

      @setSocialChannel channel
      callback null, channel


  getSocialChannelId: ->

    return @socialChannel?.id or @channelId or @getMachine()?.getChannelId()


  unsetSocialChannel: ->

    @channelId = @socialChannel = null


  # FIXME: This method is called more than once. It should cache the result and
  # return if result set exists.
  listChatParticipants: (callback) ->

    id = @getSocialChannelId()

    socialHelpers.fetchParticipants id, (err, accounts) ->
      return throwError err  if err

      callback accounts


  getRealtimeFileName: (id) ->

    id or= @getSocialChannelId()

    unless id
      return showError 'social channel id is not provided'

    hostName = @getCollaborationHost()

    return "#{hostName}.#{id}"


  whenRealtimeReady: (callback) ->

    if @rtm?.isReady
    then callback()
    else @once 'RTMIsReady', callback


  kickParticipant: (account) ->

    return  unless @amIHost

    target = account.profile.nickname

    # this object is used to follow the same pattern as other
    # methods. IMO, it makes it easier to read. ~Umut
    callbacks =
      success: =>
        @broadcastMessage { target, type: 'ParticipantKicked', params: { forceStop: no } }
      error: (err) ->
        # TODO: better error handling.
        showError err
        throwError err

    @removeWorkspaceSnapshot target

    socialHelpers.kickParticipants @socialChannel, [account], (err, result) ->
      return callbacks.error err  if err
      callbacks.success()


  handleParticipantKicked: (username) ->

    @statusBar.removeParticipantAvatar username
    @removeParticipantCursorWidget username
    # remove participant's all data persisted in realtime appInfo
    @removeParticipant username
    @removeWorkspaceSnapshot username

    @unwatchParticipant username
    @removeParticipantPermissions username

    options = {
      username
      machineUId : @getMachine().uid
    }

    @removeParticipantFromMachine username


  # Remove leaved / kicked participants from the mounted machine
  removeParticipantFromMachine: (username) ->

    @setMachineUser [username], no, (err) ->
      throwError err  if err


  handleParticipantAction: (actionType, changeData) ->

    kd.utils.wait 2000, =>

      switch actionType
        when 'join' then @onRealtimeParticipantJoined changeData
        when 'left' then @onRealtimeParticipantLeft changeData


  onRealtimeParticipantJoined: (data) ->

    return  unless @stateMachine?.state is 'Active'

    { sessionId }  = data.collaborator
    { targetUser } = realtimeHelpers.getTargetUser @participants, 'sessionId', sessionId

    unless targetUser
      return kd.warn 'Unknown user in collaboration, we should handle this case...'

    @statusBar.emit 'ParticipantJoined', targetUser

    Tracker.track Tracker.COLLABORATION_STARTED

    if @amIHost and targetUser isnt nick()
      @ensureMachineShare [targetUser], (err) ->
        return throwError err  if err


  onRealtimeParticipantLeft: (data) ->

    return  unless @stateMachine?.state is 'Active'

    { sessionId } = data.collaborator

    { targetUser, targetIndex } =
      realtimeHelpers.getTargetUser @participants, 'sessionId', sessionId

    unless targetUser
      return kd.warn 'Unknown user in collaboration, we should handle this case...'

    @statusBar.emit 'ParticipantLeft', targetUser
    @removeParticipantCursorWidget targetUser

    realtimeHelpers.ensureParticipantLeft @participants, targetUser, targetIndex


  # realtime related stuff


  broadcastMessage: (options = {}) ->

    message = _.assign {}, options, { origin: nick() }
    @broadcastMessages.push message


  activateRealtimeManager: (doc) ->

    @rtm.setRealtimeDoc doc
    @bindRealtimeErrorEvents()

    @setCollaborativeReferences()
    @addParticipant whoami()
    @setWatchMap()
    @registerCollaborationSessionId()

    if @amIHost
    then @activateRealtimeManagerForHost()
    else @activateRealtimeManagerForParticipant()

    @startRealtimePolling()

    @listenKlientKite()

    @rtm.isReady = yes
    @emit 'RTMIsReady'


  listenKlientKite: ->

    kite = @getMachine().getBaseKite()

    kite.once 'close', =>
      kite.ping()
        .timeout(30000)
        .then =>
          @listenKlientKite()
        .catch (err) =>
          if @amIHost
          then @handleCollaborationEndedForHost()
          else @handleCollaborationEndedForParticipant()


  setWatchMap: ->

    return @emit 'WatchMapIsReady'  if @amIHost

    host = @collaborationHost
    @myWatchMap.set host, host
    @emit 'WatchMapIsReady'


  activateRealtimeManagerForHost: ->

    @getView().setClass 'host'
    @startHeartbeat()


  activateRealtimeManagerForParticipant: ->

    @resurrectParticipantSnapshot()

    if @permissions.get(nick()) is 'read'
      return @makeReadOnly()  if @layoutManager.isRestored

      @layoutManager.once 'LayoutResurrected', @bound 'makeReadOnly'


  setCollaborativeReferences: ->

    refs = realtimeHelpers.getReferences @rtm, @getSocialChannelId(), @getWorkspaceSnapshot()

    # for backwards compatibility.
    # TODO: keep this until CollaborationModel abstraction. ~Umut
    @participants      = refs.participants
    @changes           = refs.changes
    @settings          = refs.settings
    @permissions       = refs.permissions
    @broadcastMessages = refs.broadcastMessages
    @myWatchMap        = refs.watchMap
    @mySnapshot        = refs.snapshot

    @rtm.once 'RealtimeManagerDidDispose', =>
      @participants      = null
      @changes           = null
      @settings          = null
      @permissions       = null
      @broadcastMessages = null
      @myWatchMap        = null
      @mySnapshot        = null


  registerCollaborationSessionId: ->

    realtimeHelpers.registerCollaborationSessionId @rtm, @participants


  addParticipant: (account) ->

    { hash, nickname } = account.profile

    val = { nickname, hash }
    index = @participants.indexOf val, (a, b) -> a.nickname is b.nickname

    @participants.push val  if index is -1
    @setMyPermission 'edit' if @amIHost


  watchParticipant: (nickname) -> @myWatchMap.set nickname, nickname


  unwatchParticipant: (nickname) -> @myWatchMap.delete nickname


  ###*
   * Show confirm modal to sync layout to host's layout.
   *
   * @param {string} nickname
  ###
  showConfirmToSyncLayout: (nickname) ->

    isHostWatched = nickname is @collaborationHost
    return  if not isHostWatched or @amIHost

    modal = new ContentModal
      width         : 400
      title         : "Host's layout is updated since you last watched his changes."
      cssClass      : 'modal-with-text collaboration-modals layout-changed-modal content-modal'
      content       : """
        If you click yes below we'll change your tabs layout to match host's layout.
        You won't lose your changes, if you have any.<br/><br/>
        Would you like to proceed?
      """
      overlay       : yes
      buttons       :
        'Cancel'    :
          cssClass  : 'solid medium light-gray'
          callback  : -> modal.destroy()
        'Yes'       :
          cssClass  : 'solid medium red'
          callback  : =>
            modal.destroy()
            @applyHostLayoutToParticipant()


  applyHostLayoutToParticipant: ->

    @getHostSnapshot (snapshot) =>

      remainingPanes = @layoutManager.clearLayout yes # Recover opened panes
      @layoutManager.resurrectSnapshot snapshot, yes, =>

        return  unless remainingPanes.length

        snapshotPanes = IDELayoutManager.getPaneHashMap snapshot

        for pane in remainingPanes
          if pane.data instanceof FSFile # editor, tailer
            paneIdentifier = pane.data.path
          else if pane.options.type is 'terminal'
            paneIdentifier = pane.view.session

          @activeTabView.addPane pane  unless snapshotPanes[paneIdentifier]

        @doResize()


  bindSocialChannelEvents: ->

    @socialChannel
      .on 'AddedToChannel', @bound 'participantAdded'
      .on 'MessageAdded',   @bound 'channelMessageAdded'
      .on 'ChannelDeleted', => @stopCollaborationSession()  # Don't pass any arguments.
      .on 'RemovedFromChannel', @bound 'participantRemoved'


  participantRemoved: (participant) ->

    socialHelpers.fetchAccount participant, (err, account) =>

      return throwError err  if err
      return  unless account

      { nickname } = account.profile

      @statusBar.removeParticipantAvatar nickname


  participantAdded: (participant) ->

    debug 'participantAdded', participant

    socialHelpers.fetchAccount participant, (err, account) =>

      return throwError err  if err
      return  unless account

      { nickname } = account.profile

      return  if nickname is nick()

      @statusBar.createParticipantAvatar nickname, no

      if @amIHost
        @setParticipantPermission nickname, 'read'
        @setMachineUser [nickname]


  channelMessageAdded: (message) ->

    return  unless message.payload

    { systemType } = message.payload
    systemType   or= message.payload['system-message']

    if systemType is 'start'
      if @stateMachine.state is 'NotStarted'
        @stateMachine.transition 'Loading'


  bindRealtimeEvents: ->

    @rtm.on 'CollaboratorJoined', (doc, participant) =>
      return  unless @stateMachine.state is 'Active'
      @handleParticipantAction 'join', participant

    @rtm.on 'CollaboratorLeft', (doc, participant) =>
      return  unless @stateMachine.state is 'Active'
      @handleParticipantAction 'left', participant

    @rtm.on 'ValuesAddedToList', (list, event) =>
      [value] = event.values

      switch list
        when @changes           then @handleChange value
        when @broadcastMessages then @handleBroadcastMessage value

    @rtm.on 'ValuesRemovedFromList', (list, event) =>
      @handleChange event.values[0]  if list is @changes

    @rtm.on 'MapValueChanged', (map, event) =>
      if map is @myWatchMap
        @handleWatchMapChange event

      else if map is @permissions
        @handlePermissionMapChange event


  bindRealtimeErrorEvents: ->

    @on 'ErrorRealtimeFileMissing',   throwError
    @on 'ErrorRealtimeServer',        throwError
    @on 'ErrorRealtimeUserForbidden', throwError
    @on 'ErrorRealtimeTokenExpired',  throwError
    @on 'ErrorGoogleDriveApiClient',  throwError
    @on 'ErrorHappened',              throwError


  removeParticipant: (nickname) ->

    refs = { @participants, @permissions }

    realtimeHelpers.removeFromManager @rtm, refs, nickname


  setRealtimeManager: (object) ->

    callback = =>
      object.rtm = @rtm
      object.emit 'RealtimeManagerSet'

    @whenRealtimeReady callback


  isRealtimeSessionActive: (id, callback) ->

    title = @getRealtimeFileName id

    @rtm or= new RealtimeManager
    @rtm.ready => realtimeHelpers.isSessionActive @rtm, title, callback


  getCollaborationData: (callback = kd.noop) ->

    host     = @collaborationHost
    settings = @getSettings()
    watchMap = @myWatchMap?.values()

    callback {
      @amIHost
      host
      settings
      watchMap
      @permissions
    }


  startHeartbeat: ->

    interval = 1000 * 15
    @sendPing() # send the first ping
    @pingInterval = kd.utils.repeat interval, @bound 'sendPing'
    @on 'RealtimeManagerWillDispose', => kd.utils.killRepeat @pingInterval


  sendPing: ->

    channelId = @getMachine().getChannelId()

    doXhrRequest
      endPoint : '/api/social/collaboration/ping'
      type     : 'POST'
      async    : yes
      data:
        fileId    : @rtmFileId
        channelId : channelId
    , (err, response) ->

      return  if not err

      if err.code is 400
        kd.utils.killRepeat @pingInterval # graceful stop
        throwError 'bad request, err: %s', err.message
      else
        throwError "#{err}: %s", JSON.stringify response


  startRealtimePolling: ->

    interval = 15 * 1000
    @pollInterval = kd.utils.repeat interval, @bound 'pollRealtimeDocument'


  pollRealtimeDocument: ->

    channelId = @getSocialChannelId()

    if not @rtm or not channelId
      kd.utils.killRepeat @pollInterval
      return

    @isRealtimeSessionActive channelId, (isActive) =>

      return  if isActive

      kd.utils.killRepeat @pollInterval

      if @amIHost
      then @stopCollaborationSession()
      else @showSessionEndedModal { redirect : yes }


  handleBroadcastMessage: (data) ->

    debug 'got broadcastMessage', data

    { origin, type, params } = data

    if origin is nick()
      switch type
        when 'ParticipantKicked'
          return @handleParticipantKicked data.target
        when 'PermissionDenied', 'PermissionGranted'
          return @destroyPermissionRequestMenuItem data.target
        else return

    switch type

      when 'SessionEnded'

        return  unless origin is @collaborationHost

        @showSessionEndedModal()

      when 'ParticipantWantsToLeave'

        @handleParticipantKicked data.origin

      when 'ParticipantKicked'

        return  unless data.origin is @collaborationHost

        if data.target is nick()
          @once 'IDEDidQuit', @bound 'showKickedModal'
          @handleCollaborationEndedForParticipant()  unless params.forceStop
          @quit yes, params.forceStop
        else
          @handleParticipantKicked data.target

      when 'SetMachineUser'

        return  if data.participants.indexOf(nick()) is -1

        @handleSharedMachine()

      when 'PermissionRequest'

        @statusBar.handlePermissionRequest origin  if @amIHost

      when 'PermissionDenied', 'PermissionRevoked'

        @handlePermissionRevert data.target, type is 'PermissionRevoked'

      when 'PermissionGranted'

        @handlePermissionGranted()  if data.target is nick()


  destroyPermissionRequestMenuItem: (target) ->

    @statusBar.participantAvatars[target]?.emit 'DestroyMenu'


  handlePermissionMapChange: (event) ->

    { property, newValue } = event

    return  unless property is nick()

    if      newValue is 'edit' then @makeEditable()
    else if newValue is 'read' then @makeReadOnly()


  handleWatchMapChange: (event) ->

    { property, newValue, oldValue } = event

    if newValue is property
      @statusBar.emit 'ParticipantWatched', property

    else unless newValue
      @statusBar.emit 'ParticipantUnwatched', property


  broadcastMachineUserChange: (participants, state) ->

    type = "#{if state then 'Set' else 'Unset'}MachineUser"

    @broadcastMessage { type, participants }


  handleSharedMachine: ->

    machine = @getMachine()
    @unmountMachine machine
    machine.getBaseKite().reconnect()
    @mountMachine machine


  ###*
   * Resurrect snapshot for participant
  ###
  resurrectParticipantSnapshot: ->

    doResurrection_ = =>
      @removeInitialViews()

      if @amIWatchingChangeOwner @collaborationHost
        @getHostSnapshot (snapshot) =>
          @layoutManager.resurrectSnapshot snapshot, yes  if snapshot
      else
        @fetchSnapshot (snapshot) =>
          @layoutManager.resurrectSnapshot snapshot, yes  if snapshot


    @whenRealtimeReady =>

      if @myWatchMap.values()?.length
        doResurrection_()
      else
        @once 'WatchMapIsReady', doResurrection_


  showShareButton: ->

    @ready => @statusBar.handleCollaborationLoading()


  collectButtonShownMetric: ->

    IDEMetrics.collect 'StatusBar.collaboration_button', 'shown'


  initCollaborationStateMachine: ->

    @stateMachine = new CollaborationStateMachine
      stateHandlers:
        Initial       : @bound 'onCollaborationInitial'
        Loading       : @bound 'onCollaborationLoading'
        Resuming      : @bound 'onCollaborationResuming'
        NotStarted    : @bound 'onCollaborationNotStarted'
        Preparing     : @bound 'onCollaborationPreparing'
        Prepared      : @bound 'onCollaborationPrepared'
        Creating      : @bound 'onCollaborationCreating'
        Active        : @bound 'onCollaborationActive'
        Ending        : @bound 'onCollaborationEnding'
        Created       : @bound 'onCollaborationCreated'
        ErrorCreating : @bound 'onCollaborationErrorCreating'


  onCollaborationInitial: ->

    machine = @getMachine()

    if machine.isMine()
      @showShareButton()
    else if machine.isPermanent()
      @attendWorkspaceChannel()

    kd.utils.defer => @stateMachine.transition 'Loading'


  onCollaborationLoading: ->

    @statusBar.emit 'CollaborationLoading'

    @checkSessionActivity
      error      : => @stateMachine.transition 'ErrorLoading'
      active     : => @stateMachine.transition 'Resuming'
      notStarted : => @stateMachine.transition 'NotStarted'


  checkSessionActivity: (callbacks, showSessionModal = yes) ->

    machine   = @getMachine()
    channelId = machine.getChannelId()

    callMethod = (name, args...) -> callbacks[name] args...

    unless channelId
      return callMethod 'notStarted'

    checkRealtimeSession = (channel) =>
      @isRealtimeSessionActive channel.id, (isActive, file) =>
        if isActive
          callMethod 'active', channel, file
          @updateSessionStartingProgress 40
        else
          callMethod 'notStarted'

    if not machine.isMine() and machine.isApproved() and not machine.isPermanent()
      if showSessionModal
        @showSessionStartingModal()

    @fetchSocialChannel (err, channel) =>

      debug 'checkSessionActivity', err, channel

      if err
        throwError err  unless err.error is 'koding.NotFoundError'
        return callMethod 'notStarted'

      @updateSessionStartingProgress 20

      if channel.isParticipant then checkRealtimeSession channel
      else
        socialHelpers.acceptChannel channel, (err) =>
          if err
            @destroySessionStartingModal()
            return callMethod 'error', err

          @updateSessionStartingProgress 30
          checkRealtimeSession channel


  onCollaborationNotStarted: ->

    @statusBar.emit 'CollaborationEnded'
    @destroySessionStartingModal()

    machine = @getMachine()

    owned = machine.isMine()
    approved = machine.isApproved()

    if (not owned) and approved
      @statusBar.share?.hide()

    @collectButtonShownMetric()


  prepareSocialChannel: (callbacks) ->

    socialHelpers.initChannel (err, channel) =>
      return callbacks.error err  if err

      @setSocialChannel channel

      callbacks.success()



  onCollaborationErrorCreating: ->

    showError 'Session could not start.'
    @stateMachine.transition 'Prepared'


  onCollaborationPreparing: ->

    { tooltipContent } = @collaborationStartOptions ? {}
    @statusBar.emit 'CollaborationPreparing', tooltipContent

    @prepareSocialChannel
      success : => @stateMachine.transition 'Prepared'
      error   : => @stateMachine.transition 'ErrorPreparing'


  onCollaborationPrepared: ->

    @startCollaborationSession @collaborationStartOptions


  startCollaborationSession: (options = {}) ->

    # Show this message while "@stateMachine" is preparing when a session is over just now.
    # It will be ready in a few seconds.
    return showError 'Please wait a few seconds.'  unless @stateMachine

    @collaborationStartOptions = options

    switch @stateMachine.state
      when 'Prepared'   then @stateMachine.transition 'Creating'
      when 'NotStarted' then @stateMachine.transition 'Preparing'


  onCollaborationCreating: ->

    @createCollaborationSession
      success : (doc) =>
        @whenRealtimeReady => @stateMachine.transition 'Created'
        @activateRealtimeManager doc
      error: =>
        @stateMachine.transition 'ErrorCreating'


  onCollaborationCreated: ->

    @setInitialSettings()

    @statusBar.share.updateProgress 100

    kd.utils.wait 500, => @stateMachine.transition 'Active'


  createCollaborationSession: (callbacks) ->

    fileName = @getRealtimeFileName()

    realtimeHelpers.createCollaborationFile @rtm, fileName, (err, file) =>
      return callbacks.error err  if err

      realtimeHelpers.loadCollaborationFile @rtm, file.id, (err, doc) =>
        return callbacks.error err  if err

        @rtmFileId = file.id

        socialHelpers.sendActivationMessage @socialChannel, kd.noop

        @setMachineSharingStatus on, (err) ->
          return callbacks.error err  if err
          callbacks.success doc


  showSessionStartingModal: ->

    @sessionStartingModal = modal = new BaseModalView
      cssClass  : 'env-machine-state session-starting'
      width     : 440
      container : @getView()

    modal.addSubView modal.container = new kd.CustomHTMLView
      cssClass: 'content-container'

    modal.container.addSubView new kd.CustomHTMLView
      tagName  : 'p'
      partial  : "<span class='icon'></span> Joining collaboration session..."
      cssClass : 'state-label running'

    modal.container.addSubView modal.progressBar = new kd.ProgressBarView { initial: 10 }

    modal.show()


  updateSessionStartingProgress: (percentage) ->

    @sessionStartingModal?.progressBar.updateBar percentage


  destroySessionStartingModal: ->

    @sessionStartingModal?.destroy()
    @sessionStartingModal = null


  onCollaborationResuming: ->

    @showShareButton()

    successCb = (channel, doc) =>
      @whenRealtimeReady =>
        @setSocialChannel channel

        @stateMachine.transition 'Active'
        @updateSessionStartingProgress 90

        kd.utils.wait 2000, =>
          @updateSessionStartingProgress 100
          kd.utils.wait 500, @bound 'destroySessionStartingModal'

      @activateRealtimeManager doc

    errorCb = => # @stateMachine.transition 'ErrorResuming'
      @destroySessionStartingModal()

    @resumeCollaborationSession
      success : successCb
      error   : errorCb


  resumeCollaborationSession: (callbacks) ->

    title = @getRealtimeFileName()

    realtimeHelpers.fetchCollaborationFile @rtm, title, (err, file) =>
      return callbacks.error err  if err

      @updateSessionStartingProgress 50

      realtimeHelpers.loadCollaborationFile @rtm, file.id, (err, doc) =>
        return callbacks.error err  if err

        @updateSessionStartingProgress 70
        @rtmFileId = file.id
        callbacks.success @socialChannel, doc


  onCollaborationActive: ->

    @bindAutoInviteHandlers()

    @transitionViewsToActive()
    @collectButtonShownMetric()
    @bindRealtimeEvents()

    # attach RTM instance to already in-screen panes.
    @forEachSubViewInIDEViews_ @bound 'setRealtimeManager'

    # attach realtime manager when a new editor pane is opened.
    @on 'EditorPaneDidOpen', @bound 'setRealtimeManager'

    @on 'SetMachineUser',   @bound 'broadcastMachineUserChange'
    @on 'SnapshotUpdated',  @bound 'handleSnapshotUpdated'

    openFolders = @rtm.getFromModel('commonStore').get 'openFolders'

    if openFolders and not @amIHost
      for path in openFolders
        @finderPane.finderController.expandFolder path


  bindAutoInviteHandlers: ->

    { actions } = require 'app/flux/socialapi'
    { notificationController, mainController, socialapi } = kd.singletons

    channel = @socialChannel

    debug 'bindAutoInviteHandlers', channel

    mainController.ready ->
      notificationController.on 'notificationFromOtherAccount', (notification) ->

        debug 'got notification', notification

        switch notification.action

          when 'COLLABORATION_REQUEST'

            debug 'COLLABORATION_REQUEST', notification.channelId, channel.id

            return  if notification.channelId isnt channel.id

            { channelId, senderUserId, senderAccountId, sender } = notification
            accountIds = [senderAccountId]

            debug 'calling socialapi', { channelId, accountIds }

            socialapi.channel.addParticipants { channelId, accountIds }, (err) ->

              debug 'got response from socialapi', err

              return throwError err  if err


  transitionViewsToActive: ->

    generateCollaborationLink nick(), @socialChannel.id, {}, (url) =>
      @statusBar.emit 'CollaborationStarted',
        channelId: @socialChannel.id
        collaborationLink: url


  onCollaborationEnding: ->

    @off 'SetMachineUser'

    if @amIHost
      @endCollaborationForHost =>
        @modal?.destroy()
        @handleCollaborationEndedForHost()
    else
      @endCollaborationForParticipant =>
        @silent = yes
        @modal?.destroy()
        @handleCollaborationEndedForParticipant()

    kd.singletons.onboarding.stop 'CollaborationStarted'


  endCollaborationForHost: (callback) ->

    @broadcastMessage { type: 'SessionEnded' }

    # Simply put, this timeout implementation was improved to prevent to clear race condition.
    # If you want to receive further information about this, you can visit the PR
    # https://github.com/koding/IDE/pull/499
    kd.utils.wait 2000, =>

      fileName = @getRealtimeFileName()

      realtimeHelpers.deleteCollaborationFile @rtm, fileName, (err) ->
        throwError err  if err

      @setMachineSharingStatus off, (err) ->
        throwError err  if err

      @clearParticipantsSnapshot()

      socialHelpers.destroyChannel @socialChannel, (err) ->
        throwError err  if err

      callback()


  clearParticipantsSnapshot: ->

    machine = @getMachine()
    debug 'clearParticipantsSnapshot', machine

    { users } = machine

    @listChatParticipants (accounts) =>
      accounts.forEach (account) =>
        { nickname } = account.profile

        machineUser  = _.find users, {
          username  : nickname
          owner     : no # Don't remove host's workspace
          approved  : yes
        }

        @removeWorkspaceSnapshot nickname  if machineUser


  handleCollaborationEndedForHost: ->

    return  unless @stateMachine.state in ['Ending']

    @rtm.once 'RealtimeManagerWillDispose', =>
      @statusBar.emit 'CollaborationEnded'

    @rtm.once 'RealtimeManagerDidDispose', =>
      kd.utils.defer @bound 'prepareCollaboration'

    @cleanupCollaboration()


  endCollaborationForParticipant: (callback) ->

    socialHelpers.leaveChannel @socialChannel, (err) ->
      throwError err  if err

    @removeWorkspaceSnapshot()
    @broadcastMessage { type: 'ParticipantWantsToLeave' }
    callback()


  handleCollaborationEndedForParticipant: ->

    return  unless @stateMachine?.state in ['Active', 'Ending']
    return  unless machine = @getMachine()

    { reactor, computeController } = kd.singletons

    if machine.isMine()
      machine.setChannelId {}, (err) ->
        console.warn 'Failed to set channelId', err  if err

    else if not machine.isPermanent()
      machine.deny (err) ->
        console.warn 'Failed to deny machine', err  if err
        reactor.dispatch \
          actionTypes.INVITATION_REJECTED, machine._id

    else
      computeController.reloadIDE machine

    # TODO: fix implicit emit.
    @rtm.once 'RealtimeManagerWillDispose', =>
      @statusBar.emit 'CollaborationEnded'
      @removeParticipant nick()

    @rtm.once 'RealtimeManagerDidDispose', =>
      method = switch
        when machine.isPermanent() then 'prepareCollaboration'
        else 'quit'

      kd.utils.defer @bound method

    @cleanupCollaboration()


  stopCollaborationSession: (callback = kd.noop) ->

    return callback()  unless @stateMachine

    @once 'CollaborationDidCleanup', callback

    switch @stateMachine.state
      when 'Active' then @stateMachine.transition 'Ending'


  prepareCollaboration: ->

    @rtm = new RealtimeManager

    @rtm.ready @bound 'initCollaborationStateMachine'


  getCollaborationHost: -> if @amIHost then nick() else @collaborationHost


  cleanupCollaboration: (options = {}) ->

    @unsetSocialChannel()

    if @rtm

      @rtm.once 'RealtimeManagerWillDispose', =>
        kd.utils.killRepeat @pingInterval

      @rtm.once 'RealtimeManagerDidDispose', =>
        @rtm = null
        delete @stateMachine

      @rtm.dispose()

    @emit 'CollaborationDidCleanup'


  # environment related


  ensureMachineShare: (usernames, callback) ->

    { fetchMissingParticipants } = envHelpers

    fetchMissingParticipants @getMachine(), usernames, (err, missing) =>
      return callback err  if err

      @setMachineUser missing, yes, callback


  setMachineSharingStatus: (status, callback) ->

    machine = @getMachine()

    getUsernames = ->
      machine.getAt 'users'
        .filter ({ permanent, owner }) -> not permanent and not owner
        .map    ({ username }) -> username

    if @amIHost
      usernames = getUsernames()

      debug 'setMachineSharingStatus', usernames
      debug 'setMachineUser calling', usernames, status

      @setMachineUser usernames, status, callback

    else
      @setMachineUser [nick()], status, callback


  setMachineUser: (usernames, share = yes, callback = kd.noop) ->

    machine = @getMachine()

    debug 'setMachineUser', { usernames, share, machine }
    # TODO: needs an investigation here.
    # if this usernames length check would be done
    # via helper method, the broadcastMessage
    # lines would be executed as well. attn to @szkl.
    return callback null  unless usernames.length

    { setMachineUser } = envHelpers

    setMachineUser machine, usernames, share, (err) =>
      debug 'setMachineUser result', err

      return callback err  if err

      @emit 'SetMachineUser', usernames, share

      callback null


  # collab related modals (should be its own mixin)


  showEndCollaborationModal: (callback) ->

    modalOptions =
      title      : 'Are you sure?'
      content    : '<p>This will end your session and all participants will be removed from this session.</p>'

    modal = @showModal modalOptions, => @stopCollaborationSession callback


  showKickedModal: ->
    options        =
      title        : 'Your session has been closed'
      content      : "<p>You have been removed from the session by <strong>@#{@collaborationHost}</strong>.</p>"
      cssClass     : 'kicked-modal'
      blocking     : yes
      buttons      :
        ok         :
          title    : 'OK'
          style    : 'GenericButton'
          callback : =>
            @modal.destroy()

    @showModal options


  showSessionEndedModal: (options = {}) ->

    { content, redirect } = options

    content ?= "<p>This collaboration session has been terminated by the host <strong>@#{@collaborationHost}</strong>.</p>"

    options        =
      title        : 'Session ended'
      content      : content
      blocking     : yes
      buttons      :
        quit       :
          style    : 'GenericButton'
          title    : 'LEAVE'
          callback : =>
            @modal.destroy()
            kd.singletons.router.handleRoute '/IDE'  if redirect

    @showModal options
    @handleCollaborationEndedForParticipant()


  handleParticipantLeaveAction: ->

    options   =
      title   : 'Are you sure?'
      content : "<p>This will remove the shared VM from your sidebar. If you want to get back to the collaboration session later, you will need to manually go to this session's URL.</p>"

    @showModal options, => @stateMachine.transition 'Ending'


  throwError: throwError = (err, args...) ->

    format = JSON.stringify \
    switch typeof err
      when 'string' then err
      when 'object' then err.message or err.description
      else args.join ' '

    argIndex = 0
    console.error """
      IDE.CollaborationController:
      #{ format.replace /%s/g, -> JSON.stringify(args[argIndex++]) or '%s' }
    """


  attendWorkspaceChannel: ->

    { notificationController } = kd.singletons

    notificationController.on 'AddedToChannel', (update) =>

      channelId = @getMachine().getChannelId()

      return  unless update.channel.id is channelId

      if update.isParticipant
      then @stateMachine.transition 'Loading'


  setInitialSessionSetting: (name, value) ->

    @initialSettings ?= {}
    @initialSettings[name] = value


  setInitialSettings: ->

    for own key, value of @initialSettings
      @settings.set key, value


  getSettings: ->

    rval = {}
    rval[key] = value  for [key, value] in @settings.items()
    return rval


  setParticipantPermission: (nickname, permission) ->

    @permissions.set nickname, permission


  removeParticipantPermissions: (nickname) ->

    @permissions.delete nickname


  getMyPermission: -> @permissions?.get nick()


  setMyPermission: (permission) ->

    permission = 'edit'  if @amIHost # override for host
    @setParticipantPermission nick(), permission


  getMyWatchers: ->

    participants = []

    for user in @participants.asArray() when user.nickname isnt nick()

      map = realtimeHelpers.getParticipantWatchMap @rtm, user.nickname

      if map.keys().indexOf(nick()) > -1
        participants.push user.nickname

    return participants


  getHostSnapshot: (callback = kd.noop) ->

    @fetchSnapshot (snapshot) ->
      callback snapshot
    , @getCollaborationHost()


  handleSnapshotUpdated: ->

    @mySnapshot.set 'layout', @getWorkspaceSnapshot()  if @rtm?.isReady


  getSnapshotFromDrive: (username = nick(), isFlat = no) ->

    layout = @mySnapshot?.get 'layout'

    if layout and isFlat
      return IDELayoutManager.convertSnapshotToFlatArray layout

    return layout


  saveOpenFoldersToDrive: ->

    openFolders = @finderPane.getOpenFolders()
    @rtm.getFromModel('commonStore').set 'openFolders', openFolders


  showRequestPermissionView: ->

    return  if @permissionView

    @permissionView = IDEHelpers.showNotificationBanner
      title   : 'WARNING:'
      content : "You don't have permission to make changes.
                 <a href='#' class='ask-permission'>Ask for permission.</a>"
      click   : (e) =>
        return  unless e.target.classList.contains 'ask-permission'
        @requestPermission()
        @permissionView.hide()

    @permissionView.once 'KDObjectWillBeDestroyed', => @permissionView = null


  requestPermission: -> @broadcastMessage { type: 'PermissionRequest' }


  denyPermissionRequest: (target) ->

    return  unless @amIHost

    @broadcastMessage { type: 'PermissionDenied', target }


  approvePermissionRequest: (target) ->

    return  unless @amIHost

    @broadcastMessage { type: 'PermissionGranted', target }
    @setParticipantPermission target, 'edit'
    @applyPermissionFor target, 'edit'


  revokePermission: (target) ->

    return  unless @amIHost

    @broadcastMessage { type: 'PermissionRevoked', target }
    @setParticipantPermission target, 'read'
    @applyPermissionFor target, 'read'
    @forEachSubViewInIDEViews_ 'editor', (ep) ->
      ep.removeParticipantCursorWidget target


  handlePermissionRevert: (username, isRevoked = no) ->

    unless username is nick()
      return @forEachSubViewInIDEViews_ 'editor', (ep) ->
        ep.removeParticipantCursorWidget username

    @permissionView?.destroy()

    cssClass = 'error'
    title    = 'REQUEST DENIED:'
    content  = 'Host has denied your request to make changes!'

    if isRevoked
      title    = 'ACCESS REVOKED:'
      content  = 'Host revoked your access to control their session!'

    @permissionView = IDEHelpers.showNotificationBanner { cssClass, title, content }
    @permissionView.once 'KDObjectWillBeDestroyed', => @permissionView = null


  handlePermissionGranted: (nickname) ->

    @permissionView?.destroy()

    @permissionView = IDEHelpers.showNotificationBanner
      cssClass : 'success'
      title    : 'ACCESS GRANTED:'
      content  : 'You can make changes now!'

    @permissionView.once 'KDObjectWillBeDestroyed', => @permissionView = null


  applyPermissionFor: (nickname, permission) ->

    return if not permission or not @amIHost or not nickname or not @rtm.isReady

    me           = nick()
    method       = if permission is 'edit' then 'set' else 'delete'
    participants = @participants.asArray()

    for participant in participants
      map = @rtm.getFromModel "#{participant.nickname}WatchMap"
      map[method] nickname, nickname


  getMachine: ->
    kd.singletons.computeController.storage.machines.get 'uid', @mountedMachineUId
