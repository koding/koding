module.exports = curryIn = (options, data) ->

  for key, value of data
    options[key] ?= ''
    options[key] += " #{value}"

  return options
