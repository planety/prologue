
import nimcrypto,strutils



proc encrypt*(secret:string,salt:string,message:cstring):string=
    var 
        cbc : CBC[aes128]
        sc = secret.substr(0,16)
        iv = salt.substr(0,16)
        mlen = message.len.uint
        encrypted:cstring = newString(mlen)
        
    #TODO pad key and IV with PKCS7
    cbc.init(sc.toOpenArrayByte(0, sc.len-1), iv.toOpenArrayByte(0, iv.len-1))
    cbc.encrypt(cast[ptr byte]( message), cast[ptr byte]( encrypted), mlen)
    
    cbc.clear()
    
    result = toHex($encrypted)

proc decrypt*(secret:string,salt:string,encrypted:cstring):string=
    var 
        cbc : CBC[aes128]
        sc = secret.substr(0,16)
        iv = salt.substr(0,16)
        len = (encrypted.len * 2).uint
        decrypted:cstring = newString(len)
        enc:cstring = parseHexStr($encrypted)
    
    #TODO pad key and IV with PKCS7
    cbc.init(sc.toOpenArrayByte(0, sc.len-1), iv.toOpenArrayByte(0, iv.len-1))
    cbc.decrypt(cast[ptr byte](enc), cast[ptr byte]( decrypted), len)
    cbc.clear()
    result = $decrypted
  
    
when isMainModule:
    let
        key = "1234123412ABCDEF"
        salt = "08090A0B0C0D0E0F"

        message ="""Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do" #eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.
                            Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaeca 
                            # t cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."""#.strip(true,true,{'\r','\n', '\r','\n', '\f', '\v'})

        enc = encrypt(key,salt,message)
        dec = decrypt(key,salt,enc) 
    assert dec == message
    
