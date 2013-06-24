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

    @getListView().setData(data)


  fetchFilters:(callback)->
    {domain} = @getData()

    KD.remote.api.JProxyFilter.fetchFiltersByContext (err, filters)=>
      return callback err if err
      callback null, filters
