class DevToolsMainView extends KDView

  viewAppended:->

    @addSubView @workspace      = new CollaborativeWorkspace
      name                      : "Kodepad"
      delegate                  : this
      firebaseInstance          : "tw-local"
      panels                    : [
        title                   : "Koding DevTools"
        buttons                 : [
          {
            title               : "Create"
            callback            : KD.singletons.kodingAppsController.makeNewApp
          }
          {
            title               : "Run"
            callback            : @bound 'previewApp'
          }
          {
            title               : "Hide Filetree"
            itemClass           : KDToggleButton
            states              : [
              {
                title           : 'Hide Filetree'
                callback        : (cb)=>
                  @workspace.activePanel.layoutContainer
                    .splitViews.BaseSplit.resizePanel 0, 0, cb
              }
              {
                title           : 'Show Filetree'
                callback        : (cb)=>
                  @workspace.activePanel.layoutContainer
                    .splitViews.BaseSplit.resizePanel "258px", 0, cb
              }
            ]
