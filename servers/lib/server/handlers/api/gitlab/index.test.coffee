apiErrors = require '../errors'

{ expect
  request
  parseEvent
  generateUrl
  gitlabApiUrl
  getSampleDataFor
  gitlabDefaultHeaders
  checkBongoConnectivity
  generateRequestParamsEncodeBody } = require './testhelpers'


beforeTests = -> before (done) ->

  checkBongoConnectivity done


runTests = -> describe 'server.handlers.api.gitlab', ->

  (require './_events').forEach (event) ->

    it "should handle #{event} requests", (done) ->

      { scope, method } = parseEvent event

      params    = generateRequestParamsEncodeBody
        url     : gitlabApiUrl
        headers : gitlabDefaultHeaders
        body    : getSampleDataFor event

      request.post params, (err, res, body) ->

        expect(err).to.not.exist
        expect(res.statusCode).to.be.equal 403
        expect(JSON.parse body).to.be.deep.equal {
          error: {
            message: "#{scope} #{method} handler is not implemented"
          }
        }

        done()


beforeTests()

runTests()
