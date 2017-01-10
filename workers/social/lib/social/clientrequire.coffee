module.exports = clientRequire = (path) ->
  require "#{process.env.KONFIG_PROJECTROOT}/client/#{path}"
