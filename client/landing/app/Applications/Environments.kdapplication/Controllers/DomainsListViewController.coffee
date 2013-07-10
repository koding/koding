class DomainsListViewController extends KDListViewController

  constructor:(options={}, data)->

    options.itemClass = DomainListItemView

    super options, data

    @loadItems()

    @on "newDomainCreated", @bound "appendNewDomain"

    @getListView().on "domainsListItemViewClicked", (item)=>
      @emit "domainItemClicked", item

  loadItems:(callback)->
    @showLazyLoader()
    KD.whoami().fetchDomains (err, domains) =>
      @instantiateListItems domains or []
      @hideLazyLoader()
      callback?()

  update:(callback)->
    @showLazyLoader()
    @removeAllItems()
    @loadItems callback

  appendNewDomain:(domainData)=>
    @addItem domainData