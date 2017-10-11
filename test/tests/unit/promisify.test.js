import { expect } from 'chai';
import { describe, it } from 'mocha';
import sinon from 'sinon';

import { promisify } from '../../../lib/publish';

describe('[unit] promisify', function () {
  it('should reject on callback error', function () {
    const errback = sinon.stub().yieldsAsync(new Error());
    return promisify(done => errback(done))
    .then(() => {
      throw new Error('promise should reject');
    })
    .catch((err) => {
      expect(err).to.be.instanceof(Error);
    });
  });

  it('should resolve with callback data', function () {
    const data = { foo: 'bar' };
    const callback = sinon.stub().yieldsAsync(null, data);
    return promisify(done => callback(done))
    .then((result) => {
      expect(result).to.equal(data);
    });
  });
});
