class NavigationController extends KDListViewController
  constructor:->
    super

    # this is temporary privateBeta
    @listenTo 
      KDEventTypes        : "MakeAllItemsUnselected"
      listenedToInstance  : @getView()
      callback            : =>
        @$('.navigation-item').removeClass 'selected'
  
  selectItemByName:(name)->
    item = no
    for navItem in @itemsOrdered
      if navItem.name is name
        @selectItem item = navItem
        break
    item

class NavigationList extends KDListView

  itemClass:(options,data)->
    if data.title is "Beta Feedback"
      new NavigationBetaFeedbackLink options, data
    else if data.title is "Invite Friends"
      new NavigationInviteLink options, data
    else
      super

class NavigationLink extends KDListItemView
  constructor:(options,data)->
    super options,data
    @name = data.title
    @setClass 'navigation-item clearfix'

  mouseDown:(event)->
    @getDelegate().handleEvent (type : "NavigationLinkTitleClick", orgEvent : event, pageName : @getData().title, appPath:@getData().path, navItem : @)
    
  partial:(data)->
    $ "<a class='title' href='#'><span class='main-nav-icon #{__utils.slugify data.title}'></span>#{data.title}</a>"

class NavigationBetaFeedbackLink extends NavigationLink
  viewAppended:()->
    bongo.api.JUser.fetchUser (err,user)=>
      @data.link = user.tenderAppLink
      @getDomElement().append @partial @data
      # @handleEvent { type : "viewAppended"}
      @setViewReady()
  
  partial:(data)->
      $ "<a class='title' href='#{data.link}' target='_blank'><span class='main-nav-icon #{__utils.slugify data.title}'></span>#{data.title}</a>"

class NavigationInviteLink extends NavigationLink
  
  constructor:->
    super
    @hide()
    @count = new KDCustomHTMLView
      pistachio: "{{#(quota)-#(usage)}}"
    KD.whoami().fetchLimit 'invite', (err, limit)=>
      if limit?
        @show()
        @count.setData limit
        limit.on 'update', => @count.render()
        @count.render()
  
  sendInvite:(formElements, modal)->
    bongo.api.JInvitation.create
      emails        : [formElements.recipient]
      customMessage :
        # subject     : formElements.subject
        body        : formElements.body
    , (err)=>
      modal.modalTabs.forms["Invite Friends"].buttons.Send.hideLoader()
      if err
        new KDNotificationView
          title: err.message or 'Sorry, something bad happened.'
          content: 'Please try again later!'
      else
        new KDNotificationView title: 'Success!'
        modal.destroy()
  
  viewAppended:->
    @setTemplate @pistachio()
    @template.update()
  
  pistachio:->
    "<a class='title' href='#'><span class='main-nav-icon #{__utils.slugify @getData().title}'>{{> @count}}</span>#{@getData().title}</a>"
      
  mouseDown:(event)->
    limit = @count.getData()
    if !limit? or limit.getAt('quota') - limit.getAt('usage') <= 0
      new KDNotificationView
        title   : 'You are temporarily out of invitations.'
        content : 'Please try again later.'
    else
      log @modal
      return if @modal
      @modal = modal = new KDModalViewWithForms
        title                   : "<span class='invite-icon'></span>Invite Friends to Koding"
        content                 : ""
        width                   : 500
        height                  : "auto"
        position                :
          top                    : 150
        cssClass                : "invitation-modal"
        tabs                    :
          callback              : (formElements)=> 
            @sendInvite formElements, modal
          forms                 :
            "Invite Friends"    :
              fields            :
                recipient       :
                  label         : "Send To:"
                  type          : "text"
                  name          : "recipient"
                  placeholder   : "Enter your friend's email address..."
                  validate      :
                    rules       : 
                      required  : yes
                      email     : yes
                    messages    :
                      required  : "An email address is required!"
                      email     : "That does not not seem to be a valid email address!"
                # Subject         :
                #   label         : "Subject:"
                #   type          : "text"
                #   name          : "subject"
                #   placeholder   : "Come try Koding, a new way for developers to work..."
                #   defaultValue  : "Come try Koding, a new way for developers to work..."
                #   # attributes    :
                #   #   readonly    : yes
                Message         :
                  label         : "Message:"
                  type          : "textarea"
                  name          : "body"
                  placeholder   : "Hi! You're invited to try out Koding, a new way for developers to work."
                  defaultValue  : "Hi! You're invited to try out Koding, a new way for developers to work."
                  # attributes    :
                  #   readonly    : yes
              buttons           :
                Send            :
                  style         : "modal-clean-gray"
                  type          : 'submit'
                  loader        :
                    color       : "#444444"
                    diameter    : 12
                cancel          :
                  style         : "modal-cancel"
                  callback      : ()->
                    modal.destroy()

    @listenTo 
      KDEventTypes       : "KDModalViewDestroyed"
      listenedToInstance : modal
      callback           : =>
        @modal = null
    
    inviteForm = modal.modalTabs.forms["Invite Friends"]
    inviteForm.on "ValidationFailed", => inviteForm.buttons["Send"].hideLoader()

    modalHint = new KDView
      cssClass  : "modal-hint"
      partial   : "<p>Your friend will receive an Email from Koding that 
                   includes a unique invite link so they can register for 
                   the Koding Public Beta.</p>
                   <p><cite>* We take privacy seriously, we will not share any personal information.</cite></p>"

    modal.modalTabs.addSubView modalHint, null, yes
    
    inviteHint = new KDView
      cssClass  : "invite-hint fl"
      pistachio : "{{#(quota)-#(usage)}} Invites remaining"
    , @count.getData()

    modal.modalTabs.panes[0].form.buttonField.addSubView inviteHint, null, yes
      
