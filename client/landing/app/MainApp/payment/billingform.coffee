class BillingForm extends PaymentForm

  constructor:(options={}, data)->
  
    data = @getData() or {}

    cip            = options.countryOfIp
    defaultCountry = if options.countries[cip] then cip else 'US'

    options.additionalFields =
      company             :
        label             : 'Company & VAT'
        placeholder       : 'Company (optional)'
        value             : data.company
        nextElementFlat   :
          vatNumber       :
            placeholder   : 'VAT Number (optional)'
            value         : data.vatNumber 

      address             :
        label             : 'Address & ZIP'
        placeholder       : 'Address (optional)'
        value             : data.value
        nextElementFlat   :
          zip             :
            placeholder   : 'ZIP (optional)'

      city                :
        label             : 'City & Country'
        placeholder       : 'City (optional)'
        value             : data.city
        nextElementFlat   :
          country         :
            itemClass     : KDSelectBox
            selectOptions : _.values options.countries
            defaultValue  : defaultCountry
            value         : data.country

      phone               :
        label             : 'Phone'
        placeholder       : '(optional)'
        value             : data.phone

    super options, data
