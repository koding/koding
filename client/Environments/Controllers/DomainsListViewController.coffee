class DomainsListViewController extends KDListViewController

  constructor:(options={}, data)->

    options.itemClass = DomainListItemView

    super options, data

    @loadItems()

    @on "newDomainCreated", @bound "appendNewDomain"

    @getListView().on "domainsListItemViewClicked", (item)=>
      @emit "domainItemClicked", item

    @getListView().on "domainRemoved", (item)=>
      @removeItem item
      @emit "domainItemClicked"

  loadItems:(callback)->
    @showLazyLoader()
    {JDomain} = KD.remote.api
    JDomain.fetchDomains (err, domains) =>
      @instantiateListItems domains or []
      @hideLazyLoader()
      callback?()

  update:(callback)->
    @showLazyLoader()
    @removeAllItems()
    @loadItems callback

  appendNewDomain:(domainData)=>
    @addItem domainData