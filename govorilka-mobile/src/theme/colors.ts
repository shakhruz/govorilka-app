export const colors = {
  pink: '#FF69B4',
  lightPink: '#FFB6C1',
  softPink: '#FFF0F5',
  textColor: '#5D4E6D',
  backgroundTop: '#FFF5F8',
  backgroundBottom: '#FFE4EC',
  white: '#FFFFFF',
  cloudLight: '#FFD1DC',
  cloudDark: '#FFB6C1',
  blush: '#FF8FAB',
  eye: '#6B5B7A',
  danger: '#FF4444',
  success: '#4CAF50',
  gray: '#999999',
  lightGray: '#F5F5F5',
} as const;

export type ColorName = keyof typeof colors;
