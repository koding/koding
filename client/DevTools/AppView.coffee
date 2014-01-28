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
            callback            : ->
              KD.singletons.kodingAppsController.makeNewApp()
          }
          {
            title               : "Run"
            callback            : @bound 'previewApp'
          }
          {
            title               : "Hide Filetree"
            itemClass           : KDToggleButton
            states              : [
              {
                title           : 'Hide Filetree'
                callback        : (cb)=>
                  @workspace.activePanel.layoutContainer
                    .splitViews.BaseSplit.resizePanel 0, 0, cb
              }
              {
                title           : 'Show Filetree'
                callback        : (cb)=>
                  @workspace.activePanel.layoutContainer
                    .splitViews.BaseSplit.resizePanel "258px", 0, cb
              }
            ]
          }
        ]
        layout                  :
          direction             : "vertical"
          sizes                 : [ "258px", null ]
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
                      type      : "editor"
                      name      : "CSSEditor"
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
        _.debounce (@bound 'previewApp'), 500

      CSSEditor.codeMirrorEditor.on "change", \
        _.debounce (@bound 'previewCss'), 500

      CSSEditor.setEditorTheme 'vibrant-ink'

  previewApp:->

    time 'Compile took:'

    return  if @_inprogress
    @_inprogress = yes

    {JSEditor, PreviewPane} = @workspace.activePanel.panesByName

    @compiler (coffee)=>

      code = JSEditor.getValue()

      PreviewPane.container.destroySubViews()
      window.appView = new KDView

      try

        coffee.compile code
        coffee.run code

        PreviewPane.container.addSubView window.appView

      catch e

        try window.appView.destroy?()
        warn "Compile failed:", e

      finally

        delete window.appView
        @_inprogress = no

        timeEnd 'Compile took:'

  previewCss:->

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
      mode            : "coffeescript"
      extraKeys       :
        "Cmd-S"       : @bound "handleSave"
        "Ctrl-S"      : @bound "handleSave"
        "Tab"         : (cm)->
          spaces = Array(cm.getOption("indentUnit") + 1).join " "
          cm.replaceSelection spaces, "end", "+input"

    @setEditorMode  'coffee'
    @setEditorTheme 'vibrant-ink'