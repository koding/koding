kd                  = require 'kd'
KDButtonView        = kd.ButtonView
KDListItemView      = kd.ListItemView
dateFormat          = require 'dateformat'
InvoicePreviewModal = require './invoicepreviewmodal'


module.exports = class PaymentHistoryListItem extends KDListItemView


  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'clearfix', options.cssClass

    super options, data


  partial: (data) ->

    status = if data.paid
    then 'success'
    else ''

    """
      <div class='#{status} status-icon'><span></span></div>
      <div class='billing-info'>
        <span class='amount'>$#{data.amount / 100} on</span>
        <span class='invoice-date'>#{dateFormat(data.periodEnd, 'mmm dd, yyyy')}</span>
      </div>
    """


  viewAppended: ->

    super

    @addSubView @showDetail = new KDButtonView
      cssClass  : 'solid small green show-detail'
      title     : 'DETAIL'
      callback  : =>
        new InvoicePreviewModal {}, @getData()
