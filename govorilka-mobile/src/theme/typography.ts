import { TextStyle } from 'react-native';

export const typography: Record<string, TextStyle> = {
  header: {
    fontSize: 18,
    fontWeight: '600',
  },
  subheader: {
    fontSize: 16,
    fontWeight: '600',
  },
  body: {
    fontSize: 15,
    fontWeight: '400',
  },
  caption: {
    fontSize: 13,
    fontWeight: '400',
  },
  hint: {
    fontSize: 11,
    fontWeight: '400',
  },
  mono: {
    fontSize: 14,
    fontFamily: 'Courier',
  },
};
