kd           = require 'kd'
React        = require 'kd-react'
immutable    = require 'immutable'
ChannelLabel = require 'activity/components/channellabel'
{ actions }  = require 'activity/flux'

module.exports = class FollowChannelBox extends React.Component

  @propTypes =
    channel   : React.PropTypes.instanceOf immutable.Map
    className : React.PropTypes.string


  @defaultProps =
    channel   : immutable.Map()
    className : ''


  onFollowChannel: ->

    actions.channel.followChannel @props.channel.get 'id'


  render: ->

    <div className={kd.utils.curry "FollowChannelBox", @props.className}>
      This is a preview of <ChannelLabel channel={@props.channel} />
      <button
        className="Button Button-followChannel"
        onClick={@bound 'onFollowChannel'}>Join</button>
    </div>
