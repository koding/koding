jraphical = require 'jraphical'

module.exports = class JProxyFilter extends jraphical.Module

  {secure, ObjectId}  = require 'bongo'
  {Relationship} = jraphical
  {permit} = require '../group/permissionset'

  @trait __dirname, '../../traits/protected'

  @share()

  @set
    softDelete      : yes

    permissions     :
      'create filters'     : ['member']
      'edit filters'       : ['member']
      'edit own filters'   : ['member']
      'delete filters'     : ['member']
      'delete own filters' : ['member']
      'list filters'       : ['member']
      'list own filters'   : ['member']

    sharedMethods   :
      instance      : []
      static        : ['one', 'all', 'count', 'createFilter', 'fetchFiltersByContext']

    indexes         :
      name          : 'unique'

    schema          :
      name          :
        type        : String
        required    : yes
      match         :
        type        : String
        required    : yes
      type          :
        type        : String
        required    : yes
      owner         : ObjectId

      createdAt     :
        type        : Date
        default     : -> new Date
      modifiedAt    :
        type        : Date
        default     : -> new Date

  @createFilter : permit 'create filters',
    success : (client, params, callback)->
      {delegate}   = client.connection
      params.owner = delegate.getId()
      newFilter    = new JProxyFilter params
      newFilter.save (err)->
        return callback err if err

        delegate.addProxyFilter newFilter, (err)->
          return callback err if err
          callback null, newFilter

  @fetchFiltersByContext: permit 'list filters',
    success: (client, callback)->
      {delegate} = client.connection
      @some {owner:delegate.getId()}, {name:1, match:1},  (err, filters)->
        return callback err if err
        callback err, filters

  



