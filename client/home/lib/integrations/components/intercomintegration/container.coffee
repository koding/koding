_              = require 'lodash'
kd             = require 'kd'
React          = require 'app/react'
View           = require './view'
TeamFlux       = require 'app/flux/teams'
KDReactorMixin = require 'app/flux/base/reactormixin'


notify = ({title}, duration = 5000) -> new kd.NotificationView { title, duration }

module.exports = class IntercomIntegrationContainer extends React.Component

  getDataBindings: ->
    return {
      team: TeamFlux.getters.team
    }


  componentDidMount: ->

    defaultValue = @state.team?.getIn (['customize', 'intercomAppId'])
    defaultValue = ''  unless defaultValue

    @setState { defaultValue }


  handleSaveButton: ->

    value = @state.defaultValue

    dataToUpdate = if @state.team.get('customize')
    then { 'customize.intercomAppId' : value }
    else { customize : { intercomAppId : value } }

    TeamFlux.actions.updateTeam(dataToUpdate).then ({ message }) ->

      if value
      then notify { title: 'Intercom id successfully saved!' }
      else notify { title: 'Intercom integration successfully turned off!' }

    .catch ({ message }) ->
      notify { title: 'There was an error, please try again!' }


  onValueChange: (event) ->

    @setState
      defaultValue : event.target.value


  render: ->

    <View
      defaultValue={@state.defaultValue}
      onValueChange={@bound 'onValueChange'}
      onSave={@bound 'handleSaveButton'}
      />


IntercomIntegrationContainer.include [KDReactorMixin]
