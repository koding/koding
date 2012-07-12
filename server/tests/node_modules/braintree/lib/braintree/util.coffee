class Util
  @convertObjectKeysToUnderscores: (obj) ->
    newObj = {}
    for key, value of obj
      newKey = Util.toUnderscore(key)
      if value instanceof Array
        newObj[newKey] = (
          (if typeof(item) is 'object' then Util.convertObjectKeysToUnderscores(item) else item) for item in value
        )
      else if typeof(value) is 'object'
        if value instanceof Date
          newObj[newKey] = value
        else
          newObj[newKey] = Util.convertObjectKeysToUnderscores(value)
      else
        newObj[newKey] = value
    newObj

  @toCamelCase: (string) ->
    string.replace(/([\-\_][a-z0-9])/g, (match) -> match.toUpperCase().replace('-','').replace('_',''))

  @toUnderscore: (string) ->
    string.replace(/([A-Z])/g, (match) -> "_" + match.toLowerCase())

exports.Util = Util
