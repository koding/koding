class DemosMainView extends KDScrollView

  viewAppended:->

    @addSubView @tabHandleContainer = new ApplicationTabHandleHolder
      delegate          : @
      addPlusHandle     : yes

    @addSubView @tabView = new ApplicationTabView
      delegate                  : @
      sortable                  : yes
      closeAppWhenAllTabsClosed : no
      resizeTabHandles          : no
      lastTabHandleMargin       : 200
      maxHandleWidth            : 200
      tabHandleContainer        : @tabHandleContainer

    for i in [0..5]
      pane   = new KDTabPaneView
        name : "#{i} --- SOME FILE asdas das d"
      pane.addSubView new KDCustomHTMLView
        cssClass  : "no-file"
        partial   : """
          <h1 style='color:white'>SOME FILE -- #{i}</h1>
        """
      @tabView.addPane pane

