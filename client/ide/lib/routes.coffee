debug           = (require 'debug') 'ide:routes'

kd              = require 'kd'
nick            = require 'app/util/nick'
showError       = require 'app/util/showError'
remote          = require 'app/remote'
actions         = require 'app/flux/environment/actions'
Machine         = require 'app/providers/machine'
lazyrouter      = require 'app/lazyrouter'


loadIDENotFound = ->

  { appManager } = kd.singletons
  appManager.open 'IDE', { forceNew: yes }, (app) ->
    app.amIHost = yes
    appManager.tell 'IDE', 'showNoMachineState'


loadIDE = (data, done = kd.noop) ->

  debug 'loadIDE called with', data

  { machine, username, channelId, showInstance = yes } = data

  unless machine
    debug 'loadIDE no machine found'
    loadIDENotFound()
    return

  if showInstance

    actions.setSelectedMachineId machine._id

    actions.setSelectedTemplateId  if machine.data?.generatedFrom?
    then machine.data.generatedFrom.templateId
    else null

  appManager = kd.getSingleton 'appManager'
  ideApps    = appManager.appControllers.IDE
  machineUId = machine.uid

  callback   = ->
    appManager.open 'IDE', { forceNew: yes, showInstance }, (app) ->
      app.mountedMachineUId   = machineUId

      if username and username isnt nick()
        app.isInSession       = yes
        app.amIHost           = no
        app.collaborationHost = username
        app.channelId         = channelId
      else
        # Don't remove this flag. Snapshot restoring procedure depends on this property.
        # If you want it, ping Turunc or Acet.
        app.amIHost           = yes

      app.mountMachineByMachineUId machineUId, done

  return callback()  unless ideApps?.instances

  ideInstance = findInstance machine

  if ideInstance and showInstance
    appManager.showInstance ideInstance
  else
    callback()


findInstance = (machine) ->

  { instances } = kd.singletons.appManager.appControllers.IDE

  for instance in instances when instance.mountedMachineUId is machine.uid
    ideInstance = instance

  return ideInstance


routeToTestWorkspace = ->

  kd.singletons.router.handleRoute '/IDE/test-machine'


loadTestIDE = ->

  machine = require('mocks/mockmanagedmachine')()
  machine = remote.revive machine

  require('app/util/createTestMachine')().then ->
    loadIDE { machine, username: nick() }, ->
      require('ide/test/browser').prepare(machine)


routeToMachine = (options = {}) ->

  cc = kd.singletons.computeController
  { machine, label, uid } = options

  if machine and machine instanceof Machine
    loadIDE { machine }

  else
    cc.ready ->

      if label
        machine = cc.storage.get 'machines', 'label', label
        debug 'machine with label', { label, machine }
      else if uid
        machine = cc.storage.get 'machines', 'uid', uid
        debug 'machine with uid', { uid, machine }

      unless machine
        [ machine ] = cc.storage.get 'machines'
        if machine
          if label or uid
            showError 'Requested machine not found, first available machine is loaded instead.'
          kd.getSingleton('router').handleRoute "/IDE/#{machine.label}"
          return

      # if machine.isPermanent() or machine.jMachine.meta?.oldOwner
      #   identifier = machine.uid
      # kd.getSingleton('router').handleRoute "/IDE/#{identifier}"

      loadIDE { machine }


loadCollaborativeIDE = (id) ->

  { loadIDE } = module.exports

  debug 'loadCollaborativeIDE called, loading normal IDE for now'
  routeToMachine()

  # kd.singletons.socialapi.cacheable 'channel', id, (err, channel) ->

  #   return routeToMachine()  if err

  #   try

  #     # FIXMEWS ~ GG
  #     dataProvider.fetchMachineAndWorkspaceByChannelId id, (machine, workspace) ->
  #       return routeToLatestWorkspace()  unless workspace

  #       query = { socialApiId: channel.creatorId }

  #       remote.api.JAccount.some query, {}, (err, account) ->
  #         if err
  #           routeToLatestWorkspace()
  #           return throw new Error err

  #         username  = account.first.profile.nickname
  #         channelId = channel.id

  #         return loadIDE { machine, workspace, username, channelId }

  #   catch e

  #     routeToLatestWorkspace()
  #     return console.error e


routeHandler = (type, info, state, path, ctx) ->

  # This is just a dirty workaround to be able to run the unit tests because
  # exported functions are not the same functions as the defined ones,
  # this is to make spies work in the future we hope to find a better way and
  # remove this imports. -- acet /cc usirin
  { loadCollaborativeIDE, routeToMachine } = module.exports

  debug 'hit', type, info

  switch type

    when 'home' then routeToMachine()

    when 'machine'

      { machineLabel } = info.params
      # routeToMachine machineLabel

      # we assume that if machineLabel is all numbers it is the channelId - SY
      if /^[0-9]+$/.test machineLabel
        loadCollaborativeIDE machineLabel
      else if machineLabel is 'test-machine'
        routeToTestWorkspace()
      else
        routeToMachine { label: machineLabel }

    when 'workspace'

      { machineLabel } = info.params
      kd.getSingleton('router').handleRoute "/IDE/#{machineLabel}"



module.exports = {

  loadIDENotFound
  loadIDE
  routeToMachine
  loadCollaborativeIDE
  findInstance
  routeHandler

  init: -> lazyrouter.bind 'ide', (type, info, state, path, ctx) ->

    routeHandler type, info, state, path, ctx

}
