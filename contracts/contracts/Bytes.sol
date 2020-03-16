pragma solidity 0.5.16;


library Bytes {

    function toBytesFromUInt16(uint16 self) internal pure returns (bytes memory bts) {
        bts = toBytesFromBytes32(bytes32(uint(self) << 240), 2);
    }

    function toBytesFromUInt24(uint24 self) internal pure returns (bytes memory bts) {
        bts = toBytesFromBytes32(bytes32(uint(self) << 232), 3);
    }

    function toBytesFromUInt32(uint32 self) internal pure returns (bytes memory bts) {
        bts = toBytesFromBytes32(bytes32(uint(self) << 224), 4);
    }

    function toBytesFromUInt128(uint128 self) internal pure returns (bytes memory bts) {
        bts = toBytesFromBytes32(bytes32(uint(self) << 128), 16);
    }

    // Copies 'len' bytes from 'self' into a new 'bytes memory', starting at index '0'.
    // Returns the newly created 'bytes memory'. The returned bytes will be of length 'len'.
    function toBytesFromBytes32(bytes32 self, uint8 len) internal pure returns (bytes memory bts) {
        require(len <= 32, "bt211");
        bts = new bytes(len);
        // Even though the bytes will allocate a full word, we don't want
        // any potential garbage bytes in there.
        uint data = uint(self) & ~uint(0) << (32 - len)*8;
        assembly {
            mstore(add(bts, /*BYTES_HEADER_SIZE*/32), data)
        }
    }

    // Copies 'self' into a new 'bytes memory'.
    // Returns the newly created 'bytes memory'. The returned bytes will be of length '20'.
    function toBytesFromAddress(address self) internal pure returns (bytes memory bts) {
        bts = toBytesFromBytes32(bytes32(uint(self) << 96), 20);
    }

    function bytesToAddress(bytes memory self) internal pure returns (address addr) {
        require(self.length >= 20, "bbs11");
        assembly {
            addr := div(mload(add(add(self, 0x20), 0)), 0x1000000000000000000000000)
        }
    }

    function bytesToUInt16(bytes memory self) internal pure returns (uint16 r) {
        require(self.length >= 2, "bb611");
        assembly {
            r := mload(add(add(self, 0x2), 0))
        }
    }

    function bytesToUInt24(bytes memory self) internal pure returns (uint24 r) {
        require(self.length >= 3, "bb411");
        assembly {
            r := mload(add(add(self, 0x3), 0))
        }
    }

    function bytesToUInt32(bytes memory self) internal pure returns (uint32 r) {
        require(self.length >= 4, "bb411");
        assembly {
            r := mload(add(add(self, 0x4), 0))
        }
    }

    function bytesToUInt128(bytes memory self) internal pure returns (uint128 r)
    {
        require(self.length >= 16, "bb811");
        assembly {
            r := mload(add(add(self, 0x10), 0))
        }
    }

    function bytesToBytes32(bytes memory  _input) internal pure returns (bytes32 _output) {
        for (uint i = 0; i < 32; i++) {
            _output |= bytes32(_input[i]) >> (i * 8);
        }
    }

    // Original source code: https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol#L228
    // Get slice from bytes arrays
    // Returns the newly created 'bytes memory'
    function slice(
        bytes memory _bytes,
        uint _start,
        uint _length
    )
        internal
        pure
        returns (bytes memory)
    {
        require(_bytes.length >= (_start + _length), "bse11"); // bytes length is less then start byte + length bytes

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    /// Reads byte stream
    /// @return new_offset - offset + amount of bytes read
    /// @return data - actually read data
    function read(bytes memory _data, uint _offset, uint _length) internal pure returns (uint new_offset, bytes memory data) {
        data = slice(_data, _offset, _length);
        new_offset = _offset + _length;
    }

    function readUInt16(bytes memory _data, uint _offset) internal pure returns (uint new_offset, uint16 r) {
        bytes memory buf;
        (new_offset, buf) = read(_data, _offset, 2);
        r = bytesToUInt16(buf);
    }

    function readUInt24(bytes memory _data, uint _offset) internal pure returns (uint new_offset, uint24 r) {
        bytes memory buf;
        (new_offset, buf) = read(_data, _offset, 3);
        r = bytesToUInt24(buf);
    }

    function readUInt32(bytes memory _data, uint _offset) internal pure returns (uint new_offset, uint32 r) {
        bytes memory buf;
        (new_offset, buf) = read(_data, _offset, 4);
        r = bytesToUInt32(buf);
    }

    function readUInt128(bytes memory _data, uint _offset) internal pure returns (uint new_offset, uint128 r) {
        bytes memory buf;
        (new_offset, buf) = read(_data, _offset, 16);
        r = bytesToUInt128(buf);
    }

    function readAddress(bytes memory _data, uint _offset) internal pure returns (uint new_offset, address r) {
        bytes memory buf;
        (new_offset, buf) = read(_data, _offset, 20);
        r = bytesToAddress(buf);
    }

    // Original source code: https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol#L13
    // Concatenate bytes arrays in memory
    // Returns the newly created 'bytes memory'.
    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    ) internal pure returns (bytes memory) {
        bytes memory tempBytes;
        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
              add(add(end, iszero(add(length, mload(_preBytes)))), 31),
              not(31) // Round down to the nearest 32 bytes.
            ))
        }
        return tempBytes;
    }

    // Helper function for hex conversion.
    function halfByteToHex(byte _byte) internal pure returns (byte _hexByte) {
        uint8 numByte = uint8(_byte);
        if (numByte >= 0 && numByte <= 9) {
            return byte(0x30 + numByte); // ASCII 0-9
        } else if (numByte <= 15) {
            return byte(0x57 + numByte); // ASCII a-f
        }
    }

    // Convert bytes to ASCII hex representation
    function bytesToHexASCIIBytes(bytes memory  _input) internal pure returns (bytes memory _output) {
        bytes memory outStringBytes = new bytes(_input.length * 2);
        for (uint i = 0; i < _input.length; ++i) {
            outStringBytes[i*2] = halfByteToHex(_input[i] >> 4);
            outStringBytes[i*2+1] = halfByteToHex(_input[i] & 0x0f);
        }
        return outStringBytes;
    }

}