# Run SplitBurn on your iPhone (Mac + free Apple ID)

About 30–45 minutes the first time (mostly downloads), about 2 minutes after that.

With a free Apple ID the app stays installed for **7 days**; after that, plug the
phone in and run the same command again. Your data survives reinstalls.

---

## 1. Set up the Mac (once)

1. **Xcode**: install it from the Mac App Store, open it once, accept the
   licence and let it install the iOS components. Then in Terminal:
   ```bash
   sudo xcode-select -s /Applications/Xcode.app
   ```
2. **Homebrew** (if you don't have it): follow https://brew.sh.
3. **CocoaPods** (fetches Google ML Kit for the receipt scanner):
   ```bash
   brew install cocoapods
   ```
4. **Flutter 3.47.8** (the version CI uses):
   ```bash
   git clone https://github.com/flutter/flutter.git -b 3.47.8 ~/flutter
   echo 'export PATH="$HOME/flutter/bin:$PATH"' >> ~/.zshrc
   source ~/.zshrc
   flutter doctor
   ```
   `flutter doctor` should show a green tick next to **Xcode**. Android
   warnings don't matter here.

## 2. Get the code

```bash
git clone https://github.com/Adithya-109/Budget.git
cd Budget
git checkout claude/serene-goldberg-wkhw1o
flutter pub get
```

## 3. Prepare the iPhone (once)

1. Plug the iPhone into the Mac with a cable. On the phone, tap **Trust** and
   enter your passcode.
2. Turn on **Developer Mode**: *Settings → Privacy & Security → Developer
   Mode → On*, then restart the phone when asked. (The switch only appears
   after the phone has been connected to Xcode once; if it's missing, do
   step 4 first and come back.)

## 4. Signing in Xcode (once)

```bash
open ios/Runner.xcworkspace
```

1. *Xcode → Settings → Accounts → +* and sign in with your Apple ID.
2. In the left sidebar click **Runner** (blue icon), then for each of the
   targets **Runner** and **BalanceWidgetExtension**:
   *Signing & Capabilities → Team → "Your Name (Personal Team)"*.
3. Wait a few seconds for Xcode to create the signing profile. One of three
   things happens:

| What you see | What to do |
|---|---|
| No errors | Use the **full** command in step 5. |
| An error mentioning **App Groups** (e.g. "Personal development teams … do not support the App Groups capability") | On **both** targets, scroll to the **App Groups** box under *Signing & Capabilities* and remove it (the trash / ✕ icon). Use the **free Apple ID** command in step 5. |
| "Failed to register bundle identifier" / "is not available" | Someone else already owns `com.splitburn.app`. Change the **Bundle Identifier** of Runner to e.g. `com.yourname.splitburn` and of BalanceWidgetExtension to `com.yourname.splitburn.BalanceWidget` (it must start with the app's ID). |

Don't commit these Xcode changes; they're only for your personal build
(`git checkout -- ios/` undoes them).

## 5. Install and run

Close Xcode (optional), and from the `Budget` folder:

**Full build** (App Group worked in step 4):
```bash
flutter run --release
```

**Free Apple ID build** (you removed App Groups in step 4):
```bash
flutter run --release --dart-define=SPLITBURN_SANDBOX_LEDGER=true
```

Pick your iPhone if asked. The first build takes several minutes.

`--release` matters: a debug build only opens while the Mac is running it;
a release build stays on the phone like a normal app.

**First launch only:** iOS says *Untrusted Developer*. On the phone open
*Settings → General → VPN & Device Management → (your Apple ID) → Trust*,
then open SplitBurn again.

## 6. What works in each build

| Feature | Full build | Free Apple ID build |
|---|---|---|
| Everything inside the app (dashboard, splits, receipt scan, friends, Nudge Bot, bills, trial alerts, dark/light mode) | ✅ | ✅ |
| Home / Lock Screen widget | ✅ | Shows "Open SplitBurn to set up" (it can't read the app's data) |
| Siri / Action Button / Apple Pay shortcut ("Log Split Expense") | ✅ | ❌ (can't reach the data) |

Settings shows a "Test build (free Apple ID)" note in the free build. If you
later get the paid Apple Developer account, turn App Groups back on and use
the full command: your data moves into the shared storage automatically.

## 7. Things worth trying

- Settings: set your allowance, the day it arrives, your name and UPI ID, and
  tap **Match my bank app** to set your real balance.
- Type `450 on Domino's with Rahul and Priya` in the bar at the bottom of
  Today, then **Log it**.
- Scan a real restaurant bill (the scan icon in the same bar), then tap who
  had what.
- Friends → a friend → **Nudge (nicely)** → share the meme receipt on WhatsApp.
- Bills → add a free trial charging tomorrow and check the 48-hour alert.
- The sun / moon button at the top right of Today switches dark and light.
- Full build only: long-press the Home Screen → **+** → SplitBurn to add the
  widget; *Shortcuts → Automation → Transaction* to log Apple Pay payments.

## Troubleshooting

| Problem | Fix |
|---|---|
| `pod install` fails or "CocoaPods not installed" | `brew install cocoapods`, then `cd ios && pod install --repo-update && cd ..` |
| The iPhone isn't listed | Unlock it, check the cable, tap **Trust**, and check Developer Mode is on. `flutter devices` should list it. |
| "Could not launch … invalid code signature / untrusted" | Do the *Trust* step under step 5. |
| The app stopped opening after a week | Free signing expired: plug in and run the same `flutter run --release …` command again. |
| Anything else | Copy the last ~30 lines of the error and send them over. |
