class Payment_Tabs extends MainTabView

  constructor:->
    super
    @setClass "payment-tabs"
    @listenTo
      KDEventTypes        : "PaymentShowTab"
      listenedToInstance  : @getDelegate().accountNav
      callback            : (publishingInstance,e)=>
        @setPane name : e.pageName

    @listenTo
      KDEventTypes        : "SeeAllDepositHistory"
      callback            : (publishingInstance,e)=>
        @getDelegate().accountNav.selectItemAtIndex 2
        @setPane name : "Purchase History"

    @listenTo
      KDEventTypes        : "SeeAllPurchaseHistory"
      callback            : (publishingInstance,e)=>
        @getDelegate().accountNav.selectItemAtIndex 2
        @setPane name : "Purchase History"

    @listenTo
      KDEventTypes        : "ChangeAutoRecharge"
      callback            : (publishingInstance,e)=>
        @getDelegate().accountNav.selectItemAtIndex 1
        @setPane name : "Payment Settings"

  createPagePane:(pane)->

    switch pane.name

      # Pages
      when "Overview"             then pane.addSubView new Payment_Overview (delegate : pane)
      when "Payment Settings"     then pane.addSubView new Payment_Settings (delegate : pane)
      when "Purchase History"     then pane.addSubView new Payment_PurchaseHistory (delegate : pane)

  setPane:(options,data = null)->
    balanceView = @getDelegate()
    pane = @getPaneByName options.name

    if pane is false
      @createTabPane name : options.name,data
      balanceView.expandTabs()
    else
      if pane.active
        if balanceView.tabsExpanded
          balanceView.collapseTabs()
          @getDelegate().accountNav.deselectAllItems()
        else
          balanceView.expandTabs()
      else
        @showPane pane
        balanceView.expandTabs()

class Payment_TabContent extends KDView
  constructor:->
    super
    @setClass "payment-tab-content"

  viewAppended:->
    @addSubView @wrapper = new KDScrollView cssClass : "payment-tab-wrapper"


class Payment_ModalTabs extends KDTabView
