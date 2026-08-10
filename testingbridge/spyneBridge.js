/**
 * Thin JS wrapper around the native Spyne module.
 *
 * Works on both iOS (`SpyneModule`) and Android (`SpyneModule`) via NativeModules.Spyne.
 */

import { NativeModules } from 'react-native';

const Spyne = NativeModules.Spyne
  ? NativeModules.Spyne
  : new Proxy(
      {},
      {
        get() {
          throw new Error(
            'NativeModules.Spyne is not linked. Rebuild the native app after installing the Spyne SDK bridge.',
          );
        },
      },
    );

/**
 * Starts a Spyne automobile shoot.
 *
 * @param {string} userId Spyne user / email identifier
 * @param {string} vin Optional VIN (17 characters when provided)
 * @param {string} stockNumber Optional stock number
 * @param {string} registrationNumber Optional registration number
 * @param {string} [locale='en'] Locale code for SDK UI strings
 */
export const start = (
  userId,
  vin,
  stockNumber,
  registrationNumber,
  locale = 'en',
) => {
  return Spyne.start(userId, vin, stockNumber, registrationNumber, locale);
};

export default Spyne;
