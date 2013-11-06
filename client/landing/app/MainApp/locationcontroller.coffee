class LocationController extends KDController

  fetchCountryData:(callback)->

    { JPayment } = KD.remote.api

    if @countries or @countryOfIp
      return @utils.defer => callback null, @countries, @countryOfIp

    ip = $.cookie 'clientIPAddress'

    JPayment.fetchCountryDataByIp ip, (err, @countries, @countryOfIp) =>
      callback err, @countries, @countryOfIp

  #
#    @fetchCountryData (err, countries, countryOfIp) =>
#      modal.setCountryData { countries, countryOfIp }
