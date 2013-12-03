class CommonDomainCreateForm extends KDFormViewWithFields
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