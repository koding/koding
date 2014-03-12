class EnvironmentsMainScene extends JView

  constructor: (options = {}, data) ->

    options.cssClass = KD.utils.curry 'environment-content', options.cssClass

    super options, data

    @on "NewStackRequested",   @bound "createNewStack"
    @on "CloneStackRequested", @bound "cloneStack"

  viewAppended:->

    @addSubView header = new KDView
      tagName  : 'header'
      partial  : """
        <h1>Environments</h1>
        <div class="content">
          Welcome to Environments.
          Here you can setup your servers and development environment.
        </div>
      """

    freePlanView = new KDView
      cssClass : "top-warning"
      click    : (event) ->
        if "usage" in event.target.classList
          KD.utils.stopDOMEvent event
          new KDNotificationView title: "Coming soon..."

    header.addSubView freePlanView

    paymentControl = KD.getSingleton("paymentController")
    paymentControl.fetchActiveSubscription tags: "vm", (err, subscription) ->
      return warn err  if err
      if not subscription or "nosync" in subscription.tags
        freePlanView.updatePartial """
          You are on a free developer plan,
          see your <a class="usage" href="#">usage</a> or
          <a class="pricing" href="/Pricing">upgrade</a>.
        """

    paymentControl.on "SubscriptionCompleted", ->
      freePlanView.updatePartial ""

    @fetchStacks()

  fetchStacks: (callback)->

    EnvironmentDataProvider.get (@environmentData) =>
      console.clear()
      # log "environment data", @environmentData
      {JStack} = KD.remote.api
      JStack.getStacks (err, stacks)=>
        warn err  if err

        # group = KD.getGroup().title
        # if not stacks or stacks.length is 0
        #   stacks = [{sid:0, group}]

        if not stacks or stacks.length is 0
          meta    =
            title : "Your default stack on Koding"
            slug  : "default"
          JStack.createStack meta, (err, stack) =>
            @createStacks [stack]
        else
          @createStacks stacks

  createStacks: (stacks) ->
    @_stacks = []
    stacks.forEach (stack, index) =>
      stack = new StackView  { stack, isDefault: index is 0 }, @environmentData
      @_stacks.push @addSubView stack
      @forwardEvent stack, "NewStackRequested"
      @forwardEvent stack, "CloneStackRequested"

      callback?()  if index is stacks.length - 1

  createNewStack: (meta, modal) ->
    KD.remote.api.JStack.createStack meta, (err, stack) =>
      title = "Failed to create a new stack. Try again later!"
      return new KDNotificationView { title }  if err
      modal.destroy()

      stackView = new StackView { stack} , @environmentData
      @_stacks.push @addSubView stackView

      stackView.once "transitionend", =>
        stackView.getElement().scrollIntoView()
        KD.utils.wait 300, => # wait for a smooth feedback
          stackView.setClass "hilite"
          stackView.once "transitionend", =>
            stackView.setClass "hilited"

  cloneStack: (stackData) ->
    new CloneStackModal {}, stackData


class CloneStackModal extends KDModalView

  constructor: (options = {}, data) ->

    options.overlay  = yes
    options.width    = 720
    options.cssClass = "clone-stack-modal loading"

    super options, data

    @createInitialState()
    @fetchSubscription()

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
    form = new DomainCreateForm {}, { @stack }
    form.addSubView new KDCustomHTMLView
      tagName  : "span"
      cssClass : "old-name"
      partial  : domain.title
      click    : -> form.subdomainForm.inputs.domainName.setFocus()

    form.addSubView new KDCustomHTMLView
      tagName  : "span"
      cssClass : "icon"
      click    : -> form.subdomainForm.inputs.domainName.setFocus()

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
    KD.remote.api.JStack.createStack {name: "ali"}, (err, @stack) =>
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

  createInitialState: ->
    @addSubView @loader = new KDLoaderView
      showLoader        : yes
      size              :
        width           : 40

    @addSubView @label  = new KDCustomHTMLView
      partial           : "<p>Fetching your subscriptions...</p>"
