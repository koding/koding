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
        KD.getSingleton('appManager').tell 'IDE', 'showStatusBarMenu', @menuButton

    @addSubView @status
    @addSubView @menuButton

  showInformation: ->
    @status.updatePartial 'Click the plus button above to create a new panel'
