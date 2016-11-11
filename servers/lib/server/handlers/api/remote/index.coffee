
KONFIG    = require 'koding-config-manager'
async     = require 'async'

{ sendApiError, sendApiResponse } = require '../helpers'
{ generateFakeClient } = require '../../../client'

apiErrors = require '../errors'
Models    = (require '../../../bongo').models

getModel = (name) ->
  for own model, konstructor of Models
    return model  if model.toLowerCase() is name


module.exports = RemoteHandler = (req, res, next) ->

  generateFakeClient req, res, (err, client) ->
    if err or not client
      sendApiError res, apiErrors.unauthorizedRequest
      return

    { method: METHOD }     = req
    { model, instance_id } = req.params

    unless model
      sendApiError res, apiErrors.invalidInput
      return

    [ model, method ] = model.split '.'

    unless method
      sendApiError res, apiErrors.invalidInput
      return

    model = getModel model

    unless model
      sendApiError res, apiErrors.invalidInput
      return

    sendResponse = (err, data) ->

      if err
        sendApiError res, { ok: false, error: err }

      else
        res.status(200)
          .send { ok: true, data }
          .end()


    if instance_id
      Models[model].one { _id: instance_id }, (err, instance) ->

        if err
          sendApiError res, { ok: false, error: err }

        else if not instance
          sendApiError res, { ok: false, error: 'No instance found' }

        else
          instance["#{method}$"] client, sendResponse

    else
      Models[model][method] req.body, sendResponse
