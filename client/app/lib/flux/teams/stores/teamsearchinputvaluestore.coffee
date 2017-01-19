KodingFluxStore      = require 'app/flux/base/store'
toImmutable          = require 'app/util/toImmutable'
immutable            = require 'immutable'
actions              = require '../actiontypes'

module.exports = class TeamSearchInputValueStore extends KodingFluxStore

  @getterPath = 'TeamSearchInputValueStore'


  getInitialState: -> ''


  initialize: ->

    @on actions.SET_SEARCH_INPUT_VALUE, @setValue


  setValue: (value, { newValue }) ->

    return newValue
