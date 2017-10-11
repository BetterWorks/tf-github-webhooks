import { expect } from 'chai';
import { before, afterEach, describe, it } from 'mocha';
import sinon from 'sinon';

import { handler, promisify, sns } from '../../../lib/publish';
import webhookEvent from './webhook-event.json';

describe('[integration] publish', function () {
  before(function () {
    this.sandbox = sinon.sandbox.create();
  });

  afterEach(function () {
    this.sandbox.restore();
  });

  it('should fail (401) if signature is missing');
  it('should fail (401) if signature header is invalid');
  it('should fail (403) if signature is incorrect');
  it('should fail (500) if there is an unexpected error publishing to SNS');
  it('should succeed (200) with SNS message id', function () {
    const MessageId = 'abcdefg';
    this.sandbox.stub(sns, 'publish').yieldsAsync(null, { MessageId });
    return promisify((done) => {
      handler(webhookEvent, {}, done);
    })
    .then((res) => {
      expect(res).to.have.property('statusCode', 200);
      expect(res).to.have.deep.property('headers.Content-Type', 'application/json');
      expect(res).to.have.property('body').that.is.a('string');
      const body = JSON.parse(res.body);
      expect(body).to.have.deep.property('jsonapi.version', '1.0');
      expect(body).to.have.deep.property('data.type', 'github-webhook-acknowledgement');
      expect(body).to.have.deep.property('data.id', MessageId);
    });
  });
});
