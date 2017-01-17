actions = require '../actions/actiontypes'
toImmutable = require 'app/util/toImmutable'
KodingFluxStore = require 'app/flux/base/store'

module.exports = class LoggedInUserEmailStore extends KodingFluxStore

  @getterPath = 'LoggedInUserEmailStore'

  getInitialState: -> null


  initialize: ->
    @on actions.LOAD_LOGGED_IN_USER_EMAIL_SUCCESS, @load


  load: (oldEmail, { email }) ->
    toImmutable email
