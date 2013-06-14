class FirewallActionListController extends KDListViewController

  constructor:(options={}, data)->
    options.itemClass = FirewallActionListItemView
    super options, data

    @getListView().on "moveToIndexRequested", @bound 'moveItemToNewIndex'

   moveItemToNewIndex:(item, index)->
   	@moveItemToIndex item, index