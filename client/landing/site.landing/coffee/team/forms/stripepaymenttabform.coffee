kd = require 'kd'
utils = require '../../core/utils'
LoginViewInlineForm = require '../../login/loginviewinlineform'
LoginInputView = require '../../login/logininputview'
Payment = require 'payment'

module.exports = class StripePaymentTabForm extends LoginViewInlineForm

  constructor: ->

    super

    team = utils.getTeamData()

    cleanPayment = ->
      if utils.getPayment()
        utils.cleanPayment()

    @number = new LoginInputView
      inputOptions   :
        name         : 'number'
        label        : 'Card Number'
        placeholder  : '•••• •••• •••• ••••'
        attributes   : { maxlength: 19 } # 16 + 3 spaces
        keydown      : cleanPayment
        validate     :
          rules      :
            required : yes
          messages   :
            required : 'Card Number is invalid'

    @cvc = new LoginInputView
      inputOptions   :
        name         : 'cvc'
        label        : 'CVC'
        placeholder  : '•••'
        keydown      : cleanPayment
        validate     :
          rules      :
            required : yes
          messages   :
            required : 'CVC is invalid'

    @exp_month = new LoginInputView
      inputOptions   :
        name         : 'exp_month'
        label        : 'Month'
        placeholder  : '••'
        keydown      : cleanPayment
        validate     :
          rules      :
            required : yes
          messages   :
            required : 'Expiration Month is invalid'

    @exp_year = new LoginInputView
      inputOptions   :
        name         : 'exp_year'
        label        : 'Year'
        placeholder  : '••••'
        keydown      : cleanPayment
        validate     :
          rules      :
            required : yes
          messages   :
            required : 'Expiration Year is invalid'

    @button = new kd.ButtonView
      title: 'NEXT'
      style: 'TeamsModal-button'
      type: 'submit'
      loader: yes

    @backLink = @getButtonLink 'BACK', '/Team/Domain'

    @on [ 'FormSubmitFailed', 'FormValidationFailed' ], @button.bound 'hideLoader'

    kd.singletons.router.on 'RouteInfoHandled', =>

      # cleanup first
      [@number, @cvc, @exp_month, @exp_year].forEach (view) ->
        view.input.setValue ''

      { card } = utils.getPayment()
      return @setValues card  if card


  setValues: (values) ->
    Object.keys(values).forEach (inputType) =>
      value = values[inputType]

      if inputType is 'last4'
        inputType = 'number'
        value = "•••• •••• •••• #{value}"

      { input } = this[inputType]

      console.log {inputType, input}

      return  unless input

      return  if input.getValue() is value

      input.setValue value


  viewAppended: ->

    super

    Payment.formatCardNumber @number.getElement()
    Payment.formatCardCVC @cvc.getElement()


  getButtonLink: (partial, href, callback) ->

    new kd.CustomHTMLView
      tagName  : 'span'
      cssClass : 'TeamsModal-button-link'
      partial  : if href then "<a href='#{href}'>#{partial}</a>" else partial
      click    : callback


  pistachio: ->

    """
    {{> @number}}
    <div class="form-group">
      {{> @cvc}}
      {{> @exp_month}}
      {{> @exp_year}}
    </div>
    {{> @button}}
    {{> @backLink}}
    """

