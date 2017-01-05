KodingFluxStore      = require 'app/flux/base/store'
toImmutable          = require 'app/util/toImmutable'
immutable            = require 'immutable'
actions              = require '../actiontypes'

module.exports = class TeamRoleFilterKeyStore extends KodingFluxStore

  @getterPath = 'TeamRoleFilterKeyStore'


  getInitialState: -> ''


  initialize: ->

    @on actions.SET_ROLE_FILTER_KEY, @setValue


  setValue: (value, { newValue }) -> newValue
