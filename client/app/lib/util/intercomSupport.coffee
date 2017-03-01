makeHttpClient = require 'app/util/makeHttpClient'
exports.client = client = makeHttpClient { baseURL: '/-/intercomlauncher' }

module.exports = (callback) ->

  client.get('')
  .then ({ data }) -> callback data
  .catch -> callback no
