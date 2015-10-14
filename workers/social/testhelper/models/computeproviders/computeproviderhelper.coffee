{ daisy
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
    stack         = null
    stackTemplate = null

    _createStackTemplate = (client, options, callback) ->
      createStackTemplate client, options, (err, template) ->
        expect(err).to.not.exist
        data.stackTemplate     = stackTemplate = template.stackTemplate
        data.stackTemplateData = template.stackTemplateData
        callback data

    _createStackFromTemplate = (stackData, options, callback) ->
      ComputeProvider.generateStackFromTemplate stackData, options, (err, { stack }) ->
        expect(err?.message).to.not.exist
        callback { stack }

    models.forEach (model) ->

      switch model
        when 'StackTemplate'
          queue.push ->
            return queue.next()  if stackTemplate
            _createStackTemplate client, options, (data_) ->
              { stackTemplate } = data_
              queue.next()

        when 'Stack'
          queue.push ->
            stackData = { client, user, account, template : stackTemplate }

            _queue = [

              ->
                # adding group to stackData, will be needed while creating stack
                JGroup.one { slug : groupSlug }, (err, group) ->
                  expect(err).to.not.exist
                  stackData.group = data.group = group
                  _queue.next()

              ->
                # if stackTemplate already exists, skip this step
                return queue.next()  if stackTemplate
                _createStackTemplate client, options, (data_) ->
                  { stackTemplate }  = data_
                  stackData.template = stackTemplate
                  _queue.next()

              ->
                # create a stack from the given template
                _createStackFromTemplate stackData, options, ({ stack }) ->
                  data.stack = stack
                  _queue.next()

              -> queue.next()

            ]

            daisy _queue

        when 'Provisioner'
          queue.push ->
            createProvisioner client, options, (err, { provisioner }) ->
              expect(err).to.not.exist
              data.provisioner = provisioner
              queue.next()

    queue.push -> callback data

    daisy queue


module.exports = {
  withConvertedUserAnd
}

