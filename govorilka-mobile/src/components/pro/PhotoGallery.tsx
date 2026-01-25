import React from 'react';
import { View, Image, StyleSheet, ScrollView, Dimensions } from 'react-native';
import { colors } from '../../theme/colors';

interface PhotoGalleryProps {
  photos: string[];
}

const PHOTO_SIZE = Dimensions.get('window').width * 0.6;

export function PhotoGallery({ photos }: PhotoGalleryProps) {
  if (photos.length === 0) return null;

  return (
    <View style={styles.container}>
      <ScrollView
        horizontal
        showsHorizontalScrollIndicator={false}
        contentContainerStyle={styles.scrollContent}
        pagingEnabled={false}
        snapToInterval={PHOTO_SIZE + 12}
        decelerationRate="fast"
      >
        {photos.map((uri, index) => (
          <Image
            key={index}
            source={{ uri }}
            style={styles.photo}
            resizeMode="cover"
          />
        ))}
      </ScrollView>
      {photos.length > 1 && (
        <View style={styles.dots}>
          {photos.map((_, index) => (
            <View key={index} style={styles.dot} />
          ))}
        </View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    marginVertical: 12,
  },
  scrollContent: {
    paddingHorizontal: 4,
    gap: 12,
  },
  photo: {
    width: PHOTO_SIZE,
    height: PHOTO_SIZE * 0.75,
    borderRadius: 12,
    backgroundColor: colors.softPink,
  },
  dots: {
    flexDirection: 'row',
    justifyContent: 'center',
    marginTop: 8,
    gap: 6,
  },
  dot: {
    width: 6,
    height: 6,
    borderRadius: 3,
    backgroundColor: colors.lightPink,
  },
});
