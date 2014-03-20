class CloneStackModal extends KDModalView

  constructor: (options = {}, data) ->

    options.overlay  = yes
    options.width    = 720
    options.cssClass = "clone-stack-modal loading"
    options.meta   or= {}

    super options, data

    if data.vms.length # has vm
      @fetchSubscription()
      @createInitialState "<p>Fetching your subscriptions...</p>"
    else
      @createInitialState "<p>Cloning your stack, please wait...</p>"
      @createStack => @destroy()

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
          @askForNewDomainNames domains
          @once "AllDomainsCreated", =>
            @cloneVMs()
        else
          @cloneVMs()

  askForNewDomainNames: (domains) ->
    @loader.destroy()
    @unsetClass "loading"
    @setClass   "domain-names"
    @label.updatePartial """<p class="label">Choose your new domains for your new stack</p>"""

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
      # FIXME: fatihacet - what about group related urls ?
      splitted = domain.title.split "."
      splitted.first = ""  if splitted.first is KD.nick()

      KD.utils.wait 300, => # need to remove this timeout
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
      callback : @bound "cloneDomains"

  cloneDomains: ->
    userDomains = []
    newDomains  = []
    isValidated = yes

    KD.remote.api.JDomain.fetchDomains (err, domains) =>
      # TODO: ERROR CHECK
      userDomains.push domain.domain  for domain in domains

      for form in @domainCreateForms
        {inputs, fields} = form.subdomainForm
        {domainName}     = inputs
        name             = domainName.getValue()
        extension        = fields.domains.getSubViews().last.getValue()
        newDomains.push if name.length then "#{name}.#{extension}" else "#{extension}"

        domainName.unsetClass "validation-error"

      for domainName, index in newDomains
        domainNameInput   = @domainCreateForms[index].subdomainForm.inputs.domainName
        isValid           = KD.utils.subdomainPattern.test domainNameInput.getValue()
        isExists          = userDomains.indexOf(domainName) > -1
        isSameDomainTyped = newDomains.indexOf(domainName) isnt index

        if isExists or isSameDomainTyped or not isValid
          isValidated = no
          domainNameInput.setClass "validation-error"

      createdDomainLength = 0

      if isValidated
        for form, index in @domainCreateForms
          form.createJDomain newDomains[index], (err, domain) =>
            @handleDomainCreationError err  if err
            createdDomainLength++

            if createdDomainLength is newDomains.length
              @emit "AllDomainsCreated"

  cloneVMs: ->
    vmLength = @getData().vms.length

    for [0...vmLength]
      KD.singleton("vmController").createNewVM @stack.getId(), (err) ->
        KD.showError err

  deleteStack: ->
    @destroy()
    @stack.remove()

  createStack: (callback = noop) ->
    KD.remote.api.JStack.createStack @getOptions().meta, (err, @stack) =>
      title = "Failed to create a new stack. Try again later!"
      return new KDNotificationView { title }  if err

      callback()

  handleSubscriptionError: (err) ->
    @loader.destroy()
    @setClass "resource-required"

    if err.message is "quota exceeded"
      @label.updatePartial """
        <p class="subscription-notice">
          You do not have enough resources, you need to buy at least one
          "Resource Pack" to be able to create an extra VM.
        </p>
      """

      @addSubView new KDButtonView
        cssClass  : "buy-packs"
        style     : "solid green medium"
        title     : "Buy Resource Packs"
        callback  : ->
          @destroy()
          KD.singleton("router").handleRoute "/Pricing"
    else
      @label.updatePartial """
        Something went wrong with your process.
        Please try again in a few minutes. Sorry for the inconvenience.
      """

  createInitialState: (partial) ->
    @addSubView @loader = new KDLoaderView showLoader: yes, size : width : 40
    @addSubView @label  = new KDCustomHTMLView { partial }
