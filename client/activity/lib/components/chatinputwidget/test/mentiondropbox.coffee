kd                   = require 'kd'
React                = require 'kd-react'
ReactDOM             = require 'react-dom'
expect               = require 'expect'
TestUtils            = require 'react-addons-test-utils'
toImmutable          = require 'app/util/toImmutable'
MentionDropbox       = require '../mentiondropbox'
helpers              = require './helpers'
generateDummyAccount = require 'app/util/generateDummyAccount'

describe 'MentionDropbox', ->

  userMentions = toImmutable [
    generateDummyAccount 1, 'nick', '', ''
    generateDummyAccount 2, 'john', 'John', 'Johnson'
  ]

  channelMentions = toImmutable [
    {
      names       : [ 'channel', 'all', 'team', 'group' ]
      description : 'notify everyone in the channel'
    }
    {
      names       : [ 'admins' ]
    }
  ]


  afterEach -> helpers.clearDropboxes()


  describe '::render', ->

    it 'renders invisible dropbox if user and channel items are empty', ->

      dropbox = helpers.renderDropbox {}, MentionDropbox
      expect(dropbox.props.visible).toBe no

    it 'renders dropbox with user and channel items in one list', ->

      props = { userMentions, channelMentions }

      dropbox = helpers.renderDropbox props, MentionDropbox
      content = dropbox.getContentElement()

      userItems = content.querySelectorAll '.UserMentionItem'
      expect(userItems.length).toEqual props.userMentions.size

      channelItems = content.querySelectorAll '.ChannelMentionItem'
      expect(channelItems.length).toEqual props.channelMentions.size

    it 'renders user items correctly', ->

      props = { userMentions }

      dropbox = helpers.renderDropbox props, MentionDropbox
      content = dropbox.getContentElement()

      userItems = content.querySelectorAll '.UserMentionItem'
      expect(userItems.length).toEqual props.userMentions.size
      for item, i in userItems
        dataItem = props.userMentions.get i

        avatar = item.querySelector 'img'
        expect(avatar).toExist()

        nickname = item.querySelector '.UserMentionItem-nickname'
        expect(nickname).toExist()
        expect(nickname.textContent).toEqual dataItem.getIn [ 'profile', 'nickname' ]

        fullName = item.querySelector '.UserMentionItem-fullName'

        firstName = dataItem.getIn [ 'profile', 'firstName' ]
        lastName  = dataItem.getIn [ 'profile', 'lastName' ]
        if firstName and lastName
          expect(fullName).toExist()
          expect(fullName.textContent).toEqual "#{firstName} #{lastName}"
        else
          expect(fullName).toNotExist()

    it 'renders channel items correctly', ->

      props = { channelMentions }

      dropbox = helpers.renderDropbox props, MentionDropbox
      content = dropbox.getContentElement()

      channelItems = content.querySelectorAll '.ChannelMentionItem'
      expect(channelItems.length).toEqual props.channelMentions.size
      for item, i in channelItems
        dataItem = props.channelMentions.get i

        names       = dataItem.get('names').toJS()
        mentionList = item.querySelector '.ChannelMentionItem-mentionList'
        expect(mentionList).toExist()
        for name in names
          expect(mentionList.textContent).toInclude "@#{name}"

        description = item.querySelector '.ChannelMentionItem-description'
        text        = dataItem.get 'description'
        if text
          expect(description).toExist()
          expect(description.textContent).toInclude text
        else
          expect(description).toNotExist()

    it 'renders dropbox with selected item', ->

      props = { userMentions, channelMentions, selectedIndex : 1 }
      helpers.dropboxSelectedItemTest props, MentionDropbox


  describe '::onItemSelected', ->

    it 'should be called when dropbox item is hovered', ->

      props = { userMentions, channelMentions, selectedIndex : 1 }
      helpers.dropboxSelectedItemCallbackTest props, MentionDropbox


  describe '::onItemConfirmed', ->

    it 'should be called when dropbox item is clicked', ->

      props = { userMentions, channelMentions, selectedIndex : 2 }
      helpers.dropboxConfirmedItemCallbackTest props, MentionDropbox
