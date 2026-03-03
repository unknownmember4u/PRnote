import { ThemeMode } from '../types/models';

export type AppTheme = {
  mode: ThemeMode;
  background: string;
  surface: string;
  card: string;
  text: string;
  muted: string;
  divider: string;
  primary: string;
  danger: string;
};

export const getTheme = (mode: ThemeMode): AppTheme => {
  if (mode === 'light') {
    return {
      mode,
      background: '#F8F9FA',
      surface: '#FFFFFF',
      card: '#FFFFFF',
      text: '#1A1A2E',
      muted: '#6B7280',
      divider: '#E5E7EB',
      primary: '#FFC107',
      danger: '#EF4444',
    };
  }

  if (mode === 'amoled') {
    return {
      mode,
      background: '#000000',
      surface: '#0A0A0A',
      card: '#111111',
      text: '#FFFFFF',
      muted: '#AAAAAA',
      divider: '#222222',
      primary: '#FFC107',
      danger: '#EF4444',
    };
  }

  return {
    mode,
    background: '#1A1A2E',
    surface: '#232340',
    card: '#2A2A4A',
    text: '#F1F1F1',
    muted: '#9CA3AF',
    divider: '#374151',
    primary: '#FFC107',
    danger: '#EF4444',
  };
};
