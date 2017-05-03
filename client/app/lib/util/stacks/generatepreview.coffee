jspath = require 'jspath'
requirementsParser = require './requirementsparser'

module.exports = generatePreview = (options = {}, callback) ->

  { account, group, template, custom = {} } = options

  availableData = { group, account, custom }
  requiredData  = requirementsParser template
  errors        = {}
  warnings      = {}

  processTemplate = ->

    for type, data of requiredData

      for field in data

        if type is 'userInput'
          warnings.userInput ?= []
          warnings.userInput.push field
          continue

        if content = jspath.getAt availableData[type], field
          search   = if type is 'custom'
          then ///\${var\.#{type}_#{field}}///g
          else ///\${var\.koding_#{type}_#{field}}///g
          template = template.replace search, content.replace /\n/g, '\\n'
        else
          errors[type] ?= []
          errors[type].push field

    callback null, { errors, warnings, template }

  if requiredData.user?
    account.fetchFromUser requiredData.user, (err, data) ->
      kd.warn err  if err
      availableData.user = data or {}
      processTemplate()
  else
    processTemplate()
