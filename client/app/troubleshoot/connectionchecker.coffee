class ConnectionChecker extends KDObject

  constructor: (options, data)->
    super options, data

    @url  = @getData()

    {@fail, @jsonp} = @getOptions()

  ping: (callback) ->
    {crossDomain} = @getOptions()
    # if there are more than two consecutive crossDomain calls
    # this window.jsonp will be overriden and it will cause errors - CtF
    ConnectionChecker.jsonp = callback  if crossDomain

    $.ajax
      url     : @url
      success : -> callback arguments...
      jsonpCallback : @jsonp  if @jsonp
      timeout : 5000
      dataType: "jsonp"
      error   : => @fail? arguments...
