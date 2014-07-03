class EnvironmentDomainContainer extends EnvironmentContainer

  # EnvironmentDataProvider.addProvider "domains", ->

  #   new Promise (resolve, reject)->

  #     KD.remote.api.JDomain.fetchDomains (err, domains)->
  #       if err or not domains or domains.length is 0
  #         warn "Failed to fetch domains", err  if err
  #         return resolve []

  #       resolve domains

  constructor: (options = {}, data) ->

    options     =
      title     : 'domains'
      cssClass  : 'domains'
      itemClass : EnvironmentDomainItem

    super options, data

    @stack = @getData()

    # Plus button on domainsContainer opens up the domainCreateModal
    @on 'PlusButtonClicked', =>
      return unless KD.isLoggedIn()
        new KDNotificationView title: "You need to login to add a new domain."

      domainCreateForm = @getDomainCreateForm()

      @domainCreateModal = new KDModalView
        title          : "Add Domain"
        cssClass       : "domain-creation"
        view           : domainCreateForm
        width          : 600
        overlay        : yes
        buttons        :
          createButton :
            title      : "Create"
            style      : "modal-clean-green"
            type       : "button"
            loader     :
              color    : "#1aaf5d"
            callback   : =>
              paneType = domainCreateForm.tabView.getActivePane().getOption 'type'

              if paneType is "redirect"
                domainCreateForm.handleRedirect()
              else
                domainCreateForm.createSubDomain()

  addDomain: (domain) ->

    @addItem
      title       : domain.proposedDomain
      description : $.timeago domain.meta.createdAt
      activated   : yes
      machines    : domain.machines
      domain      : domain

  getDomainCreateForm: ->

    domainCreateForm = new DomainCreateForm {}, { @stack }

    @on "itemRemoved", domainCreateForm.bound "updateDomains"
    domainCreateForm.on "DomainSaved", (domain) =>
      @addDomain domain
      @emit "itemAdded"
      @domainCreateModal.destroy()

    return domainCreateForm
