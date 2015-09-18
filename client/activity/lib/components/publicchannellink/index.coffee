kd = require 'kd'
React = require 'kd-react'
Link  = require 'app/components/common/link'


module.exports = class PublicChannelLink extends React.Component

  @defaultProps = { to: null }


  channel: (key) -> @props.to?.getIn ['channel', key]


  render: ->
    <Link {...@props}
      className={kd.utils.curry "PublicChannelLink", @props.className}
      href="/Channels/#{@channel('name') ? '#'}">
      {@props.children}
    </Link>
