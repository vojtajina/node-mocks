# simple unit test (jasmine syntax, coffescript)
describe 'app', ->
  mocks = require 'mocks'
  loadFile = mocks.loadFile
  app = done = null

  beforeEach ->
    done = jasmine.createSpy 'done'
    # load the file and inject fake fs module
    app = loadFile __dirname + '/app.js',
      fs: mocks.fs.create
        'bin':
          'run.sh': 1,
          'install.sh': 1
        'home':
          'some.js': 1,
          'another.txt': 1
        'one.js': 1,
        'two.js': 1,
        'three.js': 1


  it 'should return only existing files', ->
    done.andCallFake (err, filtered) ->
      expect(err).toBeFalsy()
      expect(filtered).toEqual ['/bin/run.sh']

    app.filterOnlyExistingFiles ['/bin/run.sh', '/non.txt'], done
    waitsFor -> done.callCount

  it 'should ignore directories', ->
    done.andCallFake (err, filtered) ->
      expect(filtered).toEqual ['/bin/run.sh', '/home/some.js']

    app.filterOnlyExistingFiles ['/bin/run.sh', '/home', '/home/some.js'], done
    waitsFor -> done.callCount

  it 'should preserve order', ->
    done.andCallFake (err, filtered) ->
      expect(filtered).toEqual ['/one.js', '/two.js', '/three.js']

    # mock fs will call back in this pattern order
    mocks.predictableNextTick.pattern = [2, 0, 1]
    app.filterOnlyExistingFiles ['/one.js', '/two.js', '/three.js'], done
    waitsFor -> done.callCount
