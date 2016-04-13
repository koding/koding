KodingFluxStore      = require 'app/flux/base/store'
toImmutable          = require 'app/util/toImmutable'
immutable            = require 'immutable'
actions              = require '../actiontypes'

module.exports = class TeamMembersRoleStore extends KodingFluxStore

  @getterPath = 'TeamMembersRoleStore'


  getInitialState: -> immutable.Map()


  initialize: ->

    @on actions.FETCH_TEAM_MEMBERS_ROLES_SUCCESS, @load
    @on actions.UPDATE_TEAM_MEMBER, @updateTeamMember

  load: (memberRoles, roles ) ->

    return memberRoles.withMutations (memberRoles) ->
      # hold for future use fix @hakan
      userRoles = {}
      for role in roles
        list = userRoles[role.targetId] or= []
        list.push role.as
      roles.forEach ( role ) ->
        memberRoles.set role.targetId, role.as #userRoles[role.targetId]


  updateTeamMember: (memberRoles, roles ) ->
    id = roles.get '_id'
    value = roles.get 'role'
    hasOwner = 'owner' in value
    hasAdmin = 'admin' in value

    value = if hasOwner then 'owner' else if hasAdmin then 'admin' else 'member'
    debugger
    memberRoles.set id, value
