import { Stack } from 'expo-router';
import React, { useEffect, useState } from 'react';
import { StatusBar } from 'expo-status-bar';
import { ActivityIndicator, View } from 'react-native';
import { initDatabase } from '../src/db/database';
import { ThemeProvider, useTheme } from '../src/theme/ThemeProvider';

function RootNavigator() {
  const { theme, ready } = useTheme();
  const [dbReady, setDbReady] = useState(false);

  useEffect(() => {
    initDatabase()
      .catch(() => {
        // keep app booting even if db init fails; screens handle retry paths.
      })
      .finally(() => setDbReady(true));
  }, []);

  if (!ready || !dbReady) {
    return (
      <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center', backgroundColor: '#1A1A2E' }}>
        <ActivityIndicator color="#FFC107" />
      </View>
    );
  }

  return (
    <>
      <StatusBar style={theme.mode === 'light' ? 'dark' : 'light'} />
      <Stack screenOptions={{ headerShown: false, contentStyle: { backgroundColor: theme.background } }}>
        <Stack.Screen name="index" />
        <Stack.Screen name="(tabs)" />
        <Stack.Screen name="editor/new" />
        <Stack.Screen name="editor/[noteId]" />
      </Stack>
    </>
  );
}

export default function RootLayout() {
  return (
    <ThemeProvider>
      <RootNavigator />
    </ThemeProvider>
  );
}
