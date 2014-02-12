class DevToolsMainView extends KDView

  COFFEE = "//cdnjs.cloudflare.com/ajax/libs/coffee-script/1.6.3/coffee-script.min.js"

  constructor:->
    super

    @storage = KD.singletons.localStorageController.storage "DevTools"
    @liveMode = @storage.getAt 'liveMode'

  viewAppended:->

    @addSubView @workspace      = new CollaborativeWorkspace
      name                      : "Koding DevTools"
      delegate                  : this
      firebaseInstance          : "tw-local"
      panels                    : [
        title                   : "Koding DevTools"
        buttons                 : [
          {
            title               : "Create"
            cssClass            : "solid"
            callback            : ->
              KD.singletons.kodingAppsController.makeNewApp()
          }
          {
            title               : "Compile"
            cssClass            : "solid green"
            disabled            : yes
            callback            : => @compileApp()
          }
          {
            title               : 'Run as I type'
            cssClass            : "solid #{if @liveMode then 'green' else 'live'}"
            callback            : =>

              button = @workspace.panels.first.headerButtons['Run as I type']
              button.unsetClass 'live green'
              button.setClass if @liveMode then 'live' else 'green'
              @liveMode = button.hasClass 'green'
              @storage.setValue 'liveMode', @liveMode

              if @liveMode
                @previewApp yes; @previewCss yes

          }
        ]
        layout                  :
          direction             : "vertical"
          sizes                 : [ "264px", null ]
          splitName             : "BaseSplit"
          views                 : [
            {
              type              : "finder"
              name              : "finder"
              editor            : "JSEditor"
              handleFileOpen    : (file, content) =>

                {CSSEditor, JSEditor} = @workspace.activePanel.panesByName

                switch FSItem.getFileExtension file.path
                  when 'css', 'styl'
                  then editor = CSSEditor
                  else editor = JSEditor

                editor.openFile file, content

            }
            {
              type              : "split"
              options           :
                direction       : "vertical"
                sizes           : [ "50%", "50%" ]
                splitName       : "InnerSplit"
                cssClass        : "inner-split"
              views             : [
                {
                  type          : "split"
                  options       :
                    direction   : "horizontal"
                    sizes       : [ "50%", "50%" ]
                    splitName   : "EditorSplit"
                    cssClass    : "editor-split"
                  views         : [
                    {
                      type      : "custom"
                      name      : "JSEditor"
                      paneClass : DevToolsEditorPane
                      title     : "JavaScript"
                      # buttons : [
                      #   {
                      #     itemClass: KDOnOffSwitch
                      #     callback: ->
                      #       log arguments
                      #   }
                      # ]
                    }
                    {
                      type      : "custom"
                      name      : "CSSEditor"
                      title     : "Style"
                      paneClass : DevToolsCssEditorPane
                    }
                  ]
                }
                {
                  type          : "custom"
                  name          : "PreviewPane"
                  paneClass     : CollaborativePane
                }
              ]
            }
          ]
      ]

    @workspace.ready =>

      {JSEditor, CSSEditor} = panes = @workspace.activePanel.panesByName

      JSEditor.ready =>
        JSEditor.codeMirrorEditor.on "change", \
          _.debounce (@lazyBound 'previewApp', no), 500

        JSEditor.on "OpenedAFile", (file, content)->
          app = KodingAppsController.getAppInfoFromPath file.path
          button = @workspace.panels.first.headerButtons['Compile']
          if app then button.enable() else button.disable()

      CSSEditor.ready =>
        CSSEditor.codeMirrorEditor.on "change", \
          _.debounce (@lazyBound 'previewCss', no), 500

  previewApp:(force = no)->

    return  if not force and not @liveMode
    return  if @_inprogress
    @_inprogress = yes

    {JSEditor, PreviewPane} = @workspace.activePanel.panesByName
    editorData = JSEditor.getData()
    extension = if editorData then editorData.getExtension() else 'coffee'

    if extension not in ['js', 'coffee']
      @_inprogress = no
      pc = PreviewPane.container
      pc.destroySubViews()
      pc.addSubView new ErrorPaneWidget {},
        error     :
          name    : "Preview not supported"
          message : "You can only preview .coffee and .js files."
      return

    @compiler (coffee)=>

      code = JSEditor.getValue()

      PreviewPane.container.destroySubViews()
      window.appView = new KDView

      try

        switch extension
          when 'js' then eval code
          when 'coffee' then coffee.run code

        PreviewPane.container.addSubView window.appView

      catch error

        try window.appView.destroy?()
        warn "Failed to run:", error

        PreviewPane.container.addSubView new ErrorPaneWidget {}, {code, error}

      finally

        delete window.appView
        @_inprogress = no


  previewCss:(force = no)->

    return  if not force and not @liveMode

    {CSSEditor, PreviewPane} = @workspace.activePanel.panesByName

    @_css?.remove()

    @_css = $ "<style scoped></style>"
    @_css.html CSSEditor.getValue()

    PreviewPane.container.domElement.prepend @_css

  compiler:(callback)->

    return callback @coffee  if @coffee
    require [COFFEE], (@coffee)=> callback @coffee


  compileApp:->

    {JSEditor} = @workspace.activePanel.panesByName
    app = KodingAppsController.getAppInfoFromPath JSEditor.getData()?.path

    if app

      @compileAppOnServer app, ->
        log "COMPILE", arguments


  compileAppOnServer:(app, callback)->

    loader = new KDNotificationView
      duration : 18000
      title    : "Compiling #{app.name}..."
      type     : "mini"

    {vmController} = KD.singletons
    vmController.run "kdc #{app.path}", (err, response)=>

      unless err

        loader.notificationSetTitle "App compiled successfully"
        loader.notificationSetTimer 2000
        callback()

      else

        loader.destroy()

        if err.message is "exit status 127"
          @installKDC()
          callback? err
          return

        new KDModalView
          title    : "An error occured while compiling #{app.name}"
          width    : 600
          overlay  : yes
          cssClass : 'compiler-modal'
          content  : if response then "<pre>#{response}</pre>" \
                                 else "<p>#{err.message}</p>"

        callback? err

  installKDC:->
    modal = new ModalViewWithTerminal
      title   : "Koding app compiler is not installed in your VM."
      width   : 500
      overlay : yes
      terminal:
        hidden: yes
      content : """
                  <p>
                    If you want to install it now, click <strong>Install Compiler</strong> button.
                  </p>
                  <p>
                    <strong>Remember to enter your password when asked.</strong>
                  </p>
                """
      buttons:
        "Install Compiler":
          cssClass: "modal-clean-green"
          callback: =>
            modal.run "sudo npm install -g kdc; echo $?|kdevent;" # find a clean/better way to do it.

    modal.on "terminal.event", (data)=>
      if data is "0"
        new KDNotificationView title: "Installed successfully!"
        modal.destroy()
      else
        new KDNotificationView
          title   : "An error occured."
          content : "Something went wrong while installing Koding App Compiler. Please try again."

class DevToolsEditorPane extends CollaborativeEditorPane

  constructor:(options = {}, data)->

    options.cssClass = 'devtools-editor'
    super options, data

    @_mode   = "coffeescript"
    @storage = KD.singletons.localStorageController.storage "DevTools"

  loadLastOpenFile:->

    path = @storage.getAt "lastFileOn#{@_mode}"
    return  unless path

    lastOpenFile = FSHelper.createFileFromPath path
    lastOpenFile.fetchContents (err, content)=>
      if err
        KD.showError err, "Failed to load last open file: #{path}"
      else
        # Override the path to keep VM Info
        lastOpenFile.path = path

        @openFile lastOpenFile, content

  createEditor: (callback)->

    {cdnRoot} = CollaborativeEditorPane

    KodingAppsController.appendScriptElement 'script',
      url        : "#{cdnRoot}/addon/selection/active-line.js"
      identifier : "codemirror-activeline-addon"
      callback   : =>

        @codeMirrorEditor = CodeMirror @container.getDomElement()[0],
          lineNumbers     : yes
          lineWrapping    : yes
          styleActiveLine : yes
          scrollPastEnd   : yes
          cursorHeight    : 1
          tabSize         : 2
          mode            : @_mode
          extraKeys       :
            "Cmd-S"       : @bound "handleSave"
            "Ctrl-S"      : @bound "handleSave"
            "Tab"         : (cm)->
              spaces = Array(cm.getOption("indentUnit") + 1).join " "
              cm.replaceSelection spaces, "end", "+input"

        @setEditorMode @_mode ? "coffee"

        callback?()

        @emit 'ready'
        @loadLastOpenFile()

  openFile: (file, content)->
    @storage.setValue "lastFileOn#{@_mode}", file.path
    super

    path = (FSHelper.plainPath file.path).replace \
      "/home/#{KD.nick()}/Applications/", ""

    @header.title.updatePartial path

class DevToolsCssEditorPane extends DevToolsEditorPane
  constructor:-> super; @_mode = 'css'

class ErrorPaneWidget extends JView
  constructor:(options = {}, data)->
    options.cssClass = KD.utils.curry 'error-pane', options.cssClass
    super

  pistachio:->
    {error} = @getData()
    line    = if error.location then "at line: #{error.location.last_line+1}" else ""
    stack   = if error.stack? then """
      <div class='stack'>
        <h2>Full Stack</h2>
        <pre>#{error.stack}</pre>
      </div>
    """ else ""

    """
      {h1{#(error.name)}}
      <pre>#{error.message} #{line}</pre>
      #{stack}
    """

  click:-> @setClass 'in'