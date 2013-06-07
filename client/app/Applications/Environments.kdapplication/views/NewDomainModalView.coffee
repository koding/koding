class NewDomainModalView extends KDModalViewWithForms

  constructor: (options={}, data)->
    sucessCallbackError = 
    """
      You must send a successCallback method for a successfull creation handling.
    """
    
    unless options.successCallback then warn sucessCallbackError

    options = $.extend(options,
      title                     : "Add New Domain"
      content                   : "<div class='modalformline'>Add a new domain.</div>"
      overlay                   : yes
      width                     : 400
      height                    : "auto"
      tabs                      :
        navigable               : yes
        forms                   :
          form                  :
            callback            : @bound "addNewDomain"
            buttons             :
              Create            :
                cssClass        : "modal-clean-gray"
                type            : "submit"
                loader          :
                  color         : "#444444"
                  diameter      : 12
            fields              :
              domain            :
                label           : "Domain Name:"
                name            : "domain"
                placeholder     : "Your Domain Name (e.g. example.com)"
                validate        :
                  rules         :
                    required    : yes
                  messages      :
                    required    : "You must enter a domain."

      )

    super options, data

  notify:(msg)->
    new KDNotificationView
      type : "top"
      title: msg

  addNewDomain:(formData)->
    
    {form}          = @modalTabs.forms
    domainInfo      = form.inputs.domain.getValue().split "."
    successCallback = @getOptions().successCallback  
  
    domain = domainInfo.slice(0, domainInfo.length-1).join ""
    tld = domainInfo[domainInfo.length-1]

    KD.remote.api.JDomain.count {domain: domain}, (err, count) =>
      if err then warn err
      
      if count > 0
        @notify "Someone has already added this domain."

      KD.remote.api.JDomain.isDomainAvailable domain, tld, (err, domainStatus)=>
        if err then @notify err

        if domainStatus is "unknown"
          @notify "An unknown error occured. Please try again later."
          form.buttons.Create.hideLoader()

        if domainStatus in ["regthroughus", "regthroughothers"]
          @notify "This domain is already registered. Please try another domain."
          form.buttons.Create.hideLoader()

          


          """
          KD.remote.api.JDomain.createDomain
            domain : domain
            owner  : KD.whoami()
            , (err, model) =>
              if not err 
                new KDNotificationView
                  type  : "top"
                  title : "Your domain has been successfully saved."
                successCallback {id:model.getId(), name:model.domain}
                @destroy()
          """