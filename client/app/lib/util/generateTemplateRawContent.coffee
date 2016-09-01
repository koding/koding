{ jsonToYaml } = require 'app/util/stacks/yamlutils'

module.exports = (jsonTemplate, addReadme = yes) ->

  readme = if addReadme then '''
    # Here is your stack preview
    # You can make advanced changes like modifying your VM,
    # installing packages, and running shell commands.


  '''
  else ''

  return "#{readme}#{jsonToYaml(jsonTemplate).content}"
