class KodingBot extends KDObject

  CHANNEL_ID = null

  constructor: ->

    super

    CHANNEL_ID = @getDelegate().getData().id

  updateProfile = (key, value, callback) ->
    me = KD.whoami()
    oldValue = me.profile[key]
    # do not do anything if current firstname and lastname is same
    return if oldValue is value

    options = {}
    options["profile.#{key}"] = value

    me.modify options, (err)->
      return notify err.message  if err
      callback()

  questionMap =
    'Name?' :
      fn    : (firstName)->
        updateProfile 'firstName', firstName, =>
          KD.singletons.socialapi.message.sendPrivateMessage
            channelId : CHANNEL_ID
            body : "Nice to meet you #{firstName}! What is your last name?"
          , log

    'Last name?' :
      fn    : (lastName)->
        updateProfile 'lastName', lastName, ->
          KD.singletons.socialapi.message.sendPrivateMessage
            channelId : CHANNEL_ID
            body : "Great, Welcome #{KD.utils.getFullnameFromAccount KD.whoami()}!"
          , log

    # 'Password?' :
    #   fn    : (lastName)->
    #     updateProfile 'firstName', firstname, ->
    #       new KDNotificationView title : "Alright last name is set..."

  process : (question, answer) ->
    if questionMap[question.body]
      {fn} = questionMap[question.body]
      fn answer
