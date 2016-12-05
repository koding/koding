# Generates RainForest RFML file to simple mocha test as a starter.
fs = require 'fs'
path = require 'path'
async = require 'async'

landingTestPath = path.join(__dirname, '../client/landing/site.landing/coffee/testrunner/tests')
rfmlFilesPath = path.join(__dirname, '/spec/rainforest')

class Generator

  getRainforestTests: ->

    files = fs.readdirSync rfmlFilesPath

    files.filter (file) -> file.indexOf('.rfml') != -1


  isFileExist: (filename) ->

    exists = no

    try
      stats = fs.lstatSync "#{filename}"
      exists = stats.isFile()
    catch
      console.info "#{filename} doesnt exist at all. Proceeding..."

    console.info "#{filename} exists. Skipping..." if exists

    exists


  createMappingIfNotExist: ->

    mappingPath = path.join(__dirname, 'mapping.json')
    if @isFileExist mappingPath
      mapping = fs.readFileSync mappingPath, 'utf-8'
      return JSON.parse mapping  if mapping?

    @createMapping()


  createMapping: ->
    console.info 'Creating mapping for RainForest tests...'
    mapping = @parseRFMLFiles()
    fs.writeFile path.join(__dirname, 'mapping.json'), JSON.stringify mapping, null, 2
    fs.writeFile path.join(landingTestPath, '../mapping.json'), JSON.stringify mapping, null, 2
    console.info 'Mapping finished.'
    mapping


  parseFileHeader: (header) ->

    id = header[0].split(' ')[1]
    startUri = header[2].split(':')[1].trim()
    tag = header[3].split(':')[1]

    if id and startUri and tag then { id, startUri, tag }
    else throw new Error('Parse failed! while parsing file header')


  parseEmbeddedTestInfo: (embeddedInfo) ->

    return null  unless embeddedInfo[1].indexOf('-') is 0

    embedded =
      name: embeddedInfo[0].split(' ')[1]
      id: embeddedInfo[1].split(' ')[1]


  parseTestSteps: (body, index = 1) ->

    steps = []
    [index..body.length - 1].forEach (i) ->
      step = body[i]
      if step.length
        # remove redirect line
        if step.indexOf('redirect') > -1
          s = step.split('\n')
          s.shift()
          step = s.join('\n')

        # get descritions and assertions
        [description, asserts...] = step.split('\n')
        step = { description, asserts: asserts[0].trim().split('? ') }
        steps.push step

    steps


  parseRFMLFiles: ->

    mapping = {}
    fileNames = @getRainforestTests()
    fileNames.forEach (fileName) =>
      body = fs.readFileSync path.join(rfmlFilesPath, "#{fileName}"), 'utf-8'
      body = body.split '\n\n'

      fileName = fileName.split('.')[0]
      # header parse
      header = @parseFileHeader body[0].split('\n')

      embedded = @parseEmbeddedTestInfo body[1].split('\n')

      # body parse
      startIndex = 1
      startIndex = 2  if embedded
      steps = @parseTestSteps body, startIndex

      testCount = steps.length
      { id, startUri, tag } = header
      mapping[fileName] = { id, startUri, testCount, steps, tag, embedded: embedded if embedded? }

    mapping


  isTestsValid: (mapping, fileName) ->

    coffeefilename = "#{fileName}.coffee"
    console.info "Checking is file is valid for #{coffeefilename}..."

    coffeeFile = fs.readFileSync path.join(landingTestPath, "#{coffeefilename}"), 'utf-8'
    testCount = mapping[fileName].testCount

    validTests = coffeeFile.match(/describe/g)?.length + 1;

    if (validTests is not testCount)
      throw new Error('Test failed! Inccorrect amount of test exists.')

    console.info "File is valid."


  generateMochaTests: (mapping, callback = ->) ->

    fileNames = @getRainforestTests()

    func = (fileName, next) =>
      fileName = fileName.split('.')[0]
      if not @isFileExist path.join(landingTestPath, "#{fileName}.coffee")
        @generateMochaTest mapping, fileName, next
      else
        @isTestsValid mapping, fileName

    queue = fileNames.map (fileName) -> (next) -> func fileName, next
    async.series queue, callback


  generateMochaTest: (mapping, fileName, callback = ->) ->

    embedded = mapping[fileName]?.embedded

    mocha = "$ = require 'jquery'\n"
    mocha += "assert = require 'assert'\n"
    mocha += "#{embedded.name} = require './#{embedded.name}'\n\n"  if embedded
    mocha += "module.exports = ->\n\n"

    mocha += "\t#{embedded.name}()\n\n"  if embedded
    mocha += "\tdescribe '#{fileName}', ->\n"
    steps = mapping[fileName].steps
    steps.forEach (step) ->
      description = step.description
      description = description.replace /"/g, "'"
      asserts = step.asserts
      mocha += "\t\tdescribe \"#{description}?\", ->\n"
      mocha += '\t\t\tbefore (done) -> \n'
      mocha += '\t\t\t\t# implement before hook \n\t\t\t\tdone()\n\n\n'

      asserts.forEach (it) ->
        it = it.replace /"/g, "'"
        mocha += "\t\t\tit \"#{it}?\", (done) -> \n"
        mocha += "\t\t\t\tassert(false, 'Not Implemented')\n\t\t\t\tdone()\n\n"

    @save fileName, mocha, callback


  save: (fileName, data, callback = ->) ->

    fs.writeFile path.join(landingTestPath, "#{fileName}.coffee"), data, ->
      callback()
    fs.appendFile path.join(landingTestPath, "index.coffee"), "\t#{fileName}: require './#{fileName}'\n"
    fs.appendFile path.join(landingTestPath, "filenames.coffee"), "\t'#{fileName}'\n"


  initializeNeccessaryFiles: ->

    fs.writeFile path.join(landingTestPath, 'index.coffee'), 'module.exports = {\n'
    fs.writeFile path.join(landingTestPath, 'filenames.coffee'), 'module.exports = {\n'


  closeNeccessaryFiles: ->

    fs.appendFile path.join(landingTestPath, 'index.coffee'), "}\n"
    fs.appendFile path.join(landingTestPath, 'filenames.coffee'), "}\n"


generator = new Generator()
generator.initializeNeccessaryFiles()
mapping = generator.createMappingIfNotExist()
generator.generateMochaTests mapping, ->
  generator.closeNeccessaryFiles()

