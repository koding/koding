class DomainBuyConfirmForm extends KDFormViewWithFields

  constructor: (options = {}, data) ->

    options.buttons ?= {}

    options.buttons.Buy ?=
      cssClass  : "modal-clean-green"
      callback  : => @emit 'PaymentConfirmed'

    options.buttons.cancel ?=
      cssClass  : "modal-cancel"

    super options, data

  setPaymentMethod: (method) ->
    @details.addSubView new PaymentMethodView {}, method

  viewAppended: ->
    { year, domain, price } = @getOptions()

    yearFmt = @utils.formatPlural year, 'year', no

    @details = new KDView
      partial:
        """
        <h3>Do you want to buy #{domain} for #{year} #{yearFmt}?</h3>
        <div class='modalformline'>
          <p>You will be charged <b>#{price}</b> for registering
          <b>#{domain}</b> domain for <b>#{year}</b> #{yearFmt}.</p>
        </div>
        """

    @addSubView @details, null, yes
