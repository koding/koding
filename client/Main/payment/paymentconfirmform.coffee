class PaymentConfirmForm extends JView

  constructor: (options = {}, data) ->
    super options, data

    @buttonBar = new KDButtonBar
      buttons       :
        Buy         :
          title     : "PLACE YOUR ORDER"
          style     : "solid medium green"
          loader    :
            color   : "#ffffff"
            diameter: "26"
          callback  : =>
            @buttonBar.buttons['Buy'].showLoader()
            @emit 'PaymentConfirmed'

        cancel      :
          title     : "CANCEL"
          style     : "solid medium light-gray"
          callback  : => @emit 'Cancel'

  getExplanation: (key) -> # doesn't define any copy
