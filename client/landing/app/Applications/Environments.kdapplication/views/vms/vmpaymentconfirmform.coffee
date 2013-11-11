class VmPaymentConfirmForm extends PaymentConfirmForm

  viewAppended: ->
    data = @getData()

    @plan = new KDView

    @details = new KDView

    @addSubView @details, null, yes

    @addSubView @plan, null, yes

    super()

  setData: (data) ->
    if data.productData?.plan
      @plan.addSubView new VmProductView {}, data.productData.plan
      
    super data