class PaymentHistoryListItem extends KDListItemView

  constructor: (options = {}, data) ->

    options.cssClass = KD.utils.curry 'clearfix', options.cssClass

    super options, data


  partial: (data) ->

    status = if data.paid
    then 'success'
    else ''

    """
      <div class='#{status} status-icon'><span></span></div>
      <div class='billing-info'>
        <span class='amount'>#{data.amount / 100}</span>
        <span class='invoice-date'>#{dateFormat(data.periodEnd, 'mmm dd, yyyy')}</span>
        <span class='card-number'>**** #{data.paymentMethod?.last4}</span>
      </div>
    """


