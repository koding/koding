defaultTemplate = require './views/stacks/defaulttemplate'
generateStackTemplateTitle = require 'app/util/generateStackTemplateTitle'
generateTemplateRawContent = require 'app/util/generateTemplateRawContent'


module.exports = {
  title: generateStackTemplateTitle()
  description: '''
    ##### Readme text for this stack template

    You can write down a readme text for new users.
    This text will be shown when they want to use this stack.
    You can use markdown with the readme content.

  '''

  template: defaultTemplate
  rawContent: generateTemplateRawContent defaultTemplate
  credentials: {}
  templateDetails: null
}
