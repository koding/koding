class EnvironmentDomainContainer extends EnvironmentContainer

  constructor:(options={}, data)->
    options.cssClass  = 'domains'
    options.itemClass = EnvironmentDomainItem
    options.title     = 'Domains'
    super options, data

    # Plus button on domainsContainer opens up the domainCreateModal
    @on 'PlusButtonClicked', =>
      return unless KD.isLoggedIn()
        new KDNotificationView title: "You need to login to add a new domain."

      domainCreateForm = @getDomainCreateForm()

      new KDModalView
        title          : "Add Domain"
        view           : domainCreateForm
        width          : 700
        buttons        :
          createButton :
            title      : "Create"
            style      : "modal-clean-green"
            callback   : =>
              domainCreateForm.createSubDomain()

  loadItems:->

    KD.whoami().fetchDomains (err, domains)=>

      if err or not domains or domains.length is 0
        @emit "DataLoaded"
        return warn "Failed to fetch domains", err  if err

      @removeAllItems()

      domains.forEach (domain, index)=>

        @addItem
          title       : domain.domain
          description : $.timeago domain.createdAt
          activated   : yes
          aliases     : domain.hostnameAlias
          domain      : domain

        if index is domains.length - 1 then @emit "DataLoaded"

  getDomainCreateForm: ->
    domainCreateForm = new DomainCreateForm
    @on "itemRemoved", domainCreateForm.bound "updateDomains"
    domainCreateForm.on "DomainSaved", @bound "loadItems"
    return domainCreateForm
