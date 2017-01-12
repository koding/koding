module.exports = getChannelTypeByName = (name) ->

  # SocialApiController::cacheable requires a type parameter. But, since we only
  # have channelName from router, this was the only (probably the easiest) way
  # that came to my mind to determine a type for a channel by its name. - US

  switch name
    when 'public' then 'group'
    when 'changelog' then 'announcement'
    else 'topic'
