machina = require 'machina'
RealtimeManager = require 'ide/realtimemanager'
getNick = require 'app/util/nick'
_ = require 'lodash'

create = (fileIdentifier) ->
  rtmMachine = new machina.Fsm
    initialState: 'loading'

    initialize: (options) ->
      @manager = new RealtimeManager
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

      uninitialized:
        _onEnter             : -> @_checkSessionActivity()
        sessionCheckFinished : (result) ->
          @constraints.uninitialized.checkList.active = result.active
          @nextIfReady()
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

    whenLoadingFinished: (callback) ->
      if @loaded
        callback()
      else
        listener = @on 'LoadingFinished', ->
          callback()
          listener.off()

    _activateManager: ->
      createCollaborationFile @manager, fileIdentifier, (file) =>
        loadCollaborationFile @manager, file.id, =>
          @constraints.activating.checkList.active = yes
          @handle 'managerActive'

    _checkSessionActivity: ->
      isSessionActive @manager, fileIdentifier, (isActive, file) =>
        if isActive
          loadCollaborationFile @manager, file.id, =>
            @handle 'sessionCheckFinished', { active: yes }
        else
          @handle 'sessionCheckFinished', { active: no }

    _terminateManager: ->
      @manager.once 'FileDeleted', => @handle 'managerTerminated'
      @manager.deleteFile fileIdentifier

loadCollaborationFile = (manager, id, callback) ->
  manager.once 'FileLoaded', (doc) ->
    manager.setRealtimeDoc doc
    manager.isReady = yes
    callback()
  manager.getFile id

createCollaborationFile = (manager, id, callback) ->
  manager.once 'FileCreated', (file) ->
    callback file
  manager.createFile id

isSessionActive = (manager, title, callback) ->
  manager.once 'FileQueryFinished', (file) ->
    if file.result.items.length > 0
    then callback yes, file.result.items[0]
    else callback no
  manager.fetchFileByTitle title

module.exports = { create }
