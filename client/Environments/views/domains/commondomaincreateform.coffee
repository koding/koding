class CommonDomainCreateForm extends KDFormViewWithFields

  constructor:(options = {}, data)->

    o =
      cssClass              : KD.utils.curry "new-domain-form", options.cssClass
      fields                :
        domainName          :
          name              : "domainInput"
          cssClass          : "domain-input"
          attributes        :
            spellcheck      : false
          label             : options.label        ? "Subdomain"
          placeholder       : options.placeholder or "Type your domain"
          validate          :
            rules           : required : yes
            messages        : required : "A domain name is required"
          nextElement       :
            domains         :
              itemClass     : KDSelectBox
              cssClass      : "main-domain-select"
              selectOptions : options.selectOptions
            suffixDomain    :
              itemClass     : KDView
              cssClass      : "suffix-domain"
              partial       : ".#{options.suffixDomain}"

    if options.noDomainSelector
      delete o.fields.domainName.nextElement.domains

    unless options.suffixDomain
      delete o.fields.domainName.nextElement.suffixDomain

    super o, data

    @addSubView @message = new KDCustomHTMLView
      cssClass : 'status-message hidden'

  # submit:->
  #   @buttons?.createButton.hideLoader()
  #   @off  "FormValidationPassed"
  #   @once "FormValidationPassed", =>
  #     @emit 'registerDomain'
  #     @buttons?.createButton.showLoader()
  #   super
