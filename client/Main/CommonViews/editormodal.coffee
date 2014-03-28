class EditorModal extends KDModalView

  constructor: (options = {}, data) ->

    options.cssClass      = KD.utils.curry "editor-modal", options.cssClass
    options.domId         = "editor-modal"
    options.width         = 800 # currently 800 for styling
    options.height        = 400 # currently 400 for styling
    options.overlay      ?= yes
    options.overlayClick ?= no

    super options, data

    @setClass "loading"

    @addSubView @loader = new KDLoaderView
      showLoader  : yes
      size        :
        width     : 36

    appManager    = KD.getSingleton "appManager"
    editorOptions = options.editor or {}

    appManager.require "Teamwork", =>
      @editor        = new EditorPane
        cssClass     : "hidden"
        title        : editorOptions.title   or ""
        content      : Encoder.htmlDecode editorOptions.content or ""
        size         :
          width      : 800
          height     : 400
        buttons      : [
          {
            title    : "Save"
            cssClass : "solid compact green"
            callback : @bound "save"
          }
          {
            title    : "Close"
            cssClass : "solid compact gray"
            callback : => @destroy()
          }
        ]

      @addSubView @editor

      @editor.ace.once "ace.ready", =>
        @editor.unsetClass "hidden"
        @unsetClass "loading"
        @loader.destroy()
        @editor.ace.addKeyCombo "save", "Ctrl-S", @bound "save"

    {saveMessage, saveFailedMessage, closeOnSave} = @getOptions().editor

    if saveMessage
      @on "Saved", =>
        @showNotification saveMessage, "success"
        if closeOnSave
          KD.utils.wait 800, => @destroy()

    if saveFailedMessage
      @on "SaveFailed", => @showNotification saveFailedMessage, "error"

  save: ->
    editorOptions = @getOptions().editor or {}
    callback      = editorOptions.saveCallback or noop

    callback @editor.getValue(), this

  showNotification: (title, cssClass) ->
    type      = "mini"
    duration  = 3000
    container = this

    new KDNotificationView { title, cssClass, container, duration, type }
