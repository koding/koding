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
          cssClass              : 'basesplit-gokmen'
          views                 : [
            {
              type              : "finder"
              name              : "finder"
              editor            : "JSEditor"
              handleFileOpen    : (file, content) =>
                # log file, content
                panes = @workspace.activePanel.panesByName
                switch FSItem.getFileExtension file.path
                  when 'css', 'styl'
                  then panes.CSSEditor.openFile file, content
                  else panes.JSEditor.openFile file, content
            }
            {
              type              : "split"
              options           :
                direction       : "vertical"
                sizes           : [ "50%", "50%" ]
                splitName       : "InnerSplit"
              views             : [
                {
                  type          : "split"
                  options       :
                    direction   : "horizontal"
                    sizes       : [ "50%", "50%" ]
                    splitName   : "EditorSplit"
                  views         : [
                    {
                      type      : "custom"
                      name      : "JSEditor"
                      paneClass : DevToolsEditorPane
                      # title   : "JavaScript"
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

      JSEditor.codeMirrorEditor.on "change", \
        _.debounce (@lazyBound 'previewApp', no), 500

      CSSEditor.codeMirrorEditor.on "change", \
        _.debounce (@lazyBound 'previewCss', no), 500

  previewApp:(force = no)->

    return  if not force and not @liveMode
    return  if @_inprogress
    @_inprogress = yes

    time 'Compile took:'

    {JSEditor, PreviewPane} = @workspace.activePanel.panesByName

    @compiler (coffee)=>

      code = JSEditor.getValue()

      PreviewPane.container.destroySubViews()
      window.appView = new KDView

      try

        coffee.compile code
        coffee.run code

        PreviewPane.container.addSubView window.appView

      catch error

        try window.appView.destroy?()
        warn "Failed to run:", error

        PreviewPane.container.addSubView new ErrorPaneWidget {}, {code, error}

      finally

        delete window.appView
        @_inprogress = no

        timeEnd 'Compile took:'

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

  createEditor: ->

    @codeMirrorEditor = CodeMirror @container.getDomElement()[0],
      lineNumbers     : yes
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

class DevToolsCssEditorPane extends DevToolsEditorPane
  constructor:-> super; @_mode = 'css'

class ErrorPaneWidget extends JView
  constructor:(options = {}, data)->
    options.cssClass = KD.utils.curry 'error-pane', options.cssClass
    super

  pistachio:->
    {error} = @getData()
    line = if error.location then "at line: #{error.location.last_line+1}" else ""
    """
      {h1{#(error.name)}}
      <pre>#{error.message} #{line}</pre>
      <div class='stack'>
        <h2>Full Stack</h2>
        {pre{#(error.stack)}}
      </div>
    """

  click:-> @setClass 'in'