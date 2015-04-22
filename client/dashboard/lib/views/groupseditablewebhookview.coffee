kd = require 'kd'
KDButtonView = kd.ButtonView
KDInputView = kd.InputView
KDLabelView = kd.LabelView
JView = require 'app/jview'


module.exports = class GroupsEditableWebhookView extends JView

  constructor:->
    super

    @setClass 'editable-webhook'

    @webhookEndpointLabel = new KDLabelView title: "Webhook endpoint"

    @webhookEndpoint = new KDInputView
      label       : @webhookEndpointLabel
      name        : "title"
      placeholder : "https://example.com/verify"

    @saveButton = new KDButtonView
      title     : "Save"
      style     : "cupid-green"
      callback  : =>
        @emit 'WebhookChanged', webhookEndpoint: @webhookEndpoint.getValue()

  setFocus:->
    @webhookEndpoint.focus()
    return this

  setValue:(webhookEndpoint)->
    @webhookEndpoint.setValue webhookEndpoint

  pistachio:->
    """
    {{> @webhookEndpointLabel}}
    {{> @webhookEndpoint}}
    {{> @saveButton}}
    """


