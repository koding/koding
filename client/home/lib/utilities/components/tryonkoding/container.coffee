_               = require 'lodash'
kd              = require 'kd'
React           = require 'kd-react'
View            = require './view'
TeamFlux        = require 'app/flux/teams'
KDReactorMixin  = require 'app/flux/base/reactormixin'
copyToClipboard = require 'app/util/copyToClipboard'


module.exports = class TryOnKodingContainer extends React.Component

  getDataBindings: ->
    return {
      team: TeamFlux.getters.loadTeam
    }
  

  componentDidMount: ->

    team = @state.team
    value = ''
    checked = no
    
    if team
      value = """
          <a href="https://#{team.get('slug')}.koding.com/Join">
            <img src="https://koding.com/a/img/try_on_koding.png" srcset="https://koding.com/a/img/try_on_koding@1x.png 1x, https://koding.com/a/img/try_on_koding@2x.png 2x" />
          </a>
          """
          
      allowedDomains = @state.team.get 'allowedDomains'
      
      if '*' in allowedDomains.toJS()
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

    allowedDomains = @state.team.get 'allowedDomains'
    allowedDomains = allowedDomains.toJS()
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
      
      @setState
        checked: state
    .catch ({ message }) -> 
      @setState
        checked: not state
  
    
  handleCodeBlockClick: ->
    
    copyContent = @refs.view.refs.textarea
    copyToClipboard copyContent
    
    
  render: ->
    
    <View
      ref='view'
      value={@state.value}
      checked={@state.checked}
      handleCodeBlockClick={@bound 'handleCodeBlockClick'}
      primaryClassName={@state.primaryClassName}
      secondaryClassName={@state.secondaryClassName}
      handleSwitch={@bound 'handleSwitch'}/>
    
    
TryOnKodingContainer.include [KDReactorMixin]
