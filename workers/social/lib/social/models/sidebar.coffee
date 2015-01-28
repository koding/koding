bongo = require 'bongo'
{dash, secure, signature} = bongo

JMachine   = require './computeproviders/machine'
JWorkspace = require './workspace'

SocialMessage = require './socialapi/message'

KodingError = require '../error'

module.exports = class Sidebar extends bongo.Base

  @share()

  @set
    sharedMethods:
      static:
        fetchEnvironment: (signature Function)


  @fetchEnvironment$ = secure (client, callback) ->

    data = own: []

    client.connection.delegate.fetchUser (err, user) ->

      return callback new KodingError err  if err

      query = 'users.id': user.getId()

      JMachine.some query, {}, (err, machines) ->
        return callback new KodingError err  if err

        machineUIds = machines.map (machine) -> machine.uid
        JWorkspace.some machineUId: $in: machineUIds, {}, (err, workspaces) ->

          return callback new KodingError err  if err

          options = {client, user, machines, workspaces, callback}
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

    return ({machine, workspace}) ->

      unless node = findNode machine
        node = {machine, workspaces: []}
        list.push node

      {workspaces} = node
      workspaces.push workspace  if workspace


  decorateEnvironmentData = (options) ->

    {client, user} = options
    {machines, workspaces} = options
    {addOwnFn, addSharedFn, addCollaborationFn} = options
    {callback} = options

    machineMap = {}

    machines.forEach (machine) ->
      machineMap[machine.uid] = machine

      addNodeFn = switch
        when isMachineOwner user, machine
          addOwnFn

      addNodeFn {machine}

    workspaceQueue = workspaces.map (workspace) ->

      machine = machineMap[workspace.machineUId]

      nodeValue = {machine, workspace}

      return ->

        failureFn = (err) ->

          filterQueue.fin()

          console.error \
            new KodingError "Sidebar decorate environment data: #{err}"

        makeSuccessFn = (fn) ->

          return ->

            fn.call null, nodeValue
            filterQueue.fin()

        filterQueue = [
          ->

            successFn = makeSuccessFn addOwnFn

            options = {user, machine, successFn, failureFn}
            filterOwnWorkspace options
        ]

        dash filterQueue, -> workspaceQueue.fin()

    dash workspaceQueue, callback


  filterOwnWorkspace = (options) ->

    {user, machine, successFn, failureFn} = options

    if isMachineOwner user, machine
    then successFn()
    else failureFn()


  isMachineOwner = (user, machine) ->

    for u in machine.users
      if u.owner and u.id.equals user.getId()
        return yes

    return no


  isMachineShared = (user, machine) ->

    for u in machine.users
      if u.id.equals user.getId() and u.permanent
        return yes

    return no
