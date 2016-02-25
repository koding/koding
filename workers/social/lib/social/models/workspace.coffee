{ Module } = require 'jraphical'

JMachine = require './computeproviders/machine'

module.exports = class JWorkspace extends Module

  KodingError  = require '../error'
  { slugify }    = require '../traits/slugifiable'
  { signature, secure, ObjectId } = require 'bongo'

  @share()

  @set

    indexes             :
      originId          : 'sparse'
      slug              : 'sparse'

    schema              :
      name              : String
      slug              : String
      isDefault         :
        type            : Boolean
        default         : no
      channelId         : String
      machineUId        : String
      machineLabel      : String
      rootPath          : String
      originId          : ObjectId
      layout            : Object

    sharedMethods       :
      static            :
        create          : signature Object, Function
        deleteById      : signature String, Function
        deleteByUid     : signature String, Function
        update          : signature String, Object, Function
        fetchByMachines : signature Function
        createDefault   : signature String, Function
      instance          :
        delete          : signature Function
    sharedEvents        :
      instance          : ['updateInstance']


  @create$ = secure (client, data, callback) ->

    { delegate }    = client.connection
    data.originId = delegate._id

    @create client, data, callback


  @create = secure (client, data, callback) ->

    { delegate }     = client.connection
    data.originId ?= delegate._id

    nickname  = delegate.profile.nickname
    data.slug = slugify data.name?.toLowerCase()

    { name, slug, machineUId, rootPath, originId, machineLabel } = data

    # we don't support saving layout for now, i will set it to empty object
    # to prevent storing any kind of data in it. -- acetz!
    data.layout = {}

    kallback = (name, slug) ->

      data.name      = name
      data.slug      = slug
      data.rootPath  = "/home/#{nickname}/Workspaces/#{slug}"  unless data.rootPath
      workspace      = new JWorkspace data

      workspace.save (err) ->
        if err
          switch err.code
            when 11000 # duplicate key error
              callback()
            else
              callback err  if err
          return

        delegate.emit 'NewWorkspaceCreated', workspace
        message =
          accountId: delegate.socialApiId
          name: name
          groupName: slug

        require('./socialapi/requests').dispatchEvent 'social.workspace_created', message, (err) ->
          console.error '[dispatchEvent][workspace_created]', err if err

        uid       = machineUId
        eventName = 'NewWorkspaceCreated'
        options   = { nickname, workspace, uid, eventName }

        notifyUsers options, callback


    if data.isDefault
    then kallback data.name, data.slug
    else
      generateUniqueName { originId, name, machineUId }, (err, res) ->

        return callback err  if err?

        { name, slug } = res

        kallback name, slug


  notifyUsers = (options, callback) ->

    { nickname, workspace, uid, eventName } = options

    JMachine.one { uid }, (err, machine) ->

      return callback err  if err
      return callback new KodingError 'Machine not found.'  unless machine

      users = machine.users.filter (user) -> user.username isnt nickname
      users = users.map (user) -> user.username

      if users.length
        { notifyByUsernames } = require './notify'
        notifyByUsernames users, eventName, workspace

      return callback null, workspace


  generateUniqueName = ({ originId, machineUId, name, index }, callback) ->

    slug = if index? then "#{name}-#{index}" else name
    slug = slugify slug

    JWorkspace.count { originId, slug, machineUId }, (err, count) ->

      return callback err  if err?

      if count is 0

        name = "#{name} #{index}"  if index?
        callback null, { name, slug }

      else

        index ?= 0
        index += 1

        generateUniqueName { originId, machineUId, name, index }, callback


  @fetch = secure (client, query = {}, callback) ->

    query.originId = client.connection.delegate._id

    JWorkspace.some query, { limit: 30 }, callback


  @fetchByMachines$ = secure (client, callback) ->

    query = {}

    JMachine.some$ client, query, (err, machines) ->
      return callback err  if err

      machineUIds = machines.map (machine) -> machine.uid
      JWorkspace.some { machineUId: { $in: machineUIds } }, {}, callback


  @deleteById = secure (client, id, callback) ->

    delegate   = client.connection.delegate
    selector   =
      originId : delegate._id
      _id      : ObjectId id

    JWorkspace.one selector, (err, ws) ->
      return callback err  if err?
      unless ws
        callback new KodingError 'Workspace not found.'
      else
        ws.remove (err) ->
          return callback err  if err
          options =
            uid      : ws.machineUId
            nickname : delegate.profile.nickname
            workspace: ws
            eventName: 'WorkspaceRemoved'
            group    : client?.context?.group

          notifyUsers options, callback


  @deleteByUid = secure (client, uid, callback) ->

    selector     =
      originId   : client.connection.delegate._id
      machineUId : uid

    JWorkspace.remove selector, (err) ->
      callback err


  delete: secure (client, callback) ->

    { delegate } = client.connection

    unless delegate.getId().equals this.originId
      return callback new KodingError 'Access denied'

    @remove callback


  @update$ = secure (client, id, options, callback) ->

    selector   =
      originId : client.connection.delegate._id
      _id      : ObjectId id

    JWorkspace.one selector, (err, ws) ->
      return callback err  if err
      return callback new KodingError 'Workspace not found.'  unless ws

      ws.update options, callback


  @createDefault = secure (client, machineUId, callback) ->

    JMachine.one$ client, machineUId, (err, machine) =>

      return callback err  if err
      return callback 'Machine not found'  unless machine

      { nickname } = client.connection.delegate.profile
      rootPath   = '/'  if machine.provider is 'managed'
      selector   = { machineUId, slug: 'my-workspace' }

      @one selector, (err, workspace) =>

        return callback err  if err
        return callback null, workspace  if workspace

        machine.fetchOwner (err, account) =>

          return callback err  if err

          { nickname }     = account.profile

          data           =
            name         : 'My Workspace'
            isDefault    : yes
            machineLabel : machine.label
            machineUId   : machine.uid
            rootPath     : rootPath ? "/home/#{nickname}"
            originId     : account.getId()

          @create client, data, callback
