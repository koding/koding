class FinderBottomControlsListItem extends KDListItemView
  constructor:(options,data)->
    options = $.extend
      tagName      : "li"
    ,options
    super options,data

  click:(event)->
    if @getData().path?
      appManager.openApplication @getData().path if @getData().path? 
      # if @getData().path isnt 'Shell.kdapplication'
      #   appManager.openApplication @getData().path
      # else if @getData().path is 'Shell.kdapplication' and not appManager.terminalIsOpen
      #   appManager.openApplication @getData().path 
      #   appManager.terminalIsOpen = yes
    
    else 
      new KDNotificationView
        title : "Coming Soon!"
        duration : 1000
  
  viewAppended:->
    super

    data = @getData()
    if data.icon isnt "terminal"
      @$().twipsy
        title     : "<p class='login-tip'>Coming Soon</p>"
        placement : "right"
        offset    : 3
        delayIn   : 300
        html      : yes
        animate   : yes
        offset    : -60

  partial:(data)->
    """
      <a href="#"><span class='icon #{data.icon}'></span>#{data.title}</a>
    """
