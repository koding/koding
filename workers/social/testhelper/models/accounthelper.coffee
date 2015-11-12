JAppStorage              = require '../../lib/social/models/appstorage'
{ Relationship }         = require 'jraphical'
{ generateRandomString } = require '../index'

createOldAppStorageDocument = (data, callback) ->
  { account, appId, version } = data

  bucket =
    someString  : generateRandomString()
    someData    :
      moreData  : { data : {} }
    anotherData :
      someArray : [1,2,3]

  storage = new JAppStorage { appId, version, bucket }
  storage._shouldPrune = no
  storage.save (err) ->
    return callback err  if err

    relationshipOptions =
      targetId    : storage.getId()
      targetName  : 'JAppStorage'
      sourceId    : account.getId()
      sourceName  : 'JAccount'
      as          : 'appStorage'
      data        : { appId, version }

    rel = new Relationship relationshipOptions
    rel.save (err) ->
      callback err, { storage, relationshipOptions, bucket }


module.exports = {
  createOldAppStorageDocument
}
