class GroupPaymentController extends KDController

  constructor: (options = {}, data) ->
    super options, data

    @preparePaymentsView()

  preparePaymentsView:->

    { view } = @getOptions()

    group = KD.getGroup()

    paymentController = KD.getSingleton 'paymentController'
    paymentController.on 'PaymentDataChanged', => @refreshPaymentView()

    @refreshPaymentView()

    view.on 'PaymentMethodEditRequested', => @showPaymentInfoModal()
    view.on 'PaymentMethodUnlinkRequested', (paymentMethod) =>
      modal = KDModalView.confirm
        title       : 'Are you sure?'
        description : 'Are you sure you want to unlink this payment method?'
        subView     : new PaymentMethodView {}, paymentMethod
        ok          :
          title     : 'Unlink'
          callback  : =>
            group.unlinkPaymentMethod paymentMethod.paymentMethodId, =>
              modal.destroy()
              @refreshPaymentView()

  refreshPaymentView: ->

    { view } = @getOptions()

    group = KD.getGroup()
    group.fetchPaymentMethod (err, paymentMethod) =>
      return if KD.showError err

      view.setPaymentInfo paymentMethod

  showPaymentInfoModal: ->
    modal = @createPaymentInfoModal()

    group = KD.getGroup()

    paymentController = KD.getSingleton 'paymentController'
    paymentController.observePaymentSave modal, (err, { paymentMethodId }) =>
      return  if KD.showError err

      modal.destroy()
      group.linkPaymentMethod paymentMethodId, (err) =>
        return  if KD.showError err

        @refreshPaymentView()

#    modal.on 'CountryDataPopulated', -> callback null, modal
    modal

  createPaymentInfoModal: ->

    paymentController = KD.getSingleton "paymentController"
    modal = paymentController.createPaymentInfoModal 'group'

    group = KD.getGroup()
    group.fetchPaymentMethod (err, groupPaymentMethod) =>
      return  if KD.showError err

      if groupPaymentMethod
        modal.setState 'editExisting', groupPaymentMethod

      else
        paymentController.fetchPaymentMethods (err, personalPaymentMethods) =>
          return  if KD.showError err

          if personalPaymentMethods.methods.length > 0
            modal.setState 'selectPersonal', personalPaymentMethods
            modal.on 'PaymentMethodChosen', ({ paymentMethodId }) =>

              group.linkPaymentMethod paymentMethodId, (err) =>
                return  if KD.showError err

                modal.destroy()
                @refreshPaymentView()

          else
            modal.setState 'createNew'

    return modal
