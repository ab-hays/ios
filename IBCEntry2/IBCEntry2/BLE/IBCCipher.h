//
//  IBCCipher.h
//  BLE_App
//
//  Created by Nicholas Pisarro on 5/14/22.
//  Copyright © 2022 IBC All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IBCCipher : NSObject
{
#define Nb 4

    int Nr;
    int Nk;

    // in - it is the array that holds the plain text to be encrypted. We have initialized with test data but you will need to create
    // key - the key to be used

    unsigned char Data[16];
    unsigned char Key[32];
    char convertedC[33];
    unsigned char authkey[8];
    unsigned char temp1,temp2,temp3,temp4;
    unsigned char newkey0,newkey2,newkey7,newkey13;
    unsigned char ConvertedAuthKey[4];
    unsigned char ConvertedAuthKey_objectiveC[16];


    // out - it is the array that holds the output CipherText after encryption.
    // state - the array that holds the intermediate results during encryption.

    unsigned char output[16], state[4][4];
    unsigned char RoundKey[240];
}

@property (readonly, nonatomic) char *convertedC;
@property (readonly, nonatomic) unsigned char *ConvertedAuthKey_objectiveC;

- (int)getSBoxValue:(int)num;
- (int)getSBoxInvert:(int)num;

- (void)KeyExpansion;

// This function adds the round key to state.
// The round key is added to the state by an XOR function.
- (void)AddRoundKey:(int)round;

// The SubBytes Function Substitutes the values in the
// state matrix with values in an S-box.
- (void)SubBytes;

// The ShiftRows() function shifts the rows in the state to the left.
// Each row is shifted with different offset.
// Offset = Row number. So the first row is not shifted.
- (void)ShiftRows;

// xtime is a macro that finds the product of {02} and the argument to xtime modulo {1b}
#define xtime(x)   ((x<<1) ^ (((x>>7) & 1) * 0x1b))

// MixColumns function mixes the columns of the state matrix
// The method used may look complicated, but it is easy if you know the underlying theory.
// Refer the documents specified above.
- (void)MixColumns;

// The SubBytes Function Substitutes the values in the
// state matrix with values in an S-box.
- (void)InvSubBytes;

// Multiplty is a macro used to multiply numbers in the field GF(2^8)
#define Multiply(x,y) (((y & 1) * x) ^ ((y>>1 & 1) * xtime(x)) ^ ((y>>2 & 1) * xtime(xtime(x))) ^ ((y>>3 & 1) * xtime(xtime(xtime(x)))) ^ ((y>>4 & 1) * xtime(xtime(xtime(xtime(x))))))

// The ShiftRows() function shifts the rows in the state to the left.
// Each row is shifted with different offset.
// Offset = Row number. So the first row is not shifted.
- (void)InvShiftRows;

// MixColumns function mixes the columns of the state matrix.
// The method used to multiply may be difficult to understand for beginners.
// Please use the references to gain more information.
- (void)InvMixColumns;

// InvCipher is the main function that decrypts the CipherText.
- (void)InvCipher;

#define bufferSize1 8

- (void)keymakerMaethod1:(NSArray *)array;

- (void)AuthAlgorithm;

#define bufferSize 4

- (int)getConverted_auth;

#define bufferSize2 16

- (int)getConverted;

// Cipher is the main function that encrypts the PlainText.
- (void)Cipher;

- (char *_Nullable *_Nullable)cArrayFromNSArray:(NSArray *)array;


- (void)keymakerMaethod:(NSArray *)array;

// AES Encryption – doencrypt - call this routine to encrypt
- (void)doencrypt:(NSArray *)array;
- (void)dodecrypt;

// Perform IBC Encryption. This mixes up the bytes before doing an AES Encryption on it.
- (NSString *)IBCEncryption:(NSString *)deviceId
                   userCode:(NSString *)userCode
                   authCode:(NSString *)authCode;

// *bytes must be at least str.length / 2.
+ (BOOL)convertHex:(NSString *)str toBytes:(Byte *)bytes;

+ (NSString*)convertHexToBinary:(NSString*)hexString;

@end

NS_ASSUME_NONNULL_END
