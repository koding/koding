module.exports = providersParser = (content) ->

    regex     = /\$\{var\.(.*?)\_/g
    providers = {}
    match     = regex.exec content

    while match
      providers[match[1]] = null
      match = regex.exec content

    # Return list of providers
    return Object.keys providers