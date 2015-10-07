kd          = require 'kd'
React       = require 'kd-react'
classnames  = require 'classnames'

module.exports = class ChannelDropContainer extends React.Component

  getClassNames: -> classnames
    'ChannelDropContainer': yes
    'hidden': not @props.showDropTarget


  render: ->

    <div
      onDrop={@props.onDrop}
      onDragOver={@props.onDragOver}
      onDragLeave={@props.onDragLeave}
      className={@getClassNames()}>
      <div className='ChannelDropContainer-content'>Drop VMs here<br/> to start collaborating</div>
    </div>

