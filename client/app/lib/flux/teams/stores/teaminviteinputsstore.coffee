KodingFluxStore      = require 'app/flux/base/store'
toImmutable          = require 'app/util/toImmutable'
immutable            = require 'immutable'
actions              = require '../actiontypes'

module.exports = class TeamInviteInputsStore extends KodingFluxStore

  @getterPath = 'TeamInviteInputsStore'

  initialize: ->
    @on actions.SET_TEAM_INVITE_INPUT_VALUE, @handleChange
    @on actions.RESET_TEAM_INVITES, @handleReset # handleReset comes from base class


  createRecord = (role) ->
    immutable.Map
      email: ''
      firstname: ''
      lastname: ''
      role: role


  getInitialState: ->

    ['admin', 'member', 'member'].reduce (state, role, index) ->
      state.set index, createRecord role
    , immutable.Map()


  handleChange: (state, {index, inputType, value}) ->

    state = state.setIn [index, inputType], value

    empties = state.filter (val) -> val.get('email') is ''

    return state  if empties.size

    return state.set(state.size, createRecord 'member')

