import os
#coding=utf-8
def generateTestConfig (coreNum, L2_cache_size, outputPath, wr_size = 10, wr_bit_size = 4):
    wBuff = []
    wBuff.append("#ifndef _TEST_CONFIG_H")
    wBuff.append("#define _TEST_CONFIG_H")
    wBuff.append("")
    wBuff.append("#define CORE_NUM " + str(coreNum))
    wBuff.append("#define L2_CACHE_SIZE " + str(L2_cache_size) + "  // L2 Cache 的大小 (in Bytes)")
    wBuff.append("#define MEMORY_SIZE MEMORY_MEM_SIZE               // RAM 的大小 (in Bytes)")
    wBuff.append("")
    wBuff.append("#define MEMORY_WR_SIZE (L2_CACHE_SIZE * " + str(wr_size) + ")        // 小范围测试")
    wBuff.append("#define MEMORY_WR_SIZE_BIT (L2_CACHE_SIZE * " + str(wr_bit_size) + ")")
    wBuff.append("")
    wBuff.append("// #define MEMORY_WR_SIZE MEMORY_SIZE ")
    wBuff.append("#define DEFINED_TYPE uint8_t                      // 访存最小单位的类型 (u_int8_t, u_int16_t, etc.)")
    wBuff.append("#define TYPE_WIDTH (sizeof(DEFINED_TYPE) << 3)    // 计算出访存最小单位的宽度 (in bits) (e.g. 1 Byte = 8 bits)")
    wBuff.append("#define TYPE_RANGE (1 << TYPE_WIDTH)              // 计算出访存最小单位的范围 (e.g. 1 Byte 的范围为 256)")
    wBuff.append("")
    wBuff.append("#define OUTPUT_SHIFT 37                           // 在输出扫描的地址时，每 OUTPUT_SHIFT 个地址输出一次")
    wBuff.append("")
    wBuff.append("#endif")
    f = open(outputPath + "testConfig.h", 'w')
    f.writelines([line + '\n' for line in wBuff])
    f.close()
    return


def beforeBootTest (coreNum, L2_cache_size, outputPath):
    """
    功能：
        输出 testConfig.h，配置启动前测试用例的参数，并配置测试用例的 BootROM
    参数：
        coreNum: 进行启动前测试的核心数量
        L2_cache_size: L2 Cache 的大小，这个参数决定内存测试的范围大小
        outputPath: 输出 testConfig.h 的路径
    """
    generateTestConfig(coreNum, L2_cache_size, outputPath)
    val1 = os.system('chmod u+x ./util/setup_boot_test.sh')
    val2 = os.system('chmod ./util/setup_boot_test.sh set ' + outputPath)
    return

def cleanTest():
    val1 = os.system('chmod u+x ./util/setup_boot_test.sh')
    val2 = os.system('chmod ./util/setup_boot_test.sh clean '+ outputPath)
    return

beforeBootTest(coreNum = 4, L2_cache_size = 1024, outputPath = "../fpga/src/main/resources/vcu118/sdboot")