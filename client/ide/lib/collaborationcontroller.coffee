_                             = require 'lodash'
remote                        = require('app/remote').getInstance()
dateFormat                    = require 'dateformat'
sinkrow                       = require 'sinkrow'
globals                       = require 'globals'
kd                            = require 'kd'
KDNotificationView            = kd.NotificationView
nick                          = require 'app/util/nick'
getCollaborativeChannelPrefix = require 'app/util/getCollaborativeChannelPrefix'
showError                     = require 'app/util/showError'
whoami                        = require 'app/util/whoami'
RealtimeManager               = require './realtimemanager'
IDEChatView                   = require './views/chat/idechatview'
IDEMetrics                    = require './idemetrics'
doXhrRequest                  = require 'app/util/doXhrRequest'
realtimeHelpers               = require './collaboration/helpers/realtime'
socialHelpers                 = require './collaboration/helpers/social'
envHelpers                    = require './collaboration/helpers/environment'

{warn} = kd

# Attn!!
#
# This object is designed to be a mixin for IDEAppController.
#
# @see `IDEAppController`

module.exports =

  # social related

  setSocialChannel: (channel) ->

    @socialChannel = channel


  initPrivateMessage: (callback) ->

    socialHelpers.initChannel (err, channel) =>
      return callback err  if err

      @setSocialChannel channel
      envHelpers.updateWorkspace @workspaceData, { channelId : channel.id }
        .then =>
          @workspaceData.channelId = channel.id
          callback null, channel
          @chat.ready => @chat.emit 'CollaborationNotInitialized'
        .error callback


  fetchSocialChannel: (callback) ->

    if @socialChannel
      return callback null, @socialChannel

    unless id = @getSocialChannelId()
      return callback()

    socialHelpers.fetchChannel id, (err, channel) =>
      return callback err  if err

      @setSocialChannel channel
      callback null, @socialChannel


  getSocialChannelId: ->

    return @socialChannel?.id or @channelId or @workspaceData.channelId


  unsetSocialChannel: -> @channelId = @socialChannel = null


  deletePrivateMessage: (callback = kd.noop) ->

    socialHelpers.destroyChannel @socialChannel, (err) =>
      return callback err  if err

      envHelpers.detachSocialChannel @workspaceData, (err) =>
        return callback err  if err
        @unsetSocialChannel()


  # FIXME: This method is called more than once. It should cache the result and
  # return if result set exists.
  listChatParticipants: (callback) ->

    id = @getSocialChannelId()

    socialHelpers.fetchParticipants id, (err, accounts) =>
      return throwError err  if err

      callback accounts


  continuePrivateMessage: (callback) ->

    @chat.emit 'CollaborationStarted'

    @listChatParticipants (accounts) =>
      @statusBar.emit 'ShowAvatars', accounts, @participants.asArray()

    callback null


  startChatSession: (callback) ->

    channelId = @channelId or @workspaceData.channelId

    if channelId
    then @reactivateChatSession callback
    else @initPrivateMessage callback


  reactivateChatSession: (callback) ->

    @fetchSocialChannel (err, channel) =>
      if err or not channel
        return @initPrivateMessage callback

      @createChatPaneView channel
      @isRealtimeSessionActive channel.id, (isActive, file) =>
        if isActive
          @whenRealtimeReady => @continuePrivateMessage callback
          return @loadCollaborationFile file.id

        @statusBar.share.show()
        @chat.emit 'CollaborationNotInitialized'


  getRealtimeFileName: (id) ->

    unless id = @getSocialChannelId()
      return showError 'social channel id is not provided'

    hostName = @getCollaborationHost()

    return "#{hostName}.#{id}"


  stopChatSession: ->

    @chat.emit 'CollaborationEnded'
    @chat = null


  whenRealtimeReady: (callback) ->

    if @rtm?.isReady
    then callback()
    else @once 'RTMIsReady', callback


  showChat: ->

    return @createChatPane()  unless @chat

    @chat.start()


  createChatPane: ->

    @startChatSession (err, channel) =>

      return showError err  if err

      @createChatPaneView channel


  createChatPaneView: (channel) ->
    return throwError 'RealtimeManager is not set'  unless @rtm

    options = { @rtm, @isInSession }
    @getView().addSubView @chat = new IDEChatView options, channel
    @chat.show()

    @on 'RTMIsReady', =>
      @listChatParticipants (accounts) =>
        @chat.settingsPane.createParticipantsList accounts

      @statusBar.emit 'CollaborationStarted'

      {settingsPane} = @chat

      settingsPane.on 'ParticipantKicked', @bound 'handleParticipantKicked'
      settingsPane.updateDefaultPermissions()


  kickParticipant: (account) ->

    return  unless @amIHost

    targetUser = account.profile.nickname

    displayError = (err) ->
      showError err
      throwError err

    @setMachineUser [targetUser], no, (err) =>
      return displayError err  if err

      socialHelpers.kickParticipants @socialChannel, [account], (err, result) =>
        return displayError err  if err

        message    =
          type     : 'ParticipantKicked'
          target   : targetUser

        @broadcastMessage message
        @handleParticipantKicked targetUser


  handleParticipantKicked: (username) ->

    @chat.emit 'ParticipantLeft', username
    @statusBar.removeParticipantAvatar username
    @removeParticipantCursorWidget username
    # remove participant's all data persisted in realtime appInfo
    @removeParticipant username


  handleParticipantAction: (actionType, changeData) ->

    return  unless @rtm

    kd.utils.wait 2000, => @whenRealtimeReady =>

      switch actionType
        when 'join' then @onRealtimeParticipantJoined changeData
        when 'left' then @onRealtimeParticipantLeft changeData


  onRealtimeParticipantJoined: (data) ->

    {sessionId} = data.collaborator

    {targetUser} =
      realtimeHelpers.getTargetUser @participants, 'sessionId', sessionId

    unless targetUser
      return kd.warn 'Unknown user in collaboration, we should handle this case...'

    @chat.emit 'ParticipantJoined', targetUser
    @statusBar.emit 'ParticipantJoined', targetUser

    if @amIHost
      @ensureMachineShare [targetUser], (err) =>
        return throwError err  if err


  onRealtimeParticipantLeft: (data) ->

    {sessionId} = data.collaborator

    {targetUser, targetIndex} =
      realtimeHelpers.getTargetUser @participants, 'sessionId', sessionId

    unless targetUser
      return kd.warn 'Unknown user in collaboration, we should handle this case...'

    @chat?.emit 'ParticipantLeft', targetUser
    @statusBar.emit 'ParticipantLeft', targetUser
    @removeParticipantCursorWidget targetUser

    realtimeHelpers.ensureParticipantLeft @participants, targetUser, targetIndex


  # realtime related stuff


  broadcastMessage: (options = {}) ->

    message = _.assign {}, options, { origin: nick() }
    @broadcastMessages.push message


  activateRealtimeManager: (doc) ->

    @rtm.setRealtimeDoc doc
    @setCollaborativeReferences()
    @addParticipant whoami()
    @registerCollaborationSessionId()
    @bindRealtimeEvents()

    if @amIHost
    then @activateRealtimeManagerForHost()
    else @activateRealtimeManagerForParticipant()

    @rtm.isReady = yes
    @emit 'RTMIsReady'

    unless @myWatchMap.values().length
      @listChatParticipants (accounts) =>
        accounts.forEach (account) =>
          {nickname} = account.profile
          @myWatchMap.set nickname, nickname


  activateRealtimeManagerForHost: ->

    @getView().setClass 'host'
    @startHeartbeat()


  activateRealtimeManagerForParticipant: ->

    @startRealtimePolling()
    @resurrectSnapshot()

    if @collaborationHost in @myWatchMap.values()
      @reviveHostSnapshot()

    if @permissions.get(nick()) is 'read'
      @makeReadOnly()


  loadCollaborationFile: (fileId) ->

    return  unless fileId

    @rtmFileId = fileId

    realtimeHelpers.loadCollaborationFile @rtm, fileId, (err, doc) =>
      return throwError err  if err

      @activateRealtimeManager doc
      @bindSocialChannelEvents()
      @finderPane.on 'ChangeHappened', @bound 'syncChange'


  reviveHostSnapshot: ->

    hostName     = @getCollaborationHost()
    hostSnapshot = realtimeHelpers.getFromManager @rtm, "#{hostName}Snapshot"

    for key, change of hostSnapshot.values()
      @createPaneFromChange change


  setCollaborativeReferences: ->

    initialSnapshot = if @amIHost then @getWorkspaceSnapshot() else {}

    refs = realtimeHelpers.getReferences @rtm, @getSocialChannelId(), initialSnapshot

    # for backwards compatibility.
    # TODO: keep this until CollaborationModel abstraction. ~Umut
    @participants      = refs.participants
    @changes           = refs.changes
    @permissions       = refs.permissions
    @broadcastMessages = refs.broadcastMessages
    @myWatchMap        = refs.watchMap
    @mySnapshot        = refs.snapshot


  registerCollaborationSessionId: ->

    realtimeHelpers.registerCollaborationSessionId @rtm, @participants


  addParticipant: (account) ->

    {hash, nickname} = account.profile

    val = {nickname, hash}
    index = @participants.indexOf val, (a, b) -> a.nickname is b.nickname
    @participants.push val  if index is -1


  watchParticipant: (nickname) -> @myWatchMap.set nickname, nickname


  unwatchParticipant: (nickname) -> @myWatchMap.delete nickname


  bindSocialChannelEvents: ->

    @socialChannel.on 'AddedToChannel', (socialAccount) =>

      socialHelpers.fetchAccount socialAccount, (account) =>

        return  unless account

        {nickname} = account.profile
        @statusBar.createParticipantAvatar nickname, no
        @watchParticipant nickname


  bindRealtimeEvents: ->

    @rtm.on 'CollaboratorJoined', (doc, participant) =>
      @handleParticipantAction 'join', participant

    @rtm.on 'CollaboratorLeft', (doc, participant) =>
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


  removeParticipant: (nickname) ->

    refs = { @participants, @permissions }

    realtimeHelpers.removeFromManager @rtm, refs, nickname


  setRealtimeManager: (object) ->

    callback = =>
      object.rtm = @rtm
      object.emit 'RealtimeManagerSet'

    if @rtm?.isReady then callback() else @once 'RTMIsReady', => callback()


  isRealtimeSessionActive: (id, callback) ->

    title = @getRealtimeFileName id

    @rtm or= new RealtimeManager
    @rtm.ready => realtimeHelpers.isSessionActive @rtm, title, callback


  getCollaborationData: (callback = kd.noop) ->

    collaborationData =
      watchMap        : @myWatchMap?.values()
      amIHost         : @amIHost

    callback collaborationData


  startHeartbeat: ->

    interval = 1000 * 15
    @sendPing() # send the first ping
    @pingInterval = kd.utils.repeat interval, @bound 'sendPing'


  sendPing: ->

    {channelId} = @workspaceData

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
        throwError "bad request, err: %s", err.message
      else
        throwError "#{err}: %s", JSON.stringify response


  startRealtimePolling: ->

    interval = 15 * 1000
    @pollInterval = kd.utils.repeat interval, @bound 'pollRealtimeDocument'


  pollRealtimeDocument: ->

    unless @rtm
      kd.utils.killRepeat @pollInterval
      return

    id = @getSocialChannelId()

    @isRealtimeSessionActive id, (isActive) =>

      return  if isActive

      kd.utils.killRepeat @pollInterval
      @showSessionEndedModal()


  handleBroadcastMessage: (data) ->

    {origin, type} = data

    if origin is nick()
      switch type
        when 'ParticipantWantsToLeave'
          @removeMachineNode()
          return kd.utils.defer @bound 'quit'
        when 'ParticipantKicked'
          return @handleParticipantKicked data.target
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
          @removeMachineNode()
          @showKickedModal()
        else
          @handleParticipantKicked data.target

      when 'SetMachineUser'

        return  if data.participants.indexOf(nick()) is -1

        @handleSharedMachine()


  handlePermissionMapChange: (event) ->

    @chat.settingsPane.emit 'PermissionChanged', event

    {property, newValue} = event

    return  unless property is nick()

    if      newValue is 'edit' then @makeEditable()
    else if newValue is 'read' then @makeReadOnly()


  handleWatchMapChange: (event) ->

    {property, newValue, oldValue} = event

    if newValue is property
      @statusBar.emit 'ParticipantWatched', property

    else unless newValue
      @statusBar.emit 'ParticipantUnwatched', property


  handleSharedMachine: ->

    @unmountMachine @mountedMachine
    @mountedMachine.getBaseKite().reconnect()
    @mountMachine @mountedMachine


  resurrectSnapshot: ->

    return  if @collaborationJustInitialized or @fakeTabView

    mySnapshot   = @mySnapshot.values().filter (item) -> return not item.isInitial
    hostSnapshot = @rtm.getFromModel("#{@collaborationHost}Snapshot")?.values()
    snapshot     = if hostSnapshot then mySnapshot.concat hostSnapshot else mySnapshot

    @forEachSubViewInIDEViews_ (pane) =>
      @removePaneFromTabView pane  if pane.isInitial

    for change in snapshot when change.context
      @changeActiveTabView change.context.paneType
      @createPaneFromChange change


  showShareButton: ->

    @ready =>
      @statusBar.handleCollaborationLoading()
      @statusBar.share.show()


  collectButtonShownMetric: ->

    IDEMetrics.collect 'StatusBar.collaboration_button', 'shown'


  setCollaborationState: (state) ->

    @stateMachine.transition state
    @emit 'change', { state }


  initCollaborationStateMachine: ->



  prepareCollaboration: ->

    @initCollaborationStateMachine()


  startCollaborationSession: (callback) ->

    return callback msg : 'no social channel'  unless @socialChannel

    kallback = (err, channel) => @whenRealtimeReady => callback err, channel
    socialHelpers.sendActivationMessage @socialChannel, kallback

    @collaborationJustInitialized = yes

    @rtm or= new RealtimeManager
    title  = @getRealtimeFileName()

    realtimeHelpers.createCollaborationFile @rtm, title, (err, file) =>
      return throwError err  if err
      @loadCollaborationFile file.id

    @setMachineSharingStatus on, (err) ->
      throwError err  if err


  # should clean realtime manager.
  # should delete workspace channel id.
  # should broadcast the session ended message.
  # IF USER IS HOST
  #   should delete private message.
  #   should set machine sharing status to off.
  # IF USER IS NOT HOST
  #   should only call the callback without an error.
  #   given callback should do the rest. (e.g cleaning-up, quitting..)
  stopCollaborationSession: (callback) -> @whenRealtimeReady =>

    @chat.settingsPane.endSession.disable()

    return callback msg : 'no social channel'  unless @socialChannel

    if @amIHost
      @broadcastMessage { type: 'SessionEnded' }

    title = @getRealtimeFileName()
    realtimeHelpers.deleteCollaborationFile @rtm, title, (err) =>
      return throwError err  if err
      @setMachineSharingStatus off, (err) =>
        return callback err  if err
        @deletePrivateMessage (err) =>
          return callback err  if err
          @cleanupCollaboration { reinit: yes }
          callback()

      @statusBar.emit 'CollaborationEnded'
      @stopChatSession()
      @modal?.destroy()


    @mySnapshot.clear()


  getCollaborationHost: -> if @amIHost then nick() else @collaborationHost


  cleanupCollaboration: (options = {}) ->
    return warn 'RealtimeManager is not set'  unless @rtm

    kd.utils.killRepeat @pingInterval
    @rtm?.dispose()
    @rtm = null
    kd.singletons.mainView.activitySidebar.emit 'ReloadMessagesRequested'
    @forEachSubViewInIDEViews_ 'editor', (ep) => ep.removeAllCursorWidgets()

    { reinit } = options

    @prepareCollaboration()  if reinit

  # environment related


  removeMachineNode: ->

    kd.singletons.mainView.activitySidebar.removeMachineNode @mountedMachine


  ensureMachineShare: (usernames, callback) ->

    {fetchMissingParticipants} = envHelpers

    fetchMissingParticipants @mountedMachine, usernames, (err, missing) =>
      return callback err  if err

      @setMachineUser missing, yes, callback


  setMachineSharingStatus: (status, callback) ->

    getUsernames = (accounts) ->

      accounts
        .map ({profile: {nickname}}) -> nickname
        .filter (nickname) -> nickname isnt nick()

    if @amIHost
      @listChatParticipants (accounts) =>
        usernames = getUsernames accounts
        @setMachineUser usernames, status, callback
    else
      @setMachineUser [nick()], status, callback


  setMachineUser: (usernames, share = yes, callback = kd.noop) ->

    # TODO: needs an investigation here.
    # if this usernames length check would be done
    # via helper method, the broadcastMessage
    # lines would be executed as well. attn to @szkl.
    return callback null  unless usernames.length

    {setMachineUser} = envHelpers

    setMachineUser @mountedMachine, usernames, share, (err) =>
      if err
        return  if err.message is 'User not found' and not share
        return callback err  if err

      @whenRealtimeReady =>
        @broadcastMessage
          type: "#{if share then 'Set' else 'Unset'}MachineUser"
          participants: usernames

      callback null


  # collab related modals (should be its own mixin)


  showEndCollaborationModal: (callback) ->

    modalOptions =
      title      : 'Are you sure?'
      content    : 'This will end your session and all participants will be removed from this session.'

    @showModal modalOptions, => @stopCollaborationSession callback


  showKickedModal: ->
    options        =
      title        : 'Your session has been closed'
      content      : "You have been removed from the session by @#{@collaborationHost}."
      blocking     : yes
      buttons      :
        ok         :
          title    : 'OK'
          style    : 'solid green medium'
          callback : => @modal.destroy()

    @showModal options
    @quit()


  showSessionEndedModal: (content) ->

    content ?= "This collaboration session has been terminated by the host @#{@collaborationHost}."

    options        =
      title        : 'Session ended'
      content      : content
      blocking     : yes
      buttons      :
        quit       :
          style    : 'solid light-gray medium'
          title    : 'LEAVE'
          callback : =>
            @modal.destroy()
            @quit()
            @removeMachineNode()

    @showModal options


  handleParticipantLeaveAction: ->

    options   =
      title   : 'Are you sure?'
      content : "If you leave this session you won't be able to return back."

    @showModal options, =>
      @stopChatSession()
      @modal.destroy()

      options = channelId: @socialChannel.getId()
      kd.singletons.socialapi.channel.leave options, (err) =>
        return showError err  if err
        @setMachineUser [nick()], no, =>
          # remove the leaving participant's info from the collaborative doc
          @whenRealtimeReady =>
            @broadcastMessage { type: 'ParticipantWantsToLeave' }
            @removeParticipant nick()


  throwError: throwError = (err, args...) ->

    format = \
      switch typeof err
        when 'string' then err
        when 'object' then err.message
        else args.join ' '

    argIndex = 0
    console.error """
      IDE.CollaborationController:
      #{ format.replace /%s/g, -> args[argIndex++] or '%s' }
    """
