class UserModel {
  final int id;
  final String name;
  final String role;

  final String? nip;
  final String? nisn;
  final String? email;
  final String? username;

  final String? noHp;
  final String? pekerjaan;
  final String? alamat;

  final String? tempatLahir;
  final String? tanggalLahir;
  final String? agama;
  final String? jenisKelamin;
  final String? statusNikah;
  final String? pendidikan;
  final String? jurusan;
  final String? rtRw;
  final String? kelurahan;
  final String? kecamatan;
  final String? kota;
  final String? provinsi;
  final String? kodePos;

  UserModel({
    required this.id,
    required this.name,
    required this.role,
    this.nip,
    this.nisn,
    this.email,
    this.username,
    this.noHp,
    this.pekerjaan,
    this.alamat,
    this.tempatLahir,
    this.tanggalLahir,
    this.agama,
    this.jenisKelamin,
    this.statusNikah,
    this.pendidikan,
    this.jurusan,
    this.rtRw,
    this.kelurahan,
    this.kecamatan,
    this.kota,
    this.provinsi,
    this.kodePos,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: int.parse(json['id'].toString()),
      name: json['name'] ?? '',
      role: json['role'] ?? '',

      nip: json['nip'],
      nisn: json['nisn'],
      email: json['email'],
      username: json['username'],

      noHp: json['no_hp'] ?? json['no_telp'],
      pekerjaan: json['pekerjaan'],
      alamat: json['alamat'],

      tempatLahir: json['tempat_lahir'],
      tanggalLahir: json['tanggal_lahir'],
      agama: json['agama'],
      jenisKelamin: json['jenis_kelamin'],
      statusNikah: json['status_nikah'],
      pendidikan: json['pendidikan'],
      jurusan: json['jurusan'],
      rtRw: json['rt_rw'],
      kelurahan: json['kelurahan'],
      kecamatan: json['kecamatan'],
      kota: json['kota'],
      provinsi: json['provinsi'],
      kodePos: json['kode_pos'],
    );
  }
}
