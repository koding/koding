debug           = (require 'debug') 'ide:routes'

kd              = require 'kd'
nick            = require 'app/util/nick'
showError       = require 'app/util/showError'
remote          = require 'app/remote'
actions         = require 'app/flux/environment/actions'
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

    { sidebar } = kd.singletons

    sidebar.setSelected 'machineId', machine.getId()

    if parent = machine.generatedFrom
    then sidebar.setSelected 'templateId', parent.templateId
    else sidebar.setSelected 'templateId', null

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

  if not Cookies.get('use-ose') and not machine.isBuilt()
    debug 'new build flow', "/Stack-Editor/Build/#{machine.getId()}"
    kd.singletons.router.handleRoute "/Stack-Editor/Build/#{machine.getId()}"
    return

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

  { computeController: cc, socialapi, router } = kd.singletons
  { machine, slug, uid } = options

  if machine
    loadIDE { machine }

  else
    cc.ready ->

      if uid
        machine = cc.storage.machines.get 'uid', uid
        debug 'machine with uid', { uid, machine }

      if not machine and slug
        for machine in cc.storage.machines.query 'slug', slug
          break  if machine.isMine()
        debug 'machine with slug', { slug, machine }

      if machine

        if channelId = machine.getChannelId()

          socialapi.cacheable 'channel', channelId, (err, channel) ->

            if err or not channel
              return loadIDE { machine }

            query = { socialApiId: channel.creatorId }

            remote.api.JAccount.some query, {}, (err, account) ->

              if err or not account
                console.warn 'Account not found'
                return loadIDE { machine }

              username  = account.first.profile.nickname
              channelId = channel.id

              loadIDE { machine, username, channelId }

        else

          loadIDE { machine }

      else

        [ machine ] = cc.storage.machines.get()

        if machine
          router.handleRoute "/IDE/#{machine.slug}"
        else if router.currentPath is '/IDE'
          loadIDENotFound()
        else
          router.handleRoute '/IDE'


routeHandler = (type, info, state, path, ctx) ->

  # This is just a dirty workaround to be able to run the unit tests because
  # exported functions are not the same functions as the defined ones,
  # this is to make spies work in the future we hope to find a better way and
  # remove this imports. -- acet /cc usirin
  { routeToMachine } = module.exports

  debug 'hit', type, info

  switch type

    when 'home' then routeToMachine()

    when 'machine'

      { machineLabel } = info.params

      if machineLabel is 'test-machine'
        routeToTestWorkspace()
      else
        slug = uid = machineLabel
        routeToMachine { slug, uid }

    when 'workspace'

      # for old links
      { machineLabel } = info.params
      kd.getSingleton('router').handleRoute "/IDE/#{machineLabel}"



module.exports = {

  loadIDENotFound
  loadIDE
  routeToMachine
  findInstance
  routeHandler

  init: -> lazyrouter.bind 'ide', (type, info, state, path, ctx) ->

    routeHandler type, info, state, path, ctx

}
