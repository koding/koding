kd = require 'kd'
React = require 'kd-react'
ApiToken = require './apitoken'
List = require 'app/components/list'
Toggle = require 'app/components/common/toggle'
remote = require 'app/remote'
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


  renderEmptySectionAtIndex: ->

    <div className='HomeApp-ApiToken--no-token'> No tokens have been created yet. When you create, they will be listed here.</div>


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
      <Header callback={@bound 'addNewApiToken'}/>
      <div className='HomeApp-ApiToken--label'>Active API Token List</div>
      <List
        numberOfSections={@bound 'numberOfSections'}
        numberOfRowsInSection={@bound 'numberOfRowsInSection'}
        renderSectionHeaderAtIndex={@bound 'renderSectionHeaderAtIndex'}
        renderRowAtIndex={@bound 'renderRowAtIndex'}
        renderEmptySectionAtIndex={@bound 'renderEmptySectionAtIndex'}
        rowClassName='HomeApp-ApiToken--ListItem'
        sectionClassName='HomeApp-ApiTokenSection'
      />
      <div className='HomeApp-ApiToken--footer'>
        <div className='HomeApp-ApiToken--footer--button-wrapper'>
          <GuideButton />
          <AddNewApiTokenButton toggleState={toggleState} callback={@bound 'addNewApiToken'}/>
        </div>
      </div>

    </div>

Header = ({ callback }) ->

  label = 'Enable API Access'
  description = 'Allow 3rd party services to securely communicate with Koding.'

  <div className='HomeApp-ApiToken--header'>
    <div className='label'>{label}</div>
    <span className='description'>{description}</span>
  </div>


GuideButton = ->

  <a className="custom-link-view HomeAppView--button fl" href="https://www.koding.com/docs/api-tokens">
    <span className="title">VIEW GUIDE</span>
  </a>


AddNewApiTokenButton = ({ toggleState, callback }) ->

  className = 'custom-link-view HomeAppView--button primary fr'
  className = "#{className} disabled"  unless toggleState

  <a className={className} onClick={callback}>
    <span className="title">ADD NEW API TOKEN</span>
  </a>
