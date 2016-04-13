KodingFluxStore      = require 'app/flux/base/store'
toImmutable          = require 'app/util/toImmutable'
immutable            = require 'immutable'
actions              = require '../actiontypes'

module.exports = class TeamMembersIdStore extends KodingFluxStore

  @getterPath = 'TeamMembersIdStore'


  getInitialState: -> immutable.Map()


  initialize: ->

    @on actions.FETCH_TEAM_MEMBERS_SUCCESS, @load


  load: (memberIds, {users} ) ->

    return memberIds.withMutations (memberIds) ->
      users.forEach ( user ) ->
        memberIds.set user._id, user._id
