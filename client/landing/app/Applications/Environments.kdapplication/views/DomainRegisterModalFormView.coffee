class DomainForwardForm extends KDView

  constructor:(options={}, data)->
    super options, data

    @header = new KDHeaderView
      type  : "small"
      title : "Forward My Domain"

    @forwardForm = new KDFormViewWithFields
      callback          : @bound "saveDomain"
      buttons           :
        Forward         :
          type          : "submit"
          loader        :
            color       : "#444444"
            diameter    : 12

      fields            :
          domainName    :
            label       : "Enter your domain name"
            placeholder : "Domain (e.g. example.com)"
            validate    :
              rules     :
                required: yes
              messages  :
                requires: "Enter your domain name"

  saveDomain:->
    modalTabs = @getOptions().modalTabs
    domainName = @forwardForm.inputs.domainName.getValue()

    KD.remote.api.JDomain.createDomain
      domain         : domainName
      regYears       : 0
      hostnameAlias  : []
      loadBalancer   :
          mode       : "roundrobin"
    , (err, domain)=>
      unless err
        modalTabs.parent.emit "DomainForwarded", {domainName}
      console.log err


  pistachio:->
    """
    {{> @header}}
    {{> @forwardForm}}
    """

  viewAppended: JView::viewAppended


class DomainRegistrationCompleteView extends JView

  constructor:(options = {}, data)->
    super options,data

    {orderInfo} = @getOptions()

    @header  = new KDHeaderView
      type  : "Small"
      title : "Domain Registration Complete"

    @content = new KDView
      partial : """
      <div class = "hate-that-css-stuff">
        Your #{orderInfo.domainName} domain has been successfully registered.
        You can select your domain from the left panel and connect it to any VM
        listed on the right panel.
      </div>
      """

  pistachio:->
    """
    {{> @header}}
    {{> @content}}
    """

class DomainSettingsModalForm extends KDModalViewWithForms

  constructor : (options = {}, data) ->

    options = {
      title                             : "Domain Settings"
      overlay                           : no
      width                             : 600
      height                            : "auto"
      cssClass                          : "domain-settings-modal-view"
      tabs                              :
        navigable                       : yes
        goToNextFormOnSubmit            : no
        forms                           :
          "Domain Information"          :
            fields                      :
              DomainOption              :
                name                    : "DomainOption"
                label                   : "Created at"
                type                    : "text"
                defaultValue            : "2012/12/12"
                disabled                : yes
                partial                 : =>"asdasd"

          "Domain Contact Information"  :
            buttons                     : null
            fields                      : {}

          "DNS Management"              :
            buttons                     : null
            fields                      : {}

          "Statitics"                   :
            buttons                     : null
            fields                      : {}
    }

    super options, data




class DomainCreationForm extends KDTabViewWithForms

  constructor:->

    {nickname, firstName, lastName} = KD.whoami().profile

    paymentController = KD.getSingleton('paymentController')
    group             = KD.getSingleton("groupsController").getCurrentGroup()
    domainOptions     = [
      { title : "Create a #{nickname}.kd.io subdomain", value : "subdomain" }
      { title : "I want to register a domain",          value : "new" }
      { title : "I already have a domain",              value : "existing" }
    ]

    super
      navigable                       : no
      goToNextFormOnSubmit            : no
      hideHandleContainer             : yes
      forms                           :
        "Domain Address"              :
          buttons                     :
            billingButton             :
              title                   : "Billing Info"
              style                   : "cupid-green hidden"
              type                    : "submit"
              loader                  :
                color                 : "#ffffff"
                diameter              : 24
              callback                : =>
                form = @forms["Domain Address"]
                {createButton, billingButton} = form.buttons

                billingButton.hideLoader()

                paymentController.setBillingInfo 'user', group, (success)->
                  if success
                    billingButton.hide()
                    createButton.show()

            createButton              :
              title                   : "Add Domain"
              style                   : "cupid-green"
              type                    : "submit"
              loader                  :
                color                 : "#ffffff"
                diameter              : 24
              callback                : @bound "registerDomain"
            close                     :
              title                   : "Close"
              style                   : "cupid-green hidden"
              callback                : => @reset()
            cancel                    :
              style                   : "modal-cancel"
              callback                : => @emit 'DomainCreationCancelled'
          fields                      :
            header                    :
              title                   : "Add a domain"
              itemClass               : KDHeaderView
            DomainOption              :
              name                    : "DomainOption"
              itemClass               : KDRadioGroup
              cssClass                : "group-type"
              defaultValue            : "subdomain"
              radios                  : domainOptions
              change                  : =>
                {DomainOption, domainName, domains, regYears} = @forms["Domain Address"].inputs
                actionState = DomainOption.getValue()
                domainName.getElement().setAttribute 'placeholder', switch actionState
                  when "new"
                    @suggestionBox?.show()
                    domains.hide()
                    regYears.show()
                    @needBilling yes
                    "#{KD.utils.slugify firstName}s-new-domain.com"
                  when "existing"
                    @suggestionBox?.hide()
                    domains.hide()
                    regYears.hide()
                    @needBilling no
                    "#{KD.utils.slugify firstName}s-existing-domain.com"
                  when "subdomain"
                    @suggestionBox?.hide()
                    domains.show()
                    regYears.hide()
                    @needBilling no
                    "#{KD.utils.slugify firstName}s-subdomain"


            domainName                :
              placeholder             : "#{KD.utils.slugify firstName}s-new-domain.com"
              validate                :
                rules                 :
                  required            : yes
                  regExp              : /^([\da-z\.-]+)\.([a-z\.]{2,6})$/i
                messages              :
                  required            : "Enter your domain name"
                  regExp              : "This doesn't look like a valid domain name."
              nextElement             :
                regYears              :
                  cssClass            : "hidden"
                  itemClass           : KDSelectBox
                  selectOptions       : ({title: "#{i} Year#{if i > 1 then 's' else ''}", value:i} for i in [1..10])
                domains               :
                  cssClass            : "hidden"
                  itemClass           : KDSelectBox
                  validate            :
                    rules             :
                      required        : yes
                    messages          :
                      requires        : "Enter your domain name"
            suggestionBox             :
              type                    : "hidden"

    form = @forms["Domain Address"]
    {createButton} = form.buttons

    form.on "FormValidationFailed", createButton.bound 'hideLoader'
    @on "DomainCreationCancelled", createButton.bound 'hideLoader'

  viewAppended:->
    KD.whoami().fetchDomains (err, userDomains)=>
      warn err  if err
      domainList = []
      for domain in userDomains
        domainList.push {title:domain.domain, value:domain.domain}  unless domain.regYears > 0
      @forms["Domain Address"].inputs.domains.setSelectOptions domainList

  needBilling:(paymentRequired)->
    form = @forms["Domain Address"]
    {createButton, billingButton} = form.buttons

    unless paymentRequired
      createButton.show()
      billingButton.hide()
      return

    paymentController = KD.getSingleton('paymentController')
    group             = KD.getSingleton("groupsController").getCurrentGroup()

    paymentController.getBillingInfo 'user', group, (err, account)->
      need = err or not account or not account.cardNumber
      if need
        billingButton.show()
        createButton.hide()
      else
        createButton.show()
        billingButton.hide()

  registerDomain:->
    form = @forms["Domain Address"]
    {createButton} = form.buttons
    @clearSuggestions()

    {DomainOption, domainName, regYears} = form.inputs
    splittedDomain    = domainName.getValue().split "."
    domain            = splittedDomain.first
    tld               = splittedDomain.slice(1).join('')

    domainOptionValue = DomainOption.getValue()

    if domainOptionValue is 'new'
      KD.remote.api.JDomain.isDomainAvailable domain, tld, (avErr, status, suggestions)=>

        if avErr
          createButton.hideLoader()
          return notifyUser "An error occured: #{avErr}"

        switch status
          when "regthroughus", "regthroughothers"
            @showSuggestions suggestions
            return createButton.hideLoader()
          when "unknown"
            notifyUser "An error occured. Please try again later."
            return createButton.hideLoader()

        KD.remote.api.JDomain.registerDomain
          domainName : domainName.getValue()
          years      : regYears.getValue()
        , (err, domain)=>
          createButton.hideLoader()
          if err
            warn err
            notifyUser "An error occured. Please try again later."
          else
            @showSuccess()
            domain.setDomainCNameToProxyDomain()

    else if domainOptionValue is 'existing'
      KD.remote.api.JDomain.createDomain
        domain         : domainName.getValue()
        regYears       : 0
        hostnameAlias  : []
        loadBalancer   :
            mode       : "roundrobin"
      , (err, domain)=>
        createButton.hideLoader()
        if err
          warn err
          return notifyUser "An error occured. Please try again later."
        else
          @showSuccess()
    else if domainOptionValue is 'subdomain'
      KD.remote.api.JDomain.createDomain
        domain         : domainName.getValue()
        regYears       : 0
        hostnameAlias  : []
        loadBalancer   :
            mode       : "roundrobin"
      , (err, domain)=>
        createButton.hideLoader()
        if err
          warn err
          return notifyUser "An error occured. Please try again later."
        else
          @showSuccess()

    else # groupSubDomain



  clearSuggestions:-> @suggestionBox?.destroy()

  showSuggestions:(suggestions)->
    @clearSuggestions()

    form            = @forms["Domain Address"]
    {domainName}    = form.inputs
    {suggestionBox} = form.fields
    partial         = "<p>This domain is already registered. You may click and try one below.</p>"

    for domain, variants of suggestions
      for variant, status of variants when status is "available"
        partial += "<li class='#{variant}'>#{domain}.#{variant}</li>"

    suggestionBox.addSubView @suggestionBox = new KDCustomHTMLView
      tagName : 'ul'
      cssClass: 'suggestion-box'
      partial : partial
      click   : (event)->
        domainName.setValue $(event.target).closest('li').text()

  showSuccess:->
    @clearSuggestions()
    form            = @forms["Domain Address"]
    {domainName}    = form.inputs
    {suggestionBox} = form.fields
    {close, createButton, cancel} = form.buttons

    close.show()
    createButton.hide()
    cancel.hide()

    @emit 'DomainSaved'

    suggestionBox.addSubView @successNote = new KDCustomHTMLView
      tagName : 'p'
      cssClass: 'success'
      # the following partial will vary depending on the DomainOption value.
      # Users who registered a domain through us won't need this change.
      partial : "<b>Thank you!</b><br>Your domain #{domainName.getValue()} has been added to our database. Please go to your provider's website and add a CNAME record mapping to kontrol.in.koding.com."
      click   : => @reset()


  reset:->
    form            = @forms["Domain Address"]
    {domainName}    = form.inputs
    {suggestionBox} = form.fields
    {close, createButton, cancel} = form.buttons

    close.hide()
    createButton.show()
    cancel.show()
    @successNote.destroy()
    delete @successNote
    domainName.setValue ''
    @emit 'CloseClicked'


  notifyUser = (msg)->
    new KDNotificationView
      type     : 'tray'
      title    : msg
      duration : 5000