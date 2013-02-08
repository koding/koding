{Module} = require 'jraphical'

module.exports = class JReadme extends Module

  @share()

  @set
    schema :
      content : String
      meta    : require 'bongo/bundles/meta'
