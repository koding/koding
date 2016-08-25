GitHubProvider = require './githubprovider'
{ expect }     = require '../../../../testhelper'


runTests = -> describe 'workers.social.models.gitprovider.githubprovider', ->

  describe '#parseImportData()', ->

    it 'returns nothing if url host is not github.com', ->

      url = 'http://www.google.com'
      expect(GitHubProvider.parseImportData url).not.exist


    it 'returns nothing if github url is not repository url', ->

      url = 'https://github.com/koding/koding/blob/master/package.json'
      expect(GitHubProvider.parseImportData url).not.exist


    it 'returns parse result if url is correct github repository url', ->

      url = 'https://github.com/koding/kd'
      parseResult = GitHubProvider.parseImportData url
      expect(parseResult.user).to.be.equal 'koding'
      expect(parseResult.repo).to.be.equal 'kd'
      expect(parseResult.branch).to.be.equal 'master'


    it 'detects branch reference in github repository url', ->

      url = 'https://github.com/koding/kd/tree/1.x'
      parseResult = GitHubProvider.parseImportData url
      expect(parseResult.user).to.be.equal 'koding'
      expect(parseResult.repo).to.be.equal 'kd'
      expect(parseResult.branch).to.be.equal '1.x'


runTests()
