import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class ApiService {

  // =====================================================
  // CONFIG BASE URL
  // =====================================================

  static const bool isProduction = false;

  // Gunakan true jika menjalankan di HP fisik (bukan emulator)
  // Ganti false jika menggunakan Android Emulator
  static const bool usePhysicalDevice = true;

  // WEB / WINDOWS
  static const String localUrl = "http://127.0.0.1/monak/backend";

  // ANDROID EMULATOR (10.0.2.2 = localhost PC dari emulator)
  static const String androidUrl = "http://10.0.2.2/monak/backend";

  static const String physicalDeviceUrl = "http://192.168.1.11/monak/backend";

  // HOSTING
  static const String onlineUrl =
      "http://202.10.44.63/monak/backend";

  static String get baseUrl {

    if (isProduction) {
      return onlineUrl;
    }

    if (!kIsWeb && Platform.isAndroid) {
      // Ganti usePhysicalDevice = true untuk HP fisik
      // Ganti usePhysicalDevice = false untuk Android Emulator
      return usePhysicalDevice ? physicalDeviceUrl : androidUrl;
    }

    // Windows / Web
    return localUrl;
  }

  // =====================================================
  // MOCK DATA
  // =====================================================

  static List<Map<String, dynamic>> mockKelas = [];

  static List<Map<String, dynamic>> mockTahun = [];

  static List<Map<String, dynamic>> mockAnak = [];

  static List<Map<String, dynamic>> mockOrtuAnak = [];

  // =====================================================
  // GLOBAL USER STATE — untuk activity tracking
  // =====================================================
  
  static Map<String, dynamic>? _currentUser;
  
  static void setCurrentUser(Map<String, dynamic>? user) {
    _currentUser = user;
  }
  
  static Map<String, dynamic>? getCurrentUser() {
    return _currentUser;
  }

  // =====================================================
  // LOGIN
  // =====================================================

  static Future<Map<String, dynamic>> login(
  String username,
  String password,
) async {

  try {

    final url =
        "${ApiService.baseUrl}/login.php";

    print("LOGIN URL : $url");

    final response = await http.post(
      Uri.parse(url),

      headers: {
        "Content-Type": "application/json"
      },

      body: jsonEncode({
        "username": username,
        "password": password,
      }),
    ).timeout(const Duration(seconds: 12));

    print("STATUS CODE : ${response.statusCode}");
    print("BODY : ${response.body}");

    final result = jsonDecode(response.body);
    
    // Store user data for activity tracking
    if (result['status'] == 'success' && result['user'] != null) {
      setCurrentUser(result['user']);
    }

    return result;

  } catch (e) {

    print("ERROR LOGIN : $e");

    return {
      "status": "error",
      "message": e.toString()
    };
  }
}

  // =====================================================
  // GET USERS
  // =====================================================

  static Future<Map<String, dynamic>> getUsers() async {

    try {

      final response = await http.get(
        Uri.parse("${ApiService.baseUrl}/get_users.php"),
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return {
        "status": "error",
        "message": "Server Error"
      };

    } catch (e) {

      return {
        "status": "error",
        "message": "Connection Error : $e"
      };

    }
  }

  // =====================================================
  // ADD USER
  // =====================================================

  static Future<Map<String, dynamic>> addUser(
    Map<String, dynamic> userData,
  ) async {

    try {

      final response = await http.post(
        Uri.parse("${ApiService.baseUrl}/add_user.php"),

        headers: {
          "Content-Type": "application/json"
        },

        body: jsonEncode(userData),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return {
        "status": "error",
        "message": "Server Error"
      };

    } catch (e) {

      return {
        "status": "error",
        "message": "Connection Error : $e"
      };

    }
  }

  // =====================================================
  // UPDATE USER
  // =====================================================

  static Future<Map<String, dynamic>> updateUser(
    Map<String, dynamic> userData,
  ) async {

    try {

      final response = await http.post(
        Uri.parse("${ApiService.baseUrl}/update_user.php"),

        headers: {
          "Content-Type": "application/json"
        },

        body: jsonEncode(userData),
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return {
        "status": "error",
        "message": "Server Error"
      };

    } catch (e) {

      return {
        "status": "error",
        "message": "Connection Error : $e"
      };

    }
  }

  // =====================================================
  // DELETE USER
  // =====================================================

  static Future<Map<String, dynamic>> deleteUser(
    int id,
  ) async {

    try {

      final response = await http.post(
        Uri.parse("${ApiService.baseUrl}/delete_user.php"),

        headers: {
          "Content-Type": "application/json"
        },

        body: jsonEncode({
          "id": id
        }),
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return {
        "status": "error",
        "message": "Server Error"
      };

    } catch (e) {

      return {
        "status": "error",
        "message": "Connection Error : $e"
      };

    }
  }

  // =====================================================
  // DASHBOARD
  // =====================================================

  static Future<Map<String, dynamic>> getDashboardStats({int? semester}) async {
    try {
      String url = "${ApiService.baseUrl}/get_dashboard_stats.php";
      if (semester != null) {
        url += "?semester=$semester";
      }

      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return {
        "status": "error",
        "message": "Server Error"
      };

    } catch (e) {

      return {
        "status": "error",
        "message": "Connection Error : $e"
      };

    }
  }

  // =====================================================
  // RECENT ACTIVITIES
  // =====================================================
  //
  // Endpoint PHP yang diharapkan: GET /get_recent_activities.php?limit=10
  //
  // Contoh response JSON dari server:
  // {
  //   "status": "success",
  //   "data": [
  //     {
  //       "id": 1,
  //       "judul": "Data anak baru ditambahkan",
  //       "deskripsi": "Ahmad Fauzi berhasil didaftarkan",
  //       "jenis": "anak",          // anak | guru | ortu | aspek | kelas | tahun | user | nilai
  //       "aksi": "tambah",         // tambah | edit | hapus | login | logout
  //       "waktu_label": "5 menit lalu",
  //       "created_at": "2025-06-08 10:30:00"
  //     },
  //     ...
  //   ]
  // }

  static Future<Map<String, dynamic>> getRecentActivities({int limit = 10}) async {
    try {
      final response = await http.get(
        Uri.parse("${ApiService.baseUrl}/get_recent_activities.php?limit=$limit"),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return {
        "status": "error",
        "message": "Server Error"
      };

    } catch (e) {
      // Kembalikan mock data agar dashboard tetap bisa ditampilkan
      // saat server tidak tersedia
      return {
        "status": "success",
        "source": "mock",
        "data": _mockActivities,
      };
    }
  }

  /// Mock data aktivitas — dipakai saat server tidak terhubung
  static final List<Map<String, dynamic>> _mockActivities = [
    {
      "id": 1,
      "judul": "Data anak baru ditambahkan",
      "deskripsi": "Ahmad Fauzi berhasil didaftarkan ke sistem",
      "jenis": "anak",
      "aksi": "tambah",
      "waktu_label": "5 menit lalu",
      "created_at": "",
    },
    {
      "id": 2,
      "judul": "Data guru diperbarui",
      "deskripsi": "Profil Ibu Sari berhasil diperbarui",
      "jenis": "guru",
      "aksi": "edit",
      "waktu_label": "20 menit lalu",
      "created_at": "",
    },
    {
      "id": 3,
      "judul": "Aspek penilaian ditambahkan",
      "deskripsi": "Aspek Kognitif berhasil dibuat",
      "jenis": "aspek",
      "aksi": "tambah",
      "waktu_label": "1 jam lalu",
      "created_at": "",
    },
    {
      "id": 4,
      "judul": "Data orang tua dihapus",
      "deskripsi": "Data Bpk. Hendra dihapus dari sistem",
      "jenis": "ortu",
      "aksi": "hapus",
      "waktu_label": "2 jam lalu",
      "created_at": "",
    },
    {
      "id": 5,
      "judul": "Kelas baru dibuat",
      "deskripsi": "Kelas Melati A berhasil ditambahkan",
      "jenis": "kelas",
      "aksi": "tambah",
      "waktu_label": "3 jam lalu",
      "created_at": "",
    },
  ];

  // =====================================================
  // GENERIC FETCH
  // =====================================================

  static Future<Map<String, dynamic>> fetchData(
    String endpoint,
    dynamic mockData,
  ) async {

    try {

      final response = await http.get(
        Uri.parse("${ApiService.baseUrl}/$endpoint"),
      );

      if (response.statusCode == 200) {

        final result = jsonDecode(response.body);

        return {
          ...result,
          "source": "server",
        };
      }

      return {
        "status": "success",
        "data": mockData,
        "source": "mock",
      };

    } catch (e) {

      return {
        "status": "success",
        "data": mockData,
        "source": "mock",
      };

    }
  }

  static Future<Map<String, dynamic>> fetch(String endpoint) async {
    try {
      final url = "${ApiService.baseUrl}/$endpoint";
      print("📥 API GET: $url");

      final response = await http.get(
        Uri.parse(url),
      ).timeout(const Duration(seconds: 12));

      print("📥 Status: ${response.statusCode}");
      print("📄 Response: ${response.body}");

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return {
          ...result,
          "source": "server",
        };
      }

      return {
        "status": "error",
        "message": "Server Error (${response.statusCode})",
        "data": [],
        "source": "error",
      };

    } catch (e) {
      print("❌ API Error: $e");
      return {
        "status": "error",
        "message": "Connection Error : $e",
        "data": [],
        "source": "error",
      };
    }
  }

  // =====================================================
  // GENERIC POST
  // =====================================================

  static Future<Map<String, dynamic>> postData(
    String endpoint,
    Map<String, dynamic> data,
  ) async {

    try {

      final url = "${ApiService.baseUrl}/$endpoint";
      
      // Automatically include current user in request for activity tracking
      final dataWithUser = {...data};
      final currentUser = getCurrentUser();
      if (currentUser != null) {
        dataWithUser['user'] = currentUser;
      }
      
      print("📤 API POST: $url");
      print("📦 Data: $dataWithUser");

      final response = await http.post(
        Uri.parse(url),

        headers: {
          "Content-Type": "application/json"
        },

        body: jsonEncode(dataWithUser),
      ).timeout(const Duration(seconds: 12));

      print("📥 Status: ${response.statusCode}");
      print("📄 Response: ${response.body}");

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result;
      }

      return {
        "status": "error",
        "message": "Server Error (${response.statusCode}): ${response.body}"
      };

    } catch (e) {

      print("❌ API Error: $e");
      return {
        "status": "error",
        "message": "Connection Error : $e"
      };

    }
  }

  // Compatibility wrapper used by existing screens
  static Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    return postData(endpoint, data);
  }

  // =====================================================
// ORTU ANAK
// =====================================================

static Future<Map<String, dynamic>> updateOrtuAnakLink(
  int ortuId,
  List<int> anakIds,
) async {

  return postData(
    "manage_ortu.php",
    {
      "action": "update_link",
      "ortu_id": ortuId,
      "anak_ids": anakIds,
    },
  );
}

static Future<Map<String, dynamic>> updateOrtuDetail(
  int ortuId, {
  String? noHp,
  String? pekerjaan,
  String? alamat,
}) async {

  return postData(
    "manage_ortu.php",
    {
      "action": "update_detail",
      "ortu_id": ortuId,
      "no_hp": noHp,
      "pekerjaan": pekerjaan,
      "alamat": alamat,
    },
  );
}

static Future<Map<String, dynamic>> addOrtu({
  required String name,
  String? noHp,
  String? pekerjaan,
  String? alamat,
  String? email,
  String? nisn,
}) async {

  return postData(
    "manage_ortu.php",
    {
      "action": "add_parent",
      "name": name,
      "no_hp": noHp,
      "pekerjaan": pekerjaan,
      "alamat": alamat,
      "email": email,
      "nisn": nisn,
    },
  );
}

  // =====================================================
  // SCHOOL PROFILE
  // =====================================================

  static Future<Map<String, dynamic>> getSchoolProfile() async {

    try {

      final response = await http.get(
        Uri.parse("${ApiService.baseUrl}/manage_sekolah.php"),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return {
        "status": "error",
        "message": "Server Error"
      };

    } catch (e) {

      return {
        "status": "error",
        "message": "Connection Error : $e"
      };

    }
  }

  static Future<Map<String, dynamic>> updateSchoolProfile(
    Map<String, dynamic> data,
  ) async {

    final payload = {
      ...data,
      'action': 'update',
    };

    return postData('manage_sekolah.php', payload);
  }

  static Future<Map<String, dynamic>> createSchoolProfile(
    Map<String, dynamic> data,
  ) async {

    final payload = {
      ...data,
      'action': 'add',
    };

    return postData('manage_sekolah.php', payload);
  }

  // =====================================================
  // ORANG TUA DASHBOARD APIS
  // =====================================================

  static Future<Map<String, dynamic>> getAnakByOrtu(int ortuId) async {
    try {
      final response = await http.get(
        Uri.parse("${ApiService.baseUrl}/get_anak_by_ortu.php?id_ortu=$ortuId"),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return {
        "status": "error",
        "message": "Server Error"
      };
    } catch (e) {
      return {
        "status": "error",
        "message": "Connection Error : $e"
      };
    }
  }

  static Future<Map<String, dynamic>> getKehadiranOrtu(
    int anakId, {
    int? bulan,
    int? tahun,
    int? semester,
  }) async {
    try {
      int bulanSekarang = bulan ?? DateTime.now().month;
      int tahunSekarang = tahun ?? DateTime.now().year;

      String url = "${ApiService.baseUrl}/get_kehadiran_ortu.php?id_anak=$anakId&bulan=$bulanSekarang&tahun=$tahunSekarang";
      if (semester != null) {
        url += "&semester=$semester";
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return {
        "status": "error",
        "message": "Server Error"
      };
    } catch (e) {
      return {
        "status": "error",
        "message": "Connection Error : $e"
      };
    }
  }

  static Future<Map<String, dynamic>> getPenilaianOrtu(int anakId) async {
    try {
      final response = await http.get(
        Uri.parse("${ApiService.baseUrl}/get_penilaian_ortu.php?id_anak=$anakId"),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return {
        "status": "error",
        "message": "Server Error"
      };
    } catch (e) {
      return {
        "status": "error",
        "message": "Connection Error : $e"
      };
    }
  }

  static Future<Map<String, dynamic>> getPertumbuhanFisik(
    int anakId, {
    int? limit,
  }) async {
    try {
      int limitData = limit ?? 6;

      final response = await http.get(
        Uri.parse(
          "${ApiService.baseUrl}/get_pertumbuhan_fisik.php?id_anak=$anakId&limit=$limitData",
        ),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return {
        "status": "error",
        "message": "Server Error"
      };
    } catch (e) {
      return {
        "status": "error",
        "message": "Connection Error : $e"
      };
    }
  }

  static Future<Map<String, dynamic>> getKaryaAnak(
    int anakId, {
    int? limit,
    int? offset,
  }) async {
    try {
      int limitData = limit ?? 20;
      int offsetData = offset ?? 0;

      final response = await http.get(
        Uri.parse(
          "${ApiService.baseUrl}/get_karya_anak.php?id_anak=$anakId&limit=$limitData&offset=$offsetData",
        ),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return {
        "status": "error",
        "message": "Server Error"
      };
    } catch (e) {
      return {
        "status": "error",
        "message": "Connection Error : $e"
      };
    }
  }

  // ── Anekdot untuk orang tua ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> getAnekdotOrtu(int anakId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/manage_anekdot.php?id_anak=$anakId'),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      return {'status': 'error', 'message': 'Server Error'};
    } catch (e) {
      return {'status': 'error', 'message': 'Connection Error: $e'};
    }
  }

  // ── Ekstrakurikuler anak ──────────────────────────────────────────────
  static Future<Map<String, dynamic>> getEkstrakurikulerAnak(int anakId, {int semester = 1}) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/manage_ekstrakurikuler.php?type=anak-ekstra&id_anak=$anakId&semester=$semester'),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      return {'status': 'error', 'message': 'Server Error'};
    } catch (e) {
      return {'status': 'error', 'message': 'Connection Error: $e'};
    }
  }

  // ── Refleksi guru kelas anak ──────────────────────────────────────────
  static Future<Map<String, dynamic>> getRefleksiGuru(int idKelas, {int? semester, int? idAnak}) async {
    try {
      String url = '${ApiService.baseUrl}/manage_refleksi_guru.php?id_kelas=$idKelas';
      if (semester != null) url += '&semester=$semester';
      if (idAnak != null) url += '&id_anak=$idAnak';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) return jsonDecode(response.body);
      return {'status': 'error', 'message': 'Server Error'};
    } catch (e) {
      return {'status': 'error', 'message': 'Connection Error: $e'};
    }
  }

  // ── Refleksi orang tua: GET ────────────────────────────────────────────
  static Future<Map<String, dynamic>> getRefleksiOrtu(int anakId, {int? idOrtu}) async {
    try {
      String url = '${ApiService.baseUrl}/manage_refleksi_ortu.php?id_anak=$anakId';
      if (idOrtu != null) url += '&id_ortu=$idOrtu';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) return jsonDecode(response.body);
      return {'status': 'error', 'message': 'Server Error'};
    } catch (e) {
      return {'status': 'error', 'message': 'Connection Error: $e'};
    }
  }

  // ── Refleksi orang tua by kelas: GET (for teacher view) ───────────────
  static Future<Map<String, dynamic>> getRefleksiOrtuByKelas(int idKelas, {int? semester}) async {
    try {
      String url = '${ApiService.baseUrl}/manage_refleksi_ortu.php?id_kelas=$idKelas';
      if (semester != null) url += '&semester=$semester';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) return jsonDecode(response.body);
      return {'status': 'error', 'message': 'Server Error'};
    } catch (e) {
      return {'status': 'error', 'message': 'Connection Error: $e'};
    }
  }

  // ── Refleksi orang tua: POST ───────────────────────────────────────────
  static Future<Map<String, dynamic>> submitRefleksiOrtu(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/manage_refleksi_ortu.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      return {'status': 'error', 'message': 'Server Error'};
    } catch (e) {
      return {'status': 'error', 'message': 'Connection Error: $e'};
    }
  }



  /// Create / set password for an existing guru / orang_tua / kepsek user.
  static Future<Map<String, dynamic>> createSmartUser({
    required String role,
    required int sourceId,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/create_smart_user.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'role':      role,
          'source_id': sourceId,
          'password':  password,
        }),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      return {'status': 'error', 'message': 'Server Error ${response.statusCode}'};
    } catch (e) {
      return {'status': 'error', 'message': 'Connection Error: $e'};
    }
  }
}








































































