class PaymentForm extends JView

  constructor: (options = {}, data) ->

    options.cssClass = @utils.curry 'payment-form-wrapper', options.cssClass

    super options, data

    @initViews()
    @initEvents()


  initViews: ->

    { MONTH, YEAR } = PaymentWorkflow.interval

    @intervalToggle = new KDButtonGroupView
      cssClass     : 'interval-toggle'
      buttons      :
        MONTH      :
          title    : MONTH
          callback : => @emit 'IntervalToggleChanged', { interval : MONTH }
        YEAR       :
          title    : YEAR
          callback : => @emit 'IntervalToggleChanged', { interval : YEAR }

    { subscription, name, price, interval } = @getData()

    @subscription = new KDCustomHTMLView
      cssClass: 'plan-name'
      partial : "#{subscription.capitalize()} Plan"


    @price = new KDCustomHTMLView
      cssClass: 'plan-price'
      partial : "#{price / 100}"

    fields = {
      cardNumber          :
        label             : 'Card Number'
        blur              : ->
          @oldValue = @getValue()
          @setValue @oldValue.replace /\s|-/g, ''
        focus             : ->
          @setValue @oldValue  if @oldValue
      cardCVC             :
        label             : 'CVC'
      cardName            :
        label             : 'Name on Card'
        cssClass          : 'card-name'
      cardMonth           :
        label             : 'Exp. Date'
        maxLength         : 2
      cardYear            :
        label             : '&nbsp'
        maxLength         : 2
    }

    { cssClass } = @getOptions()

    @form = new KDFormViewWithFields
      cssClass              : KD.utils.curry 'payment-method-entry-form clearfix', cssClass
      name                  : 'method'
      fields                : fields
      callback              : (formData) => @emit "PaymentSubmitted", formData

    @submitButton = new KDButtonView
      style     : 'solid medium green'
      title     : 'UPGRADE YOUR PLAN'
      loader    : yes
      cssClass  : 'submit-btn'

    @securityNote = new KDCustomHTMLView
      cssClass  : 'security-note'
      partial   : "
        <span>Secure credit card payments</span>
        Koding.com uses 128 Bit SSL Encrypted Transactions
      "


  initEvents: ->

    @on 'IntervalToggleChanged', (subscription) => @handleToggleChanged subscription


  handleToggleChanged: (subscription) ->

    data = @getData()
    data.subscription = subscription


  pistachio: ->
    """
    {{> @intervalToggle}}
    <div class='summary clearfix'>
      {{> @subscription}}{{> @price}}
    </div>
    {{> @form}}
    {{> @submitButton}}
    {{> @securityNote}}
    """

