kd = require 'kd'
KDButtonView = kd.ButtonView
KDCustomHTMLView = kd.CustomHTMLView
KDInputView = kd.InputView
remote = require('app/remote').getInstance()
JView = require 'app/jview'
Encoder = require 'htmlencode'
AceView = require 'ace/aceview'


module.exports = class AddNewCustomViewForm extends JView

  constructor: (options = {}, data) ->

    options.cssClass   = "add-new-view"
    options.hasEditor ?= yes

    super options, data

    @input        = new KDInputView
      cssClass    : "big-input"
      type        : "text"
      defaultValue: @getData()?.name or ""

    @cancelButton = new KDButtonView
      title       : "CANCEL"
      cssClass    : "solid red medium"
      callback    : =>
        @destroy()
        @getDelegate().emit "AddingNewViewCancelled"

    @saveButton   = new KDButtonView
      title       : "SAVE"
      cssClass    : "solid green medium"
      callback    : @bound "addNew"

    if @getOption "hasEditor" then @createEditor() else @editor = new KDCustomHTMLView


  createEditor: ->

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

    files.splice 0, 1  unless @getOptions().viewType is "HOME"

    @editor       = new AceView
      cssClass    : "editor-container"
      size        :
        width     : 876
        height    : 400
      files       : files


  addNew: ->

    jCustomPartial    = @getData()
    {hasEditor}       = @getOptions()
    emptyValues       = { html: "", css: "", js: "" }
    data              =
      name            : @input.getValue()
      partial         : if hasEditor then @encode @editor.getValues() else emptyValues
      partialType     : @getOption "viewType"
      isActive        : jCustomPartial?.isActive        ? no
      viewInstance    : jCustomPartial?.viewInstance    or ""
      isPreview       : jCustomPartial?.isPreview       ? no
      previewInstance : jCustomPartial?.previewInstance ? no

    if jCustomPartial
      jCustomPartial.update data, (err, customPartial) =>
        return kd.warn err  if err
        @getDelegate().emit "NewViewAdded", customPartial
    else
      remote.api.JCustomPartials.create data, (err, customPartial) =>
        return kd.warn err  if err
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


