class DemosAppController extends AppController

  KD.registerAppClass @,
    name         : "Demos"
    route        : "/Demos"
    hiddenHandle : yes

  constructor:(options = {}, data)->
    options.view    = new DemosMainView
      cssClass      : "content-page demos"
    options.appInfo =
      name          : "Demos"

    super options, data

  loadView:(mainView)->

    data = [
      { title : "Item 1",  id : 1,  parentId: 0}
      { title : "Item 2",  id : 2,  parentId: 1}
      { title : "Item 3",  id : 3,  parentId: 1}
      { title : "Item 4",  id : 4,  parentId: 1}

      { title : "Item 5",  id : 5,  parentId: 1}
      { title : "Item 6",  id : 6,  parentId: 1}
      { title : "Item 7",  id : 7,  parentId: 1}

      { title : "Item 8",  id : 8,  parentId: 5}
      { title : "Item 9",  id : 9,  parentId: 5}
      { title : "Item 10", id : 10, parentId: 5}
      { title : "Item 11", id : 11, parentId: 5}
      { title : "Item 12", id : 12, parentId: 5}
      { title : "Item 13", id : 13, parentId: 5}
      { title : "Item 14", id : 14, parentId: 5}

      { title : "Item 15", id : 15, parentId: 1}
      { title : "Item 16", id : 16, parentId: 1}

      { title : "Item 17", id : 17, parentId: 11}
      { title : "Item 18", id : 18, parentId: 11}

      { title : "Item 20", id : 20, parentId: 14}
      { title : "Item 19", id : 19, parentId: 20}
    ]

    t = new JTreeViewController
      addListsCollapsed : no
    , data

    i = 0

    addRandom = =>
      nodes    = t.indexedNodes.length
      inrn     = if nodes > 1 then rand(nodes - 1) else 0
      parent   = t.indexedNodes[inrn]
      parentCn = t.listControllers[parent.id]
      index    = 0
      if parentCn
        items  = parentCn.itemsOrdered.length
        index = rand if items > 1 then items - 1 else 1

      id       = rand()+41+inrn
      parentId = parent.id
      title    = "Item #{id}"

      log "Item '#{title}' is adding to '#{parent.title}'"# at index #{index}"

      t.addNode { title, id, parentId } #, index
      view.$('.expanded ul').css
        "padding-right"    : "10px"
        "padding-left"     : "10px"
        "background-color" : "rgba(0,0,0,.2)"
        "color"            : "rgba(255,255,255,.9)"

      i+=1
      if i < 200
        KD.utils.wait 100, addRandom

    rand = KD.utils.getRandomNumber
    mainView.addSubView button = new KDButtonView
      style    : "clean-gray"
      title    : "Click"
      callback : addRandom

    view = t.getView()
    mainView.addSubView view

    view.$('.expanded ul').css
      "padding-left"     : "10px"
      "padding-right"    : "10px"
      "background-color" : "rgba(0,0,0,.2)"
      "color"            : "rgba(255,255,255,.9)"
