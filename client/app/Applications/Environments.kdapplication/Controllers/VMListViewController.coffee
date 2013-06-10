class VMListViewController extends KDListViewController
  
  constructor:(options={}, data)->
    options.itemClass = VMListItemView
    super options, data