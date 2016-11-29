kd = require 'kd'
utils = require '../../core/utils'
LoginViewInlineForm = require '../../login/loginviewinlineform'
LoginInputView = require '../../login/logininputview'
Payment = require 'payment'
Cookies = require 'js-cookie'

module.exports = class StripePaymentTabForm extends LoginViewInlineForm

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'cc-form', options.cssClass

    super options, data

    team = utils.getTeamData()

    @number = new LoginInputView
      inputOptions   :
        name         : 'number'
        label        : 'Card Number'
        placeholder  : '•••• •••• •••• ••••'
        attributes   :
          maxlength  : 19 # 16 + 3 spaces
          autocomplete : 'cc-number'
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
        attributes   :
          maxlength  : 4
          autocomplete : 'cc-csc'
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
        attributes   :
          maxlength  : 2
          autocomplete : 'cc-exp-month'
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
        attributes   :
          maxlength  : 4
          autocomplete : 'cc-exp-year'
        validate     :
          rules      :
            required : yes
          messages   :
            required : 'Expiration Year is invalid'

    @whyTip = new kd.CustomHTMLView
      cssClass : 'TeamsModal-ccwarning'
      partial : '''<strong>We ask your credit card purely for verification purposes.</strong>
                   Your credit card will not be charged unless you buy a
                   plan after your trial period ends.
                   Read more on our <a href="www.koding.com/pricing" target="_blank">Pricing</a> page.'''

    @button = new kd.ButtonView
      title: 'NEXT'
      style: 'TeamsModal-button'
      type: 'submit'
      loader: yes

    @backLink = @getButtonLink 'BACK', '/Team/Domain'
    @resetFormLink = @getResetFormLink()

    @on [ 'FormSubmitFailed', 'FormValidationFailed' ], @button.bound 'hideLoader'

    kd.singletons.router.on 'RouteInfoHandled', =>

      @resetValues()

      return  unless card = utils.getPayment()?.card

      @resetFormLink.show()
      @setValues card
      @makeDisabled()


  forEachInputView: (callback) ->
    [@number, @cvc, @exp_month, @exp_year].forEach callback


  resetValues: ->
    @forEachInputView (view) -> view.input.setValue ''


  makeDisabled: ->
    @forEachInputView (view) -> view.input.makeDisabled()

  setValues: (values) ->

    values['cvc'] ?= '•••'

    Object.keys(values).forEach (inputType) =>
      value = values[inputType]

      if inputType is 'last4'
        inputType = 'number'
        value = "•••• •••• •••• #{value}"

      { input } = this[inputType]

      return  unless input

      return  if input.getValue() is value

      input.setValue value


  viewAppended: ->

    super

    Payment.formatCardNumber @number.getElement()
    Payment.formatCardCVC @cvc.getElement()


  getResetFormLink: ->

    new kd.CustomHTMLView
      tagName  : 'a'
      cssClass : 'hidden'
      partial  : 'Use different card'
      click    : ->
        Cookies.remove 'clientId'
        location.reload()


  getButtonLink: (partial, href, callback) ->

    new kd.CustomHTMLView
      tagName  : 'span'
      cssClass : 'TeamsModal-button-link'
      partial  : if href then "<a href='#{href}'>#{partial}</a>" else partial
      click    : callback


  pistachio: ->

    """
    <div class='cc-form-resetLink'>
      {{> @resetFormLink}}
    </div>
    {{> @number}}
    <div class="form-group">
      {{> @cvc}}
      {{> @exp_month}}
      {{> @exp_year}}
    </div>
    {{> @whyTip }}
    {{> @button}}
    {{> @backLink}}
    """

