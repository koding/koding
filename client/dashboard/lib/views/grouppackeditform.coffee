kd = require 'kd'
KDDelimitedInputView = kd.DelimitedInputView
KDFormViewWithFields = kd.FormViewWithFields
remote = require('app/remote').getInstance()
module.exports = class GroupPackEditForm extends KDFormViewWithFields
  constructor: (options = {}, data = new remote.api.JPaymentPack) ->
    options.fields ?= {}

    model = data  if data.planCode

    options.callback ?= =>
      @emit 'SaveRequested', model, @getProductData()

    options.buttons ?=
      Save        :
        cssClass  : "solid green medium"
        type      : "submit"
      cancel      :
        cssClass  : "solid light-gray medium"
        callback  : => @emit 'CancelRequested'

    options.fields ?= {}

    options.fields.title ?=
      label           : "Title"
      placeholder     : options.placeholders?.title
      defaultValue    : data.decoded 'title'
      required        : 'Title is required!'

    options.fields.description ?=
      label           : "Description"
      placeholder     : options.placeholders?.description or "(optional)"
      defaultValue    : data.decoded 'description'

    options.fields.tags ?=
      label         : "Tags"
      itemClass     : KDDelimitedInputView
      defaultValue  : data.tags

    super options, data

  getProductData: @::getFormData


