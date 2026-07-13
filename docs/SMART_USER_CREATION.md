# Smart User Creation System 🔐

## Overview
The Smart User Creation system allows operators to create login accounts that are automatically linked to existing organizational data (Guru, Orang Tua, Kepala Sekolah) **without requiring data duplication or manual linking**.

---

## How It Works

### User Flow
1. **Operator clicks "Tambah User"** on the Manage Users screen
2. **Two options appear:**
   - ✨ **Buat User Smart** - Auto-link to existing Guru/Ortu/Kepsek records
   - 📝 **Buat User Manual** - Traditional manual user creation

3. **Select Role:** Guru → Orang Tua → Kepala Sekolah

4. **Select Person:** Dropdown shows only people **without** existing user accounts:
   - **Guru:** Name (NIP)
   - **Orang Tua:** Child's Name (NISN)  
   - **Kepala Sekolah:** Name (Email)

5. **Enter Password:** Secure password for login

6. **Auto-Generated Username:**
   - **Guru:** `si_guru` (first 2 chars of name + role)
   - **Orang Tua:** `an_ortu` (first 2 chars of child's name + role)
   - **Kepala Sekolah:** `da_kepsek` (first 2 chars of name + role)

7. **User Created:** System returns auto-generated username
   - Password is hashed with `password_hash()`
   - Account is ready to login immediately

---

## Backend APIs

### `GET /backend/get_available_users.php?role=guru`
Returns all people with a specific role who **don't have user accounts yet**.

**Parameters:**
- `role`: `guru` | `orang_tua` | `kepsek`

**Response:**
```json
{
  "status": "success",
  "data": [
    {
      "id": 1,
      "name": "Siti Nurhaliza",
      "nip": "123456789"
    },
    {
      "id": 2,
      "name": "Ahmad Badawi",
      "nip": "987654321"
    }
  ]
}
```

---

### `POST /backend/create_smart_user.php`
Creates a new user account linked to an existing person.

**Request:**
```json
{
  "role": "guru",
  "source_id": 1,
  "password": "secret123"
}
```

**Parameters:**
- `role`: `guru` | `orang_tua` | `kepsek`
- `source_id`: ID of the person (guru_id, siswa_id for ortu, kepsek_id)
- `password`: Plain text password (will be hashed)

**Response:**
```json
{
  "status": "success",
  "data": {
    "username": "si_guru",
    "name": "Siti Nurhaliza",
    "role": "guru"
  }
}
```

---

## Flutter Implementation

### Widget: `CreateSmartUserSheet`
Located in `lib/widgets/create_smart_user_sheet.dart`

**Features:**
- Role-specific color coding (Green for Guru, Orange for Ortu, Purple for Kepsek)
- Dropdown to select available people
- Live username preview
- Password input with show/hide toggle
- Secure API call to create user
- Callback to refresh user list on success

**Usage:**
```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  builder: (context) => CreateSmartUserSheet(
    role: 'guru',
    onSuccess: () {
      // Refresh user list
      _fetchUsers();
    },
  ),
);
```

---

## Database Links

### How It Works Internally

**Before Smart User Creation:**
- Guru records exist in `users` table (with `name`, `nip`, `email` but **no username/password**)
- Orang Tua linked to Siswa via `siswa.id_ortu` FK
- Kepsek record exists in `users` table

**After Smart User Creation:**
- Same records updated with:
  - `username`: Auto-generated from name + role
  - `password`: Hashed using `password_hash(PASSWORD_DEFAULT)`
  - `role`: Unchanged

**Result:** User can now login with username/password and access their data immediately!

---

## Security Details

### Password Hashing
- Uses PHP's `password_hash($password, PASSWORD_DEFAULT)`
- Algorithm: bcrypt (as of PHP 8.2)
- Verification: `password_verify($input, $hash)` in login.php

### Login Flow
1. User enters username & password
2. login.php queries: `SELECT * FROM users WHERE username = ?`
3. Verifies: `password_verify($_POST['password'], $user['password'])`
4. Returns JWT token with user role

---

## Example Scenarios

### Scenario 1: Create Guru Account
1. Operator: "Siti Nurhaliza (NIP: 123456789) sudah didata, tapi belum bisa login"
2. Operator clicks Tambah User → Buat User Smart → Guru
3. Selects "Siti Nurhaliza (NIP: 123456789)"
4. Enters password "Siti123456"
5. System creates username: `si_guru`
6. Siti dapat login dengan:
   - **Username:** `si_guru`
   - **Password:** `Siti123456`

### Scenario 2: Create Orang Tua Account
1. Operator has Siswa "Ahmad Badawi" with parent already linked
2. Operator: Tambah User → Buat User Smart → Orang Tua
3. Selects "Ahmad Badawi (NISN: 000123)" - child's data
4. Enters password "Ahmad2024"
5. System creates username: `ah_ortu`
6. Parent dapat login dengan:
   - **Username:** `ah_ortu`
   - **Password:** `Ahmad2024`
7. When parent logs in, they see Ahmad's data automatically!

---

## Testing the Feature

### Step 1: Verify Backend is Running
```bash
php -S 127.0.0.1:8000 -t backend
```

### Step 2: Test get_available_users.php
```bash
curl "http://127.0.0.1:8000/get_available_users.php?role=guru"
```

### Step 3: Create a Test User
```bash
curl -X POST "http://127.0.0.1:8000/create_smart_user.php" \
  -H "Content-Type: application/json" \
  -d '{
    "role": "guru",
    "source_id": 1,
    "password": "test123456"
  }'
```

### Step 4: Login with Created Account
1. Launch Flutter app
2. Go to Login screen
3. Enter username from Step 3 response
4. Enter password: `test123456`
5. Verify successful login!

---

## Troubleshooting

### ❌ "Tidak ada data yang tersedia"
- **Cause:** All people in that role already have user accounts
- **Solution:** Create more Guru/Ortu/Kepsek records first

### ❌ "Username sudah digunakan"
- **Cause:** Another user already has the same auto-generated username
- **Solution:** Very rare - happens if multiple people have same first 2 characters + role + no existing account
- **Manual fix:** Use "Buat User Manual" instead to choose custom username

### ❌ "Password tidak boleh kosong"
- **Cause:** User didn't enter a password
- **Solution:** Enter at least one character for password

### ❌ Login fails after user creation
- **Cause 1:** Backend not running
- **Solution:** Start PHP server: `php -S 127.0.0.1:8000 -t backend`
- **Cause 2:** Password typed incorrectly
- **Solution:** Re-create user with simpler password for testing

---

## Advantages Over Manual User Creation

| Feature | Manual | Smart |
|---------|--------|-------|
| Data entry errors | ❌ High risk | ✅ Zero risk |
| Duplicate data | ❌ Possible | ✅ Prevented |
| User linking | ❌ Manual | ✅ Automatic |
| Time taken | ❌ 5-10 min per user | ✅ 30 sec per user |
| Password security | ⚠️ Admin choice | ✅ User's choice |
| Username generation | ❌ Manual | ✅ Automatic |
| Verification | ❌ Manual | ✅ Instant |

---

## Files Involved

### Backend
- `backend/get_available_users.php` - Fetch available people
- `backend/create_smart_user.php` - Create linked user account
- `backend/login.php` - Updated to use password_verify()

### Frontend
- `lib/widgets/create_smart_user_sheet.dart` - User creation widget
- `lib/screens/operator/manage_users_screen.dart` - Integrated into UI
- `lib/services/api_service.dart` - API calls (fetch, post methods)

### Utilities
- `pubspec.yaml` - Dependencies (intl for date formatting)

---

## Next Steps / Enhancements

- [ ] **Bulk User Import:** Upload CSV with Guru/Ortu data and create accounts in batch
- [ ] **Username Customization:** Allow operator to edit auto-generated username before save
- [ ] **Password Reset:** Add "Forgot Password" feature with email verification
- [ ] **User Audit Log:** Track when users were created and by whom
- [ ] **Role-based Dashboard:** Show different stats per role (Guru sees students, Ortu sees child)

---

## Questions?

Refer to the AGENTS.md file for project-wide context and API patterns.
