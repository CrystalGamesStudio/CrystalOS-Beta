/* SPDX-License-Identifier: GPL-2.0 */
#ifndef __TOOLS_ASM_BYTEORDER_H
#define __TOOLS_ASM_BYTEORDER_H

#ifndef __LITTLE_ENDIAN
#define __LITTLE_ENDIAN 1234
#endif
#ifndef __BIG_ENDIAN
#define __BIG_ENDIAN    4321
#endif
#ifndef __BYTE_ORDER
#define __BYTE_ORDER    __LITTLE_ENDIAN
#endif
#ifndef __LITTLE_ENDIAN_BITFIELD
#define __LITTLE_ENDIAN_BITFIELD
#endif

#include <stdint.h>

static inline uint32_t __swab32(uint32_t x)
{
	return ((x & 0x000000ff) << 24) |
	       ((x & 0x0000ff00) << 8)  |
	       ((x & 0x00ff0000) >> 8)  |
	       ((x & 0xff000000) >> 24);
}

static inline uint64_t __swab64(uint64_t x)
{
	return ((x & 0x00000000000000ffULL) << 56) |
	       ((x & 0x000000000000ff00ULL) << 40) |
	       ((x & 0x0000000000ff0000ULL) << 24) |
	       ((x & 0x00000000ff000000ULL) << 8)  |
	       ((x & 0x000000ff00000000ULL) >> 8)  |
	       ((x & 0x0000ff0000000000ULL) >> 24) |
	       ((x & 0x00ff000000000000ULL) >> 40) |
	       ((x & 0xff00000000000000ULL) >> 56);
}

#define __cpu_to_le64(x) (x)
#define __le64_to_cpu(x) (x)
#define __cpu_to_le32(x) (x)
#define __le32_to_cpu(x) (x)
#define __cpu_to_le16(x) (x)
#define __le16_to_cpu(x) (x)

#define __cpu_to_be64(x) __swab64(x)
#define __be64_to_cpu(x) __swab64(x)
#define __cpu_to_be32(x) __swab32(x)
#define __be32_to_cpu(x) __swab32(x)
#define __cpu_to_be16(x) (__swab32((uint32_t)(x)) >> 16)
#define __be16_to_cpu(x) (__swab32((uint32_t)(x)) >> 16)

#endif /* __TOOLS_ASM_BYTEORDER_H */
