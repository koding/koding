class GmailContactsListItem extends KDListItemView

  constructor:(options={}, data)->
    options.type     = "gmail"
    data.invited    ?= no

    super options, data

    @isSelected = no

  setAvatar: ->
    hash = md5.digest @getData().email
    @$(".avatar").css "background-image", "url(//gravatar.com/avatar/#{hash}?size=25)"

  viewAppended:->
    uber = JView::viewAppended.bind @
    @setClass "already-invited" if @getData().invited
    uber()

    @setAvatar()

  partial:->

  click:->
    contact = @getData()
    contact.invite (err) =>
      if err
        log "we have a problem"
        log err
      else
        @setClass "invite-sent"
        @data.invited = yes

  pistachio:->
    name = @getData().title || "Gmail Contact"
    """
      <div class="avatar"></div>
      <div class="contact-info">
        <span class="full-name">#{name}</span>
        {{ #(email)}}
      </div>
      <div class="invite-sent-overlay">
        <i></i>Invite Sent
      </div>
    """
