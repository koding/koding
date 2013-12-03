class PaymentWidget extends KDView
  constructor: (options, data) ->
    super options, data

    @planCode = options.planCode

    @loader = new KDLoaderView
      size:
        width: 20

    @buttonSubscribe = new KDButtonView
      title    : "Subscribe"
      cssClass : "hidden"
      callback : =>
        @confirmSubscription => @subscribe (err, sub) => @updateButtons()

    @buttonBilling = new KDButtonView
      title    : "Billing Info"
      cssClass : "hidden"
      callback : => @askPaymentInfo (status) => @updateButtons()

    @widgetContent = options.content
    @widgetContent.setClass "hidden"

    @buttonSubscribe.setClass options.contentCssClass
    @buttonBilling.setClass options.contentCssClass

    @updateButtons()

  updateButtons:->
    @buttonBilling.hide()
    @buttonSubscribe.hide()
    @widgetContent.hide()
    @loader.show()
    @checkBilling (needBilling) =>
      if needBilling
        @loader.hide()
        @buttonBilling.show()
      else
        @checkSubscription (status) =>
          @loader.hide()
          if status
            @emit "subscribed"
            @widgetContent.show()
          else
            @buttonSubscribe.show()

  checkBilling:(callback)->
    paymentController = KD.getSingleton('paymentController')
    group             = KD.getSingleton("groupsController").getCurrentGroup()

    paymentController.fetchPaymentInfo 'user', group, (err, account) =>
      callback err or not account or not account.cardNumber

  checkSubscription:(callback)-> throw Error 'reimplement this'
  
  pistachio:->
    """
    {{> @loader}}
    {{> @buttonBilling}}
    {{> @buttonSubscribe}}
    {{> @widgetContent}}
    """

  viewAppended: ->
    @setTemplate @pistachio()
    @template.update()
    @loader.show()

  fetchPlan: (callback) ->
    { JPaymentPlan } = KD.remote.api
    JPaymentPlan.fetchPlanByCode @planCode, callback

  subscribe: (callback) ->
    @fetchPlan (err, plan) ->
      if not err and plan
        plan.subscribe {}, callback

  askPaymentInfo: (callback) ->
    paymentController = KD.getSingleton('paymentController')
    paymentController.setPaymentInfo 'user', callback

  confirmSubscription: (callback) ->
    @fetchPlan (err, plan) =>

      title     = plan.title
      price     = plan.feeAmount / 100
      recurring = plan.feeInterval is 1

      if recurring
        description = "(Monthly payment)"
      else
        description = "(Single payment)"

      content = """<div>Are you sure you want to buy to this product?</div>
                  <br/>
                  <div>#{title} - #{@utils.formatMoney price} #{description}</div>
                  <br/>
                """

      modal           = new KDModalView
        title         : "Confirm Subcription"
        content       : "<div class='modalformline'>#{content}</div>"
        overlay       : yes
        buttons       :
          No          :
            title     : "No"
            cssClass  : "modal-clean-gray"
            callback  : =>
              modal.destroy()
          Yes         :
            title     : "Yes, subscribe"
            cssClass  : "modal-clean-green"
            callback  : =>
              modal.destroy()
              callback()
