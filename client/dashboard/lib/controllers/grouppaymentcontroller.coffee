kd = require 'kd'
KDController = kd.Controller
KDModalView = kd.ModalView
getGroup = require 'app/util/getGroup'
showError = require 'app/util/showError'
PaymentMethodView = require 'app/payment/paymentmethodview'


module.exports = class GroupPaymentController extends KDController

  constructor: (options = {}, data) ->
    super options, data

    @preparePaymentsView()

  preparePaymentsView:->

    { view } = @getOptions()

    group = getGroup()

    paymentController = kd.getSingleton 'paymentController'
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

    group = getGroup()
    group.fetchPaymentMethod (err, paymentMethod) =>
      return if showError err

      view.setPaymentInfo paymentMethod

  showPaymentInfoModal: ->
    modal = @createPaymentInfoModal()

    group = getGroup()

    paymentController = kd.getSingleton 'paymentController'
    paymentController.observePaymentSave modal, (err, { paymentMethodId }) =>
      return  if showError err

      modal.destroy()
      group.linkPaymentMethod paymentMethodId, (err) =>
        return  if showError err

        @refreshPaymentView()

#    modal.on 'CountryDataPopulated', -> callback null, modal
    modal

  createPaymentInfoModal: ->

    paymentController = kd.getSingleton "paymentController"
    modal = paymentController.createPaymentInfoModal 'group'

    group = getGroup()
    group.fetchPaymentMethod (err, groupPaymentMethod) =>
      return  if showError err

      if groupPaymentMethod
        modal.setState 'editExisting', groupPaymentMethod

      else
        paymentController.fetchPaymentMethods (err, personalPaymentMethods) =>
          return  if showError err

          if personalPaymentMethods.methods.length > 0
            modal.setState 'selectPersonal', personalPaymentMethods
            modal.on 'PaymentMethodChosen', ({ paymentMethodId }) =>

              group.linkPaymentMethod paymentMethodId, (err) =>
                return  if showError err

                modal.destroy()
                @refreshPaymentView()

          else
            modal.setState 'createNew'

    return modal


