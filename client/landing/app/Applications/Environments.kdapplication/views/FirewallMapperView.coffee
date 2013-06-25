class FirewallMapperView extends KDView

  constructor:(options={}, data)->
    data or= {}
    super options, data

    @on "domainChanged", (domainListItem)->
      @getData().domain = domainListItem.data
      @updateViewContent()

    @nav = new KDView
      tagName  : "ul"
      cssClass : "kdlistview kdlistview-default"
    @utils.defer => @nav.unsetClass "kdtabhandlecontainer"

    @tabView = new KDTabView
      cssClass           : 'environment-content'
      tabHandleContainer : @nav
      tabHandleClass     : EnvironmentsTabHandleView

    @filtersPane = new KDTabPaneView
      name     : "Filters"
      closable : no

    @rulesPane = new KDTabPaneView
      name     : "Rules"
      closable : no

    @tabView.addPane @rulesPane
    @tabView.addPane @filtersPane
    @tabView.showPaneByIndex 0

  updateViewContent:->
    {domain} = @getData()

    @rulesPane.destroySubViews()
    @filtersPane.destroySubViews()

    @filterListController = new FirewallFilterListController {}, {domain}
    @ruleListController = new FirewallRuleListController {}, {domain}

    @rulesPane.addSubView @ruleListView = new KDCustomHTMLView
      partial  : "<h3>Rule List For #{domain.domain}</h3>"
      cssClass : 'rule-list-view'

    @ruleListView.addSubView @ruleListController.getView()

    @filtersPane.addSubView @fwRuleFormView = new FirewallFilterFormView 
      delegate : @filterListController.getListView()
      , {domain}

    @filtersPane.addSubView @filterListView = new KDCustomHTMLView
      partial  : "<h3>Your Filter List</h3>"
      cssClass : 'filter-list-view'

    @filterListView.addSubView @filterListController.getView()    

    @filterListController.getListView().on "newRuleCreated", (item)=>
      @ruleListController.emit "newRuleCreated", item


  viewAppended:->
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    """
    <aside class="fl">
        <div class="kdview common-inner-nav">
          <div class="kdview listview-wrapper list">
            <h4 class="kdview kdheaderview list-group-title"><span></span></h4>
            {{> @nav }}
          </div>
        </div>
      </aside>
      <section class='right-overflow'>
        {{> @tabView }}
      </section>
    """

  updateActionOrders:(domain)->
    newRulesList = (item.getData() for item in @ruleListController.itemsOrdered)
    domain.updateRuleOrders newRulesList, (err, response)->
      return console.log err if err?
      new KDNotificationView
        title : "Order of your rule list has been successfully updated."
        type  : "top"