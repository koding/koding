kd                   = require 'kd'
React                = require 'kd-react'
Link                 = require 'app/components/common/link'

module.exports = class StartVideoCallLink extends React.Component

  render: ->

    <Link className='StartVideoCall-link' onClick={@props.onStart}>
      <span>Start a Video Call</span>
      <i className='StartVideoCall-icon'></i>
    </Link>
