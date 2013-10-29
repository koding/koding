class DomainCreationForm extends KDCustomHTMLView

  subDomainPattern = \
    /^([a-z0-9]([_\-](?![_\-])|[a-z0-9]){0,60}[a-z0-9]|[a-z0-9])$/

  # -- Form -- #
  domainOptions = [
    { title : "Create A Subdomain",     value : "subdomain" }
    { title : "Register New Domain",    value : "new"}
    { title : "Use An Existing Domain", value : "existing", disabled : yes }
  ]

  constructor:(options = {})->
    options.cssClass = "environments-add-domain-form"
    super options

    # -- Header -- #
    @addSubView @header = new KDHeaderView
      title             : "Add a domain"

    @header.addSubView new KDButtonView
      cssClass          : "small-gray"
      title             : "Cancel"
      callback          : => @emit 'CloseClicked'

    @addSubView @typeSelector = new KDInputRadioGroup
      name              : "DomainOption"
      radios            : domainOptions
      cssClass          : "domain-option-group"
      defaultValue      : "subdomain"
      change            : (actionType)=>
        # Let's implement a simple state machine ~ GG
        # switch actionType
        #   when 'new'
        #     @createButton.setTitle 'Check availability...'
        #   when 'subdomain'
        #     @createButton.setTitle 'Create Subdomain'

    @addSubView @domainEntryForm = new KDFormViewWithFields
      cssClass          : "new-subdomain-form"
      fields            :
        domainName      :
          name          : "subdomainInput"
          cssClass      : "subdomain-input"
          placeholder   : "Type your subdomain"
          validate      :
            rules       : required : yes
            messages    : required : "Subdomain name is required!"
          nextElement   :
            domains     :
              itemClass : KDSelectBox
              cssClass  : "main-domain-select"

    @addSubView @createButton = new KDButtonView
      title             : "Create Subdomain"
      style             : "cupid-green"
      cssClass          : "add-domain"
      type              : "submit"
      loader            : {color : "#ffffff", diameter : 10}
      callback          : @bound 'registerDomain'

  registerDomain : ->

    {domains, domainName} = @domainEntryForm.inputs
    domainName            = domainName.getValue()
    actionType            = @typeSelector.getValue()

    switch actionType
      when 'new'
        # new domain
        log "Not implemented yet."
      when 'existing'
        # use existing domain
        log "Not implemented yet."
      else # create a subdomain

        # Test given subdomain
        unless subDomainPattern.test domainName
          @createButton.hideLoader()
          return notifyUser "#{domainName} is an invalid subdomain."

        domainName = "#{domainName}.#{domains.getValue()}"
        domainType = 'subdomain'
        regYears   = 0

        @createDomain {domainName, regYears, domainType}, (err, domain)=>
          @createButton.hideLoader()
          if err
            warn "An error occured while creating domain:", err
            if err.code is 11000
              return notifyUser "The domain #{domainName} already exists."
            else if err.name is "INVALIDDOMAIN"
              return notifyUser "#{domainName} is an invalid subdomain."
            return notifyUser "An unknown error occured. Please try again later."
          else
            @showSuccess domain
            @updateDomains()

  createDomain:(params, callback) ->

    KD.remote.api.JDomain.createDomain
      domain         : params.domainName
      regYears       : params.regYears
      proxy          : { mode: 'vm' }
      hostnameAlias  : []
      domainType     : params.domainType
      loadBalancer   : mode : ""
    , callback

  showSuccess:(domain) ->

    {domainName} = @domainEntryForm.inputs
    @emit 'DomainSaved', domain
    @successNote?.destroy()

    @addSubView @successNote = new KDCustomHTMLView
      tagName  : 'p'
      cssClass : 'success'
      partial  : """
        Your subdomain <strong>#{domainName.getValue()}</strong> has been added.
        You can dismiss this panel and point your new domain to one of your VMs
        on the right.
      """
      click    : @bound 'reset'

    KD.utils.wait 7000, @successNote.bound 'destroy'

  notifyUser = (msg) ->
    new KDNotificationView
      type     : 'tray'
      title    : msg
      duration : 5000

  reset:->
    @successNote?.destroy()
    @domainEntryForm.inputs.domainName.setValue ''
    @emit 'CloseClicked'

  updateDomains: ->

    KD.whoami().fetchDomains (err, userDomains)=>
      warn "Failed to update domains:", err  if err
      domainList = []

      for domain in userDomains
        if not domain.regYears > 0
          domainList.push {title:".#{domain.domain}", value:domain.domain}

      {domains, domainName} = @domainEntryForm.inputs

      domainName.setValue ""
      domains.removeSelectOptions()
      domains.setSelectOptions domainList

  viewAppended:->
    @updateDomains()
    KD.getSingleton("vmController").on 'VMListChanged', @bound 'updateDomains'

