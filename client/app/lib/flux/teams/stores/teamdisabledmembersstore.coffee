KodingFluxStore      = require 'app/flux/base/store'
toImmutable          = require 'app/util/toImmutable'
immutable            = require 'immutable'
actions              = require '../actiontypes'

module.exports = class TeamDisabledMembersStore extends KodingFluxStore

  @getterPath = 'TeamDisabledMembersStore'

  initialize: ->
    @on actions.LOAD_DISABLED_MEMBERS, @load
    @on actions.REMOVE_ENABLED_MEMBER, @remove
    @on actions.SAVE_DISABLED_TEAM_MEMBER, @handleChange


  getInitialState: -> immutable.Map()


  remove: (members, { memberId }) ->

    members.delete memberId

  load: (disabledMembersIds, { members } ) ->

    disabledMembersIds.withMutations (disabledMembersIds) ->
      members.forEach ( member ) ->

        member.status = 'disabled'
        member.role = 'disabled'
        disabledMembersIds.set member._id, toImmutable member


  handleChange: (members, { member }) ->

    member = member.set 'status', 'disabled'
    member = member.set 'role', 'disabled'

    members.set member.get('_id'), member
