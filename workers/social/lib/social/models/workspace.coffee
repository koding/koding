{Inflector}  = require 'bongo'
{Module}     = require 'jraphical'

module.exports = class JWorkspace extends Module

  {signature, secure} = require 'bongo'
  @share()

  @set
    schema         :
      name         : String
      slug         : String
      machineUId   : String
      rootPath     : String
      owner        : String
      layout       : Object

    sharedMethods  :
      static       :
        create     : signature Object, Function
        some       : signature Object, Object, Function
      instance     : []
    sharedEvents   :
      static       : []
      instance     : []

  @create = secure (client, data, callback) ->
    data.owner = client.connection.delegate._id
    data.slug  = Inflector.slugify data.name.toLowerCase()

    {name, slug, machineUId, rootPath, owner, layout} = data

    JWorkspace.one { slug }, (err, workspace) ->
      return callback err, null  if err

      if workspace or name is 'My Workspace'
        query   =
          owner : client.connection.delegate._id
          slug  : new RegExp slug

        JWorkspace.some query, {}, (err, workspaces) ->
          return callback err, null  if err

          seed = 1

          for workspace in workspaces
            parts = workspace.slug.split '-'
            last  = parts[parts.length - 1]
            seed  = ++last  unless isNaN last

          name = "#{name} #{seed}"
          slug = "#{slug}-#{seed}"

          create_ { name, slug, machineUId, rootPath, owner, layout }, callback
      else
        create_ { name, slug, machineUId, rootPath, owner, layout }, callback

  create_ = (data, callback) ->
    workspace  = new JWorkspace data

    workspace.save (err) ->
      return callback err  if err
      return callback null, workspace

  some$: secure (client, query = {}, callback) ->
    query.owner = client.connection.delegate._id
    JWorkspace.some query, callback
