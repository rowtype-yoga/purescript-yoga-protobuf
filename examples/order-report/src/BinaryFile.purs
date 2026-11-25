-- | Protocol buffer bytes from and to files, on Go.
module BinaryFile (readBytes, writeChunks) where

import Prelude

import Effect (Effect)
import Yoga.Protobuf.Bytes (Bytes)

-- | The whole file. A file that can't be read stops the program.
readBytes :: String -> Effect Bytes
readBytes path = readBytesImpl path

foreign import readBytesImpl :: String -> Effect Bytes

-- | Writes the chunks one after the other, replacing the file.
writeChunks :: String -> Array Bytes -> Effect Unit
writeChunks path chunks = writeChunksImpl path chunks

foreign import writeChunksImpl :: String -> Array Bytes -> Effect Unit
