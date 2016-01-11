{ _
  daisy
  expect
  ObjectId
  withConvertedUser
  generateRandomString } = require '../../index'
{ createProvisioner }    = require './provisionerhelper'
{ createStackTemplate }  = require './stacktemplatehelper'
{ createCredential }     = require './credentialhelper'
{ createMachine }        = require './machinehelper'
{ PROVIDERS } = require './../../../../social/lib/social/models/computeproviders/computeutils'

JGroup          = require '../../../../social/lib/social/models/group'
JProvisioner    = require '../../../../social/lib/social/models/computeproviders/provisioner'
JStackTemplate  = require '../../../../social/lib/social/models/computeproviders/stacktemplate'
ComputeProvider = require '../../../../social/lib/social/models/computeproviders/computeprovider'


forEachProvider = (fn, callback) ->

  queue = []

  for providerSlug, provider of PROVIDERS
    queue.push ->
      fn providerSlug, provider
      queue.next()

  queue.push -> callback()

  daisy queue


# this helper registers a new user and creates requested models
withConvertedUserAnd = (models, options, callback) ->

  [options, callback] = [callback, options]  unless callback
  options            ?= {}
  queue               = []

  withConvertedUser options, (data) ->
    { client, user, account } = data
    { group : groupSlug }     = client.context

    _createGroup = (client, options, callback) ->
      group = null

      groupData =
        slug           : groupSlug
        title          : generateRandomString()
        visibility     : 'visible'
        allowedDomains : ['koding.com']

      _queue = [

        ->
          JGroup.create client, groupData, account, (err, group_) ->
            expect(err?.message).to.not.exist
            group = group_
            _queue.next()

        ->
          # if StackTemplate is in models, then create a StackTemplate
          # for the newly created group
          return _queue.next()  unless 'StackTemplate' in models
          _createStackTemplate client, options, ({ stackTemplate }) ->
            query = { $set : { stackTemplates : [stackTemplate._id] } }
            group.update query, (err) ->
              expect(err).to.not.exist
              _queue.next()

        -> callback { group }

      ]

      daisy _queue


    _createCredential = (client, options, callback) ->
      createCredential client, options, (err, data_) ->
        expect(err?.message).to.not.exist
        callback data_


    _createProvisioner = (client, options, callback) ->
      createProvisioner client, options, (err, data_) ->
        expect(err?.message).to.not.exist
        callback data_


    _createStackTemplate = (client, options, callback) ->
      createStackTemplate client, options, (err, data_) ->
        expect(err?.message).to.not.exist
        callback data_


    _createMachine = (client, options, callback) ->
      createMachine client, options, (err, data_) ->
        expect(err).to.not.exist
        callback data_


    _createStack = (client, options, callback) ->
      stackData = { client, user, account, template : data.stackTemplate }
      group             = null
      stackTemplate     = null
      stackTemplateData = null

      _queue = [

        ->
          # adding group to stackData, will be needed while creating stack
          JGroup.one { slug : groupSlug }, (err, group_) ->
            expect(err?.message).to.not.exist
            stackData.group = group = group_
            _queue.next()

        ->
          _createStackTemplate client, options, (data_) ->
            stackData.template = stackTemplate = data_.stackTemplate
            stackTemplateData  = data_.stackTemplateData
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
      stack           = options.stack ? null
      label           = generateRandomString()
      provider        = 'aws'
      generatedFrom   = new ObjectId

      _queue = [

        ->
          return queue.next()  if stack
          _createStack client, options, (data_) ->
            { stack } = data_
            _queue.next()

        ->
          computeProviderOptions = {
            client, stack, provider, label, generatedFrom
            users : []
            provisioners : [data.provisioner ? 'devrim/koding-base']
          }

          ComputeProvider.create client, computeProviderOptions, (err, machine) ->
            expect(err?.message).to.not.exist
            callback { machine, stack }

      ]

      daisy _queue


    models.forEach (model) ->

      # each helper function for the request model will be called
      # the created data will be aggregated in the data variable
      fn = switch model
        when 'Group'            then _createGroup
        when 'Stack'            then _createStack
        when 'Machine'          then _createMachine
        when 'Credential'       then _createCredential
        when 'Provisioner'      then _createProvisioner
        when 'StackTemplate'    then _createStackTemplate
        when 'ComputeProvider'  then _createComputeProvider
        else                      -> callback 'invalid request'

      queue.push ->
        fn client, options, (data_) ->
          data = _.extend data, data_
          queue.next()

    # returning data variable after requested models created
    queue.push -> callback data

    daisy queue


module.exports = {
  forEachProvider
  withConvertedUserAnd
}
