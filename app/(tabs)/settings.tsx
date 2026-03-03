import React from 'react';
import { Pressable, Text, View } from 'react-native';
import { useTheme } from '../../src/theme/ThemeProvider';
import { ThemeMode } from '../../src/types/models';

const modes: ThemeMode[] = ['light', 'dark', 'amoled'];

export default function SettingsScreen() {
  const { theme, mode, setMode } = useTheme();

  return (
    <View style={{ flex: 1, backgroundColor: theme.background, padding: 16 }}>
      <Text style={{ color: theme.text, fontSize: 28, fontWeight: '700', marginBottom: 16 }}>Settings</Text>
      <Text style={{ color: theme.muted, fontSize: 12, letterSpacing: 1.5, marginBottom: 8 }}>APPEARANCE</Text>

      <View style={{ backgroundColor: theme.surface, borderRadius: 14, borderWidth: 1, borderColor: theme.divider }}>
        {modes.map((m) => {
          const selected = mode === m;
          return (
            <Pressable
              key={m}
              onPress={() => setMode(m)}
              style={{
                paddingHorizontal: 14,
                paddingVertical: 14,
                borderBottomWidth: m === modes[modes.length - 1] ? 0 : 1,
                borderBottomColor: theme.divider,
                backgroundColor: selected ? 'rgba(255,193,7,0.15)' : 'transparent',
              }}
            >
              <Text style={{ color: selected ? theme.primary : theme.text, fontWeight: selected ? '700' : '500' }}>
                {m.toUpperCase()}
              </Text>
            </Pressable>
          );
        })}
      </View>

      <View style={{ marginTop: 24 }}>
        <Text style={{ color: theme.muted, fontSize: 12, letterSpacing: 1.5 }}>ABOUT</Text>
        <Text style={{ color: theme.text, marginTop: 8, fontSize: 14 }}>PRnote v1.0.0</Text>
        <Text style={{ color: theme.muted, marginTop: 4 }}>Offline-first note-taking app.</Text>
      </View>
    </View>
  );
}
