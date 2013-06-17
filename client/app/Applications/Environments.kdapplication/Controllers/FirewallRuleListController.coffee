class FirewallRuleListController extends KDListViewController

  constructor:(options={}, data)->
    options.itemClass = FirewallRuleListItemView
    super options, data

    @getListView().on "moveToIndexRequested", @bound 'moveItemToIndex'