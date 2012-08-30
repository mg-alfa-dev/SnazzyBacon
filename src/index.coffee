global.window = {}
global._fixtures = []

global.fixture = (name, fixtureBody) ->
   body = fixtureBody
   setup = body.setup ? (()->)
   teardown = body.teardown ? (()->)
   _fixtures.push {name, body,setup,teardown}

global.Runner = {}
global.Runner.run = () ->
   for fixture in global._fixtures
      console.log 'executing fixture: ' + fixture.name

      for own testName, testAction of fixture.body
        continue if testName == 'setup' or testName == 'teardown'
        
        try
          setup?()
        catch error
          console.log "error in setup for : #{testName} \n\t Error: #{error}"
          
        try
          testAction()
        catch error
          console.log "error in test for : #{testName} \n\t Error: #{error}"

        try
          teardown?()
        catch error
          console.log "error in teardown for: #{testName} \n\t Error: #{error}"


Object::shouldBeFalse = () -> if @ != false then throw "expected: false, but got: #{@}"
Object::shouldBeTrue = () -> if @ != true then throw "expected: true, but got: #{@}"

fixture "sample"
  setup: ->
      console.log 'hello from setup'

  'the awesome failing test': ->
      console.log 'a failing test'
      true.shouldBeFalse()

  teardown: ->
      console.log 'A teardown'

Runner.run()
