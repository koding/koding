class GroupProductEditForm extends KDFormViewWithFields

  constructor: (options = {}, data = new KD.remote.api.JPaymentProduct) ->

    model = data  if data.planCode

    options.isRecurOptional ?= yes

    options.callback ?= =>
      @emit 'SaveRequested', model, @getProductData()

    options.buttons ?=
      Save        :
        cssClass  : "modal-clean-green"
        type      : "submit"
      cancel      :
        cssClass  : "modal-cancel"
        callback  : => @emit 'CancelRequested'

    options.fields ?= {}

    options.fields.title ?=
      label           : "Title"
      placeholder     : options.placeholders?.title
      defaultValue    : data.decoded 'title'
      required        : 'Title is required!'

    options.fields.description ?=
      label           : "Description"
      placeholder     : options.placeholders?.description or "(optional)"
      defaultValue    : data.decoded 'description'

    options.fields.subscriptionType ?=
      label           : "Subscription type"
      itemClass       : KDSelectBox
      defaultValue    : data.subscriptionType ? "mo"
      selectOptions   : @getSubscriptionTypes options
      callback        : @bound 'subscriptionTypeChanged'

    options.fields.feeAmount ?=
      label           : "Amount"
      placeholder     : "0.00"
      defaultValue    :
        if data.feeAmount
        then (data.feeAmount / 100).toFixed 2
      change          : @bound 'feeChanged'
      nextElementFlat :

        perMonth      :
          itemClass   : KDCustomHTMLView
          partial     : "/ #{ data.subscriptionType ? 'mo' }"
          cssClass    : 'fr'

    if options.showPriceIsVolatile
      options.fields.priceIsVolatile ?=
        label         : "Price is volatile"
        itemClass     : KDOnOffSwitch
        defaultValue  : data.priceIsVolatile
        callback      : @bound 'priceVolatilityChanged'

    if options.showOverage
      options.fields.overageEnabled ?=
        label         : "Overage enabled"
        itemClass     : KDOnOffSwitch
        defaultValue  : data.overageEnabled

    if options.showSoldAlone
      options.fields.soldAlone ?=
        label         : "Sold alone"
        itemClass     : KDOnOffSwitch
        defaultValue  : data.soldAlone

    if options.canApplyCoupon
      options.fields.discountCode ?=
        label         : "Discount code"
        defaultValue  : data.couponCodes?.discount

      options.fields.vmCode ?=
        label         : "VM code"
        defaultValue  : data.couponCodes?.vm

    options.fields.tags ?=
      label         : "Tags"
      itemClass     : KDDelimitedInputView
      defaultValue  : data.tags

    super options, data

    @fields.feeAmount.hide()  if data.priceIsVolatile

  getPlanInfo: (subscriptionType = @inputs.subscriptionType?.getValue()) ->
    feeUnit     : 'months'
    feeInterval : switch subscriptionType
      when 'mo'     then 1
      when '3 mo'   then 3
      when '6 mo'   then 6
      when 'yr'     then 12
      when '2 yr'   then 12 * 2 # 24 mo
      when '5 yr'   then 12 * 5 # 60 mo
    subscriptionType: subscriptionType

  getProductData: ->
    do (i = @inputs) =>
      title           = i.title.getValue()
      description     = i.description.getValue()
      overageEnabled  = i.overageEnabled?.getValue()
      soldAlone       = i.soldAlone?.getValue()
      priceIsVolatile = i.priceIsVolatile?.getValue()
      tags            = i.tags.getValue()
      couponCodes     =
        discount      : i.discountCode?.getValue()
        vm            : i.vmCode?.getValue()
      feeAmount       =
        unless priceIsVolatile
        then i.feeAmount.getValue() * 100

      { subscriptionType, feeUnit, feeInterval } = @getPlanInfo()

      {
        title
        description
        feeAmount
        feeUnit
        feeInterval
        subscriptionType
        overageEnabled
        soldAlone
        priceIsVolatile
        couponCodes
        tags
      }

  getSubscriptionTypes: (options) ->

    selectOptions = [
      { title: "Recurs every month",     value: 'mo' }
      { title: "Recurs every 3 months",  value: '3 mo' }
      { title: "Recurs every 6 months",  value: '6 mo' }
      { title: "Recurs every year",      value: 'yr' }
      { title: "Recurs every 2 years",   value: '2 yr' }
      { title: "Recurs every 5 years",   value: '5 yr' }
    ]

    if options.isRecurOptional
      selectOptions.push { title: "Single payment", value: 'single' }

    return selectOptions

  subscriptionTypeChanged: ->
    { subscriptionType, perMonth } = @inputs
    newType = subscriptionType.getValue()
    if subscriptionType is 'single'
      perMonth.hide()
    else
      perMonth.show()
      perMonth.updatePartial "/ #{ newType }"

  feeChanged: ->
    { feeAmount } = @inputs
    num = parseFloat feeAmount.getValue()
    feeAmount.setValue if isNaN num then '' else num.toFixed 2

  priceVolatilityChanged: ->
    enabled = @inputs.priceIsVolatile.getValue()
    do @fields.feeAmount[if enabled then 'hide' else 'show']
