actions         = require '../actions/actiontypes'
KodingFluxStore = require 'app/flux/store'
toImmutable     = require 'app/util/toImmutable'

module.exports = class SuggestionStateStore extends KodingFluxStore

  getInitialState: -> toImmutable { isAccessible: yes, isHidden: yes }

  initialize: ->

    @on actions.CHANGE_SUGGESTION_VISIBILITY, @changeVisibility
    @on actions.CHANGE_SUGGESTION_ACCESS, @changeAccess


  changeVisibility: (currentState, { isHidden }) ->

    currentState.set 'isHidden', isHidden


  changeAccess: (currentState, { isAccessible }) ->

    currentState.set 'isAccessible', isAccessible