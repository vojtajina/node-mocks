#==============================================================================
# test/mock/fs.js module
#==============================================================================
describe 'fs', ->
  fsMock = require '../lib/fs'
  fs = callback = finished = null

  waitForFinished = (count = 1, name = 'FS') ->
    waitsFor (-> finished == count), name, 100

  beforeEach ->
    finished = 0

    fs = fsMock.create
      bin:
        grep: 1
        chmod: 1
      home:
        vojta:
          sub:
            'first.js': 1
            'second.js': 1
            'third.log': 1
          sub2:
            'first.js': 1
            'second.js': 1
            'third.log': 1
          'some.js': fsMock.file '2012-01-01', 'some'
          'another.js': fsMock.file '2012-01-02', 'content'


  # ===========================================================================
  # fs.stat()
  # ===========================================================================
  describe 'stat', ->

    it 'should be async', ->
      callback = jasmine.createSpy 'done'
      fs.stat '/bin', callback
      expect(callback).not.toHaveBeenCalled()


    it 'should stat directory', ->
      fs.stat '/bin', (err, stat) ->
        expect(err).toBeFalsy()
        expect(stat.isDirectory()).toBe true
        finished++
      waitForFinished()


    it 'should stat file', ->
      callback = (err, stat) ->
        expect(err).toBeFalsy()
        expect(stat.isDirectory()).toBe false
        finished++

      fs.stat '/bin/grep', callback
      fs.stat '/home/vojta/some.js', callback
      waitForFinished 2


    it 'should return error when path does not exist', ->
      callback = (err, stat) ->
        expect(err).toBeTruthy()
        expect(stat).toBeFalsy()
        finished++

      fs.stat '/notexist', callback
      fs.stat '/home/notexist', callback
      waitForFinished 2


    it 'should have modified timestamp', ->
      callback = (err, stat) ->
        expect(err).toBeFalsy()
        expect(stat.mtime instanceof Date).toBe true
        expect(stat.mtime).toEqual new Date '2012-01-01'
        finished++

      fs.stat '/home/vojta/some.js', callback
      waitForFinished()


  # ===========================================================================
  # fs.statSync()
  # ===========================================================================
  describe 'statSync', ->

    it 'should stat directory', ->
      stat = fs.statSync '/bin'
      expect(stat.isDirectory()).toBe true


    it 'should stat file', ->
      stat = fs.statSync '/bin/grep'
      expect(stat.isDirectory()).toBe false

      stat = fs.statSync '/home/vojta/some.js'
      expect(stat.isDirectory()).toBe false


    it 'should throw an error when path does not exist', ->
      expect(-> fs.statSync '/notexist').toThrow 'ENOENT, no such file or directory "/notexist"'


  # ===========================================================================
  # fs.readdir()
  # ===========================================================================
  describe 'readdir', ->

    it 'should be async', ->
      callback = jasmine.createSpy 'done'
      fs.readdir '/bin', callback
      expect(callback).not.toHaveBeenCalled()


    it 'should return array of files and directories', ->
      callback = (err, files) ->
        expect(err).toBeFalsy()
        expect(files).toContain 'sub'
        expect(files).toContain 'some.js'
        expect(files).toContain 'another.js'
        finished++

      fs.readdir '/home/vojta', callback
      waitForFinished()


    it 'should return error if does not exist', ->
      callback = (err, files) ->
        expect(err).toBeTruthy()
        expect(files).toBeFalsy()
        finished++

      fs.readdir '/home/not', callback
      waitForFinished()


  # ===========================================================================
  # fs.readdirSync
  # ===========================================================================
  describe 'readdirSync', ->

    it 'should read dir content and sync return all content files', ->
      content = fs.readdirSync '/home/vojta/sub'
      expect(content instanceof Array).toBe true
      expect(content).toEqual ['first.js','second.js','third.log']


    it 'should throw when dir does not exist', ->
      expect(-> fs.readdirSync '/non-existing').
        toThrow 'ENOENT, no such file or directory "/non-existing"'


    it 'should throw when reading a file', ->
      expect(-> fs.readdirSync '/home/vojta/some.js').
        toThrow 'ENOTDIR, not a directory "/home/vojta/some.js"'


  # ===========================================================================
  # fs.mkdir()
  # ===========================================================================
  describe 'mkdir', ->

    it 'should be async', ->
      callback = jasmine.createSpy 'done'
      fs.mkdir '/bin', callback
      expect(callback).not.toHaveBeenCalled()


    it 'should create directory', ->
      callback = (err) ->
        expect(err).toBeFalsy()
        stat = fs.statSync '/home/new'
        expect(stat).toBeDefined()
        expect(stat.isDirectory()).toBe true
        finished++

      fs.mkdir '/home/new', callback
      waitForFinished()


    it 'should create a root directory', ->
      callback = (err) ->
        expect(err).toBeFalsy()
        stat = fs.statSync '/new-root'
        expect(stat).toBeDefined()
        expect(stat.isDirectory()).toBe true
        finished++

      fs.mkdir '/new-root', callback
      waitForFinished()


    it 'should return error if parent does not exist', ->
      callback = (err) ->
        expect(err).toBeTruthy()
        expect(err.errno).toBe 34
        expect(err.code).toBe 'ENOENT'
        finished++

      fs.mkdir '/new/non/existing', callback
      waitForFinished()


  # ===========================================================================
  # fs.mkdirSync()
  # ===========================================================================
  describe 'mkdirSync', ->

    it 'should create directory', ->
      fs.mkdirSync '/home/new'
      expect(fs.statSync('/home/new').isDirectory()).toBe true


  # ===========================================================================
  # fs.readFile
  # ===========================================================================
  describe 'readFile', ->

    it 'should read file content as Buffer', ->
      callback = (err, data) ->
        expect(err).toBeFalsy()
        expect(data instanceof Buffer).toBe true
        expect(data.toString()).toBe 'some'
        finished++

      fs.readFile '/home/vojta/some.js', callback
      waitForFinished()


    it 'should be async', ->
      callback = jasmine.createSpy 'calback'
      fs.readFile '/home/vojta/some.js', callback
      expect(callback).not.toHaveBeenCalled()


    it 'should call error callback when non existing file or directory', ->
      callback = (err, data) ->
        expect(err).toBeTruthy()
        finished++

      fs.readFile '/home/vojta', callback
      fs.readFile '/some/non-existing', callback
      waitForFinished 2


    # regression
    it 'should not silent exception from callback', ->
      fs.readFile '/home/vojta/some.js', (err) ->
        throw 'CALLBACK EXCEPTION' if not err

      uncaughtExceptionCallback = (err) ->
        process.removeListener 'uncaughtException', uncaughtExceptionCallback
        expect(err).toEqual 'CALLBACK EXCEPTION'
        finished++

      process.on 'uncaughtException', uncaughtExceptionCallback
      waitForFinished 1, 'exception', 100


    it 'should allow optional second argument (encoding)', ->
      fs.readFile '/home/vojta/some.js', 'utf-8', (err) ->
        finished++

      waitForFinished()


  # ===========================================================================
  # fs.readFileSync
  # ===========================================================================
  describe 'readFileSync', ->

    it 'should read file content and sync return buffer', ->
      buffer = fs.readFileSync '/home/vojta/another.js'
      expect(buffer instanceof Buffer).toBe true
      expect(buffer.toString()).toBe 'content'


    it 'should throw when file does not exist', ->
      expect(-> fs.readFileSync '/non-existing').
        toThrow 'No such file or directory "/non-existing"'


    it 'should throw when reading a directory', ->
      expect(-> fs.readFileSync '/home/vojta').
        toThrow 'Illegal operation on directory'


  # ===========================================================================
  # fs.writeFile
  # ===========================================================================
  describe 'writeFile', ->

    it 'should write file content as Buffer', ->
      callback = (err) ->
        expect(err).toBeFalsy()
        finished++

      fs.writeFile '/home/vojta/some.js', 'something', callback
      waitForFinished()

      runs ->
        expect(fs.readFileSync('/home/vojta/some.js').toString()).toBe 'something'


    it 'should return ENOENT when writing to non-existing directory', ->
      callback = (err) ->
        expect(err).toBeTruthy()
        expect(err instanceof Error).toBe true
        expect(err.code).toBe 'ENOENT'
        finished++

      fs.writeFile '/home/vojta/non/existing/some.js', 'something', callback
      waitForFinished()


  # ===========================================================================
  # fs.watchFile
  # ===========================================================================
  describe 'watchFile', ->

    it 'should call when when file accessed', ->
      callback = jasmine.createSpy('watcher').andCallFake (current, previous) ->
        expect(current.isFile()).toBe true
        expect(previous.isFile()).toBe true
        expect(current.mtime).toEqual previous.mtime

      fs.watchFile '/home/vojta/some.js', callback
      expect(callback).not.toHaveBeenCalled()

      fs._touchFile '/home/vojta/some.js'
      expect(callback).toHaveBeenCalled()


    it 'should call when file modified', ->
      original = new Date '2012-01-01'
      modified = new Date '2012-01-02'

      callback = jasmine.createSpy('watcher').andCallFake (current, previous) ->
        expect(previous.mtime).toEqual original
        expect(current.mtime).toEqual modified

      fs.watchFile '/home/vojta/some.js', callback
      expect(callback).not.toHaveBeenCalled()

      fs._touchFile '/home/vojta/some.js', '2012-01-02', 'new content'
      expect(callback).toHaveBeenCalled()


    it 'should allow optional second argument (options)', ->
      callback = jasmine.createSpy 'watcher'
      fs.watchFile '/home/vojta/some.js', {some: 'options'}, callback
      fs._touchFile '/home/vojta/some.js'

      expect(callback).toHaveBeenCalled()


  # ===========================================================================
  # fs.existsSync
  # ===========================================================================
  describe 'existsSync', ->

    it 'should return true for existing file and false for non-existing', ->
      expect(fs.existsSync '/home/vojta/some.js').toBe(true)
      expect(fs.existsSync '/home/vojta/non-existing.js').toBe(false)


  # ===========================================================================
  # fs.exists
  # ===========================================================================
  describe 'exists', ->

    it 'should callback with true for existing file', ->
      callback = (exists) ->
        expect(exists).toBe(true)
        finished++

      fs.exists '/home/vojta/some.js', callback
      waitForFinished()


    it 'should callback with false for none-existing file', ->
      callback = (exists) ->
        expect(exists).toBe(false)
        finished++

      fs.exists '/home/vojta/none-existing.js', callback
      waitForFinished()


  describe 'relative paths', ->

    it 'should read file with a relative path', ->
      callback = (err, data) ->
        expect(err).toBeFalsy()
        expect(data instanceof Buffer).toBe true
        expect(data.toString()).toBe 'some'
        finished++

      fs._setCWD '/home/vojta'
      fs.readFile './some.js', callback
      waitForFinished()
