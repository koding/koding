kd = require 'kd'
KDListItemView = kd.ListItemView
dateFormat = require 'dateformat'

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




