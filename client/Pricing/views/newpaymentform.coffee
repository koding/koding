class NewPaymentForm extends KDFormViewWithFields
  constructor: (options = {}, data) ->

    fields =
      cardNumber          :
        label             : 'Card Number'
        defaultValue      : '4012888888881881'
        blur              : ->
          @oldValue = @getValue()
          @setValue @oldValue.replace /\s|-/g, ''
        focus             : ->
          @setValue @oldValue  if @oldValue
      cardCVC             :
        label             : 'CVC'
        defaultValue      : '303'
      cardName            :
        label             : 'Name on Card'
        defaultValue      : 'Senthil Arivudainambi'
        cssClass          : 'card-name'
      cardMonth           :
        label             : 'Exp. Date'
        maxLength         : 2
        defaultValue      : '10'
      cardYear            :
        label             : ''
        maxLength         : 2
        defaultValue      : '2015'

    super
      cssClass              : KD.utils.curry 'payment-method-entry-form clearfix', options.cssClass
      name                  : 'method'
      fields                : fields
      callback              : (formData) =>
        @emit "PaymentSubmitted", formData
      buttons               :
        Save                :
          title             : 'ADD CARD'
          style             : 'solid medium green'
          type              : 'submit'
          loader            : yes
        BACK                :
          style             : 'medium solid light-gray to-left'
          callback          : => # close modal

class NewPaymentModal extends KDModalView

  constructor: (options = {}, data) ->
    options.title or= "Upgrade your plan"

    super options, data

    @addSubView @payment = new NewPaymentForm
    @payment.on "PaymentSubmitted", (formData)=>
      @emit "PaymentSubmitted", formData
