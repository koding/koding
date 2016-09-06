_ = require 'lodash'
kd = require 'kd'
isAdmin = require 'app/util/isAdmin'
immutable = require 'app/util/immutable'
showError = require 'app/util/showError'
whoami = require 'app/util/whoami'
getMachineOwner = require 'app/util/getMachineOwner'

{ makeNamespace, expandActionType,
  normalize, defineSchema } = require 'app/redux/helper'

withNamespace = makeNamespace 'koding', 'sidebar', 'stacks'

GENERATE_STACK = expandActionType withNamespace 'GENERATE_STACK'
EDIT = expandActionType withNamespace 'EDIT'
INITIALIZE = expandActionType withNamespace 'INITIALIZE'
{ LOAD, REMOVE } = require 'app/redux/modules/bongo'


reducer = (state = immutable({}), action) ->

  switch action.type

    when 'STACK_REVISION_SUCCESS'
      { result: { _id, data, error } } = action
      return state  if error
      state = state.set _id, immutable data

      return state

    else
      return state

# actions

initializeStack = (template) ->

  return {
    types: [LOAD.BEGIN, LOAD.SUCCESS, LOAD.FAIL]
    bongo: -> template.generateStack().then (result) ->

      { stack, results: { machines } } = result
      instances = []
      instances.push stack
      machines.forEach (machine) -> instances.push machine.obj

      return instances
  }


openOnGitlab = (stack) ->

  remoteUrl = stack.getAt ['config', 'remoteDetails', 'originalUrl']
  kd.singletons.linkController.openOrFocus remoteUrl


handleRoute = (route) ->

  kd.singletons.router.handleRoute route


destroyStack = (stack, machines) ->

  return  unless stack

  { computeController, appManager } = kd.singletons

  return {
    types: [REMOVE.BEGIN, REMOVE.SUCCESS, REMOVE.FAIL]
    promise: -> new Promise (resolve, reject) ->
      computeController.ui.askFor 'deleteStack', {}, (status) ->

        return  unless status.confirmed # reject

        appManager.quitByName 'IDE', ->
          computeController.destroyStack stack, (err) ->

            return  if showError err # reject
            result = []
            result.push stack

            machines.forEach (machine) -> result.push machine
            return resolve result

          , followEvents = no
  }


reloadIDE = (machineSlug) ->

  { computeController } = kd.singletons
  computeController.reloadIDE machineSlug


reinitStack = (stack, template) ->

  return  unless template or not stack

  { computeController } = kd.singletons

  console.log 'reinit stack', stack, template
  return {
    type: []
    promise: -> new Promise (resolve, reject) ->
      computeController.ui.askFor 'reinitStack', {}, (status) ->

        return  unless status.confirmed # reject

  }

# selectors

privateStackTemplates = (stackTemplates) ->

  return null  unless stackTemplates

  _.values(stackTemplates).filter (template) ->
    template.accessLevel is 'private'


privateStacks = (stacks) ->

  return null  unless stacks

  _.values(stacks).filter (stack) ->
    not stack.getAt(['config', 'groupStack'])


teamStackTemplates = (stackTemplates) ->

  return null  unless stackTemplates

  _.values(stackTemplates).filter (template) ->
    template.accessLevel is 'group'


teamStacks =  (stacks) ->

  return null  unless stacks

  _.values(stacks).filter (stack) ->
    stack.getAt(['config', 'groupStack'])


draftStackTemplates = (stacks, templates) ->

  return null  unless stacks or not templates

  baseStackIds = _.values(stacks).map (s) -> s.baseStackId

  _.values(templates).filter (template) ->
    not (template._id in baseStackIds)


stacksWithMachines = (stacks, machines) ->

  return null  if not stacks or not machines

  stacksWithMachines = {}
  _.values(stacks).forEach (stack) ->
    stacksWithMachines[stack._id] = []
    stack.machines.forEach (machineId) ->
      if machines[machineId]
        stacksWithMachines[stack._id].push immutable machines[machineId]

  return stacksWithMachines


stacksWithTemplates = (stacks, templates) ->

  return null if not stacks or not templates

  stacksWithTemplates = {}

  baseStackIds = _.values(stacks).map (s) -> s.baseStackId

  _.values(stacks).map (stack) ->
    if templates[stack.baseStackId]
      stacksWithTemplates[stack._id] = templates[stack.baseStackId]

  #drafts
  _.values(templates).forEach (template) ->
    if not (template._id in baseStackIds)
      stacksWithTemplates[template._id] = template

  return stacksWithTemplates


stacksWithMenuItems = (stacks, templates, stacksRevisionStatus) ->

  return unless stacks

  baseStackIds = _.values(stacks).map (s) -> s.baseStackId

  stacksWithMenuItems = {}

  _.values(stacks).forEach (stack) ->
    menuItems = {}
    if stack.machines.length
      revision = stacksRevisionStatus?[stack._id]
      if revision?.status?.code
        menuItems['Update'] = { }

      managedVM = stack.title.indexOf('Managed VMs') > -1

      if managedVM
        menuItems['VMs'] = { }
      else
        menuItems['Edit'] = { }  if isAdmin() and not stack.config.oldOwner
        menuItems['Reinitialize'] = {} unless stack.config.oldOwner
        ['VMs', 'Destroy VMs'].forEach (name) ->
          menuItems[name] = { }

    stacksWithMenuItems[stack._id] = menuItems

    _.values(templates).forEach (template) ->
      menuItems = {}
      # for drafts
      if not (template._id in baseStackIds)
        ['Edit', 'Initialize'].forEach (name) -> menuItems[name] = { }
        stacksWithMenuItems[template._id] = menuItems

  return stacksWithMenuItems

sharedVMs = (machines) ->

  _.values(machines).filter (machine) ->
    return no  unless machine.users.length > 1

    # dont show sharedVMs to its owner
    { profile: { nickname } } = whoami()
    ownerNickname = getMachineOwner machine, yes
    nickname isnt ownerNickname



module.exports = _.assign reducer, {
  namespace: withNamespace()
  reducer
  initializeStack
  openOnGitlab
  handleRoute
  destroyStack
  reinitStack
  reloadIDE
  privateStackTemplates
  privateStacks
  teamStackTemplates
  teamStacks
  stacksWithMachines
  stacksWithMenuItems
  draftStackTemplates
  stacksWithTemplates
  sharedVMs
}

