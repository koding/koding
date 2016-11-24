module.exports = (id, nickname, firstName = nickname, lastName = nickname) ->
  timeString = (new Date).toISOString()
  return {
    socialApiId     : '18'
    systemInfo      : { 'defaultToLastUsedEnvironment': true }
    counts          :
      followers     : 0
      following     : 0
      topics        : 0
      likes         : 0
      lastLoginDate : '2015-07-28T20:07:58.353Z'
      referredUsers : 0
      invitations   : 0
    type            : 'registered'
    profile         :
      nickname      : nickname
      hash          : '6096f133628c477db64002beaf0ceb72'
      firstName     : firstName
      lastName      : lastName
    isExempt        : false
    globalFlags     : [ 'super-admin' ]
    meta            :
      data          :
        modifiedAt  : timeString
        createdAt   : timeString
        likes       : 0
      createdAt     : timeString
      modifiedAt    : timeString
      likes         : 0
    _id             : id
    timestamp_      : timeString
  }
