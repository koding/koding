hat       = require 'hat'
jraphical = require 'jraphical'

{ argv }  = require 'optimist'
KONFIG    = require('koding-config-manager').load("main.#{argv.c}")


module.exports = class CredentialStore

  KodingError      = require '../../error'
  JCredentialData  = require './credentialdata'
  SocialCredential = require '../socialapi/credential'

  @SNEAKER_SUPPORTED = do ->

    for key, val of KONFIG.sneakerS3
      return no  if not val or val is ''

    return yes


  # STORE BEGINS --------------------------------------------------------------


  storeOnSneaker = (client, data, callback) ->

    { meta, identifier } = data

    meta.pathName = identifier

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
      storeOnSneaker client, data, (err) ->
        # This part can be removed once kloud is ready
        # to use sneaker by default ~ GG cc/ RJ
        return callback err  if err
        storeOnMongo data, callback
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
      callback null, data


  @fetch = (client, identifier, callback) ->

    if @SNEAKER_SUPPORTED

      fetchFromSneaker client, identifier, (err, data) ->

        if err
          failedToFetchFromSneaker = yes
          return callback err  unless /^NoSuchKey/.test err.description

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

      storeOnSneaker client, data, (err) ->
        return callback err  if err

        updateOnMongo identifier, meta, callback

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
