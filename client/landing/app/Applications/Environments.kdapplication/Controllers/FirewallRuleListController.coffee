class FirewallRuleListController extends KDListViewController

  constructor:(options={}, data)->
    options.itemClass       or= FirewallRuleListItemView
    options.showDefaultItem or= yes
    options.defaultItem     or=
      itemClass : EmptyFirewallRuleListItemView
    options.viewOptions     or=
      tagName   : "table"
      type      : "rules"
      partial   :
        """
        <thead>
          <tr>
            <th></th>
            <th>Rule</th>
            <th>Actions</th>
          </tr>
        </thead>
        """
    super options, data

    @getListView().on "moveToIndexRequested", @bound 'moveItemToIndex'
    @getListView().on "ruleActionChanged", @bound 'refreshProxyRulesList'
    @getListView().on "ruleDeleted", (item)=>
      @removeItem item
      @refreshProxyRulesList()
    @on "newRuleCreated", @bound 'refreshProxyRulesList'

    @fetchProxyRules()

  fetchProxyRules:->
  	{domain} = @getData()

  	domain.fetchProxyRules (err, ruleList)=>
      return console.log err if err
      if ruleList
        rule.domainName = domain.domain for rule in ruleList
        @instantiateListItems ruleList

  refreshProxyRulesList:->
    @removeAllItems()
    @fetchProxyRules()
