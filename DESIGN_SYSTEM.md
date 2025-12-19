# Zawāj Design System

This document outlines the design patterns, structure, and standards used throughout the Zawāj app onboarding flow.

## Color Palette

### Gradient Background
All onboarding screens use a consistent purple-to-pink gradient:

```swift
LinearGradient(
    gradient: Gradient(colors: [
        Color(red: 0.18, green: 0.05, blue: 0.35), // #2e0d5a (dark purple)
        Color(red: 0.72, green: 0.28, blue: 0.44)  // #b7486f (rose pink)
    ]),
    startPoint: .top,
    endPoint: .bottom
)
.ignoresSafeArea()
```

### Text Colors
- **Primary text**: `.white` (headings, labels)
- **Secondary text**: `.white.opacity(0.7)` (descriptions, subtitles)
- **Input text**: `.primary` (automatic light/dark adaptation)
- **Placeholder text**: `.secondary`

## Typography

### Dynamic Type Fonts
All text uses iOS Dynamic Type for accessibility:

```swift
// Page titles
.font(.largeTitle.weight(.bold))

// Body text and input fields
.font(.body)

// Descriptions and secondary text
.font(.title3)

// Button text
.font(.body.weight(.semibold))
```

### Custom Fonts
Three custom fonts are used in the launch screen:
- **Platypi**: Main app title "Zawāj" (64pt)
- **Amiri**: Arabic text "الزَّواجُ" (40pt)
- **Nunito Sans**: Tagline text (20pt)

## Layout Structure

### Standard Onboarding Screen Layout

All sign-up screens follow this consistent structure:

```swift
ZStack {
    // 1. Gradient background (always first)
    LinearGradient(...)
        .ignoresSafeArea()

    VStack(spacing: 0) {
        // 2. Navigation bar (back button + progress)
        HStack {
            Button(action: { /* Back action */ }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
            }
            ProgressBar(progress: 0.1)
        }
        .frame(height: 44)
        .padding(.horizontal, 24)
        .padding(.top, 8)

        // 3. Content section (title, subtitle, input fields)
        VStack(alignment: .leading, spacing: 16) {
            Text("Title")
                .font(.largeTitle.weight(.bold))
                .foregroundColor(.white)

            Text("Subtitle description")
                .font(.body)
                .foregroundColor(.white.opacity(0.7))

            // Input fields here
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)

        Spacer()

        // 4. Action button (always at bottom)
        GlassmorphicButton(title: "Continue") {
            // Continue action
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }
}
```

### Spacing Guidelines
- **Horizontal padding**: 24pt (consistent across all elements)
- **Top navigation padding**: 8pt from safe area
- **Content top padding**: 24pt below navigation
- **Bottom button padding**: 24pt from safe area
- **VStack spacing**: 16pt between title and subtitle
- **Button spacing**: 24pt between stacked buttons

## Components

### GlassmorphicButton

Reusable button component with iOS glassmorphic styling:

```swift
struct GlassmorphicButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.body.weight(.semibold))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 25))
        }
        .buttonStyle(.plain)
    }
}
```

**Properties:**
- Height: 50pt
- Corner radius: 25pt (oval shape)
- Background: `.ultraThinMaterial`
- Text: Semibold, `.primary` color
- Width: Full width (`.maxWidth: .infinity`)

### ProgressBar

Progress indicator component for tracking onboarding flow:

```swift
struct ProgressBar: View {
    let progress: Double // 0.0 to 1.0

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(white: 0.47, opacity: 0.2))
                    .frame(height: 6)

                // Filled progress
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(red: 0.0, green: 0.53, blue: 1.0)) // iOS blue
                    .frame(width: max(6, geometry.size.width * progress), height: 6)
            }
        }
        .frame(height: 6)
        .padding(.horizontal, 16)
    }
}
```

**Properties:**
- Height: 6pt
- Corner radius: 3pt
- Track color: Gray with 20% opacity
- Fill color: iOS blue (#0087FF)
- Minimum width: 6pt (ensures visibility at 0%)

## Input Fields

### Text Field Standard

All text fields follow this pattern:

```swift
TextField("", text: $binding, prompt: Text("Placeholder").foregroundColor(.secondary))
    .font(.body)
    .textFieldStyle(.plain)
    .padding(.horizontal, 16)
    .frame(height: 50)
    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    .textContentType(.appropriateType) // For autofill
    .autocapitalization(.appropriateSetting)
    .keyboardType(.appropriateType) // If needed
```

**Properties:**
- Height: 50pt
- Corner radius: 12pt
- Background: `.regularMaterial`
- Horizontal padding: 16pt (internal)
- Font: `.body`

### Text Content Types

Use appropriate `textContentType` for iOS autofill:
- `.email` - Email addresses
- `.telephoneNumber` - Phone numbers
- `.newPassword` - Password creation
- `.name` - Full names
- `.username` - Usernames

### Autocapitalization Settings
- `.none` - Email, username, password
- `.words` - Full name
- Default - Standard text input

### Keyboard Types
- `.emailAddress` - Email fields
- `.phonePad` - Phone numbers
- Default - Text fields

## Screen-Specific Patterns

### Password Fields with Visibility Toggle

```swift
@State private var password: String = ""
@State private var isPasswordVisible: Bool = false

HStack {
    if isPasswordVisible {
        TextField("", text: $password, prompt: Text("Password").foregroundColor(.secondary))
            .font(.body)
            .textFieldStyle(.plain)
            .textContentType(.newPassword)
    } else {
        SecureField("", text: $password, prompt: Text("Password").foregroundColor(.secondary))
            .font(.body)
            .textFieldStyle(.plain)
            .textContentType(.newPassword)
    }

    Button(action: {
        isPasswordVisible.toggle()
    }) {
        Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
            .font(.body)
            .foregroundColor(.secondary)
    }
    .buttonStyle(.plain)
}
.padding(.horizontal, 16)
.frame(height: 50)
.background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
```

### Country Code Picker

Phone number fields include a country code selector:

```swift
@State private var countryCode: String = "+1"
@State private var showingCountryPicker = false

HStack(spacing: 12) {
    // Country code button
    Button(action: { showingCountryPicker = true }) {
        HStack(spacing: 6) {
            Text(countryCode)
                .font(.body)
                .foregroundColor(.primary)
            Image(systemName: "chevron.down")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .frame(height: 50)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    .buttonStyle(.plain)

    // Phone number field
    TextField("", text: $phoneNumber, prompt: Text("Phone Number").foregroundColor(.secondary))
        .font(.body)
        .textFieldStyle(.plain)
        .padding(.horizontal, 16)
        .frame(height: 50)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .keyboardType(.phonePad)
}
```

### Date Picker (Birthday)

```swift
@State private var selectedDate = Date()

DatePicker("", selection: $selectedDate, displayedComponents: [.date])
    .datePickerStyle(.graphical)
    .tint(.blue)
    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 13))
    .frame(maxWidth: .infinity)
```

**Note:** Date picker uses 13pt corner radius (slightly larger than text fields).

### Selection Buttons (Gender)

For option selection screens, use stacked buttons:

```swift
VStack(spacing: 24) {
    GlassmorphicButton(title: "Male") {
        selectedGender = "Male"
    }

    GlassmorphicButton(title: "Female") {
        selectedGender = "Female"
    }
}
.padding(.horizontal, 24)
.padding(.bottom, 24)
```

**Important:** Ensure title/subtitle VStack has proper alignment:

```swift
VStack(alignment: .leading, spacing: 16) {
    Text("Gender")
        .font(.largeTitle.weight(.bold))
        .foregroundColor(.white)

    Text("Select your gender")
        .font(.body)
        .foregroundColor(.white.opacity(0.7))
}
.frame(maxWidth: .infinity, alignment: .leading) // Critical for left alignment
.padding(.horizontal, 24)
.padding(.top, 24)
```

## Materials & Effects

### iOS Materials
- **`.ultraThinMaterial`**: Buttons, highly transparent elements
- **`.regularMaterial`**: Text fields, date pickers, more opacity

### Material Benefits
- Automatic light/dark mode adaptation
- Native iOS blur effects
- Consistent with system UI
- Better accessibility

## File Structure

```
Zawaj/
├── Assets.xcassets/
│   └── logo.imageset/
│       ├── logo.png
│       └── Contents.json
├── Fonts/
│   ├── Platypi-Regular.ttf
│   ├── Amiri-Regular.ttf
│   └── NunitoSans-Regular.ttf
├── Components/
│   └── ProgressBar.swift
├── LaunchScreen.swift
├── WelcomeView.swift          (includes GlassmorphicButton)
├── SignUpEmailView.swift
├── SignUpPhoneView.swift      (includes CountryCodePickerView)
├── SignUpPasswordView.swift
├── SignUpFullNameView.swift
├── SignUpBirthdayView.swift
├── SignUpGenderView.swift
├── SignUpUsernameView.swift
└── ContentView.swift          (main entry point)
```

## Onboarding Flow Sequence

1. **LaunchScreen** - App branding with logo and tagline
2. **WelcomeView** - Log In / Sign Up options
3. **SignUpEmailView** - Email address input
4. **SignUpPhoneView** - Phone number with country code
5. **SignUpPasswordView** - Password creation with confirmation
6. **SignUpFullNameView** - Full name input
7. **SignUpBirthdayView** - Birthday selection
8. **SignUpGenderView** - Gender selection
9. **SignUpUsernameView** - Username creation

## Best Practices

### Accessibility
- Always use Dynamic Type fonts
- Use semantic colors (`.primary`, `.secondary`) where possible
- Ensure sufficient contrast ratios
- Support VoiceOver with proper labels

### iOS Integration
- Use appropriate `textContentType` for autofill support
- Enable strong password generation with `.textContentType(.newPassword)`
- Set correct keyboard types for input context
- Support system-wide appearance settings

### Consistency
- Maintain 24pt horizontal padding across all screens
- Use consistent spacing values (8, 16, 24pt)
- Keep button heights at 50pt
- Apply same gradient to all onboarding screens
- Use ProgressBar component (don't recreate inline)

### State Management
- Use `@State` for local view state
- Use `@Binding` for shared state between parent/child
- Use `@Environment(\.dismiss)` for modal dismissal

### Navigation
- Back buttons should use `chevron.left` icon
- Back buttons should be 20pt, semibold weight
- Progress bar should show incremental progress (0.1 per screen)

## Common Patterns

### Left-Aligned Content
When content needs to be left-aligned (especially important for titles):

```swift
VStack(alignment: .leading, spacing: 16) {
    // Content
}
.frame(maxWidth: .infinity, alignment: .leading)
.padding(.horizontal, 24)
```

### Modal Sheets
For presenting pickers or additional options:

```swift
.sheet(isPresented: $showingPicker) {
    PickerView(selectedValue: $selectedValue)
}
```

### Preview Provider
Always include preview for development:

```swift
#Preview {
    ViewName()
}
```

## Corner Radius Standards

- **Buttons**: 25pt (oval shape)
- **Text fields**: 12pt
- **Date picker**: 13pt
- **Progress bar**: 3pt

## Notes

- **iOS Version**: Designed for iOS 18+ (references to "iOS 26 standard" mean iOS 18 current standards)
- **Device Support**: Optimized for iPhone with Dynamic Island
- **Orientation**: Portrait only (typical for onboarding flows)
- **Safe Areas**: All content respects safe area insets
