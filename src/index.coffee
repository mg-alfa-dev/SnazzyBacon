require 'should'
_ = require 'underscore'
glob = require 'glob'
path = require 'path'
jsdom = require 'jsdom'

global.window = global
global.document = jsdom.jsdom()
global.navigator = {}

navigator.userAgent = ""
document.addEventListener = ->

global._fixtures = []
global.includeJsFile = (filePath, contextObjectName) ->
    syncedFilePath = glob.sync "./**/#{filePath}"
    resolvedPath = path.resolve syncedFilePath[0]

    if contextObjectName?
        window[contextObjectName] = require(resolvedPath)
    else
        require(resolvedPath)

global.fixture = (name, fixtureBody) ->
   body = fixtureBody
   setup = body.setup ? (()->)
   teardown = body.teardown ? (()->)
   _fixtures.push {name, body,setup,teardown}

class global.Runner
    constructor: (@testRoot, @fileMatcher) ->
        @files = glob.sync "#{@testRoot}/**/#{fileMatcher}"
        _.map @files, (o) -> require(path.resolve o)

    formatTestName: (fixture, test) -> "#{fixture} \n\t #{test}"

    run: ->
       @tests = 0
       @errors = []
       @passingTests = []
       @failingTests = []
       for fixture in global._fixtures
          for own testName, testAction of fixture.body
            continue if testName == 'setup' or testName == 'teardown'
            
            @tests++
            try
              fixture.setup?()
            catch error
              console.log "error in setup for : #{testName} \n\t Error: #{error}"
              
            try
              testAction()
              @passingTests.push testName
              process.stdout.write "."
            catch error
              @errors.push  "error in test #{fixture.name} -> #{testName} \n\t Error: #{error} \n\t Trace: #{error.stack}"
              @failingTests.push @formatTestName(fixture.name, testName)
              process.stdout.write "F"

            try
              fixture.teardown?()
            catch error
              console.log "error in teardown for: #{testName} \n\t Error: #{error}"
             
        console.log "\n\nran #{@tests} tests >> #{@passingTests.length} passed >> #{@failingTests.length} failed"
        if @failingTests.length > 0 then _.map @failingTests, (o) -> console.log "#{o}\n"
        if @errors.length > 0 then _.map @errors, (o) -> console.log "#{o}\n"
        process.exit()

runner = new Runner(".", "**/tests/*_tests.coffee") # '.' in this case is based on running from the base dir
runner.run()
