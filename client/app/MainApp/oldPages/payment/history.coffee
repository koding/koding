class Payment_PurchaseHistory extends Payment_TabContent
  constructor:->
    super

  dummyDepositHistory:
    items : [{ timestamp : 1312889694107, deposit : 20, currency : "$", status : "booked" },{ timestamp : 1312889694107, deposit : 50, currency : "$", status : "failed" },{ timestamp : 1312889694107, deposit : 20, currency : "$", status : "booked" },{ timestamp : 1312889694107, deposit : 100, currency : "$", status : "booked" },{ timestamp : 1312889694107, deposit : 20, currency : "$", status : "booked" },{ timestamp : 1312889694107, deposit : 50, currency : "$", status : "failed" },{ timestamp : 1312889694107, deposit : 20, currency : "$", status : "booked" },{ timestamp : 1312889694107, deposit : 100, currency : "$", status : "booked" }]

  dummyPurchaseHistory:
    items : [{timestamp : 1312889694107, cost : 2, currency : "$", status : "booked", description : "Standard package, no limits blah blah...",product:{id : 123,title : "Git Repository"}},{timestamp : 1312889694107, cost : 56.2, currency : "$", status : "failed", description : "Some package information",product:{id : 123,title : "Mongo Database"}},{timestamp : 1312889694107, cost : 18,   currency : "$", status : "booked", description : "n/a",product:{id : 123,title : "Something else"}},{timestamp : 1312889694107, cost : 112,  currency : "$", status : "booked", description : "n/a",product:{id : 123,title : "XEN Server"}},{timestamp : 1312889694107, cost : 2, currency : "$", status : "booked", description : "Standard package, no limits blah blah...",product:{id : 123,title : "Git Repository"}},{timestamp : 1312889694107, cost : 56.2, currency : "$", status : "failed", description : "Some package information",product:{id : 123,title : "Mongo Database"}},{timestamp : 1312889694107, cost : 18,   currency : "$", status : "booked", description : "n/a",product:{id : 123,title : "Something else"}},{timestamp : 1312889694107, cost : 112,  currency : "$", status : "booked", description : "n/a",product:{id : 123,title : "XEN Server"}}]

  viewAppended:->
    super

    left  = new KDView()
    right = new KDView()
    split = new SplitView
      cssClass : "full-list"
      views : [left,right]
      resizable : no

    left.addSubView new KDHeaderView type : "small", title : "Purchase History:"
    left.addSubView purchaseList  = new Payment_OverviewHistoryList delegate : @, itemClass : Payment_OverviewPurchaseHistoryListItem,@dummyPurchaseHistory
    right.addSubView new KDHeaderView type : "small", title : "Deposit History:"
    right.addSubView depositList  = new Payment_OverviewHistoryList delegate : @, itemClass : Payment_OverviewDepositHistoryListItem,@dummyDepositHistory
    @wrapper.addSubView split
