_               = require 'lodash'
kd              = require 'kd'
React           = require 'app/react'
View            = require './view'
TeamFlux        = require 'app/flux/teams'
showError       = require 'app/util/showError'
KDReactorMixin  = require 'app/flux/base/reactormixin'
copyToClipboard = require 'app/util/copyToClipboard'


module.exports = class TryOnKodingContainer extends React.Component

  getDataBindings: ->
    return {
      team: TeamFlux.getters.team
    }

  constructor: (props) ->

    super props

    canEdit = kd.singletons.groupsController.canEditGroup()
    @state = {canEdit : canEdit}


  componentDidMount: ->

    team = @state.team
    value = ''
    checked = no

    if team
      value = """
          <a href="https://#{team.get('slug')}.koding.com/Team/Join">
            <img src="https://koding-cdn.s3.amazonaws.com/try_on_koding_1x.png" srcset="https://koding-cdn.s3.amazonaws.com/try_on_koding_1x.png 1x, https://koding-cdn.s3.amazonaws.com/try_on_koding_2x.png 2x" />
          </a>
          """

      allowedDomains = @state.team.get 'allowedDomains'

      unless '*' in allowedDomains.toJS()
        @setState
          primaryClassName : 'primary'
          secondaryClassName : 'secondary hidden'
          value : value
          checked: checked
      else
        @setState
          primaryClassName : 'primary hidden'
          secondaryClassName : 'secondary'
          value : value
          checked: not checked


  handleSwitch: (state) ->

    unless @state.canEdit
      return showError 'You are not allowed to toggle this button'

    allowedDomains = @state.team?.get 'allowedDomains'
    allowedDomains = allowedDomains?.toJS()
    allowedDomains = _.clone allowedDomains or []

    if state
      allowedDomains.push '*'
    else
      _.remove allowedDomains, (domain) -> domain is '*'

    dataToUpdate = {}
    dataToUpdate.allowedDomains = allowedDomains

    TeamFlux.actions.updateTeam(dataToUpdate).then ({ message }) =>
      if state
        @setState
          primaryClassName : 'primary hidden'
          secondaryClassName : 'secondary'
      else
        @setState
          primaryClassName : 'primary'
          secondaryClassName : 'secondary hidden'

      @setState { checked: state }
    .catch ({ message }) -> @setState { checked: not state }


  render: ->

    <View
      ref='view'
      value={@state.value}
      checked={@state.checked}
      canEdit={@state.canEdit}
      primaryClassName={@state.primaryClassName}
      secondaryClassName={@state.secondaryClassName}
      handleSwitch={@bound 'handleSwitch'}/>


TryOnKodingContainer.include [KDReactorMixin]
