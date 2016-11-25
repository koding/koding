kd = require 'kd'
applyMarkdown = require 'app/util/applyMarkdown'
ContentModal = require 'app/components/contentModal'
StackTemplateEditorView  = require './stacktemplateeditorview'

module.exports = class StackTemplatePreviewModal extends ContentModal


  constructor: (options = {}, data) ->

    options.title           = 'Template Preview'
    options.cssClass        = kd.utils.curry 'stack-template-preview content-modal', options.cssClass
    options.overlay         = yes
    options.overlayOptions  = { cssClass : 'second-overlay' }
    options.buttons         = null

    super options, data

    { errors, warnings } = @getData()

    errors   = createReportFor errors,   'errors'
    warnings = createReportFor warnings, 'warnings'

    @main.addSubView container = new kd.CustomHTMLView

    container.addSubView new kd.CustomHTMLView
      partial : "<p class='preview-label'>This preview renders variables such as ${var.koding_user_username} to their actual values.</p>"

    container.addSubView new kd.CustomHTMLView
      cssClass : 'has-markdown'
      partial  : applyMarkdown """
        #{errors}
        #{warnings}
        """

    container.addSubView @tabView = new kd.TabView { hideHandleCloseIcons : yes }

    @tabView.addSubView expandButton = new kd.ButtonView
      cssClass : 'solid compact solid-bg expand-button'
      title    : 'Expand'
      callback : =>
        @unsetClass 'stack-template-preview'
        @setClass 'expanded-stack-template-preview'
        @minimizeButton.show()
        @resizeOpenPane()

    @tabView.addSubView @minimizeButton = new kd.ButtonView
      cssClass : 'solid compact solid-bg minimize-button hidden'
      title    : 'Collapse'
      callback : =>
        @setClass 'stack-template-preview'
        @unsetClass 'expanded-stack-template-preview'
        @minimizeButton.hide()
        @resizeOpenPane()

    @createYamlView()
    @createJSONView()

    @tabView.showPaneByIndex 0
    @tabView.on 'PaneDidShow', => @resizeOpenPane()


  resizeOpenPane: ->

    return window.dispatchEvent new Event 'resize'


  createYamlView: ->

    options = {
      contentType       : 'yaml'
      targetContentType : 'yaml'
    }

    view = @createEditorView options

    @tabView.addPane yaml = new kd.TabPaneView {
      name : 'YAML'
      view
    }


  createJSONView: ->

    options = {
      contentType       : 'yaml'
      targetContentType : 'json'
    }

    view = @createEditorView options

    @tabView.addPane yaml = new kd.TabPaneView {
      name : 'JSON'
      view
    }


  createEditorView : (options) ->

    { contentType, targetContentType } = options
    { template } = @getData()

    new StackTemplateEditorView
      delegate          : this
      content           : template
      readOnly          : yes
      contentType       : contentType
      showHelpContent   : no
      targetContentType : targetContentType


  createReportFor = (data, type) ->

    if (Object.keys data).length > 0
      console.warn "#{type.capitalize()} for preview requirements: ", data

      issues = ''
      for issue of data
        if issue is 'userInput'
          issues += " - These variables: `#{data[issue]}`
                        will be requested from user.\n"
        else
          issues += " - These variables: `#{data[issue]}`
                        couldn't find in `#{issue}` data.\n"
    else
      issues = ''

    return issues
