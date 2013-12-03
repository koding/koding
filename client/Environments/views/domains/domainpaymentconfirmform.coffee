class DomainPaymentConfirmForm extends PaymentConfirmForm

  viewAppended: ->
    { year, domain, price } = @getOptions()

    yearFmt = @utils.formatPlural year, 'year', no

    @details = new KDView
      partial:
        """
        <div class='modalformline'>
          <h3>Do you want to buy #{domain} for #{year} #{yearFmt}?</h3>
          <p>You will be charged <b>#{price}</b> for registering
          <b>#{domain}</b> domain for <b>#{year}</b> #{yearFmt}.</p>
        </div>
        """

    @addSubView @details, null, yes
