{Module} = require 'jraphical'

module.exports = class JMarkdownDoc extends Module

  @share()

  @set
    schema      :
      content   : String
      html      : String
      checksum  : String

  @generateHTML=(content)->
    options =
      gfm : yes
      sanitize : yes
      highlight : (code, lang)->
        hljs = require('highlight.js')
        try
          hljs.highlight(lang, code).value
        catch e
          try
            hljs.highlightAuto(code).value
          catch _e
            code
      breaks : yes
      langPrefix : 'lang-'
    marked = require('marked')
    marked.setOptions options
    marked content

  @generateChecksum=(content)->
    require('crypto')
      .createHash('sha1')
      .update(content)
      .digest 'hex'

  update:(atomically)->
    setOp = atomically.$set ?= {}
    setOp.html = JMarkdownDoc.generateHTML setOp.content
    setOp.checksum = JMarkdownDoc.generateChecksum setOp.content
    Module::update.apply this, arguments

  @create = (formData, callback)->

    data = formData
    data.html = @generateHTML data.content
    data.checksum = @generateChecksum data.content

    markdownDoc = new @ data
    markdownDoc.save (err)->
      if err then callback err
      else callback null, markdownDoc