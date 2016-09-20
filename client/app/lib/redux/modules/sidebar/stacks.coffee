_ = require 'lodash'
kd = require 'kd'
isAdmin = require 'app/util/isAdmin'
immutable = require 'app/util/immutable'
showError = require 'app/util/showError'
whoami = require 'app/util/whoami'
getMachineOwner = require 'app/util/getMachineOwner'
isStackTemplateSharedWithTeam = require 'app/util/isstacktemplatesharedwithteam'
{ series, waterfall } = require 'async'
{ createSelector } = require 'reselect'


{ makeNamespace, expandActionType,
  normalize, defineSchema } = require 'app/redux/helper'

withNamespace = makeNamespace 'koding', 'sidebar', 'stacks'

GENERATE_STACK = expandActionType withNamespace 'GENERATE_STACK'
EDIT = expandActionType withNamespace 'EDIT'
INITIALIZE = expandActionType withNamespace 'INITIALIZE'
{ LOAD, REMOVE } = require 'app/redux/modules/bongo'

bongo = require 'app/redux/modules/bongo'

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

initializeStack = (template) -> (dispatch) ->
  { reactor } = kd.singletons

  waterfall([
    (next) ->
      dispatch {
        types: [LOAD.BEGIN, LOAD.SUCCESS, LOAD.FAIL]
        bongo: -> template.generateStack().then (result) ->
          { stack, results: { machines } } = result
          instances = []
          instances.push stack
          machines.forEach (machine) -> instances.push machine.obj
          next null, machines[0].obj
          reactor.dispatch 'GENERATE_STACK_SUCCESS', { template, stack }

          return instances
        }

    (machine, next) ->
      console.log '???? ', machine, ' should be null amk', machine.label
      new kd.NotificationView { title: 'Stack generated successfully' }
      reloadIDE machine.label
      next()
  ])
  console.log 'something'


openOnGitlab = (stack) ->

  remoteUrl = stack.getAt ['config', 'remoteDetails', 'originalUrl']
  kd.singletons.linkController.openOrFocus remoteUrl


handleRoute = (route) ->

  kd.singletons.router.handleRoute route


setAccess = (template) ->

  return  unless template

  return {
    types: 'UPDATE'
    promise: -> new Promise (resolve, reject) ->
      template.setAccess 'group', (err) ->
        return resolve()  unless err
        reject()
  }

makeTeamDefault = (template, credential) ->

  kd.singletons.computeController.makeTeamDefault2 template, credential, ->
    console.log '??? make team default'


destroyStack = (stack, machines, type = 'deleteStack') ->

  return  unless stack

  { computeController, appManager } = kd.singletons

  return {
    types: [REMOVE.BEGIN, REMOVE.SUCCESS, REMOVE.FAIL]
    promise: -> new Promise (resolve, reject) ->
      computeController.ui.askFor type, {}, (status) ->

        return  unless status.confirmed # reject

        appManager.quitByName 'IDE', ->
          computeController.destroyStack stack, (err) ->

            return  if showError err # reject
            result = []
            result.push stack

            machines.forEach (machine) -> result.push machine
            handleRoute '/IDE'
            return resolve result

          , followEvents = no
  }


reloadIDE = (machineSlug) ->
  console.log 'machine Slug ', machineSlug
  { computeController } = kd.singletons
  computeController.reloadIDE machineSlug


reinitStack = (stack, machines, template) -> (dispatch) ->

  return  unless template or not stack

  { computeController, appManager } = kd.singletons

  series([
    (next) -> dispatch(destroyStack stack, machines, 'reinitStack').then ->
      next()
    (next) ->
      initializeStack(template)(dispatch)
  ])




# selectors

myStackTemplates = createSelector(
  bongo.all 'JStackTemplate'
  (templates) -> _.pickBy templates, (template) -> template.originId is whoami()._id
)

myStacks = createSelector(
  bongo.all 'JComputeStack'
  (stacks) -> _.pickBy stacks, (stack) -> stack.originId is whoami()._id
)

privateStackTemplates = createSelector(
  myStackTemplates
  (templates) -> templates and _.values(templates).filter (template) -> template.accessLevel is 'private'
)

teamStackTemplates = createSelector(
  myStackTemplates
  (templates) -> templates and _.values(templates).filter (template) -> template.accessLevel is 'group'
)

draftStackTemplates = createSelector(
  myStacks
  myStackTemplates
  (stacks, templates) ->
    return null  unless stacks and templates

    baseStackIds = _.values(stacks).map (s) -> s.baseStackId
    _.pickBy templates, (template) -> not (template._id in baseStackIds)
)


sidebarStacks = createSelector(
  myStacks
  draftStackTemplates
  (stacks, templates) ->
    return null  unless stacks and templates

    _.merge stacks, templates
)

stacksAndMachines = createSelector(
  sidebarStacks
  bongo.all 'JMachine'
  (stacks, machines) ->
    return null  unless stacks and machines

    return _.mapValues stacks, (stack, key) ->
      return stack.machines
        .map (machineId) -> machines[machineId]
        .filter Boolean
)

stacksAndTemplates = createSelector(
  sidebarStacks
  myStackTemplates
  (stacks, templates) ->
    return null unless stacks and templates

    return _.mapValues stacks, (stack, key) ->
      if stack.baseStackId
        templates[stack.baseStackId]
      else stack
)

stacksAndCredential = createSelector(
  sidebarStacks
  bongo.all 'JCredential'
  (stacks, credentials) ->
    return _.mapValues stacks, (stack, key) ->
      provider = stackProvider stack
      return _.values(credentials)
        .filter (credential) ->
          stack.credentials?["#{provider}"]?.first is credential.identifier
)

stackProvider = (stack) ->

  { config, credentials } = stack
  return 'managedVM'  unless config
  { requiredProviders } = config
  for selectedProvider in requiredProviders
    break  if selectedProvider in ['aws', 'vagrant']

  selectedProvider ?= (Object.keys credentials ? { aws: yes }).first
  selectedProvider ?= 'aws'

  return selectedProvider


stacksRevisionStatus = (state) ->

  state.stacksAndRevisions


stacksAndMenuItems = createSelector(
  sidebarStacks
  stacksRevisionStatus
  (stacks, status) ->

    return unless stacks and status

    return _.mapValues stacks, (stack, key) ->
      menuItems = {}

      if stack.bongo_.constructorName is 'JComputeStack'
        revision = status?[stack._id]
        if revision?.status?.code
          menuItems['Update'] = null

        managedVM = stack.title.indexOf('Managed VMs') > -1

        if managedVM
          menuItems['VMs'] = null
        else
          menuItems['Edit'] = null  if isAdmin() and not stack.config.oldOwner
          menuItems['Reinitialize'] = null  unless stack.config.oldOwner
          ['VMs', 'Destroy VMs'].forEach (name) ->
            menuItems[name] = null
          if isAdmin() and not isStackTemplateSharedWithTeam stack.baseStackId
            menuItems['Make Team Default'] = null
        return menuItems
      else
        ['Edit', 'Initialize'].forEach (name) -> menuItems[name] = null
        menuItems['Make Team Default'] = null  if isAdmin() and not stack.baseStackId
        return menuItems
)


sharedVMs = createSelector(
  bongo.all 'JMachine'
  (machines) ->

    _.values(machines).filter (machine) ->
      return no  unless machine.users.length > 1

      # dont show sharedVMs to its owner
      { profile: { nickname } } = whoami()
      ownerNickname = getMachineOwner machine, yes
      nickname isnt ownerNickname
)



module.exports = _.assign reducer, {
  namespace: withNamespace()
  reducer, initializeStack
  openOnGitlab, handleRoute
  destroyStack, reinitStack
  reloadIDE, setAccess
  makeTeamDefault
  stacksAndMachines
  stacksAndMenuItems
  stacksAndTemplates
  stacksAndCredential
  sharedVMs
  sidebarStacks
}

