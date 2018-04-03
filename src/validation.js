/**
 * @module validation
 * @overview json schema validation provider
 */
import Ajv from 'ajv';

import config from '../schemas/config.json';

export const inject = {
  name: 'validation',
};

export default function () {
  return new Ajv({
    $data: true,
    coerceTypes: 'array',
    useDefaults: true,
    schemas: {
      config,
    },
  });
}
