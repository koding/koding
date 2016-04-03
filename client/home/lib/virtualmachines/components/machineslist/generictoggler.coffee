kd     = require 'kd'
React  = require 'kd-react'
Toggle = require 'app/components/common/toggle'


module.exports = class GenericToggler extends React.Component


  render: ->

    <div className={kd.utils.curry @props.className, 'GenericToggler'}>
      <div className="GenericToggler-top">
        <div className='pull-left'>
          <div className='GenericToggler-title'>{@props.title}</div>
          <div className='GenericToggler-description'>{@props.description}</div>
        </div>
        <div className='pull-right'>
          <div className='GenericToggler-toggle'>
            <Toggle callback={@props.onToggle} />
          </div>
        </div>
      </div>
      <div className='GenericToggler-bottom'>
        {@props.children}
      </div>
    </div>


