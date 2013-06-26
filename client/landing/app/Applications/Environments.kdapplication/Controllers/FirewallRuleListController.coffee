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
    @getListView().on "ruleActionChanged", @bound 'refreshProxyRulesList'
    @on "newRuleCreated", @bound 'refreshProxyRulesList'
    @on "itemsFetched", @bound 'itemsFetched'

    @fetchProxyRules()

  fetchProxyRules:->
  	{domain} = @getData()

  	domain.fetchProxyRules (err, ruleList)=>
      return console.log err if err
      if ruleList
        rule.domainName = domain.domain for rule in ruleList
        @instantiateListItems ruleList
      @emit 'itemsFetched'

  refreshProxyRulesList:->
    @removeAllItems()
    @fetchProxyRules()

  itemsFetched:->
    if @itemsOrdered.length is 0
      @getView().updatePartial "You don't have any rules set for this domain."
