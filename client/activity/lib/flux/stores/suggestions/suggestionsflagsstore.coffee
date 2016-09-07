actions         = require 'activity/flux/actions/actiontypes'
KodingFluxStore = require 'app/flux/base/store'
toImmutable     = require 'app/util/toImmutable'

###*
 * Store to contain suggestions flags,
 * namely: accessible and visible flags.
 * It listens for SET_SUGGESTIONS_VISIBILITY and
 * SET_SUGGESTIONS_ACCESSIBILITY actions to update those flags
###
module.exports = class SuggestionsFlagsStore extends KodingFluxStore

  @getterPath = 'SuggestionsFlagsStore'

  getInitialState: -> toImmutable { accessible: yes, visible: yes }

  initialize: ->

    @on actions.SET_SUGGESTIONS_VISIBILITY, @setVisibility
    @on actions.SET_SUGGESTIONS_ACCESSIBILITY, @setAccessibility


  ###*
   * Handler for SET_SUGGESTIONS_VISIBILITY action
   * It sets current state to a state with updated
   * visible flag
   *
   * @param {Immutable.Map} currentState
   * @param {object} payload
   * @param {bool} payload.visible
   * @return {Immutable.Map} nextState
  ###
  setVisibility: (currentState, { visible }) ->

    currentState.set 'visible', visible


  ###*
   * Handler for SET_SUGGESTIONS_ACCESSIBILITY action
   * It sets current state to a state with updated
   * accessible flag
   *
   * @param {Immutable.Map} currentState
   * @param {object} payload
   * @param {bool} payload.accessible
   * @return {Immutable.Map} nextState
  ###
  setAccessibility: (currentState, { accessible }) ->

    currentState.set 'accessible', accessible
