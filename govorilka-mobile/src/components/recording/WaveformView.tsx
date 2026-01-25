import React, { useEffect } from 'react';
import { View, StyleSheet } from 'react-native';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withTiming,
  withRepeat,
  withDelay,
  withSequence,
  Easing,
} from 'react-native-reanimated';
import { colors } from '../../theme/colors';

interface WaveformViewProps {
  isRecording: boolean;
  audioLevel: number;
}

const RING_COUNT = 3;

export function WaveformView({ isRecording, audioLevel }: WaveformViewProps) {
  const rings = Array.from({ length: RING_COUNT }, (_, i) => i);

  return (
    <View style={styles.container}>
      {rings.map((index) => (
        <WaveRing
          key={index}
          index={index}
          isRecording={isRecording}
          audioLevel={audioLevel}
        />
      ))}
    </View>
  );
}

function WaveRing({
  index,
  isRecording,
  audioLevel,
}: {
  index: number;
  isRecording: boolean;
  audioLevel: number;
}) {
  const scale = useSharedValue(1);
  const opacity = useSharedValue(0);

  useEffect(() => {
    if (isRecording) {
      const baseScale = 1.2 + index * 0.3 + audioLevel * 0.5;
      scale.value = withRepeat(
        withDelay(
          index * 200,
          withSequence(
            withTiming(baseScale, {
              duration: 1000,
              easing: Easing.inOut(Easing.ease),
            }),
            withTiming(1, {
              duration: 1000,
              easing: Easing.inOut(Easing.ease),
            })
          )
        ),
        -1,
        true
      );
      opacity.value = withDelay(
        index * 200,
        withTiming(0.3 - index * 0.08, { duration: 300 })
      );
    } else {
      scale.value = withTiming(1, { duration: 300 });
      opacity.value = withTiming(0, { duration: 300 });
    }
  }, [isRecording, audioLevel, index, scale, opacity]);

  const animatedStyle = useAnimatedStyle(() => ({
    transform: [{ scale: scale.value }],
    opacity: opacity.value,
  }));

  const size = 120 + index * 40;

  return (
    <Animated.View
      style={[
        styles.ring,
        {
          width: size,
          height: size,
          borderRadius: size / 2,
        },
        animatedStyle,
      ]}
    />
  );
}

const styles = StyleSheet.create({
  container: {
    width: 240,
    height: 240,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 20,
  },
  ring: {
    position: 'absolute',
    borderWidth: 2,
    borderColor: colors.lightPink,
    backgroundColor: 'rgba(255, 182, 193, 0.1)',
  },
});
