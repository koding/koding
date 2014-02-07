class DevToolsMainView extends KDView

  COFFEE = "//cdnjs.cloudflare.com/ajax/libs/coffee-script/1.6.3/coffee-script.min.js"

  viewAppended:->

    @addSubView @workspace      = new CollaborativeWorkspace
      name                      : "Kodepad"
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
            title               : "Run"
            cssClass            : "solid green"
            callback            : => @previewApp yes; @previewCss yes
          }
          {
            title               : 'Run as I type'
            cssClass            : "solid live"
            callback            : =>
              button = @workspace.panels.first.headerButtons['Run as I type']
              button.unsetClass 'live green'
              button.setClass if @liveMode then 'live' else 'green'
              @liveMode = button.hasClass 'green'
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
                log file, JSEditor.header

                switch FSItem.getFileExtension file.path
                  when 'css', 'styl'
                  then editor = CSSEditor
                  else editor = JSEditor

                path = (FSHelper.plainPath file.path).replace \
                  "/home/#{KD.nick()}/Applications/", ""

                editor.openFile file, content
                editor.header.title.updatePartial path

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


class DevToolsEditorPane extends CollaborativeEditorPane

  constructor:(options = {}, data)->
    options.cssClass = 'devtools-editor'
    super options, data

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
          mode            : @_mode ? "coffeescript"
          extraKeys       :
            "Cmd-S"       : @bound "handleSave"
            "Ctrl-S"      : @bound "handleSave"
            "Tab"         : (cm)->
              spaces = Array(cm.getOption("indentUnit") + 1).join " "
              cm.replaceSelection spaces, "end", "+input"

        @setEditorMode @_mode ? "coffee"

        callback?()

        @emit 'ready'

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