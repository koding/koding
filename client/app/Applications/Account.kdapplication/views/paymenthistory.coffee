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

    transactions = []
    JPayment.fetchTransactions (err, trans=[]) =>
      warn err  if err

      for t in trans when t.amount + t.tax > 0
        {status, createdAt, card, cardType, cardNumber, owner, refundable} = t
        amount = @utils.formatMoney (t.amount + t.tax) / 100
        transactions.push {
          status, cardType, cardNumber, owner, refundable, amount
          currency : 'USD'
          paidVia  : card or ''
        }

      @instantiateListItems transactions
      @hideLazyLoader()

  loadView:->
    super

    @getView().parent.addSubView updateButton = new KDButtonView
      style     : 'clean-gray account-header-cc'
      title     : 'Update billing info'
      callback  : ->
        # TODO: needs implementin'
        # KD.getSingleton('paymentController').updatePaymentInfo 'user'

    @getView().parent.addSubView reloadButton = new KDButtonView
      style     : 'clean-gray account-header-button'
      title     : ''
      icon      : yes
      iconOnly  : yes
      iconClass : 'refresh'
      callback  : @getListView().emit.bind @getListView(), 'Reload'


class AccountPaymentHistoryList extends KDListView

  constructor:(options={},data)->
    options.tagName   or= 'table'
    options.itemClass or= AccountPaymentHistoryListItem

    super options, data


class AccountPaymentHistoryListItem extends KDListItemView

  constructor:(options={},data)->
    options.tagName or= 'tr'

    super options, data

  viewAppended:->
    super
    @addSubView editLink = new KDCustomHTMLView
      tagName      : 'a'
      partial      : 'View invoice'
      cssClass     : 'action-link'

  click:(event)->
    event.stopPropagation()
    event.preventDefault()
    if $(event.target).is 'a.delete-icon'
      @getDelegate().emit 'UnlinkAccount', accountType : @getData().type

  partial:(data)->
    cycleNotice = if data.billingCycle then "/#{data.billingCycle}" else ''
    """
    <td>
      <span class='invoice-date'>#{dateFormat(data.createdAt, 'mmm dd, yyyy')}</span>
    </td>
    <td>
      <strong>#{data.amount}</strong>
    </td>
    <td>
      <span class='ttag #{data.status}'>#{data.status.toUpperCase()}</span>
    </td>
    <td class='ccard'>
      <span class='icon #{data.cardType.toLowerCase().replace(' ', '-')}'></span>...#{data.cardNumber.split("...")[1]}
    </td>
    """
