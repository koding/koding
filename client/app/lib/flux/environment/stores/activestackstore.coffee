KodingFluxStore  = require 'app/flux/base/store'
actions          = require '../actiontypes'


module.exports = class ActiveStackStore extends KodingFluxStore

  @getterPath = 'ActiveStackStore'

  getInitialState: -> null


  initialize: ->

    @on actions.STACK_IS_ACTIVE, @setStackId

  setStackId: (activeStackId, id) -> id
