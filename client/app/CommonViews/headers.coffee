class HeaderViewWithLogo extends KDHeaderView
  constructor:->
    super
    @setClass "header-view-with-logo"

  setTitle:(title)->
    @$().append "<b class='koding-logo-bg'><span class='koding-logo'></span></b>"
    @$().append "<span class='section-title'>#{title}</span>"

class HeaderViewSection extends KDHeaderView
  constructor:->
    super
    @setClass "header-view-section"

  setTitle:(title)->
    @$().append "<cite></cite> <span class='section-title'>#{title}</span>"

class WelcomeHeader extends KDHeaderView
  constructor:->
    super
    @setClass "notification-header"
  
  click :(event)->
    if $(event.target).is "a"
      localStorage.welcomeMessageClosed = yes
      @remove()

  remove:(callback)->
    h = @getHeight()
    @$().animate marginTop : -h, 100, ()=> 
      @destroy()
      @notifyResizeListeners()
      # after half an hour try i didn't understand why it didnt work at one call, so have the second :)
      # fix this if you see it again.
      @notifyResizeListeners()

  setTitle:()->
    {title, subtitle} = @getOptions()
    @$().append "<div><span>#{title}</span><cite>#{subtitle}</cite></div><a href='#'> </a>"