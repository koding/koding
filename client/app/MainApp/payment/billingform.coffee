class BillingForm extends PaymentForm

  constructor:(options={}, data)->
    super
  
    cip            = options.countryOfIp
    defaultCountry = if options.countries[cip] then cip else 'US'

    options.additionalFields =
      company             :
        label             : 'Company & VAT'
        placeholder       : 'Company (optional)'
        nextElement   :
          vatNumber       :
            placeholder   : 'VAT Number (optional)'

      address             :
        label             : 'Address & ZIP'
        placeholder       : 'Address (optional)'
        nextElement   :
          zip             :
            placeholder   : 'ZIP (optional)'

      city                :
        label             : 'City & Country'
        placeholder       : 'City (optional)'
        nextElement   :
          country         :
            itemClass     : KDSelectBox
            selectOptions : _.values options.countries
            defaultValue  : defaultCountry

      phone               :
        label             : 'Phone'
        placeholder       : '(optional)'

    super options, data
