class VMListViewController extends KDListViewController
  
  constructor:(options={}, data)->
    options.itemClass = DomainVMListItemView
    super options, data