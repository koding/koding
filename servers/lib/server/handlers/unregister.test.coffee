Cookie = require 'tough-cookie'
koding = require './../bongo'
{ withRegisteredUser } = require '../../../testhelper/handler/registerhelper'
{ async
  expect
  request
  generateUrl
  generateRequestParamsEncodeBody
} = require '../../../testhelper'

# getCookiesFromHeader returns cookies obtained from a header
getCookiesFromHeader = (headers) ->
  return [] unless headers?['set-cookie']
  if headers['set-cookie'] instanceof Array
    return headers['set-cookie'].map Cookie.parse
  else
    return [Cookie.parse(headers['set-cookie'])]

describe 'server.handlers.unregister', ->

  it 'should send HTTP 500 if user is not logged in', (done) ->

    params =
      url : generateUrl { route : 'Unregister' }

    opts =
      clientId: undefined # having client id undefined means, not logged in

    requestParams = generateRequestParamsEncodeBody params, opts

    request.post requestParams, (err, res, body) ->
      expect(err).to.not.exist
      expect(res.statusCode).to.be.equal 500
      done()

  it 'should send HTTP 200 if user is logged in', (done) ->

    withRegisteredUser (user, extraParams) ->
      cookees = getCookiesFromHeader extraParams.headers
      clientCookees = cookees.filter (cookee) -> cookee.key is 'clientId'

      expect(clientCookees).to.have.length.above(0)

      { username }  = user

      params =
        url : generateUrl { route : 'Unregister' }

      opts =
        clientId: clientCookees[clientCookees.length - 1].value

      requestParams = generateRequestParamsEncodeBody params, opts

      request.post requestParams, (err, res, body) ->
        expect(err).to.not.exist
        expect(res.statusCode).to.be.equal 200
        expect(body).to.be.empty

        params =
          url : generateUrl { route : '-/validate/username' }
          body : { username }

        requestParams = generateRequestParamsEncodeBody params, {}
        request.post requestParams, (err, res, body) ->
          expect(err).to.not.exist
          expect(res.statusCode).to.be.equal 200

          body = try JSON.parse body
          expect(body).not.to.be.empty
          expect(body.kodingUser).to.be.false
          expect(body.forbidden).to.be.false
          done()
