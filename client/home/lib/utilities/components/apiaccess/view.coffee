kd = require 'kd'
React = require 'kd-react'
ApiToken = require './apitoken'
List = require 'app/components/list'
Toggle = require 'app/components/common/toggle'
remote = require('app/remote').getInstance()
TeamFlux = require 'app/flux/teams'
showError = require 'app/util/showError'


module.exports = class View extends React.Component

  constructor: (props) ->

    super props


  numberOfSections: -> 1


  numberOfRowsInSection: ->

    @props.apiTokens?.size or 0


  renderSectionHeaderAtIndex: -> null


  renderRowAtIndex: (sectionIndex, rowIndex) ->

    apiToken = @props.apiTokens.toList().get(rowIndex)
    key = apiToken?.get '_id'
    toggleState = @props.apiAccessState
    <ApiToken
      key={key}
      apiToken={apiToken}
      toggleState={toggleState} />  if apiToken


  renderEmptySectionAtIndex: -> <div> No data found</div>


  addNewApiToken: ->

    remote.api.JApiToken.create (err, apiToken) ->
      return showError err  if err
      TeamFlux.actions.addApiToken apiToken


  switchToggle: (state) ->

    TeamFlux.actions.disableApiTokens(state)
    .catch ({err}) ->
      showError err

  render: ->

    toggleState = @props.apiAccessState

    <div className='HomeApp-ApiToken'>

      <Toggle checked={toggleState} className='HomeApp-ApiToken--swicth-toggle' callback={@bound 'switchToggle'} />
      <Header toggleState={toggleState} callback={@bound 'addNewApiToken'}/>
      <List
        numberOfSections={@bound 'numberOfSections'}
        numberOfRowsInSection={@bound 'numberOfRowsInSection'}
        renderSectionHeaderAtIndex={@bound 'renderSectionHeaderAtIndex'}
        renderRowAtIndex={@bound 'renderRowAtIndex'}
        renderEmptySectionAtIndex={@bound 'renderEmptySectionAtIndex'}
        rowClassName='HomeApp-ApiToken--ListItem'
        sectionClassName='HomeApp-ApiTokenSection'
      />
    </div>

Header = ({ toggleState, callback }) ->

  className = 'kdbutton GenericButton fr'
  className = "#{className} disabled"  unless toggleState

  <div className='HomeApp-ApiToken--header'>
    <label> API Token List </label>
    <button className={className} onClick={callback}>Add New API Token</button>
  </div>
