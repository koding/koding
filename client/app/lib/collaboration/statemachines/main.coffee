machina = require 'machina'
getNick = require 'app/util/nick'
_ = require 'lodash'

ChannelStateMachine = require './channel'
RealtimeStateMachine = require './realtime'

create = (workspace = null, initialSnapshot) ->
  channelId = workspace?.channelId or null
  hostMachine = new machina.Fsm
    initialState: 'loading'
    initialize: (options) ->
      @channelMachine  = ChannelStateMachine.create channelId
      @realtimeMachine = RealtimeStateMachine.create getFileIdentifier channelId
      @workspace       = workspace
      @loaded = no
      @on 'transition', (data) =>
        { fromState } = data
        return  unless fromState
        eventName = "#{fromState.capitalize()}Finished"
        @emit eventName

      @on 'LoadingFinished', => @loaded = yes

    constraints:
      loading:
        nextState: 'uninitialized'
        checkList:
          channelMachineLoaded: no
          realtimeMachineLoaded: no
      uninitialized:
        nextState: 'active'
        checkList: [
          -> @channelMachine.state is 'active'
          -> @realtimeMachine.state is 'active'
        ]
      activating:
        nextState: 'activated'
        checkList: [
          -> @channelMachine.state is 'active'
          -> @realtimeMachine.state is 'active'
          -> @workspace?
        ]
      terminating:
        nextState: 'terminated'
        checkList: [
          -> @channelMachine.state is 'terminated'
          -> @realtimeMachine.state is 'terminated'
        ]

    states:
      loading:
        _onEnter: ->
          @channelMachine.whenLoadingFinished =>
            @constraints.loading.checkList.channelMachineLoaded = yes
            @nextIfReady()
          @realtimeMachine.whenLoadingFinished =>
            @constraints.loading.checkList.realtimeMachineLoaded = yes
            @nextIfReady()

      uninitialized:
        _onEnter: ->
          @emit 'CollaborationUninitialized'
          @channelMachine.on 'UninitializedFinished', => @nextIfReady()
          @realtimeMachine.on 'UninitializedFinished', => @nextIfReady()
          @nextIfReady()

        activate: -> @transition 'activating'

      activating:
        _onEnter             : -> @_activateCollaboration()
        channelMachineReady  : -> @nextIfReady()
        realtimeMachineReady : -> @nextIfReady()
        workspaceReady       : -> @nextIfReady()

      active:
        _onEnter: ->
          @rtm        = @realtimeMachine.manager
          @references = getReferences @rtm, channelId, initialSnapshot
          @_subscribeToRealtimeManager()
          @emit 'CollaborationActive',
            channel         : @channelMachine.channel
            realtimeManager : @realtimeMachine.manager

        broadcast        : (data) -> @_broadcastMessage data
        terminate        : -> @transition 'terminating'
        leave            : -> @transition 'leaving'

      terminating:
        _onEnter                  : -> @_terminateCollaboration()
        channelMachineTerminated  : -> @nextIfReady()
        realtimeMachineTerminated : -> @nextIfReady()

      leaving:
        _onEnter           : -> @_leaveCollaboration()
        participantRemoved : -> @transition 'terminated'

      terminated:
        _onEnter : -> @emit 'CollaborationTerminated'

      communicating:
        changeHappened: (change) ->
          @emit 'ChangeHappened', { change }
          @transition 'active'

        broadcastMessageArrived: (message) ->
          @emit 'BroadcastMessageArrived', { message }
          @transition 'active'

        participantJoined: (nickname) ->
          @emit 'ParticipantJoined', { nickname }
          @transition 'active'

        participantLeft: (nickname) ->
          @emit 'ParticipantLeft', { nickname }
          @transition 'active'

        participantWatched: (nickname) ->
          @emit 'ParticipantWatched', { nickname }
          @transition 'active'

        participantUnwatched: (nickname) ->
          @emit 'ParticipantUnwatched', { nickname }
          @transition 'active'

        permissionChanged: (property, type) ->
          @emit 'PermissionChanged', { type, property }
          @transition 'active'

    nextIfReady: ->
      constraint = @constraints[@state]
      ready = _.all constraint.checkList, (checkItem) =>
        checkItem = checkItem.call this  if 'function' is typeof checkItem
        return checkItem
      @transition constraint.nextState  if ready

    whenLoadingFinished: (callback) ->
      if @loaded
        callback()
      else
        event = @on 'LoadingFinished', ->
          callback()
          event.off()

    leave: -> @handle 'leave'

    getParticipants: ->
      @rtm.getFromModel('participants').asArray()

    getParticipantInfo: (nickname) ->
      watchList         = @rtm.getFromModel("#{nickname}WatchMap").keys()
      isWatching        = watchList.indexOf(nickname) > -1
      permissionsMap    = @rtm.getFromModel 'permissions'
      defaultPermission = permissionsMap.get 'default'
      permission        = permissionsMap.get(nickname) or defaultPermission

      return { isWatching, permission }

    setParticipantPermission: (nickname, permission) ->
      @rtm.getFromModel('permissions').set nickname, permission

    _activateCollaboration: ->
      @channelMachine.on 'ChannelReady', ({channel}) => @handle 'channelMachineReady', channel
      @realtimeMachine.on 'ManagerReady', ({manager}) => @handle 'realtimeMachineReady', manager
      @channelMachine.activate()
      @realtimeMachine.activate()

    _terminateCollaboration: ->
      @channelMachine.on 'ChannelTerminated', => @handle 'channelMachineTerminated'
      @realtimeMachine.on 'ManagerTerminated', => @handle 'realtimeMachineTerminated'

    _leaveCollaboration: ->
      @channelMachine.on 'ChannelTerminated', =>
        @_removeParticipant getNick()

    _removeParticipant: (nickname) ->
      removeParticipantFromMaps @realtimeMachine.manager, nickname
      removeParticipantFromParticipantList @references, nickname
      removeParticipantFromPermissions @references, nickname
      @handle 'participantRemoved', nickname

    _subscribeToRealtimeManager: ->
      @rtm.on 'ValuesAddedToList', (list, event) =>
        @transition 'communicating'
        [value] = event.values
        action = switch list
          when @references.changes           then 'changeHappened'
          when @references.broadcastMessages then 'broadcastMessageArrived'
        @handle action, value

      @rtm.on 'ValuesRemovedFromList', (list, event) =>
        @transition 'communicating'
        [value] = event.values
        @handle 'changeHappened', value  if list is @references.changes

      @rtm.on 'MapValueChanged', (map, event) =>
        @transition 'communicating'
        {property, newValue} = event
        if map is @references.watchMap
          if property is newValue
            @handle 'participantWatched', property
          else unless newValue
            @handle 'participantUnwatched', property
        else if map is @references.permissions
          @handle 'permissionChanged', property, newValue

      # for both joined and left check CollaborationController#handleParticipantAction
      @rtm.on 'CollaboratorJoined', (doc, participantData) =>
        @transition 'communicating'
        {participants} = @references
        {sessionId}    = participantData.collaborator
        {targetUser}   = getTargetUser participants, 'sessionId', sessionId

        unless targetUser
          return warn 'Unknown user in collaboration, we should handle this case...'

        @handle 'participantJoined', targetUser

      @rtm.on 'CollaboratorLeft', (doc, participantData) =>
        @transition 'communicating'
        {participants}            = @references
        {sessionId}               = participantData.collaborator
        {targetUser, targetIndex} = getTargetUser participants, 'sessionId', sessionId

        user = participants.get targetIndex

        unless user.nickname is targetUser
          {targetIndex} = getTargetUserWithIndex participants, 'nickname', targetUser

        participants.remove targetIndex
        @handle 'participantLeft', targetUser

  return hostMachine

getFileIdentifier = (id) -> "#{getNick()}.#{id}"

getTargetUserWithIndex = (participants, field, predicateValue) ->
  targetIndex = null
  targetUser  = null
  for p, index in participants when participant[field] is predicateValue
    targetIndex = index
    targetUser  = p.nickname
    break

  return { targetUser, targetIndex }

getReferences = (manager, channelId, initialSnapshot) ->
  nickname          = getNick()
  watchMapName      = "#{nickname}WatchMap"
  snapshotName      = "#{nickname}Snapshot"
  defaultPermission = { default: 'edit' }

  refs =
    participants      : getFromManager manager, 'participants', 'list'
    changes           : getFromManager manager, 'changes', 'list'
    permissions       : getFromManager manager, 'permissions', 'map'
    broadcastMessages : getFromManager manager, 'broadcastMessages', 'list'
    pingTime          : getFromManager manager, 'pingTime', 'list'
    watchMap          : getFromManager manager, watchMapName, 'list'
    snapshot          : getFromManager manager, snapshotName, 'map', initialSnapshot

  manager.bindRealtimeListeners refs.changes, 'list'
  manager.bindRealtimeListeners refs.broadcastMessages, 'list'
  manager.bindRealtimeListeners refs.watchMap, 'map'
  manager.bindRealtimeListeners refs.permissions, 'map'

  registerCollaborationSessionId manager, refs.participants

  return refs

getFromManager = (manager, name, defaultType, defaultValue) ->
  item   = manager.getFromModel name
  item or= manager.create defaultType, name, defaultValue

  return item

registerCollaborationSessionId = (manager, participants) ->
  collaborators = manager.getCollaborators()
  for collaborator in collaborators when collaborator.isMe
    for user, index in participants.asArray() when user.nickname is getNick()
      newData = _.assign {}, user
      newData.sessionId = collaborator.sessionId
      participants.remove index
      participants.insert index, newData

fetchParticipants = (channelId, callback) ->
  {socialapi} = kd.singletons
  socialapi.channel.listParticipants {channelId}, (err, participants) ->
    return callback err  if err
    idList = participants.map ({accountId}) -> accountId
    query  = socialApiId: $in: idList

    remote.api.JAccount.some query, {}
      .then (accounts) -> callback null, accounts

removeParticipantFromParticipantList = (references, nickname) ->
  { participants } = references
  return warn 'participants is not set'  unless participants

  for participant, index in participants.asArray()
    if participant.nickname is nickname
      participants.remove index
      break

removeParticipantFromMaps = (manager, nickname) ->
  myWatchMapName = "#{nickname}WatchMap"
  mySnapshotName = "#{nickname}Snapshot"

  manager.delete 'map', myWatchMapName
  manager.delete 'map', mySnapshotName

removeParticipantFromPermissions = (references, nickname) ->
  references.permissions.delete nickname

module.exports = { create }
