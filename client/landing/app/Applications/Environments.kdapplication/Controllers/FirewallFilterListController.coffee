class FirewallFilterListController extends KDListViewController

  constructor:(options={}, data)->
    options = $.extend
      itemClass   : FirewallFilterListItemView
      viewOptions : 
        type      : 'filters'
        tagName   : 'table'
        partial   : 
          """
          <thead>
            <tr>
              <th>Filter Name</th>
              <th>Filter Match</th>
              <th>Actions</th>
            </tr>
          </thead>
          """
    , options

    super options, data

    listView = @getListView()
    # set the data so filter items know which domain to work on
    listView.setData(data)

    listView.on "newFilterCreated", @bound 'addItem'

    @fetchFilters()


  fetchFilters:->
    {domain} = @getData()

    KD.remote.api.JProxyFilter.fetchFiltersByContext (err, filters)=>
      domain.fetchProxyRules (err, ruleList)=>
        ruleMatches = Object.keys(ruleList)
        for filter in filters
          if filter.match in ruleMatches
            filter.ruleAction = ruleList[filter.match]
        @instantiateListItems filters
