actions         = require '../actions/actiontypes'
immutable       = require 'immutable'
toImmutable     = require 'app/util/toImmutable'
KodingFluxStore = require 'app/flux/store'

module.exports = class UsersStore extends KodingFluxStore

  @getterPath = 'UsersStore'

  getInitialState: -> immutable.Map()

  initialize: ->

    @on actions.LOAD_USER_SUCCESS, @handleLoadSuccess
    @on actions.SEARCH_USERS_SUCCESS, @handleLoadListSuccess

    @on actions.MARK_USER_AS_TROLL_BEGIN, @handleMarkUserAsTrollBegin
    @on actions.MARK_USER_AS_TROLL_SUCCESS, @handleMarkUserAsTrollSuccess
    @on actions.MARK_USER_AS_TROLL_FAIL, @handleMarkUserAsTrollFail

    @on actions.UNMARK_USER_AS_TROLL_BEGIN, @handleUnmarkUserAsTrollBegin
    @on actions.UNMARK_USER_AS_TROLL_SUCCESS, @handleUnmarkUserAsTrollSuccess
    @on actions.UNMARK_USER_AS_TROLL_FAIL, @handleUnmarkUserAsTrollFail

    @on actions.BLOCK_USER_BEGIN, @handleBlockUserBegin
    @on actions.BLOCK_USER_SUCCESS, @handleBlockUserSuccess
    @on actions.BLOCK_USER_FAIL, @handleBlockUserFail


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


  ###*
   * Load account list.
   *
   * @param {Immutable.Map} currentUsers
   * @param {object} payload
   * @param {array} payload.users
  ###
  handleLoadListSuccess: (currentUsers, { users }) ->

    return currentUsers.withMutations (map) ->
      map.set user._id, toImmutable user for user in users
      return map


