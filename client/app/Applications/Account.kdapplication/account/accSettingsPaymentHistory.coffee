class AccountPaymentHistoryListController extends KDListViewController

  constructor:(options,data)->
    data = $.extend
      items : [
        { title : "n/a" }
        # { createdAt : "01/01/2011", status : "paid",      amount : "42.50", currency : "$", paidVia : "Amex 4456" }
        # { createdAt : "13/02/2011", status : "pending",   amount : "12.00", currency : "$", paidVia : "Visa 1256" }
        # { createdAt : "31/03/2011", status : "cancelled", amount : "22.50", currency : "$", paidVia : "Amex 4456" }
        # { createdAt : "05/04/2011", status : "paid",      amount : "2.25",  currency : "$", paidVia : "PayPal" }
        # { createdAt : "23/07/2011", status : "paid",      amount : "32.50", currency : "$", paidVia : "PayPal" }
        # { createdAt : "01/12/2011", status : "paid",      amount : "12.50", currency : "$", paidVia : "Visa 1256" }
      ]
    ,data
    super options,data

class AccountPaymentHistoryList extends KDListView

  constructor:(options,data)->
    options = $.extend
      tagName      : "ul"
      itemClass : AccountPaymentHistoryListItem
    ,options
    super options,data

class AccountPaymentHistoryListItem extends KDListItemView
  constructor:(options,data)->
    options = tagName : "li"
    super options,data

  viewAppended:()->
    super
    # @addSubView editLink = new KDCustomHTMLView
    #   tagName      : "a"
    #   partial      : "View invoice"
    #   cssClass     : "action-link"

  click:(event)->
    if $(event.target).is "a.delete-icon"
      @getDelegate().handleEvent type : "UnlinkAccount", accountType : @getData().type

  partial:(data)->
    """
      <span class='darkText'>#{data.title}</span>
    """
    # cycleNotice = if data.billingCycle then "/#{data.billingCycle}" else ""
    # """
    #   <div class='labelish'>
    #     <span class='invoice-date'>#{data.createdAt}</span>
    #   </div>
    #   <div class='swappableish swappable-wrapper posstatic'>
    #     <span class='tag #{data.status}'>#{data.status}</span>
    #     <strong>#{data.currency}#{data.amount}</strong>
    #     <cite>#{data.paidVia}</cite>
    #   </div>
    # """
