# EcoSched - IoT-Enabled Smart Waste Collection App

EcoSched is a comprehensive mobile application for smart waste collection scheduling and community notifications, built with Flutter and Supabase.

## Features Implemented

### ✅ Core Infrastructure
- **Supabase Backend Integration** - Database, authentication, and real-time features
- **MQTT IoT Integration** - Real-time sensor data from waste bins
- **Multi-role Authentication** - Email/password and Google Sign-In
- **State Management** - Provider pattern for app state
- **Modern UI/UX** - Eco-themed design with Material 3

### ✅ User Management
- **Role-based Access** - Residents, Collectors, and Administrators
- **Profile Management** - User profiles with location and contact info
- **Authentication Flow** - Login, registration, password reset

### ✅ Resident Dashboard
- **Welcome Section** - Personalized greeting and quick stats
- **Quick Actions** - Easy access to key features
- **Nearby Bins** - Real-time bin status with fill levels
- **Collection Schedules** - Upcoming collection times
- **Community Announcements** - Latest news and updates

### ✅ Data Models & Repositories
- **Complete Data Models** - User, Bin, Schedule, Route, Notification, Announcement
- **Repository Pattern** - Clean data access layer
- **Real-time Updates** - Supabase streams for live data

## Architecture

```
lib/
├── core/                    # App configuration and constants
│   ├── config/             # Supabase and MQTT configuration
│   ├── constants/          # App constants and enums
│   └── theme/              # App theming
├── data/                   # Data layer
│   ├── models/             # Data models
│   ├── repositories/       # Data access layer
│   └── services/           # External services (MQTT, etc.)
├── features/               # Feature modules
│   ├── auth/               # Authentication
│   ├── dashboard/          # Role-based dashboards
│   ├── bins/               # Bin monitoring
│   ├── schedules/          # Collection scheduling
│   ├── routes/             # Route optimization
│   ├── notifications/      # Push notifications
│   ├── analytics/          # Analytics dashboard
│   └── community/          # Community features
└── widgets/                # Reusable components
```

## Technology Stack

- **Frontend**: Flutter 3.9.2+
- **Backend**: Supabase (PostgreSQL + Auth + Realtime)
- **IoT**: MQTT protocol for sensor communication
- **Maps**: Google Maps integration
- **Notifications**: Firebase Cloud Messaging
- **State Management**: Provider
- **Charts**: FL Chart for analytics

## Getting Started

### Prerequisites
- Flutter SDK 3.9.2 or higher
- Dart SDK
- Supabase account
- Firebase project (for notifications)
- Google Maps API key

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd ecosched
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure environment**
   - Update `lib/core/config/supabase_config.dart` with your Supabase credentials
   - Add your Google Maps API key
   - Configure Firebase for your project

4. **Set up Supabase database**
   Create the following tables in your Supabase project:
   - `users` - User profiles and roles
   - `bins` - Waste bin information and status
   - `collection_schedules` - Collection schedules by zone
   - `collection_routes` - Optimized collection routes
   - `notifications` - User notifications
   - `community_announcements` - Community announcements
   - `collection_reports` - Collection reports and analytics

5. **Run the app**
   ```bash
   flutter run
   ```

## Features in Development

### 🚧 Collector Dashboard
- Route optimization and navigation
- Collection tracking and reporting
- Real-time bin status updates

### 🚧 Admin Dashboard
- Analytics and reporting
- System management
- User management
- Schedule management

### 🚧 Advanced Features
- Interactive bin map with clustering
- Route optimization algorithms
- Push notifications
- Community issue reporting
- Analytics dashboard with charts

## Database Schema

The app uses the following main entities:

- **Users**: Authentication and profile data
- **Bins**: IoT sensor data and location information
- **Schedules**: Collection schedules by zone and day
- **Routes**: Optimized collection paths for collectors
- **Notifications**: Push and in-app notifications
- **Announcements**: Community news and updates
- **Reports**: Collection data and analytics

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions, please open an issue in the repository or contact the development team.

---

**EcoSched** - Making waste collection smarter and more efficient through IoT technology.