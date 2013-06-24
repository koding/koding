class FirewallMapperView extends KDView

  constructor:(options={}, data) ->
    data or= {}
    super options, data

    @on "domainChanged", (domainListItem)->
      @getData().domain = domainListItem.data
      @updateViewContent()

    @addSubView new KDCustomHTMLView
      partial: 'Select a domain to continue.'

  updateViewContent:->
    domain = @getData().domain

    @destroySubViews()

    @filterListController = new FirewallFilterListController {}, {domain}
    @filterListController.fetchFilters (err, filters)=>
      if err

        notifyMsg = if err is "not found"
        then "You don't have any filters set for this domain."
        else "An error occured while fetching the filters. Please try again."

        @actionOrdersButton.hide() if err is "not found"
        return new KDNotificationView
          title : notifyMsg
          type  : "top"

      @filterListController.instantiateListItems filters

    @ruleListController = new FirewallRuleListController {}, {domain}
    @ruleListController.fetchProxyRules()

    @addSubView @fwRuleFormView = new FirewallFilterFormView 
      delegate : @filterListController.getListView()
      , {domain}

    @addSubView @filterListView = new KDCustomHTMLView
      partial  : "<h3>Your Filter List</h3>"
      cssClass : 'filter-list-view'

    @addSubView @ruleListView = new KDCustomHTMLView
      partial  : "<h3>Rule List for #{domain.domain}</h3>"
      cssClass : "rule-list-view"

    @filterListView.addSubView @filterListController.getView()

    @ruleListScrollView = new KDScrollView
      cssClass : 'fw-rl-sw'

    @ruleListView.addSubView @ruleListScrollView
    @ruleListView.addSubView @actionOrdersButton = new KDButtonView
      title    : "Update Action Order"
      callback : => @updateActionOrders domain

    @ruleListScrollView.addSubView @ruleListController.getView()

    @filterListController.getListView().on "newFilterCreated", (item) => 
      @filterListController.addItem item

    # this event is on rule list controller because
    # both allow & deny buttons live on FirewallFilterListItemView.
    @filterListController.getListView().on "newRuleCreated", (item) =>
      @ruleListController.addItem item

  updateActionOrders:(domain)->
    newRulesList = (item.getData() for item in @ruleListController.itemsOrdered)
    domain.updateRuleOrders newRulesList, (err, response)->
      return console.log err if err?
      new KDNotificationView
        title : "Order of your rule list has been successfully updated."
        type  : "top"