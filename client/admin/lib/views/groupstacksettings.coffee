kd             = require 'kd'

remote         = require('app/remote').getInstance()
FSHelper       = require 'app/util/fs/fshelper'
IDEEditorPane  = require 'ide/workspace/panes/ideeditorpane'

module.exports = class GroupStackSettings extends kd.View

  constructor: (options = {}, data) ->

    options.cssClass = 'group-stack-settings'

    super options, data


  viewAppended: ->

    kd.singletons.appManager.require 'IDE', =>

      file = FSHelper.createFileInstance path: 'localfile:/stack.yml'
      content = """
        provider "aws" {
            access_key = "${var.access_key}"
            secret_key = "${var.secret_key}"
            region = "us-east-1"
        }

        resource "aws_instance" "example" {
            count = 2
            ami = "ami-25773a24"
            instance_type = "t1.micro"
        }
      """

      @addSubView editorContainer = new kd.View
      editorContainer.setCss height: '240px'

      editorContainer.addSubView editorPane  = new IDEEditorPane {
        file, content, delegate: this
      }

      editorPane.setCss background: 'black'

      { JCredential } = remote.api

      JCredential.some {}, { limit: 30 }, (err, credentials)=>

        return console.warn err  if err

        credentials = ({title: c.title, value: c.publicKey} for c in credentials)

        @addSubView new kd.LabelView title: "Select credential to use:"
        @addSubView credentialBox = new kd.SelectBox
          name          : "credential"
          selectOptions : credentials

        @addSubView new kd.ButtonView
          title    : 'Set as default stack'
          loader   : yes
          callback : ->

            terraformContext = editorPane.getValue()
            publicKeys = {aws: credentialBox.getValue()}

            console.log {terraformContext, publicKeys}

            { computeController } = kd.singletons

            computeController.getKloud()

              .checkPlan {terraformContext, publicKeys}

              .then (res) ->
                console.log "WOHOOO RES::", res

              .catch (err) ->
                console.warn "WOJOOO BOM ERR::", err

              .finally =>
                @hideLoader()
