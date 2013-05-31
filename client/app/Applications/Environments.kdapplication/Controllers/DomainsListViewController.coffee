class DomainsListViewController extends KDListViewController

  constructor:(options={}, data)->
    if options.mapperView?
      @mapperView = options.mapperView
    options.itemClass = DomainsListItemView
    super options, data

    @loadItems()

    @getListView().on "domainsListItemViewClicked", (item)=>
      @deselectAllItems()
      @selectSingleItem item
      @mapperView.update item

  loadItems:->
    KD.remote.api.JDomain.findByAccount {'owner._id':KD.whoami()._id}, (err, domains) =>
      if err
        @instantiateListItems []
      unless err
        @instantiateListItems domains

      @hideLazyLoader()

  update:->
    @showLazyLoader()
    @removeAllItems()
    @loadItems()

  appendItem:(data)=>
    @addItem data