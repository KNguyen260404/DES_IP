# DES Implementation for Altera DE2 Board

## Mô tả dự án
Implementation của thuật toán DES (Data Encryption Standard) trên board Altera DE2. Thiết kế cho phép mã hóa và giải mã dữ liệu 64-bit với key 64-bit sử dụng các nút bấm và switch trên board.

## Cấu trúc thư mục
```
FPGA/
├── des_de2_top.v         - Top module cho DE2 board
├── tb_des_de2_top.v      - Testbench
└── README.md             - File này

HW/
├── des_core.v            - Module DES core
└── tb_des_core.v         - Testbench cho DES core
```

## Chức năng các nút và switch

### Nút bấm (KEY - Active Low)
- **KEY[0]** - Reset hệ thống (giữ để reset)
- **KEY[1]** - Bắt đầu mã hóa (Encryption)
- **KEY[2]** - Bắt đầu giải mã (Decryption)
- **KEY[3]** - Nạp dữ liệu/key vào hệ thống

### Switch (SW)
- **SW[17:16]** - Chọn chế độ nạp dữ liệu:
  - `00`: Nạp data bits [15:0]
  - `01`: Nạp data bits [31:16]
  - `10`: Nạp data bits [47:32]
  - `11`: Nạp data bits [63:48]
- **SW[15:0]** - Dữ liệu/Key input (16 bits mỗi lần)

### LED
- **LEDR[17:0]** - Hiển thị trạng thái của switch
- **LEDG[8]** - DES Ready (sáng khi sẵn sàng)
- **LEDG[7]** - Đang mã hóa
- **LEDG[6]** - Đang giải mã

### 7-Segment Display
- **HEX7-HEX0** - Hiển thị 32 bits thấp của kết quả (8 chữ số hex)

## Hướng dẫn sử dụng

### 1. Nạp dữ liệu mặc định
- Plaintext mặc định: `0x0123456789ABCDEF`
- Key mặc định: `0x133457799BBCDFF1`

### 2. Nạp dữ liệu tùy chỉnh (64-bit data)
Để nạp dữ liệu 64-bit, cần nạp 4 lần (mỗi lần 16 bits):

**Ví dụ**: Nạp data = `0x0123456789ABCDEF`

a. Nạp bits [15:0] = `0xCDEF`:
   - SW[17:16] = `00`
   - SW[15:0] = `0xCDEF`
   - Nhấn KEY[3]

b. Nạp bits [31:16] = `0x89AB`:
   - SW[17:16] = `01`
   - SW[15:0] = `0x89AB`
   - Nhấn KEY[3]

c. Nạp bits [47:32] = `0x4567`:
   - SW[17:16] = `10`
   - SW[15:0] = `0x4567`
   - Nhấn KEY[3]

d. Nạp bits [63:48] = `0x0123`:
   - SW[17:16] = `11`
   - SW[15:0] = `0x0123`
   - Nhấn KEY[3]

### 3. Mã hóa (Encryption)
- Đảm bảo LEDG[8] sáng (DES ready)
- Nhấn KEY[1] để bắt đầu mã hóa
- Đợi LEDG[8] sáng lại (quá trình hoàn tất)
- Xem kết quả trên 7-segment displays

### 4. Giải mã (Decryption)
- Nạp dữ liệu đã mã hóa (cipher text)
- Nhấn KEY[2] để bắt đầu giải mã
- Đợi LEDG[8] sáng lại
- Xem kết quả trên 7-segment displays

## Test Vectors

### Test Vector 1 (Standard DES)
- **Plaintext**: `0x0123456789ABCDEF`
- **Key**: `0x133457799BBCDFF1`
- **Expected Ciphertext**: `0x85E813540F0AB405`

## Biên dịch và chạy testbench

### Sử dụng Icarus Verilog
```bash
# Compile
iverilog -o sim_de2 des_de2_top.v ../HW/des_core.v tb_des_de2_top.v

# Run simulation
vvp sim_de2

# View waveform
gtkwave tb_des_de2_top.vcd
```

### Sử dụng ModelSim
```tcl
# Compile
vlog des_de2_top.v ../HW/des_core.v tb_des_de2_top.v

# Simulate
vsim tb_des_de2_top

# Add waves and run
add wave -radix hex /*
run -all
```

## Tổng hợp cho FPGA (Quartus II)

### Bước 1: Tạo project mới
1. Mở Quartus II
2. File → New Project Wizard
3. Chọn device: Cyclone II EP2C35F672C6 (DE2 board)

### Bước 2: Thêm files
1. Thêm `des_de2_top.v` (top module)
2. Thêm `des_core.v` từ thư mục HW/

### Bước 3: Pin Assignment
Import file `.qsf` hoặc assign thủ công theo datasheet DE2.

**Các pin chính:**
- CLOCK_50 → PIN_N2
- KEY[0..3] → PIN_G26, PIN_N23, PIN_P23, PIN_W26
- SW[0..17] → PIN_N25, PIN_N26, ...
- LEDR[0..17] → PIN_AE23, PIN_AF23, ...
- LEDG[0..8] → PIN_AE22, PIN_AF22, ...
- HEX0-HEX7 → Multiple pins

### Bước 4: Compile
1. Processing → Start Compilation
2. Đợi quá trình tổng hợp hoàn tất
3. Kiểm tra timing và resource utilization

### Bước 5: Programming
1. Tools → Programmer
2. Chọn file `.sof`
3. Kết nối USB Blaster
4. Start programming

## Thông số kỹ thuật

- **Clock frequency**: 50 MHz
- **Data width**: 64 bits
- **Key width**: 64 bits
- **Number of rounds**: 16 rounds
- **Encryption/Decryption time**: ~17 clock cycles (~340 ns @ 50MHz)

## Troubleshooting

### Vấn đề: DES không sẵn sàng (LEDG[8] không sáng)
- Kiểm tra reset (KEY[0])
- Đảm bảo clock 50MHz hoạt động

### Vấn đề: Kết quả không đúng
- Kiểm tra lại data và key đã nạp
- Xác nhận thứ tự nạp dữ liệu (LSB first)
- Verify với test vector chuẩn

### Vấn đề: Không compile được
- Kiểm tra đường dẫn tới file `des_core.v`
- Đảm bảo tất cả files có trong project

## Tác giả
Nguyen2604

## License
Educational purpose only
