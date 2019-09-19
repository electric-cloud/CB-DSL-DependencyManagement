import java.security.MessageDigest
import groovy.json.JsonOutput


List<String> files = args.files
String source = args.source
int startWithFile = args.startWithFile ?: 0
int chunkSize = args.chunkSize ?: 2 * 1024 * 1024

File path = new File(source)

List<String> chunk = []
int size = 0
int i = startWithFile
while(size < chunkSize && i < files.size()) {
    String fileName = files[i]
    File f = new File(path, fileName)
    if (f.exists()) {
        byte[] b = f.bytes
        size += b.size()
        chunk.add(b.encodeBase64().toString())
    }
    else {
        throw new RuntimeException("File $f.absolutePath does not exist")
    }
    i++
}

return [
    chunk: chunk
]

// Older version of Groovy does not have String.md5()
String generateMD5(byte[] bytes) {
    MessageDigest digest = MessageDigest.getInstance("MD5")
    digest.update(bytes)
    byte[] md5sum = digest.digest()
    BigInteger bigInt = new BigInteger(1, md5sum)
    return bigInt.toString(16).padLeft(32, '0')
}
