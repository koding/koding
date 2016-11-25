kd = require 'kd'
utils = require '../../core/utils'
LoginViewInlineForm = require '../../login/loginviewinlineform'
LoginInputView = require '../../login/logininputview'
Payment = require 'payment'

module.exports = class StripePaymentTabForm extends LoginViewInlineForm

  constructor: ->

    super

    team = utils.getTeamData()

    @number = new LoginInputView
      inputOptions   :
        name         : 'number'
        label        : 'Card Number'
        placeholder  : '•••• •••• •••• ••••'
        attributes   : { maxlength: 19 } # 16 + 3 spaces
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

    @backLink = @getButtonLink 'BACK', '/Team/Username'

    @on [ 'FormSubmitFailed', 'FormValidationFailed' ], @button.bound 'hideLoader'

    kd.singletons.router.on 'RouteInfoHandled', =>
      [@number, @cvc, @exp_month, @exp_year].forEach (view) ->
        view.input.setValue ''


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

