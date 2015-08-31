kd                = require 'kd'
dateFormat        = require 'dateformat'
KDModalView       = kd.ModalView
KDCustomHTMLView  = kd.CustomHTMLView


module.exports = class InvoicePreviewModal extends KDModalView


  constructor: (options = {}, data) ->

    options.width       = 450
    options.cssClass  or= 'ivoice-preview'
    options.title     or= 'Invoice Preview'

    super options, data

    { plan, amount, periodEnd } = @getData()
    amount                      = amount / 100

    plan = 'Developer'

    @addSubView new KDCustomHTMLView
      partial : """
        <div class="billing-info">
          Subscribed to
          <em>#{plan} on #{dateFormat(periodEnd, 'mmm dd, yyyy')}</em>
        </div>
        <div class="billing-info">
          <span>Total</span>
          <em>$#{amount}</em>
        </div>
      """

