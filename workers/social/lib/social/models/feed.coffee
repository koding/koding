jraphical = require 'jraphical'

module.exports = class JFeed extends jraphical.Module
  @set
    schema:
      title: String
      description: String
      owner: String
      meta: require 'bongo/bundles/meta'
    relationships:
      content       :
        as          : 'container'
        targetType  : ["CActivity", "JStatusUpdate", "JCodeSnip", "JComment"]