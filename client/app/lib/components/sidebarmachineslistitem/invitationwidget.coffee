kd      = require 'kd'
React   = require 'kd-react'
Popover = require 'app/components/common/popover'


module.exports = class InvitationWidget extends React.Component

  render: ->
    <Popover {...@props} className={kd.utils.curry 'InvitationWidget', @props.className}>
      {@props.children}
    </Popover>