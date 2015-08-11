actions         = require '../actions/actiontypes'
immutable       = require 'immutable'
toImmutable     = require 'app/util/toImmutable'
KodingFluxStore = require 'app/flux/store'

module.exports = class UsersStore extends KodingFluxStore

  @getterPath = 'UsersStore'

  getInitialState: -> immutable.Map()

  initialize: ->

    @on actions.LOAD_USER_SUCCESS, @handleLoadSuccess
    @on actions.LOAD_USERS_SUCCESS, @handleLoadListSuccess


  ###*
   * Load account.
   *
   * @param {Immutable.Map} users
   * @param {object} payload
   * @param {string} payload.id
   * @param {JAccount} payload.account
  ###
  handleLoadSuccess: (users, { id, account }) ->

    return users.set id, toImmutable account


  handleLoadListSuccess: (currentUsers, { users }) ->

    return currentUsers.withMutations (map) ->
      map.set user._id, toImmutable user for user in users
      return map


