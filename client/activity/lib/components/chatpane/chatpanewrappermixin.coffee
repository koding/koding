kd           = require 'kd'
React        = require 'kd-react'
ActivityFlux = require 'activity/flux'

module.exports = ChatPaneWrapperMixin =

  channel: (key) -> @props.thread?.getIn ['channel', key]


  onSubmit: ({ value }) ->

    return  unless body = value

    ActivityFlux.actions.message.createMessage @channel('id'), body


  onCommand: ({ command }) ->

    ActivityFlux.actions.command.executeCommand command, @props.thread.get 'channel'


  onLoadMore: ->

    messages = @props.thread.get 'messages'
    return  unless messages.size

    from = messages.first().get 'createdAt'

    ActivityFlux.actions.message.loadMessages @channel('id'), { from }


  onInviteOthers: ->

    return  unless input = @refs.chatInputWidget

    input.setCommand '/invite @'

