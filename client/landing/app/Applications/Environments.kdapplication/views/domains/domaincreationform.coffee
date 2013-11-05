class DomainCreationForm extends KDCustomHTMLView

  subDomainPattern = \
    /^([a-z0-9]([_\-](?![_\-])|[a-z0-9]){0,60}[a-z0-9]|[a-z0-9])$/

  domainOptions = [
    { title : "Create a subdomain",     value : "subdomain" }
    { title : "Register a new domain",    value : "new"}
    { title : "Use an existing domain", value : "existing", disabled : yes }
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
    {message}             = @newDomainEntryForm
    {createButton}        = @newDomainEntryForm.buttons
    {domains, domainName} = @newDomainEntryForm.inputs
    domainName            = "#{domainName.getValue()}.#{domains.getValue()}"
    {getDomainInfo, getDomainSuggestions} = KD.remote.api.JDomain

    @newDomainEntryForm.domainListView?.unsetClass 'in'

    # Maybe a CSS hero can remove these br with some alternative styles ~GG
    message.updatePartial "<br/> Checking for availability..."
    message.setClass 'in'

    getDomainInfo domainName, (err, status)=>

      if err
        createButton.hideLoader()
        message.updatePartial "<br/> Please just provide domain name."
        return warn err

      if status.available
        @newDomainEntryForm.setAvailableDomainsData \
          [{domain:domainName, price:status.price}]
        createButton.hideLoader()
        message.updatePartial "<br/> Yay it's available!"
      else
        message.updatePartial "<br/> Checking for alternatives..."
        getDomainSuggestions domainName, (err, suggestions)=>
          createButton.hideLoader()
          return warn err if err
          result = "Sorry, <b>#{domainName}</b> is taken,"
          if suggestions.length is 1
            result = "#{result}<br/>but we found an alternative:"
          else if suggestions.length > 1
            result = "#{result}<br/>but we found following alternatives:"
          else
            result = "#{result}<br/>and we couldn't find any alternative."
          message.updatePartial result
          @newDomainEntryForm.setAvailableDomainsData suggestions

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
      cssClass              : KD.utils.curry "new-domain-form",options.cssClass
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

    @addSubView @message = new KDCustomHTMLView
      cssClass : 'status-message'

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
    , data

    @availableDomainsList = new KDListViewController
      itemClass : DomainBuyItem

    @domainListView = @availableDomainsList.getView()
                      .setClass 'domain-list'

    listView = @availableDomainsList.getListView()
    listView.on 'BuyButtonClicked', (item)->
      {price, domain} = item.getData()
      year  =  item.yearBox.getValue()
      price = (year * price).toFixed 2
      new BuyDomainApprovalDialog {}, {domain, year, price}

  viewAppended:->
    tldList = []
    KD.remote.api.JDomain.getTldList (tlds)=>
      for tld in tlds
        tldList.push {title:".#{tld}", value: tld}
      @inputs.domains.setSelectOptions tldList
    @addSubView @domainListView

  setAvailableDomainsData:(domains)->
    @availableDomainsList.replaceAllItems domains
    @utils.defer => @domainListView.setClass 'in'

class DomainBuyItem extends KDListItemView

  constructor:(options={}, data)->
    options.cssClass = KD.utils.curry "domain-buy-items", options.cssClass

    data.price = (parseFloat data.price).toFixed 2
    super options, data

    selectOptions = \
      ({title: "#{i} year for $#{(@getData().price * i).toFixed 2}", \
        value: i} for i in [1..5])

    @yearBox = new KDSelectBox {name:'year', selectOptions}

    @buyButton = new KDButtonView
      title    : "Buy"
      style    : "clean-gray"
      callback : => @parent.emit 'BuyButtonClicked', this

  viewAppended: ->
    JView::viewAppended.call this

  pistachio:->
    """
      {h1{#(domain)}}
      {{> @yearBox}}
      {{> @buyButton}}
    """

class BuyDomainApprovalDialog extends KDModalView

  constructor:(options={}, data)->

    data.year = parseInt data.year, 10
    s = if data.year > 1 then 's' else ''

    super
      cssClass      : KD.utils.curry "modal-with-text", options.cssClass
      title         : "Do you want to buy #{data.domain} for #{data.year} year#{s} ?"
      content       : """
        <div class='modalformline'>
          <p>You will be charged <b>$#{data.price}</b> for registering
          <b>#{data.domain}</b> domain for <b>#{data.year}</b> year#{s}.</p>
        </div>
      """
      overlay       : yes
      buttons       :
        Buy         :
          cssClass  : "modal-clean-green"
          callback  : =>
            {registerDomain} = KD.remote.api.JDomain
            log 'Buying....', @getData()
            registerDomain @getData(), (err)=>
              log "Register result:", err
              @destroy()

        "Cancel"    :
          cssClass  : "modal-cancel"
          title     : "Cancel"
          callback  : => @destroy()
    , data
