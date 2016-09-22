kd              = require 'kd'
React           = require 'app/react'
TeamFlux        = require 'app/flux/teams'
KDReactorMixin  = require 'app/flux/base/reactormixin'
View            = require './view'
showError       = require 'app/util/showError'

notify = (title, duration = 5000) -> new kd.NotificationView { title, duration }

module.exports = class HomeTeamPermissionsContainer extends React.Component

  getDataBindings: ->
    return {
      team: TeamFlux.getters.team
    }

  componentDidMount: ->

  updateTeam: (permission, state) ->

    customize = @state.team.get 'customize'
    customize = if customize then customize.toJS() else {}

    if state
      customize[permission] = on
    else
      delete customize[permission]

    dataToUpdate = { customize }

    TeamFlux.actions.updateTeam(dataToUpdate).then ({ message }) =>
      @setState { permission: state }
    .catch ({ message }) -> @setState { permission: not state }


  render: ->

    <View
      team={@state.team}
      canCreateStacks={@state.team.getIn ['customize', 'membersCanCreateStacks']}
      seeTeamMembers={not @state.team.getIn ['customize', 'hideTeamMembers']}
      onToggle={@bound 'updateTeam'}/>


HomeTeamPermissionsContainer.include [KDReactorMixin]
