class DomainsListViewController extends KDListViewController

  constructor:(options={}, data)->

    options.itemClass = DomainsListItemView

    super options, data

    @loadItems()

    @on "newDomainCreated", @bound "appendNewDomain"

    @getListView().on "domainsListItemViewClicked", (item)=>
      @emit "domainItemClicked", item

  loadItems:->
    @showLazyLoader()
    KD.whoami().fetchDomains (err, domains) =>
      if err
        @instantiateListItems []
        @hideLazyLoader()
      unless err
        @instantiateListItems domains
        @hideLazyLoader()

  update:->
    @showLazyLoader()
    @removeAllItems()
    @loadItems()

  appendNewDomain:(domainData)=>
    @addItem domainData