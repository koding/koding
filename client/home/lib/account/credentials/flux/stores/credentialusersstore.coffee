KodingFluxStore = require 'app/flux/base/store'
immutable       = require 'immutable'
toImmutable     = require 'app/util/toImmutable'
actions         = require '../actiontypes'
_ = require 'lodash'

###
#Exmple here
#
#
#
###


module.exports = class CredentialUsersStore extends KodingFluxStore

  @getterPath = 'CredentialUsersStore'

  getInitialState: -> immutable.Map()


  initialize: ->

    @on actions.LOAD_CREDENTIAL_USERS, @load
    @on actions.UPDATE_CREDENTIAL_USERS, @update


  load: (credentialUsers, { id, users }) ->

    credentialUsers.withMutations (credentialUsers) ->
      newUsers = immutable.Map()
      newUsers.withMutations (newUsers) ->
        users.map (user) ->
          { _id } = user
          newUsers.set _id, user

        credentialUsers.set id, newUsers

  update: (credentialUsers, { id, _id, instance } ) ->

    users = credentialUsers.get(id)
    users = users.set _id, users.get(_id)['instance'] = instance

    credentialUsers.set id, users
