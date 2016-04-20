kd = require 'kd'
React = require 'kd-react'
KodingSwitch = require 'app/commonviews/kodingswitch'
Toggle = require 'app/components/common/toggle'

module.exports = class TryOnKodingView extends React.Component

  renderGuideButton: ->
    
    <a className='custom-link-view HomeAppView--button' href='https://www.koding.com/docs/koding-button'>
      <span className='title'>VIEW GUIDE</span>
    </a>
  
  
  renderTryOnKodingButton: ->
    
    <a className='custom-link-view TryOnKodingButton fr' href='#'></a>
    
  renderButtons: ->

    <span>
      {@renderGuideButton()} {@renderTryOnKodingButton()}
    </span>
  
  
  render: ->

    <div>
      <Toggle checked={@props.checked} className='TryOnKoding-onOffButton' callback={@props.handleSwitch} />
      <Primary className={@props.primaryClassName}/>
      <p className={@props.secondaryClassName}>
        <strong>“Try On Koding” Button</strong>
        Visiting users will have access to all team stack scripts
        <code className='HomeAppView--code block' onClick={@props.handleCodeBlockClick}>
          <textarea ref='textarea' spellCheck={no} disabled={yes} value={@props.value}>
          </textarea>
        </code>
        {@renderButtons()}
      </p>
    </div>


Primary = ({ className }) ->
  
  <p className={className}>
    <strong>Enable “Try On Koding” Button</strong>
    Allow access to team stack catalogue for visitors
  </p>
  
  