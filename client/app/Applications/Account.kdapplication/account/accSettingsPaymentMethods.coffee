deleteAccountPaymentMethod = (callback) ->
  modal = new KDModalView
    title        : "Warning"
    content      : "<div class='modalformline'>Are you sure you want to delete your billing information?</div>"
    height       : "auto"
    overlay      : yes
    buttons      :
      Yes        :
        loader   :
          color  : "#ffffff"
          diameter : 16
        style    : "modal-clean-gray"
        callback : ->
          KD.remote.api.JPayment.deleteAccountPaymentMethod {}, (err, res) ->
            modal.destroy()
            callback?()

submitAccountPaymentForm = (form, callback) ->
  formData = form.getFormData()

  if formData.cardNumber.indexOf('...') > -1
    delete formData['cardNumber']
  if formData.cardCV == 'XXX'
    delete formData['cardCV']

  KD.remote.api.JPayment.setAccount formData, (err, res) =>
    if err
      showAccountPaymentErrors form.fields, form.inputs, err
      callback? yes
    else
      showAccountPaymentErrors form.fields, form.inputs, []
      KD.remote.api.JPayment.getAccount {}, (e, r) =>
        unless e
          for k, v of r
            if form.inputs[k]
              form.inputs[k].setValue v
      callback? no

showAccountPaymentErrors = (fields, inputs, err) ->
  ERRORS =
    address1             :
      input              : inputs.address1
      field              : fields.address1
    address2             :
      input              : inputs.address2
      field              : fields.address2
    city                 :
      input              : inputs.city
      field              : fields.city
    state                :
      input              : inputs.state
      field              : fields.state
    country              :
      input              : inputs.country
      field              : fields.country
    first_name           :
      input              : inputs.cardFirstName
      field              : fields.cardFirstName
    last_name            :
      input              : inputs.cardLastName
      field              : fields.cardLastName
    number               :
      input              : inputs.cardNumber
      field              : fields.cardNumber
    zip                  :
      input              : inputs.zip
      field              : fields.zip
    verification_value   :
      input              : inputs.cardCV
      field              : fields.cardCV

  for key, val of ERRORS
    val.input.giveValidationFeedback no

  for e in err
    if e.field == 'account.base'
      val.input.showValidationError e.message
      if e.message.indexOf('card') > -1
        inputs.cardNumber.giveValidationFeedback yes
    else
      for key, val of ERRORS
        if e.field.indexOf(key) > -1
          val.input.giveValidationFeedback yes
          field = val.field.subViews[0].labelTitle
          val.input.showValidationError "#{field} #{e.message}"

class AccountPaymentMethodsListController extends KDListViewController
  constructor:(options,data)->
    super options,data

    @loadItems()

    @on "reload", (data)=>
      @loadItems()

    list = @getListView()
    list.on 'reload', (data)=>
      @loadItems()

  loadItems: ()->
    @removeAllItems()
    @showLazyLoader no

    KD.remote.api.JRecurlyPlan.getUserAccount (err, res) =>
      accounts = []
      if err
        @instantiateListItems []
        @hideLazyLoader()
      unless err
        if res.cardNumber
          accounts.push
            title        : "#{res.cardFirstName} #{res.cardLastName}"
            type         : res.cardType
            cardNumber   : res.cardNumber
            cardExpiry   : res.cardMonth + '/' + res.cardYear
            cardAddress  : res.address1 + ' ' + res.address2
            cardCity     : res.city
            cardState    : res.state
            cardZip      : res.zip
        @instantiateListItems accounts
        @hideLazyLoader()

  loadView:->
    super
    @getView().parent.addSubView addButton = new KDButtonView
      style     : "clean-gray account-header-button"
      title     : ""
      icon      : yes
      iconOnly  : yes
      iconClass : "plus"
      callback  : =>
        @getListView().showModal @

createAccountPaymentMethodModal = (data, callback) ->
  modal = new KDModalViewWithForms
    title                       : "Billing Information"
    content                     : ''
    helpContent                 :
      """
      """
    overlay                     : yes
    width                       : 500
    height                      : "auto"
    cssClass                    : "payments-modal"
    tabs                        :
      navigable                 : yes
      goToNextFormOnSubmit      : no
      forms                     :
        "Billing Info"          :
          buttons               :
            Add                 :
              title             : "Add"
              style             : "modal-clean-green"
              type              : "submit"
              loader            :
                color           : "#444444"
                diameter        : 12
              callback          : =>
                tabs = modal.modalTabs
                form = tabs.forms["Billing Info"]
                button = form.buttons["Add"]
                onError = ->
                    button.hideLoader()
                onSuccess = ->
                    modal.destroy()
                callback form.getFormData(), onError, onSuccess
          fields                :
            cardFirstName       :
              label             : "Name"
              itemClass         : KDInputView
              name              : "cardFirstName"
              placeholder       : "First Name"
              nextElementFlat   :
                cardLastName    :
                  itemClass     : KDInputView
                  name          : "cardLastName"
                  placeholder   : "Last Name"
            cardNumber          :
              label             : "Card Number"
              itemClass         : KDInputView
              name              : "cardNumber"
              placeholder       : 'Card Number'
              # validate          :
              #   event           : "blur"
              #   rules           : "creditCard"
              nextElementFlat   :
                cardCV          :
                  tooltip       :
                    placement   : 'right'
                    direction   : 'center'
                    title       : 'The location of this verification number depends on the issuer of your credit card'
                  itemClass     : KDInputView
                  name          : "cardCV"
                  placeholder   : "CV Number"
            cardMonth           :
              label             : "Expire Date"
              itemClass         : KDSelectBox
              type              : "select"
              name              : "cardMonth"
              selectOptions     : __utils.getMonthOptions()
              nextElementFlat   :
                cardYear        :
                  itemClass     : KDSelectBox
                  type          : "select"
                  name          : "cardYear"
                  selectOptions : __utils.getYearOptions((new Date().getFullYear()),(new Date().getFullYear()+25))
                  defaultValue  : (new Date().getFullYear())
            address1            :
              label             : "Address"
              itemClass         : KDInputView
              name              : "address1"
              placeholder       : "Street Name & Number"
            address2            :
              label             : " "
              itemClass         : KDInputView
              name              : "address2"
              placeholder       : "Apartment/Suite Number"
            city                :
              label             : "City & State"
              itemClass         : KDInputView
              name              : "city"
              placeholder       : "City Name"
              nextElementFlat   :
                state           :
                  itemClass     : KDInputView
                  name          : "state"
                  placeholder   : "State"
            zip                 :
              label             : "ZIP & Country"
              itemClass         : KDInputView
              name              : "zipCode"
              placeholder       : "ZIP Code"
              nextElementFlat   :
                country         :
                  itemClass     : KDInputView
                  name          : "country"
                  placeholder   : "Country"

  form = modal.modalTabs.forms["Billing Info"]
  for k, v of data
    if form.inputs[k]
      form.inputs[k].setValue v
  return modal

class AccountPaymentMethodsList extends KDListView
  constructor:(options,data)->
    options = $.extend
      tagName      : "ul"
      itemClass : AccountPaymentMethodsListItem
    ,options
    super options,data

  showModal: (controller) ->
    KD.remote.api.JRecurlyPlan.getUserAccount (err, data)->
      if err or not data
        data = {}

      modal = createAccountPaymentMethodModal data, (newData, onError, onSuccess) ->
        KD.remote.api.JRecurlyPlan.setUserAccount newData, (err, result)->
          if err
            onError()
          else

            controller.emit 'reload'
            onSuccess()

      form = modal.modalTabs.forms["Billing Info"]

      # Credit card icon
      form.fields['cardNumber'].addSubView icon = new KDCustomHTMLView tagName : "span", cssClass : "icon"

      form.inputs['cardNumber'].on "CreditCardTypeIdentified", (type)=>
        cardType = type.toLowerCase()
        $icon = icon.$()
        unless $icon.hasClass cardType
          $icon.removeClass "visa mastercard discover amex"
          $icon.addClass cardType

class AccountPaymentMethodsListItem extends KDListItemView
  constructor:(options,data)->
    options.tagName = "li"
    super options,data

  viewAppended:->
    @setPartial @partial @data

  partial:(data)->
    """
      <div class="credit-card-info">
        <p class="lightText"><strong>#{data.title} - #{data.type}</strong></p>
        <p class="lightText"><strong>#{data.cardNumber}</strong> - <strong>#{data.cardExpiry}</strong></p>
        <p class="darkText">
          #{data.cardAddress}<br>
          #{data.cardCity}, #{data.cardState} #{data.cardZip}
        </p>
      </div>
    """