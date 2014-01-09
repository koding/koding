class TopicSplitViewController extends KDViewController
  constructor:(options={}, data)->
    options = $.extend
      view : new ContentPageSplitBelowHeader
        # views     : [null,null]
        sizes     : [139,null]
        minimums  : [10,null]
        resizable : no
        # colored   : yes
    ,options
    super options, data
  
  loadView:(topicSplit)->
    log topicSplit
    topicSplit._windowDidResize()
# 
# 
# class TopicSplitView extends ContentPageSplitBelowHeader
