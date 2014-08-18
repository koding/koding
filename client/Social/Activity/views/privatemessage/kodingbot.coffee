class KodingBot extends KDObject

  questionMap =
    'Name?' :
      fn    : (firstName)->
        me = KD.whoami()
        {profile:{firstName:oldFirstName}} = me
        # do not do anything if current firstname and lastname is same
        return if oldFirstName is firstName

        me.modify {
          "profile.firstName" : firstName
        }, (err)->
          return notify err.message  if err
          new KDNotificationView title : "Nice to meet you #{firstName}! What is your last name?"

    'Last name?' :
      fn    : (lastName)->
        me = KD.whoami()
        {profile:{lastName:oldLastName}} = me
        # do not do anything if current firstname and lastname is same
        return if oldLastName is lastName

        me.modify {
          "profile.lastName" : lastName
        }, (err)->
          return notify err.message  if err
          new KDNotificationView title : "Alright last name is set..."

  process : (question, answer) ->

    if questionMap[question.body]
      {fn} = questionMap[question.body]
      fn answer
