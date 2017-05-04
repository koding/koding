{ _
  async
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
    queue.push (next) ->
      fn providerSlug, provider, next

  async.series queue, callback


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
        customize      : { membersCanCreateStacks: yes }
        visibility     : 'visible'
        allowedDomains : ['koding.com']

      async.series [

        (next) ->
          JGroup.create client, groupData, account, (err, group_) ->
            group = group_
            next err

        (next) ->
          # if StackTemplate is in models, then create a StackTemplate
          # for the newly created group
          return next()  unless 'StackTemplate' in models
          _createStackTemplate client, options, ({ stackTemplate }) ->
            query = { $set : { stackTemplates : [stackTemplate._id] } }
            group.update query, next

      ], (err) ->
        expect(err).to.not.exist
        callback { group }


    _createCredential = (client, options, callback) ->
      createCredential client, options, (err, data_) ->
        expect(err).to.not.exist
        callback data_


    _createProvisioner = (client, options, callback) ->
      createProvisioner client, options, (err, data_) ->
        expect(err).to.not.exist
        callback data_


    _createStackTemplate = (client, options, callback) ->
      createStackTemplate client, options, (err, data_) ->
        expect(err).to.not.exist
        callback data_


    _createMachine = (client, options, callback) ->
      createMachine client, options, (err, data_) ->
        expect(err).to.not.exist
        callback data_


    _createStack = (client, options, callback) ->
      stackTemplateData = null
      stackData = { client, user, account, template : data.stackTemplate }

      async.series {

        group: (next) ->
          # adding group to stackData, will be needed while creating stack
          JGroup.one { slug : groupSlug }, (err, group) ->
            stackData.group = group
            next err, group

        stackTemplate: (next) ->
          _createStackTemplate client, options, (data_) ->
            stackData.template = stackTemplate = data_.stackTemplate
            stackTemplateData  = data_.stackTemplateData
            next null, data_.stackTemplate

        stackTemplateData: (next) -> next null, stackTemplateData

        stack: (next) ->
          # create a stack from the given template
          ComputeProvider.generateStackFromTemplate stackData, options, (err, { stack }) ->
            next err, stack

      }, (err, results) ->
        expect(err).to.not.exist
        callback results


    _createComputeProvider = (client, options, callback) ->
      client.r = { group : groupSlug, user, account }
      stack    = options.stack ? null

      async.series {

        stack: (next) ->
          return next()  if stack
          _createStack client, options, (data_) ->
            { stack } = data_
            next null, stack

        machine: (next) ->
          computeProviderOptions =
            stack         : stack
            users         : []
            label         : generateRandomString()
            client        : client
            provider      : 'aws'
            provisioners  : [data.provisioner ? 'devrim/koding-base']
            generatedFrom : new ObjectId

          ComputeProvider.create client, computeProviderOptions, next

      }, (err, results) ->
        expect(err).to.not.exist
        callback results


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
        else                    -> callback 'invalid request'

      queue.push (next) ->
        fn client, options, (data_) ->
          data = _.extend data, data_
          next()

    # returning data variable after requested models created
    async.series queue, -> callback data


module.exports = {
  forEachProvider
  withConvertedUserAnd
}
