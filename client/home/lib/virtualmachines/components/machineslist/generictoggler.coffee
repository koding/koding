kd     = require 'kd'
React  = require 'kd-react'
Toggle = require 'app/components/common/toggle'


module.exports = class GenericToggler extends React.Component

  @propTypes =
    className   : React.PropTypes.string
    title       : React.PropTypes.string
    description : React.PropTypes.string
    onToggle    : React.PropTypes.func.isRequired


  @defaultProps =
    className   : ''
    title       : ''
    description : ''


  render: ->

    <div className={kd.utils.curry @props.className, 'GenericToggler'}>
      <div className="GenericToggler-top">
        <div className='pull-left'>
          <div className='GenericToggler-title'>{@props.title}</div>
          <div className='GenericToggler-description'>{@props.description}</div>
        </div>
        <div className='pull-right'>
          <div className='GenericToggler-toggle'>
            <Toggle ref='toggle' callback={@props.onToggle} />
          </div>
        </div>
      </div>
      <div className='GenericToggler-bottom'>
        {@props.children}
      </div>
    </div>


