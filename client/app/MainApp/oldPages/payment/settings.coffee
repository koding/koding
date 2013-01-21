class Payment_Settings extends Payment_TabContent
  constructor:->
    super

  dummyStoredPaymentMethods:
    items : [{ type : "paypal", medium : { title : "PayPal", id : "mail@sinanyasar.com"}},{ type : "visa", default : yes, medium : { title : "VISA", id : "xxxx-0123"}}]

  viewAppended:->
    super
    @wrapper.addSubView   form1     = new KDFormView delegate : @

    form1.addSubView                  new KDHeaderView      type : "small", title : "Auto-Recharge:"
    form1.addSubView      fieldset1 = new KDCustomHTMLView  "fieldset"
    fieldset1.addSubView  label1    = new KDLabelView       title : "Enable or disable Auto-Recharge"
    fieldset1.addSubView  switch1   = new KDInputSwitch     title : "Enable or disable Auto-Recharge",defaultValue : on,callback : (state)=> @autoRechargeSwitch state
    fieldset1.addSubView  @input1   = new KDInputView
      type          : "select"
      label         : label1
      defaultValue  : "20"
      selectOptions : [
        { title : "$ 20", value : "20" }
        { title : "$ 50", value : "50" }
        { title : "$ 100",value : "100" }
        { title : "$ 200",value : "200" }
        { title : "$ 500",value : "200" }
      ]
    @input1.$().hide()

    @wrapper.addSubView form2       = new KDFormView delegate : @
    form2.addSubView                  new KDHeaderView      type : "small", title : "Stored Payment Methods:"
    form2.addSubView    historyList = new Payment_OverviewHistoryList delegate : @, itemClass : Payment_PaymentMethodListItem,@dummyStoredPaymentMethods

    # form2.addSubView    addPayPal   = new KDButtonView title : "Add a Paypal Account", style : "small-gray"
    # form2.addSubView    addCC       = new KDButtonView title : "Add a Credit Card", style : "small-gray"
    form2.addSubView    addPaymentMethod = new KDButtonView title : "Add Payment Method", style : "small-gray" ,callback:@addNewPaymentMethod

  addNewPaymentMethod:->
    modal = new KDModalView
      title   : "Add a new Payment Method"
      cssClass: "payment-method-modal"
      overlay : yes
      width   : 600
      height  : 300

    #@modal.addSubView (appTabs = new Payment_ModalTabs delegate : @),'.kdmodal-content'
    # modal.addSubView (new KDButtonView (title : "Add Payment Method", style : "small-gray")),'.kdmodal-content'
    #tabNames = ["Credit Card","Direct Debit"]#"Google checkout","Amazon","PayPal","Moneybookers"]
    #appTabs.hideHandleCloseIcons()
    #appTabs.setHeight "auto"
    #
    #tabs = {}
    #for name in tabNames
    #  tab = new KDTabPaneView null,null
    #  appTabs.addPane tab
    #  tab.setTitle name
    #  tabs[name] = tab
    #
    #appTabs.showPane tabs["Credit Card"]
    #
    modal.addSubView ccView = new Payment_AddCreditCardView
    #tabs["Direct Debit"].addSubView ddView = new Payment_AddDirectDebitView()
    # tabs["Google checkout"].addSubView gcView = new Payment_AddGoogleCheckoutView()

  autoRechargeSwitch:(state)->
    if state
      @input1.$().fadeIn(100)
    else
      @input1.$().fadeOut(100)


class Payment_AddCreditCardView extends KDFormView
  constructor:(options={})->
    options.callback = @formSubmit
    super options

  viewAppended:->
    modal = @parent
    #@addSubView form = new KDFormView
    #  callback:(formData)->
    #    log formData
    @addSubView fieldset1                = new KDCustomHTMLView "fieldset"
    fieldset1.addSubView cardNumberLabel = new KDLabelView title : "Card Number"
    fieldset1.addSubView cardNumber      = new KDInputView
      name : "card-number"
      cssClass : "big"
      label : cardNumberLabel
      defaultValue : "xxxx-xxxx-xxxx-xxxx"
      validate  :
        event     : "blur"
        rules     : "creditCard"
        messages  :
          creditCard : "correct credit card please"

    @listenTo
      KDEventTypes : "ValidatorHasToSay"
      listenedToInstance : cardNumber
      callback:(pubInst,event)->
        new KDNotificationView
          title     : "That's a '#{event.creditCardType} Card"
          duration  : 500

    @addSubView fieldset2                = new KDCustomHTMLView "fieldset"
    fieldset2.addSubView cardOwnerLabel  = new KDLabelView title : "Card Owner"
    fieldset2.addSubView cardOwner       = new KDInputView name : "card-owner",cssClass : "middle",label : cardOwnerLabel,defaultValue : "Justin Bieber"

    fieldset2.addSubView expiryLabel     = new KDLabelView title : "Expiry Date"
    fieldset2.addSubView expiryMonths    = new KDInputView
      type : "select"
      name : "card-exp-month"
      cssClass : "small"
      label : expiryLabel
      defaultValue  : (new Date().getMonth())
      selectOptions : __utils.getMonthOptions()

    fieldset2.addSubView expiryMonths    = new KDInputView
      type : "select"
      name : "card-exp-year"
      cssClass : "small"
      label : expiryLabel
      defaultValue  : (new Date().getFullYear())
      selectOptions : __utils.getYearOptions((new Date().getFullYear()),(new Date().getFullYear()+10))

    @addSubView fieldset3          = new KDCustomHTMLView "fieldset"
    fieldset3.addSubView cvcLabel  = new KDLabelView title : "Card Verification Code (cvc)"
    fieldset3.addSubView cvc       = new KDInputView name : "card-cvc",cssClass : "small",label : cvcLabel
    fieldset3.setPartial "<a href='#' class='propagateWhatIsCvc'>What is verification code?</a>"
    @setPartial "<a href='#' class='propagatePrivacyPolicy'>Privacy Policy</a>"
    @addSubView buttons = new KDView
    buttons.addSubView cancelButton = new KDButtonView
      title: 'Cancel'
      callback: ->
        modal.destroy()
        no
    buttons.addSubView okButton = new KDButtonView title: 'Add a payment method', style: 'cupid-green'

  formSubmit:(formData)->
    KDData::invokeServerSide
      addPaymentMethod  :
        params: formData
        middleware: (err, params, result)->
          log arguments
    no


class Payment_AddDirectDebitView extends KDView
  viewAppended:->
    @addSubView label = new KDLabelView title : "Bank Account"

class Payment_AddGoogleCheckoutView extends KDView
  viewAppended:->
    @addSubView label = new KDLabelView title : "Google Id"


class Payment_PaymentMethodListItem extends KDListItemView
  partial:(data)->
    defaultMethod = if data.default? and data.default then "default-method" else "hidden"
    partial = $ "
      <span class='#{data.type}'>#{data.medium.title}</span>
      <span class='#{defaultMethod}'>Default</span>
      <a href='#' class='propagateRemovePaymentMethod fr'>Remove</a>
      <span class='fr'>#{data.medium.id}</span>
      "
