class BillingForm extends PaymentForm

  constructor:(options={}, data)->
    cip            = options.countryOfIp
    defaultCountry = if options.countries[cip] then cip else 'US'

    options.additionalFields =
      company             :
        label             : 'Company & VAT'
        placeholder       : 'Company (optional)'
        nextElementFlat   :
          vatNumber       :
            placeholder   : 'VAT Number (optional)'

      address             :
        label             : 'Address & ZIP'
        placeholder       : 'Address (optional)'
        nextElementFlat   :
          zip             :
            placeholder   : 'ZIP (optional)'

      city                :
        label             : 'City & Country'
        placeholder       : 'City (optional)'
        nextElementFlat   :
          country         :
            itemClass     : KDSelectBox
            selectOptions : _.values options.countries
            defaultValue  : defaultCountry

      phone               :
        label             : 'Phone'
        placeholder       : '(optional)'

    super options, data
