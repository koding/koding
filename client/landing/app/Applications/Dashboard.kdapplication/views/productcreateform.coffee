class GroupProductCreateForm extends KDFormViewWithFields

  constructor: (options = {}, data) ->

    options.isRecurOptional ?= yes

    options.callback ?= =>
      @emit 'CreateRequested', @getProductData()

    options.buttons ?=
      Create      :
        cssClass  : "modal-clean-green"
        type      : "submit"
      cancel      :
        cssClass  : "modal-cancel"
        callback  : =>
          @emit 'CancelRequested'

    options.fields ?=

      title             :
        label           : "Title"
        placeholder     : options.placeholders?.title

      description       :
        label           : "Description"
        placeholder     : options.placeholders?.description or "(optional)"

    if options.isRecurOptional
      options.fields.subscriptionType =
        label           : "Subscription type"
        itemClass       : KDSelectBox
        defaultValue    : "recurring"
        selectOptions   : [
          { title : "Recurring payment", value : 'recurring' }
          { title : "Single payment"   , value : 'single'    }
        ]
        callback: =>
          if @inputs.subscriptionType.getValue() is 'single'
          then @inputs.perMonth.hide()
          else @inputs.perMonth.show()

    options.fields.amount ?=
      label           : "Amount"
      placeholder     : "0.00"
      change          : ->
        num = parseFloat @getValue()

        @setValue if isNaN num then '' else num.toFixed(2)
      nextElementFlat :

        perMonth      :
          itemClass   : KDCustomHTMLView
          partial     : "/ mo"
          cssClass    : 'fr'

    if options.showOverage
      options.fields.overageEnabled =
        label           : "Overage enabled"
        itemClass       : KDOnOffSwitch

    super options, data

  getProductData: ->
    { amount, title, description, subscriptionType } = @inputs
    amount            : amount.getValue()
    title             : title.getValue()
    description       : description.getValue()
    subscriptionType  : subscriptionType?.getValue()