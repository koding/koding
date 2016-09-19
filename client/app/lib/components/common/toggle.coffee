kd          = require 'kd'
React       = require 'kd-react'
ReactToggle = require 'react-toggle'

require './styl/toggle.styl'
require './styl/popover.styl'

module.exports = class Toggle extends React.Component

  @defualtProps =
    size            : 'small'
    defaultChecked  : no
    callback        : kd.noop


  onChange: (event) ->

    @props.callback event.target.checked


  render: ->

    className = "#{kd.utils.curry('ReactToggle', @props.className)} #{@props.size}"

    props = _.omit @props, ['callback']

    <div className={className}>
      <ReactToggle {...props} onChange={@bound 'onChange'} />
    </div>


