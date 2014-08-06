class AccountPaymentHistoryListController extends AccountListViewController

  constructor:(options={},data)->
    options.noItemFoundText or= 'You have no payment history.'

    super options, data

    @getListView().on 'Reload', @bound 'loadItems'
    @loadItems()

  loadItems:->
    { JPayment } = KD.remote.api

    @removeAllItems()
    @showLazyLoader no

    items = []
    JPayment.fetchTransactions (err, transactions) =>
      warn err  if err

      for own paymentMethodId, transactionList of transactions
        for transaction in transactionList when transaction.amount > 0

          { status, createdAt, card, cardType, invoice
            cardNumber, owner, refundable, type } = transaction

          amount = @utils.formatMoney (transaction.amount + transaction.tax) / 100

          items.push {
            status
            cardType
            cardNumber
            owner
            refundable
            amount
            invoice
            currency : 'USD'
            paidVia  : card or ''
          }

      @instantiateListItems items
      @hideLazyLoader()


class AccountPaymentHistoryList extends KDListView

  constructor:(options={},data)->
    options.itemClass or= AccountPaymentHistoryListItem

    super options, data


class AccountPaymentHistoryListItem extends KDListItemView

  constructor:(options={},data)->
    options.cssClass = KD.utils.curry 'clearfix', options.cssClass
    super options, data

  viewAppended:->
    super

    @addSubView new KDButtonView
      title        : 'invoice'
      style        : 'solid green medium'
      cssClass     : 'invoice-btn'

  click:(event)->
    event.stopPropagation()
    event.preventDefault()
    if $(event.target).is 'a.delete-icon'
      @getDelegate().emit 'UnlinkAccount', accountType : @getData().type

  partial:(data)->
    cycleNotice = if data.billingCycle then "/#{data.billingCycle}" else ''
    """
      <div class='#{data.status} status-icon'><span></span></div>
      <div class='billing-info'>
        <strong>#{data.amount}</strong>
        <span class='invoice-date'>#{dateFormat(data.createdAt, 'mmm dd, yyyy')}</span>
        <span class='card-number'>**** #{data.cardNumber}</span>
      </div>
    """
