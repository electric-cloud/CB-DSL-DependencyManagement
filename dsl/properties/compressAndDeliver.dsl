import java.security.MessageDigest
import groovy.json.JsonOutput
import java.util.zip.ZipEntry
import java.util.zip.ZipException
import java.util.zip.ZipOutputStream


int offset = args.offset ?: 0
String source = args.source
int chunkSize = args.chunkSize ?: 2 * 1024 * 1024

File path = new File(source)
File archive = packDependencies(path)

// Reading the file by chunks
RandomAccessFile ra = new RandomAccessFile(archive, "r")

long size = ra.length()
ra.skipBytes(offset)
int remainingBytes = size - offset
if (remainingBytes <= 0) {
    return [
        readBytes: -1
    ]
}
int bufferSize = remainingBytes < chunkSize ? remainingBytes : chunkSize
byte[] b = new byte[bufferSize]

int readBytes = ra.read(b, 0, bufferSize)
int remaining = size - offset - bufferSize

return [
    chunk: b.encodeBase64().toString(),
    readBytes: readBytes,
    remaining: remaining
]

// List<String> files = args.files
// String source = args.source
// int startWithFile = args.startWithFile ?: 0



// List<String> chunk = []
// int size = 0
// int i = startWithFile
// while(size < chunkSize && i < files.size()) {
//     String fileName = files[i]
//     File f = new File(path, fileName)
//     if (f.exists()) {
//         byte[] b = f.bytes
//         size += b.size()
//         chunk.add(b.encodeBase64().toString())
//     }
//     else {
//         throw new RuntimeException("File $f.absolutePath does not exist")
//     }
//     i++
// }

// return [
//     chunk: chunk
// ]


File packDependencies(File agentFolder) {
    if (!agentFolder.exists()) {
        throw new RuntimeException("The agent folder $agentFolder does not exist")
    }
    // We literally do not care for concurrency at this point, just assuming that it will probably write something
    // Also, try .. catch in DSL is kinda broken
    // And looks like lock() does not work either
    File output = new File(agentFolder, ".cbDependencies.zip")

    if (output.exists()) {
        return output
    }
    ZipOutputStream zipFile = new ZipOutputStream(new FileOutputStream(output))
    agentFolder.eachFileRecurse { File file ->
        if (!file.isDirectory() && !file.name.startsWith('.')) {
            def relative = agentFolder.toPath().relativize(file.toPath())
            try {
                zipFile.putNextEntry(new ZipEntry(relative.toString()))
                def buffer = new byte[file.size()]
                file.withInputStream {
                    zipFile.write(buffer, 0, it.read(buffer))
                }
                zipFile.closeEntry()
            } catch (ZipException e) {
                throw e
            }
        }
    }
    zipFile.close()
    return output
}


