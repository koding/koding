class DevToolsMainView extends KDView

  viewAppended:->

    KD.getSingleton("appManager").require "Ace", =>
      @addSubView new CollaborativeWorkspace
        name                : "Kodepad"
        delegate            : this
        firebaseInstance    : "tw-local"
        panels              : [
          buttons           : [
            {
              title: "Hello"
              callback: (panel, workspace) ->
                log "hello", panel, workspace
            }
          ]
          layout            :
            direction       : "vertical"
            sizes           : [ "265px", null ]
            splitName       : "BaseSplit"
            views           : [
              {
                type        : "finder"
                name        : "finder"
                editor      : "JSEditor"
              }
              {
                type        : "split"
                options     :
                  direction : "horizontal"
                  sizes     : [ "50%", "50%" ]
                  splitName : "InnerSplit"
                views       : [
                  {
                    type    : "tabbedEditor"
                    name    : "JSEditor"
                  }
                  {
                    type    : "editor"
                    name    : "CSSEditor"
                  }
                ]
              }
            ]
        ]