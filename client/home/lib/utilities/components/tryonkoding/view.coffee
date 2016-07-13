kd = require 'kd'
React = require 'kd-react'
KodingSwitch = require 'app/commonviews/kodingswitch'
Toggle = require 'app/components/common/toggle'
CodeBlock = require 'app/components/codeblock'

module.exports = class TryOnKodingView extends React.Component

  comingSoon: ->

    return new kd.NotificationView
      title    : 'Coming Soon!'
      duration : 2000

  renderGuideButton: ->

    <a className='custom-link-view HomeAppView--button' onClick={@comingSoon}>
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
      <ToggleButton canEdit={@props.canEdit} checked={@props.checked} callback={@props.handleSwitch} />
      <Primary className={@props.primaryClassName}/>
      <p className={@props.secondaryClassName}>
        <strong>“Try On Koding” Button</strong>
        Visiting users will have access to all team stack scripts
        <CodeBlock cmd={@props.value} />
        {@renderButtons()}
      </p>
    </div>


ToggleButton = ({ checked, callback, canEdit }) ->

  return <span></span>  unless canEdit

  <Toggle checked={checked} className='TryOnKoding-onOffButton' callback={callback} />


Primary = ({ className }) ->

  <p className={className}>
    <strong>Enable “Try On Koding” Button</strong>
    Allow access to team stack catalogue for visitors
  </p>

