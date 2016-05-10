kd        = require 'kd'
expect    = require 'expect'
Proxifier = require 'app/util/proxifier'


baseDomain    = 'koding.com'
tunnelDomain  = 'koding.me'
prodProxyUrl  = "p.#{baseDomain}/-/prodproxy"
devProxyUrl   = "dev-p.#{baseDomain}/-/devproxy"

prodTunnelUrl = "p.#{baseDomain}/-/prodtunnel"
devTunnelUrl  = "dev-p.#{baseDomain}/-/devtunnel"

testTunnelUrl = "some.test.url.3f5.#{tunnelDomain}/kite"

discoverKite  = [
  { protocol: 'https', addr: 'dev.kodi.ng:56790', local: true }
  { protocol: 'http',  addr: '127.0.0.1:56789',   local: true }
  { protocol: 'http',  addr: testTunnelUrl,       local: false }
]


describe 'Proxifier.proxify', ->

  afterEach -> expect.restoreSpies()

  describe 'should provide proxified versions of given kite urls', ->

    protocol = 'http:'
    baseURL  = '1.2.3.4/kite'
    url      = "#{protocol}//#{baseURL}"

    it 'should use dev proxy for dev environment', (done) ->

      expect.spyOn(Proxifier, 'isInProduction').andReturn no

      expectedURL = "#{protocol}//#{devProxyUrl}/#{baseURL}"

      Proxifier.proxify { url }, (proxifiedUrl) ->
        expect(Proxifier.isInProduction).toHaveBeenCalled()
        expect(proxifiedUrl).toEqual expectedURL
        done()

    it 'should use production proxy for production environment', (done) ->

      expect.spyOn(Proxifier, 'isInProduction').andReturn yes

      expectedURL = "#{protocol}//#{prodProxyUrl}/#{baseURL}"

      Proxifier.proxify { url }, (proxifiedUrl) ->
        expect(Proxifier.isInProduction).toHaveBeenCalled()
        expect(proxifiedUrl).toEqual expectedURL
        done()


    it 'should provide proxified url over https if current location is https', (done) ->

      protocol = 'https:'
      url      = "#{protocol}//#{baseURL}"

      expect.spyOn(Proxifier, 'getProtocol').andReturn protocol

      expectedURL = "#{protocol}//#{devProxyUrl}/#{baseURL}"

      Proxifier.proxify { url }, (proxifiedUrl) ->
        expect(Proxifier.getProtocol).toHaveBeenCalled()
        expect(proxifiedUrl).toEqual expectedURL
        done()


    it 'should provide proxified url over http if current location is http', (done) ->

      protocol = 'http:'
      url      = "#{protocol}//#{baseURL}"

      expect.spyOn(Proxifier, 'getProtocol').andReturn protocol

      expectedURL = "#{protocol}//#{devProxyUrl}/#{baseURL}"

      Proxifier.proxify { url }, (proxifiedUrl) ->
        expect(Proxifier.getProtocol).toHaveBeenCalled()
        expect(proxifiedUrl).toEqual expectedURL
        done()


    it 'should use dev tunnel for tunnel urls on dev environment', (done) ->

      url = "#{protocol}//#{testTunnelUrl}"

      expectedURL = "#{protocol}//#{devTunnelUrl}/#{testTunnelUrl}"

      Proxifier.proxify { url, checkAlternatives: no }, (proxifiedUrl) ->
        expect(proxifiedUrl).toEqual expectedURL
        done()


    it 'should use production tunnel for tunnel urls on production environment', (done) ->

      url = "#{protocol}//#{testTunnelUrl}"

      expect.spyOn(Proxifier, 'isInProduction').andReturn yes

      expectedURL = "#{protocol}//#{prodTunnelUrl}/#{testTunnelUrl}"

      Proxifier.proxify { url, checkAlternatives: no }, (proxifiedUrl) ->
        expect(Proxifier.isInProduction).toHaveBeenCalled()
        expect(proxifiedUrl).toEqual expectedURL
        done()



  describe 'should provide same url for proxified and local tunnel urls', ->

    it 'should return same url for local tunnel urls', (done) ->

      url = "http://#{discoverKite[0].addr}/kite"

      Proxifier.proxify { url }, (proxifiedUrl) ->
        expect(url).toEqual proxifiedUrl

        url = "http://#{discoverKite[1].addr}/kite"
        Proxifier.proxify { url }, (proxifiedUrl) ->
          expect(url).toEqual proxifiedUrl

          done()

    it 'should return same url for already proxified urls', (done) ->

      url = "https://#{prodProxyUrl}/test/foo"

      Proxifier.proxify { url }, (proxifiedUrl) ->
        expect(url).toEqual proxifiedUrl

        url = "https://#{devProxyUrl}/test/foo"
        Proxifier.proxify { url }, (proxifiedUrl) ->
          expect(url).toEqual proxifiedUrl

          done()


  describe 'should provide local alternatives for tunnel urls', ->

    protocol = 'http:'
    baseURL  = testTunnelUrl
    url      = "#{protocol}//#{baseURL}"

    it 'should return local alternative of tunnel url', (done) ->

      expect.spyOn Proxifier, 'checkAlternative'
        .andCall (protocol, baseURL, callback) ->
          callback null, discoverKite

      expectedURL = "#{discoverKite[1].protocol}://#{discoverKite[1].addr}/kite"

      Proxifier.proxify { url }, (proxifiedUrl) ->
        expect(Proxifier.checkAlternative).toHaveBeenCalled()
        expect(proxifiedUrl).toEqual expectedURL
        done()

    it 'should provide a secure local alternative for tunnel urls over https', (done) ->

      protocol = 'https:'
      url      = "#{protocol}//#{baseURL}"

      expect.spyOn(Proxifier, 'getProtocol').andReturn protocol
      expect.spyOn Proxifier, 'checkAlternative'
        .andCall (protocol, baseURL, callback) ->
          callback null, discoverKite

      expectedURL = "#{discoverKite[0].protocol}://#{discoverKite[0].addr}/kite"

      Proxifier.proxify { url }, (proxifiedUrl) ->
        expect(Proxifier.getProtocol).toHaveBeenCalled()
        expect(Proxifier.checkAlternative).toHaveBeenCalled()
        expect(proxifiedUrl).toEqual expectedURL
        done()

    it 'should only proxify tunnel urls if alternatives not requested', (done) ->

      expect.spyOn(Proxifier, 'getProtocol').andReturn protocol

      expectedURL = "#{protocol}//#{devTunnelUrl}/#{baseURL}"

      Proxifier.proxify { url, checkAlternatives: no }, (proxifiedUrl) ->
        expect(Proxifier.getProtocol).toHaveBeenCalled()
        expect(proxifiedUrl).toEqual expectedURL
        done()
