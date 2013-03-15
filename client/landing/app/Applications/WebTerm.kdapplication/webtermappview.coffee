class WebTermAppView extends JView

  constructor: (options = {}, data) ->

    super options, data

    @tabHandleContainer = new ApplicationTabHandleHolder
      delegate: @

    @tabView = new ApplicationTabView
      delegate           : @
      tabHandleContainer : @tabHandleContainer
      resizeTabHandles   : yes

    @on 'ViewClosed', => @emit 'WebTermAppViewWantsToClose'

    @on 'AllViewsClosed', => @emit 'WebTermAppViewWantsToClose'

    @tabView.on 'PaneDidShow', (pane) =>
      {webTermView} = pane.getOptions()
      webTermView.on 'viewAppended', -> webTermView.terminal.setFocused yes
      webTermView.terminal?.setFocused yes

  viewAppended: ->
    super
    @addNewTab()

  addNewTab: ->
    webTermView = new WebTermView
    pane = new KDTabPaneView
      name: 'Terminal'
      webTermView: webTermView

    @tabView.addPane pane
    pane.addSubView webTermView

  pistachio: ->
    """
      {{> @tabHandleContainer}}
      {{> @tabView}}
    """