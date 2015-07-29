actions         = require '../actions/actiontypes'
immutable       = require 'immutable'
toImmutable     = require 'app/util/toImmutable'
KodingFluxStore = require 'app/flux/store'

module.exports = class UsersStore extends KodingFluxStore

  @getterPath = 'UsersStore'

  getInitialState: -> immutable.Map()

  initialize: ->

    @on actions.LOAD_USER_SUCCESS, @handleLoadSuccess


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


