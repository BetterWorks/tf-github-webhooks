import { fromCallback } from 'bluebird';
import { expect } from 'chai';
import { cloneDeep } from 'lodash';
import { before, afterEach, describe, it } from 'mocha';
import sinon from 'sinon';

import { handler } from '../../src';
import container from '../../src/container';
import invalidEvent from './invalid-signature.json';
import webhookEvent from './webhook-event.json';

before(async function () {
  const ssm = await container.load('ssm');
  sinon.stub(ssm, 'getParametersByPath').returns({
    promise: sinon.stub().resolves({
      Parameters: [{
        Name: '/github/secret',
        Value: process.env.GITHUB_SECRET,
      }, {
        Name: '/log/level',
        Value: process.env.LOG_LEVEL,
      }, {
        Name: '/sns/topic_arn',
        Value: process.env.SNS_TOPIC_ARN,
      }].map((p) => {
        // eslint-disable-next-line
        p.Name = `${process.env.CONFIG_PREFIX}${p.Name}`;
        return p;
      }),
    }),
  });
});

describe('[integration] basic', function () {
  before(async function () {
    const modules = await container.load({
      sns: 'sns',
    });
    Object.assign(this, modules);
    this.sandbox = sinon.createSandbox();
  });

  afterEach(function () {
    this.sandbox.restore();
  });

  it('should fail (401) if signature is missing', async function () {
    const e = cloneDeep(webhookEvent);
    delete e.headers['X-Hub-Signature'];
    const spy = this.sandbox.spy(this.sns.sns(), 'publish');
    const res = await fromCallback(done => handler(e, {}, done));
    expect(res).to.have.property('statusCode', 401);
    expect(spy.callCount).to.equal(0);
  });

  it('should fail (401) if signature header is invalid', async function () {
    this.timeout(30000);
    const e = cloneDeep(webhookEvent);
    e.headers['X-Hub-Signature'] = e.headers['X-Hub-Signature'].replace('sha1=', 'foo=');
    const spy = this.sandbox.spy(this.sns.sns(), 'publish');
    const res = await fromCallback(done => handler(e, {}, done));
    expect(res).to.have.property('statusCode', 401);
    expect(spy.callCount).to.equal(0);
  });

  it('should fail (403) if signature is incorrect', async function () {
    const spy = this.sandbox.stub(this.sns.sns(), 'publish');
    const res = await fromCallback(done => handler(invalidEvent, {}, done));
    expect(res).to.have.property('statusCode', 403);
    expect(spy.callCount).to.equal(0);
  });

  it('should fail (500) if there is an unexpected error publishing to SNS', async function () {
    this.sandbox.stub(this.sns.sns(), 'publish').returns({
      promise: sinon.stub().rejects(new Error()),
    });
    const res = await fromCallback(done => handler(webhookEvent, {}, done));
    expect(res).to.have.property('statusCode', 500);
  });

  it('should succeed (200) with SNS message id', async function () {
    const MessageId = 'dc365e9d-1a1d-5f3d-8c39-0ce0b5ae410a';
    const stub = this.sandbox.stub(this.sns.sns(), 'publish').returns({
      promise: sinon.stub().resolves({
        ResponseMetadata: {
          RequestId: 'fb850c2e-2940-5353-a40e-5e5386f30d64',
        },
        MessageId,
      }),
    });
    const res = await fromCallback(done => handler(webhookEvent, {}, done));
    expect(stub.callCount).to.equal(1);
    const params = stub.lastCall.args[0];
    expect(params).to.have.property('Subject', webhookEvent.headers['X-GitHub-Event']);
    expect(res).to.have.property('statusCode', 200);
    expect(res).to.have.nested.property('headers.Content-Type', 'application/json');
    expect(res).to.have.property('body').that.is.a('string');
    const body = JSON.parse(res.body);
    expect(body).to.have.nested.property('jsonapi.version', '1.0');
    expect(body).to.have.nested.property('data.type', 'github-webhook-acknowledgement');
    expect(body).to.have.nested.property('data.id', MessageId);
  });
});
