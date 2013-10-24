class GroupProductCreateForm extends KDFormView

  constructor: (options = {}, data) ->

    super options, data

    @titleInput = new KDInputView
      cssClass   : "product-title"
      placeholder: "Product name"

    @descriptionInput = new KDInputView
      cssClass   : "product-description"
      placeholder: "Product description"

    @subscriptionTypeInput = new KDSelectBox
      defaultValue  : "recurring"
      selectOptions : [
        { title : "Recurring payment", value : 'recurring' }
        { title : "Single payment"   , value : 'single'    }
      ]
      callback: =>
        if @subscriptionTypeInput.getValue() is 'single'
        then @perMonth.hide()
        else @perMonth.show()

    @amountInput = new KDInputView
      cssClass    : "product-price"
      placeholder : "0.00"
      change      : ->
        num = parseFloat @getValue()

        @setValue if isNaN num then '' else num.toFixed(2)

    @perMonth = new KDView
      tagName: 'span'
      partial: '/ mo'

    @submitButton = new KDButtonView
      cssClass   : "product-button"
      title      : "Create product"
      callback   : =>
        @emit 'ProductCreateRequested', @getProductData()

  viewAppended: JView::viewAppended

  pistachio: ->
    """
    {{> @titleInput}}
    {{> @descriptionInput}}
    {{> @subscriptionTypeInput}}
    {{> @amountInput}}
    {{> @perMonth}}
    {{> @submitButton}}
    """

  getProductData: ->
    price             : @amountInput.getValue()
    title             : @titleInput.getValue()
    description       : @descriptionInput.getValue()
    subscriptionType  : @subscriptionTypeInput.getValue()
