kd = require 'kd'
utils = require '../../core/utils'
LoginViewInlineForm = require '../../login/loginviewinlineform'
LoginInputView = require '../../login/logininputview'
Payment = require 'payment'
Cookies = require 'js-cookie'
CardInput = require './cardinput'


module.exports = class StripePaymentTabForm extends LoginViewInlineForm

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'cc-form', options.cssClass

    super options, data

    team = utils.getTeamData()

    @number = new CardInput { label: 'Card Number' }
    @cvc = new CardInput { label: 'CVC' }
    @expiration = new CardInput { label: 'Expiration' }

    @whyTip = new kd.CustomHTMLView
      cssClass : 'TeamsModal-ccwarning'
      partial : '''<strong>We ask your credit card purely for verification purposes.</strong>
                   Your credit card will be charged 50 cents for authentication, and it will be
                   automatically refunded within 1-7 days. You will receive an email to confirm
                   before your trial ends.
                   '''

    @button = new kd.ButtonView
      title: 'NEXT'
      style: 'TeamsModal-button'
      type: 'submit'
      loader: yes

    @backLink = @getButtonLink 'BACK', '/Team/Domain'
    @resetFormLink = @getResetFormLink()

    @on [ 'FormSubmitFailed', 'FormValidationFailed' ], @button.bound 'hideLoader'

    kd.singletons.router.on 'RouteInfoHandled', =>

      return  unless card = utils.getPayment()?.card

      @resetFormLink.show()
      @forEachInputView (input) -> input.hide()


  forEachInputView: (callback) ->
    [@number, @cvc, @expiration].forEach callback


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

    utils.loadStripe().then (client) =>

      @stripeClient = client

      style =
        base:
          fontSize: '18px'
          fontFamily: "'Proxima Nova','proxima-nova',Helvetica,Arial"
          color: '#4a4a4a'
          '::placeholder':
            color: '#ccc'
            fontWeight: 300

      elements = client.elements()
      @cardNumber = elements.create('cardNumber', { style, classes: base: 'kdinput text' })
      cardExpiry = elements.create('cardExpiry', { style, classes: base: 'kdinput text' })
      cardCvc = elements.create('cardCvc', { placeholder: '•••', style, classes: base: 'kdinput text' })

      @cardNumber.on 'ready', => @emit 'ready'

      @number.mountTo @cardNumber
      @cvc.mountTo cardCvc
      @expiration.mountTo cardExpiry

      [@cardNumber, cardExpiry, cardCvc].forEach (element) =>
        element.on 'change', =>
          @forEachInputView (input) -> input.resetDecoration()


  focusFirstElement: ->
    @ready => @cardNumber.focus()


  submit: (event) ->
    kd.utils.stopDOMEvent event

    utils.authorizeCreditCard(@stripeClient, @cardNumber)
      .then (token) => @options.onSubmitSuccess token
      .catch (err) => @options.onSubmitError err



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
      {{> @expiration}}
    </div>
    {{> @whyTip }}
    {{> @button}}
    {{> @backLink}}
    """
