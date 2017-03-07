async = require 'async'
bongo = require 'bongo'
{ secure, signature } = bongo

JMachine   = require './computeproviders/machine'

SocialChannel = require './socialapi/channel'

KodingError = require '../error'

module.exports = class Sidebar extends bongo.Base

  { revive } = require './computeproviders/computeutils'

  @share()

  @set
    sharedMethods        :
      static             :
        fetchEnvironment : (signature Function)


  @fetchEnvironment = secure revive

    shouldReviveClient   : yes
    shouldReviveProvider : no
    hasOptions           : no

  , (client, callback) ->

    data            =
      collaboration : []
      shared        : []
      own           : []

    { r: { user, group } } = client

    query =
      'users.id'  : user.getId()
      'groups.id' : group.getId()

    JMachine.some query, {}, (err, machines) ->
      return callback new KodingError err  if err

      machineUIds = machines.map (machine) -> machine.uid
      workspaces = []

      options = { client, user, machines, workspaces, callback }
      options.addOwnFn = makeEnvironmentNodeAdderFn data.own
      options.addSharedFn = makeEnvironmentNodeAdderFn data.shared
      options.addCollaborationFn = makeEnvironmentNodeAdderFn data.collaboration
      options.callback = -> callback null, data

      decorateEnvironmentData options


  makeEnvironmentNodeAdderFn = (list) ->

    findNode = (machine) ->

      for node in list
        if machine.uid is node.machine.uid
          return node

    return ({ machine, workspace }) ->

      unless node = findNode machine
        node = { machine, workspaces: [] }
        list.push node

      { workspaces } = node
      workspaces.push workspace  if workspace


  decorateEnvironmentData = (options) ->

    { client, user } = options
    { machines, workspaces } = options
    { addOwnFn, addSharedFn, addCollaborationFn } = options
    { callback } = options

    machineMap = {}

    machines.forEach (machine) ->
      machineMap[machine.uid] = machine

      addNodeFn = switch
        when isMachineOwner user, machine
          addOwnFn
        when isMachineShared user, machine
          addSharedFn

      addNodeFn? { machine }

    workspaceQueue = workspaces.map (workspace) ->

      machine = machineMap[workspace.machineUId]

      nodeValue = { machine, workspace }

      return (workspaceQueueFin) ->

        makeFailureFn = (callback) ->

          return callback

        makeSuccessFn = (fn, callback) ->

          return ->

            fn.call null, nodeValue
            callback()

        filterQueue = [

          (fin) ->

            successFn = makeSuccessFn addOwnFn, fin
            failureFn = makeFailureFn fin

            if isMachineOwner user, machine
            then successFn()
            else failureFn()

          (fin) ->

            successFn = makeSuccessFn addSharedFn, fin
            failureFn = makeFailureFn fin

            if isMachineShared user, machine
            then successFn()
            else failureFn()

          (fin) ->

            return fin()  unless workspace.channelId

            isOwner  = isMachineOwner  user, machine
            isShared = isMachineShared user, machine
            skip     = workspace.channelId and (isOwner or isShared)

            return fin()  if skip

            successFn = makeSuccessFn addCollaborationFn, fin
            failureFn = makeFailureFn fin

            options = { client, user, workspace, successFn, failureFn }
            filterCollaborationWorkspace options
        ]

        async.parallel filterQueue, workspaceQueueFin

    async.parallel workspaceQueue, callback


  isMachineOwner = (user, machine) ->

    for u in machine.users
      if u.owner and u.id.equals user.getId()
        return yes

    return no


  isMachineShared = (user, machine) ->

    for u in machine.users
      if (u.id.equals user.getId()) and u.permanent
        return yes

    return no


  filterCollaborationWorkspace = (options = {}) ->

    { client, user, workspace, successFn, failureFn } = options

    SocialChannel.byId client, { id: workspace.channelId }, (err, channel) ->

      if err

        switch err.error
          when 'koding.NotFoundError'
            return failureFn()

        data =
          channelId   : workspace.channelId
          workspaceId : workspace.getId()

        console.error 'error: fetch workspace channel'
        console.error JSON.stringify { data }
        console.error JSON.stringify { err }

        return failureFn()

      successFn()
