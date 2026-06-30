class SchoolProfile {
  final int? id;
  final String namaSekolah;
  final String? npsn;
  final String? alamat;
  final String? kelurahan;
  final String? kecamatan;
  final String? kotaKabupaten;
  final String? provinsi;
  final String? kodePos;
  final String? telepon;
  final String? email;
  final String? website;
  final String? kepalaSekol;
  final String? nipKepalaSekol;
  final String? visi;
  final String? misi;
  final String? logoUrl;
  final int? tahunBerdiri;
  final String? akreditasi;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SchoolProfile({
    this.id,
    required this.namaSekolah,
    this.npsn,
    this.alamat,
    this.kelurahan,
    this.kecamatan,
    this.kotaKabupaten,
    this.provinsi,
    this.kodePos,
    this.telepon,
    this.email,
    this.website,
    this.kepalaSekol,
    this.nipKepalaSekol,
    this.visi,
    this.misi,
    this.logoUrl,
    this.tahunBerdiri,
    this.akreditasi,
    this.createdAt,
    this.updatedAt,
  });

  factory SchoolProfile.fromJson(Map<String, dynamic> json) {
    return SchoolProfile(
      id: json['id'],
      namaSekolah: json['nama_sekolah'] ?? '',
      npsn: json['npsn'],
      alamat: json['alamat'],
      kelurahan: json['kelurahan'],
      kecamatan: json['kecamatan'],
      kotaKabupaten: json['kota_kabupaten'],
      provinsi: json['provinsi'],
      kodePos: json['kode_pos'],
      telepon: json['telepon'],
      email: json['email'],
      website: json['website'],
      kepalaSekol: json['kepala_sekolah'],
      nipKepalaSekol: json['nip_kepala_sekolah'],
      visi: json['visi'],
      misi: json['misi'],
      logoUrl: json['logo_url'],
      tahunBerdiri: json['tahun_berdiri'] != null 
          ? int.tryParse(json['tahun_berdiri'].toString())
          : null,
      akreditasi: json['akreditasi'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama_sekolah': namaSekolah,
      'npsn': npsn,
      'alamat': alamat,
      'kelurahan': kelurahan,
      'kecamatan': kecamatan,
      'kota_kabupaten': kotaKabupaten,
      'provinsi': provinsi,
      'kode_pos': kodePos,
      'telepon': telepon,
      'email': email,
      'website': website,
      'kepala_sekolah': kepalaSekol,
      'nip_kepala_sekolah': nipKepalaSekol,
      'visi': visi,
      'misi': misi,
      'logo_url': logoUrl,
      'tahun_berdiri': tahunBerdiri,
      'akreditasi': akreditasi,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  SchoolProfile copyWith({
    int? id,
    String? namaSekolah,
    String? npsn,
    String? alamat,
    String? kelurahan,
    String? kecamatan,
    String? kotaKabupaten,
    String? provinsi,
    String? kodePos,
    String? telepon,
    String? email,
    String? website,
    String? kepalaSekol,
    String? nipKepalaSekol,
    String? visi,
    String? misi,
    String? logoUrl,
    int? tahunBerdiri,
    String? akreditasi,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SchoolProfile(
      id: id ?? this.id,
      namaSekolah: namaSekolah ?? this.namaSekolah,
      npsn: npsn ?? this.npsn,
      alamat: alamat ?? this.alamat,
      kelurahan: kelurahan ?? this.kelurahan,
      kecamatan: kecamatan ?? this.kecamatan,
      kotaKabupaten: kotaKabupaten ?? this.kotaKabupaten,
      provinsi: provinsi ?? this.provinsi,
      kodePos: kodePos ?? this.kodePos,
      telepon: telepon ?? this.telepon,
      email: email ?? this.email,
      website: website ?? this.website,
      kepalaSekol: kepalaSekol ?? this.kepalaSekol,
      nipKepalaSekol: nipKepalaSekol ?? this.nipKepalaSekol,
      visi: visi ?? this.visi,
      misi: misi ?? this.misi,
      logoUrl: logoUrl ?? this.logoUrl,
      tahunBerdiri: tahunBerdiri ?? this.tahunBerdiri,
      akreditasi: akreditasi ?? this.akreditasi,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'SchoolProfile(id: $id, namaSekolah: $namaSekolah, npsn: $npsn)';
  }
}

