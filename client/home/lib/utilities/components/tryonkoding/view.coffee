kd               = require 'kd'
React            = require 'kd-react'
KodingSwitch     = require 'app/commonviews/kodingswitch'


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
    
    toggleState = if @props.checked then 'on' else off
    toggleClassName = kd.utils.curry 'kdinput koding-on-off small', toggleState
     
    <div>
      <div className={toggleClassName} onClick={@props.handleSwitch.bind(this, @props.checked)}>
        <a href='#' className='knob' title='turn on'></a>
        <input className="react-toggle-screenreader-only" type="checkbox" />
      </div>
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
  
  