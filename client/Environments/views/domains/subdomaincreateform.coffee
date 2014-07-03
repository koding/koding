class SubdomainCreateForm extends CommonDomainCreateForm

  constructor:(options = {}, data)->

    super
      label            : ""
      placeholder      : "Type your subdomain "
      buttonTitle      : "Create subdomain"
      suffixDomain     : "#{KD.nick()}.#{KD.config.userSitesDomain}"
      noDomainSelector : yes
    , data
