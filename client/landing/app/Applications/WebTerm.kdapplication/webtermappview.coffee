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
      webTermView.once 'viewAppended', => @emit "ready"
      webTermView.terminal?.setFocused yes

      webTermView.on "WebTerm.terminated", (server) =>
        if not pane.isDestroyed and @tabView.getActivePane() is pane
          @tabView.removePane pane

  handleQuery:(query)->
    pane = @tabView.getActivePane()
    {webTermView} = pane.getOptions()
    webTermView.once 'WebTermConnected', (remote)->
      if query.command
        command = decodeURIComponent query.command
        modal = new KDModalView
          title   : "Warning!"
          content : """
          <div class="modalformline">
            <p>
              If you <strong>don't trust this app</strong>, or if you clicked on this
              link <strong>not knowing what it would do</strong> - be careful it <strong>can
              damage/destroy</strong> your Koding VM.
            </p>
          </div>
          <div class="modalformline">
            <p>
              This URL is set to execute the command below:
            </p>
          </div>
          <pre>
            #{Encoder.XSSEncode command}
          </pre>
          """
          buttons :
            "Run" :
              cssClass: "modal-clean-gray"
              callback: ->
                remote.input "#{command}\n"
                modal.destroy()
            "Cancel":
              cssClass: "modal-cancel"
              callback: ->
                modal.destroy()

  _windowDidResize:->
    # 10px being the application page's padding
    @tabView.setHeight @getHeight() - @tabHandleContainer.getHeight() - 10

  viewAppended: ->
    super
    @addNewTab()

  addNewTab: ->
    webTermView = new WebTermView
      delegate: this

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