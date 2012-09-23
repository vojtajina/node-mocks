#==============================================================================
# test/mock/util.js module
#==============================================================================
describe 'mock-util', ->
  util = require '../lib/util'

  #============================================================================
  # util.predictableNextTick()
  #============================================================================
  describe 'predictableNextTick', ->
    nextTick = util.predictableNextTick

    it 'should be async', ->
      spy = jasmine.createSpy 'nextTick callback'
      nextTick spy

      expect(spy).not.toHaveBeenCalled()
      waitsFor (-> spy.callCount), 'nextTick', 100


    it 'should behave predictable based on given pattern', ->
      stressIt = ->
        log = ''
        runs ->
          nextTick.pattern = [1, 0]

          nextTick -> log += 1
          nextTick -> log += 2
          nextTick -> log += 3
          nextTick -> log += 4
          waitsFor (-> log.length is 4), 'all nextTicks', 100
        runs ->
          expect(log).toBe '2143'

      # execute this test five times
      stressIt() for i in [1..5]


    it 'should do 021 pattern k*n fns', ->
      nextTick.pattern = [0, 2, 1]
      log = ''
      nextTick -> log += 0
      nextTick -> log += 1
      nextTick -> log += 2
      nextTick -> log += 3
      nextTick -> log += 4
      nextTick -> log += 5
      waitsFor (-> log.length is 6), 'all nextTicks', 100
      runs ->
        expect(log).toBe '021354'


    it 'should do 3021 pattern with n+1 fns', ->
      nextTick.pattern = [3, 0, 2, 1]
      log = ''
      nextTick -> log += 0
      nextTick -> log += 1
      nextTick -> log += 2
      nextTick -> log += 3
      nextTick -> log += 4
      waitsFor (-> log.length is 5), 'all nextTicks', 100
      runs ->
        expect(log).toBe '30214'


    # regression
    it 'should survive exception inside callback and fire callbacks registered afterwards', ->
      exceptionHandled = false
      beforeExceptionSpy = jasmine.createSpy 'before exception'
      afterExceptionSpy = jasmine.createSpy 'after exception'

      nextTick beforeExceptionSpy
      nextTick -> throw 'CALLBACK EXCEPTION'
      nextTick afterExceptionSpy

      uncaughtExceptionHandler = (err) ->
        process.removeListener 'uncaughtException', uncaughtExceptionHandler
        exceptionHandled = true

      process.on 'uncaughtException', uncaughtExceptionHandler
      waitsFor (-> afterExceptionSpy.callCount), 'after exception callback', 100
      runs ->
        expect(beforeExceptionSpy.callCount).toBe 1
        expect(afterExceptionSpy.callCount).toBe 1
        expect(exceptionHandled).toBe true


    # regression
    it 'should not ignore fn that was added into already skipped space during execution', ->
      nextTick.pattern = [1, 0]
      anotherCallback = jasmine.createSpy 'another later added fn'
      callback = jasmine.createSpy 'later added fn'

      nextTick ->
        nextTick ->
          callback()
          nextTick anotherCallback

      waitsFor (-> callback.callCount), 'later added fn to be called', 100
      waitsFor (-> anotherCallback.callCount), 'another later added fn to be called', 100


    it 'should follow pattern even if callbacks are nested', ->
      nextTick.pattern = [0, 2, 3, 1]
      log = []

      nextTick ->
        log.push '0'
        nextTick ->
          log.push '01'
        nextTick ->
          log.push '02'

      nextTick ->
        log.push '1'

      waitsFor (-> log.length is 4), 'all callbacks processed', 100
      runs ->
        expect(log).toEqual ['0', '01', '02', '1']


    # regression
    it 'should recover after error', ->
      spy = jasmine.createSpy 'nextTick callback'

      exceptionHandled = false
      uncaughtExceptionHandler = (err) ->
        process.removeListener 'uncaughtException', uncaughtExceptionHandler
        exceptionHandled = true

      process.on 'uncaughtException', uncaughtExceptionHandler

      nextTick ->
        throw new Error 'SOME ERR'

      waitsFor (-> exceptionHandled), 'exception handled', 100

      # register another tick callback, after the handled exception
      runs ->
        nextTick spy
      waitsFor (-> spy.callCount), 'spy being called', 100


  #============================================================================
  # util.loadFile()
  #============================================================================
  describe 'loadFile', ->
    loadFile = util.loadFile
    fixturePath = __dirname + '/fixtures/some.js'

    it 'should load file with access to private state', ->
      module = loadFile fixturePath
      expect(module.privateNumber).toBe 100


    it 'should inject mocks', ->
      fsMock = {}
      module = loadFile fixturePath, {fs: fsMock}
      expect(module.privateFs).toBe fsMock


    it 'should load local modules', ->
      module = loadFile fixturePath
      expect(module.privateLocalModule).toBeDefined()
      expect(module.privateLocalModule.id).toBe 'LOCAL_MODULE'


    it 'should inject globals', ->
      fakeConsole = {}
      module = loadFile fixturePath, {}, {console: fakeConsole}
      expect(module.privateConsole).toBe fakeConsole


    it 'should inject mocks into nested modules', ->
      fsMock = {}

      # /fixtures/some.js requires /fixtures/other.js
      # /fixtures/other.js requires fs
      module = loadFile fixturePath, {fs: fsMock}, {}, true

      expect(module.privateLocalModule.fs).toBe fsMock

