class CommonFeedMessage extends KDView
  viewAppended:->
    {messageLocation} = @getOptions()
    messageLocation += 'MessageClosed'
    if localStorage[messageLocation]?
      @destroy()
      return
    @setClass 'pane-message'
    @setPartial @partial()
  
  partial:->
    {title} = @getOptions()
    """
      <cite></cite>
      <span class=\"close-btn\" title=\"Close\"></span>
      <div class="message-internals">#{title}</div>
    """
    
  click:(event)->
    if $(event.target).hasClass 'close-btn'
      @slideUpAndDestroy()
      
  slideUpAndDestroy:->
    {messageLocation} = @getOptions()
    messageLocation += 'MessageClosed'
    
    messageHeight = @getHeight()
    
    @$().slideUp =>
      localStorage[messageLocation] = yes
      @propagateEvent { KDEventType : 'FeedMessageDialogClosed', globalEvent : yes }, data: messageHeight
      @destroy()

