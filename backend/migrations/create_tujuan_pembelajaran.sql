-- Create tujuan_pembelajaran table (Learning Objectives - Private per Guru)
CREATE TABLE IF NOT EXISTS tujuan_pembelajaran (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_guru INT NOT NULL,
    id_aspek INT NOT NULL,
    nama_tujuan VARCHAR(255) NOT NULL,
    deskripsi TEXT,
    indikator TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (id_guru) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (id_aspek) REFERENCES aspek_penilaian(id) ON DELETE CASCADE
);

-- Create kegiatan_pembelajaran table (Learning Activities - Private per Guru)
-- Modified to link to tujuan_pembelajaran instead of aspek_penilaian
CREATE TABLE IF NOT EXISTS kegiatan_pembelajaran (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_guru INT NOT NULL,
    id_tujuan INT NOT NULL,
    nama_kegiatan VARCHAR(255) NOT NULL,
    deskripsi TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (id_guru) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (id_tujuan) REFERENCES tujuan_pembelajaran(id) ON DELETE CASCADE
);

-- Seed data - Example tujuan pembelajaran for "Agama & Moral" aspek
INSERT INTO tujuan_pembelajaran (id_guru, id_aspek, nama_tujuan, deskripsi, indikator) VALUES 
(2, 1, 'Anak berpartisipasi aktif dalam kegiatan yang melibatkan gerak motorik', 
 'Anak dapat melakukan aktivitas dengan antusias dan fokus',
 'Anak tampak antusias saat melakukan kegiatan\nAnak dapat menyelesaikan kegiatan dari awal hingga akhir\nAnak ikut serta tanpa disuruh');

INSERT INTO kegiatan_pembelajaran (id_guru, id_tujuan, nama_kegiatan, deskripsi) VALUES 
(2, 1, 'Anak mampu melipat pola sederhana, menggunting, dan menempel', 
 'Anak dapat melakukan aktivitas melipat, gunting, tempel dengan baik');
