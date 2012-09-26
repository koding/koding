class DemosMainView extends KDScrollView

  viewAppended:()->

    # @addSubView split = new SlidingSplit
    #   type            : "horizontal"
    #   cssClass        : "chat-split"
    #   sizes           : [null]
    #   scrollContainer : @

    mainView     = @

    @addSubView tokenInput = new KDTokenizedInput
      match                :
        topic              :
          regex            : /\B#\w.*/
          # throttle         : 2000
          wrapperClass     : "highlight-tag"
          replaceSignature : "{{#(title)}}"
          added            : (data)->
            log "tag is added to the input", data
          removed          : (data)->
            log "tag is removed from the input", data
          dataSource       : (token)->
            appManager.tell "Topics", "fetchSomeTopics", selector : token.slice(1), (err, topics)->
              # log err, topics
              if not err and topics.length > 0
                tokenInput.showMenu {token, rule : "topic"}, topics
        username           :
          regex            : /\B@\w.+/
          wrapperClass     : "highlight-user"
          replaceSignature : "{{#(profile.firstName)}} {{#(profile.lastName)}}"
          added            : (data)->
            log "user is added to the input", data
          removed          : (data)->
            log "user is removed from the input", data
          dataSource       : (token)->
            # log token, "member"
            appManager.tell "Members", "fetchSomeMembers", selector : token.slice(1), (err, members)->
              # log err, members
              if not err and members.length > 0
                tokenInput.showMenu {token, rule : "username"}, members