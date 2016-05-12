KodingFluxStore      = require 'app/flux/base/store'
toImmutable          = require 'app/util/toImmutable'
immutable            = require 'immutable'
actions              = require '../actiontypes'

module.exports = class TeamDisabledMembersStore extends KodingFluxStore

  @getterPath = 'TeamDisabledMembersStore'

  initialize: ->
    @on actions.SAVE_DISABLED_TEAM_MEMBER, @handleChange


  getInitialState: -> immutable.Map()


  handleChange: (members, { member }) ->

    members.set member.get('id'), member
