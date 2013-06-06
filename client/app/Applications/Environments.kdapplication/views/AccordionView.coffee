class AccordionView extends KDView

  constructor:(options={}, data)->
    options.panes      or= []
    options.type       or= ""
    options.activePane or= null
    options.cssClass   or= "kdaccview"

    @panes = options.panes

    super options, data

  viewAppended:->
    activePaneName = @getOptions().activePane
    pane.hideContent() for pane in @panes when activePaneName and pane.getOptions().title isnt activePaneName

  addPanes:(panes)->
    @addPane pane for pane in panes

  addPane:(pane)->
    @panes.push pane
    @addSubView pane

  removePane:(pane)->
    @panes.forEach (p) ->
      del @panes[p] if p is pane


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
    contentViewData = contentView.getData()

    if contentViewData.state is 'closed'
      contentViewData.state = 'open'
      contentView.$().slideDown()
    else
      contentViewData.state = 'closed'
      contentView.$().slideUp()

  hideContent:->
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