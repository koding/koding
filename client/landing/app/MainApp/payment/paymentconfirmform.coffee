class PaymentConfirmForm extends JView

  constructor: (options = {}, data) ->
    super options, data

    @buttonBar = new KDButtonBar
      buttons       :
        Buy         :
          cssClass  : "modal-clean-green"
          callback  : => @emit 'PaymentConfirmed'
        cancel      :
          title     : "cancel"
          cssClass  : "modal-cancel"
          callback  : => @emit 'Cancel'
