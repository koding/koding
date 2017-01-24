kd     = require 'kd'
React  = require 'app/react'
Toggle = require 'app/components/common/toggle'


module.exports = class GenericToggler extends React.Component

  @propTypes =
    className   : React.PropTypes.string
    title       : React.PropTypes.string
    description : React.PropTypes.string
    onToggle    : React.PropTypes.func.isRequired
    checked     : React.PropTypes.bool
    disabled    : React.PropTypes.bool


  @defaultProps =
    className   : ''
    title       : ''
    description : ''
    checked     : no
    disabled    : no


  render: ->

    { button, machineState } = @props

    toggleClassName = 'GenericToggler-toggle'
    buttonClassName = 'GenericToggler-button hidden'
    topClassName = 'GenericToggler-top'

    if button
      buttonClassName = 'GenericToggler-button'
      toggleClassName = 'GenericToggler-toggle hidden'
      topClassName = 'GenericToggler-top build-logs'

    unless machineState
      buttonClassName = "#{buttonClassName} disabled"

    <div className={kd.utils.curry @props.className, 'GenericToggler'}>
      <div className={topClassName}>
        <div className='pull-left'>
          <div className='GenericToggler-title'>{@props.title}</div>
          <div className='GenericToggler-description'>{@props.description}</div>
        </div>
        <div className='pull-right'>
          <div className={toggleClassName}>
            <Toggle ref='toggle' callback={@props.onToggle} checked={@props.checked} disabled={@props.disabled} />
          </div>
          <div className={buttonClassName}>
            <a className='custom-link-view HomeAppView--button primary fr' href='#' onClick={@props.onClickButton}>
              <span className='title'>{@props.buttonTitle}</span>
            </a>
          </div>
        </div>
      </div>
      <div className='GenericToggler-bottom'>
        {@props.children}
      </div>
    </div>
