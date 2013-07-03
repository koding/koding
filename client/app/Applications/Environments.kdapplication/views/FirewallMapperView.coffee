class FirewallMapperView extends KDView

  constructor:(options={}, data)->
    data or= {}
    super options, data

    @on "DomainChanged", (domainListItem)->
      @getData().domain = domainListItem.data
      @updateViewContent()

  updateViewContent:->
    {domain} = @getData()

    @destroySubViews()

    @filterListController = new FirewallFilterListController {}, {domain}
    @ruleListController = new FirewallRuleListController {}, {domain}

    @ruleListView = new KDCustomHTMLView
      partial  : "<h4>Rule List For #{domain.domain}</h4>"
      cssClass : 'rule-list-view'

    @fwRuleFormView = new FirewallFilterFormView
      delegate : @filterListController.getListView()
      , {domain}

    @filterListView = new KDCustomHTMLView
      partial  : "<h4>Your Filter List</h4>"
      cssClass : 'filter-list-view'

    @filterListView.addSubView @fwRuleFormView
    @filterListView.addSubView @filterListController.getView()

    @ruleListView.addSubView @ruleListController.getView()
    @ruleListView.addSubView new KDButtonView
        title : "Update Rule Orders"

    @filterListController.getListView().on "newRuleCreated", (ruleObj)=>
      @ruleListController.emit "newRuleCreated"

    @ruleListController.getListView().on "ruleDeleted", =>
      @filterListController.refreshFilters()

    @addSubView @ruleListView
    @addSubView @filterListView

  updateActionOrders:(domain)->
    newRulesList = (item.getData() for item in @ruleListController.itemsOrdered)
    domain.updateRuleOrders newRulesList, (err, response)->
      return console.log err if err?
      new KDNotificationView
        title : "Order of your rule list has been successfully updated."
        type  : "top"