kd = require 'kd'
React = require 'app/react'
View = require './view'
TeamFlux = require 'app/flux/teams'
KDReactorMixin = require 'app/flux/base/reactormixin'


module.exports = class ApiAccessContainer extends React.Component

  getDataBindings: ->

    return {
      team: TeamFlux.getters.team
      apiTokens: TeamFlux.getters.apiTokens
      apiAccessState: TeamFlux.getters.apiAccessState
    }

  componentDidMount: ->

    TeamFlux.actions.fetchApiTokens()
    TeamFlux.actions.fetchCurrentStateOfApiAccess()


  constructor: (props) ->

    super props

  render: ->

    <View
      apiTokens={@state.apiTokens}
      apiAccessState={@state.apiAccessState}/>

ApiAccessContainer.include [KDReactorMixin]
