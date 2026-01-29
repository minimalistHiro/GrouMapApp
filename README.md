# GrouMap - Monorepo

GrouMap is a location-based social app with rotating QR tokens for user check-ins.

## 日本語での解説

- 「店舗用」と言われた場合は `/Users/kanekohiroki/Desktop/groumapapp_store` を対象プロジェクトとする。
- 「ユーザー用」と言われた場合は `/Users/kanekohiroki/Desktop/groumapapp` を対象プロジェクトとする。

## Project Structure

```
groumapapp/
├── apps/
│   ├── user_app/          # Flutter user app
│   └── store_app/         # Flutter store app (future)
├── backend/
│   └── functions/         # Firebase Functions (TypeScript)
├── lib/                   # Current Flutter app code
├── android/               # Android platform files
├── ios/                   # iOS platform files
├── web/                   # Web platform files
└── README.md
```

## Features

- **JWT-based QR Tokens**: Secure 60-second TTL tokens with replay prevention
- **Real-time Updates**: Live countdown timer for token expiration
- **Firebase Integration**: Auth, Firestore, Functions, Storage, App Check
- **Cross-platform**: Flutter for iOS, Android, and Web
- **Timezone Support**: Asia/Tokyo with 5-second clock skew tolerance
- **Security**: JWT signing, rate limiting, role-based access control
- **Replay Prevention**: JTI-based token consumption tracking

## Setup Instructions

### Prerequisites

- Flutter SDK (stable channel, Dart >=3.0)
- Node.js 18+
- Firebase CLI
- pnpm (for functions)

### 1. Flutter App Setup

```bash
# Install dependencies
flutter pub get

# Run on web
flutter run -d chrome

# Run on mobile
flutter run
```

### 2. Firebase Functions Setup

```bash
# Navigate to functions directory
cd backend/functions

# Install dependencies
pnpm install

# Copy environment variables
cp env.example .env
# Edit .env with your JWT secret and other settings

# Build TypeScript
pnpm run build

# Run tests
pnpm test

# Deploy functions
pnpm run deploy
```

### 3. Environment Configuration

Create `.env` file in `backend/functions/`:

```env
QR_SECRET_KEY=your_secret_key_here
```

### 4. Firebase Project Setup

1. Enable Firebase Functions
2. Enable Firestore
3. Enable Authentication
4. Configure App Check (optional)
5. Set up Cloud Storage (optional)

## JWT-based QR Token System

### How it Works

1. **Token Issuance**: `issueQrToken` function creates JWT with user ID, expiration, and JTI
2. **60-second TTL**: Tokens automatically expire every 60 seconds
3. **Clock Skew Tolerance**: 5-second tolerance for network delays
4. **Server Validation**: `verifyQrToken` function validates JWT signature and claims
5. **Replay Prevention**: JTI-based token consumption tracking in Firestore

### Security Features

- JWT signing with HS256 algorithm
- Time-based expiration (iat/exp claims)
- Replay prevention via JTI consumption
- Role-based access control (store/company roles)
- Rate limiting per IP/UID
- App Check enforcement
- Device binding (optional)

## API Endpoints

### `issueQrToken` (Callable)

**Region**: asia-northeast1  
**Authentication**: Required (user)  
**App Check**: Required

**Request Data**:
```json
{
  "deviceId": "optional-device-id"
}
```

**Response**:
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expiresAt": 1703123456789,
  "jti": "abc123def456789"
}
```

### `verifyQrToken` (Callable)

**Region**: asia-northeast1  
**Authentication**: Required (store role)  
**App Check**: Required

**Request Data**:
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "storeId": "store123"
}
```

**Response**:
```json
{
  "uid": "user123",
  "status": "OK",
  "jti": "abc123def456789"
}
```

## Development

### Running Locally

```bash
# Start Firebase emulators
firebase emulators:start

# Run Flutter app
flutter run -d chrome
```

### Code Generation

```bash
# Generate models
flutter packages pub run build_runner build

# Watch for changes
flutter packages pub run build_runner watch
```

## Dependencies

### Flutter App
- `flutter_riverpod`: State management
- `firebase_*`: Firebase services
- `qr_flutter`: QR code generation
- `mobile_scanner`: QR code scanning
- `crypto`: Token hashing

### Firebase Functions
- `firebase-functions`: Cloud Functions
- `firebase-admin`: Admin SDK
- `crypto`: Node.js crypto module

## Deployment

### Flutter Web
```bash
flutter build web
firebase deploy --only hosting
```

### Firebase Functions
```bash
cd backend/functions
pnpm run deploy
```

## Security Considerations

1. **Secret Key Management**: Store QR secret in environment variables
2. **Token Validation**: Always validate tokens server-side
3. **Rate Limiting**: Implement rate limiting for check-ins
4. **App Check**: Enable Firebase App Check for production

## Troubleshooting

### Common Issues

1. **Token Validation Fails**: Check clock synchronization
2. **Functions Timeout**: Increase timeout in function configuration
3. **CORS Errors**: Verify Firebase hosting headers configuration

### Debug Mode

Enable debug logging in `QRTokenService`:

```dart
// Add debug prints
print('Generated token: $token');
print('Remaining seconds: $remainingSeconds');
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests and linting
5. Submit a pull request

## License

This project is licensed under the MIT License.
