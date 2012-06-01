class EditorBottomBarWithSyntaxOnly extends Editor_BottomBar
  viewAppended:()->
    @addSubView rightWrapper = new KDView cssClass : "bottom-right-wrapper clearfix" 
    rightWrapper.addSubView new Editor_BottomBar_SyntaxSelector delegate: @
