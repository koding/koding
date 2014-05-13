class CloneStackModal extends KDModalView

  constructor: (options = {}, data) ->

    options.overlay  = yes
    options.width    = 720
    options.cssClass = "clone-stack-modal loading"
    options.meta   or= {}

    super options, data

    @queue               = []
    @listData            = {}
    @completedTaskLength = 0
    @totalTaskLength     = @getData().vms.length + @getData().domains.length

    if data.vms.length # has vm
      @fetchSubscription()
      @createInitialState "<p>Fetching your subscriptions...</p>"
    else if data.domains.length
      @createStack => @askForNewDomains()
    else
      @createInitialState "<p>Cloning your stack, please wait...</p>"
      @createStack => @handleCloneDone()

  fetchSubscription: ->
    stackData         = @getData()
    options           =
      subscriptionTag : "vm"
      packTag         : "vm"
      multiplyFactor  : stackData.vms.length

    KD.getSingleton("paymentController").canDebitPack options, (err) =>
      return @handleSubscriptionError err  if err

      @createStack =>
        {domains} = stackData
        if domains.length
          @askForNewDomains()
        else
          @addVMsToQueue()
          @processQueue()

  askForNewDomains: ->
    {domains} = @getData()
    @unsetClass "loading"
    @setClass   "domain-names"
    @loader?.destroy()
    @label?.updatePartial """<p class="label">Choose your new domains for your new stack</p>"""

    @domainCreateForms = []
    domains.forEach (domain) =>
      @createDomainCreateForm domain

    @createDomainCreationButtons()

  createDomainCreateForm: (domain) ->
    form  = new DomainCreateForm {}, { @stack }
    input = form.subdomainForm.inputs.domainName
    form.addSubView new KDCustomHTMLView
      tagName  : "span"
      cssClass : "old-name"
      partial  : domain.title
      click    : -> input.setFocus()

    form.addSubView new KDCustomHTMLView
      tagName  : "span"
      cssClass : "icon"
      click    : -> input.setFocus()

    form.once "viewAppended", =>
      splitted = domain.title.split "."
      splitted.first = ""  if splitted.first is KD.nick()

      KD.utils.wait 500, => # need to remove this timeout
        input.setValue "#{splitted.first}-#{@getOptions().meta.slug}"

    @addSubView form
    @domainCreateForms.push form

  createDomainCreationButtons: ->
    @addSubView container = new KDCustomHTMLView
      cssClass : "buttons-container"

    container.addSubView new KDButtonView
      title    : "Cancel"
      cssClass : "solid gray medium"
      callback : @bound "deleteStack"

    container.addSubView new KDButtonView
      title    : "Clone Stack"
      cssClass : "solid green medium"
      callback : @bound "validateDomains"

  validateDomains: ->
    userDomains = []
    @newDomains = []
    isValidated = yes

    KD.remote.api.JDomain.fetchDomains (err, domains) =>
      return @notify "Unable to fetch your domains"  if err

      userDomains.push domain.domain  for domain in domains

      for form in @domainCreateForms
        {inputs, fields} = form.subdomainForm
        {domainName}     = inputs
        name             = domainName.getValue()
        extension        = fields.domains.getSubViews().last.getValue()
        @newDomains.push if name.length then "#{name}.#{extension}" else "#{extension}"

        domainName.unsetClass "validation-error"

      for domainName, index in @newDomains
        domainNameInput   = @domainCreateForms[index].subdomainForm.inputs.domainName
        isValid           = KD.utils.subdomainPattern.test domainNameInput.getValue()
        isExists          = userDomains.indexOf(domainName) > -1
        isSameDomainTyped = @newDomains.indexOf(domainName) isnt index

        if isExists or isSameDomainTyped or not isValid
          isValidated = no
          domainNameInput.setClass "validation-error"

      if isValidated
        @addDomainsToQueue()
        @addVMsToQueue()  if @getData().vms.length
        @processQueue()

  # TODO: fatihacet - DRY addVMsToQueue and addDomainsToQueue
  addDomainsToQueue: ->
    domainList = @listData["Creating Domains"] = []
    {vms, domains} = @getData()

    @domainCreateForms.forEach (form, index) =>
      newName = @newDomains[index]
      domainList.push newName
      @queue.push =>
        KD.remote.api.JDomain.createDomain { domain: newName, stack: @stack.getId() }, (err, res) =>
          if err
            @notify "Unable to create your domain"
            @queue.error()

          @queue.next()
          @progressModal.next()
          @completedTaskLength++
          @handleCloneDone()  if @completedTaskLength is @totalTaskLength

  # TODO: fatihacet - DRY addVMsToQueue and addDomainsToQueue
  addVMsToQueue: ->
    vmList    = @listData["Creating VMs"] = []
    vmNumber  = 0
    {vms, domains} = @getData()

    for [0...vms.length]
      vmList.push "#{++vmNumber}. VM"
      @queue.push =>
        KD.singleton("vmController").createNewVM @stack.getId(), (err) =>
          if err
            @notify "Unable to create your VM"
            @queue.error()

          @queue.next()
          @progressModal.next()
          @completedTaskLength++
          @handleCloneDone()  if @completedTaskLength is @totalTaskLength
        , no

  processQueue: ->
    @destroy()
    @progressModal = new StackProgressModal {}, @listData
    Bongo.daisy @queue

  deleteStack: ->
    @destroy()
    @stack.remove()

  handleCloneDone: ->
    newConfig = @clearConfigValues @getData().config
    @stack.updateConfig newConfig, (err, res) =>
      @emit "StackCloned"
      @progressModal?.destroy()
      @destroy()

  createStack: (callback = noop) ->
    # KD.remote.api.JStack.createStack @getOptions().meta, (err, @stack) =>
    #   return @notify "Failed to create a new stack. Try again later!"  if err

    callback()

  notify: (title, cssClass = "error", duration = 3000, type = "mini") ->
    new KDNotificationView { title, cssClass, duration, type }

  handleSubscriptionError: (err) ->
    @destroy()

    if err.message is "quota exceeded"
      modal      = new KDModalView
        cssClass : "create-vm"
        overlay  : yes

      view = KD.singletons.paymentController.createUpgradeForm modal
      modal.addSubView view
      modal.once "Cancel", -> modal.destroy()
    else
      @label.updatePartial """
        Something went wrong with your process.
        Please try again in a few minutes. Sorry for the inconvenience.
      """

  createInitialState: (partial) ->
    @addSubView @loader = new KDLoaderView showLoader: yes, size : width : 40
    @addSubView @label  = new KDCustomHTMLView { partial }

  # Very basic implementation, should be updated later for requirements
  clearConfigValues: (config) ->
    config    = config.split "\n"
    newConfig = []

    for line in config
        if line.indexOf("=") > -1
            newConfig.push """#{line.slice(0, line.indexOf("="))} = "" """
        else if line.indexOf(":") > -1
            newConfig.push """#{line.slice(0, line.indexOf(":"))} : "" """
        else
            newConfig.push line

    return newConfig.join "\n"
