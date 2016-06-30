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


  describe 'server.handlers.api.gitlab.user.add_to_team', ->

    it 'should add user to given team', (done) ->

      doRequestFor 'user_add_to_team', (err, res, body) ->

        expect(err).to.not.exist
        expect(res.statusCode).to.be.equal 403
        expect(JSON.parse body).to.be.deep.equal {
          error: {
            message: 'user add_to_team handler is not implemented'
          }
        }

        done()


  describe 'server.handlers.api.gitlab.user.remove_from_team', ->

    it 'should remove user from given team', (done) ->

      doRequestFor 'user_remove_from_team', (err, res, body) ->

        expect(err).to.not.exist
        expect(res.statusCode).to.be.equal 403
        expect(JSON.parse body).to.be.deep.equal {
          error: {
            message: 'user remove_from_team handler is not implemented'
          }
        }

        done()


  describe 'server.handlers.api.gitlab.user.add_to_group', ->

    it 'should add user to given group', (done) ->

      doRequestFor 'user_add_to_group', (err, res, body) ->

        expect(err).to.not.exist
        expect(res.statusCode).to.be.equal 403
        expect(JSON.parse body).to.be.deep.equal {
          error: {
            message: 'user add_to_group handler is not implemented'
          }
        }

        done()


  describe 'server.handlers.api.gitlab.user.remove_from_group', ->

    it 'should remove user from given group', (done) ->

      doRequestFor 'user_remove_from_group', (err, res, body) ->

        expect(err).to.not.exist
        expect(res.statusCode).to.be.equal 403
        expect(JSON.parse body).to.be.deep.equal {
          error: {
            message: 'user remove_from_group handler is not implemented'
          }
        }

        done()


beforeTests()

runTests()
