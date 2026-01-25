import { Stack } from 'expo-router';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import { StyleSheet } from 'react-native';

export default function RootLayout() {
  return (
    <GestureHandlerRootView style={styles.container}>
      <Stack screenOptions={{ headerShown: false }}>
        <Stack.Screen name="(tabs)" />
        <Stack.Screen
          name="history/[id]"
          options={{
            headerShown: true,
            headerTitle: 'Запись',
            headerTintColor: '#FF69B4',
            headerStyle: { backgroundColor: '#FFF5F8' },
            presentation: 'card',
          }}
        />
        <Stack.Screen
          name="pro-review"
          options={{
            presentation: 'modal',
            headerShown: false,
          }}
        />
      </Stack>
    </GestureHandlerRootView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
});
