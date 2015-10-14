{ _
  daisy
  expect
  withConvertedUser }    = require '../../index'
{ createProvisioner }    = require './provisionerhelper'
{ createStackTemplate }  = require './stacktemplatehelper'
{ createCredential }     = require './credentialhelper'

JGroup          = require '../../../../social/lib/social/models/group'
JProvisioner    = require '../../../../social/lib/social/models/computeproviders/provisioner'
JStackTemplate  = require '../../../../social/lib/social/models/computeproviders/stacktemplate'
ComputeProvider = require '../../../../social/lib/social/models/computeproviders/computeprovider'


withConvertedUserAnd = (models, options, callback) ->

  [options, callback] = [callback, options]  unless callback
  options            ?= {}
  queue               = []

  withConvertedUser (data) ->
    { client, user, account } = data
    { group : groupSlug }     = client.context

    _createCredential = (client, options, callback) ->
      createCredential client, options, (err, data_) ->
        expect(err).to.not.exist
        callback data_


    _createProvisioner = (client, options, callback) ->
      createProvisioner client, options, (err, data_) ->
        expect(err).to.not.exist
        callback data_


    _createStackTemplate = (client, options, callback) ->
      createStackTemplate client, options, (err, template) ->
        expect(err).to.not.exist
        callback { template }


    _createStack = (client, options, callback) ->
      stackData = { client, user, account, template : data.stackTemplate }
      group             = null
      stackTemplate     = null
      stackTemplateData = null

      _queue = [

        ->
          # adding group to stackData, will be needed while creating stack
          JGroup.one { slug : groupSlug }, (err, group_) ->
            expect(err).to.not.exist
            stackData.group = group = group_
            _queue.next()

        ->
          _createStackTemplate client, options, ({ template }) ->
            stackData.template = stackTemplate = template.stackTemplate
            stackTemplateData  = template.stackTemplateData
            _queue.next()

        ->
          # create a stack from the given template
          ComputeProvider.generateStackFromTemplate stackData, options, (err, { stack }) ->
            expect(err?.message).to.not.exist
            callback { group, stack, stackTemplate, stackTemplateData }

      ]

      daisy _queue


    _createComputeProvider = (client, options, callback) ->
      computeProvider = null
      client.r        = { group : groupSlug, user, account }
      label           = generateRandomString()
      generatedFrom   = new ObjectId
      provider        = 'aws'

      expect(stack).to.exist
      computeProviderOptions = {
        client, stack, provider, label, generatedFrom
        users : []
        provisioners : [data.provisioner ? 'test_provisioner']
      }

      ComputeProvider.create client, computeProviderOptions, (err, data_) ->
        expect(err).to.not.exist
        callback data_


    models.forEach (model) ->

      fn = switch model
        when 'Credential'       then _createCredential
        when 'Provisioner'      then _createProvisioner
        when 'StackTemplate'    then _createStackTemplate
        when 'Stack'            then _createStack
        when 'ComputeProvider'  then _createComputeProvider
        else                         callback 'invalid request'

      queue.push ->
        fn client, options, (data_) ->
          data = _.extend data, data_
          queue.next()

    queue.push -> callback data

    daisy queue


module.exports = {
  withConvertedUserAnd
}

