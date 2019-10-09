const {healthz, publishBigQuery} = require('../src')
const {BigQuery}                 = require('@google-cloud/bigquery')

const chai                       = require('chai')
const expect                     = require('chai').expect
const sinon                      = require('sinon')
const sinonChai                  = require('sinon-chai')

chai.should()
chai.use(sinonChai)


afterEach(() => {
    sinon.restore()
})

describe('Test function', function() {
    it('healthz respond success', function() {
	const status = sinon.stub()
	const send   = sinon.spy()
        
	const req = { query: {}, body: {}}
	const res = { status, send }
	status.returns(res)
	
	healthz(req, res)
	
	status.should.have.been.calledWith(200)
	expect(send).to.have.been.calledWith("hello")
    })
})



