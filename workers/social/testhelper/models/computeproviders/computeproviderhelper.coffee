{ _
  daisy
  expect
  withConvertedUser }    = require '../../index'
{ createProvisioner }    = require './provisionerhelper'
{ createStackTemplate }  = require './stacktemplatehelper'

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

    _createStackTemplate = (client, options, callback) ->
      createStackTemplate client, options, (err, template) ->
        expect(err).to.not.exist
        callback { template }


    _createStackFromTemplate = (stackData, options, callback) ->
      ComputeProvider.generateStackFromTemplate stackData, options, (err, { stack }) ->
        expect(err?.message).to.not.exist
        callback { stack }


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
          _createStackFromTemplate stackData, options, (data_) ->
            callback { group, stack : data_.stack, stackTemplate, stackTemplateData }

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
        provisioners : ['test_provisioner']
      }

      ComputeProvider.create client, computeProviderOptions, (err, data_) ->
        expect(err).to.not.exist
        callback data_


    models.forEach (model) ->

      switch model
        when 'StackTemplate'
          queue.push ->
            _createStackTemplate client, options, (data_) ->
              data = _.extend data, data_
              queue.next()

        when 'Stack'
          queue.push ->
            _createStack client, options, (data_) ->
              data = _.extend data, data_
              queue.next()

        when 'Provisioner'
          queue.push ->
            createProvisioner client, options, (err, data_) ->
              expect(err).to.not.exist
              data = _.extend data, data_
              queue.next()

    queue.push -> callback data

    daisy queue


module.exports = {
  withConvertedUserAnd
}

