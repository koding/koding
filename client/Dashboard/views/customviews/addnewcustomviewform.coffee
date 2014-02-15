class AddNewCustomViewForm extends JView

  constructor: (options = {}, data) ->

    options.cssClass = "add-new-view"

    super options, data

    @input        = new KDInputView
      cssClass    : "page-name"
      type        : "input"
      defaultValue: @getData()?.name or ""

    editorValues  = @encode @getData()?.partial

    files         = [
        path      : "localfile://index.html"
        name      : "html"
        content   : editorValues.html
      ,
        path      : "localfile://main.css"
        name      : "css"
        content   : editorValues.css
      ,
        path      : "localfile://main.js"
        name      : "js"
        content   : editorValues.js
    ]

    files.splice 0, 1  if @getOptions().viewType is "WIDGET"

    @editor       = new EditorPane
      cssClass    : "editor-container"
      size        :
        width     : 876
        height    : 400
      files       : files

    @cancelButton = new KDButtonView
      title       : "CANCEL"
      cssClass    : "solid red"
      callback    : =>
        @destroy()
        @getDelegate().emit "AddingNewViewCancelled"

    @saveButton   = new KDButtonView
      title       : "SAVE"
      cssClass    : "solid green"
      callback    : @bound "addNew"

  addNew: ->
    isUpdate          = @getData()
    data              =
      name            : @input.getValue()
      partial         : @encode @editor.getValues()
      partialType     : @getOption "viewType"
      # TODO: Update sets this options to default
      isActive        : no
      viewInstance    : ""
      isPreview       : no
      previewInstance : no

    if isUpdate
      @getData().update data, (err, customPartial) =>
        return warn err  if err
        @getDelegate().emit "NewViewAdded", customPartial
    else
      KD.remote.api.JCustomPartials.create data, (err, customPartial) =>
        return warn err  if err
        @getDelegate().emit "NewViewAdded", customPartial

  encode: (data) ->
    encoded = {}
    return encoded unless data

    for key, value of data
      encoded[key] = Encoder.htmlDecode value

    return encoded

  pistachio: ->
    """
      <p>Name:</p>
      {{> @input}}
      <p>Code:</p>
      {{> @editor}}
      <div class="button-container">
        {{> @cancelButton}}
        {{> @saveButton}}
      </div>
    """
