import { MaterialIcons } from '@expo/vector-icons';
import { useFocusEffect } from 'expo-router';
import React, { useCallback, useState } from 'react';
import { Pressable, ScrollView, Text, TextInput, View } from 'react-native';
import { createFolder, deleteFolder, getAllFolders, getFolderNoteCount, renameFolder } from '../../src/db/database';
import { useTheme } from '../../src/theme/ThemeProvider';
import { Folder } from '../../src/types/models';

export default function FoldersScreen() {
  const { theme } = useTheme();
  const [folders, setFolders] = useState<Folder[]>([]);
  const [counts, setCounts] = useState<Record<string, number>>({});
  const [newName, setNewName] = useState('');
  const [renameFolderId, setRenameFolderId] = useState<string | null>(null);

  const load = useCallback(async () => {
    const data = await getAllFolders();
    setFolders(data);
    const entries = await Promise.all(data.map(async (f) => [f.id, await getFolderNoteCount(f.id)] as const));
    setCounts(Object.fromEntries(entries));
  }, []);

  useFocusEffect(
    useCallback(() => {
      load();
    }, [load])
  );

  return (
    <View style={{ flex: 1, backgroundColor: theme.background, padding: 16 }}>
      <Text style={{ color: theme.text, fontSize: 28, fontWeight: '700', marginBottom: 14 }}>Folders</Text>

      <View style={{ flexDirection: 'row', gap: 8, marginBottom: 16 }}>
        <TextInput
          value={newName}
          onChangeText={setNewName}
          placeholder="New folder name"
          placeholderTextColor={theme.muted}
          style={{
            flex: 1,
            backgroundColor: theme.surface,
            color: theme.text,
            borderWidth: 1,
            borderColor: theme.divider,
            borderRadius: 12,
            paddingHorizontal: 12,
            paddingVertical: 10,
          }}
        />
        <Pressable
          onPress={async () => {
            if (!newName.trim()) return;
            if (renameFolderId) {
              await renameFolder(renameFolderId, newName.trim());
              setRenameFolderId(null);
            } else {
              await createFolder(newName.trim());
            }
            setNewName('');
            await load();
          }}
          style={{ backgroundColor: theme.primary, borderRadius: 12, paddingHorizontal: 14, justifyContent: 'center' }}
        >
          <MaterialIcons name={renameFolderId ? 'check' : 'create-new-folder'} size={22} color="#111" />
        </Pressable>
      </View>

      <ScrollView contentContainerStyle={{ paddingBottom: 100 }}>
        {folders.map((f) => (
          <View
            key={f.id}
            style={{
              backgroundColor: theme.card,
              borderWidth: 1,
              borderColor: theme.divider,
              borderRadius: 14,
              padding: 14,
              marginBottom: 10,
            }}
          >
            <Text style={{ color: theme.text, fontWeight: '700', fontSize: 16 }}>{f.name}</Text>
            <Text style={{ color: theme.muted, marginTop: 3 }}>{counts[f.id] ?? 0} notes</Text>
            {f.id !== 'default' ? (
              <View style={{ flexDirection: 'row', gap: 10, marginTop: 10 }}>
                <Pressable
                  onPress={() => {
                    setRenameFolderId(f.id);
                    setNewName(f.name);
                  }}
                >
                  <Text style={{ color: theme.primary }}>Rename</Text>
                </Pressable>
                <Pressable
                  onPress={async () => {
                    await deleteFolder(f.id);
                    await load();
                  }}
                >
                  <Text style={{ color: theme.danger }}>Delete</Text>
                </Pressable>
              </View>
            ) : null}
          </View>
        ))}
      </ScrollView>
    </View>
  );
}
