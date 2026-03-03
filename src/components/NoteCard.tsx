import { MaterialIcons } from '@expo/vector-icons';
import React from 'react';
import { Pressable, Text, View } from 'react-native';
import { Note } from '../types/models';
import { useTheme } from '../theme/ThemeProvider';

function formatTimeAgo(iso: string) {
  const updated = new Date(iso);
  const now = new Date();
  const ms = now.getTime() - updated.getTime();
  const mins = Math.floor(ms / 60000);
  if (mins < 1) return 'Just now';
  if (mins < 60) return `${mins}m ago`;
  const hours = Math.floor(mins / 60);
  if (hours < 24) return `${hours}h ago`;
  const days = Math.floor(hours / 24);
  if (days < 7) return `${days}d ago`;
  return updated.toLocaleDateString(undefined, { month: 'short', day: 'numeric' });
}

export function NoteCard({ note, onPress }: { note: Note; onPress: () => void }) {
  const { theme } = useTheme();
  const preview = note.content.length > 120 ? `${note.content.slice(0, 120)}...` : note.content;

  return (
    <Pressable
      onPress={onPress}
      style={{
        padding: 16,
        borderRadius: 16,
        borderWidth: 1,
        borderColor: `${theme.divider}`,
        backgroundColor: theme.card,
        marginBottom: 10,
      }}
    >
      <View style={{ flexDirection: 'row', alignItems: 'center' }}>
        <Text
          numberOfLines={1}
          style={{ flex: 1, color: note.title ? theme.text : theme.muted, fontWeight: '700', fontSize: 16 }}
        >
          {note.title || 'Untitled'}
        </Text>
        {note.isFavorite ? <MaterialIcons name="favorite" size={16} color="#EF4444" /> : null}
      </View>

      {preview ? (
        <Text numberOfLines={2} style={{ color: theme.muted, marginTop: 8, lineHeight: 20 }}>
          {preview}
        </Text>
      ) : null}

      <View style={{ marginTop: 10, flexDirection: 'row', alignItems: 'center' }}>
        <MaterialIcons name="access-time" size={13} color={theme.muted} />
        <Text style={{ marginLeft: 4, color: theme.muted, fontSize: 12 }}>{formatTimeAgo(note.updatedAt)}</Text>
        <View style={{ flex: 1 }} />
        {note.isPinned ? <MaterialIcons name="push-pin" size={14} color={theme.primary} /> : null}
      </View>
    </Pressable>
  );
}
