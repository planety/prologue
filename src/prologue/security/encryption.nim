
import nimcrypto,strutils,base64

from ../core/types import SecretKey,len

let cbcIV = "08090A0B0C0D0E0F" #iv: string = "ABCDEF1234123412"






# proc oneShot(message:cstring)=


#     var cbc,dbc : CBC[aes128]
#     var mlen = message.len.uint + 1
#     var decrypted:cstring = newString(mlen)
#     var encrypted:cstring = newString(mlen)

#     cbc.init(key.toOpenArrayByte(0, key.len-1), iv.toOpenArrayByte(0, iv.len-1))
#     cbc.encrypt(cast[ptr byte]( message), cast[ptr byte]( encrypted), mlen)
#     echo encode($encrypted)
#     cbc.clear()
    
#     echo encrypted.len
#     ## Initialization of context one more time
#     cbc.init(key.toOpenArrayByte(0, key.len-1), iv.toOpenArrayByte(0, iv.len-1))
#     cbc.decrypt(cast[ptr byte](encrypted), cast[ptr byte]( decrypted), mlen)
#     echo decrypted

#     ## Do not forget to clear `CBC[aes128]` context
#     cbc.clear()

#     assert decrypted == message


proc encrypt(secret:SecretKey,message:cstring):cstring=
    var 
        cbc : CBC[aes128]
        mlen = message.len.uint
        encrypted:cstring = newString(mlen)
        
    assert secret.len < 17,"aes128 key size is 128 bits or 16 bytes"
    cbc.init(secret.string.toOpenArrayByte(0, secret.string.len-1), cbcIV.toOpenArrayByte(0, cbcIV.len-1))
    cbc.encrypt(cast[ptr byte]( message), cast[ptr byte]( encrypted), mlen)
    
    cbc.clear()
    
    result = toHex($encrypted)

proc decrypt(secret:SecretKey,encrypted:cstring):string=
    var 
        cbc : CBC[aes128]
        len = (encrypted.len * 2).uint
        decrypted:cstring = newString(len)
        enc:cstring = parseHexStr($encrypted)
    
    assert secret.string.len < 17,"aes128 key size is 128 bits or 16 bytes"
    cbc.init(secret.string.toOpenArrayByte(0, secret.string.len-1), cbcIV.toOpenArrayByte(0, cbcIV.len-1))
    cbc.decrypt(cast[ptr byte](enc), cast[ptr byte]( decrypted), len)
    cbc.clear()
    result = $decrypted
  
    
when isMainModule:
    let
        key:string = "1234123412ABCDEF"
        message ="""Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do" #eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.
                            Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaeca 
                            # t cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."""#.strip(true,true,{'\r','\n', '\r','\n', '\f', '\v'})

        enc = encrypt(key.SecretKey,message)
        b64 = encode($enc)
    #echo toHex($enc).len
    #echo message.len
    echo decrypt(key.SecretKey,decode(b64)) 
    #assert decrypt(key.SecretKey,enc,message.len.uint) == message
    
