jsyaml = require 'js-yaml'

sanitize = (content) ->

  newContent = ''
  for line in content.split '\n'
    newContent += "#{line.trimRight()}\n"

  return newContent


module.exports = {

  jsonToYaml: (content) ->

    contentType     = 'json'

    try
      contentObject = JSON.parse content

      content       = jsyaml.safeDump contentObject
      contentType   = 'yaml'

    catch err
      console.error '[JsonToYaml]', err

    return { content, contentType, err }


  yamlToJson: (content) ->

    contentType     = 'yaml'

    try
      content       = sanitize content
      contentObject = jsyaml.safeLoad content

      content       = JSON.stringify contentObject
      contentType   = 'json'
    catch err
      console.error '[YamlToJson]', err

    return { content, contentType, err }

}