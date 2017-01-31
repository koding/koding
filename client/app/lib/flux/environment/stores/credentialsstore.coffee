actions = require '../actiontypes'
immutable = require 'immutable'
toImmutable = require 'app/util/toImmutable'
KodingFluxStore = require 'app/flux/base/store'



###

#
#
Example Here

###



module.exports = class CredentialsStore extends KodingFluxStore

  @getterPath = 'CredentialsStore'

  getInitialState: -> immutable.Map()

  initialize: ->

    @on actions.LOAD_CREDENTIALS_SUCCESS, @load
    @on actions.UPDATE_CREDENTIAL_SUCCESS, @updateCredential
    @on actions.REMOVE_CREDENTIAL_SUCCESS, @removeCredential


  load: (credentials, jCredentials) ->

    credentials.withMutations (credentials) ->
      jCredentials.forEach (jCredential) ->
        credentials.set jCredential._id, toImmutable jCredential


  updateCredential: (credentials, credential) ->

    credentials.withMutations (credentials) ->
      credentials.set credential._id, toImmutable credential


  removeCredential: (credentials, id) ->

    credentials.withMutations (credentials) ->
      credentials.remove id
