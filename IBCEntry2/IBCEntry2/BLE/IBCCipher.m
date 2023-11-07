//
//  IBCCipher.m
//  BLE_App
//
//  Created by Nicholas Pisarro on 5/14/22.
//  Copyright © 2022 IBC All rights reserved.
//

#import "IBCCipher.h"

int sbox[256] =   {
//0     1    2      3     4    5     6     7      8    9     A      B    C     D     E     F
0x63, 0x7c, 0x77, 0x7b, 0xf2, 0x6b, 0x6f, 0xc5, 0x30, 0x01, 0x67, 0x2b, 0xfe, 0xd7, 0xab, 0x76, //0
0xca, 0x82, 0xc9, 0x7d, 0xfa, 0x59, 0x47, 0xf0, 0xad, 0xd4, 0xa2, 0xaf, 0x9c, 0xa4, 0x72, 0xc0, //1
0xb7, 0xfd, 0x93, 0x26, 0x36, 0x3f, 0xf7, 0xcc, 0x34, 0xa5, 0xe5, 0xf1, 0x71, 0xd8, 0x31, 0x15, //2
0x04, 0xc7, 0x23, 0xc3, 0x18, 0x96, 0x05, 0x9a, 0x07, 0x12, 0x80, 0xe2, 0xeb, 0x27, 0xb2, 0x75, //3
0x09, 0x83, 0x2c, 0x1a, 0x1b, 0x6e, 0x5a, 0xa0, 0x52, 0x3b, 0xd6, 0xb3, 0x29, 0xe3, 0x2f, 0x84, //4
0x53, 0xd1, 0x00, 0xed, 0x20, 0xfc, 0xb1, 0x5b, 0x6a, 0xcb, 0xbe, 0x39, 0x4a, 0x4c, 0x58, 0xcf, //5
0xd0, 0xef, 0xaa, 0xfb, 0x43, 0x4d, 0x33, 0x85, 0x45, 0xf9, 0x02, 0x7f, 0x50, 0x3c, 0x9f, 0xa8, //6
0x51, 0xa3, 0x40, 0x8f, 0x92, 0x9d, 0x38, 0xf5, 0xbc, 0xb6, 0xda, 0x21, 0x10, 0xff, 0xf3, 0xd2, //7
0xcd, 0x0c, 0x13, 0xec, 0x5f, 0x97, 0x44, 0x17, 0xc4, 0xa7, 0x7e, 0x3d, 0x64, 0x5d, 0x19, 0x73, //8
0x60, 0x81, 0x4f, 0xdc, 0x22, 0x2a, 0x90, 0x88, 0x46, 0xee, 0xb8, 0x14, 0xde, 0x5e, 0x0b, 0xdb, //9
0xe0, 0x32, 0x3a, 0x0a, 0x49, 0x06, 0x24, 0x5c, 0xc2, 0xd3, 0xac, 0x62, 0x91, 0x95, 0xe4, 0x79, //A
0xe7, 0xc8, 0x37, 0x6d, 0x8d, 0xd5, 0x4e, 0xa9, 0x6c, 0x56, 0xf4, 0xea, 0x65, 0x7a, 0xae, 0x08, //B
0xba, 0x78, 0x25, 0x2e, 0x1c, 0xa6, 0xb4, 0xc6, 0xe8, 0xdd, 0x74, 0x1f, 0x4b, 0xbd, 0x8b, 0x8a, //C
0x70, 0x3e, 0xb5, 0x66, 0x48, 0x03, 0xf6, 0x0e, 0x61, 0x35, 0x57, 0xb9, 0x86, 0xc1, 0x1d, 0x9e, //D
0xe1, 0xf8, 0x98, 0x11, 0x69, 0xd9, 0x8e, 0x94, 0x9b, 0x1e, 0x87, 0xe9, 0xce, 0x55, 0x28, 0xdf, //E
0x8c, 0xa1, 0x89, 0x0d, 0xbf, 0xe6, 0x42, 0x68, 0x41, 0x99, 0x2d, 0x0f, 0xb0, 0x54, 0xbb, 0x16 }; //F

// The round constant word array, Rcon[i], contains the values given by
// x to th e power (i-1) being powers of x (x is denoted as {02}) in the field GF(28)
// Note that i starts at 1, not 0).
int Rcon[255] = {
0x8d, 0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80, 0x1b, 0x36, 0x6c, 0xd8, 0xab, 0x4d, 0x9a,
0x2f, 0x5e, 0xbc, 0x63, 0xc6, 0x97, 0x35, 0x6a, 0xd4, 0xb3, 0x7d, 0xfa, 0xef, 0xc5, 0x91, 0x39,
0x72, 0xe4, 0xd3, 0xbd, 0x61, 0xc2, 0x9f, 0x25, 0x4a, 0x94, 0x33, 0x66, 0xcc, 0x83, 0x1d, 0x3a,
0x74, 0xe8, 0xcb, 0x8d, 0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80, 0x1b, 0x36, 0x6c, 0xd8,
0xab, 0x4d, 0x9a, 0x2f, 0x5e, 0xbc, 0x63, 0xc6, 0x97, 0x35, 0x6a, 0xd4, 0xb3, 0x7d, 0xfa, 0xef,
0xc5, 0x91, 0x39, 0x72, 0xe4, 0xd3, 0xbd, 0x61, 0xc2, 0x9f, 0x25, 0x4a, 0x94, 0x33, 0x66, 0xcc,
0x83, 0x1d, 0x3a, 0x74, 0xe8, 0xcb, 0x8d, 0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80, 0x1b,
0x36, 0x6c, 0xd8, 0xab, 0x4d, 0x9a, 0x2f, 0x5e, 0xbc, 0x63, 0xc6, 0x97, 0x35, 0x6a, 0xd4, 0xb3,
0x7d, 0xfa, 0xef, 0xc5, 0x91, 0x39, 0x72, 0xe4, 0xd3, 0xbd, 0x61, 0xc2, 0x9f, 0x25, 0x4a, 0x94,
0x33, 0x66, 0xcc, 0x83, 0x1d, 0x3a, 0x74, 0xe8, 0xcb, 0x8d, 0x01, 0x02, 0x04, 0x08, 0x10, 0x20,
0x40, 0x80, 0x1b, 0x36, 0x6c, 0xd8, 0xab, 0x4d, 0x9a, 0x2f, 0x5e, 0xbc, 0x63, 0xc6, 0x97, 0x35,
0x6a, 0xd4, 0xb3, 0x7d, 0xfa, 0xef, 0xc5, 0x91, 0x39, 0x72, 0xe4, 0xd3, 0xbd, 0x61, 0xc2, 0x9f,
0x25, 0x4a, 0x94, 0x33, 0x66, 0xcc, 0x83, 0x1d, 0x3a, 0x74, 0xe8, 0xcb, 0x8d, 0x01, 0x02, 0x04,
0x08, 0x10, 0x20, 0x40, 0x80, 0x1b, 0x36, 0x6c, 0xd8, 0xab, 0x4d, 0x9a, 0x2f, 0x5e, 0xbc, 0x63,
0xc6, 0x97, 0x35, 0x6a, 0xd4, 0xb3, 0x7d, 0xfa, 0xef, 0xc5, 0x91, 0x39, 0x72, 0xe4, 0xd3, 0xbd,
0x61, 0xc2, 0x9f, 0x25, 0x4a, 0x94, 0x33, 0x66, 0xcc, 0x83, 0x1d, 0x3a, 0x74, 0xe8, 0xcb  };

int rsbox[256] = {
0x52, 0x09, 0x6a, 0xd5, 0x30, 0x36, 0xa5, 0x38, 0xbf, 0x40, 0xa3, 0x9e, 0x81, 0xf3, 0xd7, 0xfb,
0x7c, 0xe3, 0x39, 0x82, 0x9b, 0x2f, 0xff, 0x87, 0x34, 0x8e, 0x43, 0x44, 0xc4, 0xde, 0xe9, 0xcb,
0x54, 0x7b, 0x94, 0x32, 0xa6, 0xc2, 0x23, 0x3d, 0xee, 0x4c, 0x95, 0x0b, 0x42, 0xfa, 0xc3, 0x4e,
0x08, 0x2e, 0xa1, 0x66, 0x28, 0xd9, 0x24, 0xb2, 0x76, 0x5b, 0xa2, 0x49, 0x6d, 0x8b, 0xd1, 0x25,
0x72, 0xf8, 0xf6, 0x64, 0x86, 0x68, 0x98, 0x16, 0xd4, 0xa4, 0x5c, 0xcc, 0x5d, 0x65, 0xb6, 0x92,
0x6c, 0x70, 0x48, 0x50, 0xfd, 0xed, 0xb9, 0xda, 0x5e, 0x15, 0x46, 0x57, 0xa7, 0x8d, 0x9d, 0x84,
0x90, 0xd8, 0xab, 0x00, 0x8c, 0xbc, 0xd3, 0x0a, 0xf7, 0xe4, 0x58, 0x05, 0xb8, 0xb3, 0x45, 0x06,
0xd0, 0x2c, 0x1e, 0x8f, 0xca, 0x3f, 0x0f, 0x02, 0xc1, 0xaf, 0xbd, 0x03, 0x01, 0x13, 0x8a, 0x6b,
0x3a, 0x91, 0x11, 0x41, 0x4f, 0x67, 0xdc, 0xea, 0x97, 0xf2, 0xcf, 0xce, 0xf0, 0xb4, 0xe6, 0x73,
0x96, 0xac, 0x74, 0x22, 0xe7, 0xad, 0x35, 0x85, 0xe2, 0xf9, 0x37, 0xe8, 0x1c, 0x75, 0xdf, 0x6e,
0x47, 0xf1, 0x1a, 0x71, 0x1d, 0x29, 0xc5, 0x89, 0x6f, 0xb7, 0x62, 0x0e, 0xaa, 0x18, 0xbe, 0x1b,
0xfc, 0x56, 0x3e, 0x4b, 0xc6, 0xd2, 0x79, 0x20, 0x9a, 0xdb, 0xc0, 0xfe, 0x78, 0xcd, 0x5a, 0xf4,
0x1f, 0xdd, 0xa8, 0x33, 0x88, 0x07, 0xc7, 0x31, 0xb1, 0x12, 0x10, 0x59, 0x27, 0x80, 0xec, 0x5f,
0x60, 0x51, 0x7f, 0xa9, 0x19, 0xb5, 0x4a, 0x0d, 0x2d, 0xe5, 0x7a, 0x9f, 0x93, 0xc9, 0x9c, 0xef,
0xa0, 0xe0, 0x3b, 0x4d, 0xae, 0x2a, 0xf5, 0xb0, 0xc8, 0xeb, 0xbb, 0x3c, 0x83, 0x53, 0x99, 0x61,
0x17, 0x2b, 0x04, 0x7e, 0xba, 0x77, 0xd6, 0x26, 0xe1, 0x69, 0x14, 0x63, 0x55, 0x21, 0x0c, 0x7d };

@implementation IBCCipher

- (unsigned char *)ConvertedAuthKey_objectiveC
{
    return ConvertedAuthKey_objectiveC;
}
- (char *)convertedC
{
    return convertedC;
}

- (int)getSBoxValue:(int)num
{
    return sbox[num];
}

- (int)getSBoxInvert:(int)num
{
    return rsbox[num];
}

- (void)KeyExpansion
{
    int i,j;
    unsigned char temp[4],k;
    
    // The first round key is the key itself.
    for(i=0;i<Nk;i++)
    {
        RoundKey[i*4]=Key[i*4];
        RoundKey[i*4+1]=Key[i*4+1];
        RoundKey[i*4+2]=Key[i*4+2];
        RoundKey[i*4+3]=Key[i*4+3];
    }
    
    // All other round keys are found from the previous round keys.
    while (i < (Nb * (Nr+1)))
    {
        for(j=0;j<4;j++)
        {
            temp[j]=RoundKey[(i-1) * 4 + j];
        }
        if (i % Nk == 0)
        {
            // This function rotates the 4 bytes in a word to the left once.
            // [a0,a1,a2,a3] becomes [a1,a2,a3,a0]
            
            // Function RotWord()
            {
                k = temp[0];
                temp[0] = temp[1];
                temp[1] = temp[2];
                temp[2] = temp[3];
                temp[3] = k;
            }
            
            // SubWord() is a function that takes a four-byte input word and
            // applies the S-box to each of the four bytes to produce an output word.
            
            // Function Subword()
            {
                temp[0] = [self getSBoxValue:temp[0]];
                temp[1] = [self getSBoxValue:temp[1]];
                temp[2] = [self getSBoxValue:temp[2]];
                temp[3] = [self getSBoxValue:temp[3]];
            }
            
            temp[0] =  temp[0] ^ Rcon[i/Nk];
        }
        else if (Nk > 6 && i % Nk == 4)
        {
            // Function Subword()
            {
                temp[0] = [self getSBoxValue:temp[0]];
                temp[1] = [self getSBoxValue:temp[1]];
                temp[2] = [self getSBoxValue:temp[2]];
                temp[3] = [self getSBoxValue:temp[3]];
            }
        }
        RoundKey[i*4+0] = RoundKey[(i-Nk)*4+0] ^ temp[0];
        RoundKey[i*4+1] = RoundKey[(i-Nk)*4+1] ^ temp[1];
        RoundKey[i*4+2] = RoundKey[(i-Nk)*4+2] ^ temp[2];
        RoundKey[i*4+3] = RoundKey[(i-Nk)*4+3] ^ temp[3];
        i++;
    }
}

// This function adds the round key to state.
// The round key is added to the state by an XOR function.
- (void)AddRoundKey:(int)round
{
    int i,j;
    for(i=0;i<4;i++)
    {
        for(j=0;j<4;j++)
        {
            state[j][i] ^= RoundKey[round * Nb * 4 + i * Nb + j];
        }
    }
}

// The SubBytes Function Substitutes the values in the
// state matrix with values in an S-box.
-(void)SubBytes
{
    int i,j;
    for(i=0;i<4;i++)
    {
        for(j=0;j<4;j++)
        {
            state[i][j] = [self getSBoxValue:state[i][j]];
            
        }
    }
}

// The ShiftRows() function shifts the rows in the state to the left.
// Each row is shifted with different offset.
// Offset = Row number. So the first row is not shifted.
- (void)ShiftRows
{
    unsigned char temp;
    
    // Rotate first row 1 columns to left
    temp=state[1][0];
    state[1][0]=state[1][1];
    state[1][1]=state[1][2];
    state[1][2]=state[1][3];
    state[1][3]=temp;
    
    // Rotate second row 2 columns to left
    temp=state[2][0];
    state[2][0]=state[2][2];
    state[2][2]=temp;
    
    temp=state[2][1];
    state[2][1]=state[2][3];
    state[2][3]=temp;
    
    // Rotate third row 3 columns to left
    temp=state[3][0];
    state[3][0]=state[3][3];
    state[3][3]=state[3][2];
    state[3][2]=state[3][1];
    state[3][1]=temp;
}
// MixColumns function mixes the columns of the state matrix
// The method used may look complicated, but it is easy if you know the underlying theory.
// Refer the documents specified above.
-(void)MixColumns
{
    int i;
    unsigned char Tmp,Tm,t;
    for(i=0;i<4;i++)
    {
        t=state[0][i];
        Tmp = state[0][i] ^ state[1][i] ^ state[2][i] ^ state[3][i] ;
        Tm = state[0][i] ^ state[1][i] ; Tm = xtime(Tm); state[0][i] ^= Tm ^ Tmp ;
        Tm = state[1][i] ^ state[2][i] ; Tm = xtime(Tm); state[1][i] ^= Tm ^ Tmp ;
        Tm = state[2][i] ^ state[3][i] ; Tm = xtime(Tm); state[2][i] ^= Tm ^ Tmp ;
        Tm = state[3][i] ^ t ; Tm = xtime(Tm); state[3][i] ^= Tm ^ Tmp ;
    }
}

// The SubBytes Function Substitutes the values in the
// state matrix with values in an S-box.
- (void)InvSubBytes
{
    int i,j;
    for(i=0;i<4;i++)
    {
        for(j=0;j<4;j++)
        {
            state[i][j] = [self getSBoxInvert:state[i][j]];
        }
    }
}

// The ShiftRows() function shifts the rows in the state to the left.
// Each row is shifted with different offset.
// Offset = Row number. So the first row is not shifted.
- (void)InvShiftRows
{
    unsigned char temp;
    
    // Rotate first row 1 columns to right
    temp=state[1][3];
    state[1][3]=state[1][2];
    state[1][2]=state[1][1];
    state[1][1]=state[1][0];
    state[1][0]=temp;
    
    // Rotate second row 2 columns to right
    temp=state[2][0];
    state[2][0]=state[2][2];
    state[2][2]=temp;
    
    temp=state[2][1];
    state[2][1]=state[2][3];
    state[2][3]=temp;
    
    // Rotate third row 3 columns to right
    temp=state[3][0];
    state[3][0]=state[3][1];
    state[3][1]=state[3][2];
    state[3][2]=state[3][3];
    state[3][3]=temp;
}

// MixColumns function mixes the columns of the state matrix.
// The method used to multiply may be difficult to understand for beginners.
// Please use the references to gain more information.
- (void)InvMixColumns
{
    int i;
    unsigned char a,b,c,d;
    for(i=0;i<4;i++)
    {
        
        a = state[0][i];
        b = state[1][i];
        c = state[2][i];
        d = state[3][i];
        
        
        state[0][i] = Multiply(a, 0x0e) ^ Multiply(b, 0x0b) ^ Multiply(c, 0x0d) ^ Multiply(d, 0x09);
        state[1][i] = Multiply(a, 0x09) ^ Multiply(b, 0x0e) ^ Multiply(c, 0x0b) ^ Multiply(d, 0x0d);
        state[2][i] = Multiply(a, 0x0d) ^ Multiply(b, 0x09) ^ Multiply(c, 0x0e) ^ Multiply(d, 0x0b);
        state[3][i] = Multiply(a, 0x0b) ^ Multiply(b, 0x0d) ^ Multiply(c, 0x09) ^ Multiply(d, 0x0e);
    }
}

// InvCipher is the main function that decrypts the CipherText.
- (void)InvCipher
{
    int i,j,round=0;
    
    //Copy the input CipherText to state array.
    for(i=0;i<4;i++)
    {
        for(j=0;j<4;j++)
        {
            state[j][i] = Data[i*4 + j];
        }
    }
    
    // Add the First round key to the state before starting the rounds.
    [self AddRoundKey:Nr];
    
    
    
    // There will be Nr rounds.
    // The first Nr-1 rounds are identical.
    // These Nr-1 rounds are executed in the loop below.
    for(round=Nr-1;round>0;round--)
    {
        [self InvShiftRows];
        [self InvSubBytes];
        [self AddRoundKey:round];
        [self InvMixColumns];
    }
    
    // The last round is given below.
    // The MixColumns function is not here in the last round.
    [self InvShiftRows];
    [self InvSubBytes];
    [self AddRoundKey:0];
    
    // The decryption process is over.
    // Copy the state array to output array.
    for(i=0;i<4;i++)
    {
        for(j=0;j<4;j++)
        {
            output[i*4+j]=state[j][i];
        }
    }
}

- (void)keymakerMaethod1:(NSArray *)array
{
    unsigned holder;
    for (int i = 0; i < array.count; ++i) {
        sscanf([[array objectAtIndex:i] UTF8String], "%x", &holder);
        authkey[i] = holder; /* same thing */
    }
    
    printf("%s\n", Key);
}

- (void)AuthAlgorithm

{
    temp1=authkey[0]*4; // 196
    temp1=temp1+authkey[5]; // 250
    newkey2=temp1; // 250
    ConvertedAuthKey[1]=newkey2;


    temp1=authkey[1]; // 50
    temp2=authkey[2]+3; // 54
    temp3=authkey[7]*16; // 128
    newkey0=temp1+temp2+temp3; // 232
    ConvertedAuthKey[0]=newkey0;
    
    temp1=authkey[3]*2; // 104
    temp1=temp1+authkey[4]; // 157
    newkey13=temp1;
    ConvertedAuthKey[3]=newkey13;

    temp1=authkey[1]; // 50
    temp2=authkey[6]+2; // 57
    temp1=temp1+temp2; // 107
    newkey7=temp1;
    ConvertedAuthKey[2]=newkey7;
}

- (int)getConverted_auth
{

    
    //    unsigned char buffer[bufferSize]={1,2,3,4,5,6,7,8,9,10};
    char converted[bufferSize*2 + 1];
    int i;
    
    for(i=0;i<bufferSize;i++)
    {
        sprintf(&converted[i*2], "%02X", ConvertedAuthKey[i]);
        
        /* equivalent using snprintf, notice len field keeps reducing
         with each pass, to prevent overruns
         
         snprintf(&converted[i*2], sizeof(converted)-(i*2),"%02X", buffer[i]);
         */
        
    }
    printf("%s\n", converted);
    size_t destination_size = sizeof (ConvertedAuthKey_objectiveC);
    
    strncpy(ConvertedAuthKey_objectiveC, converted, destination_size);
    ConvertedAuthKey_objectiveC[destination_size - 1] = '\0';
    
    
    return 0;
}

- (int)getConverted
{
    
    //    unsigned char buffer[bufferSize]={1,2,3,4,5,6,7,8,9,10};
    char converted[bufferSize2*2 + 1];
    int i;
    
    for(i=0;i<bufferSize2;i++)
    {
        sprintf(&converted[i*2], "%02X", output[i]);
        
        /* equivalent using snprintf, notice len field keeps reducing
         with each pass, to prevent overruns
         
         snprintf(&converted[i*2], sizeof(converted)-(i*2),"%02X", buffer[i]);
         */
        
    }
    printf("%s\n", converted);
    size_t destination_size = sizeof (convertedC);
    
    strncpy(convertedC, converted, destination_size);
    convertedC[destination_size - 1] = '\0';
    
    return 0;
}

// Cipher is the main function that encrypts the PlainText.
- (void)Cipher
{
    
    int i,j,round=0;
    
    //Copy the input PlainText to state array.
    for(i=0;i<4;i++)
    {
        for(j=0;j<4;j++)
        {
            state[j][i] = Data[i*4 + j];
        }
    }
    
    // Add the First round key to the state before starting the rounds.
    [self AddRoundKey:0];
    
    // There will be Nr rounds.
    // The first Nr-1 rounds are identical.
    // These Nr-1 rounds are executed in the loop below.
    for(round=1;round<Nr;round++)
    {
        [self SubBytes];
        [self ShiftRows];
        [self MixColumns];
        [self AddRoundKey:round];
    }
    
    // The last round is given below.
    // The MixColumns function is not here in the last round.
    [self SubBytes];
    [self ShiftRows];
    [self AddRoundKey:Nr];
    
    // The encryption process is over.
    // Copy the state array to output array.
    for(i=0;i<4;i++)
    {
        for(j=0;j<4;j++)
        {
            output[i*4+j]=state[j][i];
        }
    }
    printf("%s",output);
    [self getConverted];
}

- (char * _Nullable *)cArrayFromNSArray:(NSArray *)array
{
    int i, count = (int)array.count;
    char **cargs = (char**) malloc(sizeof(char*) * (count + 1));
    for(i = 0; i < count; i++) {        //cargs is a pointer to 4 pointers to char
        NSString *s      = array[i];     //get a NSString
        const char *cstr = s.UTF8String; //get cstring
        int          len = (int)strlen(cstr); //get its length
        char  *cstr_copy = (char*) malloc(sizeof(char) * (len + 1));//allocate memory, + 1 for ending '\0'
        strcpy(cstr_copy, cstr);         //make a copy
        cargs[i] = cstr_copy;            //put the point in cargs
    }
    cargs[i] = NULL;
    size_t destination_size = sizeof (Data);
    
    strncpy(Data, *cargs, destination_size);
    convertedC[destination_size - 1] = '\0';
    return cargs;
}

- (void)keymakerMaethod:(NSArray *)array
{
    unsigned holder;
    for (int i = 0; i < array.count; ++i) {
        sscanf([[array objectAtIndex:i] UTF8String], "%x", &holder);
        Key[i] = holder; /* same thing */
    }
    
    printf("%s\n", Key);
}


// doencrypt - call this routine to encrypt
-(void)doencrypt:(NSArray *)array
{
    //    int i;
    unsigned holder;
    for (int i = 0; i < array.count; ++i) {
        sscanf([[array objectAtIndex:i] UTF8String], "%x", &holder);
        Data[i] = holder; /* same thing */
    }
    printf("%s\n", Data);
    
    Nr=128;
    Nk = Nr / 32;
    Nr = Nk + 6;
    
    
    // The KeyExpansion routine must be called before encryption.
    [self KeyExpansion];
    
    // The next function call encrypts the PlainText with the Key using AES algorithm.
    [self Cipher];
    
}

- (void)dodecrypt
{
    int i;
    
    for(i=0;i<16;i++)
    {
        Data[i]=output[i];
    }
    
    Nr=128;
    Nk = Nr / 32;
    Nr = Nk + 6;
    
    // The KeyExpansion routine must be called before encryption.
    [self KeyExpansion];
    
    // The next function call encrypts the PlainText with the Key using AES algorithm.
    [self InvCipher];
}

// ******** Converting to Hexa from string *******************
+ (NSString *) stringToHex:(NSString *)str
{
    NSUInteger len = [str length];
    unichar *chars = malloc(len * sizeof(unichar));
    [str getCharacters:chars];
    NSMutableString *hexString = [[NSMutableString alloc] init];
    
    for(NSUInteger i = 0; i < len; i++ )
    {
        // [hexString [NSString stringWithFormat:@"%02x", chars[i]]]; /*previous input*/
        [hexString appendFormat:@"%02x", chars[i]]; /*EDITED PER COMMENT BELOW*/
    }
    
    free(chars);
    
    return hexString;
}

- (NSString *)IBCEncryption:(NSString *)deviceId
                   userCode:(NSString *)userCode
                   authCode:(NSString *)authCode
{
    //Device id to 16 bit
    NSMutableArray *arrayFor_deviceId = [NSMutableArray array];
    for (int i = 0; i < 32; i += 2)
    {
        [arrayFor_deviceId addObject:[NSString stringWithFormat:@"%C%C", [deviceId characterAtIndex:i],[deviceId characterAtIndex:i+1]]];
    }
    
    // ***** Kludge! *****
    // If an 8 character password, pad it out as "sdpppppppp00"
    NSString *stringUserID;
    if (userCode.length == 8)
        stringUserID = [NSString stringWithFormat:@"cd%@00",userCode];
    else if (userCode.length != 12)
        NSLog(@"Invallid User Code: '%@'", userCode);
    else
        stringUserID = userCode;
    
    NSMutableArray *array_userCode = [[NSMutableArray alloc] initWithCapacity:stringUserID.length];
    for (int i=0; i < [stringUserID length]; i++) {
        NSString *ichar  = [NSString stringWithFormat:@"%c", [stringUserID characterAtIndex:i]];
        [array_userCode addObject:ichar];
    }
    
    NSLog(@"%@",array_userCode);

    //AES statis key
    NSMutableArray *aes_Key_Static;

    // If an authCode is supplied, converted to an AuthKey, else use a canned value.
    if (authCode.length > 0)
    {
        NSMutableArray *array_statisAesKey = [[NSMutableArray alloc] initWithCapacity:[authCode length]];
        
        for (int i=0; i < authCode.length; i++)
        {
            NSString *ichar  = [NSString stringWithFormat:@"%c", [authCode characterAtIndex:i]];
            [array_statisAesKey addObject:ichar];
        }
        
        for (int i = 0; i<[array_statisAesKey count]; i++)
        {
            NSString * stringValue =[array_statisAesKey objectAtIndex:i];
            NSString *str2 = [NSString stringWithFormat:@"0x%02x", [stringValue characterAtIndex:0]];
            [array_statisAesKey replaceObjectAtIndex:i withObject:str2];
        }
        
        NSArray * arrayAuth =array_statisAesKey;
        [self keymakerMaethod1:arrayAuth];
        [self AuthAlgorithm];
        [self getConverted_auth];
        NSString * stringconveted1 =[NSString stringWithFormat:@"%s" , self.ConvertedAuthKey_objectiveC];
        
        NSString *final_string2  =[NSString stringWithFormat:@"%@\r", stringconveted1];

        aes_Key_Static = [[NSMutableArray alloc] initWithObjects:@"A1",@"20",@"49",@"F7",@"E8",@"9F",@"7D",@"55",@"C3",@"AA",@"39",@"87",@"2E",@"30",@"7E",@"18", nil];
        
        NSString *subString0 = [final_string2 substringWithRange:NSMakeRange(0,2)];
        NSString *subString2 = [final_string2 substringWithRange:NSMakeRange(2,2)];
        NSString *subString7 = [final_string2 substringWithRange:NSMakeRange(4,2)];
        NSString *subString13 = [final_string2 substringWithRange:NSMakeRange(6,2)];


        [aes_Key_Static replaceObjectAtIndex:0 withObject:subString0];
        [aes_Key_Static replaceObjectAtIndex:2 withObject:subString2];
        [aes_Key_Static replaceObjectAtIndex:7 withObject:subString7];
        [aes_Key_Static replaceObjectAtIndex:13 withObject:subString13];

    }
    
    // No Auth Code provided, use a canned value.
    else
    {
        aes_Key_Static = [[NSMutableArray alloc] initWithObjects:@"A1",@"20",@"49",@"F7",@"E8",@"9F",@"7D",@"55",@"C3",@"AA",@"39",@"87",@"2E",@"30",@"7E",@"18", nil];

    }

    //Modified AES key
    NSMutableArray * newModifiedAESkey =[[NSMutableArray alloc] initWithArray:aes_Key_Static];
    
    [newModifiedAESkey replaceObjectAtIndex:3 withObject:[arrayFor_deviceId objectAtIndex:3]];
    [newModifiedAESkey replaceObjectAtIndex:5 withObject:[arrayFor_deviceId objectAtIndex:5]];
    [newModifiedAESkey replaceObjectAtIndex:9 withObject:[arrayFor_deviceId objectAtIndex:9]];
    
    NSLog(@"Modified AES Key: %@",newModifiedAESkey);
    
    
    for (int i = 0; i<32; i++)
    {
        if (i < 16)
        {
            NSString * stringHexa =[NSString stringWithFormat:@"0x%@  ",[newModifiedAESkey objectAtIndex:i]];
            [newModifiedAESkey replaceObjectAtIndex:i withObject:stringHexa];
            
        }
        else
        {
            NSString * stringHexa =@"0x00  ";
            
            [newModifiedAESkey addObject:stringHexa];
        }
        
    }
    
    NSLog(@"%@",newModifiedAESkey);
    
    //New Array from user code and Device ID
    NSMutableArray *newArray =[[NSMutableArray alloc] init];
    
    [newArray addObject:[arrayFor_deviceId objectAtIndex:3]];       //  0
    [newArray addObject:[array_userCode objectAtIndex:0]];          //  1
    [newArray addObject:[array_userCode objectAtIndex:1]];          //  2
    [newArray addObject:[arrayFor_deviceId objectAtIndex:2]];       //  3
    [newArray addObject:[array_userCode objectAtIndex:2]];          //  4
    [newArray addObject:[array_userCode objectAtIndex:3]];          //  5
    [newArray addObject:[array_userCode objectAtIndex:4]];          //  6
    [newArray addObject:[array_userCode objectAtIndex:5]];          //  7
    [newArray addObject:[arrayFor_deviceId objectAtIndex:15]];      //  8
    [newArray addObject:[array_userCode objectAtIndex:6]];          //  9
    [newArray addObject:[array_userCode objectAtIndex:7]];          // 10
    [newArray addObject:[array_userCode objectAtIndex:8]];          // 11
    [newArray addObject:[arrayFor_deviceId objectAtIndex:8]];       // 12
    [newArray addObject:[array_userCode objectAtIndex:9]];          // 13
    [newArray addObject:[array_userCode objectAtIndex:10]];         // 14
    [newArray addObject:[array_userCode objectAtIndex:11]];         // 15
    
    
    for (int i = 0; i<[newArray count]; i++)
    {
        if ([[newArray objectAtIndex:i] length]<2) {
            NSLog(@"%d",i);
            NSString * stringHExaConvert = [IBCCipher stringToHex:[newArray objectAtIndex:i]];
            NSLog(@"hexa value%@",stringHExaConvert);
            
            [newArray replaceObjectAtIndex:i withObject:stringHExaConvert];
        }
        
        NSString * stringHexa =[NSString stringWithFormat:@"0x%@  ",[newArray objectAtIndex:i]];
        [newArray replaceObjectAtIndex:i withObject:stringHexa];
    }
    
    NSLog(@"NEW ARRAY CREATED:%@",newArray);
    
    NSMutableString *_string_Modified_AES_key  =[[NSMutableString alloc]init];
    for(int i= 0; i<[newModifiedAESkey count]; i++)
    {
        [_string_Modified_AES_key appendFormat:@"%@",[newModifiedAESkey objectAtIndex:i]];
    }
    NSLog(@"_string = %@",_string_Modified_AES_key);
    
    NSArray *imputData_Array = newArray;
    NSArray *arrayKey = newModifiedAESkey;
    
    [self keymakerMaethod:arrayKey];
    
    //Encryption method call:- c class
    [self doencrypt:imputData_Array];
    
    return [NSString stringWithFormat:@"%s" , self.convertedC];
}

// Convert '0xhh' to unsigned integer. (Use this instead of 'scanf'?)
+ (unsigned)oXConvert:(NSString *)arg
{
    if (arg.length != 4 || ![[arg substringToIndex:2] isEqual:@"0x"])
        return 1000000;
    
    Byte result[1];
    [IBCCipher convertHex:[arg substringFromIndex:2] toBytes:result];
    
    return result[0];
}

// *bytes must be at least str.length / 2.
+ (BOOL)convertHex:(NSString *)str toBytes:(Byte *)bytes
{
    // We can only deal with pairs of bytes.
    if ((str.length & 1) != 0 && ! [[str substringFromIndex:str.length - 1] isEqual:@"\r"])
        return FALSE;
    
    int wkgLength = (int) str.length >> 1;
    
    for (int i = 0; i < wkgLength; ++i)
    {
        unichar temp;
        
        *(bytes + i) = 0;
        for (int j = 0; j < 2; ++j)
        {
            temp = [str characterAtIndex:(i * 2) + j];
            
            if (temp >= 'a' && temp <= 'f') 
                temp = temp - 'a' + 10;
            else if (temp >= 'A' && temp <= 'F') 
                temp = temp - 'A' + 10;
            else  if (temp >= '0' && temp <= '9')
              temp = temp - '0';
            else
                return FALSE;
            
            *(bytes + i) = (*(bytes + i) << 4) | temp;
        }
    }
    
    return TRUE;
}

+ (NSString*)convertHexToBinary:(NSString*)hexString
{
    NSMutableString *returnString = [NSMutableString string];
    for(int i = 0; i < [hexString length]; i++)
    {
        char c = [[hexString lowercaseString] characterAtIndex:i];
        
        switch(c) {
            case '0': [returnString appendString:@"0000"]; break;
            case '1': [returnString appendString:@"0001"]; break;
            case '2': [returnString appendString:@"0010"]; break;
            case '3': [returnString appendString:@"0011"]; break;
            case '4': [returnString appendString:@"0100"]; break;
            case '5': [returnString appendString:@"0101"]; break;
            case '6': [returnString appendString:@"0110"]; break;
            case '7': [returnString appendString:@"0111"]; break;
            case '8': [returnString appendString:@"1000"]; break;
            case '9': [returnString appendString:@"1001"]; break;
            case 'a': [returnString appendString:@"1010"]; break;
            case 'b': [returnString appendString:@"1011"]; break;
            case 'c': [returnString appendString:@"1100"]; break;
            case 'd': [returnString appendString:@"1101"]; break;
            case 'e': [returnString appendString:@"1110"]; break;
            case 'f': [returnString appendString:@"1111"]; break;
            default : break;
        }
    }
    
    return returnString;
}

@end
