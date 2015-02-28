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
          @channelMachine.on 'LoadingFinished', =>
            @constraints.loading.checkList.channelMachineLoaded = yes
            @nextIfReady()
          @realtimeMachine.on 'LoadingFinished', =>
            @constraints.loading.checkList.realtimeMachineLoaded = yes
            @nextIfReady()

      uninitialized:
        _onEnter: ->
          @emit 'CollaborationUninitialized'
          @nextIfReady()

        activate: -> @transition 'activating'

      activating:
        _onEnter             : -> @_activateCollaboration()
        channelMachineReady  : -> @nextIfReady()
        realtimeMachineReady : -> @nextIfReady()
        workspaceReady       : -> @nextIfReady()

      active:
        _onEnter: ->
          @emit 'CollaborationActive',
            channel         : @channelMachine.channel
            realtimeManager : @realtimeMachine.manager

          @_subscribeToRealtimeManager()

        broadcast: (data) -> @_broadcastMessage data
        terminate: -> @transition 'terminating'

      terminating:
        _onEnter                  : -> @_terminateCollaboration()
        channelMachineTerminated  : -> @nextIfReady()
        realtimeMachineTerminated : -> @nextIfReady()

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
        checkItem = checkItem()  if 'function' is typeof checkItem
        return checkItem
      @transition constraint.nextState  if ready

    _activateCollaboration: ->
      @channelMachine.on 'ChannelReady', ({channel}) => @handle 'channelReady', channel
      @realtimeMachine.on 'ManagerReady', ({manager}) => @handle 'realtimeMachineReady', manager
      @channelMachine.init()
      @realtimeMachine.activate()

    _terminateCollaboration: ->
      @channelMachine.on 'ChannelDestroyed', => @handle 'channelMachineTerminated'
      @realtimeMachine.on 'ManagerTerminated', => @handle 'realtimeMachineTerminated'

    _subscribeToRealtimeManager: ->
      @manager.on 'ValuesAddedToList', (list, event) =>
        @transition 'communicating'
        [value] = event.values
        action = switch list
          when @references.changes           then 'changeHappened'
          when @references.broadcastMessages then 'broadcastMessageArrived'
        @handle action, value

      @manager.on 'ValuesRemovedFromList', (list, event) =>
        @transition 'communicating'
        [value] = event.values
        @handle 'changeHappened', value  if list is @references.changes

      @manager.on 'MapValueChanged', (map, event) =>
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
      @manager.on 'CollaboratorJoined', (doc, participantData) =>
        @transition 'communicating'
        {participants} = @references
        {sessionId}    = participantData.collaborator
        {targetUser}   = getTargetUser participants, 'sessionId', sessionId

        unless targetUser
          return warn 'Unknown user in collaboration, we should handle this case...'

        @handle 'participantJoined', targetUser

      @manager.on 'CollaboratorLeft', (doc, participantData) =>
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
  manager.bindRealtimeListeners refs.myWatchMap, 'map'
  manager.bindRealtimeListeners refs.permissions, 'map'

  return refs

getFromManager = (manager, name, defaultType, defaultValue) ->
  item   = manager.getFromModel name
  item or= manager.create defaultType, name, defaultValue

  return item

fetchParticipants = (channelId, callback) ->
  {socialapi} = kd.singletons
  socialapi.channel.listParticipants {channelId}, (err, participants) ->
    return callback err  if err
    idList = participants.map ({accountId}) -> accountId
    query  = socialApiId: $in: idList

    remote.api.JAccount.some query, {}
      .then (accounts) -> callback null, accounts

module.exports = { create }
