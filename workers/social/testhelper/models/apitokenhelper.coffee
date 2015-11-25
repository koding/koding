{ expect
  withConvertedUser
  generateRandomString } = require '../index'

JApiToken = require '../../lib/social/models/apitoken'


withConvertedUserAndApiToken = (options, callback) ->

  [options, callback] = [callback, options]  unless callback
  options             ?= {}
  options.context     ?= { group : generateRandomString() }
  options.createGroup ?= yes

  withConvertedUser options, (data) ->
    { client, account, group } = data

    JApiToken.create { account, group : group.slug }, (err, apiToken) ->
      expect(err).to.not.exist
      data.apiToken = apiToken
      callback data


module.exports = {
  withConvertedUserAndApiToken
}
