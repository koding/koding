{Model} = require 'bongo'

module.exports = class JZipcode extends Model

  @share()

  @set
    sharedMethods:
      static: [ 'importAll', 'byCode', 'one' ]
    schema  :
      zip   : String
      city  : String
      state : String

  @importAll = secure (client, callback) ->

    {delegate} = client.connection

    return callback { message: 'Access denied!' }  unless delegate.can 'flag'

    importer = (require 'koding-zips-importer')
      collectionName  : @getCollectionName()
      mongo           : @getClient()

    importer
      .on 'error', (err)  -> callback err
      .on 'end',          -> callback null

  @byCode = (zip, callback) -> @one { zip }, callback