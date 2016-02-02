konstraints = require 'konstraints'

module.exports = constraintChecker = (template, rules) ->

  return 'No template or rules given.'  if not template or not rules

  if typeof template is 'string'
    try
      template = JSON.parse template
    catch
      return { message: 'Template is not valid JSON' }

  { passed, results } = konstraints template, rules, log: yes

  return results.last[1]  unless passed
  return null
