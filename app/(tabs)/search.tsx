import { useRouter } from 'expo-router';
import React, { useEffect, useState } from 'react';
import { ScrollView, Text, TextInput, View } from 'react-native';
import { NoteCard } from '../../src/components/NoteCard';
import { searchNotes } from '../../src/db/database';
import { useTheme } from '../../src/theme/ThemeProvider';
import { Note } from '../../src/types/models';

export default function SearchScreen() {
  const { theme } = useTheme();
  const router = useRouter();
  const [query, setQuery] = useState('');
  const [results, setResults] = useState<Note[]>([]);

  useEffect(() => {
    const id = setTimeout(async () => {
      if (!query.trim()) {
        setResults([]);
        return;
      }
      const data = await searchNotes(query.trim());
      setResults(data);
    }, 180);

    return () => clearTimeout(id);
  }, [query]);

  return (
    <View style={{ flex: 1, backgroundColor: theme.background, padding: 16 }}>
      <Text style={{ color: theme.text, fontSize: 28, fontWeight: '700', marginBottom: 14 }}>Search</Text>
      <TextInput
        value={query}
        onChangeText={setQuery}
        placeholder="Search notes..."
        placeholderTextColor={theme.muted}
        style={{
          backgroundColor: theme.surface,
          color: theme.text,
          borderRadius: 14,
          borderWidth: 1,
          borderColor: theme.divider,
          paddingHorizontal: 14,
          paddingVertical: 12,
          marginBottom: 14,
        }}
      />

      <ScrollView contentContainerStyle={{ paddingBottom: 100 }}>
        {!query.trim() ? (
          <Text style={{ color: theme.muted }}>Find notes by title or content.</Text>
        ) : results.length === 0 ? (
          <Text style={{ color: theme.muted }}>No results found.</Text>
        ) : (
          results.map((n) => <NoteCard key={n.id} note={n} onPress={() => router.push(`/editor/${n.id}`)} />)
        )}
      </ScrollView>
    </View>
  );
}
