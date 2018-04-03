/**
 * @module config
 * @overview encrypted configuration provider
 */
import ssmConfig from '@cludden/ssm-config';

export const inject = {
  name: 'config',
  require: ['ssm', 'validation'],
};

export default function (ssm, v) {
  // load configuration from ssm on cold start
  return ssmConfig({
    prefix: process.env.CONFIG_PREFIX.split(','),
    ssm,
    validate(c) {
      if (!v.validate('config', c)) {
        throw new Error(`Invalid Configuration: ${v.errorsText(v.errors)}`);
      }
    },
  });
}
