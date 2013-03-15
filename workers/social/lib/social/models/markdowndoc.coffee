{Module} = require 'jraphical'

module.exports = class JMarkdownDoc extends Module

  @share()

  @set
    schema      :
      content   : String
      html      : String
      checksum  : String

  update:(atomically)->
    setOp = atomically.$set ?= {}
    setOp.html = require('marked') setOp.content
    setOp.checksum = require('crypto')
      .createHash('sha1')
      .update(@content)
      .digest 'hex'
    Module::update.apply this, arguments