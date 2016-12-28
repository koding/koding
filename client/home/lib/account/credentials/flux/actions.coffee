kd = require 'kd'
whoami = require 'app/util/whoami'
remote = require 'app/remote'
getters = require './getters'
actions = require './actiontypes'
getGroup = require 'app/util/getGroup'

_bindCredentialEvents = (credential) ->

  { reactor } = kd.singletons

  { _id: id } = credential

  loadCredentialUsers credential

  credential.on 'update', ->
    reactor.dispatch actions.UPDATE_CREDENTIAL_SUCCESS, credential
  credential.on 'deleteInstance', ->
    reactor.dispatch actions.REMOVE_CREDENTIAL_SUCCESS, id


loadCredentials = ->

  { reactor } = kd.singletons

  query = { group: getGroup().slug, originId: whoami()._id }

  reactor.dispatch actions.LOAD_CREDENTIALS_BEGIN, { query }

  remote.api.JCredential.some {}, { limit: 15 }, (err, credentials) ->
    if err
      reactor.dispatch actions.LOAD_CREDENTIALS_FAIL

    reactor.dispatch actions.LOAD_CREDENTIALS_SUCCESS, credentials

    credentials.forEach (credential) -> _bindCredentialEvents credential


loadCredentialUsers = (credential) ->

  { reactor } = kd.singletons

  credential.fetchUsers()
  .then (users) ->
    reactor.dispatch actions.LOAD_CREDENTIAL_USERS, { id: credential._id, users }
    users.forEach (u) ->
      { constructorName, _id } = u
      remote.api["#{constructorName}"].one({ _id }).then (instance) ->
        reactor.dispatch actions.UPDATE_CREDENTIAL_USERS, { id: credential._id, _id, instance }


onClickCredentialShare = ->
  # not implemented

onClickCredentialEdit = ->
  # not implemented

onClickCredentialRemove = ->
  # not implemented

onClickCredentialUnshare = ->
  # not implemented

onClickCredentialPreview =  (id) ->
  # not implemented

module.exports = {
  loadCredentials
  loadCredentialUsers
  onClickCredentialShare
  onClickCredentialEdit
  onClickCredentialRemove
  onClickCredentialUnshare
  onClickCredentialPreview
}