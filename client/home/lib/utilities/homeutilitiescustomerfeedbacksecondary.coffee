kd             = require 'kd'
JView          = require 'app/jview'
KodingSwitch   = require 'app/commonviews/kodingswitch'


module.exports = class HomeUtilitiesCustomerFeedbackSecondary extends kd.CustomHTMLView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    super options, data

    @input = new kd.InputView
    @button = new kd.ButtonView


  pistachio: ->
    """
    <p>
    <cite>**Required: Chatlio.com requires slack integration**</cite>
    Enable Chatlio.com for real-time customer feedback
    <filedset>
    <label>Chatlio.io API Key</label>
    {{> @input}}
    {{> @button}}
    </p>
    """
