import { MaterialIcons } from '@expo/vector-icons';
import { useFocusEffect, useRouter } from 'expo-router';
import React, { useCallback, useMemo, useState } from 'react';
import { Pressable, ScrollView, Text, View } from 'react-native';
import { EmptyState } from '../../src/components/EmptyState';
import { NoteCard } from '../../src/components/NoteCard';
import { createNote, getAllNotes } from '../../src/db/database';
import { useTheme } from '../../src/theme/ThemeProvider';
import { Note } from '../../src/types/models';

export default function HomeScreen() {
  const { theme } = useTheme();
  const router = useRouter();
  const [notes, setNotes] = useState<Note[]>([]);
  const [loading, setLoading] = useState(true);

  const loadNotes = useCallback(async () => {
    try {
      const data = await getAllNotes();
      setNotes(data);
    } finally {
      setLoading(false);
    }
  }, []);

  useFocusEffect(
    useCallback(() => {
      setLoading(true);
      loadNotes();
    }, [loadNotes])
  );

  const pinned = useMemo(() => notes.filter((n) => n.isPinned), [notes]);
  const recent = useMemo(() => notes.filter((n) => !n.isPinned), [notes]);

  return (
    <View style={{ flex: 1, backgroundColor: theme.background }}>
      <ScrollView contentContainerStyle={{ padding: 16, paddingBottom: 110 }}>
        <View style={{ flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
          <Text style={{ color: theme.text, fontSize: 28, fontWeight: '800' }}>PRnote</Text>
          <View style={{ backgroundColor: 'rgba(255,193,7,0.2)', paddingHorizontal: 10, paddingVertical: 5, borderRadius: 14 }}>
            <Text style={{ color: theme.primary, fontWeight: '600' }}>
              {new Date().toLocaleDateString(undefined, { month: 'short', day: 'numeric' })}
            </Text>
          </View>
        </View>

        {loading ? (
          <Text style={{ color: theme.muted }}>Loading...</Text>
        ) : notes.length === 0 ? (
          <EmptyState />
        ) : (
          <>
            {pinned.length > 0 ? (
              <>
                <Text style={{ color: theme.primary, fontSize: 11, letterSpacing: 1.5, fontWeight: '700', marginBottom: 10 }}>
                  PINNED
                </Text>
                {pinned.map((n) => (
                  <NoteCard key={n.id} note={n} onPress={() => router.push(`/editor/${n.id}`)} />
                ))}
                <View style={{ height: 10 }} />
              </>
            ) : null}

            {recent.length > 0 ? (
              <>
                <Text style={{ color: theme.muted, fontSize: 11, letterSpacing: 1.5, fontWeight: '700', marginBottom: 10 }}>
                  RECENT
                </Text>
                {recent.map((n) => (
                  <NoteCard key={n.id} note={n} onPress={() => router.push(`/editor/${n.id}`)} />
                ))}
              </>
            ) : null}
          </>
        )}
      </ScrollView>

      <Pressable
        onPress={async () => {
          const note = await createNote();
          router.push(`/editor/${note.id}`);
        }}
        style={{
          position: 'absolute',
          right: 20,
          bottom: 26,
          width: 56,
          height: 56,
          borderRadius: 18,
          backgroundColor: theme.primary,
          alignItems: 'center',
          justifyContent: 'center',
        }}
      >
        <MaterialIcons name="add" size={30} color="#111" />
      </Pressable>
    </View>
  );
}
