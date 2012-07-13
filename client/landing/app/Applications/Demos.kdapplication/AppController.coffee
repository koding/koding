class Demos12345 extends AppController
  constructor:(options = {}, data)->
    options.view = new DemosMainView
      cssClass : "content-page demos"

    super options, data

  bringToFront:()->
    super name : 'Demos'#, type : 'background'

  loadView:(mainView)->
    data = [
      { title : "title 1",  id : 1,  parentId: 0}
      { title : "title 2",  id : 2,  parentId: 0}
      { title : "title 3",  id : 3,  parentId: 0}
      { title : "title 4",  id : 4,  parentId: 0}
      { title : "title 5",  id : 5,  parentId: 1}
      { title : "title 6",  id : 6,  parentId: 1}
      { title : "title 7",  id : 7,  parentId: 1}
      { title : "title 8",  id : 8,  parentId: 5}
      { title : "title 9",  id : 9,  parentId: 5}
      { title : "title 10", id : 10, parentId: 5}
      { title : "title 11", id : 11, parentId: 5}
      { title : "title 12", id : 12, parentId: 5}
      { title : "title 13", id : 13, parentId: 5}
      { title : "title 14", id : 14, parentId: 5}
      { title : "title 15", id : 15, parentId: 1}
      { title : "title 16", id : 16, parentId: 1}
      { title : "title 17", id : 17, parentId: 11}
      { title : "title 18", id : 18, parentId: 11}
      { title : "title 19", id : 19, parentId: 11}
      { title : "title 20", id : 20, parentId: 1}
    ]
    
    # window.sss = mainView.addSubView followButton = new KDToggleButton # MemberFollowToggleButton
    #   style           : "kdwhitebtn profilefollowbtn"
    #   title           : "Follow"
    #   dataPath        : "followee"
    #   defaultState    : "Unfollow"
    #   loader          :
    #     color         : "#333333"
    #     diameter      : 18
    #     left          : 3
    #   states          : [
    #     "Follow", (callback)->
    #       # memberData.follow (err, response)=>
    #       #   unless err
    #       #     @setClass 'following-btn'
    #       log "follow callback"
    #       @hideLoader()
    #       callback? null
    #     "Unfollow", (callback)->
    #       # memberData.unfollow (err, response)=>
    #       #   unless err
    #       #     @unsetClass 'following-btn'
    #       log "unfollow callback"
    #       @hideLoader()
    #       callback? null
    #   ]
    # 
    # mainView.addSubView a = new KDView
    #   click : ->
    #     log "click"
    #   dblclick : ->
    #     log "dblClick"

    mainView.addSubView a = new KDView
      click : ->
        log "click"
      dblclick : ->
        log "dblClick"
    ###


    t = new JTreeViewController
      addListsCollapsed : yes
      multipleSelection : yes
      dragdrop          : yes
    , data
    mainView.addSubView t.getView()
    t.getView().$().height "auto"

    # mainView.addSubView a = new ProfileLinkView {},KD.whoami()
    # mainView.addSubView b = new KDButtonView
    #   title     : "render"
    #   callback  : ->
    #     log "being rendered"
    #     a.render.call a
    #

    # controller = new MembersListViewController
    #   subItemClass : MembersListItemView
    # , items : [KD.whoami()]
    #
    # mainView.addSubView controller.getView()

    # KD.whoami().on "update", => log "data has changed"

    # mainView.addSubView form = new KDFormViewWithFields
    #   fields          :
    #     title         :
    #       name        : "title"
    #       placeholder : "title"
    #     parent        :
    #       name        : "parentId"
    #       placeholder : "parentId"
    #     remove        :
    #       name        : "id"
    #       placeholder : "to be removed id"
    #   buttons         :
    #     add           :
    #       title       : "add"
    #       type        : "submit"
    #     remove        :
    #       title       : "remove"
    #       callback    : ->
    #         if t.selectedNodes.length > 0
    #           for node in t.selectedNodes
    #             t.removeNode t.getNodeId(node.getData())
    #             null
    #         #
    #         # t.removeNode form.inputs.remove.getValue()
    #         # for node in t.indexedNodes
    #         #   log node.id, node.parentId, node.depth
    #     removeChildren:
    #       title       : "remove children only"
    #       callback    : ->
    #         t.removeChildNodes form.inputs.remove.getValue()
    #   callback        : (formData)->
    #     t.addNode
    #       title     : formData.title
    #       parentId  : formData.parentId
    #     for node in t.indexedNodes
    #       log node.id, node.parentId, node.depth

    # mainView.addSubView new KDButtonGroupView
    #   buttons      :
    #     a          :
    #       callback : ->
    #         number = @utils.getRandomNumber(20)
    #         finderController.addNode parentId : number, title : "#{number}'s child"
    #     b          :
    #       callback : -> log "b"
    #     c          :
    #       callback : -> log "c"


    # mainView.addSubView new Dragee
    # mainView.addSubView new Dragee
    # mainView.addSubView new Dropee


# class Dragee extends KDCustomHTMLView
#
#   constructor:(options, data)->
#     super
#       tagName       : "section"
#       cssClass      : "drag"
#       attributes    :
#         draggable   : "true"
#       bind          : "dragstart dragenter dragleave dragend dragover drop"
#       dragstart     : (pubInst, event)->
#         log event, event.type
#         e = event.originalEvent
#         e.dataTransfer.effectAllowed = 'copy' # only dropEffect='copy' will be dropable
#         e.dataTransfer.setData('Text', this.id) # required otherwise doesn't work
#         pubInst.setClass "drag-started"
#
#       dragenter     : (pubInst, event)->
#         log event.type
#
#       dragover      : (pubInst, event)->
#         event.preventDefault()
#         # event.originalEvent.dataTransfer.dropEffect = 'move'
#         log event.type
#         no
#
#       dragleave     : (pubInst, event)->
#         log event.type
#
#       drop          : (pubInst, event)->
#         log event.type
#         event.preventDefault()
#         event.stopPropagation()
#         no
#
#       dragend       : (pubInst, event)->
#         pubInst.unsetClass "drag-started"
#         log event.type
#
#     , data
#
# class Dropee extends KDCustomHTMLView
#
#   constructor:(options, data)->
#     super
#       tagName       : "section"
#       cssClass      : "drop"
#       bind          : "dragenter dragleave dragover drop"
#       drop          : (pubInst, event)->
#         log event.type, "burdaki"
#         event.preventDefault()
#         event.stopPropagation()
#         no
#     , data
