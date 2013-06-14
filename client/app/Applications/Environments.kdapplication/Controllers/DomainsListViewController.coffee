class DomainsListViewController extends KDListViewController

  constructor:(options={}, data)->
    options.itemClass = DomainsListItemView
    super options, data

    @loadItems()

    @on "newDomainCreated", @bound "appendNewDomain"

    @getListView().on "domainsListItemViewClicked", (item)=>
      @emit "domainItemClicked", item

  loadItems:->
    KD.remote.api.JDomain.findByAccount {owner:KD.whoami().getId()}, (err, domains) =>
      if err
        @instantiateListItems []
      unless err
        @instantiateListItems domains

      @hideLazyLoader()

  update:->
    @showLazyLoader()
    @removeAllItems()
    @loadItems()

  appendNewDomain:(domainData)=>
    @addItem domainData