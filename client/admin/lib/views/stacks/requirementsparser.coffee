module.exports = requirementsParser = (content) ->

    regex = /\{\{(user|account|group)\ (.*?)\}\}/g
    requirements = {}
    match = regex.exec content

    while match
      requirements[match[1]] ?= {}
      requirements[match[1]][match[2]] = null
      match = regex.exec content

    for match of requirements
      requirements[match] = Object.keys requirements[match]

    return requirements