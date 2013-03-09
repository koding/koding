class ViewerTopBar extends JView
  constructor:(options,data)->

    options.cssClass = 'viewer-header top-bar clearfix'

    super options, data

    @addressBarIcon = new KDCustomHTMLView
      tagName    : "a"
      cssClass   : "address-bar-icon"
      attributes :
        href     : "#"
        target   : "_blank"

    @pageLocation = new KDHitEnterInputView
      type      : "text"
      keyup     : =>
        @addressBarIcon.setDomAttributes href : @pageLocation.getValue()
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

    @addressBarIcon.$().attr "href", path
    @pageLocation.unsetClass "validation-error"
    @pageLocation.setValue path

  pistachio:->

    """
    {{> @addressBarIcon}}
    {{> @pageLocation}}
    {{> @refreshButton}}
    """
