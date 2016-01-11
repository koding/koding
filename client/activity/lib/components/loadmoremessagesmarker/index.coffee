kd = require 'kd'
React = require 'kd-react'
ActivityFlux = require 'activity/flux'


module.exports = class LoadMoreMessagesMarker extends React.Component

  @defaultProps =
    channelId : null
    messageId : null
    timestamp : null
    position  : 'after'
    autoload  : no


  onClick: (event) ->

    kd.utils.stopDOMEvent event

    { channelId, messageId, position, timestamp } = @props

    positionToLimiterMap = after: 'from', before: 'to'
    positionToSortOrderMap = after: 'ASC', before: 'DESC'

    limiterOption = positionToLimiterMap[position]
    sortOrderOption = positionToSortOrderMap[position]

    options = {}
    options[limiterOption] = timestamp
    options['sortOrder'] = sortOrderOption

    { message: messageActions } = ActivityFlux.actions

    messagesBefore = kd.singletons.reactor.evaluate ['MessagesStore']

    messageActions.loadMessages(channelId, options).then ({ messages }) ->
      messageActions.removeLoaderMarker channelId, messageId, { position }

      [..., last] = messages
      return  unless last

      # don't put loader markers on top.
      return  unless position is 'after'

      unless messagesBefore.has last.id
        messageActions.putLoaderMarker channelId, last.id, { position: 'after', autoload: no }


  render: ->
    return null  unless @props.channelId

    <div className="LoadMoreMessagesMarker">
      <a href="#" onClick={@bound 'onClick'}>Load more</a>
    </div>
