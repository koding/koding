kd             = require 'kd'
JView          = require 'app/jview'
KodingSwitch   = require 'app/commonviews/kodingswitch'


module.exports = class HomeUtilitiesCustomerFeedback extends kd.CustomHTMLView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    super options, data

    @switch  = new KodingSwitch
      cssClass: 'small'
      callback: (state) =>
        if state
          @emit 'ChatlioActivated'
        else
          @emit 'ChatlioDeactivated'



  pistachio: ->
    """
    <p>
    <strong>Customer Feedback</strong>
    Enable Chatlio.com for real-time customer feedback
    {{> @switch}}
    </p>
    """
