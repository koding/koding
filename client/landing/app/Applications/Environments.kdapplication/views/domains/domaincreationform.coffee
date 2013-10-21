class DomainCreationForm extends KDCustomHTMLView

  constructor:(options = {})->
    options.cssClass = "environments-add-domain-form"

    super options

    {firstName} = KD.whoami().profile

    # -- Header -- #
    @addSubView @header = new KDHeaderView
      title       : "Add a domain"

    @header.addSubView new KDButtonView
      cssClass    : "small-gray"
      title       : "Cancel"
      callback    : => @emit 'CloseClicked'

    # -- Form -- #
    domainOptions = [
      { title : "Create A Subdomain", value : "subdomain" }
      { title : "Register New Domain", value : "new", disabled : yes }
      { title : "Use An Existing Domain", value : "existing", disabled : yes }
    ]

    @addSubView @form = new KDFormViewWithFields
      cssClass              : "main-form"
      fields                :
        domainOption        :
          name              : "DomainOption"
          itemClass         : KDInputRadioGroup
          cssClass          : "domain-option-group"
          defaultValue      : "subdomain"
          radios            : domainOptions
        domainName          :
          name              : "subdomainInput"
          cssClass          : "subdomain-input"
          placeholder       : "Type your subdomain"
          validate          :
            rules           :
              required      : yes
            messages        :
              required      : "Subdomain name is required!"
          nextElement       :
            domains         :
              itemClass     : KDSelectBox
              cssClass      : "main-domain-select"
      buttons               :
        createButton        :
          title             : "Add Domain"
          style             : "cupid-green"
          cssClass          : "add-domain"
          type              : "submit"
          loader            :
            color           : "#ffffff"
            diameter        : 10
          callback          : (event) => @registerDomain event

  registerDomain : (event) ->

    KD.utils.stopDOMEvent event

    form           = @form
    {createButton} = form.buttons

    {domainOption, domainName, domains} = form.inputs
    domainInput       = domainName
    domainName        = form.inputs.domainName.getValue()

    domainOptionValue = domainOption.getValue()

    if domainOptionValue is 'new'
      # new domain

    else if domainOptionValue is 'existing'
      # use existing domain

    else # create a subdomain
      subDomainPattern = /^([a-z0-9]([_\-](?![_\-])|[a-z0-9]){0,60}[a-z0-9]|[a-z0-9])$/
      unless subDomainPattern.test domainName
        createButton.hideLoader()
        return notifyUser "#{domainName} is an invalid subdomain."
      domainName = "#{domainName}.#{domains.getValue()}"

      @createDomain {domainName, regYears:0, domainType:'subdomain'}, (err, domain)=>
        createButton.hideLoader()
        if err
          warn err
          if err.message?.indexOf("duplicate key error") isnt -1
            return notifyUser "The domain #{domainName} already exists."
          else if err.name is "INVALIDDOMAIN"
            return notifyUser "#{domainName} is an invalid subdomain."
          return notifyUser "An error occured. Please try again later."
        else
          @showSuccess domain
          @updateDomains()

  createDomain:(params, callback) ->
    # log params

    KD.remote.api.JDomain.createDomain
      domain         : params.domainName
      regYears       : params.regYears
      proxy          : { mode: 'vm' }
      hostnameAlias  : []
      domainType     : params.domainType
      loadBalancer   :
        mode         : ""
    , (err, domain)=>
      callback err, domain

  showSuccess:(domain) ->

    form = @form
    {domainName}   = form.inputs
    {createButton} = form.buttons

    @emit 'DomainSaved', domain

    @successNote?.destroy()
    delete @successNote?

    @addSubView @successNote = new KDCustomHTMLView
      tagName : 'p'
      cssClass: 'success'
      partial : "Your subdomain <strong>#{domainName.getValue()}</strong> has been added. You can dismiss this panel and point your new domain to one of your VMs on the right."
      click   : => @reset()

    KD.utils.wait 7000, =>
      @successNote.destroy()

  notifyUser = (msg) ->
    new KDNotificationView
      type     : 'tray'
      title    : msg
      duration : 5000

  reset:->
    form            = @form
    {domainName}    = form.inputs
    {createButton}  = form.buttons

    @successNote?.destroy()
    delete @successNote?
    domainName.setValue ""
    @emit 'CloseClicked'

  updateDomains: ->
    KD.whoami().fetchDomains (err, userDomains)=>
      warn err  if err
      domainList = []
      for domain in userDomains
        if not domain.regYears > 0
          domainList.push {title:".#{domain.domain}", value:domain.domain}
      {domains, domainName} = @form.inputs
      domainName.setValue ""
      domains.removeSelectOptions()
      domains.setSelectOptions domainList

  viewAppended:->
    @updateDomains()
    KD.getSingleton("vmController").on 'VMListChanged', @bound 'updateDomains'

# splitDomain = (domainName) ->
#   splitted =  domainName.split "."
#   return {
#     first: splitted[0],
#     extension: if splitted.length > 1 then splitted[1..].join "." else ""
#   }

# class DomainCreationForm extends KDTabViewWithForms

#   domainOptions = [
#       { title : "Create a subdomain", value : "subdomain" }
#       { title : "I want to register a domain", value : "new" }
#       { title : "I already have a domain", value : "existing" }
#     ]

#   constructor:->

#     {nickname, firstName, lastName} = KD.whoami().profile

#     super
#       navigable                       : no
#       goToNextFormOnSubmit            : no
#       hideHandleContainer             : yes
#       forms                           :
#         "Domain Address"              :
#           callback                    : ->
#           buttons                     :
#             registerButton            :
#               title                   : "Register Domain"
#               style                   : "cupid-green hidden"
#               type                    : "submit"
#               loader                  :
#                 color                 : "#ffffff"
#                 diameter              : 24
#               callback                : =>
#                 @registerDomain()
#             createButton              :
#               title                   : "Add Domain"
#               style                   : "cupid-green"
#               type                    : "submit"
#               loader                  :
#                 color                 : "#ffffff"
#                 diameter              : 24
#               callback                : =>
#                 @registerDomain()
#             checkButton              :
#               title                   : "Check Domain"
#               style                   : "cupid-green hidden"
#               type                    : "submit"
#               loader                  :
#                 color                 : "#ffffff"
#                 diameter              : 24
#               callback                : =>
#                 @checkAvailability()

#             close                     :
#               title                   : "Back to settings"
#               style                   : "cupid-green hidden"
#               callback                : => @reset()
#             cancel                    :
#               style                   : "cupid-green"
#               callback                : => @emit 'DomainCreationCancelled'
#             another                   :
#               title                   : "add another domain"
#               style                   : "modal-cancel hidden"
#               callback                : => @addAnotherDomainClicked()

#           fields                      :
#             header                    :
#               title                   : "Add a domain"
#               itemClass               : KDHeaderView
#             DomainOption              :
#               name                    : "DomainOption"
#               itemClass               : KDRadioGroup
#               cssClass                : "group-type"
#               defaultValue            : "subdomain"
#               radios                  : domainOptions
#               change                  : =>
#                 {DomainOption, domainName, domains, regYears} = @forms["Domain Address"].inputs
#                 {checkButton, registerButton} = @forms["Domain Address"].buttons
#                 actionState = DomainOption.getValue()
#                 domainName.setValue ''
#                 domainName.getElement().setAttribute 'placeholder', switch actionState
#                   when "new"
#                     @suggestionBox?.show()
#                     # domainName.setValidation domainNameValidation
#                     domains.hide()
#                     regYears.show()
#                     createButton.hide()
#                     checkButton.show()
#                     registerButton.hide()
#                     "#{KD.utils.slugify firstName}s-new-domain.com"
#                   when "existing"
#                     @suggestionBox?.hide()
#                     # domainName.setValidation domainNameValidation
#                     domains.hide()
#                     regYears.hide()
#                     checkButton.hide()
#                     registerButton.hide()
#                     createButton.show()
#                     "#{KD.utils.slugify firstName}s-existing-domain.com"
#                   when "subdomain"
#                     # domainName.unsetValidation()
#                     @suggestionBox?.hide()
#                     domains.show()
#                     regYears.hide()
#                     checkButton.hide()
#                     registerButton.hide()
#                     createButton.show()
#                     "#{KD.utils.slugify firstName}s-subdomain"
#             domainName                :
#               cssClass                : "domain"
#               placeholder             : "#{KD.utils.slugify firstName}s-subdomain"
#               validate                :
#                 rules                 :
#                   required            : yes
#                 messages              :
#                   required            : "Subdomain name is required!"
#               keydown                 :
#                 =>
#                   @clearSuggestions()
#                   {DomainOption} = @forms["Domain Address"].inputs
#                   actionState = DomainOption.getValue()
#                   if actionState is "new"
#                     {registerButton, checkButton} = form.buttons
#                     registerButton.hide()
#                     checkButton.show()
#               nextElement             :
#                 regYears              :
#                   cssClass            : "hidden"
#                   itemClass           : KDSelectBox
#                   selectOptions       : ({title: "#{i} Year#{if i > 1 then 's' else ''}", value:i} for i in [1..10])
#                 domains               :
#                   cssClass            : "domains"
#                   itemClass           : KDSelectBox
#                   validate            :
#                     rules             :
#                       required        : yes
#                     messages          :
#                       required        : "Please select a parent domain."
#             suggestionBox             :
#               type                    : "hidden"

#     form = @forms["Domain Address"]
#     {createButton} = form.buttons

#     form.on "FormValidationFailed", createButton.bound 'hideLoader'
#     @on "DomainCreationCancelled",  createButton.bound 'hideLoader'
#     @on "DomainNameShouldFocus", => form.inputs.domainName.setFocus()

#   viewAppended:->
#     KD.whoami().fetchDomains (err, userDomains)=>
#       warn err  if err
#       domainList = []
#       for domain in userDomains
#         if not domain.regYears > 0
#           domainList.push {title:".#{domain.domain}", value:domain.domain}
#       {domains} = @forms["Domain Address"].inputs
#       domains.setSelectOptions domainList

#   checkAvailability: ->
#     form = @forms["Domain Address"]
#     domainInput       = domainName
#     domainName        = form.inputs.domainName.getValue()
#     splittedDomain    = splitDomain(domainName)
#     domain            = splittedDomain.first
#     tld               = splittedDomain.extension
#     {createButton, checkButton, registerButton} = form.buttons
#     @clearSuggestions()
#     KD.remote.api.JDomain.getTldPrice tld, (err, tldPrice) =>
#       if err
#         notifyUser "An error occured. Please try again later."
#       KD.remote.api.JDomain.isDomainAvailable domain, tld, (avErr, result) =>
#         if avErr
#           checkButton.hideLoader()
#           log result
#           log tld
#           log avErr
#           return notifyUser "An error occured: #{avErr}"
#         status = result.status
#         price = result.price
#         suggestions = result.suggestions
#         checkButton.hideLoader()
#         switch status
#           when "available"
#             checkButton.hide()
#             registerButton.show()
#             @showSuggestions true, price, suggestions
#           when "regthroughus", "regthroughothers"
#             checkButton.show()
#             registerButton.hide()
#             @showSuggestions false, price, suggestions
#           when "unknown"
#             checkButton.show()
#             registerButton.hide()
#             notifyUser "Connections are not available. re-check the domain name availability after some time."

#   registerDomain: ->
#     form = @forms["Domain Address"]
#     {createButton, registerButton} = form.buttons
#     @clearSuggestions()

#     {DomainOption, domainName, regYears, domains} = form.inputs
#     domainInput       = domainName
#     domainName        = form.inputs.domainName.getValue()

#     domainOptionValue = DomainOption.getValue()

#     if domainOptionValue is 'new'
#       splittedDomain    = splitDomain(domainName)
#       domain            = splittedDomain.first
#       tld               = splittedDomain.extension
#       form = @forms["Domain Address"]
#       {createButton, registerButton} = form.buttons
#       paymentController = KD.getSingleton('paymentController')
#       group             = KD.getSingleton("groupsController").getCurrentGroup()
#       registerTheDomain = =>
#           KD.remote.api.JDomain.registerDomain
#             domainName : domainInput.getValue()
#             years      : regYears.getValue()
#           , (err, domain) =>
#             if err
#               warn err
#               console.log err
#               notifyUser "An error occured. Please try again later."
#             else
#               @showSuccess domain
#               domain.setDomainCNameToProxyDomain()
#             registerButton.hideLoader()

#       paymentController.getPaymentInfo 'user', group, (err, account)->
#         need = err or not account or not account.cardNumber
#         if need
#           paymentController.setPaymentInfo 'user', group, (success)->
#             if success
#               registerTheDomain()
#         else
#           registerTheDomain()


#     else if domainOptionValue is 'existing'
#       @createDomain {domainName, regYears:0, domainType:'existing'}, (err, domain)=>
#         createButton.hideLoader()
#         if err
#           warn err
#           if err.message?.indexOf("duplicate key error") isnt -1
#             return notifyUser "The domain #{domainName} already exists."
#           return notifyUser "Invalid domain #{domainName}.  "
#         else
#           @showSuccess domain


#     else # create a subdomain
#       subDomainPattern = /^([a-z0-9]([_\-](?![_\-])|[a-z0-9]){0,60}[a-z0-9]|[a-z0-9])$/
#       unless subDomainPattern.test domainName
#         createButton.hideLoader()
#         return notifyUser "#{domainName} is an invalid subdomain."
#       domainName = "#{domainName}.#{domains.getValue()}"

#       @createDomain {domainName, regYears:0, domainType:'subdomain'}, (err, domain)=>
#         createButton.hideLoader()
#         if err
#           warn err
#           if err.message?.indexOf("duplicate key error") isnt -1
#             return notifyUser "The domain #{domainName} already exists."
#           return notifyUser "An error occured. Please try again later."
#         else
#           @showSuccess domain


#   createDomain:(params, callback) ->
#     console.log params
#     KD.remote.api.JDomain.createDomain
#         domain         : params.domainName
#         regYears       : params.regYears
#         proxy          : { mode: 'vm' }
#         hostnameAlias  : []
#         domainType     : params.domainType
#         loadBalancer   :
#             # mode       : "roundrobin"
#             mode         : ""
#       , (err, domain)=>
#         callback err, domain

#   clearSuggestions:-> @suggestionBox?.destroy()

#   showSuggestions:(available, price, suggestions) ->
#     @clearSuggestions()

#     form            = @forms["Domain Address"]
#     {domainName}    = form.inputs
#     {suggestionBox} = form.fields
#     if not available
#       partial         = "<p>This domain is already registered. #{if suggestions.length > 0 then 'You may click and try one below.' else ''}</p>"
#     else
#       partial         = "<p>Domain price is: #{price}$</p>"

#     for domain in suggestions
#       partial += "<li class=''>#{domain.domain}</li><i>#{domain.price}$</i>"

#     for own domain, variants of suggestions
#       for own variant, status of variants when status is "available"
#         partial += "<li class='#{variant}'>#{domain}.#{variant}</li>"

#     suggestionBox.addSubView @suggestionBox = new KDCustomHTMLView
#       tagName : 'ul'
#       cssClass: 'suggestion-box'
#       partial : partial
#       click   : (event)->
#         domainName.setValue $(event.target).closest('li').text()

#   showSuccess:(domain) ->
#     @clearSuggestions()
#     form            = @forms["Domain Address"]
#     {domainName}    = form.inputs
#     {suggestionBox} = form.fields
#     {close, createButton, cancel, another} = form.buttons

#     close.show()
#     another.show()
#     createButton.hide()
#     cancel.hide()

#     @emit 'DomainSaved', domain

#     suggestionBox.addSubView @successNote = new KDCustomHTMLView
#       tagName : 'p'
#       cssClass: 'success'
#       # the following partial will vary depending on the DomainOption value.
#       # Users who registered a domain through us won't need this change.
#       # partial : "<b>Thank you!</b><br>Your domain #{domainName.getValue()} has been added to our database. Please go to your provider's website and add a CNAME record mapping to kontrol.in.koding.com."

#       # change this part when registering is there.
#       partial : "<b>Thank you!</b><br>Your subdomain <strong>#{domainName.getValue()}</strong> has been added to our database. You can dismiss this panel and point your new domain to one of your VMs on the settings screen."
#       click   : => @reset()


#   reset:->
#     form            = @forms["Domain Address"]
#     {domainName}    = form.inputs
#     {suggestionBox} = form.fields
#     {close, createButton, cancel, another} = form.buttons

#     close.hide()
#     another.hide()
#     createButton.show()
#     cancel.show()
#     @successNote.destroy()
#     delete @successNote
#     domainName.setValue ''
#     @emit 'CloseClicked'

#   addAnotherDomainClicked:->
#     form            = @forms["Domain Address"]
#     {domainName}    = form.inputs
#     {suggestionBox} = form.fields
#     {close, createButton, cancel, another} = form.buttons

#     close.hide()
#     another.hide()
#     createButton.show()
#     cancel.show()
#     @successNote.destroy()
#     delete @successNote
#     domainName.setValue ''
#     domainName.setFocus()

#   notifyUser = (msg) ->
#     new KDNotificationView
#       type     : 'tray'
#       title    : msg
#       duration : 5000
