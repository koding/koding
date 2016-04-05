kd                          = require 'kd'
curryIn                     = require 'app/util/curryIn'
StackTemplateList           = require 'app/stacks/stacktemplatelist'
StackTemplateListController = require 'app/stacks/stacktemplatelistcontroller'


module.exports = class StackTemplateListView extends kd.View

  constructor: (options = {}, data) ->

    curryIn options, { cssClass: 'stack-template-list' }

    super options, data

    @listController = new StackTemplateListController
      view          : new StackTemplateList
      viewType      : options.viewType

    @listView = @listController.getView()


  viewAppended: ->

    @addSubView @listView
