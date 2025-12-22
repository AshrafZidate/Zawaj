# Adding question_bank.json to Xcode

## Manual Steps Required

The `question_bank.json` file needs to be added to the Xcode project to be included in the app bundle.

### Steps:

1. **Open Xcode** with the Zawaj project

2. **Locate the file**:
   - In Finder, navigate to: `/Users/ashraf/Documents/Zawaj/Zawaj/Resources/`
   - You should see `question_bank.json`

3. **Add to Xcode**:
   - Drag `question_bank.json` from Finder into the Xcode project navigator
   - Drop it into the `Zawaj` group (or create a `Resources` group)

4. **Configure the file**:
   - When prompted, make sure:
     - ✅ "Copy items if needed" is checked
     - ✅ "Zawaj" target is selected
     - Click "Finish"

5. **Verify**:
   - Select `question_bank.json` in Xcode
   - Open the File Inspector (right sidebar)
   - Under "Target Membership", ensure "Zawaj" is checked

### Alternative: Add via Xcode Menu

1. In Xcode, right-click on the Zawaj folder
2. Select "Add Files to Zawaj..."
3. Navigate to the Resources folder
4. Select `question_bank.json`
5. Click "Add"

## Testing

Once added, the question bank should load automatically in development mode. You can verify by:

1. Running the app in simulator
2. Navigating to Profile tab
3. Tapping "Developer Tools" (only visible in development mode)
4. You should see the question bank info and upload button

## Uploading to Firestore

Once the JSON file is properly added to Xcode:

1. Run the app
2. Go to Profile > Developer Tools
3. Tap "Upload to Firestore"
4. Wait for confirmation

**Note**: Only upload once! Re-uploading will overwrite existing questions.
