class ViewerTopBar extends JView
  constructor:(options,data)->
    options.cssClass = 'viewer-header top-bar clearfix'
    super options,data

    @addressBarIcon = new KDCustomHTMLView
      tagName   : "span"
      cssClass  : "address-bar-icon"

    @pageLocation = new KDHitEnterInputView
      type      : "text"
      callback  : =>
        @parent.openPath @pageLocation.getValue()
        @pageLocation.focus()

    @refreshButton = new KDCustomHTMLView
      tagName   : "a"
      attributes:
        href    : "#"
      cssClass  : "refresh-link"
      click     : => @parent.refreshIFrame()

  setPath:(path)->
    @pageLocation.unsetClass "validation-error"
    @pageLocation.setValue "#{path}"

  pistachio:->

    """
    {{> @addressBarIcon}}
    {{> @pageLocation}}
    {{> @refreshButton}}
    """
