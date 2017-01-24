kd      = require 'kd'
React   = require 'app/react'
Popover = require 'app/components/common/popover'


module.exports = class SidebarWidget extends React.Component

  render: ->
    <Popover {...@props} className={kd.utils.curry 'SidebarWidget', @props.className}>
      {@props.children}
    </Popover>
