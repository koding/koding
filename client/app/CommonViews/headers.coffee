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
