from des import DES


des = DES(key=193)
number = 2014812094041914194
ciphertext = des.encrypt_number(number)
decrypted = des.decrypt_number(ciphertext)

print('Number:', number)
print('Encrypted:', ciphertext)
print('Decrypyed', decrypted)
