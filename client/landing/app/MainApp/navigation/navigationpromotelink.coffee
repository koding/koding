class NavigationPromoteLink extends JView

  constructor:(options = {}, data)->

    options.tagName  = "a"
    options.cssClass = "title"

    super options, data

    @icon       = new KDCustomHTMLView
      tagName   : "span"
      cssClass  : "main-nav-icon promote"

  click:(event)->
    KD.utils.stopDOMEvent event
    appManager = KD.getSingleton "appManager"
    appManager.tell "Account", "showReferrerTooltip",
      linkView    : this
      top         : 50
      left        : -70
      arrowMargin : -200

    return no

  pistachio: ->
    """
      {{> @icon}} {{ #(title)}}
    """
