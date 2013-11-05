class SubdomainCreateForm extends CommonDomainCreateForm

  constructor:(options = {}, data)->
    super
      placeholder : "Type your subdomain..."
      buttonTitle : "Create subdomain"
    , data
