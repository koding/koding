hat       = require 'hat'
traverse  = require 'traverse'
jraphical = require 'jraphical'
KONFIG    = require 'koding-config-manager'


module.exports = class CredentialStore

  KodingError      = require '../../error'
  JCredentialData  = require './credentialdata'
  SocialCredential = require '../socialapi/credential'

  @SNEAKER_SUPPORTED = do ->

    return no  if process.env.CI

    for key, val of KONFIG.sneakerS3
      return no  if not val or val is ''

    return yes


  # STORE BEGINS --------------------------------------------------------------


  storeOnSneaker = (client, data, callback) ->

    { meta, identifier } = data

    meta.pathName = identifier
    meta.__allowEmpty = yes

    SocialCredential.store client, meta, (err) ->
      callback err, identifier


  storeOnMongo = (data, callback) ->

    credData = new JCredentialData data
    credData.save (err) ->
      callback err, data.identifier


  @create = (client, data, callback) ->

    { meta, originId, identifier } = data
    identifier ?= hat()
    data = { meta, originId, identifier }

    if @SNEAKER_SUPPORTED
      storeOnSneaker client, data, callback
    else
      storeOnMongo data, callback


  # STORE ENDS ----------------------------------------------------------------


  # FETCH BEGINS --------------------------------------------------------------

  fetchFromSneaker = (client, pathName, callback) ->

    SocialCredential.get client, { pathName }, (err, data) ->
      return callback err  if err
      callback null, { meta: data, identifier: pathName }


  fetchFromMongo = (identifier, callback) ->

    JCredentialData.one { identifier }, (err, data) ->
      return callback err  if err
      return callback new KodingError 'No data found'  unless data

      # Kloud keeps $binary data on Mongo while bootstrapping
      # and it's failing to parse on Bongo side if it's requested
      # over express. This needs to be converted to string at some
      # point since Bongo is not affiliated with binary data yet. ~ GG
      #
      # TODO: apply a similar solution on Bongo
      traverse(data).forEach (node) ->
        @update node.toString()  if node._bsontype is 'Binary'

      callback null, data


  @fetch = (client, identifier, callback) ->

    if @SNEAKER_SUPPORTED

      fetchFromSneaker client, identifier, (err, data) ->

        if err
          failedToFetchFromSneaker = yes

        if data
          return callback null, data

        fetchFromMongo identifier, (err, data) ->
          return callback err  if err

          if failedToFetchFromSneaker

            console.log "Data couldn't found on sneaker, uploading..."
            storeOnSneaker client, data, (err) ->
              console.log 'Data sync with sneaker:', if err
              then err else 'success'

          callback null, data

    else

      fetchFromMongo identifier, callback

  # FETCH ENDS ----------------------------------------------------------------


  # UPDATE BEGINS -------------------------------------------------------------

  updateOnMongo = (identifier, meta, callback) ->

    JCredentialData.one { identifier }, (err, data) ->
      return callback err  if err
      return callback new KodingError 'No data found'  unless data

      data.update { $set : { meta } }, callback


  @update = (client, data, callback) ->

    { identifier, meta } = data

    if @SNEAKER_SUPPORTED
      storeOnSneaker client, data, callback
    else
      updateOnMongo identifier, meta, callback

  # UPDATE ENDS ---------------------------------------------------------------


  # REMOVE BEGINS -------------------------------------------------------------

  removeFromSneaker = (client, pathName, callback) ->

    SocialCredential.delete client, { pathName }, callback


  removeFromMongo = (identifier, callback) ->

    JCredentialData.remove { identifier }, callback


  @remove = (client, identifier, callback) ->

    if @SNEAKER_SUPPORTED

      removeFromSneaker client, identifier, (err) ->
        removeFromMongo identifier, callback

    else

      removeFromMongo identifier, callback

  # REMOVE ENDS ---------------------------------------------------------------
