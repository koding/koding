class HeaderViewWithLogo extends KDHeaderView
  constructor:->
    super
    @setClass "header-view-with-logo"

  setTitle:(title)->
    console.log 'does this happen?'
    @$().append "<b class='koding-logo-bg'><span class='koding-logo chrisrulez'></span></b>",
                "<span class='section-title'>#{title}</span>"

class HeaderViewSection extends KDHeaderView
  constructor:->
    super
    @setClass "header-view-section"

  setTitle:(title)->
    @$().append "<cite></cite> <span class='section-title'>#{title}</span>"

  setSearchInput:(options = {})->
    @searchInput?.destroy() # If already exist, destroy the old one

    @addSubView @searchInput = new KDHitEnterInputView
      placeholder  : options.placeholder or "Search..."
      name         : options.name        or "searchInput"
      cssClass     : options.cssClass    or "header-search-input"
      type         : "text"
      callback     : =>
        @parent.emit "searchFilterChanged", @searchInput.getValue()
        @searchInput.focus()
      keyup        : =>
        if @searchInput.getValue() is ""
          @parent.emit "searchFilterChanged", ""

    @addSubView icon = new KDCustomHTMLView
      tagName  : "span"
      cssClass : "header-search-input-icon"

class WelcomeHeader extends KDHeaderView
  constructor:->
    super
    @setClass "notification-header"

  click:(event)->
    if $(event.target).is "i"
      localStorage.welcomeMessageClosed = yes
      @remove()
    else if $(event.target).is "a"
      $.ajax
        # url       : KD.config.apiUri+'https://api.koding.com/1.0/logout'
        url       : "/beta.txt"
        success   : (response)=>
          modal = new KDModalView
            title       : "Thanks for joining our beta."
            cssClass    : "what-you-should-know-modal"
            height      : "auto"
            width       : 500
            overlay     : yes
            content     : response
            buttons     :
              Close     :
                title   : 'Close'
                style   : 'modal-clean-gray'
                callback: -> modal.destroy()



  remove:(callback)->
    h = @getHeight()
    @$().animate marginTop : -h, 100, ()=>
      @destroy()
      @utils.wait @notifyResizeListeners.bind @

  setTitle:()->
    {title, subtitle} = @getOptions()
    @$().append "<div><span>#{title}</span><cite>#{subtitle}</cite></div><i/>"


