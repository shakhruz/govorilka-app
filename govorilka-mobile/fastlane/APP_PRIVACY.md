# App Privacy Information for App Store Connect

## Data Collection Summary

Govorilka collects minimal data and prioritizes user privacy.

---

## Data Types Collected

### 1. Audio Data
- **Collected**: Yes (temporarily)
- **Purpose**: App Functionality (speech-to-text transcription)
- **Linked to User**: No
- **Tracking**: No
- **Details**: Audio is streamed to Deepgram API for transcription and is NOT stored permanently

### 2. Photos (Pro Mode only)
- **Collected**: Yes (with user action)
- **Purpose**: App Functionality (context for transcription)
- **Linked to User**: No
- **Tracking**: No
- **Details**: Photos are processed locally or sent to AI API, not stored on servers

---

## Data NOT Collected

- ❌ Contact Info (name, email, phone)
- ❌ Health & Fitness
- ❌ Financial Info
- ❌ Location
- ❌ Contacts
- ❌ Browsing History
- ❌ Search History
- ❌ Identifiers (User ID, Device ID)
- ❌ Purchases
- ❌ Usage Data (NOT sent to our servers)
- ❌ Diagnostics

---

## Third-Party Services

### Deepgram API
- **Purpose**: Speech-to-text transcription
- **Data Sent**: Audio stream
- **Data Retained**: According to Deepgram's privacy policy (audio not stored by default)
- **Privacy Policy**: https://deepgram.com/privacy

### User's API Key
- The app uses the USER'S OWN Deepgram API key
- No data goes through Govorilka servers
- Direct connection: User's device → Deepgram

---

## App Store Connect Answers

When filling out App Privacy in App Store Connect:

### "Does your app collect data?"
**Yes** - but only for app functionality

### Data Types to Select:
1. **Audio Data**
   - Used for: App Functionality
   - Linked to User: No
   - Used for Tracking: No

### "Does your app use data for tracking?"
**No**

### "Does your app link collected data to user identity?"
**No**

---

## Privacy Nutrition Label Result

Your app's privacy label should show:
- **Data Not Linked to You**: Audio Data
- **Data Not Collected**: Everything else

This is the most privacy-friendly label possible for a voice transcription app.
