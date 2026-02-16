# Admin Login Credentials

## Hardcoded Admin Access

The application now includes hardcoded admin credentials for testing and development purposes.

### Credentials:
- **Email:** `admin@sugenix.com`
- **Password:** `admin123`

### How to Use:
1. Launch the application (mobile or web)
2. On the login screen, enter the credentials above
3. Click "Login" or "Sign in"
4. You will be redirected directly to the **Admin Panel**

### Implementation Details:
- The hardcoded check is implemented in both:
  - `lib/Login.dart` (Mobile login screen)
  - `lib/screens/web_landing_screen.dart` (Web landing screen)
  
- The check happens **before** Firebase authentication, so it bypasses the normal auth flow
- This allows immediate access to the admin panel without needing a Firebase account

### Important Notes:
- ⚠️ This is for **development/testing only**
- Some features requiring Firebase Auth user context may show default values
- For production, you should:
  1. Remove the hardcoded credentials
  2. Create a proper admin account in Firebase
  3. Set the user's role to 'admin' in Firestore

### Admin Panel Features:
Once logged in, you can access:
- Dashboard with statistics
- User management
- Doctor management
- Pharmacy management
- Revenue tracking
- Platform settings
- Medical records
- Order management

---
**Last Updated:** 2026-02-02
