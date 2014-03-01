class LocationController extends KDController

  fetchCountryData:(callback)->

    { JPayment } = KD.remote.api

    if @countries or @countryOfIp
      return @utils.defer => callback null, @countries, @countryOfIp

    ip = Cookies.get 'clientIPAddress'

    JPayment.fetchCountryDataByIp ip, (err, @countries, @countryOfIp) =>
      callback err, @countries, @countryOfIp


  createLocationForm: (options, data) ->
    form = new LocationForm options, data

    @fetchCountryData (err, countries, countryOfIp)->
      return if KD.showError err

      form.setCountryData { countries, countryOfIp }

    return form