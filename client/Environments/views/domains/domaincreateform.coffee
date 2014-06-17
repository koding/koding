class DomainCreateForm extends KDCustomHTMLView

  domainOptions = [
    { title : "Create a subdomain",     value : "subdomain" }
    { title : "Register a new domain",  value : "new", disabled: yes}
    { title : "Use an existing domain", value : "existing", disabled : yes }
  ]

  notifyUser = (msg) ->
    new KDNotificationView
      type     : 'tray'
      title    : msg
      duration : 5000

  constructor:(options = {}, data)->

    options.cssClass = "environments-add-domain-form"

    super options, data

    @addSubView @tabView = new KDTabView
      hideHandleCloseIcons : yes
      maxHandleWidth       : 250

    @tabView.addPane sub = new KDTabPaneView
      name : "Create a subdomain"
      type : "subdomain"
      view : @subdomainForm = new SubdomainCreateForm

    @tabView.addPane dom = new KDTabPaneView
      name               : "Route own domain"
      type               : "redirect"
      view               : @domainForm = new CommonDomainCreateForm
        label            : ""
        placeholder      : "Type your domain name..."
        noDomainSelector : yes

    nickname = KD.whoami().profile.nickname

    dom.addSubView @redirectNotice = (new KDCustomHTMLView
      tagName  : "p"
      cssClass : "status-message"
      partial  : """
        Before adding your domain, you need to create a <strong>CNAME RECORD</strong> pointing to: <strong>#{nickname}.kd.io</strong> or an <br/>
        <strong>A RECORD</strong> which is pointing to: <strong>68.68.97.66</strong>
        Otherwise Koding won't be able to add your domain. <a href="http://learn.koding.com/add-cname-records-to-your-domain/" target="_blank">Learn how</a>
        """
    ), null, yes

    @tabView.showPane sub

    @subdomainForm.on 'registerDomain', @bound 'createSubDomain'
    @tabView.on 'PaneDidShow', => @redirectNotice.unsetClass 'err'
    # @domainForm.on 'registerDomain', @bound 'createDomain'

  handleRedirect:->

    {domains, domainName} = @domainForm.inputs
    {createButton}        = @parent.buttons

    domain = Encoder.XSSEncode domainName.getValue().trim()

    unless KD.utils.domainWithTLDPattern.test domain
      createButton.hideLoader()
      return notifyUser "#{domain} is an invalid domain name"

    @hideError()

    @createJDomain domain, (err, domain)=>
      createButton.hideLoader()
      if err
        @showError err.message
      else
        @showSuccess domain, @domainForm
        @updateDomains()

  createSubDomain: ->

    {domains, domainName} = @subdomainForm.inputs
    {createButton}        = @parent.buttons

    domain = domainName.getValue()

    # Check given subdomain
    unless KD.utils.subdomainPattern.test domain
      createButton.hideLoader()
      return notifyUser "#{domain} is an invalid subdomain."

    domain =
      Encoder.XSSEncode "#{domain}.#{domains.getValue()}"

    @createJDomain domain, (err, domain)=>
      createButton.hideLoader()
      return @handleDomainCreationError err  if err

      @showSuccess domain
      @updateDomains()

  handleDomainCreationError: (err) ->
    warn "An error occured while creating domain:", err
    switch err.name
      when "INVALIDDOMAIN"
        @showError "This is an invalid subdomain.", @subdomainForm
      when "ACCESSDENIED"
        @showError "You do not have permission to create a subdomain in this domain", @subdomainForm
      else
        @showError err.message or "An unknown error occured. Please try again later.", @subdomainForm

  createJDomain:(domain, callback) ->

    {stack} = @getData()
    stack   = stack?._id

    { JDomain } = KD.remote.api
    JDomain.createDomain { domain, stack }, callback

  showSuccess:(domain, view = @subdomainForm) ->

    view.message.unsetClass 'err'

    @emit 'DomainSaved', domain
    view.message.updatePartial """
      Your domain <strong>#{domain.domain}</strong> has been added.
      You can dismiss this modal and point your new domain to one of your VMs.
      """
    view.message.show()

  hideError:(view = @domainForm)->

    view.message.hide()

  showError:(message, view = @domainForm) ->

    view.message.setClass 'err'
    view.message.updatePartial "<strong>#{message}</strong>"
    view.message.show()

  reset:->

    paneType = @tabView.getActivePane().getOption 'type'

    if paneType is 'redirect'
      @domainForm.unsetClass 'err'
      @domainForm.message.hide()
      @domainForm.message.updatePartial ''
      @domainForm.inputs.domainName.setValue ''
    else
      @subdomainForm.message.updatePartial ''
      @subdomainForm.message.hide()
      @subdomainForm.inputs.domainName.setValue ''

    @emit 'CloseClicked'

  updateDomains: ->

    domainList = []
    pushDomainOption = (context) ->
      domain = "#{context}.kd.io"
      domainList.push {title:".#{domain}", value: domain}

    {JDomain} = KD.remote.api
    JDomain.fetchDomains (err, userDomains)=>

      return warn "Failed to update domains:", err  if err

      if userDomains
        for domain in userDomains
          if not domain.regYears > 0
            domainList.push {title:".#{domain.domain}", value:domain.domain}

      group = KD.getSingleton("groupsController").currentGroupName
      # adds group root domain to domain selections
      unless group is "koding"
        pushDomainOption group
      else
        slug = KD.whoami().profile.nickname              # if user domain root does not exist, it is added
        rootDomain = userDomains.filter (domain) ->      # here. actually it is not possible to delete a root
          domain.domain is "#{slug}.kd.io"               # domain, but defensive checks are always good.
        pushDomainOption slug  unless rootDomain.length

      {domains, domainName} = @subdomainForm.inputs
      domainName.setValue ""
      domains.removeSelectOptions()
      domains.setSelectOptions domainList

  viewAppended:->
    @updateDomains()
    KD.getSingleton("vmController").on 'VMListChanged', @bound 'updateDomains'
    @subdomainForm.inputs.domainName.setFocus()
