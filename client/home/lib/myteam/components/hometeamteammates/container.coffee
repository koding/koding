kd              = require 'kd'
React           = require 'kd-react'
TeamFlux        = require 'app/flux/teams'
KDReactorMixin  = require 'app/flux/base/reactormixin'
View            = require './view'


module.exports = class HomeTeamTeamMatesContainer extends React.Component

  getDataBindings: ->
    return {
      members: TeamFlux.getters.filteredMembersWithRoleAndDisabledUsers
      disables: TeamFlux.getters.disabledUsers
      seachInput: TeamFlux.getters.searchInputValue
    }


  componentWillMount: ->

    options =
      limit : 10
      sort  : { timestamp: -1 } # timestamp is at relationship collection
      skip  : 0

    TeamFlux.actions.fetchMembers(options).then ->
      TeamFlux.actions.fetchMembersRole()


  onSearchInputChange: (event) ->

    value = event.target.value
    TeamFlux.actions.setSearchInputValue value


  handleRoleChange: (member, role, event) ->

    if role is 'kick'
      TeamFlux.actions.handleKickMember member
    else
      TeamFlux.actions.handleRoleChange member, role


  handleDisabledUser: (member, action, event) ->
    if action is 'enable'
    then TeamFlux.actions.handleDisabledUser member
    else TeamFlux.actions.handlePermanentlyDeleteMember member


  handleInvitation: (member, action, event) ->

    TeamFlux.actions.handlePendingInvitationUpdate member, action


  render: ->

    <View
      role={@props.role}
      members={@state.members}
      searchInputValue={@state.searchInputValue}
      handleInvitation={@bound 'handleInvitation'}
      handleRoleChange={@bound 'handleRoleChange'}
      handleDisabledUser={@bound 'handleDisabledUser'}
      onSearchInputChange={@bound 'onSearchInputChange'} />


HomeTeamTeamMatesContainer.include [KDReactorMixin]
