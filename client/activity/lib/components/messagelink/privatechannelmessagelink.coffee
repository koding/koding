kd        = require 'kd'
Link      = require 'app/components/common/link'
React     = require 'kd-react'
immutable = require 'immutable'


module.exports = class PrivateChannelMessageLink extends React.Component

  @defaultProps = { message: immutable.Map() }


  computeHref: ->

    return '#'  if @props.message.get 'isFake'

    { message } = @props

    channelId = message.get 'initialChannelId'
    channel = kd.singletons.socialapi.retrieveCachedItemById channelId

    return  unless channel

    id = message.get 'id'

    return "/Messages/#{channel.id}/#{id}"


  render: ->
    <Link {...@props}
      href={@computeHref()}
      className={kd.utils.curry 'MessageLink PrivateChannelMessageLink', @props.className}>
      {@props.children}
    </Link>




