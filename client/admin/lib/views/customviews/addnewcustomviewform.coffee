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

    options.cssClass   = 'add-new-view'

    super options, data

    @input        = new KDInputView
      cssClass    : 'big-input'
      type        : 'text'
      defaultValue: @getData()?.name or ''

    @cancelButton = new KDButtonView
      title       : 'CANCEL'
      cssClass    : 'solid red medium'
      callback    : =>
        @destroy()
        @getDelegate().emit 'AddingNewViewCancelled'

    @saveButton   = new KDButtonView
      title       : 'SAVE'
      cssClass    : 'solid green medium'
      callback    : @bound 'addNew'

    @editor = new KDCustomHTMLView


  addNew: ->

    jCustomPartial    = @getData()
    emptyValues       = { html: '', css: '', js: '' }
    data              =
      name            : @input.getValue()
      partial         : emptyValues
      partialType     : @getOption 'viewType'
      isActive        : jCustomPartial?.isActive        ? no
      viewInstance    : jCustomPartial?.viewInstance    or ''
      isPreview       : jCustomPartial?.isPreview       ? no
      previewInstance : jCustomPartial?.previewInstance ? no

    if jCustomPartial
      jCustomPartial.update data, (err, customPartial) =>
        return kd.warn err  if err
        @getDelegate().emit 'NewViewAdded', customPartial
    else
      remote.api.JCustomPartials.create data, (err, customPartial) =>
        return kd.warn err  if err
        @getDelegate().emit 'NewViewAdded', customPartial


  encode: (data) ->

    encoded = {}
    return encoded unless data

    for key, value of data
      encoded[key] = Encoder.htmlDecode value

    return encoded


  pistachio: ->

    '''
      <p>Name:</p>
      {{> @input}}
      <p>Code:</p>
      {{> @editor}}
      <div class="button-container">
        {{> @cancelButton}}
        {{> @saveButton}}
      </div>
    '''
