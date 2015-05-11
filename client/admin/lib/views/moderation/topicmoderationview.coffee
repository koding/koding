kd                    = require 'kd'
remote                = require('app/remote').getInstance()
KDView                = kd.View
KDTabView             = kd.TabView
KDTabPaneView         = kd.TabPaneView
TopicCommonView       = require './topiccommonview.coffee'
KDCustomHTMLView      = kd.CustomHTMLView
KDHitEnterInputView   = kd.HitEnterInputView
KDListViewController  = kd.ListViewController


module.exports = class TopicModerationView extends KDView

  constructor: (options = {}, data) ->

    options.cssClass = 'member-related'

    super options, data

    @createTabView()


  createTabView: ->

    @addSubView @tabView = new KDTabView hideHandleCloseIcons: yes

    @tabView.addPane @allTopicsPane         = new KDTabPaneView name: 'All Topics'
    @tabView.addPane @deletedTopicsPane     = new KDTabPaneView name: 'Deleted Topics'
    
    @tabView.showPaneByIndex 0

    @allTopicsPane.addSubView       new TopicCommonView { typeConstant: "topic" }, @getData()
    @deletedTopicsPane.addSubView   new TopicCommonView { typeConstant: "linkedtopic" }, @getData()

