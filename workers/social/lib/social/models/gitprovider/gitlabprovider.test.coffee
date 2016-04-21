GitLabProvider = require './gitlabprovider'
{ expect }     = require '../../../../testhelper'

runTests = -> describe 'workers.social.models.gitprovider.gitlabprovider', ->

  describe '#GitLabProvider.parseImportUrl()', ->

    it 'returns nothing if url host is not gitlab.com', ->

      url = 'http://www.google.com'
      expect(GitLabProvider.parseImportUrl url).not.exist


    it 'returns nothing if gitlab url is not repository url', ->

      url = 'https://gitlab.com/skratchdot/underscore/blob/master/package.json'
      expect(GitLabProvider.parseImportUrl url).not.exist


    it 'returns parse result if url is correct gitlab repository url', ->

      url = 'https://gitlab.com/skratchdot/underscore/tree/master'
      parseResult = GitLabProvider.parseImportUrl url
      expect(parseResult.user).to.be.equal 'skratchdot'
      expect(parseResult.repo).to.be.equal 'underscore'
      expect(parseResult.branch).to.be.equal 'master'


runTests()
