class DomainCreationForm extends KDCustomHTMLView

  subDomainPattern = \
    /^([a-z0-9]([_\-](?![_\-])|[a-z0-9]){0,60}[a-z0-9]|[a-z0-9])$/

  domainOptions = [
    { title : "Create A Subdomain",     value : "subdomain" }
    { title : "Register New Domain",    value : "new"}
    { title : "Use An Existing Domain", value : "existing", disabled : yes }
  ]

  constructor:(options = {}, data)->
    options.cssClass = "environments-add-domain-form"
    super options, data

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
        @successNote?.destroy()
        switch actionType
          when 'new'
            @tabs.showPaneByName 'NewDomain'
            @newDomainEntryForm.inputs.domainName.setFocus()
          when 'subdomain'
            @tabs.showPaneByName 'SubDomain'
            @subDomainEntryForm.inputs.domainName.setFocus()

    @addSubView @tabs = new KDTabView
      cssClass            : 'domain-tabs'
      hideHandleContainer : yes

    @newDomainPane = new KDTabPaneView { name : "NewDomain" }
    @newDomainPane.addSubView @newDomainEntryForm = new DomainBuyForm
    @tabs.addPane @newDomainPane
    @newDomainEntryForm.on 'registerDomain', @bound 'checkDomainAvailability'

    @subDomainPane = new KDTabPaneView { name : "SubDomain" }
    @subDomainPane.addSubView @subDomainEntryForm = new SubDomainCreateForm
    @subDomainEntryForm.on 'registerDomain', @bound 'createSubDomain'
    @tabs.addPane @subDomainPane

  checkDomainAvailability: ->
    {createButton}        = @newDomainEntryForm.buttons
    {domains, domainName} = @newDomainEntryForm.inputs
    domainName            = "#{domainName.getValue()}.#{domains.getValue()}"
    {getDomainInfo, getDomainSuggestions} = KD.remote.api.JDomain

    getDomainInfo domainName, (err, status)=>

      if err
        createButton.hideLoader()
        return warn err

      if status.available
        @newDomainEntryForm.setAvailableDomainsData \
          [{domain:domainName, price:status.price}]
        createButton.hideLoader()
      else
        @newDomainEntryForm.domainList?.destroy?()
        getDomainSuggestions domainName, (err, suggestions)=>
          createButton.hideLoader()
          return warn err if err
          @newDomainEntryForm.setAvailableDomainsData suggestions

      new KDNotificationView
        title: if status.available then 'Yay its available' else 'Sorry dude.'

  createSubDomain: ->
    {domains, domainName} = @subDomainEntryForm.inputs
    {createButton}        = @subDomainEntryForm.buttons
    domainName            = domainName.getValue()

    # Check given subdomain
    unless subDomainPattern.test domainName
      createButton.hideLoader()
      return notifyUser "#{domainName} is an invalid subdomain."

    domainName = "#{domainName}.#{domains.getValue()}"
    domainType = 'subdomain'
    regYears   = 0

    @createJDomain {domainName, regYears, domainType}, (err, domain)=>
      createButton.hideLoader()
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

  createJDomain:(params, callback) ->

    KD.remote.api.JDomain.createDomain
      domain         : params.domainName
      regYears       : params.regYears
      proxy          : { mode: 'vm' }
      hostnameAlias  : []
      domainType     : params.domainType
      loadBalancer   : mode : ""
    , callback

  showSuccess:(domain) ->

    {domainName} = @subDomainEntryForm.inputs
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
    for form in [@subDomainEntryForm, @newDomainEntryForm]
      form.inputs.domainName.setValue ''
    @emit 'CloseClicked'

  updateDomains: ->

    KD.whoami().fetchDomains (err, userDomains)=>
      warn "Failed to update domains:", err  if err
      domainList = []

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

class CommonDomainCreationForm extends KDFormViewWithFields
  constructor:(options = {}, data)->
    super
      cssClass              : KD.utils.curry "new-domain-form", options.cssClass
      fields                :
        domainName          :
          name              : "domainInput"
          cssClass          : "domain-input"
          placeholder       : options.placeholder or "Type your domain"
          validate          :
            rules           : required : yes
            messages        : required : "A domain name is required"
          nextElement       :
            domains         :
              itemClass     : KDSelectBox
              cssClass      : "main-domain-select"
              selectOptions : options.selectOptions
      buttons               :
        createButton        :
          name              : "createButton"
          title             : options.buttonTitle or "Check availability"
          style             : "cupid-green"
          cssClass          : "add-domain"
          type              : "submit"
          loader            : {color : "#ffffff", diameter : 10}
      , data

    if options.createButtonAnimated
      # Add working animations for create button
      @buttons.createButton.showLoader = ->
        KDButtonView::showLoader.call this
        @setClass 'working'

      @buttons.createButton.hideLoader = ->
        KDButtonView::hideLoader.call this
        @unsetClass 'working'

  submit:->
    @buttons.createButton.hideLoader()
    @off  "FormValidationPassed"
    @once "FormValidationPassed", =>
      @emit 'registerDomain'
      @buttons.createButton.showLoader()
    super

class SubDomainCreateForm extends CommonDomainCreationForm
  constructor:(options = {}, data)->
    super
      placeholder : "Type your subdomain..."
      buttonTitle : "Create Subdomain"
    , data

class DomainBuyForm extends CommonDomainCreationForm
  constructor:(options = {}, data)->
    super
      placeholder : "Type your awesome domain..."
      createButtonAnimated : yes
    , data

    @domainList = null

  viewAppended:->
    tldList = []
    KD.remote.api.JDomain.getTldList (tlds)=>
      for tld in tlds
        tldList.push {title:".#{tld}", value: tld}
      @inputs.domains.setSelectOptions tldList

  setAvailableDomainsData:(domains)->
    @domainList?.destroy?()

    @domainList = new KDView cssClass:'domain-list'
    @addSubView @domainList

    for domain in domains
      @domainList.addSubView new DomainBuyItem {}, domain

class DomainBuyItem extends JView

  constructor:(options={}, data)->
    options.cssClass = KD.utils.curry "domain-buy-items", options.cssClass
    super options, data

  pistachio:->
    """
      {h1#domain{#(domain)}}
      {{#(price)}}
    """