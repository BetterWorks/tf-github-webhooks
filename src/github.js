/**
 * @module github
 * @overview this module provides functionality related to parsing, authorizing,
 * and extracting information from github webhook events
 */
import crypto from 'crypto';
import get from 'lodash/get';

import { httpError } from './utils';

export const inject = {
  name: 'github',
  require: ['config'],
};

export default function (config) {
  const secret = config.get('github.secret');

  /**
   * extract and validate github signature from request headers
   * @param  {Object} e - lambda event
   * @return {String}
   */
  function parseSignature(e) {
    const signature = get(e, 'headers.X-Hub-Signature');
    if (!/^sha1=/g.test(signature)) {
      throw httpError('Missing/Invalid Signature', 'Unauthorized', 401);
    }
    return signature.replace('sha1=', '');
  }

  /**
   * verify github event signature
   * @param  {String} signature - x-hub-signature header
   * @param  {String} body      - event body
   * @return {Undefined}
   */
  function verifySignature(signature, body) {
    const verification = crypto.createHmac('sha1', secret).update(body).digest('hex');
    if (signature !== verification) {
      throw httpError('Invalid Signature', 'Forbidden', 403);
    }
  }

  return {
    parseSignature,
    verifySignature,
  };
}
