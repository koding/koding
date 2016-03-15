kd                          = require 'kd'

curryIn                     = require 'app/util/curryIn'

StackTemplateList           = require 'app/stacks/stacktemplatelist'
StackTemplateListController = require 'app/stacks/stacktemplatelistcontroller'


module.exports = class StackTemplateListView extends kd.View

  constructor: (options = {}, data) ->

    curryIn options, { cssClass: 'stack-template-list' }

    super options, data

    @list           = new StackTemplateList
    @listController = new StackTemplateListController
      view       : @list
      wrapper    : no
      scrollView : no
      viewType   : options.viewType

    @listView = @listController.getView()


  viewAppended: ->

    @addSubView @listView
