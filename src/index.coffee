require 'should'
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

class NormalFeedback
    constructor: () ->
        @testCount = 0
        @errors = []
        @passingTests = []
        @failingTests = []
    
    formatTestName: (fixtureName, testName) -> "#{fixtureName} -> #{testName}"
    
    start: (fixtureName, testName) -> @testCount++

    pass: (fixtureName, testName) ->
        @passingTests.push (@formatTestName fixtureName, testName)
        process.stdout.write "."

    fail: (fixtureName, testName, error) ->
        formattedTestName = @formatTestName fixtureName, testName
        @errors.push "error in test #{formattedTestName} \n\t Error: #{error} \n\t Trace: #{error.stack}"
        @failingTests.push formattedTestName
        process.stdout.write "F"
        
    setupFail: (fixtureName, testName, error) ->
        formattedTestName = @formatTestName fixtureName, testName
        @failingTests.push formattedTestName
        console.log "error in setup for : #{formattedTestName} \n\t Error: #{error}"
        
    tearDownFail: (fixtureName, testName, error) ->
        formattedTestName = @formatTestName fixtureName, testName
        console.log "error in teardown for : #{formattedTestName} \n\t Error: #{error}"
        
    finish: () ->
        console.log "\n\nran #{@tests} tests >> #{@passingTests.length} passed >> #{@failingTests.length} failed"
        if @failingTests.length > 0 then console.log "#{test}\n" for test in @failingTests
        if @errors.length > 0 then console.log "#{error}\n" for error in @errors
        
class PorcelainFeedback
    porcelainMessage: (messageType, messageBody) -> process.stdout.write "JSTEST-PORCELAIN-#{messageType.toUpperCase()} #{JSON.stringify(messageBody)}\n"
    start: (fixtureName, testName) -> @porcelainMessage "TESTSTART", { fixture: fixtureName, test: testName }
    pass: (fixtureName, testName) -> @porcelainMessage "TESTPASS", { fixture: fixtureName, test: testName }
    fail: (fixtureName, testName, error) ->
        error = { message: error.message, stack: error.stack } if error.name == "AssertionError"
        @porcelainMessage "TESTFAIL", { fixture: fixtureName, test: testName, error: error }
    setupFail: (fixtureName, testName, error) ->
        error = { message: error.message, stack: error.stack } if error.name == "AssertionError"
        @porcelainMessage "SETUPFAIL", { fixture: fixtureName, test: testName, error: error }
    tearDownFail: (fixtureName, testName, error) ->
        error = { message: error.message, stack: error.stack } if error.name == "AssertionError"
        @porcelainMessage "TEARDOWNFAIL", { fixture: fixtureName, test: testName, error: error }
    finish: () ->


class global.Runner
    constructor: (@testRoot, @fileMatcher) ->
        @files = glob.sync "#{@testRoot}/**/#{fileMatcher}"
        require(path.resolve file) for file in @files
        @porcelain = (arg for arg in (process.argv.splice 2) when arg == '--porcelain').length > 0

    run: ->
       feedback = if @porcelain then (new PorcelainFeedback) else (new NormalFeedback)

       for fixture in global._fixtures
          for own testName, testAction of fixture.body
            continue if testName == 'setup' or testName == 'teardown'
            
            setupFailed = false
            feedback.start fixture.name, testName

            try
              fixture.setup?()
            catch error
              if not error.stack?
                error.stack = "unknown"
              feedback.setupFail fixture.name, testName, error
              setupFailed = true
             
              
            if not setupFailed
              try
                testAction()
                feedback.pass fixture.name, testName
              catch error
                if not error.stack?
                    error.stack = "unknown"
                feedback.fail fixture.name, testName, error

            try
              fixture.teardown?()
            catch error
              if not error.stack?
                error.stack = "unknown"
              feedback.tearDownFail fixture.name, testName, error

        feedback.finish()
        
        # seems there's a bug in node where it doesn't wait for redirected output to be processed before exiting.
        #   not sure how else to work around this!
        setTimeout (() -> process.exit()), 100

runner = new Runner(".", "**/tests/*_tests.coffee") # '.' in this case is based on running from the base dir
runner.run()
