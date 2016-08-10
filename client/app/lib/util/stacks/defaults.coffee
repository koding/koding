defaultTemplate = require './defaulttemplate'
generateStackTemplateTitle = require 'app/util/generateStackTemplateTitle'
generateTemplateRawContent = require 'app/util/generateTemplateRawContent'


module.exports = {
  title: generateStackTemplateTitle()
  description: '''
    ###### Stack Template Readme

    You can write a readme for this stack template here.
    It will be displayed whenever a user attempts to build this stack.
    You can use markdown within the readme content.

  '''

  template: defaultTemplate.json
  rawContent: defaultTemplate.yaml
  credentials: {}
  templateDetails: null
}

