# UART Communication Module for DES on Altera DE2
import serial
import time
import sys


class UARTComm:
    """Class to handle UART communication with Altera DE2 board."""
    
    def __init__(self, port='COM3', baudrate=115200, timeout=2):
        """
        Initialize UART communication.
        
        Args:
            port: Serial port (e.g., 'COM3' on Windows, '/dev/ttyUSB0' on Linux)
            baudrate: Baud rate for UART (default: 115200)
            timeout: Read timeout in seconds (default: 2)
        """
        self.port = port
        self.baudrate = baudrate
        self.timeout = timeout
        self.ser = None
        
    def connect(self):
        """Establish connection to the board."""
        try:
            self.ser = serial.Serial(
                port=self.port,
                baudrate=self.baudrate,
                bytesize=serial.EIGHTBITS,
                parity=serial.PARITY_NONE,
                stopbits=serial.STOPBITS_ONE,
                timeout=self.timeout
            )
            time.sleep(0.1)  # Wait for connection to stabilize
            print(f"✓ Connected to {self.port} at {self.baudrate} baud")
            return True
        except serial.SerialException as e:
            print(f"✗ Error connecting to {self.port}: {e}")
            return False
    
    def disconnect(self):
        """Close the serial connection."""
        if self.ser and self.ser.is_open:
            self.ser.close()
            print("✓ Disconnected from board")
    
    def send_byte(self, byte_val):
        """Send a single byte to the board."""
        if self.ser and self.ser.is_open:
            self.ser.write(bytes([byte_val]))
            return True
        return False
    
    def send_bytes(self, data):
        """
        Send multiple bytes to the board.
        
        Args:
            data: bytes or list of integers
        """
        if self.ser and self.ser.is_open:
            if isinstance(data, list):
                data = bytes(data)
            self.ser.write(data)
            return True
        return False
    
    def receive_byte(self):
        """Receive a single byte from the board."""
        if self.ser and self.ser.is_open:
            data = self.ser.read(1)
            if len(data) > 0:
                return data[0]
        return None
    
    def receive_bytes(self, num_bytes):
        """
        Receive multiple bytes from the board.
        
        Args:
            num_bytes: Number of bytes to receive
            
        Returns:
            bytes object or None if timeout
        """
        if self.ser and self.ser.is_open:
            data = self.ser.read(num_bytes)
            if len(data) == num_bytes:
                return data
            else:
                print(f"✗ Timeout: Expected {num_bytes} bytes, got {len(data)}")
        return None
    
    def flush(self):
        """Flush input and output buffers."""
        if self.ser and self.ser.is_open:
            self.ser.reset_input_buffer()
            self.ser.reset_output_buffer()
    
    def send_des_data(self, plaintext_hex, key_hex, mode='encrypt'):
        """
        Send plaintext and key to the board for DES encryption/decryption.
        
        Protocol:
            - Send 1 byte: mode (0x01 for encrypt, 0x02 for decrypt)
            - Send 8 bytes: plaintext/ciphertext
            - Send 8 bytes: key
        
        Args:
            plaintext_hex: 16-character hex string (64 bits)
            key_hex: 16-character hex string (64 bits)
            mode: 'encrypt' or 'decrypt'
            
        Returns:
            True if sent successfully, False otherwise
        """
        if not self.ser or not self.ser.is_open:
            print("✗ Serial port not open")
            return False
        
        # Validate inputs
        if len(plaintext_hex) != 16:
            print(f"✗ Invalid plaintext length: {len(plaintext_hex)} (expected 16)")
            return False
        if len(key_hex) != 16:
            print(f"✗ Invalid key length: {len(key_hex)} (expected 16)")
            return False
        
        try:
            # Convert hex strings to bytes
            plaintext_bytes = bytes.fromhex(plaintext_hex)
            key_bytes = bytes.fromhex(key_hex)
            
            # Flush buffers
            self.flush()
            
            # Send mode byte
            mode_byte = 0x01 if mode == 'encrypt' else 0x02
            self.send_byte(mode_byte)
            time.sleep(0.01)
            
            # Send plaintext (8 bytes)
            print(f"→ Sending {'plaintext' if mode == 'encrypt' else 'ciphertext'}: {plaintext_hex}")
            self.send_bytes(plaintext_bytes)
            time.sleep(0.01)
            
            # Send key (8 bytes)
            print(f"→ Sending key: {key_hex}")
            self.send_bytes(key_bytes)
            time.sleep(0.01)
            
            return True
            
        except ValueError as e:
            print(f"✗ Error converting hex to bytes: {e}")
            return False
    
    def receive_des_result(self):
        """
        Receive the DES result from the board.
        
        Protocol:
            - Receive 8 bytes: ciphertext/plaintext result
            
        Returns:
            Hex string of the result or None if failed
        """
        if not self.ser or not self.ser.is_open:
            print("✗ Serial port not open")
            return None
        
        print("← Waiting for result...")
        result_bytes = self.receive_bytes(8)
        
        if result_bytes:
            result_hex = result_bytes.hex().upper()
            print(f"← Received result: {result_hex}")
            return result_hex
        else:
            print("✗ Failed to receive result")
            return None
    
    def des_encrypt(self, plaintext_hex, key_hex):
        """
        Send data for encryption and receive ciphertext.
        
        Args:
            plaintext_hex: 16-character hex string
            key_hex: 16-character hex string
            
        Returns:
            Ciphertext as hex string or None if failed
        """
        if self.send_des_data(plaintext_hex, key_hex, mode='encrypt'):
            time.sleep(0.1)  # Wait for processing
            return self.receive_des_result()
        return None
    
    def des_decrypt(self, ciphertext_hex, key_hex):
        """
        Send data for decryption and receive plaintext.
        
        Args:
            ciphertext_hex: 16-character hex string
            key_hex: 16-character hex string
            
        Returns:
            Plaintext as hex string or None if failed
        """
        if self.send_des_data(ciphertext_hex, key_hex, mode='decrypt'):
            time.sleep(0.1)  # Wait for processing
            return self.receive_des_result()
        return None


def list_serial_ports():
    """List available serial ports."""
    import serial.tools.list_ports
    ports = serial.tools.list_ports.comports()
    if ports:
        print("\nAvailable serial ports:")
        for port in ports:
            print(f"  - {port.device}: {port.description}")
    else:
        print("\nNo serial ports found")
    return [port.device for port in ports]


def main():
    """Test the UART communication module."""
    print("=" * 60)
    print("DES UART Communication Test")
    print("=" * 60)
    
    # List available ports
    list_serial_ports()
    
    # Get port from user
    port = input("\nEnter serial port (e.g., COM3 or /dev/ttyUSB0): ").strip()
    if not port:
        print("No port specified. Exiting.")
        return
    
    # Create UART communication object
    uart = UARTComm(port=port, baudrate=115200)
    
    # Connect to board
    if not uart.connect():
        return
    
    try:
        # Test data
        plaintext = "0123456789ABCDEF"
        key = "133457799BBCDFF1"
        
        print(f"\n{'=' * 60}")
        print("Testing DES Encryption")
        print(f"{'=' * 60}")
        
        # Encrypt
        ciphertext = uart.des_encrypt(plaintext, key)
        
        if ciphertext:
            print(f"\n✓ Encryption successful!")
            print(f"  Plaintext:  {plaintext}")
            print(f"  Key:        {key}")
            print(f"  Ciphertext: {ciphertext}")
            
            # Decrypt
            print(f"\n{'=' * 60}")
            print("Testing DES Decryption")
            print(f"{'=' * 60}")
            
            decrypted = uart.des_decrypt(ciphertext, key)
            
            if decrypted:
                print(f"\n✓ Decryption successful!")
                print(f"  Ciphertext: {ciphertext}")
                print(f"  Key:        {key}")
                print(f"  Plaintext:  {decrypted}")
                
                # Verify
                if decrypted == plaintext:
                    print(f"\n✓✓ VERIFICATION PASSED! Plaintext recovered correctly.")
                else:
                    print(f"\n✗✗ VERIFICATION FAILED! Plaintext mismatch.")
        
    except KeyboardInterrupt:
        print("\n\nInterrupted by user")
    finally:
        uart.disconnect()


if __name__ == "__main__":
    main()
