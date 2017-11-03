/**
 * @module sns
 * @overview expose underlying sns driver for testing purposes
 */
import AWS from 'aws-sdk';

export const inject = {
  name: 'sns',
  require: ['config'],
};

export default function (config) {
  const TopicArn = config.get('sns.topic_arn');
  const sns = new AWS.SNS();

  /**
   * Publish a message to SNS
   * @param  {String}  Message - sns message
   * @return {Promise}
   */
  async function publish(Message) {
    return sns.publish({ Message, TopicArn }).promise();
  }

  return {
    publish,
    sns: () => sns,
  };
}
