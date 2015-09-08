KodingFluxStore = require 'app/flux/store'
actions         = require '../actions/actiontypes'
toImmutable     = require 'app/util/toImmutable'
immutable       = require 'immutable'

module.exports = class EmbedlyStore extends KodingFluxStore

  @getterPath = 'EmbedlyStore'


  getInitialState: -> immutable.Map()


  initialize: ->

    @on actions.LOAD_EMBEDLY_URL_SUCCESS, @handleLoadSuccess


  handleLoadSuccess: (currentState, { data }) ->

    data = data[0]
    currentState.set data.url, data

