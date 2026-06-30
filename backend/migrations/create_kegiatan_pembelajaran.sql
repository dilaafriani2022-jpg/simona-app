-- Create kegiatan_pembelajaran table
CREATE TABLE IF NOT EXISTS kegiatan_pembelajaran (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_aspek INT NOT NULL,
    nama_kegiatan VARCHAR(255) NOT NULL,
    deskripsi TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_aspek) REFERENCES aspek_penilaian(id) ON DELETE CASCADE
);

-- Seed data kegiatan pembelajaran dari document penilaian
-- Aspek: Agama & Moral (ID 1)
INSERT INTO kegiatan_pembelajaran (id_aspek, nama_kegiatan, deskripsi) VALUES 
(1, 'Anak mampu melaksanakan praktek beribadah dan praktek sholat', 'Anak dapat melakukan gerakan ibadah dengan benar'),
(1, 'Anak mampu membaca surah An-Nas dan Al-Kaustar', 'Anak dapat mengucapkan surah-surah pendek dengan jelas'),
(1, 'Anak mampu berdoa sebelum dan sesudah kegiatan (doa naik kendaraan)', 'Anak hafal dan melafadzkan doa dengan benar'),
(1, 'Anak jujur dalam berperilaku', 'Anak menunjukkan kejujuran dalam tindakan dan perkataan'),
(1, 'Anak menghormati orang tua dan guru', 'Anak menunjukkan sikap hormat kepada orang tua dan guru');

-- Aspek: Fisik Motorik (ID 2)
INSERT INTO kegiatan_pembelajaran (id_aspek, nama_kegiatan, deskripsi) VALUES 
(2, 'Anak mampu menggunakan alat tulis dengan berbagai kegiatan (menulis rapi, menggambar, mewarnai)', 'Anak dapat menggunakan alat tulis dengan koordinasi motorik halus'),
(2, 'Anak mampu melipat pola sederhana, mengggunting, dan menempel', 'Anak dapat melakukan aktivitas melipat, gunting, tempel dengan baik'),
(2, 'Anak mampu makan dengan tertib', 'Anak menunjukkan kebiasaan makan yang rapi dan tertib'),
(2, 'Anak mampu berjalan, berlari, melompat dengan seimbang', 'Anak menunjukkan koordinasi motorik kasar yang baik'),
(2, 'Anak mampu menangkap, melempar, dan menendang bola', 'Anak dapat melakukan aktivitas permainan bola dengan baik'),
(2, 'Anak mampu naik turun tangga dengan lancar', 'Anak menunjukkan keseimbangan dalam aktivitas naik turun');

-- Aspek: Kognitif (ID 3)
INSERT INTO kegiatan_pembelajaran (id_aspek, nama_kegiatan, deskripsi) VALUES 
(3, 'Anak mampu genal berbagai huruf (konsonan, huruf awal, suku kata)', 'Anak dapat mengenali dan menyebutkan huruf-huruf'),
(3, 'Anak mampu membangun bermain kreatif dengan berbagai media (dari: membentuk, kolase, balok, lego)', 'Anak dapat berkreasi dengan media yang tersedia'),
(3, 'Anak mampu menghitung secara berurutan (1-15) dengan berbagai benda', 'Anak dapat berhitung dan memahami konsep bilangan'),
(3, 'Anak mampu mendengarkan dan memahami percakapan sederhana', 'Anak dapat menangkap makna dari percakapan'),
(3, 'Anak mampu berkomunikasi dengan kalimat sederhana', 'Anak dapat mengungkapkan pikiran dalam kalimat yang jelas'),
(3, 'Anak mampu menceritakan pengalaman dengan urut', 'Anak dapat bercerita dengan kronologi yang benar'),
(3, 'Anak mampu bekerja sama dalam kelompok', 'Anak menunjukkan kemampuan kolaborasi dengan teman'),
(3, 'Anak mampu mengendalikan emosi dengan baik', 'Anak dapat mengatur reaksi emosional secara tepat'),
(3, 'Anak mampu berbagi dan membantu teman', 'Anak menunjukkan sikap prososial terhadap teman');
