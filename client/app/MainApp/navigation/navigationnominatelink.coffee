class NavigationNominateLink extends JView

  constructor:(options = {}, data)->

    options.tagName  = "a"
    options.cssClass = "title"
    options.tooltip  =
      placement      : "right"
      # offset         : -10
      title          :
        """
          Nominate Koding for
          Best New Startup 2013
        """

    super options, data

    @icon       = new KDCustomHTMLView
      tagName   : "span"
      cssClass  : "main-nav-icon nominate"

  click:(event)->
    KD.utils.stopDOMEvent event
    appManager = KD.getSingleton "appManager"
    appManager.tell "Account", "showNominateModal"

  pistachio: ->
    """
      {{> @icon}} {{ #(title)}}
    """
