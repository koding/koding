kookies = require 'kookies'
remote = require('./remote').getInstance()
showError = require './util/showError'
kd = require 'kd'
KDController = kd.Controller
LocationForm = require './commonviews/location/locationform'


module.exports = class LocationController extends KDController

  fetchCountryData: (callback) ->

    { JPayment } = remote.api

    if @countries or @countryOfIp
      return kd.utils.defer => callback null, { @countries, @countryOfIp }

    ip = kookies.get 'clientIPAddress'

    JPayment.fetchCountryDataByIp ip, (err, { @countries, @countryOfIp }) =>
      callback err, { @countries, @countryOfIp }


  createLocationForm: (options, data) ->
    form = new LocationForm options, data

    @fetchCountryData (err, { countries, countryOfIp }) ->
      return if showError err

      form.setCountryData { countries, countryOfIp }

    return form
