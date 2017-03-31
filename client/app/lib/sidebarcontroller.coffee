debug = require('debug')('sidebar:controller')
kd = require 'kd'
EnvironmentFlux = require 'app/flux/environment'
remote = require 'app/remote'

module.exports = class SidebarController extends kd.Controller

  constructor: (options = {}) ->

    super options

    @invitedId = null
    @leavingId = null

    @selected =
      stackId: null
      machineId: null

    @visibility =
      stacks: {}
      drafts: {}

    @managed = {}

    @bindNotificationHandlers()
    @setStateFromStorage()


  bindNotificationHandlers: ->

    { notificationController, computeController } = kd.singletons

    computeController.ready =>
      notificationController
        .on 'MachineShare:Added', @bound 'onAddSharedMachine'
        .on 'MachineShare:Removed', @bound 'onRemoveSharedMachine'


  setStateFromStorage: ->

    { computeController } = kd.singletons

    computeController.ready =>
      for machine in computeController.storage.get('machines')
        if not (machine.isMine() or machine.isApproved())
          return @setInvited machine.getId()


  onAddSharedMachine: ({ machine }) ->

    debug 'onAddSharedMachine', { machine }

    @setInvited machine.getId()


  onRemoveSharedMachine: ({ machine }) ->

    debug 'onRemoveSharedMachine', { machine }

    @setInvited null


  subscribeChange: (handler) ->

    changeHandler = => handler @getState()

    @on 'change', changeHandler

    # call the handler for the first time
    kd.utils.defer changeHandler

    return {
      cancel: => @off 'change', changeHandler
    }


  setSelected: (type, id) ->

    @selected[type] = id
    @emit 'change'


  setInvited: (machineId) ->

    @invitedId = machineId
    @emit 'change'


  setLeaving: (machineId) ->

    @leavingId = machineId
    @emit 'change'


  loadVisibilityFilters: ->

    fetchVisibility().then (filters) => @setVisibility filters


  setVisibility: (type, id, state) ->

    fetchVisibility()
      .then (filters) =>
        filters[type][id] = state
        return filters

    new Promise (resolve) ->
      appStorageController.storage('Sidebar')
        .fetchValue 'visibility', (filters) =>
          @setVisibilityFilters filters
          resolve filters


  addManaged: (id) ->

    debug 'add managed vm', { id }

    @managed[id] = id
    @emit 'change'


  removeManaged: (id) ->

    debug 'remove managed vm', { id }

    delete @managed[id]
    @emit 'change'


  getManaged: ->

    first = Object.keys(@managed)?.first

    if first then first else null


  getState: (selector = identity) ->
    return selector {
      selected: @selected
      leavingId: @leavingId
      invitedId: @invitedId
      managedId: @getManaged()
    }


identity = (state) -> state

fetchVisibility = ->

  { appStorageController } = kd.singletons

  new Promise (resolve) ->
    appStorageController.storage('Sidebar').fetchValue 'visibility', resolve


saveVisibility = (filters) ->

  { appStorageController } = kd.singletons

  new Promise (resolve) ->
    appStorageController.storage('Sidebar').setValue 'visibility', filters, ->
      resolve filters
