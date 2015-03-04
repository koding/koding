_               = require 'lodash'
machina         = require 'machina'
kd              = require 'kd'
getNick         = require 'app/util/nick'
KDObject        = kd.Object
remote          = require('app/remote').getInstance()
RealtimeManager = require 'ide/realtimemanager'
socialHelpers   = require './helpers/social'
realtimeHelpers = require './helpers/realtime'

smEvents =
  PREPARE   : 'prepare'
  ACTIVATE  : 'activate'
  TERMINATE : 'terminate'

modelEvents =
  collaboration :
    UNINITIALIZED : 'CollaborationUninitialized'
    PREPARED      : 'CollaborationPrepared'
    ACTIVE        : 'CollaborationActive'
    TERMINATED    : 'CollaborationTerminated'
    QUITTED       : 'CollaborationQuitted'
  participant   :
    JOIN          : 'ParticipantJoined'
    LEAVE         : 'ParticipantLeft'
    WATCH         : 'ParticipantWatched'
    UNWATCH       : 'ParticipantUnwatched'
    KICK          : 'ParticipantKicked'
    JOIN_REALTIME : 'ParticipantJoinedRealtime'
    LEAVE_REALTIME: 'ParticipantLeftRealtime'
  realtime      :
    CHANGE        : 'ChangeHappened'
    BROADCAST     : 'BroadcastMessageArrived'
    PERMISSION    : 'PermissionChanged'
    SESSION_CHECK : 'SessionCheckFinished'
  social :
    READY         : 'ChannelReady'

realtimeEvents =
  FILE_LOADED   : 'FileLoaded'
  VALUE_ADDED   : 'ValuesAddedToList'
  VALUE_REMOVED : 'ValuesRemovedFromList'
  MAP_CHANGED   : 'MapValueChanged'
  JOIN          : 'CollaboratorJoined'
  LEAVE         : 'CollaboratorLeft'
  TERMINATED    : 'SessionEnded'

socialEvents =
  READY : 'ChannelReady'
  JOIN  : 'AddedToChannel'
  LEAVE : 'RemovedFromChannel'

class CollaborationModel extends KDObject

  constructor: (options = {}, data) ->

    super options, data

    { @workspace } = options
    @channelId = @workspace?.channelId or null
    @rtm = new RealtimeManager
    @initStateMachine()

    @on 'ParticipantKicked', (args...) => @emit 'ParticipantLeft', args...


  initStateMachine: ->

    @stateMachine = new machina.Fsm
      initialState: 'uninitialized'
      states:
        uninitialized:
          _onEnter: @bound 'handleUninitialized'
        prepared:
          _onEnter: @bound 'handlePrepared'
        active:
          _onEnter: @bound 'handleActive'
        terminated:
          _onEnter: @bound 'handleTerminated'
        quitted:
          _onEnter: @bound 'handleQuitted'


  setState: (state) ->

    @stateMachine.transition state
    @emit 'change', { state }


  handleUninitialized: ->

    @emit modelEvents.collaboration.UNINITIALIZED

    unless @channelId
      @rtm.ready => @setState 'prepared'
      return

    socialHelpers.fetchChannel @channelId, (err, channel) =>
      return @handleError 'fetchSocialChannel', err  if err
      @setChannel channel

      @rtm.ready =>
        fileId = @getFileIdentifier @channelId
        realtimeHelpers.isSessionActive @rtm, fileId, (isActive, file) =>
          if isActive
            realtimeHelpers.loadCollaborationFile @rtm, file.id, =>
              @setState 'active'
          else
            @setState 'prepared'


  handlePrepared: ->

    @emit modelEvents.collaboration.PREPARED


  handleActive: ->

    { initialSnapshot } = @getOptions()
    @references = realtimeHelpers.getReferences @rtm, @channelId, initialSnapshot
    @subscribeToRealtimeManager()
    @subscribeToSocialChannel()

    @emit modelEvents.collaboration.ACTIVE


  handleTerminated: ->

    @emit modelEvents.collaboration.TERMINATED


  handleQuitted: ->

    @emit modelEvents.collaboration.QUITTED


  handleParticipantKicked: (nickname) ->

    @removeParticipant nickname


  leave: (callback) ->

    @broadcastMessage origin: getNick(), type: 'ParticipantWantsToLeave'
    socialHelpers.leaveChannel @channel, (err, channel) =>
      return @handleError 'leaveChannel', err  if err
      @removeParticipant getNick()
      @setState 'quitted'


  removeParticipant: (nickname) ->

    realtimeHelpers.removeFromManager @rtm, @references, nickname


  terminate: do ->
    terminateConstraints =
      channelTerminated: no
      realtimeTerminated: no
      workspaceTerminated: no
    transitionIfReady = (model) ->
      ready = _.all terminateConstraints, Boolean
      model.setState 'terminated'  if ready
    ->
      @broadcastMessage { origin: getNick(), type: realtimeEvents.TERMINATED }
      @references.snapshot.clear()
      @terminateChannel terminateConstraints, =>
        @terminateWorkspace terminateConstraints, =>
          transitionIfReady this

      @terminateRealtimeManager terminateConstraints, =>
        transitionIfReady this

      transitionIfReady this


  terminateChannel: (constraints, callback) ->

    socialHelpers.destroyChannel @channel, (err) =>
      return @handleError 'terminateChannel', err  if err
      @channel = null
      constraints?.channelTerminated = yes
      callback?()


  terminateWorkspace: (constraints, callback) ->

    {JWorkspace} = remote.api
    options = $unset: channelId: 1
    JWorkspace.update @workspace._id, options, (err) =>
      return @handleError 'terminateWorkspace', err  if err
      @workspace.channelId = null
      constraints.workspaceTerminated = yes
      callback()


  terminateRealtimeManager: (constraints, callback) ->

    realtimeHelpers.deleteCollaborationFile @rtm, @getFileIdentifier(), =>
      @rtm.dispose()
      @rtm = null
      constraints.realtimeTerminated = yes
      callback()


  kick: (account) ->

    user = account.profile.nickname

    socialHelpers.kickParticipants @channel, account, (err, result) =>
      return @handleError 'kick', err  if err
      message =
        type   : modelEvents.participant.KICK
        origin : getNick()
        target : user

      @broadcastMessage message
      @emit modelEvents.participant.KICK, user


  addChange: (change) -> @references.changes.push change

  getSnapshot: -> @references?.snapshot

  getWatchMap: -> @references.watchMap

  amIWatchingChangeOwner : (change) -> change.origin in @getWatchMap().keys()

  ###*
   * @param {String}  - message.origin
   * @param {String}  - message.type
   * @param {String=} - message.target
  ###
  broadcastMessage: (message) -> @references.broadcastMessages.push message


  setChannel: (channel) -> @channel = channel


  activate: ->

    { createCollaborationFile
      loadCollaborationFile
    } = realtimeHelpers

    socialHelpers.initChannel (err, channel) =>
      return @handleError 'initChannel', err  if err
      @channel = channel
      @channelId = channel.id
      fileIdentifier = "#{getNick()}.#{@channelId}"
      createCollaborationFile @rtm, fileIdentifier, (file) =>
        loadCollaborationFile @rtm, file.id, =>
          @updateWorkspace { channelId: channel.id }, (err) =>
            return @handleError 'initChannel', err  if err
            @workspace.channelId = channel.id
            @setState 'active'


  updateWorkspace: (options = {}, callback) ->

    return if @workspace.isDummy
      @createWorkspace().then (workspace) =>
        @workspace = _.assign @workspace, workspace
        callback null
      .error callback

    return remote.api.JWorkspace.update @workspace._id, { $set : options }
      .then => callback null
      .error callback

  createWorkspace: (options = {}) ->

    name         = options.name or 'My Workspace'
    rootPath     = "/home/#{getNick()}"
    {label, uid} = @options.machine

    options = _.assign {}, options,
      name         : name
      label        : options.label        or label
      machineUId   : options.machineUId   or uid
      machineLabel : options.machineLabel or label
      rootPath     : options.rootPath     or rootPath
      isDefault    : name is 'My Workspace'

    return remote.api.JWorkspace.create options


  getParticipants: -> @rtm.getFromModel('participants').asArray()


  getParticipantInfo: (nickname) ->

    watchList         = @rtm.getFromModel("#{nickname}WatchMap").keys()
    isWatching        = watchList.indexOf(nickname) > -1
    permissionsMap    = @rtm.getFromModel 'permissions'
    defaultPermission = permissionsMap.get 'default'
    permission        = permissionsMap.get(nickname) or defaultPermission

    return { isWatching, permission }

  addParticipant: (account) ->

    {hash, nickname} = account.profile
    @references.participants.push { nickname, hash }


  subscribeToSocialChannel: ->

    @channel.on socialEvents.JOIN, (participant) =>
      return  unless participant.constructorName is 'JAccount'
      remote.cacheable 'JAccount', participant._id, (err, account) =>
        return @handleError 'fetchAccount', err  if err
        @emit modelEvents.participant.JOIN, account.profile.nickname

    @channel.on socialEvents.LEAVE, (participant) =>
      return  unless participant.constructorName is 'JAccount'
      remote.cacheable 'JAccount', participant._id, (err, account) =>
        return @handleError 'fetchAccount', err  if err
        @emit modelEvents.participant.LEFT, account.profile.nickname


  subscribeToRealtimeManager: ->

    @rtm.on realtimeEvents.VALUE_ADDED, (list, event) =>
      [value] = event.values
      switch list
        when @references.changes
          @emit modelEvents.realtime.CHANGE, { change: value }

        when @references.broadcastMessages
          @emit modelEvents.realtime.BROADCAST, { message: value }

    @rtm.on realtimeEvents.VALUE_REMOVED, (list, event) =>
      [value] = event.values
      if list is @references.changes
        @emit modelEvents.realtime.CHANGE, { change: value }

    @rtm.on realtimeEvents.MAP_CHANGED, (map, event) =>
      {property, newValue} = event
      if map is @references.watchMap
        if property is newValue
          @emit modelEvents.participant.WATCH, property
        else unless newValue
          @emit modelEvents.participant.UNWATCH, property
      else if map is @references.permissions
        @emit modelEvents.realtime.PERMISSION, { property, type: newValue }

    # for both joined and left check CollaborationController#handleParticipantAction
    @rtm.on realtimeEvents.JOIN, (doc, participantData) => kd.utils.wait 2000, =>
      {participants} = @references
      {sessionId}    = participantData.collaborator
      targetUser     = null
      targetIndex    = null

      for participant, index in participants.asArray() when participant.sessionId is sessionId
        targetUser  = participant.nickname
        targetIndex = index

      unless targetUser
        return console.warn 'Unknown user in collaboration, we should handle this case...'

      @emit modelEvents.participant.JOIN_REALTIME, targetUser

    @rtm.on realtimeEvents.LEAVE, (doc, participantData) => kd.utils.wait 2000, =>
      {participants}            = @references
      {sessionId}               = participantData.collaborator
      {getTargetUser}           = realtimeHelpers
      targetUser     = null
      targetIndex    = null

      for participant, index in participants.asArray() when participant.sessionId is sessionId
        targetUser  = participant.nickname
        targetIndex = index

      user = participants.get targetIndex

      unless user.nickname is targetUser
        for p, index in participants.asArray() when p.sessionId is sessionId
          targetUser  = p.nickname
          targetIndex = index

      participants.remove targetIndex

      @emit modelEvents.participant.LEAVE_REALTIME, targetUser


  getFileIdentifier: -> "#{@options.host}.#{@channelId}"

  handleError: (type, err) ->

    @throwError "#{type}: #{JSON.stringify err}"


  watch: (nickname) ->

    { watchMap } = @references
    watchMap.set nickname, nickname


  unwatch: (nickname) ->

    { watchMap } = @references
    watchMap.delete nickname, nickname


  throwError: throwError = (err, args...) ->

    format = \
      switch typeof err
        when 'string' then err
        when 'object' then err.message
        else args.join ' '

    argIndex = 0
    console.error """
      IDE.CollaborationModel:
      #{ format.replace /%s/g, -> args[argIndex++] or '%s' }
    """


instances = []

getByWorkspace = (workspace) ->

  [tuple] = instances.filter (tuple) -> tuple.workspace is workspace
  return tuple?.instance

createTuple = (options) ->
  options.initialSnapshot or= {}
  tuple =
    workspace: options.workspace
    instance : new CollaborationModel options

create = (options) ->
  instances.push tuple = createTuple options
  return tuple.instance

deleteFromCache = (model) ->
  [tuple] = instances.filter (t) -> t.instance is model
  instances.splice instances.indexOf(tuple), 1

module.exports = {
  getByWorkspace
  create
  deleteFromCache
  helpers:
    realtime : realtimeHelpers
    social   : socialHelpers
}

