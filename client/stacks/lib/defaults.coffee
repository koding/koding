{ jsonToYaml } = require './views/stacks/yamlutils'

defaultTemplate = require './views/stacks/defaulttemplate'

module.exports = {
  title: 'Default Stack Template'
  description: '''
      ##### Readme text for this stack template

      You can write down a readme text for new users.
      This text will be shown when they want to use this stack.
      You can use markdown with the readme content.


    '''

  template: defaultTemplate
  rawContent: jsonToYaml(defaultTemplate).content
  credentials: {}
  templateDetails: null
}
