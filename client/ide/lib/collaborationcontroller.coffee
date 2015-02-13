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
RealTimeManager               = require './realtimemanager'
IDEChatView                   = require './views/chat/idechatview'
IDEMetrics                    = require './idemetrics'

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

    @socialChannel.on 'AddedToChannel', (originOrAccount) =>

      kallback = (account) =>

        return  unless account

        {nickname} = account.profile
        @statusBar.createParticipantAvatar nickname, no
        @watchParticipant nickname

      if originOrAccount.constructorName
        remote.cacheable originOrAccount.constructorName, originOrAccount.id, kallback
      else if 'string' is typeof originOrAccount
        remote.cacheable originOrAccount, kallback
      else
        kallback originOrAccount


  initPrivateMessage: (callback) ->

    {message} = kd.singletons.socialapi
    nickname  = nick()

    options =
      type       : 'collaboration'
      body       : "@#{nickname} initiated the IDE session."
      purpose    : "#{getCollaborativeChannelPrefix()}#{dateFormat 'HH:MM'}"
      recipients : [ nickname ]
      payload    :
        'system-message' : 'initiate'
        collaboration    : yes

    message.initPrivateMessage options, (err, channels) =>

      return callback err  if err or (not Array.isArray(channels) and not channels[0])

      [channel] = channels
      @setSocialChannel channel

      @updateWorkspace { channelId : channel.id }
        .then =>
          @workspaceData.channelId = channel.id
          callback null, channel
          @chat.ready => @chat.emit 'CollaborationNotInitialized'
        .error callback


  fetchSocialChannel: (callback) ->

    return callback null, @socialChannel  if @socialChannel

    id = @channelId or @workspaceData.channelId

    return callback()  unless id

    kd.singletons.socialapi.cacheable 'channel', id, (err, channel) =>
      return callback err  if err

      @setSocialChannel channel

      callback null, @socialChannel


  deletePrivateMessage: (callback = kd.noop) ->

    {channel}    = kd.getSingleton 'socialapi'
    {JWorkspace} = remote.api

    options = channelId: @socialChannel.getId()
    channel.delete options, (err) =>

      return callback err  if err

      @channelId = @socialChannel = null

      options = $unset: channelId: 1
      JWorkspace.update @workspaceData._id, options, (err) =>

        return callback err  if err

        @workspaceData.channelId = null
        callback null


  # FIXME: This method is called more than once. It should cache the result and
  # return if result set exists.
  listChatParticipants: (callback) ->

    channelId = @socialChannel.getId()

    {socialapi} = kd.singletons
    socialapi.channel.listParticipants {channelId}, (err, participants) ->

      idList = participants.map ({accountId}) -> accountId
      query  = socialApiId: $in: idList

      remote.api.JAccount.some query, {}
        .then callback


  continuePrivateMessage: (callback) ->

    @on 'RTMIsReady', =>
      @chat.emit 'CollaborationStarted'

      @listChatParticipants (accounts) =>
        @statusBar.emit 'ShowAvatars', accounts, @participants.asArray()

      callback null


  startChatSession: (callback) ->

    return if @workspaceData.isDummy
      @createWorkspace()
        .then (workspace) =>
          @workspaceData = workspace
          @initPrivateMessage callback
        .error callback

    channelId = @channelId or @workspaceData.channelId

    if channelId

      @fetchSocialChannel (err, channel) =>
        if err or not channel
          return @initPrivateMessage callback

        @createChatPaneView channel
        @isRealtimeSessionActive channelId, (isActive, file) =>
          if isActive
            @loadCollaborationFile file.result.items[0].id
            return @continuePrivateMessage callback

          @statusBar.share.show()
          @chat.emit 'CollaborationNotInitialized'

    else
      @initPrivateMessage callback


  getRealTimeFileName: (id) ->

    unless id
      if @channelId          then id = @channelId
      else if @socialChannel then id = @socialChannel.id
      else
        return showError 'social channel id is not provided'

    hostName = if @amIHost then nick() else @collaborationHost

    return "#{hostName}.#{id}"


  stopChatSession: ->

    @chat.emit 'CollaborationEnded'
    @chat = null


  showChat: ->

    return @createChatPane()  unless @chat

    @chat.start()


  createChatPane: ->

    @startChatSession (err, channel) =>

      return showError err  if err

      @createChatPaneView channel


  createChatPaneView: (channel) ->
    return throwError 'RealTimeManager is not set'  unless @rtm

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

    options      =
      channelId  : @socialChannel.id
      accountIds : [ account.socialApiId ]

    targetUser = account.profile.nickname

    @setMachineUser [targetUser], no, (err) =>

      kd.singletons.socialapi.channel.kickParticipants options, (err, result) =>

        return showError err  if err

        message    =
          type     : 'ParticipantKicked'
          origin   : nick()
          target   : targetUser

        @broadcastMessages.push message
        @handleParticipantKicked targetUser


  handleParticipantKicked: (username) ->

    @chat.emit 'ParticipantLeft', username
    @statusBar.removeParticipantAvatar username
    @removeParticipantCursorWidget username
    # remove participant's all data persisted in realtime appInfo
    @removeParticipant username


  handleParticipantAction: (actionType, changeData) ->

    kd.utils.wait 2000, =>
      participants  = @participants.asArray()
      {sessionId}   = changeData.collaborator
      targetUser    = null
      targetIndex   = null

      for participant, index in participants when participant.sessionId is sessionId
        targetUser  = participant.nickname
        targetIndex = index

      unless targetUser
        return warn 'Unknown user in collaboration, we should handle this case...'

      if actionType is 'join'
        @chat.emit 'ParticipantJoined', targetUser
        @statusBar.emit 'ParticipantJoined', targetUser
      else
        @chat.emit 'ParticipantLeft', targetUser
        @statusBar.emit 'ParticipantLeft', targetUser
        @removeParticipantCursorWidget targetUser

        # check the user is still at same index, so we won't remove someone else.
        user = @participants.get targetIndex

        if user.nickname is targetUser
          @participants.remove targetIndex
        else
          participants = @participants.asArray()
          for participant, index in participants when participant.nickname is targetUser
            @participants.remove index



  # realtime related stuff


  loadCollaborationFile: (fileId) ->

    return unless fileId

    @rtmFileId = fileId

    @rtm.getFile fileId

    @rtm.once 'FileLoaded', (doc) =>
      nickname = nick()
      hostName = @collaborationHost

      @rtm.setRealtimeDoc doc

      @setCollaborativeReferences()

      if @amIHost
        @getView().setClass 'host'
      #   @changes.clear()
      #   @broadcastMessages.clear()

      isInList = no

      @participants.asArray().forEach (participant) =>
        isInList = yes  if participant.nickname is nickname

      if not isInList
        @addParticipant whoami(), no

      @rtm.on 'CollaboratorJoined', (doc, participant) =>
        @handleParticipantAction 'join', participant

      @rtm.on 'CollaboratorLeft', (doc, participant) =>
        @handleParticipantAction 'left', participant

      @registerCollaborationSessionId()
      @bindRealtimeEvents()
      @listenPings()
      @rtm.isReady = yes
      @emit 'RTMIsReady'
      @resurrectSnapshot()  unless @amIHost

      unless @myWatchMap.values().length
        @listChatParticipants (accounts) =>
          accounts.forEach (account) =>
            {nickname} = account.profile
            @myWatchMap.set nickname, nickname

      if not @amIHost and @myWatchMap.values().indexOf(hostName) > -1
        hostSnapshot = @rtm.getFromModel "#{hostName}Snapshot"

        for key, change of hostSnapshot.values()
          @createPaneFromChange change

      @finderPane.on 'ChangeHappened', @bound 'syncChange'

      unless @amIHost
        @makeReadOnly()  if @permissions.get(nickname) is 'read'


  setCollaborativeReferences: ->

    nickname           = nick()
    myWatchMapName     = "#{nickname}WatchMap"
    mySnapshotName     = "#{nickname}Snapshot"
    defaultPermission  = default: 'edit'

    @participants      = @rtm.getFromModel 'participants'
    @changes           = @rtm.getFromModel 'changes'
    @permissions       = @rtm.getFromModel 'permissions'
    @broadcastMessages = @rtm.getFromModel 'broadcastMessages'
    @pingTime          = @rtm.getFromModel 'pingTime'
    @myWatchMap        = @rtm.getFromModel myWatchMapName
    @mySnapshot        = @rtm.getFromModel mySnapshotName

    @participants      or= @rtm.create 'list',   'participants', []
    @changes           or= @rtm.create 'list',   'changes', []
    @permissions       or= @rtm.create 'map',    'permissions', defaultPermission
    @broadcastMessages or= @rtm.create 'list',   'broadcastMessages', []
    @pingTime          or= @rtm.create 'string', 'pingTime'
    @myWatchMap        or= @rtm.create 'map',    myWatchMapName, {}

    initialSnapshot      = if @amIHost then @getWorkspaceSnapshot() else {}
    @mySnapshot        or= @rtm.create 'map',    mySnapshotName, initialSnapshot


  registerCollaborationSessionId: ->

    collaborators = @rtm.getCollaborators()

    for collaborator in collaborators when collaborator.isMe
      participants = @participants.asArray()

      for user, index in participants when user.nickname is nick()
        newData = kd.utils.dict()

        newData[key] = value  for key, value of user

        newData.sessionId = collaborator.sessionId
        @participants.remove index
        @participants.insert index, newData


  addParticipant: (account) ->

    {hash, nickname} = account.profile
    @participants.push { nickname, hash }


  watchParticipant: (nickname) -> @myWatchMap.set nickname, nickname


  unwatchParticipant: (nickname) -> @myWatchMap.delete nickname


  bindRealtimeEvents: ->

    @rtm.bindRealtimeListeners @changes, 'list'
    @rtm.bindRealtimeListeners @broadcastMessages, 'list'
    @rtm.bindRealtimeListeners @myWatchMap, 'map'
    @rtm.bindRealtimeListeners @permissions, 'map'

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


  removeParticipantFromParticipantList: (nickname) ->
    return throwError "participants is not set"  unless @participants

    # find the index for participant
    for participant, index in @participants.asArray()
      if participant.nickname is nickname

        # remove from participants list if the user exits
        @participants.remove index
        break

  removeParticipantFromMaps: (nickname) ->
    return throwError "rtm is not set"   unless @rtm

    myWatchMapName     = "#{nickname}WatchMap"
    mySnapshotName     = "#{nickname}Snapshot"

    # delete the keys
    @rtm.delete 'map', myWatchMapName
    @rtm.delete 'map', mySnapshotName


  removeParticipantFromPermissions: (nickname)->
    return throwError "permissions is not set"   unless @permissions
    # Removes the entry for the given key (if such an entry exists).
    @permissions.delete(nickname)


  removeParticipant: (nickname) ->
    @removeParticipantFromMaps nickname
    @removeParticipantFromParticipantList nickname
    @removeParticipantFromPermissions nickname


  setRealTimeManager: (object) ->

    callback = =>
      object.rtm = @rtm
      object.emit 'RealTimeManagerSet'

    if @rtm?.isReady then callback() else @once 'RTMIsReady', => callback()


  isRealtimeSessionActive: (id, callback) ->

    kallback = =>
      @rtm.once 'FileQueryFinished', (file) =>

        if file.result.items.length > 0
          callback yes, file
        else
          callback no

      @rtm.fetchFileByTitle @getRealTimeFileName id

    if @rtm then kallback()
    else
      @rtm = new RealTimeManager
      @rtm.ready => kallback()


  getCollaborationData: (callback = kd.noop) ->

    collaborationData =
      watchMap        : @myWatchMap?.values()
      amIHost         : @amIHost

    callback collaborationData


  isHostOnline: ->

    host = @getCollaborationHost()

    filtered = @participants
      .asArray()
      .filter (its) -> its.nickname is host

    return no  unless filtered.length

    { sessionId } = filtered.first

    return no  unless sessionId

    final = @rtm
      .getCollaborators()
      .filter (its) -> its.sessionId is sessionId

    return final.length > 0


  listenPings: ->

    pingInterval = 1000 * 5
    pongInterval = 1000 * 15

    @pingInterval = if @amIHost
    then kd.utils.repeat pingInterval, @bound 'sendPing'
    else kd.utils.repeat pongInterval, @bound 'checkPing'


  sendPing: -> @pingTime.setText Date.now().toString()


  forceQuitCollaboration: ->

    { Collaboration } = remote.api
    Collaboration.stop @rtmFileId, @workspaceData, (err) =>

      return warn err  if err

      kd.utils.killRepeat @pingInterval

      @stopCollaborationSession =>
        @quit()

        new KDNotificationView
          title    : "@#{@collaborationHost} has left the session."
          duration : 3000


  checkPing: do ->

    lastCheckedAt = null
    lastPing      = null
    errorTryCount = 3

    return ->

      diffInterval  = globals.config.collaboration.timeout

      ping = @pingTime.getText()

      # kill session if `errorTryCount`
      # limit is passed.
      if errorTryCount <= 0
        @forceQuitCollaboration()
      # update the lastChecked at if the last ping
      # is still the same, decrease the error try count.
      else if ping is lastPing and errorTryCount > 0
        errorTryCount -= 1
        lastCheckedAt = Date.now()
        return
      # this is the happy path.
      else if lastPing - ping < diffInterval
        lastCheckedAt = Date.now()
        lastPing      = ping
        errorTryCount = 3
        return


  # collab related


  handleBroadcastMessage: (data) ->

    {origin, type} = data

    if origin is nick()
      switch type
        when 'ParticipantWantsToLeave'
          return @quit()
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

    @statusBar.share.show()
    IDEMetrics.collect 'StatusBar.collaboration_button', 'shown'


  prepareCollaboration: ->

    @rtm        = new RealTimeManager
    {channelId} = @workspaceData

    @rtm.ready =>
      unless @workspaceData.channelId
        @showShareButton()

      @fetchSocialChannel (err, channel) =>
        if err or not channel
          throwError err  if err
          return @showShareButton()

        @isRealtimeSessionActive channelId, (isActive) =>
          if isActive or @isInSession
            @startChatSession => @chat.showChatPane()
            @chat.hide()
            @statusBar.share.updatePartial 'Chat'

          @showShareButton()


  startCollaborationSession: (callback) ->

    return callback msg : 'no social channel'  unless @socialChannel

    {message} = kd.singletons.socialapi
    nickname  = nick()

    message.sendPrivateMessage
      body       : "@#{nickname} activated collaboration."
      channelId  : @socialChannel.id
      payload    :
        'system-message' : 'start'
        collaboration    : yes
    , callback

    @collaborationJustInitialized = yes

    @rtm = new RealTimeManager  unless @rtm
    @rtm.once 'FileCreated', (file) =>
      @loadCollaborationFile file.id

    @rtm.createFile @getRealTimeFileName()

    @setMachineSharingStatus on


  # should clean realtime manager.
  # should delete workspace channel id.
  # should broadcast the session ended message.
  # IF USER IS HOST
  #   should delete private message.
  #   should set machine sharing status to off.
  # IF USER IS NOT HOST
  #   should only call the callback without an error.
  #   given callback should do the rest. (e.g cleaning-up, quitting..)
  stopCollaborationSession: (callback) ->

    @chat.settingsPane.endSession.disable()

    return callback msg : 'no social channel'  unless @socialChannel

    {message} = kd.singletons.socialapi
    nickname  = nick()

    if @amIHost
      @broadcastMessages.push origin: nickname, type: 'SessionEnded'

    @rtm.once 'FileDeleted', =>
      @statusBar.emit 'CollaborationEnded'
      @stopChatSession()
      @modal?.destroy()

      if @amIHost
        @setMachineSharingStatus off, (err) =>
          return callback err  if err
          @deletePrivateMessage (err) =>
            return callback err  if err
            @cleanupCollaboration { reinit: yes }
      else
        callback null

    @mySnapshot.clear()
    @rtm.deleteFile @getRealTimeFileName()


  getCollaborationHost: -> if @amIHost then nick() else @collaborationHost


  cleanupCollaboration: (options = {}) ->
    return throwError 'RealTimeManager is not set'  unless @rtm

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


  setMachineSharingStatus: (status, callback) ->

    getUsernames = (accounts) ->

      accounts
        .map ({profile: {nickname}}) -> nickname
        .filter (nickname) -> nickname isnt nick()

    if @amIHost
      @listChatParticipants (accounts) =>
        usernames = getUsernames accounts
        @setMachineUser usernames, status
    else
      @setMachineUser [nick()], status


  setMachineUser: (usernames, share = yes, callback = kd.noop) ->

    return callback()  unless usernames.length

    jMachine = @mountedMachine.getData()
    method   = if share then 'share' else 'unshare'
    jMachine[method] usernames, (err) =>

      return callback err  if err

      kite   = @mountedMachine.getBaseKite()
      method = if share then 'klientShare' else 'klientUnshare'

      queue = usernames.map (username) ->
        ->
          kite[method] {username}
            .then -> queue.fin()
            .error (err) ->
              queue.fin()

              return  if err.message in [
                'user is already in the shared list.'
                'user is not in the shared list.'
              ]

              action = if share then 'added' else 'removed'
              message = "#{username} couldn't be #{action} as an user"
              callback { message }
              console.error message

      sinkrow.dash queue, callback


  getWorkspaceName: (callback) -> callback @workspaceData.name


  createWorkspace: (options = {}) ->

    name         = options.name or 'My Workspace'
    rootPath     = "/home/#{nick()}"
    {label, uid} = @mountedMachine

    return remote.api.JWorkspace.create
      name         : name
      label        : options.label        or label
      machineUId   : options.machineUId   or uid
      machineLabel : options.machineLabel or label
      rootPath     : options.rootPath     or rootPath
      isDefault    : name is 'My Workspace'


  updateWorkspace: (options = {}) ->

    return remote.api.JWorkspace.update @workspaceData._id, { $set : options }


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
          callback : => @modal.destroy()

    @showModal options
    @quit()


  showSessionEndedModal: (content) ->

    content ?= "This session is ended by @#{@collaborationHost} You won't be able to access it anymore."

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
      @broadcastMessages.push origin: nick(), type: 'ParticipantWantsToLeave'
      @stopChatSession()
      @modal.destroy()

      options = channelId: @socialChannel.getId()
      kd.singletons.socialapi.channel.leave options, (err) =>
        return showError err  if err
        @setMachineUser [nick()], no, => @quit()
        # remove the leaving participant's info from the collaborative doc
        @removeParticipant nick()


  throwError: throwError = (format, args...) ->

    argIndex = 0
    error = new Error """
      IDE.CollaborationController:
      #{ format.replace /%s/g, -> args[argIndex++] or '%s' }
    """

    throw error
