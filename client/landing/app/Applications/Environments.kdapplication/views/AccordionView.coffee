class AccordionView extends KDView

  constructor:(options={}, data)->
    options.panes        or= []
    options.type         or= ""
    options.activePane   or= null
    options.cssClass     or= "kdaccview"
    options.multipleOpen or= no

    @panes = options.panes

    super options, data

    @on "accordionItemClicked", (accItem)->
      @getOptions().activePane = accItem.getOptions().title
      @hideInactivePanes()


  viewAppended:->
    @hideInactivePanes()

  addPanes:(panes)->
    @addPane pane for pane in panes

  addPane:(pane)->
    @addSubView p = pane
    @panes.push p

  removePane:(pane)->
    panes = @getPanes()
    p.destroy() for p in panes when p.id is pane.id

  getPanes:-> @panes

  getPaneByIndex:(index)->
    return pane for pane, i in @getPanes() when i is index

  hideInactivePanes:->
    activePaneName = @getOptions().activePane
    console.log activePaneName
    panes = @getPanes()
    pane.hideContent() for pane in panes when activePaneName and pane.getOptions().title isnt activePaneName


class AccordionPaneView extends KDView
  
  constructor:(options={}, data)->
    options.title    or= null
    options.icon     or= null
    options.cssClass or= 'kdaccpaneview'

    super options, data

    @addSubView @headerView = new AccordionPaneHeaderView
      partial  : @getOptions().title
      delegate : this

    @addSubView @contentView = new AccordionPaneContentView
      delegate : this

  getContentView:-> @contentView
  setContentView:(contentView)-> @contentView = contentView

  setContent:(view)->
    @getContentView().addSubView view

  slide:->
    contentView = @getContentView()

    if contentView.getState() is 'closed'
      contentView.setState 'open'
      contentView.$().slideDown()
      @parent.emit "accordionItemClicked", this
    else
      contentView.setState 'closed'
      contentView.$().slideUp()

  hideContent:->
    # set it to open so slide closes it.
    @getContentView().setState 'open'
    @slide()


class AccordionPaneHeaderView extends KDView

  constructor:(options={}, data)->
    options.cssClass = 'kdaccpaneviewheader'

    super options, data

  click:(event)->
    @getDelegate().slide()


class AccordionPaneContentView extends KDView

  constructor:(options={}, data)->
    options.cssClass or= 'kdaccpaneviewcontent'
    data             or= {}
    data.state       or= 'open'    

    super options, data

    @setState data.state

  setState:(state)->
    @getData().state = state

  getState:->
    @getData().state