# Generates RainForest RFML file to simple mocha test as a starter.

fs = require 'fs'
Promise = require 'bluebird'


class Generator
  constructor: (opts = {}) ->

  @getRainforestTests: () ->
    files = fs.readdirSync './'

    files.filter (file) -> file.indexOf('rfml') != -1


  openFile: (filename) ->
    @filename = filename
    @body = fs.readFileSync './' + filename, 'utf-8'

  parseFile: () ->
    lines = @body.split '\n\n'

    @header = lines[0];
    @title = lines[0].split('\n')[0].split(' ')[1]
    @requires = lines[1].split(' ')[1]

    # Delete first 2 for generation
    lines.shift()
    lines.shift()

    # Remove #redirect false
    if lines[0][0] is '#'
      lines[0] = lines[0].substr lines[0].indexOf('\n') + 1, lines[0].length

    @parsedBody = lines

  @isFileExist: (filename) ->
    exists = no

    try
      stats = fs.lstatSync "./#{filename}"
      exists = stats.isFile()
    catch
      console.info "#{filename} doesnt exist at all. Proceeding..."

    console.info "#{filename} exists. Skipping..." if exists

    exists

  generateMochaTest: () ->
    replacedChar = new RegExp "'", "g"
    mocha = @header + "\n\n"
    requires = @requiredFileName

    filename = @filename

    @parsedBody.forEach (test, index) ->
      if index is 0
        mocha += "describe '#{filename}', ->\n"
        mocha += "  before -> \n"
        mocha += "    require './#{requires}'\n\n"
        return

      should = test.split('\n')[0].replace replacedChar, "\\'"
      mocha += "  describe '#{should}', ->\n"

      assertions = test.split('\n')[1].split('? ')

      assertions.forEach (assertion, index, array) ->
        if assertion.length > 1
          assertion = assertion.replace replacedChar, "\\'"
          mocha += "    it '#{assertion}?', -> \n"
          mocha += "      console.warning 'Not yet implemented.'\n\n"

        mocha += "\n" if index is (array.length - 1)

    @mocha = mocha

  getRequiredModule: (mapping) ->
    @mapping = mapping
    @requiredFileName = mapping[@requires].name

  save: () ->
    file = @filename.split('.')[0] + '.coffee'
    fs.writeFile("./#{file}", @mocha)

  isTestsValid: () ->
    coffeefilename = @filename.split('.')[0] + '.coffee'
    console.info "Checking is file is valid for #{coffeefilename}..."
    coffeeFile = fs.readFileSync "./#{coffeefilename}", 'utf-8'
    testCount = @mapping[@title].testCount

    validTests = coffeeFile.match(/describe/g).length + 1;

    if (validTests is not testCount)
      throw new Error('Test failed! Inccorrect amount of test exists.')

    console.info "File is valid."


  @createMapping: () ->
    console.info 'Creating mapping for RainForest tests...'
    files = this.getRainforestTests()
    mapping = {}
    files.forEach (file) ->
      body = fs.readFileSync './' + file, 'utf-8'
      body = body.split '\n\n'
      requires = body[1].split(' ')[1]
      id = body[0].split('\n')[0].split(' ')[1]
      testCount = body.slice(1, body.length).length

      mapping[id] =
        name: file.split('.')[0] + '.coffee'
        requires: requires
        testCount: testCount

    fs.writeFile './mapping.json', JSON.stringify mapping
    console.info 'Mapping finished.'
    mapping

  @getMapping: () ->
    JSON.parse fs.readFileSync './mapping.json', 'utf-8'


mapping = Generator.createMapping()
files = Generator.getRainforestTests()

generator = new Generator()

files.forEach (file) ->
  generator.openFile file
  generator.parseFile()
  generator.getRequiredModule mapping

  if not Generator.isFileExist file.split('.')[0] + '.coffee'
    generator.generateMochaTest()
    generator.save()
  else
    generator.isTestsValid()
