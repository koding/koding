*Splitted Case:*

  - KDSplitViewPanel
     - KDSplitView
       - KDSplitViewPanel
         - IDEView
           - IDEApplicationTabView
             - KDTabPaneView
               - IDETerminalPanel
       - KDSplitViewPanel
       ....


*Unsplitted Case:*

  - KDSplitViewPanel
     - IDEView
       - IDEApplicationTabView
         - KDTabPaneView
           - IDETerminalPane
             - KDTabPaneView
               - IDETerminalPanel


*Sample JSON Data:*
  ```
  [
    {
      "type": "split",
      "direction": "horizontal",
      "views": [
        {
          "type": "split",
          "direction": "vertical",
          "isFirst": true,
          "views": [
            { "context": ... }
            { "context": ... }
          ]
        },
        {
          "type": "split",
          "direction": "vertical",
          "views": []
        }
      ]
    },
    {
      "type": "split",
      "direction": "horizontal",
      "views": [
        {
          "type": "split",
          "direction": "vertical",
          "views": []
        }
      ]
    }
  ]
  ```