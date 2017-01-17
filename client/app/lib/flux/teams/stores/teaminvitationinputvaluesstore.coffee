KodingFluxStore      = require 'app/flux/base/store'
toImmutable          = require 'app/util/toImmutable'
immutable            = require 'immutable'
actions              = require '../actiontypes'

module.exports = class TeamInvitationInputValuesStore extends KodingFluxStore

  @getterPath = 'TeamInvitationInputValuesStore'

  initialize: ->
    @on actions.SET_TEAM_INVITE_INPUT_VALUE, @handleChange
    @on actions.RESET_TEAM_INVITES, @handleReset # handleReset comes from base class


  createRecord = (canEdit, role) ->
    immutable.Map
      email: ''
      firstName: ''
      lastName: ''
      canEdit: canEdit
      role: role


  getInitialState: ->

    [no, no, no].reduce (state, canEdit, index) ->
      role = if canEdit then 'admin' else 'member'
      state.set index, createRecord canEdit, role
    , immutable.Map()


  ###
  * When you start to add a new value with only one empty input, it will
  * add one more empty input so there is always an empty input for users.
  * Initial State:
  *   value
  *   value
  *   ----
  *
  * User typed `v` to the empty input area
  *   value
  *   value
  *   v
  *   ----
  *
  * User typed `a` to the new input area
  *   value
  *   value
  *   va
  *   ----
  ###
  handleChange: (state, { index, inputType, value }) ->

    state = state.setIn [index, inputType], value
    role = if state.getIn([index, 'canEdit']) then 'admin' else 'member'
    state = state.setIn [index, 'role'], role

    empties = state.filter (val) -> val.get('email') is ''

    return state  if empties.size

    return state.set(state.size, createRecord no, 'member')
