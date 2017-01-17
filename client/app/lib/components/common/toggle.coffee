kd          = require 'kd'
React       = require 'app/react'
ReactToggle = require('react-toggle').default

require './styl/toggle.styl'
require './styl/popover.styl'

module.exports = class Toggle extends React.Component

  @defaultProps =
    size            : 'small'
    callback        : kd.noop


  onChange: (event) ->

    @props.callback event.target.checked


  render: ->

    className = "#{kd.utils.curry('ReactToggle', @props.className)} #{@props.size}"

    props = _.omit @props, ['callback', 'className', 'size']

    props.checked or= no
    <div className={className}>
      <ReactToggle {...props} onChange={@bound 'onChange'} />
    </div>
