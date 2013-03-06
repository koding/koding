class AccountPaymentMethodsListController extends KDListViewController
  constructor:(options,data)->
    data = $.extend
      items : [
        { title : "Payment methods are coming soon" }
      ]
    ,data
    # data = $.extend
    #   items : [
    #     {
    #       title : "My personal card",   type : "visa", cardNumber : "432* **** **** *029"
    #       cardOwner : "Ryan Goodman", cardAddress : "Somewhere in LA", cardCity : "Los Angeles"
    #       cardZip : "11111", cardState : "CA", cardExpiry : "03/2013"
    #     }
    #     ,
    #     {
    #       title : "Corporate Amex",     type : "amex", cardNumber : "370*********834"
    #       cardOwner : "Ryan Goodman", cardAddress : "780A Valencia St", cardCity : "San Francisco"
    #       cardZip : "94110", cardState : "CA", cardExpiry : "11/2015"
    #     }
    #   ]
    # ,data
    super options,data

    loadView:->
      super
      # @getView().parent.addSubView addButton = new KDButtonView
      #   style     : "clean-gray account-header-button"
      #   title     : ""
      #   icon      : yes
      #   iconOnly  : yes
      #   iconClass : "plus"
      #   callback  : =>
      #     @getListView().showModal()


class AccountPaymentMethodsList extends KDListView
  constructor:(options,data)->
    options = $.extend
      tagName      : "ul"
      itemClass : AccountPaymentMethodsListItem
    ,options
    super options,data

  showModal:->
    form = new AccountCreditCardForm
      callback : @formSubmit
      cssClass : "clearfix"

    modal = new KDModalView
      title     : "Add a new payment method"
      content   : ""
      overlay   : yes
      cssClass  : "new-kdmodal"
      width     : 500
      height    : 300
      view      : form
      buttons   :
        "Add Payment Method" :
          style     : "modal-clean-gray"
          callback  : (event)->
            if form.submit(event)
              form.destroy()
              modal.destroy()
        Cancel   :
          style     : "modal-cancel"
          callback  : (event)->
            form.destroy()
            modal.destroy()

    modal.addSubView helpBox = new HelpBox, ".kdmodal-buttons"


class AccountCreditCardInfo extends KDView
  viewAppended:->
    @setPartial @partial @data

  partial:(data)->
    """
      <div class="credit-card-info">
        <p class="lightText"><strong>#{data.type}</strong></p>
        <p class="lightText"><strong>#{data.cardNumber}</strong> - <strong>#{data.cardExpiry}</strong></p>
        <p class="darkText">
          #{data.cardAddress}<br>
          #{data.cardCity}, #{data.cardState} #{data.cardZip}
        </p>
      </div>
    """

class AccountCreditCardForm extends KDFormView
  viewAppended:->
    super

    @addSubView formline1                = new KDCustomHTMLView
      tagName : "div"
      cssClass : "modalformline"
    formline1.addSubView cardNumber      = new AccountCreditCardInput

    @addSubView formline2                = new KDCustomHTMLView
      tagName : "div"
      cssClass : "modalformline"

    formline2.addSubView cardOwner       = new KDInputView name : "card-owner", placeholder : "Card Owner..."

    @addSubView formline3          = new KDCustomHTMLView
      tagName : "div"
      cssClass : "modalformline"

    formline3.addSubView expiryLabel     = new KDLabelView title : "Expiry Date"
    formline3.addSubView expiryMonths    = new KDSelectBox
      type : "select"
      name : "card-exp-month"
      cssClass : "select"
      label : expiryLabel
      defaultValue  : (new Date().getMonth())
      selectOptions : __utils.getMonthOptions()

    formline3.addSubView expiryMonths    = new KDSelectBox
      type : "select"
      name : "card-exp-year"
      cssClass : "select"
      label : expiryLabel
      defaultValue  : (new Date().getFullYear())
      selectOptions : __utils.getYearOptions((new Date().getFullYear()),(new Date().getFullYear()+10))

    @addSubView formline4          = new KDCustomHTMLView
      tagName : "div"
      cssClass : "modalformline"

    formline4.addSubView cvc       = new KDInputView name : "card-cvc", cssClass : "small", placeholder:"cvc"

    formline4.addSubView linkholder = new KDCustomHTMLView
      tagName      : "div"
      cssClass     : "kdview linkholder"

    linkholder.addSubView cvcLink   = new KDCustomHTMLView
      tagName      : "a"
      partial      : "What is verification code?"
      cssClass     : "propagateWhatIsCvc"

    linkholder.addSubView ppLink   = new KDCustomHTMLView
      tagName      : "a"
      partial      : "Privacy Policy"
      cssClass     : "propagatePrivacyPolicy"

  putEditButtons:->
    @addSubView buttons = new KDView
      cssClass : "formline"

    @addSubView actionsWrapper = new KDCustomHTMLView
      tagName : "div"
      cssClass : "actions-wrapper"

    actionsWrapper.addSubView cancelLink = new KDCustomHTMLView
      tagName  : "a"
      partial  : "Cancel"
      click    : => @emit "FormCancelled"

    buttons.addSubView okButton = new KDButtonView title: 'Change payment method', style: 'cupid-green'


class AccountCreditCardInput extends KDView
  InputView = class CCInput extends KDInputView
    # setValidationResult:(didPass,message)->
    #   if didPass
    #     @valid = yes
    #     @inputValidationMessage = message if message
    #     @inputClearValidationError()
    #     @inputValidationNotification.destroy() if @inputValidationNotification?
    #   else
    #     @valid = no
    #     @inputValidationMessage = message
    #     @showValidationError message

  viewAppended:->
    @setClass "credit-card-input-view"
    @addSubView @input = new CCInput
      name            : "card-number"
      placeholder     : "xxxx xxxx xxxx xxxx"
      validate        :
        event         : "blur"
        rules         : "creditCard"

    @addSubView icon = new KDCustomHTMLView tagName : "span", cssClass : "icon"

    @input.on "CreditCardTypeIdentified", (type)=>
      cardType = event.creditCardType.toLowerCase()
      $icon = icon.$()
      $icon.removeClass "visa mastercard discover amex"
      $icon.addClass cardType
        # iconWrapper.$(".icon.#{cardType}").fadeIn 100,()->
        #   iconWrapper.$(".icon.#{cardType}").siblings().fadeOut 100
        # log event.creditCardType
        # KDInputValidator::ruleCreditCard pubInst,event
        # new KDNotificationView
        #   title     : "That's a '#{event.creditCardType} Card"
        #   duration  : 500





class AccountPaymentMethodsListItem extends KDListItemView
  constructor:(options,data)->
    options = tagName : "li"
    super options,data

  # viewAppended:()->
  #   super
  #
  #   form = new AccountCreditCardForm
  #     delegate : @
  #     cssClass : "posstatic"
  #   ,@data
  #
  #   info = new AccountCreditCardInfo
  #     delegate : @
  #     cssClass : "posstatic"
  #   ,@data
  #
  #   info.addSubView editLink = new KDCustomHTMLView
  #     tagName  : "a"
  #     partial  : "Edit"
  #     cssClass : "action-link"
  #     click    : @bound "swapSwappable"
  #
  #   @swappable = swappable = new AccountsSwappable
  #     views : [form,info]
  #     cssClass : "posstatic"
  #
  #   @addSubView swappable,".swappable-wrapper"
  #   form.putEditButtons()
  #
  #   form.on "FormCancelled", @bound "swapSwappable"

  swapSwappable:()=>
    @swappable.swapViews()

  click:(event)->
    if $(event.target).is "a.delete-icon"
      @getDelegate().emit "UnlinkAccount", accountType : @getData().type

  partial:(data)->
    """
      <span class='darkText'>#{data.title}</span>
    """
    # """
    #   <div class='labelish'>
    #     <span class='payment-method-title'>#{data.title}</span>
    #   </div>
    #   <div class='swappableish swappable-wrapper posstatic'>
    #   </div>
    # """


