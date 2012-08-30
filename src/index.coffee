window = {}
global.window = window

global._fixtures = []

global.fixture = (name, fixtureBody) ->
   setup = fixtureBody.setup ? (()->)
   teardown = fixtureBody.teardown ? (()->)
   _fixtures.push {name: name, body: fixtureBody(), setup: setup, teardown: teardown}

global.Runner = {}
global.Runner.run = () ->
   for fixture in global._fixtures
      console.log 'executing fixture: ' + fixture.name
      setup?()

      for own name, test of fixture.body
         console.log 'executing test: ' + name
         test()

      teardown?()



fixture "sample", ->
  setup: ->
      console.log 'hello from setup'

  'it should do awesome': ->
      console.log 'the awesome test'

  teardown: ->
      console.log 'A teardown'

Runner.run()
