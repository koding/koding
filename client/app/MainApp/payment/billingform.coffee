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

      address1            :
        label             : 'Address & ZIP'
        placeholder       : 'Address (optional)'
        defaultValue      : data.address1
        nextElementFlat   :
          zip             :
            placeholder   : 'ZIP (optional)'
            defaultValue  : data.zip
            keyup         : @bound 'handleZipCode'
      city                :
        label             : 'City & State'
        placeholder       : 'City (optional)'
        defaultValue      : data.city
        nextElementFlat   :
          state           :
            placeholder   : 'State (optional)'
            itemClass     : KDSelectBox
            defaultValue  : data.state
      country             :
        label             : 'Country'
        itemClass         : KDSelectBox
        defaultValue      : data.country or 'US'

      phone               :
        label             : 'Phone'
        placeholder       : '(optional)'
        defaultValue      : data.phone

    super options, data

    # set up a loader to compensate for latency while we load the country list
    @countryLoader = new KDLoaderView
      size        : { width: 14 }
      showLoader  : yes

    @billingForm.addCustomData 'actualState', data.state

    @billingForm.fields.country.addSubView @countryLoader

  handleZipCode:->

    { JLocation } = KD.remote.api

    { city, state, country, zip } = @billingForm.inputs

    locationSelector =
      zip           : zip.getValue()
      countryCode   : country.getValue()

    JLocation.one locationSelector, (err, location) =>
      @setLocation location  if location

  handleCountryCode: ->
    { JLocation } = KD.remote.api

    { country, state } = @billingForm.inputs

    { actualState, country: countryCode } = @billingForm.getData()

    if @countryCode isnt countryCode
      @countryCode = countryCode

      JLocation.fetchStatesByCountryCode countryCode, (err, states) ->
        state.setSelectOptions _.values states
        state.setValue actualState

  setLocation: (location) ->
      ['city', 'stateCode', 'countryCode'].forEach (field) =>
        value = location[field]
        inputName = switch field
          when 'city' then 'city'

          when 'stateCode'
            @billingForm.addCustomData 'actualState', value
            'state'

          when 'countryCode' then 'country'

        input = @billingForm.inputs[inputName]

        input.setValue value  if input? # TODO: `and not input.isDirty()` or something like that C.T.

  setCountryData: ({ countries, countryOfIp }) ->
    { country } = @billingForm.inputs

    country.setSelectOptions _.values countries

    country.setValue(
      if countries[countryOfIp]
      then countryOfIp
      else 'US'
    )

    @countryLoader.hide()
    @handleCountryCode()
    @emit 'CountryDataPopulated'

  handleFormData:->