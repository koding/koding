kd        = require 'kd'
Link      = require 'app/components/common/link'
React     = require 'kd-react'
immutable = require 'immutable'


module.exports = class PublicChannelMessageLink extends React.Component

  @defaultProps = { message: immutable.Map() }


  computeHref: ->

    return '#'  if @props.message.get 'isFake'

    { message } = @props

    channelId = message.get 'initialChannelId'
    channel = kd.singletons.socialapi.retrieveCachedItemById channelId
    return  unless channel
    id = message.get 'id'

    return "/Channels/#{channel.name.toLowerCase()}/#{id}"


  render: ->
    <Link {...@props}
      href={@computeHref()}
      className={kd.utils.curry 'MessageLink PublicChannelMessageLink', @props.className}>
      {@props.children}
    </Link>
