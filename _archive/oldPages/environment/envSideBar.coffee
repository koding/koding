class EnvironmentSideBarController extends KDViewController
  loadView:(mainView)->
    @listenTo
      KDEventTypes : "ApplicationWantsToBeShown"
      callback : (pubInst,event)=>
        @init() if event.options.name is "Environment"

  init:()->
    return if @_initiated
    @_initiated = yes
    @createSubLists @menus

  createSubLists:(data)->
    mainView = @getView()

    for key,listData of data

      mainView.addSubView header = new EnvironmentSideBarHeaderView type : "small", title : listData.title
      mainView.addSubView envSideBarSection = new EnvironmentSideBarAccordionSection
        cssClass : "#{listData.type}"
        delegate : header
      envSideBarSection.hide()

      envSideBarSection.addSubView list = new EnvironmentSideBarAbstractList
        itemClass : EnvironmentSideBarListItems[key],listData

      envSideBarSection.addSubView new EnvironmentSideBarAddLink
        cssClass : "add-item-btn"
        delegate : list,listData

  menus :
    environment:
      title : "Your Environments"
      type : "environment"
      items : [
          { title : 'sinan',          description : 'Shared Environment' }
          { title : 'My Ruby',        description : 'Dedicated Heroku Compatible Environment' }
        ]
    database:
      title : "Your Databases"
      type : "database"
      items : [
          { title : 'DB1235',          description : 'Shared MySQL Database' }
          { title : 'DB1235',          description : 'Dedicated MongoDB Database' }
        ]
    deployTarget:
      title : "Your Deploy Targets"
      type : "deploy-target"
      items : [
          { title : 'zikkim.com Production',  description : 'AWS' }
          { title : 'My Heroku',              description : 'Heroku' }
        ]

class EnvironmentSideBar extends KDView

class EnvironmentSideBarHeaderView extends KDHeaderView
  viewAppended:->
    # @$().prepend "<span class='arrow down'></span>"
    @$().prepend "<span class='arrow'></span>"

class EnvironmentSideBarAccordionSection extends KDView
  viewAppended:->

    @listenTo
      KDEventTypes : "click"
      listenedToInstance : @getDelegate()
      callback : @_toggleView

  _toggleView:->
    if @$().is ":visible"
      @$().slideUp 200
      @getDelegate().$('span.arrow').removeClass "down"
    else
      # disabledForBeta
      # @$().slideDown 200
      # @getDelegate().$('span.arrow').addClass "down"

class EnvironmentSideBarAbstractList extends KDListView
  setDomElement:(cssClass)->
    @domElement = $ "<ul class='kdview #{cssClass}'></ul>"

class EnvironmentSideBarAddLink extends KDCustomHTMLView
  constructor:(options,data)->
    partial = switch data.type
      when "environment"    then "<span>+</span><cite>Add New Environment</cite>"
      when "database"       then "<span>+</span><cite>Add New Database</cite>"
      when "deploy-target"  then "<span>+</span><cite>Add Deploy Target</cite>"

    options = $.extend
      tagName : "a"
      partial : "#{partial}"
    ,options
    super options,data

  click:->
    log "Add New asdas dasdasd"


EnvironmentSideBarListItems = {}

class EnvironmentSideBarListItems.environment extends KDListItemView
  viewAppended:->
    @setClass "environment"
    super

  partial:(data)->
    """
      <div>
      <div class='icon-wrapper'><span class='icon environment'></span></div>
      <div class='content-wrapper'>
        <strong>#{data.title}</strong>
        <p>#{data.description}</p>
      </div>
      </div>
    """
  setDomElement:(cssClass)->
    @domElement = $ "<li class='kdview #{cssClass}'></li>"

class EnvironmentSideBarListItems.database extends KDListItemView
  viewAppended:->
    @setClass "database"
    super

  partial:(data)->
    """
      <div>
      <div class='icon-wrapper'><span class='icon database'></span></div>
      <div class='content-wrapper'>
        <strong>#{data.title}</strong>
        <p>#{data.description}</p>
      </div>
      </div>
    """

  setDomElement:(cssClass)->
    @domElement = $ "<li class='kdview #{cssClass}'></li>"

class EnvironmentSideBarListItems.deployTarget extends KDListItemView
  viewAppended:->
    @setClass "deploy-target"
    super

  partial:(data)->
    """
      <div>
      <div class='icon-wrapper'><span class='icon deploy-target'></span></div>
      <div class='content-wrapper'>
        <strong>#{data.title}</strong>
        <p>#{data.description}</p>
      </div>
      </div>
    """

  setDomElement:(cssClass)->
    @domElement = $ "<li class='kdview #{cssClass}'></li>"

  click:->
    @setClass "camiryo"



