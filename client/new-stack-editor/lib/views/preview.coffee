kd = require 'kd'

whoami = require 'app/util/whoami'
applyMarkdown = require 'app/util/applyMarkdown'
generatePreview = require 'app/util/stacks/generatepreview'

Editor = require './editor'


module.exports =

  stack: (preview, customVariables) ->

    preview ?= new Editor { readonly: yes }
    preview.setContent 'Generating preview...'

    @ready =>

      template = @getContent()
      group    = kd.singletons.groupsController.getCurrentGroup()
      account  = whoami()
      options  = { template, account, group }

      getPreview = =>

        unless @hasClass 'preview-mode'
          customVariables.aceView.ace.off 'FileContentChanged', getPreview
          return

        # TODO show errors in place in somewhere
        [ err, custom = {} ] = customVariables.parseContent()
        options.custom = custom

        generatePreview options, (err, { template }) ->
          # TODO show errors and warnings in place in somewhere
          preview.setContent template, 'yaml'

      getPreview options

      customVariables.aceView.ace.on 'FileContentChanged', getPreview

    return preview


  readme: (preview) ->

    preview ?= new kd.View { cssClass: 'has-markdown' }

    @ready =>
      preview.updatePartial applyMarkdown @getContent()

    return preview
