// services/api_key_config.dart
//
// ─────────────────────────────────────────────────────────────────────────────
//  HOW TO ADD YOUR GEMINI API KEYS
// ─────────────────────────────────────────────────────────────────────────────
//
//  Step 1: Go to https://aistudio.google.com/app/apikey
//  Step 2: Click "Create API key" → Copy the key (starts with "AIza...")
//  Step 3: Paste it inside the list below, replacing the placeholder text
//
//  WHY MULTIPLE KEYS?
//  Each free-tier key allows ~15 requests/minute and 1500 requests/day.
//  Adding keys from different Google accounts multiplies your free quota.
//  The app automatically tries the next key when one hits its rate limit.
//
//  HOW TO GET MORE FREE KEYS:
//  • Use different Google accounts (Gmail accounts are free to create)
//  • Each account → 1 free Gemini API key → extra 1500 scans/day
//  • Add as many keys as you want in the list below
//
//  EXAMPLE (3 keys = 4500 free scans per day):
//    static const List<String> geminiApiKeys = [
//      'AIzaSyA1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6',
//      'AIzaSyB7c8d9e0f1g2h3i4j5k6l7m8n9o0p1q2',
//      'AIzaSyC3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8',
//    ];
//
//  SECURITY: Add this file to .gitignore so keys stay off GitHub:
//    echo "lib/services/api_key_config.dart" >> .gitignore
// ─────────────────────────────────────────────────────────────────────────────

class ApiKeyConfig {
  /// Paste your Gemini API key(s) here.
  /// Add multiple keys for more free quota — the app rotates automatically.
  static const List<String> geminiApiKeys = [
    'AIzaSyBN0PgwWZvKiK32OHtKECiFRaS9SL44nOM',
    'AIzaSyB9LRtqBg9_cPh45CIrBkMJRgnidUDsWGM',
    'AIzaSyDQBHHb5oB1AXGkjm6xyEkwu5FjafpIgIw',
    'AIzaSyDEtdLCH_betteAqZgc0gXo_Lo9ubmoq-U',
  ];
}
