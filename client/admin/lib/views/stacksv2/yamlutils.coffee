jsyaml = require 'js-yaml'

module.exports = {

  jsonToYaml: (content) ->

    contentType     = 'json'

    try
      contentObject = JSON.parse content

      content       = jsyaml.safeDump contentObject
      contentType   = 'yaml'

    catch err
      console.error '[JsonToYaml]', err

    console.log '[JsonToYaml]', { content, contentType, err }

    return { content, contentType, err }


  yamlToJson: (content) ->

    contentType     = 'yaml'

    try
      contentObject = jsyaml.safeLoad content

      content       = JSON.stringify contentObject
      contentType   = 'json'
    catch err
      console.error '[YamlToJson]', err

    console.log '[YamlToJson]', { content, contentType, err }

    return { content, contentType, err }

}