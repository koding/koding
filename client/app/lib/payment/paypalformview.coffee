kd                    = require 'kd'
globals               = require 'globals'
KDFormViewWithFields  = kd.FormViewWithFields


module.exports = class PaypalFormView extends KDFormViewWithFields


  getInitialState: -> kd.utils.dict()


  constructor: (options = {}, data) ->

    @state = kd.utils.extend @getInitialState(), options.state

    options.cssClass = kd.utils.curry 'paypal-form', options.cssClass
    options.fields = @getFields()

    super options, data

    @loadActionAttribute()


  submit: (event) ->


  loadActionAttribute: ->

    { planTitle, planInterval } = @state

    { paymentController } = kd.singletons

    paymentController.getPaypalToken planTitle, planInterval, (err, token) =>

      @state.token = token

      actionUrl = "#{globals.config.paypal.formUrl}?token=#{token}"
      @setAttribute 'action', actionUrl
      @setAttribute 'method', 'post'

      @emit 'PaypalTokenLoaded'


  getFields: ->

    planTitle:
      defaultValue: @state.planTitle
      type: 'hidden'
      cssClass: 'hidden'
    planInterval:
      defaultValue: @state.planInterval
      type: 'hidden'
      cssClass: 'hidden'
