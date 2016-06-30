{ expect
  request
  doRequestFor
  checkBongoConnectivity } = require './testhelpers'

beforeTests = -> before (done) ->

  checkBongoConnectivity done


runTests = -> describe 'server.handlers.api.gitlab.user', ->

  describe 'server.handlers.api.gitlab.user.create', ->

    before (done) -> doRequestFor 'user_destroy', done

    it 'should create a user', (done) ->

      doRequestFor 'user_create', (err, res, body) ->

        expect(err).to.not.exist
        expect(res.statusCode).to.be.equal 200

        done()


  describe 'server.handlers.api.gitlab.user.destroy', ->

    before (done) -> doRequestFor 'user_create', done

    it 'should destroy a user', (done) ->

      doRequestFor 'user_destroy', (err, res, body) ->

        expect(err).to.not.exist
        expect(res.statusCode).to.be.equal 200

        done()


beforeTests()

runTests()
