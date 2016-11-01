_               = require 'lodash'
kd              = require 'kd'
React           = require 'app/react'
View            = require './view'
TeamFlux        = require 'app/flux/teams'
KDReactorMixin  = require 'app/flux/base/reactormixin'


notify = ({title}, duration = 5000) -> new kd.NotificationView { title, duration }

module.exports = class CustomerFeedBackContainer extends React.Component

  getDataBindings: ->
    return {
      team: TeamFlux.getters.team
    }


  componentDidMount: ->

    defaultValue = @state.team?.getIn (['customize', 'chatlioId'])
    defaultValue = ''  unless defaultValue

    @setState { defaultValue }


  handleSaveButton: ->

    value = @state.defaultValue
    dataToUpdate = {}
    dataToUpdate.customize = {}
    dataToUpdate.customize.chatlioId = value

    TeamFlux.actions.updateTeam(dataToUpdate).then ({ message }) ->

      if value
      then notify { title: 'Chatlio id successfully saved!' }
      else notify { title: 'Chatlio integration successfully turned off!' }

    .catch ({ message }) ->
      notify { title: 'There was an error, please try again!' }


  onInputAreaChange: (event) ->

    @setState
      defaultValue : event.target.value


  render: ->

    <View
      defaultValue={@state.defaultValue}
      onInputAreaChange={@bound 'onInputAreaChange'}
      handleSaveButton={@bound 'handleSaveButton'}
      />


CustomerFeedBackContainer.include [KDReactorMixin]
