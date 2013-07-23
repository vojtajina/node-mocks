#==============================================================================
# test/mock/http.js module
#==============================================================================
describe 'http', ->
  httpMock = require '../lib/http'

  #==============================================================================
  # http.ServerResponse
  #==============================================================================
  describe 'ServerResponse', ->
    response = null

    beforeEach ->
      response = new httpMock.ServerResponse

    it 'should set body', ->
      response.end 'Some Body'
      expect(response._body).toBe 'Some Body'


    it 'should convert body buffer to string', ->
      response.end new Buffer 'string'
      expect(response._body).toBe 'string'


    it 'should set status', ->
      response.writeHead 201
      expect(response._status).toBe 201


    it 'should throw when trygin to end() already finished reponse', ->
      response.end 'First Body'

      expect(-> response.end 'Another Body')
        .toThrow "Can't write to already finished response."
      expect(response._body).toBe 'First Body'


    it 'should set and remove headers', ->
      response.setHeader 'Content-Type', 'text/javascript'
      response.setHeader 'Cache-Control', 'no-cache'
      response.setHeader 'Content-Type', 'text/plain'
      response.removeHeader 'Cache-Control'

      expect(response._headers).toEqual {'Content-Type': 'text/plain'}


    it 'should getHeader()', ->
      response.setHeader 'Content-Type', 'json'
      expect(response.getHeader 'Content-Type').toBe 'json'


    it 'should throw when trying to send headers twice', ->
      response.writeHead 200

      expect(-> response.writeHead 200)
        .toThrow "Can't render headers after they are sent to the client."


    it 'should throw when trying to set headers after sending', ->
      response.writeHead 200

      expect(-> response.setHeader 'Some', 'Value')
        .toThrow "Can't set headers after they are sent."


    it 'should write body', ->
      response.write 'a'
      response.end 'b'

      expect(response._body).toBe 'ab'


    it 'should throw when trying to write after end', ->
      response.write 'one'
      response.end 'two'

      expect(-> response.write 'more')
        .toThrow "Can't write to already finished response."


    it 'isFinished() should assert whether headers and body has been sent', ->
      expect(response._isFinished()).toBe false

      response.setHeader 'Some', 'Value'
      expect(response._isFinished()).toBe false

      response.writeHead 404
      expect(response._isFinished()).toBe false

      response.end 'Some body'
      expect(response._isFinished()).toBe true


  #==============================================================================
  # http.ServerRequest
  #==============================================================================
  describe 'ServerRequest', ->

    it 'should return headers', ->
      request = new httpMock.ServerRequest '/some', {'Content-Type': 'json'}
      expect(request.getHeader 'Content-Type').toBe 'json'
