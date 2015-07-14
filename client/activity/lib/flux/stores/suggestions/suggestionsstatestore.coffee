actions         = require 'activity/flux/actions/actiontypes'
KodingFluxStore = require 'app/flux/store'
toImmutable     = require 'app/util/toImmutable'

###*
 * Store to contain current state of suggestion list,
 * namely: accessible and visible flags.
 * It listens for SET_SUGGESTIONS_VISIBILITY and
 * SET_SUGGESTIONS_ACCESS actions to update those flags
###
module.exports = class SuggestionsStateStore extends KodingFluxStore

  @getterPath = 'SuggestionsStateStore'

  getInitialState: -> toImmutable { accessible: yes, visible: yes }

  initialize: ->

    @on actions.SET_SUGGESTIONS_VISIBILITY, @setVisibility
    @on actions.SET_SUGGESTIONS_ACCESS, @setAccess


  ###*
   * Handler for SET_SUGGESTIONS_VISIBILITY action
   * It sets current state to a state with updated
   * visible flag
   *
   * @param {Immutable} currentState
   * @param {object} payload
   * @param {bool} payload.visible
   * @return {Immutable} nextState
  ###
  setVisibility: (currentState, { visible }) ->

    currentState.set 'visible', visible


  ###*
   * Handler for SET_SUGGESTIONS_ACCESS action
   * It sets current state to a state with updated
   * accessible flag
   *
   * @param {Immutable} currentState
   * @param {object} payload
   * @param {bool} payload.accessible
   * @return {Immutable} nextState
  ###
  setAccess: (currentState, { accessible }) ->

    currentState.set 'accessible', accessible