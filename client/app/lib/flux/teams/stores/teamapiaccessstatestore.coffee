KodingFluxStore = require 'app/flux/base/store'
actions = require '../actiontypes'

module.exports = class TeamAPIAccessStateStore extends KodingFluxStore

  @getterPath = 'TeamAPIAccessStateStore'


  getInitialState: -> no


  initialize: ->

    @on actions.SET_API_ACCESS_STATE, @set


  set: (oldState, { state }) ->

    return state
