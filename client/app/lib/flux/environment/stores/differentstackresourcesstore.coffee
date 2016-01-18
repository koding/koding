KodingFluxStore      = require 'app/flux/base/store'
toImmutable          = require 'app/util/toImmutable'
immutable            = require 'immutable'
actions              = require '../actiontypes'


module.exports = class DifferentStackResourcesStore extends KodingFluxStore

  @getterPath = 'DifferentStackResourcesStore'

  getInitialState: -> null


  initialize: ->

    @on actions.GROUP_STACKS_INCONSISTENT, @show
    @on actions.GROUP_STACKS_CONSISTENT, @hide


  show: -> yes


  hide: -> null
