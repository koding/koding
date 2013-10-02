{Model, secure} = require 'bongo'

module.exports = class JLocation extends Model

  @share()

  @set
    sharedMethods:
      static  : [ 'importAll', 'byZip', 'one' ]
    schema    :
      zip     : String
      city    : String
      state   : String
      country : String

  @importAll = secure (client, callback) ->

    {delegate} = client.connection

    return callback { message: 'Access denied!' }  unless delegate.can 'flag'

    importer = (require 'koding-zips-importer')
      collectionName  : @getCollectionName()
      mongo           : @getClient()

    importer
      .on 'error', (err)  -> callback err
      .on 'end',          -> callback null

  @byZip = (zip, callback) -> @one { zip }, callback