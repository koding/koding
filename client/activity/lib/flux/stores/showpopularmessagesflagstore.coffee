actions         = require '../actions/actiontypes'
immutable       = require 'immutable'
toImmutable     = require 'app/util/toImmutable'
KodingFluxStore = require 'app/flux/base/store'


module.exports = class ShowPopularMessagesFlagStore extends KodingFluxStore

  @getterPath = 'ShowPopularMessagesFlagStore'

  getInitialState: -> null

  initialize: ->

    @on actions.SET_SHOW_POPULAR_MESSAGES_FLAG, @setFlag


  setFlag: (currentFlag, { showPopularMessagesFlag }) -> showPopularMessagesFlag

