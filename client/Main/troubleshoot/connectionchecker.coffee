class ConnectionChecker extends KDObject

  constructor: (options, data)->
    super options, data
    @url = data

  ping: (callback) ->
    {crossDomain} = @getOptions()
    # if there are more than two consecutive crossDomain calls
    # this window.jsonp will be overriden and it will cause errors - CtF
    window.jsonp = callback  if crossDomain

    $.ajax
      url     : @url
      success : -> callback()
      timeout : 5000
      dataType: "jsonp"
      error   : ->