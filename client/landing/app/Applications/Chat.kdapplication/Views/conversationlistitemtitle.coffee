class ChatConversationListItemTitle extends JView

  constructor:(options = {}, data)->
    options.cssClass = 'chat-item'
    data = [nick for nick in data when nick isnt KD.nick()].first
    super

  viewAppended:->

    invitees = @getData()
    @accounts = []

    for invitee in invitees
      KD.remote.cacheable invitee, (err, account)=>
        warn err  if err
        @accounts.push account?.first or Object
        @setTemplate @pistachio()  if @accounts.length is @getData().length

  getName:(index)->
    "#{@accounts[index].profile.firstName} #{@accounts[index].profile.lastName}"

  pistachio:->

    @setClass 'multiple'  if @accounts.length > 1

    @avatar  = new AvatarView
      size   : {width: 30, height: 30}
      origin : @accounts.first

    @participants = switch @accounts.length
      when 1 then @getName 0
      when 2 then "#{@getName(0)} <span>and</span> #{@getName(1)}"
      else "#{@getName(0)}, #{@getName(1)} <span>and <strong>#{@accounts.length - 2} more.</strong></span>"

    """
      <div class='avatar-wrapper fl'>
        {{> @avatar}}
      </div>
      <div class='right-overflow'>
        <h3>#{@participants}</h3>
      </div>
    """
