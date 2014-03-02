class EnvironmentDomainContainer extends EnvironmentContainer

  EnvironmentDataProvider.addProvider "domains", ->

    new Promise (resolve, reject)->

      KD.remote.api.JDomain.fetchDomains (err, domains)->

        if err or not domains or domains.length is 0
          warn "Failed to fetch domains", err  if err
          return resolve []

        resolve domains

  constructor:(options={}, data)->
    options.cssClass  = 'domains'
    options.itemClass = EnvironmentDomainItem
    options.title     = 'domains'
    super options, data

    # Plus button on domainsContainer opens up the domainCreateModal
    @on 'PlusButtonClicked', =>
      return unless KD.isLoggedIn()
        new KDNotificationView title: "You need to login to add a new domain."

      domainCreateForm = @getDomainCreateForm()

      new KDModalView
        title          : "Add Domain"
        cssClass       : "domain-creation"
        view           : domainCreateForm
        width          : 700
        buttons        :
          createButton :
            title      : "Create"
            style      : "modal-clean-green"
            type       : "button"
            loader     :
              color    : "#1aaf5d"
              diameter : 25
            callback   : =>
              paneType = domainCreateForm.tabView.getActivePane().getOption 'type'

              # @buttons?.createButton.hideLoader()
              # @off  "FormValidationPassed"
              # @once "FormValidationPassed", =>
              #   @emit 'registerDomain'
              #   @buttons?.createButton.showLoader()

              if paneType is "redirect"
                domainCreateForm.handleRedirect()
              else
                domainCreateForm.createSubDomain()

  addDomain: (domain)->

    @addItem
      title       : domain.domain
      description : $.timeago domain.createdAt
      activated   : yes
      aliases     : domain.hostnameAlias
      domain      : domain

  getDomainCreateForm: ->

    domainCreateForm = new DomainCreateForm {}, {stack: @parent.stack}

    @on "itemRemoved", domainCreateForm.bound "updateDomains"
    domainCreateForm.on "DomainSaved", (domain) =>
      @addDomain domain
      @emit "itemAdded"

    return domainCreateForm
