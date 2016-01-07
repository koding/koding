kd = require 'kd'
React = require 'kd-react'
ChannelLabel = require 'activity/components/channellabel'

{ actions } = require 'activity/flux'


module.exports = class FollowChannelBox extends React.Component

  channel: (keyPath...) -> @props.thread.getIn ['channel'].concat keyPath


  onFollowChannel: ->

    actions.channel.followChannel @channel 'id'


  render: ->

    <div className={kd.utils.curry "FollowChannelBox", @props.className}>
      This is a preview of <ChannelLabel thread={@props.thread} />
      <button
        className="Button Button-followChannel"
        onClick={@bound 'onFollowChannel'}>Join</button>
    </div>
