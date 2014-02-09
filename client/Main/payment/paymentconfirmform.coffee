class PaymentConfirmForm extends JView

  constructor: (options = {}, data) ->
    super options, data

    @buttonBar = new KDButtonBar
      buttons       :
        cancel      :
          title     : "CANCEL"
          cssClass  : "solid gray"
          callback  : => @emit 'Cancel'
        Buy         :
          title     : "CONFIRM ORDER"
          cssClass  : "solid green"
          loader    :
            color   : "#ffffff"
            diameter: "26"

          callback  : =>
            @buttonBar.buttons['Buy'].showLoader()
            @emit 'PaymentConfirmed'

  getExplanation: (key) -> # doesn't define any copy
