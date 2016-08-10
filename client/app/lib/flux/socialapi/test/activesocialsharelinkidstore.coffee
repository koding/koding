expect                       = require 'expect'
Reactor                      = require 'app/flux/base/reactor'
actionTypes                  = require '../actions/actiontypes'
ActiveSocialShareLinkIdStore = require '../stores/activesocialsharelinkidstore'

describe 'ActiveSocialShareLinkIdStore', ->

  beforeEach ->
    @reactor = new Reactor
    @reactor.registerStores activeSocialShareLinkId: ActiveSocialShareLinkIdStore

  describe '#setActiveLinkId', ->

    it 'sets active social share link id', ->

      @reactor.dispatch actionTypes.SET_ACTIVE_SOCIAL_SHARE_LINK_ID, id: '1'
      activeId = @reactor.evaluate ['activeSocialShareLinkId']

      expect(activeId).toEqual '1'

      @reactor.dispatch actionTypes.SET_ACTIVE_SOCIAL_SHARE_LINK_ID, id: '2'
      activeId = @reactor.evaluate ['activeSocialShareLinkId']

      expect(activeId).toEqual '2'

      @reactor.dispatch actionTypes.SET_ACTIVE_SOCIAL_SHARE_LINK_ID, id: null
      activeId = @reactor.evaluate ['activeSocialShareLinkId']

      expect(activeId).toBe null
