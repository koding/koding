class MembersMainView extends KDView

  createCommons:->

    @addSubView @header = new HeaderViewSection
      type  : "big"
      title : "Members"

    KD.getSingleton("mainController").on 'AccountChanged', @bound 'setSearchInput'
    @setSearchInput()

  setSearchInput:->
    @header.setSearchInput()  if 'list members' in KD.config.permissions