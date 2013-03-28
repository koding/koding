class Payment_Overview extends Payment_TabContent
  constructor:->
    super

  click:(event)->
    @handleEvent(type : "SeeAllDepositHistory") if $(event.target).is(".propagateFullDepositHistory")
    @handleEvent(type : "SeeAllPurchaseHistory") if $(event.target).is(".propagateFullPurchaseHistory")

  dummyDepositHistory:
    items : [{ timestamp : 1312889694107, deposit : 20, currency : "$", status : "booked" },{ timestamp : 1312889694107, deposit : 50, currency : "$", status : "failed" },{ timestamp : 1312889694107, deposit : 20, currency : "$", status : "booked" },{ timestamp : 1312889694107, deposit : 100, currency : "$", status : "booked" }]

  dummyPurchaseHistory:
    items : [{timestamp : 1312889694107, cost : 2, currency : "$", status : "booked", description : "Standard package, no limits blah blah...",product:{id : 123,title : "Git Repository"}},{timestamp : 1312889694107, cost : 56.2, currency : "$", status : "failed", description : "Some package information",product:{id : 123,title : "Mongo Database"}},{timestamp : 1312889694107, cost : 18,   currency : "$", status : "booked", description : "n/a",product:{id : 123,title : "Something else"}},{timestamp : 1312889694107, cost : 112,  currency : "$", status : "booked", description : "n/a",product:{id : 123,title : "XEN Server"}}]

  viewAppended:->
    super
    @wrapper.addSubView autoRecharge = new Payment_OverviewAutoRecharge delegate : @
    left  = new KDView()
    right = new KDView()
    split = new SplitView
      views : [left,right]
      resizable : no


    left.addSubView new KDHeaderView type : "small", title : "Deposit History:"
    left.addSubView historyList  = new Payment_OverviewHistoryList delegate : @, itemClass : Payment_OverviewDepositHistoryListItem,@dummyDepositHistory
    left.setPartial "<a href='#' class='see-all propagateFullDepositHistory'>See all...</a>"
    right.addSubView new KDHeaderView type : "small", title : "Purchase History:"
    right.addSubView historyList  = new Payment_OverviewHistoryList delegate : @, itemClass : Payment_OverviewPurchaseHistoryListItem,@dummyPurchaseHistory
    right.setPartial "<a href='#' class='see-all propagateFullPurchaseHistory'>See all...</a>"
    @wrapper.addSubView split

class Payment_OverviewHistoryList extends KDListView
  constructor:(options,data)->
    options.type = "payment-history"
    super options,data

class Payment_OverviewPurchaseHistoryListItem extends KDListItemView
  partial:(data)->
    @setClass data.status
    @setTooltip data.description, defaultPosition : "right" if data.description?
    partial = $ "
      <span class='status #{data.status}'>#{data.status}: </span>
      <span>#{data.product.title}</span>
      <time datetime='#{new Date(data.timestamp).format 'isoUtcDateTime'}'>#{new Date(data.timestamp).format "mmmm dS, h:MM"}</time>
      <span class='fr'>#{data.currency} #{data.cost}</span>
      "

class Payment_OverviewDepositHistoryListItem extends KDListItemView
  partial:(data)->
    @setClass data.status
    partial = $ "
      <span class='status #{data.status}'>#{data.status}: </span>
      <time datetime='#{new Date(data.timestamp).format 'isoUtcDateTime'}'>#{new Date(data.timestamp).format "mmmm dS, h:MM"}</time>
      <span class='fr'>#{data.currency} #{data.deposit}</span>
      "

class Payment_OverviewAutoRecharge extends KDView
  viewAppended:->
    @setPartial @partial()

  click:(event)->
    @handleEvent(type : "ChangeAutoRecharge") if $(event.target).is(".propagateChange")

  partial:->
    "<h4>Auto-recharge is <span>enabled</span><a href='#' class='propagateChange'>Change</a></h4>
     <p class='description'>Your Koding Credit balance will Auto-recharge with $20,00 when it falls below $2,00 using payment method Visa (XXXX-0622).</p>
     <p class='hint'>Total amount will be $23,00 including 15% tax.</p>"
