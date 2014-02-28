class SubdomainCreateForm extends CommonDomainCreateForm

  constructor:(options = {}, data)->

    super
      label       : ""
      placeholder : "Type your subdomain name..."
      buttonTitle : "Create subdomain"
    , data
