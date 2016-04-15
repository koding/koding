KodingFluxStore      = require 'app/flux/base/store'
toImmutable          = require 'app/util/toImmutable'
immutable            = require 'immutable'
actions              = require '../actiontypes'

module.exports = class TeamStore extends KodingFluxStore

  @getterPath = 'TeamStore'


  getInitialState: -> immutable.Map()


  initialize: ->

    @on actions.LOAD_TEAM_SUCCESS, @load


  load: (oldTeam, team) -> toImmutable team
