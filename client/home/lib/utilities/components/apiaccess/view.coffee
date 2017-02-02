kd = require 'kd'
React = require 'app/react'
ApiToken = require './apitoken'
List = require 'app/components/list'
Toggle = require 'app/components/common/toggle'


module.exports = class View extends React.Component


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

    <div className='HomeApp-ApiToken--no-token'>
      No tokens have been created yet. When you create, they will be listed here.
    </div>


  render: ->

    toggleState = @props.apiAccessState

    toggleProps =
      checked: toggleState
      className: 'HomeApp-ApiToken--swicth-toggle'
      callback: @props.onSwitchToggle

    buttonProps =
      toggleState: toggleState
      callback: @props.onAddNewApiToken

    <div className='HomeApp-ApiToken'>
      <Toggle {...toggleProps} />
      <Header />
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
          <AddNewApiTokenButton {...buttonProps} />
        </div>
      </div>
    </div>

Header = ->

  label = 'Enable API Access'
  description = 'Allow 3rd party services to securely communicate with Koding.'

  <div className='HomeApp-ApiToken--header'>
    <div className='label'>{label}</div>
    <span className='description'>{description}</span>
  </div>


GuideButton = ->

  <a className="custom-link-view HomeAppView--button fl"
    href="https://www.koding.com/docs/api-tokens">
    <span className="title">VIEW GUIDE</span>
  </a>


AddNewApiTokenButton = ({ toggleState, callback }) ->

  className = 'custom-link-view HomeAppView--button primary fr'
  className = "#{className} disabled"  unless toggleState

  <a className={className} onClick={callback}>
    <span className="title">ADD NEW API TOKEN</span>
  </a>
