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


  onResize: ->

    ChatPaneBody              = document.querySelector '.ChatPane-body'
    ChatPaneFooter            = document.querySelector '.ChatPaneFooter'
    scrollContainer           = ChatPaneBody.querySelector '.Scrollable'
    footerHeight              = ChatPaneFooter.offsetHeight
    ChatPaneBodyHeight        = "calc(100% \- #{footerHeight}px)"
    ChatPaneBody.style.height = ChatPaneBodyHeight


    # we can not catch 0px to scroll to bottom. If scroll near about 20px or less
    # and when new message received we make scroll to bottom so user can see new messages.
    # If not probably user is reading old messages and we don't make scroll to bottom.

    { scrollTop, offsetHeight, scrollHeight } = scrollContainer

    if scrollHeight - (scrollTop + offsetHeight) < 20
      scrollContainer.scrollTop = scrollHeight

