import React, { createContext, useContext, useEffect, useMemo, useState } from 'react';
import { getThemeMode, setThemeMode } from '../db/database';
import { ThemeMode } from '../types/models';
import { AppTheme, getTheme } from './theme';

type ThemeContextValue = {
  theme: AppTheme;
  mode: ThemeMode;
  setMode: (mode: ThemeMode) => Promise<void>;
  ready: boolean;
};

const ThemeContext = createContext<ThemeContextValue | null>(null);

export function ThemeProvider({ children }: { children: React.ReactNode }) {
  const [mode, setModeState] = useState<ThemeMode>('dark');
  const [ready, setReady] = useState(false);

  useEffect(() => {
    (async () => {
      const saved = await getThemeMode();
      setModeState(saved);
      setReady(true);
    })();
  }, []);

  const value = useMemo<ThemeContextValue>(
    () => ({
      theme: getTheme(mode),
      mode,
      ready,
      setMode: async (next: ThemeMode) => {
        setModeState(next);
        await setThemeMode(next);
      },
    }),
    [mode, ready]
  );

  return <ThemeContext.Provider value={value}>{children}</ThemeContext.Provider>;
}

export function useTheme() {
  const ctx = useContext(ThemeContext);
  if (!ctx) {
    throw new Error('useTheme must be used within ThemeProvider');
  }
  return ctx;
}
