class MemberMailLink extends KDCustomHTMLView

  JView.mixin @prototype

  constructor:(options, data)->
    options = $.extend
      tagName     : 'a'
      attributes  :
        href        : '#'
    , options
    super options, data

  pistachio:->
    name = KD.utils.getFullnameFromAccount @getData(), yes
    "<cite/><span>Contact #{name}</span>"

  click:(event)->

    event.preventDefault()
    {profile} = member = @getData()

    KD.getSingleton("appManager").tell "Inbox", "createNewMessageModal", [member]