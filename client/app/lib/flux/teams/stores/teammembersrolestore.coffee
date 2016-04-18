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
    @on actions.DELETE_TEAM_MEMBER, @deleteTeamMember


  load: (memberRoles, roles) ->

    return memberRoles.withMutations (memberRoles) ->
      # FIXME: hold for future use @hakan
      userRoles = {}
      for role in roles
        list = userRoles[role.targetId] or= []
        list.push role.as
      roles.forEach ( role ) ->
        memberRoles.set role.targetId, role.as #userRoles[role.targetId]


  updateTeamMember: (memberRoles, { account }) ->
    id = account.get '_id'
    roles = account.get 'role'
    hasOwner = 'owner' in roles
    hasAdmin = 'admin' in roles

    roles = if hasOwner then 'owner' else if hasAdmin then 'admin' else 'member'
    memberRoles.set id, roles


  deleteTeamMember: (memberRoles, memberId) ->
    memberRoles.delete memberId
