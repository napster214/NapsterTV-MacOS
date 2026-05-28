import Foundation

// Base58 解码器 (Bitcoin alphabet)
struct Base58Decoder {
    private static let alphabet = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"

    // 预计算 ASCII 到 Base58 值的映射表，避免在循环里做线性查找
    private static let asciiToValue: [Int8] = {
        var table = [Int8](repeating: -1, count: 128)
        for (index, scalar) in alphabet.unicodeScalars.enumerated() {
            if scalar.value < 128 {
                table[Int(scalar.value)] = Int8(index)
            }
        }
        return table
    }()

    static func decode(_ string: String) -> String? {
        guard !string.isEmpty else { return nil }

        // 全部转 ASCII 字节处理（Base58 字符必为 ASCII）
        let inputBytes = Array(string.utf8)

        // 统计 LEADING '1' 个数（前导零），其它位置的 '1' 不算
        let oneAscii: UInt8 = 0x31
        var leadingOnes = 0
        for byte in inputBytes {
            if byte == oneAscii {
                leadingOnes += 1
            } else {
                break
            }
        }

        // 估算输出大小：base58 每位约 5.86 bit，约 0.733 字节
        // 多预留几个字节以防边界情况
        let remaining = inputBytes.count - leadingOnes
        let capacity = (remaining * 733) / 1000 + 2
        var b256 = [UInt8](repeating: 0, count: capacity)

        // 大端序累乘：b256[0] 是 MSB，b256[capacity-1] 是 LSB
        // 已写入的有效起始位置，初始指向末尾
        var writeStart = capacity
        for byte in inputBytes {
            guard byte < 128 else { return nil }
            let digit = Self.asciiToValue[Int(byte)]
            guard digit >= 0 else { return nil }

            var carry = Int(digit)
            var index = capacity - 1
            // 至少处理到当前已写入的最高位，并继续传播 carry
            while index >= 0 && (carry != 0 || index >= writeStart) {
                carry += Int(b256[index]) * 58
                b256[index] = UInt8(carry & 0xFF)
                carry >>= 8
                index -= 1
            }
            guard carry == 0 else { return nil }
            writeStart = index + 1
        }

        // 跳过 b256 中的前导零（属于估算冗余空间）
        var firstNonZero = writeStart
        while firstNonZero < capacity && b256[firstNonZero] == 0 {
            firstNonZero += 1
        }

        let payload = b256[firstNonZero..<capacity]
        var result = [UInt8](repeating: 0, count: leadingOnes)
        result.append(contentsOf: payload)
        return String(bytes: result, encoding: .utf8)
    }
}
