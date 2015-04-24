kd             = require 'kd'
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

      @addSubView editorPane  = new IDEEditorPane { file, content, delegate: this }
      editorPane.setCss background: 'black'
