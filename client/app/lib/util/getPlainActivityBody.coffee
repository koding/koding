module.exports = (activity) ->

  { body } = activity
  tagMap = {}
  activity.tags?.forEach (tag) -> tagMap[tag.getId()] = tag

  return body.replace /\|(.+?)\|/g, (match, tokenString) ->
    [prefix, constructorName, id, name] = tokenString.split /:/

    switch prefix
      when '#' then token = tagMap?[id]

    return "#{prefix}#{if token then token.name else name or ''}"
