class EnvironmentContainer extends KDDiaContainer

  constructor:(options={}, data)->

    options.cssClass   = KD.utils.curry 'environments-container', options.cssClass
    options.bind       = 'scroll mousewheel wheel'
    # options.draggable  = yes

    super options, data

    title   = @getOption 'title'
    @header = new KDHeaderView {type : "medium", title}

    @itemHeight = options.itemHeight ? 44

    @on "DataLoaded", => @_dataLoaded = yes
    # @on "DragFinished", @bound 'savePosition'

    @newItemPlusForGroups = new KDCustomHTMLView
      cssClass   : 'new-item-plus-for-groups'
      partial    : "<i></i><span>Shared VM</span>"
      click      : =>
        @emit 'PlusButtonForGroupsClicked'

    @newItemPlus = new KDCustomHTMLView
      cssClass   : 'new-item-plus'
      partial    : "<i></i><span>Add new</span>"
      click      : =>
        @once 'transitionend', @emit 'PlusButtonClicked'

    @newItemPlus.bindTransitionEnd()
    @newItemPlusForGroups.bindTransitionEnd()

    @loader = new KDLoaderView
      cssClass   : 'new-item-loader hidden'
      size       :
        height   : 20
        width    : 20

  viewAppended:->
    super

    @addSubView @header
    @header.addSubView @newItemPlus
    KD.getSingleton("groupsController").ready =>
      currentGroup = KD.getSingleton("groupsController").getCurrentGroup()

      currentGroup.fetchAdmin (err, admin)=>
        unless err and admin?.profile
          me = KD.whoami()
          if admin.profile?.nickname is me.profile?.nickname
            title   = @getOption 'title'
            # FIXME remove magic string.
            if title is "Machines"
              @header.addSubView @newItemPlusForGroups

    @header.addSubView @loader

    {@appStorage} = @parent
    # @appStorage.ready @bound 'loadPosition'

  showLoader: ->
    @newItemPlus.hide()
    @loader.show()

  hideLoader: ->
    @newItemPlus.show()
    @loader.hide()

  addDia:(diaObj, pos)->
    pos = x: 20, y: 68 + @diaCount() * (@itemHeight + 20)
    super diaObj, pos

    diaObj.on "KDObjectWillBeDestroyed", @bound 'updatePositions'
    diaObj.on "KDObjectWillBeDestroyed", => @emit "itemRemoved"
    # @updateHeight()

  updatePositions:->

    index = 0
    for _key, dia of @dias
      dia.setX 20
      dia.setY 68 + index * 64
      index++
    # @updateHeight()

  diaCount:-> Object.keys(@dias).length

  mouseWheel:(e)->
    @emit "UpdateScene"
    super e

  loadItems:->
    @removeAllItems()

  # updateHeight:->

  #   @setHeight 80 + @diaCount() * 50
  #   @emit 'UpdateScene'

  # savePosition:->

  #   name      = @constructor.name
  #   bounds    = x: @getRelativeX(), y: @getRelativeY()
  #   positions = (@appStorage.getValue 'containerPositions') or {}
  #   positions[name] = bounds
  #   @appStorage.setValue 'containerPositions', positions

  # loadPosition:->

  #   name     = @constructor.name
  #   position = ((@appStorage.getValue 'containerPositions') or {})[name]
  #   return  unless position
  #   @setX position.x; @setY position.y

  # resetPosition:->

  #   @setX @_initialPosition.x
  #   @setY @_initialPosition.y

  #   name      = @constructor.name
  #   positions = (@appStorage.getValue 'containerPositions') or {}

  #   delete positions[name]
  #   @appStorage.setValue 'containerPositions', positions