kd                          = require 'kd'

curryIn                     = require 'app/util/curryIn'

StackTemplateList           = require 'app/stacks/stacktemplatelist'
StackTemplateListController = require 'app/stacks/stacktemplatelistcontroller'


module.exports = class StackTemplateListView extends kd.View

  constructor: (options = {}, data) ->

    curryIn options, cssClass: 'stack-template-list'

    super options, data


  viewAppended: ->

    @listView       = new StackTemplateList
    @listController = new StackTemplateListController
      view       : @listView
      wrapper    : no
      scrollView : no

    @addSubView @getView()


  getView: -> @listController.getView()