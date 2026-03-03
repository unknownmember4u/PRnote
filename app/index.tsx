import React, { useEffect } from 'react';
import { Image, Text, View } from 'react-native';
import { useRouter } from 'expo-router';
import { getLastEditedNoteId } from '../src/db/database';

export default function SplashRoute() {
  const router = useRouter();

  useEffect(() => {
    let cancelled = false;
    const run = async () => {
      try {
        await new Promise((r) => setTimeout(r, 1600));
        const lastId = await getLastEditedNoteId();
        if (cancelled) return;
        if (lastId) {
          router.replace(`/editor/${lastId}`);
        } else {
          router.replace('/(tabs)/home');
        }
      } catch {
        if (!cancelled) {
          router.replace('/(tabs)/home');
        }
      }
    };
    run();
    return () => {
      cancelled = true;
    };
  }, [router]);

  return (
    <View style={{ flex: 1, backgroundColor: '#1A1A2E', alignItems: 'center', justifyContent: 'center' }}>
      <Image source={require('../assets/images/splash_logo.png')} style={{ width: 120, height: 120, borderRadius: 28 }} />
      <Text style={{ marginTop: 24, color: '#FFC107', fontSize: 36, fontWeight: '800' }}>PR</Text>
      <Text style={{ marginTop: -4, color: '#FFFFFFCC', fontSize: 36, fontWeight: '300' }}>note</Text>
      <Text style={{ marginTop: 8, color: '#FFFFFF77', letterSpacing: 1.5 }}>Your notes, your way</Text>
    </View>
  );
}
