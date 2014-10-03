class ViewerTopBar extends JView

  constructor:(options,data)->

    options.cssClass = 'viewer-header top-bar clearfix'

    super options, data

    @addressBarIcon   = new KDCustomHTMLView
      tagName         : "a"
      cssClass        : "address-bar-icon"
      attributes      :
        href          : "#"
        target        : "_blank"

    @pageLocation     = new KDHitEnterInputView
      type            : "text"
      placeholder     : "Type a URL and hit enter"
      keyup           : =>
        @addressBarIcon.setAttribute "href", @pageLocation.getValue()
      callback        : =>
        newLocation   = @pageLocation.getValue()
        @parent.openPath newLocation
        @pageLocation.focus()
        @getDelegate().emit "ViewerLocationChanged", newLocation

    @refreshButton    = new KDCustomHTMLView
      tagName         : "a"
      attributes      :
        href          : "#"
      cssClass        : "refresh-link"
      click           : =>
        @parent.refreshIFrame()
        @getDelegate().emit "ViewerRefreshed"

  setPath:(path)->
    @addressBarIcon.setAttribute "href", path
    @pageLocation.unsetClass "validation-error"
    @pageLocation.setValue path

  pistachio:->
    """
      {{> @addressBarIcon}}
      {{> @pageLocation}}
      {{> @refreshButton}}
    """
