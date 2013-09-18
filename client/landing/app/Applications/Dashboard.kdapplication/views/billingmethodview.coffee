class BillingMethodView extends JView
  constructor: (options, data) ->
    super

    @loader = new KDLoaderView
      size        : { width: 14 }
      showLoader  : yes

    @billingMethodInfo = new KDCustomHTMLView { tagName: 'a' }
    @billingMethodInfo.hide()

  setBillingInfo: (billingInfo) ->
    @loader.hide()
    @billingMethodInfo.updatePartial billingInfo
    @billingMethodInfo.show()

  pistachio: ->
    """
    {{> @loader }}
    {{> @billingMethodInfo }}
    """

