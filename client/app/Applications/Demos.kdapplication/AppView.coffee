class DemosMainView extends KDScrollView

  viewAppended:()->

    v = new KDView
      pistachio: '{{> foo}}'
      pistachioParams:
        foo: new KDView
          partial: 'fooo!!!'

    @addSubView v

    # # @addSubView split = new SlidingSplit
    # #   type            : "horizontal"
    # #   cssClass        : "chat-split"
    # #   sizes           : [null]
    # #   scrollContainer : @

    # mainView     = @

    # @addSubView bomba = new KDInputView
    #   # click               : (event)-> bomba.setKeyView()
    #   # keydown             : (event)-> new KDNotificationView title : "input keydown"
    #   keydown             : 
    #     "command a"       : (event)-> new KDNotificationView title : "cmd and a sequence"
    #     "super+k super+b" : (event)-> new KDNotificationView title : "super+k super+b combo sequence"
    #     "k"               : (event)-> new KDNotificationView title : "only k"
    #     "s i n a n"       : (event)-> new KDNotificationView title : "sinan sequence"

    # @addSubView bombi = new KDView
    #   randomBG            : yes
    #   click               : (event)-> bombi.setKeyView()
    #   keydown             : 
    #     "command a"       : (event)-> new KDNotificationView title : "cmd and a sequence"
    #     "super+k super+b" : (event)-> new KDNotificationView title : "super+k super+b combo sequence"
    #     "k"               : (event)-> new KDNotificationView title : "only k"
    #     "s i n a n"       : (event)-> new KDNotificationView title : "sinan sequence"

    # # @addSubView tokenInput = new KDTokenizedInput
    # #   match                :
    # #     topic              :
    # #       regex            : /\B#\w.*/
    # #       # throttle         : 2000
    # #       wrapperClass     : "highlight-tag"
    # #       replaceSignature : "{{#(title)}}"
    # #       added            : (data)->
    # #         log "tag is added to the input", data
    # #       removed          : (data)->
    # #         log "tag is removed from the input", data
    # #       dataSource       : (token)->
    # #         appManager.tell "Topics", "fetchSomeTopics", selector : token.slice(1), (err, topics)->
    # #           # log err, topics
    # #           if not err and topics.length > 0
    # #             tokenInput.showMenu {token, rule : "topic"}, topics
    # #     username           :
    # #       regex            : /\B@\w.+/
    # #       wrapperClass     : "highlight-user"
    # #       replaceSignature : "{{#(profile.firstName)}} {{#(profile.lastName)}}"
    # #       added            : (data)->
    # #         log "user is added to the input", data
    # #       removed          : (data)->
    # #         log "user is removed from the input", data
    # #       dataSource       : (token)->
    # #         # log token, "member"
    # #         appManager.tell "Members", "fetchSomeMembers", selector : token.slice(1), (err, members)->
    # #           # log err, members
    # #           if not err and members.length > 0
    # #             tokenInput.showMenu {
    # #               rule             : "username"
    # #               itemChildClass   : MemberAutoCompleteItemView
    # #               itemChildOptions :
    # #                 cssClass       : "honolulu"
    # #                 userInput      : token.slice(1)
    # #               token
    # #             }, members