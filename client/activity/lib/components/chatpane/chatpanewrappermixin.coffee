module.exports = ChatPaneWrapperMixin =

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

