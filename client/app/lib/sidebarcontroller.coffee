debug = require('debug')('sidebar:controller')
kd = require 'kd'
EnvironmentFlux = require 'app/flux/environment'
remote = require 'app/remote'
{ isObject } = require 'lodash'

module.exports = class SidebarController extends kd.Controller

  @FilterType = {
    Hidden: 'hidden'
    Visible: 'visible'
  }

  constructor: (options = {}) ->

    super options

    @_templateEventCache = {}

    @invitedId = null
    @leavingId = null

    @selected =
      templateId: null
      stackId: null
      machineId: null

    @visibility =
      stack: {}
      draft: {}

    @managed = {}

    @updatedStack = null

    @isDefaultStackUpdated = no

    @bindNotificationHandlers()
    @bindComputeHandlers()
    @setStateFromStorage()
    @loadVisibilityFilters()


  bindNotificationHandlers: ->

    { notificationController, computeController } = kd.singletons

    computeController.ready =>
      notificationController
        .on 'MachineShare:Added', @bound 'onAddSharedMachine'
        .on 'MachineShare:Removed', @bound 'onRemoveSharedMachine'


  bindComputeHandlers: ->

    { computeController } = kd.singletons
    { storage } = computeController

    computeController.ready =>
      computeController.on 'GroupStacksInconsistent', =>
        @setDefaultStackUpdated updated = yes

      computeController.on 'GroupStacksConsistent', =>
        @setDefaultStackUpdated updated = no

      storage.on 'change:templates', (event) =>
        { operation, value: template } = event

        # add a handler for each template push
        if operation is 'push' and not @_templateEventCache[template.getId()]
          debug 'binding template events', template
          template.on 'update', =>
            debug 'template has an update event', template
            stacks = storage.stacks.query 'baseStackId', template.getId()

            for stack in stacks when stack.stackRevision isnt template.getRevisionStatus()
              debug 'a stack generated from template has update', { template, stack }
              @_templateEventCache[template.getId()] = yes
              return @setUpdatedStack stack.getId()

            # no matter what emit a change event to make sidebar re-render with
            # updated stack. this is required for template updates without sum
            # change.
            @emit 'change'

        # clean up handler if the template is removed from storage
        if operation is 'pop' and @_templateEventCache[template.getId()]
          delete @_templateEventCache[template.getId()]


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

    if isObject type
    then @selected = Object.assign @selected, type
    else @selected[type] = id

    @emit 'change'


  setInvited: (machineId) ->

    @invitedId = machineId
    @emit 'change'


  setLeaving: (machineId) ->

    @leavingId = machineId
    @emit 'change'


  loadVisibilityFilters: ->

    fetchVisibility().then (filters) =>
      debug 'visibility filters fetched', filters
      if filters
        @visibility = filters
        @emit 'change'


  saveVisibility: (type, id, state) ->

    Promise.resolve @visibility
      .then (filters) ->
        filters[type][id] = state
        return filters

      .then (filters) ->
        return saveVisibility(filters)

      .then (filters) =>
        @visibility = filters
        return filters

      .then (filters) =>
        @emit 'change'
        return filters


  makeVisible: (type, id) ->

    debug 'make visible', { type, id }

    { FilterType } = SidebarController

    @saveVisibility type, id, FilterType.Visible


  makeHidden: (type, id) ->

    debug 'make hidden', { type, id }

    { FilterType } = SidebarController

    @saveVisibility type, id, FilterType.Hidden


  isVisible: (type, id) ->

    { FilterType } = SidebarController

    isVisible = if visibility = @visibility[type]?[id]
    then visibility is SidebarController.FilterType.Visible
    else yes

    debug 'is visible', { isVisible, visibility }

    return isVisible


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


  setUpdatedStack: (id) ->

    debug 'set updated stack', { id }

    @updatedStack = id
    @emit 'change'


  setDefaultStackUpdated: (state) ->

    debug 'set default stack updated', { state }

    @isDefaultStackUpdated = state
    @emit 'change'


  getState: (selector = identity) ->
    return selector {
      selected: @selected
      leavingId: @leavingId
      invitedId: @invitedId
      managedId: @getManaged()
      updatedStackId: @updatedStack
      isDefaultStackUpdated: @isDefaultStackUpdated
    }


identity = (state) -> state

fetchVisibility = ->

  { appStorageController } = kd.singletons

  new Promise (resolve) ->
    appStorageController.storage('Sidebar').fetchValue 'visibility', resolve


saveVisibility = (filters) ->

  { appStorageController } = kd.singletons

  debug 'save visibility', filters

  new Promise (resolve) ->
    appStorageController.storage('Sidebar').setValue 'visibility', filters, ->
      fetchVisibility().then resolve
