kd        = require 'kd'
Link      = require 'app/components/common/link'
React     = require 'kd-react'
immutable = require 'immutable'


module.exports = class MessageLink extends React.Component

  @defaultProps =
    message         : immutable.Map()
    isSummaryActive : no
    absolute        : no


  computeHref: ->

    return '#'  if @props.message.get 'isFake'

    { message } = @props

    if @props.absolute
      channelId = message.get 'initialChannelId'
      channel = kd.singletons.socialapi.retrieveCachedItemById channelId

      href = "/Channels/#{channel.name.toLowerCase()}"
      href += '/summary'  if @props.isSummaryActive
      href += '/'

    href += message.get 'slug'

    return href


  render: ->
    <Link
      href={@computeHref()}
      className={kd.utils.curry 'MessageLink', @props.className}>
      {@props.children}
    </Link>



