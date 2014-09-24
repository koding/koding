{Inflector}  = require 'bongo'
{Module}     = require 'jraphical'

module.exports = class JWorkspace extends Module

  KodingError  = require '../error'
  {signature, secure, ObjectId} = require 'bongo'

  @share()

  @set
    schema         :
      name         : String
      slug         : String
      machineUId   : String
      machineLabel : String
      rootPath     : String
      owner        : String
      layout       : Object

    sharedMethods  :
      static       :
        create     : signature Object, Function
        deleteById : signature String, Function
      instance     :
        delete     : signature Function
    sharedEvents   :
      static       : []
      instance     : []

  @create = secure (client, data, callback) ->
    data.owner = client.connection.delegate._id
    data.slug  = Inflector.slugify data.name?.toLowerCase()

    {name, slug, machineUId, rootPath, owner, layout, machineLabel} = data

    JWorkspace.one { slug }, (err, workspace) ->
      return callback err, null  if err

      if workspace or name is 'My Workspace'
        query   =
          owner : client.connection.delegate._id
          slug  : new RegExp slug

        options =
          sort  : slug: -1
          limit : 1

        JWorkspace.some query, options, (err, workspaces) ->
          return callback err, null  if err

          if name is 'My Workspace' and workspaces?.length is 0
            workspaces = [ { name: 'My Workspace', slug: 'my-workspace' } ]

          workspace = workspaces[0]

          return callback null, null  unless workspace

          parts = workspace.slug.split '-'
          last  = parts[parts.length - 1]
          seed  = if isNaN last then 1 else ++last
          name  = "#{name} #{seed}"
          slug  = "#{slug}-#{seed}"

          create_ { name, slug, machineUId, machineLabel, rootPath, owner, layout }, callback
      else
        create_ { name, slug, machineUId, machineLabel, rootPath, owner, layout }, callback

  create_ = (data, callback) ->
    workspace  = new JWorkspace data

    workspace.save (err) ->
      return callback err  if err
      return callback null, workspace

  @fetch = secure (client, query = {}, callback) ->
    query.owner = client.connection.delegate._id
    JWorkspace.some query, {}, callback


  @deleteById = secure (client, id, callback)->

    selector =
      owner  : client.connection.delegate._id
      _id    : ObjectId id

    JWorkspace.one selector, (err, ws)->
      return callback err  if err?
      unless ws?
        callback new KodingError "Workspace not found."
      else
        ws.remove (err)-> callback err


  delete: secure (client, callback)->

    { delegate } = client.connection

    unless delegate.getId().equals this.owner
      return callback new KodingError 'Access denied'

    @remove callback
