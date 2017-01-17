KodingFluxStore = require 'app/flux/base/store'
actions = require '../actiontypes'
immutable = require 'immutable'
toImmutable = require 'app/util/toImmutable'


module.exports = class TeamOTATokenStore extends KodingFluxStore

  @getterPath = 'TeamOTATokenStore'


  getInitialState: -> null


  initialize: ->

    @on actions.LOAD_OTA_TOKEN_SUCCESS, @setValue


  setValue: (value, { cmd }) ->

    return cmd
