machina = require 'machina'
RealtimeManager = require 'ide/realtimemanager'
getNick = require 'app/util/nick'
_ = require 'lodash'

create = (fileIdentifier) ->
  rtmMachine = new machina.Fsm
    initialState: 'loading'

    initialize: (options) ->
      @manager = new RealtimeManager

    constraints:
      loading:
        nextState: 'uninitialized'
        checkList: { ready: no }

      uninitialized:
        nextState: 'active'
        checkList: { active: no }

      activating:
        nextState: 'active'
        checkList: { active: no }

      terminating:
        nextState: 'terminated'
        checkList: { terminated: no }

    states:
      loading:
        _onEnter: ->
          @manager.ready =>
            @constraints.loading.checkList.ready = yes
            @nextIfReady()
        _onExit: ->
          @emit 'LoadingFinished'

      uninitialized:
        _onEnter             : -> @_checkSessionActivity()
        sessionCheckFinished : -> @nextIfReady()
        activate             : -> @transition 'activating'

      activating:
        _onEnter      : -> @_activateManager()
        managerActive : -> @nextIfReady()

      active: ->
        _onEnter  : -> @emit 'ManagerReady', { @manager }
        terminate : -> @transition 'terminating'

      terminating:
        _onEnter         : -> @_terminateManager()
        managerDestroyed : -> @nextIfReady()

      terminated:
        _onEnter: -> @emit 'ManagerTerminated'

    activate: -> @handle 'activate'

    terminate: -> @handle 'terminate'

    nextIfReady: ->
      constraint = @constraints[@state]
      ready = _.all constraint.checkList, Boolean
      @transition constraint.nextState  if ready

    _activateManager: (callbacks) ->
      @manager.once 'FileLoaded', (doc) =>
        @manager.setRealtimeDoc doc
        @constraints.activating.checkList.active = yes
        @handle 'managerActive'

      @manager.once 'FileCreated', (file) =>
        @manager.getFile file.id

      @manager.createFile fileIdentifier

    _checkSessionActivity: ->
      isSessionActive @manager, fileIdentifier, (isActive) =>
        console.log {isActive}
        if isActive
          @constraints.uninitialized.checkList.active = yes
        @handle 'sessionCheckFinished'

    _terminateManager: ->
      @manager.once 'FileDeleted', => @handle 'managerTerminated'
      @manager.deleteFile fileIdentifier

isSessionActive = (manager, title, callback) ->
  manager.once 'FileQueryFinished', (file) ->
    if file.result.items.length > 0
    then callback yes, file
    else callback no
  manager.fetchFileByTitle title

module.exports = { create }
