class NavigationPromoteLink extends JView

  constructor:(options = {}, data)->

    options.tagName  = "a"
    options.cssClass = "title"
    options.tooltip  =
      placement      : "right"
      # offset         : -10
      title          :
        """
        If anyone registers with your referrer code,
        you will get 250MB Free disk space for your VM.
        Up to 16GB!.
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
