class CreditCardModal extends PaymentBaseModal

  constructor: (options = {}, data) ->

    options.title    = 'Update Payment Method'
    options.subtitle = ''

    super options, data


  initViews: ->

    @addSubView @form = new StripeFormView {
      callback : @lazyBound 'emit', 'CreditCardSubmitted'
    }

    @addSubView @successMessage = new KDCustomHTMLView
      cssClass : 'success-msg hidden'
      partial  : 'Your payment method has successfully been updated.'

    @addSubView @submitButton = new KDButtonView
      style    : 'solid medium green'
      title    : 'UPDATE'
      loader   : yes
      cssClass : 'submit-btn'
      callback : => @emit 'CreditCardSubmitted', @form.getData()

    @addSubView @securityNote = new KDCustomHTMLView
      cssClass  : 'security-note'
      partial   : "
        <span>Secure credit card payments</span>
        Koding.com uses 128 Bit SSL Encrypted Transactions
      "


  initEvents: ->

    @on 'CreditCardUpdateFailed', KD.showError
    @on 'CreditCardUpdateSucceeded', @bound 'handleSuccess'

    { cardNumber } = @form.inputs

    cardNumber.on 'CreditCardTypeIdentified', (tyoe) ->
      cardNumber.setClass type.toLowerCase()


  handleSuccess: ->

    @submitButton.hideLoader()

    @setTitle 'Update complete!'

    @showSuccess()

    @once 'KDModalViewDestroyed', =>
      @emit 'CreditCardWorkflowFinished'


  showSuccess: ->

    @form.hide()
    @successMessage.show()

    @submitButton.setTitle 'CONTINUE'
    @submitButton.setCallback =>
      @submitButton.hideLoader()
      @emit 'CreditCardWorkflowFinished'


