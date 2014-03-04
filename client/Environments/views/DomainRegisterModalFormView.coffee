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

      fields            :
          domainName    :
            label       : "Enter your domain name"
            placeholder : "Domain (e.g. example.com)"
            validate    :
              rules     :
                required: yes
              messages  :
                required: "Enter your domain name"

  saveDomain:->
    modalTabs = @getOptions().modalTabs
    domainName = @forwardForm.inputs.domainName.getValue()

    KD.remote.api.JDomain.createDomain
      domain         : domainName
      regYears       : 0
      hostnameAlias  : []
      loadBalancer   :
          # mode       : "roundrobin"
          mode       : ""
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
