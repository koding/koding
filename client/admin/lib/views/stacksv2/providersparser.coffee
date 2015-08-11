module.exports = providersParser = (content) ->

    providers = {}

    # Find all matches for ${var.PROVIDER_}
    (content.match /\$\{var\.(.*?)\_/g).forEach (match) ->
      # Trim prefix/suffix and remove duplicates
      providers[match[6...-1]] = null

    # Return list of providers
    return Object.keys providers