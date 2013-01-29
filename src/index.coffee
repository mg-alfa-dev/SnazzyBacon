require 'should'
glob = require 'glob'
jsdom = require 'jsdom'
path = require 'path'

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
    @errors = {}
    @passingTests = []
    @failingTests = {}
    @setupFailures = {}
    @teardownFailures = {}
  
  formatTestName: (fixtureName, testName) -> "#{fixtureName} -> #{testName}"
  
  start: (fixtureName, testName) -> 
    @errors[fixtureName] = []
    @failingTests[fixtureName] = []
    @setupFailures[fixtureName] = null
    @teardownFailures[fixtureName] = null
    @testCount++

  pass: (fixtureName, testName) ->
    @passingTests.push (@formatTestName fixtureName, testName)
    process.stdout.write "."

  fail: (fixtureName, testName, error) ->
    trimmedStack = @trimStack(error.stack)
    @errors[fixtureName].push "\"#{testName}\" => \n\t Error: #{error} \n\t Trace: #{trimmedStack}"
    @failingTests[fixtureName].push testName
    process.stdout.write "F"
    
  setupFail: (fixtureName, testName, error) ->
    @setupFailures[fixtureName] = @trimStack(error.stack)
    process.stdout.write "S"
    
  tearDownFail: (fixtureName, testName, error) ->
    @teardownFailures[fixtureName] = @trimStack(error.stack)
    process.stdout.write "T"
    
  fixtureStart: () ->
  fixtureFinish: () ->    
    
  finish: () ->
    numberOfFailingTests = 0
    for fixtureName, tests of @failingTests
      numberOfFailingTests += tests.length
    console.log "\n\nran #{@tests} tests >> #{@passingTests.length} passed >> #{numberOfFailingTests} failed\n"

    setupFailures = 0
    for fixtureName, tests of @setupFailures
      setupFailures++ if tests?
    if setupFailures > 0
      console.log "================================"
      console.log "Setup Failures"
      console.log "================================"
      for fixtureName, error of @setupFailures when error?
        console.log "\"#{fixtureName}\" =>"
        console.log "    Stack: #{error}"
      console.log()

    teardownFailures = 0
    for fixtureName, tests of @teardownFailures
      teardownFailures++ if tests?
    if teardownFailures > 0
      console.log "================================"
      console.log "Teardown Failures"
      console.log "================================"
      console.log()
      for fixtureName, error of @teardownFailures when error?
        console.log "\"#{fixtureName}\""
        console.log "    Stack: #{error}"
      console.log()

    if numberOfFailingTests > 0 
      console.log "================================"
      console.log "Test Failures"
      console.log "================================"
      console.log()
      for fixtureName, tests of @failingTests
        continue unless tests.length > 0
        console.log "#{fixtureName}: #{tests.length} FAILING"
        for test in tests
          console.log "    #{test}"
        console.log()

    numberOfErrors = 0
    for fixtureName, tests of @errors
      numberOfErrors += tests.length
    if numberOfErrors > 0 
      console.log "================================"
      console.log "Call stacks"
      console.log "================================"
      console.log()
      for fixtureName, tests of @failingTests
        console.log "#{error}\n" for error in @errors[fixtureName]

  trimStack: (stack) =>
    return "unknown" if stack == "unknown"
    stackArr = stack.split '\n'
    while true
      break if stackArr.length == 0
      break if stackArr[stackArr.length - 1].indexOf("Runner.global.Runner.Runner.run") > -1
      stackArr.pop()
    stackArr.pop() if stackArr.length > 1
    return "unknown" if stackArr.length == 0
    return stackArr.join "\n"
    
class PorcelainFeedback
  porcelainMessage: (messageType, messageBody) -> process.stdout.write "JSTEST-PORCELAIN-#{messageType.toUpperCase()} #{JSON.stringify(messageBody)}\n"
  start: (fixtureName, testName) -> @porcelainMessage "TESTSTART", { fixture: fixtureName, test: testName }
  pass: (fixtureName, testName) -> @porcelainMessage "TESTPASS", { fixture: fixtureName, test: testName }
  fail: (fixtureName, testName, error) ->
    error = { message: error.message, stack: @trimStack(error.stack) }
    @porcelainMessage "TESTFAIL", { fixture: fixtureName, test: testName, error: error }
  setupFail: (fixtureName, testName, error) ->
    error = { message: error.message, stack: @trimStack(error.stack) }
    @porcelainMessage "SETUPFAIL", { fixture: fixtureName, test: testName, error: error }
  tearDownFail: (fixtureName, testName, error) ->
    error = { message: error.message, stack: @trimStack(error.stack) }
    @porcelainMessage "TEARDOWNFAIL", { fixture: fixtureName, test: testName, error: error }
  finish: () ->
  fixtureStart: () ->
  fixtureFinish: () ->

  trimStack: (stack) =>
    return "unknown" if stack == "unknown"
    stackArr = stack.split '\n'
    while true
      break if stackArr.length == 0
      break if stackArr[stackArr.length - 1].indexOf("Runner.global.Runner.Runner.run") > -1
      stackArr.pop()
    stackArr.pop() if stackArr.length > 1
    return "unknown" if stackArr.length == 0
    return stackArr.join "\n"

class TeamCityFeedback
    outputMessage: (state, name, message, details) ->
      name = name.replace "'", ""
      process.stdout.write "##teamcity[#{state} name='#{name}']\r\n"

    start: (fixtureName, testName) -> 
      @outputMessage 'testStarted', testName
      
    finish: (fixtureName, testName) -> 
   
    pass: (fixtureName, testName) -> 
      @outputMessage 'testPassed', testName
      @outputMessage 'testFinished', testName
     
    fail: (fixtureName, testName, error) -> 
      @outputMessage 'testFailed', testName
      @outputMessage 'testFinished', testName
      
      # process.stdout.write "##teamcity[testFailed name='#{testName}' message='#{error}' details='#{error}']\r\n"
      # process.stdout.write "##teamcity[testFinished name='#{testName}']\r\n"
      
    setupFail: (fixtureName, testName, error) ->
    tearDownFail: (fixtureName, testName, error) ->
    
    fixtureStart: (fixtureName) ->
      @outputMessage 'testSuiteStarted', fixtureName
    
    fixtureFinish: (fixtureName) ->
      @outputMessage 'testSuiteFinished', fixtureName
      
class global.Runner
  constructor: (@testRoot, @fileMatcher) ->
    @files = glob.sync "#{@testRoot}/**/#{fileMatcher}"
    require(path.resolve file) for file in @files
    @porcelain = process.argv[2] == '--porcelain'
    @teamcity = process.argv[2] == '--teamcity'
    
  run: ->
    if @teamcity
      feedback = new TeamCityFeedback
    if @porcelain
      feedback = new PorcelainFeedback
    if !@porcelain and !@teamcity
      feedback = new NormalFeedback

    for fixture in global._fixtures
      for own testName, testAction of fixture.body
        continue if testName == 'setup' or testName == 'teardown'
        
        setupFailed = false
        feedback.start fixture.name, testName

        try
          fixture.setup?()
        catch error
          if(typeof(error) == 'string')
            error = new Error(error) 
            error.stack = undefined
          error.stack = "unknown" unless error.stack?
          feedback.setupFail fixture.name, testName, error
          setupFailed = true
         
          
        if not setupFailed
          try
            testAction()
            feedback.pass fixture.name, testName
          catch error
            if(typeof(error) == 'string')
              error = new Error(error) 
              error.stack = undefined
            error.stack = "unknown" unless error.stack?
            feedback.fail fixture.name, testName, error

        try
          fixture.teardown?()
        catch error
          if(typeof(error) == 'string')
            error = new Error(error) 
            error.stack = undefined
          error.stack = "unknown" unless error.stack?
          feedback.tearDownFail fixture.name, testName, error

    feedback.finish()
    
    # seems there's a bug in node where it doesn't wait for redirected output to be processed before exiting.
    #   not sure how else to work around this!
    setTimeout (() -> process.exit()), 100

runner = new Runner(".", "**/tests/*_tests.coffee") # '.' in this case is based on running from the base dir
runner.run()
