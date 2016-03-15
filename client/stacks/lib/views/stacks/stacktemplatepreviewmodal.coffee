kd                       = require 'kd'
KDTabView                = kd.TabView
KDModalView              = kd.ModalView
applyMarkdown            = require 'app/util/applyMarkdown'
KDTabPaneView            = kd.TabPaneView
KDCustomHTMLView         = kd.CustomHTMLView
StackTemplateEditorView  = require './editors/stacktemplateeditorview'


module.exports = class StackTemplatePreviewModal extends KDModalView


  constructor: (options = {}, data) ->

    options.title           = 'Template Preview'
    options.subtitle        = 'Generated from your account data'
    options.cssClass        = kd.utils.curry 'stack-template-preview content-modal', options.cssClass
    options.height        or= 500
    options.width         or= 757
    options.overlay         = yes
    options.overlayOptions  = { cssClass : 'second-overlay' }

    super options, data

    { errors, warnings } = @getData()

    errors   = createReportFor errors,   'errors'
    warnings = createReportFor warnings, 'warnings'

    @addSubView new KDCustomHTMLView
      cssClass : 'has-markdown'
      partial  : applyMarkdown """
        #{errors}
        #{warnings}
        """

    @addSubView @tabView = new KDTabView { hideHandleCloseIcons : yes }

    @createYamlView()
    @createJSONView()

    @tabView.showPaneByIndex 0


  createYamlView: ->

    options = {
      contentType       : 'yaml'
      targetContentType : 'yaml'
    }

    view = @createEditorView options

    @tabView.addPane yaml = new KDTabPaneView {
      name : 'YAML'
      view
    }


  createJSONView: ->

    options = {
      contentType       : 'yaml'
      targetContentType : 'json'
    }

    view = @createEditorView options

    @tabView.addPane yaml = new KDTabPaneView {
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
