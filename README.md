# DES IP Core Project

## Giới thiệu về dự án

Đây là dự án thiết kế IP Core cho thuật toán mã hóa DES (Data Encryption Standard) - một trong những thuật toán mã hóa đối xứng được sử dụng rộng rãi. Dự án được phát triển theo phương pháp từ trên xuống (top-down), bắt đầu từ việc triển khai thuật toán bằng phần mềm, sau đó chuyển đổi thành thiết kế phần cứng.

## Tình trạng hiện tại

### ✅ Hoàn thành: Phần mềm (Software Implementation)

Chúng tôi đã hoàn thành việc triển khai thuật toán DES bằng Python với cấu trúc modular:

#### Cấu trúc phần mềm:
- **`DES.py`**: Module chính triển khai thuật toán DES
- **`Mixer.py`**: Xử lý phép trộn dữ liệu trong các round
- **`PBox.py`**: Triển khai các phép hoán vị (Permutation Box)
- **`SBox.py`**: Triển khai Substitution Box theo chuẩn DES
- **`Round.py`**: Xử lý logic cho mỗi round mã hóa
- **`Swapper.py`** & **`NoneSwapper.py`**: Xử lý việc hoán đổi dữ liệu
- **`utils.py`**: Các hàm tiện ích hỗ trợ

#### Tính năng đã triển khai:
- ✅ Mã hóa/giải mã số nguyên 64-bit
- ✅ Mã hóa/giải mã chuỗi ký tự
- ✅ Sinh khóa con cho 16 round
- ✅ Tất cả các phép hoán vị và thay thế theo chuẩn DES
- ✅ Driver test để kiểm tra chức năng

#### Ví dụ sử dụng:
```python
from des import DES

# Khởi tạo với khóa
des = DES(key=193)

# Mã hóa số
number = 2014812094041914194
encrypted = des.encrypt_number(number)
decrypted = des.decrypt_number(encrypted)

print(f"Original: {number}")
print(f"Encrypted: {encrypted}")
print(f"Decrypted: {decrypted}")
```

### 🚧 Đang phát triển: Phần cứng (Hardware Implementation)
### 📋 Kế hoạch tiếp theo

#### Giai đoạn 1: Hoàn thiện thiết kế RTL
- [ ] Hoàn thiện và tối ưu hóa các module Verilog
- [ ] Thiết kế datapath và control unit hoàn chỉnh
- [ ] Triển khai pipeline để tăng throughput
- [ ] Tối ưu hóa diện tích và công suất
- [ ] Verification và testing đầy đủ

#### Giai đoạn 2: Layout và Physical Design
- [ ] Floor planning
- [ ] Placement và routing
- [ ] Timing analysis và optimization
- [ ] Power analysis
- [ ] DRC (Design Rule Check) và LVS (Layout vs Schematic)
- [ ] Physical verification

#### Giai đoạn 3: Integration và Testing
- [ ] Post-layout simulation
- [ ] Chip-level integration
- [ ] Package design
- [ ] Final testing và validation

## Thông số kỹ thuật mục tiêu

| Thông số | Giá trị mục tiêu |
|----------|------------------|
| Block size | 64 bit |
| Key size | 64 bit (56 bit effective) |
| Number of rounds | 16 |
| Throughput | > 1 Gbps |
| Frequency | > 100 MHz |
| Technology | 28nm/45nm |
| Power consumption | < 10 mW @ 100MHz |

## Cấu trúc thư mục

```
DES/
├── sw/                 # Software implementation
│   ├── des/           # Python DES modules
│   └── driver.py      # Test driver
├── hw/                # Hardware implementation
│   ├── *.v           # Verilog modules
│   └── *_tb.v        # Testbenches
└── README.md         # Tài liệu này
```

## Yêu cầu hệ thống

### Phần mềm:
- Python 3.6+
- Các thư viện Python cơ bản

### Phần cứng:
- Icarus Verilog hoặc ModelSim/QuestaSim
- GTKWave để xem waveform
- Synthesis tools (Synopsys Design Compiler, Cadence Genus, etc.)
- Layout tools (Cadence Innovus, Synopsys ICC2, etc.)

### Tài Liệu Tham Khảo : 
- [https://page.math.tu-berlin.de/~kant/teaching/hess/krypto-ws2006/des.htm]
- [https://en.wikipedia.org/wiki/Data_Encryption_Standard]
- [https://nguyenquanicd.blogspot.com/2017/08/background-thuat-toan-ma-hoa-va-giai-ma.html]
- [https://nguyenquanicd.blogspot.com/2017/08/ip-core-loi-ip-ma-hoa-giai-ma-des.html]
- [https://nguyenquanicd.blogspot.com/2017/09/basic-knowledgebai-1-huong-dan-phan.html]
- [https://nguyenquanicd.blogspot.com/2017/09/basic-knowledgebai-2-huong-dan-phan.html]
- [https://nguyenquanicd.blogspot.com/2017/09/basic-knowledgebai-3-huong-dan-phan.html]
- [https://nguyenquanicd.blogspot.com/2017/09/basic-knowledgebai-4-huong-dan-phan.html]
- [https://nguyenquanicd.blogspot.com/2017/09/basic-knowledgebai-5-huong-dan-phan.html]
- https://www.academia.edu/download/52101727/A_Compact_FPGA_Implementation_of_Triple-20170310-22993-8x5uyz.pdf
