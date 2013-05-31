class WebTermAppView extends JView

  constructor: (options = {}, data) ->

    super options, data

    @listenWindowResize()

    @tabHandleContainer = new ApplicationTabHandleHolder
      delegate: @

    @tabView = new ApplicationTabView
      delegate           : @
      tabHandleContainer : @tabHandleContainer
      resizeTabHandles   : yes

    @tabView.on 'PaneDidShow', (pane) =>
      @_windowDidResize()
      {webTermView} = pane.getOptions()
      webTermView.on 'viewAppended', -> webTermView.terminal.setFocused yes
      webTermView.terminal?.setFocused yes

      webTermView.on "WebTerm.terminated", (server) =>
        if not pane.isDestroyed and @tabView.getActivePane() is pane
          @tabView.removePane pane

  _windowDidResize:->
    # 10px being the application page's padding
    @tabView.setHeight @getHeight() - @tabHandleContainer.getHeight() - 10

  viewAppended: ->
    super
    @addNewTab()

  addNewTab: ->
    webTermView = new WebTermView
      delegate: @

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