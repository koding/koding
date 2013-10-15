class BillingMethodChoiceView extends JView

  constructor: (options = {}, data) ->
    options.cssClass = KD.utils.curry 'billing-method-choice', options.cssClass

    super options, data

  viewAppended: ->
    @methods = new KDView

    @createNewMethodButton = new KDButtonView
      title     : 'Use another billing method'
      callback  : => @emit 'BillingMethodSelected'

    super()

  addBillingMethod:(billingInfo) ->
    billingMethodView = new BillingMethodView {}, billingInfo

    @methods.addSubView billingMethodView

    billingMethodView.on 'BillingEditRequested', =>
      @emit 'BillingMethodSelected', billingInfo.accountCode

  pistachio:->
    """
    <div>Please link an existing billing method:</div>
    {div{> @methods }}
    {div{> @createNewMethodButton }}</div
    """
