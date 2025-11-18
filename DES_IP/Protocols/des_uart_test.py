# DES UART Test Script - Interactive Testing Tool
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from uart_comm import UARTComm, list_serial_ports


def print_menu():
    """Display the main menu."""
    print("\n" + "=" * 60)
    print("DES UART Test Menu")
    print("=" * 60)
    print("1. Encrypt plaintext")
    print("2. Decrypt ciphertext")
    print("3. Run encryption + decryption test")
    print("4. Send custom hex data")
    print("5. Change serial port settings")
    print("6. List serial ports")
    print("0. Exit")
    print("=" * 60)


def get_hex_input(prompt, length=16):
    """Get hex input from user with validation."""
    while True:
        value = input(prompt).strip().upper()
        # Remove spaces and 0x prefix if present
        value = value.replace(" ", "").replace("0X", "")
        
        if len(value) == length and all(c in '0123456789ABCDEF' for c in value):
            return value
        else:
            print(f"✗ Invalid input. Please enter exactly {length} hex characters (0-9, A-F)")


def encrypt_test(uart):
    """Test encryption."""
    print("\n" + "-" * 60)
    print("DES Encryption Test")
    print("-" * 60)
    
    plaintext = get_hex_input("Enter plaintext (16 hex chars): ")
    key = get_hex_input("Enter key (16 hex chars): ")
    
    print(f"\nPlaintext: {plaintext}")
    print(f"Key:       {key}")
    
    ciphertext = uart.des_encrypt(plaintext, key)
    
    if ciphertext:
        print(f"\n✓ Encryption Result:")
        print(f"  Ciphertext: {ciphertext}")
        return ciphertext
    else:
        print("\n✗ Encryption failed")
        return None


def decrypt_test(uart):
    """Test decryption."""
    print("\n" + "-" * 60)
    print("DES Decryption Test")
    print("-" * 60)
    
    ciphertext = get_hex_input("Enter ciphertext (16 hex chars): ")
    key = get_hex_input("Enter key (16 hex chars): ")
    
    print(f"\nCiphertext: {ciphertext}")
    print(f"Key:        {key}")
    
    plaintext = uart.des_decrypt(ciphertext, key)
    
    if plaintext:
        print(f"\n✓ Decryption Result:")
        print(f"  Plaintext: {plaintext}")
        return plaintext
    else:
        print("\n✗ Decryption failed")
        return None


def full_test(uart):
    """Run full encryption and decryption test."""
    print("\n" + "-" * 60)
    print("Full DES Encryption/Decryption Test")
    print("-" * 60)
    
    plaintext = get_hex_input("Enter plaintext (16 hex chars): ")
    key = get_hex_input("Enter key (16 hex chars): ")
    
    print(f"\n{'=' * 60}")
    print("Step 1: Encryption")
    print(f"{'=' * 60}")
    print(f"Plaintext: {plaintext}")
    print(f"Key:       {key}")
    
    ciphertext = uart.des_encrypt(plaintext, key)
    
    if not ciphertext:
        print("\n✗ Encryption failed. Test aborted.")
        return
    
    print(f"\n✓ Ciphertext: {ciphertext}")
    
    input("\nPress Enter to continue with decryption...")
    
    print(f"\n{'=' * 60}")
    print("Step 2: Decryption")
    print(f"{'=' * 60}")
    print(f"Ciphertext: {ciphertext}")
    print(f"Key:        {key}")
    
    decrypted = uart.des_decrypt(ciphertext, key)
    
    if not decrypted:
        print("\n✗ Decryption failed. Test aborted.")
        return
    
    print(f"\n✓ Decrypted:  {decrypted}")
    
    print(f"\n{'=' * 60}")
    print("Verification")
    print(f"{'=' * 60}")
    print(f"Original:  {plaintext}")
    print(f"Decrypted: {decrypted}")
    
    if decrypted == plaintext:
        print("\n✓✓ TEST PASSED! Plaintext recovered correctly.")
    else:
        print("\n✗✗ TEST FAILED! Plaintext mismatch.")


def send_custom_data(uart):
    """Send custom hex data."""
    print("\n" + "-" * 60)
    print("Send Custom Hex Data")
    print("-" * 60)
    
    data_hex = input("Enter hex data (even number of chars): ").strip().upper()
    data_hex = data_hex.replace(" ", "").replace("0X", "")
    
    if len(data_hex) % 2 != 0:
        print("✗ Invalid hex data. Length must be even.")
        return
    
    try:
        data_bytes = bytes.fromhex(data_hex)
        uart.send_bytes(data_bytes)
        print(f"✓ Sent {len(data_bytes)} bytes: {data_hex}")
        
        # Ask if user wants to receive response
        receive = input("\nReceive response? (y/n): ").strip().lower()
        if receive == 'y':
            num_bytes = int(input("Number of bytes to receive: "))
            response = uart.receive_bytes(num_bytes)
            if response:
                print(f"✓ Received: {response.hex().upper()}")
            else:
                print("✗ No response received")
    except ValueError as e:
        print(f"✗ Error: {e}")


def change_settings():
    """Change serial port settings."""
    print("\n" + "-" * 60)
    print("Current settings will be applied on reconnect")
    print("-" * 60)
    
    port = input("Enter serial port (e.g., COM3): ").strip()
    baudrate = input("Enter baud rate (default: 115200): ").strip()
    
    if not baudrate:
        baudrate = 115200
    else:
        try:
            baudrate = int(baudrate)
        except ValueError:
            print("✗ Invalid baud rate. Using default 115200.")
            baudrate = 115200
    
    return port, baudrate


def main():
    """Main interactive test program."""
    print("=" * 60)
    print("DES UART Interactive Test Tool")
    print("=" * 60)
    
    # List and select port
    available_ports = list_serial_ports()
    
    if not available_ports:
        port = input("\nNo ports detected. Enter port manually (e.g., COM3): ").strip()
    else:
        port = input(f"\nEnter serial port [{available_ports[0] if available_ports else 'COM3'}]: ").strip()
        if not port and available_ports:
            port = available_ports[0]
    
    if not port:
        print("✗ No port specified. Exiting.")
        return
    
    baudrate = input("Enter baud rate [115200]: ").strip()
    baudrate = int(baudrate) if baudrate else 115200
    
    # Create and connect
    uart = UARTComm(port=port, baudrate=baudrate)
    
    if not uart.connect():
        print("\n✗ Failed to connect to board. Exiting.")
        return
    
    try:
        while True:
            print_menu()
            choice = input("Enter choice: ").strip()
            
            if choice == '0':
                print("\nExiting...")
                break
            elif choice == '1':
                encrypt_test(uart)
            elif choice == '2':
                decrypt_test(uart)
            elif choice == '3':
                full_test(uart)
            elif choice == '4':
                send_custom_data(uart)
            elif choice == '5':
                new_port, new_baudrate = change_settings()
                uart.disconnect()
                uart = UARTComm(port=new_port, baudrate=new_baudrate)
                uart.connect()
            elif choice == '6':
                list_serial_ports()
            else:
                print("\n✗ Invalid choice. Please try again.")
            
            input("\nPress Enter to continue...")
    
    except KeyboardInterrupt:
        print("\n\nInterrupted by user")
    finally:
        uart.disconnect()


if __name__ == "__main__":
    main()
