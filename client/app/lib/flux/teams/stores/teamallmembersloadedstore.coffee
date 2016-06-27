KodingFluxStore      = require 'app/flux/base/store'
actions              = require '../actiontypes'

module.exports = class TeamAllUsersLoaded extends KodingFluxStore

  @getterPath = 'TeamAllUsersLoadedStore'


  getInitialState: -> no


  initialize: ->

    @on actions.ALL_USERS_LOADED, -> yes
