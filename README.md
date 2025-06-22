# حصن المسلم - Husn el-Muslim

حصن المسلم (Husn el-Muslim) is a beautiful, modern, and fully-featured Flutter app for reading, counting, and managing daily adhkar (remembrances) and supplications. The app is designed for Arabic speakers, with full RTL support and a focus on usability, clarity, and Islamic authenticity.

## Features

- **Comprehensive Adhkar Collection:**
  - Browse authentic daily adhkar and supplications from the famous book "حصن المسلم".
  - View details, benefits, and references for each dikr.

- **Custom Tasbeeh (مسبحة) Screen:**
  - Add, edit, and delete your own custom adhkar.
  - Each custom dikr supports benefit, reference, and a personal counter.
  - Max score tracking for each dikr.
  - Beautiful, interactive counter UI with background and Amiri font.

- **Modern UI/UX:**
  - Right-to-left (RTL) layout throughout the app.
  - Consistent use of the Amiri font for a traditional, elegant look.
  - AppBar with custom background image on all screens.
  - SafeArea usage for perfect display on all devices.
  - Responsive and touch-friendly design.

- **Persistence:**
  - All custom adhkar are saved locally and persist after closing the app.

- **Notifications:**
  - Beautiful SnackBar alerts for add, edit, and delete actions.

## Project Structure

```
lib/
  main.dart
  models/
    azkar_info.dart
    custom_dikr.dart
  screens/
    home_page.dart
    azkar_details_screen.dart
    custom_dikr_screen.dart
  constants/
    colors.dart
    strings.dart
  utils.dart
assets/
  hisnmuslim.json
  custom_dikr.json
  appBarBG.jpg
  counterBG.png
  ...
```

## Getting Started

1. **Clone the repository:**
   ```sh
   git clone <repo-url>
   cd Husn-el-Muslim
   ```

2. **Install dependencies:**
   ```sh
   flutter pub get
   ```

3. **Run the app:**
   ```sh
   flutter run
   ```

## Custom Adhkar Persistence
- Custom adhkar are stored locally using `shared_preferences`.
- On first launch, the app loads default adhkar from `assets/custom_dikr.json`.
- Any changes (add, edit, delete) are saved and restored automatically.

## RTL & Font
- The app is fully RTL, including all dialogs, sheets, and notifications.
- The Amiri font is used for all Arabic text for readability and beauty.

## Contribution
Pull requests and suggestions are welcome! Please ensure your code is clean, readable, and follows Flutter best practices.

## License
This project is open source and free to use for all Muslims. See the LICENSE file for details.

---

**May Allah accept your remembrance and make it a source of blessing!**
