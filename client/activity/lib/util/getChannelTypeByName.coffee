module.exports = getChannelTypeByName = (name) ->

  if name is 'public' then 'group' else 'topic'


