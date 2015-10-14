{ _
  expect
  ObjectId
  withConvertedUser
  generateRandomString } = require '../../index'

crypto       = require 'crypto'
JProvisioner = require '../../../../social/lib/social/models/computeproviders/provisioner'


generateProvisionerData = (data = {}) ->

  provisionerData =
    slug        : generateRandomString()
    type        : 'shell'
    label       : generateRandomString()
    group       : 'koding'
    content     : { script : generateRandomString() }
    originId    : new ObjectId
    accessLevel : 'private'

  provisionerData.contentSum = crypto
    .createHash 'sha1'
    .update "#{provisionerData.content.script}"
    .digest 'hex'

  provisionerData = _.extend provisionerData, data

  return provisionerData


createProvisioner = (data, callback) ->

  provisioner = new JProvisioner generateProvisionerData data
  provisioner.save (err) ->
    return callback err, provisioner


withConvertedUserAndProvisioner = (options, callback) ->

  [options, callback] = [callback, options]  unless callback
  options            ?= {}

  withConvertedUser (data) ->
    { client, account }       = data
    options.originId = account?.getId() ? new ObjectId
    options.group    = client?.context?.group

    createProvisioner options, (err, provisioner) ->
      expect(err).to.not.exist
      data.provisioner = provisioner
      return callback data


module.exports = {
  generateProvisionerData
  withConvertedUserAndProvisioner
}

