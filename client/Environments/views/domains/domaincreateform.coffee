class DomainCreateForm extends KDCustomHTMLView

  subDomainPattern = \
    /^([a-z0-9]([_\-](?![_\-])|[a-z0-9]){0,60}[a-z0-9]|[a-z0-9])$/

  domainOptions = [
    { title : "Create a subdomain",     value : "subdomain" }
    { title : "Register a new domain",  value : "new", disabled: yes}
    { title : "Use an existing domain", value : "existing", disabled : yes }
  ]

  constructor:(options = {}, data)->
    options.cssClass = "environments-add-domain-form"
    super options, data

    @addSubView @subDomainEntryForm = new SubdomainCreateForm
    @subDomainEntryForm.on 'registerDomain', @bound 'createSubDomain'

  createSubDomain: ->
    {domains, domainName} = @subDomainEntryForm.inputs
    {createButton}        = @parent.buttons

    domainName = domainName.getValue()

    # Check given subdomain
    unless subDomainPattern.test domainName
      createButton.hideLoader()
      return notifyUser "#{domainName} is an invalid subdomain."

    domainName =
      Encoder.XSSEncode "#{domainName}.#{domains.getValue()}"

    domainType = 'subdomain'
    regYears   = 0

    @createJDomain {domainName, regYears, domainType}, (err, domain)=>
      createButton.hideLoader()
      if err
        warn "An error occured while creating domain:", err
        switch err.name
          when "DUPLICATEDOMAIN"
            return notifyUser "The domain #{domainName} already exists."
          when "INVALIDDOMAIN"
            return notifyUser "#{domainName} is an invalid subdomain."
          when "ACCESSDENIED"
            return notifyUser "You do not have permission to create a subdomain in this domain"
          else
            return notifyUser "An unknown error occured. Please try again later."
      else
        @showSuccess domain
        @updateDomains()

  createJDomain:(params, callback) ->

    { JDomain } = KD.remote.api

    JDomain.createDomain
      domain         : params.domainName
      regYears       : params.regYears
      proxy          : { mode: 'vm' }
      hostnameAlias  : []
      domainType     : params.domainType
      loadBalancer   : mode : ""
    , callback

  showSuccess:(domain) ->
    domainName =
      Encoder.XSSEncode @subDomainEntryForm.inputs.domainName.getValue()

    @emit 'DomainSaved', domain
    @successNote?.destroy()

    @addSubView @successNote = new KDCustomHTMLView
      tagName  : 'p'
      cssClass : 'success'
      partial  : """
        Your subdomain <strong>#{domainName}</strong> has been added.
        You can dismiss this modal and point your new domain to one of your VMs.
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
    for form in [@subDomainEntryForm, @newDomainEntryForm]
      form.inputs?.domainName.setValue ''
    @emit 'CloseClicked'

  updateDomains: ->

    KD.whoami().fetchDomains (err, userDomains)=>
      warn "Failed to update domains:", err  if err
      domainList = []

      if userDomains
        for domain in userDomains
          if not domain.regYears > 0
            domainList.push {title:".#{domain.domain}", value:domain.domain}

      {domains, domainName} = @subDomainEntryForm.inputs

      domainName.setValue ""
      domains.removeSelectOptions()
      domains.setSelectOptions domainList

  viewAppended:->
    @updateDomains()
    KD.getSingleton("vmController").on 'VMListChanged', @bound 'updateDomains'
    @subDomainEntryForm.inputs.domainName.setFocus()
