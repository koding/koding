#to-do Inject this method with KD.extend!
do ->

  google =  require './google'
  mixpanel =  require './mixpanel'
  vendors = [google, mixpanel]
  # to-do log to mixpanel after subscription is upgraded
  KD.track = (eventName, data)->
    for eventData in data
      if eventData.vendor is 'google'
        _gaq.push data.module, eventName
      if eventData.vendor is 'mixpanel'
        KD.mixpanel.track eventName, data
