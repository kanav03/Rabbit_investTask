# Rabbit Invest - Mutual Fund Investment App

A beautiful and intuitive iOS app for comparing mutual fund NAV trends, built with SwiftUI using a professional black and green color scheme perfect for financial applications.

## 📱 Features

### Core Functionality
- **User Authentication**: Simple email/password login with form validation
- **Fund Discovery**: Search and filter from comprehensive mutual fund database  
- **Smart Selection**: Select 2-4 funds for detailed comparison
- **Interactive Charts**: Apple Stocks-style line charts with zoom and scroll
- **Favorites Feature**: Save up to 5 favorite funds with latest NAV display
- **Fund Analysis**: Detailed fund information cards with key metrics
- **Data Persistence**: Saves user preferences, selections, and favorites

### User Experience
- **Professional Design**: Black and green MFD-inspired color scheme
- **Smooth Navigation**: Fluid transitions between screens
- **Responsive UI**: Optimized for all iPhone screen sizes  
- **Advanced Search & Filter**: Multi-criteria filtering with visual tags
- **Real-time Data**: Live NAV data from MFApi.in
- **Smart Fund Management**: Selected funds appear at top for easy access

## 🚀 Quick Start

### Prerequisites
- **Xcode 15.0+**
- **iOS 17.0+**
- **Swift 5.9+**

### Installation

1. **Clone the Repository**
   ```bash
   git clone https://github.com/yourusername/rabbit-invest.git](https://github.com/kanav03/Rabbit_investTask.git)
   cd rabbit-invest
   ```

2. **Open in Xcode**
   ```bash
   open "Rabbit Invest.xcodeproj"
   ```

3. **Select Target Device**
   - Choose any iPhone simulator or device
   - Minimum deployment target: iOS 17.0

4. **Build and Run**
   - Press `Cmd + R` or click the play button
   - The app will launch in the simulator/device

### Demo Credentials
For demonstration purposes, any valid email format and password (6+ characters) will work.

Example:
- **Email**: `demo@example.com`
- **Password**: `password123`

## 📚 App Architecture

### Screen Flow
```
Login Screen → Fund Selection Screen → Comparison Screen
     ↑              ↓                      ↓
   Logout      (Select 2-4 funds)    (View NAV charts)
                    ↓                      ↑
              Favorites Screen ←-----------┘
           (Manage saved funds)
```

### Key Components

#### 1. **Login Screen**
- **Purpose**: User authentication and app entry point
- **Features**: 
  - Email/password validation
  - Modern iOS-style input fields
  - Non-scrollable responsive design
  - Loading states and error handling
  - Professional branding

#### 2. **Fund Selection Screen**
- **Purpose**: Browse, search, and select mutual funds
- **Features**:
  - Search by fund name, AMC, or category
  - Advanced filtering with visual tags
  - Fund selection (2-4 limit) with favorites toggle
  - Real-time search results
  - Selected funds appear at top
  - Compact native iOS UI elements

#### 3. **Comparison Screen**
- **Purpose**: Analyze and compare selected funds
- **Features**:
  - Apple Stocks-style interactive charts
  - Horizontal scrolling and pinch-to-zoom
  - Separate colored lines for each fund
  - Auto-refresh every 5 minutes
  - Fund performance metrics
  - Detailed fund information cards
  - Real-time NAV data

#### 4. **Favorites Screen**
- **Purpose**: Manage saved favorite funds (max 5)
- **Features**:
  - Latest NAV display for each favorite
  - Quick add/remove functionality
  - Refresh capability
  - Navigation to comparison

## 🎨 Design System

### Color Palette
```swift
// Primary Colors
Black Background:     #000000
Dark Gray:           #0D0D0D
Card Background:     #1A1A1A

// Green Accents
Primary Green:       #00CC66 (Financial green)
Secondary Green:     #009933
Success Green:       #00B359
Light Green:         #00E673

// Text Colors
Primary Text:        #FFFFFF
Secondary Text:      #CCCCCC
Tertiary Text:       #999999
```

### Typography
- **Large Title**: Bold, 34pt
- **Title**: Semibold, 28pt
- **Headline**: Semibold, 17pt
- **Body**: Regular, 17pt
- **Caption**: Regular, 12pt

### Layout Guidelines
- **Padding**: 8px, 16px, 24px, 32px system
- **Corner Radius**: 8px (small), 12px (standard), 16px (cards)
- **Spacing**: Consistent 16px between major elements

## 🏗️ Technical Implementation

### Architecture Pattern
- **MVVM**: Model-View-ViewModel architecture
- **ObservableObject**: Reactive state management
- **Combine**: Asynchronous data handling

### Data Flow
```
API Service → Models → AppState → Views
     ↓           ↓        ↓        ↓
Persistence ← Storage ← UserDefaults ← User Actions
```

### Key Classes

#### `AppState`
Central state management for navigation and data
```swift
@Published var currentScreen: AppScreen
@Published var selectedFunds: Set<Fund>
@Published var favoriteFunds: Set<Fund>
@Published var user: User?
```

#### `APIService`
Handles all network requests and data processing
```swift
func fetchAllFunds() -> AnyPublisher<[Fund], Error>
func fetchNAVData(for schemeCode: String) -> AnyPublisher<NAVResponse, Error>
```

#### `DataPersistenceService`
Manages local data storage and user preferences
```swift
func saveSelectedFunds(_ funds: Set<Fund>)
func saveFavoriteFunds(_ funds: Set<Fund>)
func getLastFilters() -> FundFilters
func addToFavorites(_ fund: Fund) -> Bool
```

### Data Models
```swift
struct Fund: Codable, Identifiable, Hashable
struct NAVData: Codable, Identifiable
struct User: Basic user model
struct FundFilters: Filter state management
```

## 🔌 API Integration

### MFApi.in Endpoints
- **All Funds**: `https://api.mfapi.in/mf`
- **NAV Data**: `https://api.mfapi.in/mf/{scheme_code}`

### Response Format
```json
{
  "meta": {
    "fund_house": "ICICI Prudential Mutual Fund",
    "scheme_type": "Open Ended Schemes",
    "scheme_category": "Large Cap Fund",
    "scheme_code": "120503",
    "scheme_name": "ICICI Prudential Bluechip Fund"
  },
  "data": [
    {
      "date": "20-08-2024",
      "nav": "580.45"
    }
  ]
}
```

## 📊 Charts Implementation

### SwiftUI Charts (Apple Stocks Style)
Using Apple's native Charts framework for optimal performance:
```swift
Chart {
  ForEach(selectedFunds.enumerated(), id: \.element.id) { index, fund in
    if let navData = navDataMap["\(fund.schemeCode)"] {
      ForEach(navData.prefix(30).reversed(), id: \.id) { data in
        LineMark(
          x: .value("Date", data.dateFormatted!),
          y: .value("NAV", data.navValue!),
          series: .value("Fund", fund.schemeName)
        )
        .foregroundStyle(chartColors[index])
        .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
        .interpolationMethod(.catmullRom)
      }
    }
  }
}
.chartScrollableAxes(.horizontal)
.chartXVisibleDomain(length: 3600 * 24 * 30)
```

### Chart Features
- **Multi-fund comparison**: Up to 4 separate colored lines
- **Interactive gestures**: Horizontal scroll and pinch-to-zoom (1x-3x)
- **Apple Stocks experience**: Professional financial chart UI
- **Distinct fund lines**: Each fund has its own series
- **Real-time updates**: Auto-refresh every 5 minutes
- **Performance optimized**: Shows last 30 data points
- **Color-coded legends**: Easy fund identification

## 💾 Data Persistence

### UserDefaults Storage
- **User email**: For login convenience
- **Selected funds**: Restore user's fund selection
- **Favorite funds**: Save up to 5 favorite funds
- **Search filters**: Remember last used filters
- **Search history**: Quick access to recent searches

### Privacy & Security
- **No sensitive data**: Passwords are not stored
- **Local storage only**: All data stays on device
- **Optional persistence**: Users can clear data anytime

## 🔮 Android Implementation Notes

If building the same flow on Android, consider:

### Technology Stack
- **Framework**: Jetpack Compose (similar to SwiftUI)
- **Architecture**: MVVM with LiveData/StateFlow
- **Navigation**: Navigation Component
- **Charts**: MPAndroidChart or Compose Charts
- **HTTP**: Retrofit + OkHttp
- **Storage**: SharedPreferences or Room DB

### Key Differences
```kotlin
// Android equivalent structures
@Composable fun LoginScreen()
@Composable fun FundSelectionScreen()
@Composable fun ComparisonScreen()

// State management
class AppViewModel : ViewModel()
class FundRepository
```

### Design Considerations
- **Material Design**: Use Material 3 theming
- **Navigation**: Navigation drawer or bottom navigation
- **Dark theme**: Follow system dark mode
- **Responsive**: Support tablets and foldables

## 🚧 Development Notes

### API Configuration
The app now uses **live API data** from MFApi.in:

1. **HTTP Security**: Added App Transport Security exception in Info.plist
2. **Real-time data**: Live NAV data from api.mfapi.in
3. **Error handling**: Comprehensive network error management
4. **Data validation**: Robust model parsing and validation

### Performance Optimizations
- **Lazy loading**: Lists use LazyVStack for efficiency
- **Image caching**: Consider adding for fund logos
- **Data pagination**: For large fund lists
- **Background refresh**: Update NAV data periodically

### Testing Strategy
- **Unit tests**: Model validation and business logic
- **UI tests**: Critical user flows
- **Integration tests**: API service functionality
- **Performance tests**: Chart rendering with large datasets





