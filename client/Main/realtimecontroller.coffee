class RealtimeController extends KDController

  constructor: (options = {}, data) ->

    super options, data

    {subscribekey} = KD.config.pubnub

    @pubnub = PUBNUB.init subscribe_key : subscribekey

  # subscriptionData =
  #   serviceType: 'socialapi'
  #   group      : group.slug
  #   channelType: socialApiChannel.typeConstant
  #   channelName: socialApiChannel.name
  authenticate: (options = {}, callback = noop) ->

    { channelName, typeConstant, group } = options
    return callback { message: "channel name is not defined" }  unless channelName

    xhr = new XMLHttpRequest()
    endPoint = "/api/gatekeeper/channel/authenticate"
    xhr.open 'POST', endPoint, true
    xhr.setRequestHeader "Content-Type", "application/json;"
    xhr.onreadystatechange = (result) =>
      response = JSON.parse xhr.responseText
      # 0     - connection failed
      # >=400 - http errors
      if xhr.status is 0 or xhr.status >= 400
        return callback { message: response.description}

      return if xhr.readyState isnt 4

      if xhr.status not in [200, 304]
        return callback { message: response.description}


      return callback null, response

    xhr.send JSON.stringify {name: channelName, typeConstant, group}

  subscribe: (options = {}) ->
    { channelName, typeConstant, group } = options
    return KD.showError { message: "channel name is not set" }  unless channelName

    that = this
    @pubnub.subscribe
      channel : prepareChannelName options
      message : (message, env, channel) =>
        if message
          {eventName, body} = message
          that.emit eventName, body

  prepareChannelName = (options) ->
    { channelName, typeConstant, group } = options

    return "#{group}-#{typeConstant}-#{channelName}"
