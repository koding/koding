class BottomChatRoom extends JView

  constructor:->

    super

    @tokenInput = tokenInput = new BottomChatInput
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
                tokenInput.showMenu {
                  rule             : "username"
                  itemChildClass   : MemberAutoCompleteItemView
                  itemChildOptions :
                    cssClass       : "honolulu"
                    userInput      : token.slice(1)
                  token
                }, members

    @outputController = new KDListViewController

    @output = @outputController.getView()

    @sidebar = new KDView
      cssClass : "room-sidebar"

  pistachio:->

    """
      <section>
        {{> @output}}
        {{> @tokenInput}}
      </section>
      {{> @sidebar}}
    """

class BottomChatInput extends KDTokenizedInput

  click:->

    @emit "chat.ui.inputReceivedClick"
    no

  keyDownOnInput:(e)->

    #refactor here
    #keypress is unavoidable at this point
    if e.altKey and e.which is 78
      @emit "chat.ui.splitPanel"
      return no
    else if e.altKey and e.metaKey and e.which in [37,39]
      @emit "chat.ui.changeFocus", e.which
      return no
    else
      super
