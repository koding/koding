class FirewallRuleListController extends KDListViewController

  constructor:(options={}, data)->
    options.itemClass = FirewallRuleListItemView
    super options, data

    @getListView().on "moveToIndexRequested", @bound 'moveItemToIndex'

  fetchProxyRules:->
  	{domain} = @getData()

  	domain.fetchProxyRules (err, ruleList)=>
      return console.log err if err
      if ruleList
        for rule in ruleList
          rule.domainName = domain.domain
        @instantiateListItems ruleList