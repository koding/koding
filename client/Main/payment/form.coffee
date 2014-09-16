class PaymentForm extends JView

  constructor: (options = {}, data) ->

    options.cssClass = @utils.curry 'payment-form-wrapper', options.cssClass

    super options, data

    @initViews()
    @initEvents()


  initViews: ->

    { MONTH, YEAR } = PaymentWorkflow.interval

    @intervalToggle = new KDToggleButton
      cssClass     : 'interval-toggle'
      defaultState : MONTH
      states       : [
        title      : MONTH
        callback   : => @emit 'IntervalToggleChanged', { interval : MONTH }
      ,
        title      : YEAR
        callback   : => @emit 'IntervalToggleChanged', { interval : YEAR }
      ]

    { subscription, name, price, interval } = @getData()

    @subscription = new KDCustomHTMLView
      partial : "#{subscription.capitalize()} Plan"


    @price = new KDCustomHTMLView
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
        label             : ''
        maxLength         : 2
    }

    { cssClass } = @getOptions()

    @form = new KDFormViewWithFields
      cssClass              : KD.utils.curry 'payment-method-entry-form clearfix', cssClass
      name                  : 'method'
      fields                : fields
      callback              : (formData) => @emit "PaymentSubmitted", formData
      buttons               :
        Save                :
          title             : 'ADD CARD'
          style             : 'solid medium green'
          type              : 'submit'
          loader            : yes
        BACK                :
          style             : 'medium solid light-gray to-left'
          callback          : => # close modal


  initEvents: ->

    @on 'IntervalToggleChanged', (subscription) => @handleToggleChanged subscription


  handleToggleChanged: (subscription) ->

    data = @getData()
    data.subscription = subscription


  pistachio: ->
    """
    <div>
      {{> @intervalToggle}}
    </div>
    <div>
      {{> @subscription}}{{> @price}}
    </div>
    {{> @form}}
    """

