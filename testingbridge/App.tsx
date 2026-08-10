/**
 * Spyne Automobile SDK — React Native sample
 *
 * Demonstrates starting a vehicle shoot and listening for native SDK events.
 *
 * @format
 */

import React, {useEffect, useState} from 'react';
import {
  Alert,
  Button,
  NativeEventEmitter,
  NativeModules,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from 'react-native';
import {start} from './spyneBridge';

const {Spyne} = NativeModules;
const spyneEventEmitter = new NativeEventEmitter(Spyne);

/**
 * The form is always rendered on a light background, so input colors are pinned
 * explicitly — otherwise Android's DayNight theme renders the text and hint
 * white in dark mode.
 */
const TEXT_COLOR = '#000';
const PLACEHOLDER_COLOR = '#999';

const App = () => {
  const [userId, setUserId] = useState('your-user@example.com');
  const [vin, setVin] = useState('');
  const [stockNumber, setStockNumber] = useState('');
  const [registrationNumber, setRegistrationNumber] = useState('');
  const [errors, setErrors] = useState({
    userId: false,
    atLeastOneField: false,
    vinLength: false,
  });

  useEffect(() => {
    const onShootInitiatedListener = spyneEventEmitter.addListener(
      'onShootInitiated',
      event => {
        console.log('[Spyne] onShootInitiated', event);
      },
    );

    const onShootCompletedListener = spyneEventEmitter.addListener(
      'onShootCompleted',
      event => {
        console.log('[Spyne] onShootCompleted', event);
      },
    );

    const onShootExitListener = spyneEventEmitter.addListener(
      'onShootExit',
      event => {
        console.log('[Spyne] onShootExit', event);
      },
    );

    return () => {
      onShootInitiatedListener.remove();
      onShootCompletedListener.remove();
      onShootExitListener.remove();
    };
  }, []);

  /** Validates form fields and starts the native Spyne shoot flow. */
  const handleStartShoot = () => {
    const newErrors = {
      userId: false,
      atLeastOneField: false,
      vinLength: false,
    };

    if (!userId || userId.trim() === '') {
      newErrors.userId = true;
    }

    const hasVin = vin && vin.trim() !== '';
    const hasStockNumber = stockNumber && stockNumber.trim() !== '';
    const hasRegistrationNumber =
      registrationNumber && registrationNumber.trim() !== '';

    if (!hasVin && !hasStockNumber && !hasRegistrationNumber) {
      newErrors.atLeastOneField = true;
    }

    if (hasVin && vin.trim().length !== 17) {
      newErrors.vinLength = true;
    }

    setErrors(newErrors);

    if (newErrors.userId || newErrors.atLeastOneField || newErrors.vinLength) {
      const errorMessages = [];
      if (newErrors.userId) {
        errorMessages.push('User ID is required.');
      }
      if (newErrors.atLeastOneField) {
        errorMessages.push(
          'At least one of VIN, Stock Number, or Registration Number is required.',
        );
      }
      if (newErrors.vinLength) {
        errorMessages.push('VIN must be exactly 17 characters long.');
      }
      Alert.alert('Validation Error', errorMessages.join(' '));
      return;
    }

    start(userId, vin || '', stockNumber || '', registrationNumber || '', 'en');
  };

  /** Fills the VIN field with a random 17-character value for quick testing. */
  const generateRandomVIN = () => {
    const vinChars = 'ABCDEFGHJKLMNPRSTUVWXYZ0123456789';
    let nextVin = '';
    for (let i = 0; i < 17; i++) {
      nextVin += vinChars.charAt(Math.floor(Math.random() * vinChars.length));
    }
    setVin(nextVin);
    if (errors.vinLength) {
      setErrors({...errors, vinLength: false});
    }
  };

  const showAtLeastOneFieldError =
    errors.atLeastOneField &&
    !vin.trim() &&
    !stockNumber.trim() &&
    !registrationNumber.trim();

  return (
    <ScrollView contentContainerStyle={styles.container}>
      <View style={styles.formContainer}>
        <Text style={styles.title}>Spyne Automobile SDK</Text>
        <Text style={styles.subtitle}>
          Enter vehicle details, then start a guided shoot.
        </Text>

        <Text style={styles.label}>
          User ID / Email <Text style={styles.required}>*</Text>
        </Text>
        <TextInput
          style={[styles.input, errors.userId && styles.inputError]}
          placeholder="Enter User ID or Email"
          placeholderTextColor={PLACEHOLDER_COLOR}
          value={userId}
          onChangeText={text => {
            setUserId(text);
            if (errors.userId) {
              setErrors({...errors, userId: false});
            }
          }}
          autoCapitalize="none"
          keyboardType="email-address"
        />
        {errors.userId && (
          <Text style={styles.errorText}>User ID is required</Text>
        )}

        <View style={styles.labelContainer}>
          <Text style={styles.label}>VIN</Text>
          <TouchableOpacity onPress={generateRandomVIN}>
            <Text style={styles.generateButton}>Generate Random VIN</Text>
          </TouchableOpacity>
        </View>
        <TextInput
          style={[
            styles.input,
            (showAtLeastOneFieldError || errors.vinLength) && styles.inputError,
          ]}
          placeholder="Enter VIN (17 characters)"
          placeholderTextColor={PLACEHOLDER_COLOR}
          value={vin}
          onChangeText={text => {
            const trimmedText = text.substring(0, 17).toUpperCase();
            setVin(trimmedText);
            if (errors.atLeastOneField) {
              setErrors({...errors, atLeastOneField: false});
            }
            if (errors.vinLength && trimmedText.length === 17) {
              setErrors({...errors, vinLength: false});
            }
          }}
          autoCapitalize="characters"
          maxLength={17}
        />
        {errors.vinLength && (
          <Text style={styles.errorText}>
            VIN must be exactly 17 characters long
          </Text>
        )}

        <Text style={styles.label}>Stock Number</Text>
        <TextInput
          style={[styles.input, showAtLeastOneFieldError && styles.inputError]}
          placeholder="Enter Stock Number"
          placeholderTextColor={PLACEHOLDER_COLOR}
          value={stockNumber}
          onChangeText={text => {
            setStockNumber(text);
            if (errors.atLeastOneField) {
              setErrors({...errors, atLeastOneField: false});
            }
          }}
        />

        <Text style={styles.label}>Registration Number</Text>
        <TextInput
          style={[styles.input, showAtLeastOneFieldError && styles.inputError]}
          placeholder="Enter Registration Number"
          placeholderTextColor={PLACEHOLDER_COLOR}
          value={registrationNumber}
          onChangeText={text => {
            setRegistrationNumber(text);
            if (errors.atLeastOneField) {
              setErrors({...errors, atLeastOneField: false});
            }
          }}
          autoCapitalize="characters"
        />
        {showAtLeastOneFieldError && (
          <Text style={styles.errorText}>
            At least one of VIN, Stock Number, or Registration Number is
            required
          </Text>
        )}

        <View style={styles.buttonContainer}>
          <Button title="Start Shoot" onPress={handleStartShoot} />
        </View>
      </View>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flexGrow: 1,
    justifyContent: 'center',
    padding: 20,
    backgroundColor: '#f5f5f5',
  },
  formContainer: {
    backgroundColor: '#ffffff',
    borderRadius: 10,
    padding: 20,
    shadowColor: '#000',
    shadowOffset: {
      width: 0,
      height: 2,
    },
    shadowOpacity: 0.1,
    shadowRadius: 3.84,
    elevation: 5,
  },
  title: {
    fontSize: 22,
    fontWeight: '700',
    color: '#111',
    marginBottom: 4,
  },
  subtitle: {
    fontSize: 14,
    color: '#666',
    marginBottom: 16,
  },
  labelContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8,
    marginTop: 16,
  },
  label: {
    fontSize: 16,
    fontWeight: '600',
    color: '#333',
    marginTop: 16,
    marginBottom: 8,
  },
  generateButton: {
    color: '#007AFF',
    fontSize: 14,
    fontWeight: '500',
  },
  input: {
    borderWidth: 1,
    borderColor: '#ddd',
    borderRadius: 8,
    padding: 12,
    fontSize: 16,
    color: TEXT_COLOR,
    backgroundColor: '#fff',
    marginBottom: 4,
  },
  inputError: {
    borderColor: '#ff0000',
    borderWidth: 1.5,
  },
  required: {
    color: '#ff0000',
  },
  errorText: {
    color: '#ff0000',
    fontSize: 12,
    marginTop: -4,
    marginBottom: 8,
  },
  buttonContainer: {
    marginTop: 24,
    marginBottom: 8,
  },
});

export default App;
