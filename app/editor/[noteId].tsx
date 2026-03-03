import { MaterialIcons } from '@expo/vector-icons';
import { useLocalSearchParams, useRouter } from 'expo-router';
import React, { useEffect, useRef, useState } from 'react';
import { Alert, Pressable, ScrollView, Text, TextInput, View } from 'react-native';
import {
  createNote,
  deleteNote,
  getNoteById,
  setLastEditedNoteId,
  toggleFavorite,
  togglePin,
  updateNote,
} from '../../src/db/database';
import { useTheme } from '../../src/theme/ThemeProvider';
import { Note } from '../../src/types/models';

export default function EditorScreen() {
  const { theme } = useTheme();
  const { noteId } = useLocalSearchParams<{ noteId: string }>();
  const router = useRouter();
  const saveTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  const [note, setNote] = useState<Note | null>(null);
  const [title, setTitle] = useState('');
  const [content, setContent] = useState('');
  const [loading, setLoading] = useState(true);
  const [dirty, setDirty] = useState(false);

  useEffect(() => {
    let mounted = true;

    const load = async () => {
      try {
        let target: Note | null = null;
        if (noteId === 'new') {
          target = await createNote();
          router.replace(`/editor/${target.id}`);
          return;
        }

        target = await getNoteById(noteId);
        if (!mounted) return;

        if (!target) {
          router.replace('/(tabs)/home');
          return;
        }

        setNote(target);
        setTitle(target.title);
        setContent(target.content);
        await setLastEditedNoteId(target.id);
      } finally {
        if (mounted) setLoading(false);
      }
    };

    load();

    return () => {
      mounted = false;
      if (saveTimerRef.current) clearTimeout(saveTimerRef.current);
    };
  }, [noteId, router]);

  useEffect(() => {
    if (!note || !dirty) return;

    if (saveTimerRef.current) clearTimeout(saveTimerRef.current);
    saveTimerRef.current = setTimeout(async () => {
      const updated: Note = { ...note, title, content };
      await updateNote(updated);
      const fresh = await getNoteById(note.id);
      if (fresh) setNote(fresh);
      setDirty(false);
    }, 800);

    return () => {
      if (saveTimerRef.current) clearTimeout(saveTimerRef.current);
    };
  }, [title, content, dirty, note]);

  const saveAndBack = async () => {
    if (saveTimerRef.current) clearTimeout(saveTimerRef.current);
    if (note && dirty) {
      await updateNote({ ...note, title, content });
    }
    router.replace('/(tabs)/home');
  };

  if (loading) {
    return (
      <View style={{ flex: 1, backgroundColor: theme.background, alignItems: 'center', justifyContent: 'center' }}>
        <Text style={{ color: theme.muted }}>Loading...</Text>
      </View>
    );
  }

  return (
    <View style={{ flex: 1, backgroundColor: theme.background }}>
      <View
        style={{
          height: 56,
          paddingHorizontal: 8,
          flexDirection: 'row',
          alignItems: 'center',
          borderBottomWidth: 1,
          borderBottomColor: theme.divider,
          backgroundColor: theme.background,
        }}
      >
        <Pressable onPress={saveAndBack} style={{ padding: 8 }}>
          <MaterialIcons name="arrow-back-ios-new" size={20} color={theme.text} />
        </Pressable>

        <View style={{ flex: 1 }} />

        {dirty ? <View style={{ width: 6, height: 6, borderRadius: 3, backgroundColor: '#FFC107', marginRight: 10 }} /> : null}

        <Pressable
          onPress={async () => {
            if (!note) return;
            await togglePin(note);
            const fresh = await getNoteById(note.id);
            if (fresh) setNote(fresh);
          }}
          style={{ padding: 8 }}
        >
          <MaterialIcons name="push-pin" size={22} color={note?.isPinned ? theme.primary : theme.muted} />
        </Pressable>

        <Pressable
          onPress={async () => {
            if (!note) return;
            await toggleFavorite(note);
            const fresh = await getNoteById(note.id);
            if (fresh) setNote(fresh);
          }}
          style={{ padding: 8 }}
        >
          <MaterialIcons name={note?.isFavorite ? 'favorite' : 'favorite-border'} size={22} color={note?.isFavorite ? '#EF4444' : theme.muted} />
        </Pressable>

        <Pressable
          onPress={() => {
            Alert.alert('Actions', 'Choose an action', [
              { text: 'Cancel', style: 'cancel' },
              {
                text: 'Move to trash',
                style: 'destructive',
                onPress: async () => {
                  if (!note) return;
                  await deleteNote(note.id);
                  router.replace('/(tabs)/home');
                },
              },
            ]);
          }}
          style={{ padding: 8 }}
        >
          <MaterialIcons name="more-vert" size={22} color={theme.muted} />
        </Pressable>
      </View>

      <ScrollView contentContainerStyle={{ padding: 20, paddingBottom: 120 }} keyboardShouldPersistTaps="handled">
        <TextInput
          value={title}
          onChangeText={(v) => {
            setTitle(v);
            setDirty(true);
          }}
          placeholder="Title"
          placeholderTextColor={theme.muted}
          multiline
          style={{ color: theme.text, fontSize: 28, fontWeight: '700' }}
        />

        {note ? (
          <Text style={{ color: theme.muted, fontSize: 12, marginTop: 4, marginBottom: 14 }}>
            {new Date(note.updatedAt).toLocaleString()}
          </Text>
        ) : null}

        <TextInput
          value={content}
          onChangeText={(v) => {
            setContent(v);
            setDirty(true);
          }}
          placeholder="Start writing..."
          placeholderTextColor={theme.muted}
          multiline
          textAlignVertical="top"
          style={{ color: theme.text, fontSize: 16, lineHeight: 24, minHeight: 240 }}
        />
      </ScrollView>
    </View>
  );
}
