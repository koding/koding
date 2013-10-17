class BuyVmConfirmView extends KDView
  constructor:->
    super
    console.log this

  setData: (data) ->
    @_data = data
    console.log data
    @updatePartial ""
    @addSubView new BillingMethodView {}, data.billingInfo