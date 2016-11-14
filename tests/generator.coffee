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
    mocha = ''
    filename = @filename
    @parsedBody.forEach (test, index) ->
      return mocha = "describe '#{filename}', ->\n" if index is 0
      replacedChar = new RegExp "'", "g"
      should = test.split('\n')[0].replace replacedChar, "\\'"
      mocha += "  it '#{should}', ->\n"
      mocha += "    console.warning 'Not yet implemented.'\n\n"

      assertions = test.split('\n')[1].split('? ')

      assertions.forEach (assertion, index, array) ->
        if assertion.length > 1
          mocha += "    \# #{assertion}?\n"

        mocha += "\n" if index is (array.length - 1)

    @mocha = mocha

  save: () ->
    file = @filename.split('.')[0] + '.coffee'
    fs.writeFile("./#{file}", @mocha)



files = Generator.getRainforestTests()

generator = new Generator()

files.forEach (file) ->
  if not Generator.isFileExist file.split('.')[0] + '.coffee'
    generator.openFile file
    generator.parseFile()
    generator.generateMochaTest()
    generator.save()
