class AddNewCustomViewForm extends JView

  constructor: (options = {}, data) ->

    options.cssClass = "add-new-view"

    super options, data

    @input        = new KDInputView
      cssClass    : "page-name"
      type        : "input"
      defaultValue: @getData()?.name or ""

    editorValue   = if @getData()?.partial then Encoder.htmlDecode @getData().partial else ""
    @editor       = new EditorPane
      cssClass    : "editor-container"
      content     : editorValue
      size        :
        width     : 876
        height    : 400

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

    @editor.on "viewAppended", =>
      @editor.ace.on "ace.ready", =>
        @editor.ace.setSyntax "html"

  addNew: ->
    isUpdate          = @getData()
    data              =
      name            : @input.getValue()
      partial         : @editor.getValue()
      partialType     : @getOption "viewType"
      isActive        : no
      viewInstance    : ""
      isPreview       : no
      previewInstance : no

    # TODO: fatihacet - DRY callbacks
    if isUpdate
      @getData().update data, (err, customPartial) =>
        return warn err  if err
        @getDelegate().emit "NewViewAdded", customPartial
    else
      KD.remote.api.JCustomPartials.create data, (err, customPartial) =>
        return warn err  if err
        @getDelegate().emit "NewViewAdded", customPartial

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
