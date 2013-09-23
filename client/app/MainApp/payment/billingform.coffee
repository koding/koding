class BillingFormModal extends PaymentFormModal

  constructor:(options={}, data)->

    options.callback = (formData) => @emit 'PaymentInfoSubmitted', formData

    options.additionalFields =
      company             :
        label             : 'Company & VAT'
        placeholder       : 'Company (optional)'
        defaultValue      : data.company
        nextElementFlat   :
          vatNumber       :
            placeholder   : 'VAT Number (optional)'
            defaultValue  : data.vatNumber 

      address             :
        label             : 'Address & ZIP'
        placeholder       : 'Address (optional)'
        defaultValue      : data.address1
        nextElementFlat   :
          zip             :
            placeholder   : 'ZIP (optional)'
            defaultValue  : data.zip

      city                :
        label             : 'City & Country'
        placeholder       : 'City (optional)'
        defaultValue      : data.city
        nextElementFlat   :
          country         :
            itemClass     : KDSelectBox
            defaultValue  : data.country or defaultCountry

      phone               :
        label             : 'Phone'
        placeholder       : '(optional)'
        defaultValue      : data.phone

    super options, data

    # set up a loader to compensate for latency while we load the country list
    @countryLoader = new KDLoaderView
      size        : { width: 14 }
      showLoader  : yes

    @billingForm.fields.country.addSubView @countryLoader

  setCountryData: ({ countries, countryOfIp }) ->
    { country } = @billingForm.inputs

    country.setSelectOptions _.values countries

    country.setValue(
      if countries[countryOfIp]
      then countryOfIp
      else 'US'
    )

    @countryLoader.hide()

  handleFormData:->