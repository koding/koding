kd = require 'kd'

hljs    = require 'highlight.js'
Encoder = require 'htmlencode'

{ jsonToYaml } = require 'admin/views/stacks/yamlutils'

module.exports = class StackTemplateContentModal extends kd.ModalView

  constructor: (options = {}, data) ->

    options.cssClass = 'stack-template-content has-markdown'

    options.title    = data.title
    options.subtitle = data.modifiedAt

    options.overlay  = yes
    options.overlayOptions = cssClass : 'second-overlay'

    super


  getContent: ->

    { template: { content } } = @getData()

    json = Encoder.htmlDecode content
    yaml = jsonToYaml(json).content

    return hljs.highlight('coffee', yaml).value


  viewAppended: ->

    scrollView = new kd.CustomScrollView tagName: 'pre'
    scrollView.wrapper.addSubView new kd.CustomHTMLView
      tagName: 'code'
      partial: @getContent()

    @addSubView scrollView
