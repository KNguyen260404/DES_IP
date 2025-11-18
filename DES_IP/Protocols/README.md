# DES UART Communication Protocol

Module Python để giao tiếp UART với board Altera DE2 cho thuật toán DES.

## Cài đặt

```bash
pip install -r requirements.txt
```

## Cấu trúc Protocol

### Gửi dữ liệu đến board (PC → FPGA):
1. **Mode byte** (1 byte):
   - `0x01` = Encrypt
   - `0x02` = Decrypt

2. **Data** (8 bytes):
   - Plaintext (nếu encrypt) hoặc Ciphertext (nếu decrypt)

3. **Key** (8 bytes):
   - 64-bit DES key

### Nhận dữ liệu từ board (FPGA → PC):
- **Result** (8 bytes):
  - Ciphertext (nếu encrypt) hoặc Plaintext (nếu decrypt)

## Sử dụng

### 1. Module chính: `uart_comm.py`

```python
from uart_comm import UARTComm

# Kết nối
uart = UARTComm(port='COM3', baudrate=115200)
uart.connect()

# Mã hóa
plaintext = "0123456789ABCDEF"
key = "133457799BBCDFF1"
ciphertext = uart.des_encrypt(plaintext, key)
print(f"Ciphertext: {ciphertext}")

# Giải mã
decrypted = uart.des_decrypt(ciphertext, key)
print(f"Decrypted: {decrypted}")

# Ngắt kết nối
uart.disconnect()
```

### 2. Tool test tương tác: `des_uart_test.py`

Chạy công cụ test:
```bash
python Protocols/des_uart_test.py
```

Menu tương tác:
- **1**: Mã hóa plaintext
- **2**: Giải mã ciphertext
- **3**: Test đầy đủ (encrypt + decrypt + verify)
- **4**: Gửi dữ liệu hex tùy chỉnh
- **5**: Thay đổi cấu hình port
- **6**: Liệt kê các port có sẵn
- **0**: Thoát

### 3. Test nhanh

```bash
python Protocols/uart_comm.py
```

## Cấu hình UART

### Windows:
- Port: `COM3`, `COM4`, etc.
- Kiểm tra Device Manager → Ports (COM & LPT)

### Linux:
- Port: `/dev/ttyUSB0`, `/dev/ttyS0`, etc.
- Kiểm tra: `ls /dev/tty*`
- Cấp quyền: `sudo chmod 666 /dev/ttyUSB0`

### Thông số mặc định:
- **Baud rate**: 115200
- **Data bits**: 8
- **Parity**: None
- **Stop bits**: 1
- **Flow control**: None

## API Reference

### Class `UARTComm`

#### Khởi tạo
```python
uart = UARTComm(port='COM3', baudrate=115200, timeout=2)
```

#### Phương thức chính

- `connect()`: Kết nối đến board
- `disconnect()`: Ngắt kết nối
- `des_encrypt(plaintext_hex, key_hex)`: Mã hóa
- `des_decrypt(ciphertext_hex, key_hex)`: Giải mã
- `send_bytes(data)`: Gửi raw bytes
- `receive_bytes(num_bytes)`: Nhận raw bytes
- `flush()`: Xóa buffer

#### Ví dụ nâng cao

```python
# Gửi/nhận raw data
uart.send_bytes([0x01, 0x23, 0x45, 0x67])
data = uart.receive_bytes(4)

# Custom protocol
uart.send_byte(0x01)  # Mode
uart.send_bytes(plaintext_bytes)
uart.send_bytes(key_bytes)
result = uart.receive_bytes(8)
```

## Lưu ý Implementation FPGA

### Verilog UART Receiver (RX):
- Nhận 17 bytes theo thứ tự: mode (1) + data (8) + key (8)
- Trigger DES core khi nhận đủ
- Sample ở giữa bit (baudrate/2)

### Verilog UART Transmitter (TX):
- Gửi 8 bytes result sau khi DES xong
- Start bit (0) + 8 data bits + Stop bit (1)

### Timing:
- 115200 baud = ~8.68 μs/bit
- 1 byte = ~87 μs
- 17 bytes input = ~1.5 ms
- DES processing + 8 bytes output

## Troubleshooting

### Không tìm thấy port:
```python
from uart_comm import list_serial_ports
list_serial_ports()
```

### Timeout khi nhận:
- Kiểm tra FPGA đã gửi dữ liệu chưa
- Tăng timeout: `UARTComm(timeout=5)`
- Kiểm tra baudrate khớp

### Data sai:
- Kiểm tra byte order (Big-endian/Little-endian)
- Verify checksum nếu có
- Flush buffer trước khi gửi: `uart.flush()`

## Test với Loopback

Test không cần FPGA (nối TX-RX):
```python
uart.send_bytes(b'Hello')
received = uart.receive_bytes(5)
print(received)  # Should be b'Hello'
```

## License

MIT
