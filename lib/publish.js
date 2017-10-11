import AWS from 'aws-sdk';
import crypto from 'crypto';
import get from 'lodash/get';

const { SECRET, SNS_TOPIC_ARN } = process.env;
export const sns = new AWS.SNS();

/**
 * lambda function handler
 * @param  {Object}   e    - lambda event
 * @param  {Object}   ctx  - function context
 * @param  {Function} done - callback
 * @return {Promise}
 */
export async function handler(e, ctx, done) {
  try {
    console.log('event', JSON.stringify(e));
    const result = await processEvent(e);
    sendResponse(done, result, 200);
  } catch (err) {
    console.error(err);
    sendResponse(done, err, err.statusCode || 500);
  }
}

/**
 * create an error with additional attributes for generating http responses
 * @param  {String} msg                             - error message
 * @param  {String} [title='Internal Server Error'] - error title
 * @param  {Number} [statusCode=500]                - http status code
 * @return {Error}
 */
export function httpError(msg, title = 'Internal Server Error', statusCode = 500) {
  const err = new Error(msg);
  err.title = title;
  err.statusCode = statusCode;
  return err;
}

/**
 * extract and validate github signature from request headers
 * @param  {Object} e - lambda event
 * @return {String}
 */
export function parseGithubSignature(e) {
  const signature = get(e, 'headers.X-Hub-Signature');
  if (!/^sha1=/g.test(signature)) {
    throw httpError('Missing/Invalid Signature', 'Unauthorized', 401);
  }
  return signature.replace('sha1=', '');
}

/**
 * process github webhook event
 * @param  {Object} e - lambda event
 * @return {Promise}
 */
export async function processEvent(e) {
  const signature = parseGithubSignature(e);
  const body = get(e, 'body');
  verifySignature(signature.replace('sha1=', ''), body);
  return publishToSNS(body);
}

/**
 * function that returns a promise and accepts a function that accepts a callback
 * that can be used to resolve/reject the promise (aka Bluebird.fromCallback)
 * @param  {Function} fn
 * @return {Promise}
 */
export function promisify(fn) {
  return new Promise((resolve, reject) => {
    const done = (err, data) => {
      if (err) {
        return reject(err);
      }
      return resolve(data);
    };
    fn(done);
  });
}

/**
 * trigger build for codebuild project with the same name as the repository
 * name if one exists
 * @param  {Object} payload - github webhook payload
 * @return {Promise}
 */
export function publishToSNS(Message) {
  return promisify((done) => {
    sns.publish({ Message, TopicArn: SNS_TOPIC_ARN }, done);
  });
}

/**
 * send http response
 * @param  {Function} done       - callback
 * @param  {String}   body       - response body
 * @param  {Number}   statusCode - resopnse status code
 * @return {Undefined}
 */
export function sendResponse(done, body, statusCode) {
  const payload = { jsonapi: { version: '1.0' } };
  if (body instanceof Error) {
    payload.errors = [{
      title: body.title || 'Internal Server Error',
      detail: body.message,
      status: body.statusCode.toString(),
    }];
  } else {
    payload.data = {
      type: 'github-webhook-acknowledgement',
      id: body.MessageId,
    };
  }
  done(null, {
    statusCode,
    body: JSON.stringify(payload),
    headers: {
      'Content-Type': 'application/json',
    },
  });
}

/**
 * verify github event signature
 * @param  {String} signature - x-hub-signature header
 * @param  {String} body      - event body
 * @return {Undefined}
 */
export function verifySignature(signature, body) {
  const verification = crypto.createHmac('sha1', SECRET).update(body).digest('hex');
  if (signature !== verification) {
    throw httpError('Invalid Signature', 'Forbidden', 403);
  }
}
