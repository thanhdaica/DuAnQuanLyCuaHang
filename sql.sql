USE master;
GO

-- Xóa database cũ nếu tồn tại
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'QuanLyBanHang')
    DROP DATABASE QuanLyBanHang;
GO

-- Tạo database mới
CREATE DATABASE QuanLyBanHang;
GO

USE QuanLyBanHang;
GO

-- Tạo bảng
CREATE TABLE NhaCungCap (
	MaNCC VARCHAR(15) PRIMARY KEY,
	TenNCC NVARCHAR(30),
	DiaChi NVARCHAR(50),
	SDT INT
);
CREATE TABLE ChamCong(
	MaNhanVien varchar(15) NOT NULL,
	TenNhanVien nvarchar(50) NULL,
	NgayChamCong date NULL,
	TinhTrang nvarchar(50) NULL
);
CREATE TABLE LoaiHang (
	MaLoai VARCHAR(15) PRIMARY KEY,
	TenLoai NVARCHAR(30)
);

CREATE TABLE NhanVien (
	MaNhanVien VARCHAR(15) PRIMARY KEY,
	TenDangNhap VARCHAR(30) UNIQUE,
	MatKhau VARCHAR(16),
	HoVaTen NVARCHAR(30),
	NgaySinh DATETIME,
	SoDienThoai INT,
	DiaChi NVARCHAR(30),
	GioiTinh BIT,
	QuyenLoi VARCHAR(15)
);

CREATE TABLE Hang (
	MaHang VARCHAR(15) PRIMARY KEY,
	TenHang NVARCHAR(30),
	SoLuongCon INT,
	SoLuongDaBan INT,
	DonGiaBan FLOAT,
	TinhTrangHang NVARCHAR(10),
	DonGiaNhap FLOAT,
	MaNCC VARCHAR(15),
	MaLoai VARCHAR(15),
	CONSTRAINT fk_Hang1 FOREIGN KEY (MaNCC) REFERENCES NhaCungCap(MaNCC) ON UPDATE CASCADE ON DELETE CASCADE,
	CONSTRAINT fk_Hang2 FOREIGN KEY (MaLoai) REFERENCES LoaiHang(MaLoai) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE HoaDon (
	MaHoaDon VARCHAR(15) PRIMARY KEY,
	NgayLap DATETIME,
	MaNV VARCHAR(15),
	CONSTRAINT fk_HoaDon FOREIGN KEY (MaNV) REFERENCES NhanVien(MaNhanVien) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE ChiTietHoaDon (
	MaHoaDon VARCHAR(15),
	MaHang VARCHAR(15),
	SoLuongBan INT,
	CONSTRAINT pk_ChiTietHoaDon PRIMARY KEY (MaHoaDon, MaHang),
	CONSTRAINT fk_ChiTietHoaDon1 FOREIGN KEY (MaHoaDon) REFERENCES HoaDon(MaHoaDon) ON UPDATE CASCADE ON DELETE CASCADE,
	CONSTRAINT fk_ChiTietHoaDon2 FOREIGN KEY (MaHang) REFERENCES Hang(MaHang) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE BaoCaoDoanhThu (
	MaBC VARCHAR(15) PRIMARY KEY,
	MaNV VARCHAR(15),
	NgayLap DATETIME,
	CONSTRAINT fk_BCDT FOREIGN KEY (MaNV) REFERENCES NhanVien(MaNhanVien) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE ChiTietBaoCao (
	MaHang VARCHAR(15),
	MaBC VARCHAR(15),
	SoLuongDaBan INT,
	CONSTRAINT pk_CTBC PRIMARY KEY (MaHang, MaBC),
	CONSTRAINT fk_CTBC1 FOREIGN KEY (MaHang) REFERENCES Hang(MaHang) ON UPDATE CASCADE ON DELETE CASCADE,
	CONSTRAINT fk_CTBC2 FOREIGN KEY (MaBC) REFERENCES BaoCaoDoanhThu(MaBC) ON UPDATE CASCADE ON DELETE CASCADE
);
GO

-- Thêm dữ liệu
INSERT INTO NhaCungCap VALUES ('NCC01', N'Kinh Đô', N'Hà Nội', 0775467898);
INSERT INTO NhaCungCap VALUES ('NCC02', N'Thăng Long', N'Hồ Chí Minh', 0775982345);
INSERT INTO NhaCungCap VALUES ('NCC03', N'Chikika', N'Seoul', 1123456754);

INSERT INTO LoaiHang VALUES ('Loai1', N'Sinh Hoạt');
INSERT INTO LoaiHang VALUES ('Loai2', N'Học Tập');
INSERT INTO LoaiHang VALUES ('Loai3', N'Thức Ăn Nhanh');

INSERT INTO NhanVien VALUES 
('AD01', 'Admin', '1111', N'Trần Bích Hạnh', '1987-10-23', 0937465673, N'Hà Nội', 0, 'Admin'),
('NV01', 'Staff', '1111', N'Trần Thiên Điệp', '1999-10-23', 0937466573, N'Hà Nội', 1, 'Staff');

INSERT INTO Hang VALUES 
('Hang01', N'Bút Chì', 230, 100, 3000, N'Còn', 1500, 'NCC02', 'Loai2'),
('Hang02', N'Tampon', 130, 20, 75000, N'Còn', 45000, 'NCC03', 'Loai1'),
('Hang03', N'Mì Hảo Hảo', 0, 230, 3500, N'Hết', 2500, 'NCC01', 'Loai3');

INSERT INTO HoaDon VALUES ('HD01', '2020-01-01', 'NV01'), ('HD02', '2020-01-02', 'AD01');

INSERT INTO ChiTietHoaDon VALUES ('HD01', 'Hang01', 10), ('HD01', 'Hang02', 2);

INSERT INTO BaoCaoDoanhThu VALUES ('BC01', 'NV01', '2020-01-31'), ('BC02', 'AD01', '2020-02-29');

INSERT INTO ChiTietBaoCao VALUES ('Hang01', 'BC02', 100), ('Hang02', 'BC02', 20);
GO

-- Tạo trigger kiểm tra số lượng hàng khi bán
-- Bỏ trigger cũ (nếu cần)
IF OBJECT_ID('trg_CapNhat', 'TR') IS NOT NULL
    DROP TRIGGER trg_CapNhat;
GO

-- Tạo lại trigger như cũ
CREATE TRIGGER trg_CapNhat 
ON ChiTietHoaDon
FOR INSERT
AS
BEGIN
    DECLARE @sSoLuongCon INT = (SELECT SoLuongCon FROM Hang WHERE MaHang = (SELECT MaHang FROM inserted)),
            @sSoLuongBaninsert INT = (SELECT SoLuongBan FROM inserted);

    IF (@sSoLuongCon - @sSoLuongBaninsert) < 0
    BEGIN
        PRINT(N'Không thể nhỏ hơn 0');
        ROLLBACK TRAN;
    END
    ELSE
    BEGIN
        IF (@sSoLuongCon - @sSoLuongBaninsert) = 0
        BEGIN
            UPDATE Hang
            SET SoLuongCon = 0,
                SoLuongDaBan = SoLuongDaBan + @sSoLuongBaninsert,
                TinhTrangHang = N'Hết'
            WHERE MaHang = (SELECT MaHang FROM inserted);
        END
        ELSE
        BEGIN
            UPDATE Hang
            SET SoLuongCon = SoLuongCon - @sSoLuongBaninsert,
                SoLuongDaBan = SoLuongDaBan + @sSoLuongBaninsert
            WHERE MaHang = (SELECT MaHang FROM inserted);
        END
    END
END;
GO

-- ✅ Chỉ chèn hàng còn đủ số lượng
-- Hang01 còn 220 → bán 20: OK
-- Hang02 và Hang03 không chèn vì hết hàng
INSERT INTO ChiTietHoaDon VALUES ('HD02', 'Hang01', 20);
-- INSERT INTO ChiTietHoaDon VALUES ('HD02', 'Hang02', 130); -- ❌ bị rollback nếu SoLuongCon < 130
-- INSERT INTO ChiTietHoaDon VALUES ('HD02', 'Hang03', 10);  -- ❌ bị rollback nếu SoLuongCon = 0
GO

-- Truy vấn dữ liệu kiểm tra
SELECT * FROM Hang;
SELECT * FROM ChiTietHoaDon WHERE MaHoaDon = 'HD02';
SELECT * FROM HoaDon;
SELECT * FROM NhaCungCap;
SELECT * FROM NhanVien;

-- Thử xóa 1 nhà cung cấp
DELETE FROM NhaCungCap WHERE MaNCC = 'NCC01';
GO
