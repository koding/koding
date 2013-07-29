class MemberMailLink extends KDCustomHTMLView
  constructor:(options, data)->
    options = $.extend
      tagName     : 'a'
      attributes  :
        href        : '#'
    , options
    super options, data

  viewAppended:->
    super
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    name = KD.utils.getFullnameFromAccount @getData(), yes
    "<cite/><span>Contact</span>#{name}"

  click:(event)->

    event.preventDefault()
    {profile} = member = @getData()

    KD.getSingleton("appManager").tell "Inbox", "createNewMessageModal", [member]