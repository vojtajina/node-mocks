#==============================================================================
# glob.js module
#==============================================================================
describe 'glob', ->
  createMock = require('../lib/glob').create
  predictableNextTick = require('../lib/util').predictableNextTick
  globMock = spy = null

  beforeEach ->
    spy = jasmine.createSpy 'done'
    globMock = createMock
      '/some/*.js': ['/some/a.js', '/some/b.js']
      '*.txt': ['my.txt', 'other.txt']

  it 'should be async', ->
    globMock '*.txt', null, spy
    expect(spy).not.toHaveBeenCalled();

  it 'should return predefined results', ->
    spy.andCallFake (err, results) ->
      expect(err).toBeFalsy()
      expect(results).toEqual ['/some/a.js', '/some/b.js']

    globMock '/some/*.js', null, spy
    waitsFor (-> spy.callCount), 'done callback', 100


  it 'should use predictableNextTick', ->
    predictableNextTick.pattern = [1, 0]
    globMock '*.txt', null, spy
    globMock '/some/*.js', null, spy

    waitsFor (-> spy.callCount is 2), 'both callbacks', 100
    runs ->
      # expect reversed order (because of predictableTick.pattern)
      expect(spy.argsForCall[0][1]).toEqual ['/some/a.js', '/some/b.js']
      expect(spy.argsForCall[1][1]).toEqual ['my.txt', 'other.txt']


  it 'should throw if unexpected glob', ->
    expect(-> globMock 'unexpected', null, spy).toThrow 'Unexpected glob for "unexpected"!'

