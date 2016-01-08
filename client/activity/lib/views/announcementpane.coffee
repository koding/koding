kd = require 'kd'
TopicMessagePane = require './topicmessagepane'
checkFlag = require 'app/util/checkFlag'


module.exports = class AnnouncementPane extends TopicMessagePane

  constructor: (options, data) ->

    options.cssClass = kd.utils.curry "announcement-pane", options.cssClass

    super options, data


  viewAppended: ->

    @addSubView @scrollView
    @scrollView.wrapper.addSubView @channelTitleView
    @scrollView.wrapper.addSubView @input  if checkFlag 'super-admin'
    @scrollView.wrapper.addSubView @listController.getView()


  createContentViews: ->

    data = @getData()
    options = @getContentOptions()

    @mostRecent = @createMostRecentView options, data

    # TODO: enabling search results is OK, but the input needs a close box.
    # @searchResults = @createSearchResultsView options, data

  createInputWidget: -> super "Enter announcement here"

  createSearchInput: ->
    # TODO: remove this stub method when re-enabling announcement search.

  getPaneData: ->
    [
      {
        name          : 'Most Recent'
        view          : @mostRecent
        closable      : no
        hiddenHandle  : yes
        route         : '/Activity/Public/Recent'
      }
      # {
      #   name          : 'Search Tab'
      #   view          : @searchResults
      #   closable      : no
      #   shouldShow    : no
      #   hiddenHandle  : yes
      # }
    ]
