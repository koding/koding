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
            title               : "Run as I type"
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

      toggleAutoRun = =>
        @workspace.panels.first.headerButtons['Run as I type'].click()

      {JSEditor, CSSEditor} = panes = @workspace.activePanel.panesByName

      JSEditor.ready =>

        JSEditor.codeMirrorEditor.on "change", \
          _.debounce (@lazyBound 'previewApp', no), 500

        JSEditor.on "RunRequested", @lazyBound 'previewApp', yes
        JSEditor.on "AutoRunRequested", toggleAutoRun

        JSEditor.on "OpenedAFile", (file, content)->
          app = KodingAppsController.getAppInfoFromPath file.path
          button = @workspace.panels.first.headerButtons['Compile']
          if app then button.enable() else button.disable()

      CSSEditor.ready =>

        CSSEditor.codeMirrorEditor.on "change", \
          _.debounce (@lazyBound 'previewCss', no), 500

        CSSEditor.on "RunRequested", @lazyBound 'previewCss', yes
        CSSEditor.on "AutoRunRequested", toggleAutoRun


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

    KodingAppsController.compileAppOnServer JSEditor.getData()?.path, ->
      log "COMPILE", arguments

class DevToolsEditorPane extends CollaborativeEditorPane

  constructor:(options = {}, data)->

    options.cssClass = 'devtools-editor'
    super options, data

    @_mode or= "coffeescript"
    @_lastFileKey = "lastFileOn#{@_mode}"
    @storage = KD.singletons.localStorageController.storage "DevTools"

  loadFile:(path, callback = noop)->

    file = FSHelper.createFileFromPath path
    file.fetchContents (err, content)=>
      return callback err  if err

      file.path = path
      @openFile file, content

      KD.utils.defer -> callback null, {file, content}

  loadLastOpenFile:->

    path = @storage.getAt @_lastFileKey
    return  unless path

    @loadFile path, (err, data)=>
      if err
        KD.showError "Failed to load last open file: #{path}"
        @storage.unsetKey @_lastFileKey

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
            "Alt-R"       : => @emit "RunRequested"
            "Shift-Ctrl-R": => @emit "AutoRunRequested"
            "Tab"         : (cm)->
              spaces = Array(cm.getOption("indentUnit") + 1).join " "
              cm.replaceSelection spaces, "end", "+input"

        @setEditorMode @_mode ? "coffee"

        callback?()

        @emit 'ready'
        @loadLastOpenFile()

  openFile: (file, content)->
    @storage.setValue @_lastFileKey, file.path
    super

    path = (FSHelper.plainPath file.path).replace \
      "/home/#{KD.nick()}/Applications/", ""

    @header.title.updatePartial path

class DevToolsCssEditorPane extends DevToolsEditorPane
  constructor:-> @_mode = 'css'; super

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