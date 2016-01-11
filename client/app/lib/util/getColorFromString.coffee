module.exports = (str) ->
  hash  = 0
  color = '#'

  for i in [0...str.length]
    hash = str.charCodeAt(i) + ((hash << 5) - hash)

  for i in [0...3]
    value = (hash >> (i * 8)) & 0xFF
    color += ('00' + value.toString(16)).substr(-2)

  return color
