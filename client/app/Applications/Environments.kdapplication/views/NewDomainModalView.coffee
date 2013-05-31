class NewDomainModalView extends KDModalViewWithForms

  constructor: (options={}, data)->
    unless options.successCallback then warn "You must send a successCallback option."
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

  addNewDomain:(formData)->
    
    {form}          = @modalTabs.forms
    domain          = form.inputs.domain.getValue()
    successCallback = @getOptions().successCallback

    KD.remote.api.JDomain.count {domain: domain}, (err, count) ->
      if err then warn err
      if count > 0
        new KDNotificationView
          type  : "top"
          title : "Someone has already added this domain."
        return

      KD.remote.api.JDomain.createDomain
        domain : domain
        owner  : KD.whoami()
        , (err, model) ->
          if not err 
            new KDNotificationView
              type  : "top"
              title : "Your domain has been successfully saved."
            successCallback {name: model.domain, _id:model._id}