import { MaterialIcons } from '@expo/vector-icons';
import React from 'react';
import { Text, View } from 'react-native';
import { useTheme } from '../theme/ThemeProvider';

export function EmptyState() {
  const { theme } = useTheme();

  return (
    <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center', padding: 32 }}>
      <View
        style={{
          width: 80,
          height: 80,
          borderRadius: 40,
          backgroundColor: 'rgba(255,193,7,0.15)',
          alignItems: 'center',
          justifyContent: 'center',
        }}
      >
        <MaterialIcons name="note-add" size={36} color={theme.primary} />
      </View>
      <Text style={{ color: theme.text, fontSize: 22, fontWeight: '700', marginTop: 20 }}>No notes yet</Text>
      <Text style={{ color: theme.muted, fontSize: 14, marginTop: 8 }}>Tap + to create your first note</Text>
    </View>
  );
}
