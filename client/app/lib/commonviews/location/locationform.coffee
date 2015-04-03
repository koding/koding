_ = require 'lodash'
remote = require('../../remote').getInstance()
kd = require 'kd'
KDFormViewWithFields = kd.FormViewWithFields
KDLoaderView = kd.LoaderView
KDSelectBox = kd.SelectBox
module.exports = class LocationForm extends KDFormViewWithFields

  constructor: (options = {}, data = {}) ->
    options.cssClass = kd.utils.curry 'location-form', options.cssClass
    super (@prepareOptions options, data), data

    # set up a loader for latency while we load the country list.
    @countryLoader = new KDLoaderView
      size        : { width: 14 }
      showLoader  : yes

    @on 'FormValidationFailed', => @buttons.Save.hideLoader()

  prepareOptions: (options, data) ->

    options.fields ?= {}

    options.fields.company ?=
      label             : 'Company & VAT'
      placeholder       : 'Company (optional)'
      defaultValue      : data.company
      nextElementFlat   :
        vatNumber       :
          placeholder   : 'VAT Number (optional)'
          defaultValue  : data.vatNumber

    options.fields.address1 ?=
      label             : 'Address & ZIP'
      placeholder       : 'Address'
      required          : "Address is required"
      defaultValue      : data.address1

      nextElementFlat   :
        zip             :
          placeholder   : 'ZIP'
          defaultValue  : data.zip
          keyup         : @bound 'handleZipCode'
          required      : "Zip is required"

    options.fields.city ?=
      label             : 'City & State'
      placeholder       : 'City'
      defaultValue      : data.city
      required          : "City is required"
      nextElementFlat   :
        state           :
          placeholder   : 'State'
          itemClass     : KDSelectBox
          defaultValue  : data.state
          required      : "State is required"

    options.fields.country ?=
      label             : 'Country'
      itemClass         : KDSelectBox
      defaultValue      : data.country or 'US'

    if options.phone?.show or options.phone?.required
      { required: requirePhone } = options.phone

      options.fields.phone ?=
        label             : 'Phone'
        placeholder       : if requirePhone then '' else '(optional)'
        defaultValue      : data.phone

      if requirePhone
        options.fields.phone.required = "Phone number is required."

    if options.buttons is no
      delete options.buttons

    else
      options.buttons ?= {}

      options.buttons.Save ?=
        style             : 'solid green medium'
        type              : 'submit'
        loader            : { color : '#fff', diameter : 12 }

    return options

  handleZipCode:->

    { JLocation } = remote.api

    { city, state, country, zip } = @inputs

    locationSelector =
      zip           : zip.getValue()
      countryCode   : country.getValue()

    JLocation.one locationSelector, (err, location) =>
      @setLocation location  if location

  handleCountryCode: ->
    { JLocation } = remote.api

    { country, state } = @inputs

    { actualState, country: countryCode } = @getData()

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
            @addCustomData 'actualState', value
            'state'

          when 'countryCode' then 'country'

        input = @inputs[inputName]

        input.setValue value  if input? # TODO: `and not input.isDirty()` or something like that C.T.

  setCountryData: ({ countries, countryOfIp }) ->
    { country } = @inputs

    country.setSelectOptions _.values countries

    country.setValue(
      if countries[countryOfIp]
      then countryOfIp
      else 'US'
    )

    # @countryLoader.hide()
    @handleCountryCode()
    @emit 'CountryDataPopulated'


