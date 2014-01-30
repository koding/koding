class NavigationPromoteLink extends JView

  constructor:(options = {}, data)->

    options.tagName  = "a"
    options.cssClass = "title"
    options.tooltip  =
      placement      : "right"
      # offset         : -10
      title          :
        """
        Only this week, share your link, they get 5GB instead
        of 4GB, and you get 1GB extra!
        """

    super options, data

    @icon       = new KDCustomHTMLView
      tagName   : "span"
      cssClass  : "main-nav-icon promote"

  click:(event)->
    KD.utils.stopDOMEvent event
    appManager = KD.getSingleton "appManager"
    appManager.tell "Account", "showReferrerModal"

  pistachio: ->
    """
      {{> @icon}} {{ #(title)}}
    """
