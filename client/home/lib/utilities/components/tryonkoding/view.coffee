kd = require 'kd'
React = require 'app/react'
KodingSwitch = require 'app/commonviews/kodingswitch'
Toggle = require 'app/components/common/toggle'
CodeBlock = require 'app/components/codeblock'

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

  renderFooter: ->

    return  if @props.checked
    <div className='TryOnKodingButton--footer'>
      {@renderGuideButton()}
    </div>


  render: ->

    <div>
      <ToggleButton canEdit={@props.canEdit} checked={@props.checked} callback={@props.handleSwitch} />
      <Primary className={@props.primaryClassName}/>
      <div className={@props.secondaryClassName}>
        <p>
          <strong>“Try On Koding” Button</strong>
          Visiting users will have access to all team stack scripts
        </p>
        <CodeBlock cmd={@props.value} />
        {@renderButtons()}
      </div>
      {@renderFooter()}
    </div>


ToggleButton = ({ checked, callback, canEdit }) ->

  return <span></span>  unless canEdit

  <Toggle checked={checked} className='TryOnKoding-onOffButton OnOffButton' callback={callback} />


Primary = ({ className }) ->

  <p className={className}>
    <strong>Enable “Try On Koding” Button</strong>
    Allow access to team stack catalogue for visitors
  </p>
