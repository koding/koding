{ Model }   = require 'bongo'
KodingError = require '../error'

module.exports = class JUrlAlias extends Model

  { secure, signature } = require 'bongo'

  @share()

  @set
    permissions   :
      'administer url aliases'  : []
    sharedMethods :
      static      :
        create    :
          (signature String, String, Function)
        resolve   :
          (signature String, Function)
    schema        :
      alias       : String
      target      : String

  @create = secure (client, alias, target, callback) ->
    { delegate } = client.connection
    unless delegate.can 'administer url aliases'
      return callback new KodingError 'Access denied'
    aliasModel = new this { alias, target }
    aliasModel.save (err, docs) ->
      if err then callback err
      else callback err, unless err then aliasModel

  # createRe =(alias) ->
  #   ///^#{alias.split('/').map((edge) -> "(?:#{edge}|(\w+)").join('/')}$///

  @resolve = (alias, callback) ->
    @someData { alias }, { target:1 }, (err, cursor) ->
      if err then callback err
      else cursor.nextObject (err, doc) ->
        if err then callback err
        else if doc?
          callback null, doc.target
        else
          callback new KodingError '404 - alias not found!'
