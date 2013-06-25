class FirewallRuleListController extends KDListViewController

  constructor:(options={}, data)->
    options = $.extend
      itemClass   : FirewallRuleListItemView
      viewOptions :
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
    , options
    super options, data

    @getListView().on "moveToIndexRequested", @bound 'moveItemToIndex'
    @on "newRuleCreated", @bound 'addItem'

    @fetchProxyRules()

  fetchProxyRules:->
  	{domain} = @getData()

  	domain.fetchProxyRules (err, ruleList)=>
      return console.log err if err
      if ruleList
        rule.domainName = domain.domain for rule in ruleList
        @instantiateListItems ruleList