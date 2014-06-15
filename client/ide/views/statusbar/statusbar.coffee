class IDE.StatusBar extends KDView

  constructor: (options = {}, data) ->

    options.cssClass = 'status-bar'

    super options, data

    @status     = new KDCustomHTMLView
      cssClass  : 'status'

    @menuButton = new KDCustomHTMLView
      tagName   : 'span'
      cssClass  : 'actions-button'
      click     : =>
        KD.getSingleton('appManager').tell 'IDE', 'showActionsMenu', @menuButton

    @addSubView @status
    @addSubView @menuButton
