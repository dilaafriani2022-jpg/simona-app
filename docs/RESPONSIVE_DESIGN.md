# Responsive Design Guide - Aplikasi SiMONA

Aplikasi SiMONA telah dioptimalkan untuk responsif di berbagai ukuran layar termasuk HP kecil, HP besar, tablet, dan desktop.

## Breakpoints

Sistem responsif menggunakan breakpoints berikut untuk mendeteksi ukuran perangkat:

```dart
- mobileSmall   : < 480px (HP kecil)
- mobileMedium  : 480px - 600px (HP sedang)
- mobileLarge   : 600px - 768px (HP besar)
- tablet        : 768px - 1024px (Tablet)
- desktop       : >= 1024px (Desktop/Landscape)
```

## Menggunakan Responsive Utility

### 1. Import Required
```dart
import '../../utils/responsive.dart';
```

### 2. Akses via BuildContext Extension
Semua method responsive dapat diakses langsung dari `context` (disarankan):

```dart
// Cek jenis device
if (context.isSmall) { }
if (context.isMobile) { }
if (context.isTablet) { }
if (context.isDesktop) { }

// Ukuran layar
double width = context.screenWidth;
double height = context.screenHeight;

// Font size responsif
Text(
  "Judul",
  style: TextStyle(
    fontSize: context.fontSize(base: 18, mobile: 16, tablet: 20),
  ),
)

// Spacing responsif
SizedBox(height: context.spacing)  // Default 16

// Grid columns
GridView.count(
  crossAxisCount: context.gridColumns,  // 1-4 tergantung device
)

// Tombol height
ElevatedButton(
  style: ElevatedButton.styleFrom(
    minimumSize: Size.fromHeight(context.buttonHeight),
  ),
)

// Padding responsif
Padding(
  padding: context.responsivePadding,  // 20h, 16v dengan adjustment
)
```

### 3. Menggunakan Static Methods
```dart
import '../../utils/responsive.dart';

if (Responsive.isMobile(context)) {
  // Tampilkan versi mobile
}

if (Responsive.isTablet(context)) {
  // Tampilkan versi tablet
}

// Font size dengan opsi
double fontSize = Responsive.fontSize(
  context,
  base: 14,
  mobile: 12,
  tablet: 16,
  desktop: 18,
);

// Grid aspect ratio
GridView.count(
  childAspectRatio: Responsive.gridAspectRatio(context),
)

// Menu columns untuk quick menu
GridView.count(
  crossAxisCount: Responsive.menuColumns(context),  // 3-6 item
)
```

## Implementasi Responsif di Berbagai Widget

### 1. Text dengan Ukuran Responsif
```dart
Text(
  "Title",
  style: TextStyle(
    fontSize: context.fontSize(base: 20, mobile: 16),
    fontWeight: FontWeight.bold,
  ),
)
```

### 2. Padding dan Margin Responsif
```dart
// Horizontal padding menyesuaikan dengan layar
Padding(
  padding: EdgeInsets.symmetric(
    horizontal: context.screenWidth * 0.05,  // 5% dari layar
  ),
  child: child,
)

// Atau menggunakan helper
SizedBox(height: context.spacing)
SizedBox(height: context.spacing * 2)
```

### 3. GridView Responsif
```dart
// Automatic grid count based on device
GridView.count(
  crossAxisCount: context.gridColumns,  
  crossAxisSpacing: context.isSmall ? 12 : 15,
  mainAxisSpacing: context.isSmall ? 12 : 15,
  childAspectRatio: Responsive.gridAspectRatio(context),
)

// Atau dengan custom columns
GridView.count(
  crossAxisCount: Responsive.responsiveGridCount(
    context,
    defaultCount: 2,      // Default untuk mobile large
    mobileCount: 2,       // Mobile medium
    tabletCount: 3,       // Tablet
  ),
)
```

### 4. Icon Size Responsif
```dart
Icon(
  Icons.home,
  size: Responsive.iconSize(context, base: 24),
)
```

### 5. Container dengan Max Width
```dart
Container(
  width: Responsive.maxCardWidth(context),  // Max 500 di desktop
  child: child,
)
```

## Contoh Implementasi Lengkap

### Dashboard Responsif
```dart
class Dashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header dengan padding responsif
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: context.screenWidth * 0.05,
            vertical: Responsive.spacing(context, base: 20),
          ),
          child: Text(
            "Dashboard",
            style: TextStyle(
              fontSize: context.fontSize(base: 24, mobile: 20),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(height: context.spacing),
        
        // Grid responsif
        GridView.count(
          crossAxisCount: context.gridColumns,  // 2-4 columns
          crossAxisSpacing: context.isSmall ? 12 : 15,
          mainAxisSpacing: context.isSmall ? 12 : 15,
          children: [
            // Cards...
          ],
        ),
      ],
    );
  }
}
```

### Form Responsif
```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  builder: (ctx) {
    return Padding(
      padding: EdgeInsets.all(context.isSmall ? 16 : 24),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Enter text',
              contentPadding: EdgeInsets.symmetric(
                vertical: context.isSmall ? 12 : 16,
                horizontal: context.isSmall ? 12 : 16,
              ),
            ),
          ),
          SizedBox(height: context.isSmall ? 12 : 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: Size.fromHeight(context.buttonHeight),
            ),
            onPressed: () { },
            child: Text(
              "Submit",
              style: TextStyle(
                fontSize: context.fontSize(base: 14, mobile: 12),
              ),
            ),
          ),
        ],
      ),
    );
  },
);
```

## Tips dan Best Practices

1. **Selalu gunakan context extension** untuk kemudahan:
   ```dart
   context.fontSize(...)  // ✓ Lebih mudah dibaca
   Responsive.fontSize(context, ...)  // ✗ Lebih verbose
   ```

2. **Gunakan percentage untuk padding horizontal**:
   ```dart
   horizontal: context.screenWidth * 0.05  // 5% padding
   ```

3. **Conditional rendering untuk layout berbeda**:
   ```dart
   if (context.isMobile) {
     // Single column layout
   } else {
     // Multi column layout
   }
   ```

4. **Gunakan maxLines dan overflow untuk text**:
   ```dart
   Text(
     name,
     maxLines: 1,
     overflow: TextOverflow.ellipsis,
   )
   ```

5. **Test di berbagai ukuran layar**:
   - Gunakan Flutter DevTools untuk test di berbagai breakpoints
   - Test di emulator dengan berbagai screen sizes
   - Jika mungkin, test di device fisik

## Screens yang Sudah Responsive

✅ `dashboard_operator.dart` - Fully responsive
✅ `manage_siswa_screen.dart` - Fully responsive
✅ Semua helper methods di management screens

## Screens yang Perlu Update

- `generic_management_screen.dart` - Needs full responsive update
- `dashboard_guru.dart` - Needs full responsive update
- `dashboard_kepsek.dart` - Needs full responsive update
- `dashboard_ortu.dart` - Needs full responsive update
- Semua management screens untuk helper methods

## Troubleshooting

### Text terlalu kecil di tablet
```dart
// Gunakan parameter tablet
context.fontSize(base: 14, tablet: 16)
```

### Widget terlalu lebar di desktop
```dart
// Batasi dengan MaxWidth
Container(
  constraints: BoxConstraints(maxWidth: 600),
  child: child,
)
```

### Spacing tidak konsisten
```dart
// Selalu gunakan responsive spacing
SizedBox(height: context.spacing)  // ✓
SizedBox(height: 16)  // ✗ Fixed, tidak responsive
```

## Referensi

- Utility file: `lib/utils/responsive.dart`
- Extension: `ResponsiveContext` di utility file
- Implementasi contoh: `dashboard_operator.dart`, `manage_siswa_screen.dart`

---

Untuk pertanyaan atau update lebih lanjut, lihat dokumentasi Flutter tentang responsive design:
https://flutter.dev/docs/development/ui/layout
