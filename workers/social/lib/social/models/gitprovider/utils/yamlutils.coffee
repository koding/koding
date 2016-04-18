jsyaml = require 'js-yaml'

sanitize = (content) ->

  newContent = ''
  for line in content.split '\n'
    newContent += "#{line.trimRight()}\n"

  return newContent


module.exports = {

  jsonToYaml: (content, silent = no) ->

    contentType     = 'json'

    unless typeof content is 'string'
      content       = JSON.stringify content

    try
      contentObject = JSON.parse content

      content       = jsyaml.safeDump contentObject
      contentType   = 'yaml'

    catch err
      console.error '[JsonToYaml]', err  unless silent

    contentObject or= {}

    return { content, contentType, contentObject, err }


  yamlToJson: (content, silent = no) ->

    contentType     = 'yaml'

    try
      content       = sanitize content
      contentObject = jsyaml.safeLoad content

      content       = JSON.stringify contentObject
      contentType   = 'json'
    catch err
      console.error '[YamlToJson]', err  unless silent

    contentObject or= {}

    return { content, contentType, contentObject, err }

}
