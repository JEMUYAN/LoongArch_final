# WSL 中使用 LoongArch32R 编译链

这份手册用于个人赛本地调试：Windows 上编辑代码，在 WSL 中把 LoongArch C3/LA32R 汇编编译为可加载到 BaseRAM 的 `.bin`。它与本仓库 `Final/` 练习题的约定一致：程序链接地址为 `0x1c000000`，数据通常由测试平台单独初始化到 ExtRAM。

> 边界：**比赛官方以线上编译平台的产物和判定为准。** 这里的本地编译链只用于快速发现语法、立即数、链接地址和结果布局的问题；提交前仍应在线上平台再编译、再验证。

> 核心结论：这套本地交叉编译器与当前 macOS 上通过 Docker 使用的是同一套 Linux 编译链；区别仅在宿主环境。Windows 用 WSL2 可以直接运行它，因此不需要 Docker。

## 1. 一次性安装 WSL

在 **管理员 PowerShell** 执行：

```powershell
wsl --install -d Ubuntu-22.04
```

按提示重启并首次进入 Ubuntu，创建 Linux 用户。之后在 WSL 终端执行：

```bash
sudo apt update
sudo apt install -y make file
```

检查 WSL 是版本 2（在 PowerShell 中）：

```powershell
wsl -l -v
```

若发行版不是版本 2：

```powershell
wsl --set-version Ubuntu-22.04 2
```

## 2. 放置本地调试编译链

建议把本地调试用的发布包/编译链直接放进 WSL 的 Linux 家目录，而不是长期在 `/mnt/c` 上构建；后者通常明显更慢，也更容易受到 Windows 杀毒软件、换行符和权限行为影响。

假设 Windows 中的发布包在：

```text
C:\Users\你的用户名\Desktop\nscscc2026个人赛发布包_loongarch_v1.0
```

第一次可在 WSL 中复制到家目录：

```bash
mkdir -p ~/loongarch
cp -a /mnt/c/Users/你的用户名/Desktop/nscscc2026个人赛发布包_loongarch_v1.0 ~/loongarch/
```

本地发布包内的工具链目录应为：

```text
~/loongarch/nscscc2026个人赛发布包_loongarch_v1.0/
  loongarch32r-linux-gnusf-2022-05-20/
    bin/loongarch32r-linux-gnusf-gcc
```

为避免每次写完整路径，把工具链加入 `PATH`。下面两行只需执行一次：

```bash
echo 'export LA_TOOLCHAIN=$HOME/loongarch/nscscc2026个人赛发布包_loongarch_v1.0/loongarch32r-linux-gnusf-2022-05-20' >> ~/.bashrc
echo 'export PATH=$LA_TOOLCHAIN/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```

验证：

```bash
loongarch32r-linux-gnusf-gcc --version
loongarch32r-linux-gnusf-objcopy --version
```

若遇到 `Permission denied`，修复工具的可执行权限：

```bash
chmod +x "$LA_TOOLCHAIN/bin/loongarch32r-linux-gnusf-"*
```

## 3. 在 Windows 与 WSL 间打开工程

WSL 能直接访问 Windows 盘：

```bash
cd /mnt/c/Users/你的用户名/Documents/Finals/ext_filter_u32_1024
```

也可从 Windows 资源管理器打开当前 WSL 目录：

```bash
explorer.exe .
```

若用 VS Code，推荐安装 *Remote - WSL*，然后在 WSL 工程目录运行：

```bash
code .
```

编辑器保存为 **UTF-8 + LF**。汇编源里不能混入 Windows 的不可见字符；若编译出现奇怪的指令不匹配，可检查：

```bash
file user-sample.s
sed -n '1,80l' user-sample.s
```

## 4. 编译 Final 中的汇编题

以某个题目目录为例：

```bash
cd ~/loongarch/Finals/ext_filter_u32_1024
make -f Makefile_la all FLAGS='-march=loongarch32r'
```

这条命令只生成本地调试产物。比赛时，使用线上平台要求的源文件、入口和提交方式；即使本地通过，也要以线上编译器的报错、反汇编（若平台提供）和运行结果为最终依据。

生成三个关键文件：

| 文件 | 用途 |
| --- | --- |
| `user-sample.elf` | 带 ELF 头、符号和段信息，用于检查 |
| `user-sample.asm` | 反汇编，确认汇编器实际接受的指令 |
| `user-sample.bin` | 仅 `.text` 裸二进制，供 BaseRAM 从复位地址加载 |

清理构建产物：

```bash
make -f Makefile_la clean
```

### 不使用 Makefile 的等价命令

适合临时检查单个源文件：

```bash
loongarch32r-linux-gnusf-gcc \
  -nostdinc -nostdlib -fno-builtin -mabi=ilp32s -g \
  -march=loongarch32r \
  -Wl,-Ttext=0x1c000000 -Wl,-e,_start \
  -o user-sample.elf user-sample.s

loongarch32r-linux-gnusf-objcopy \
  -j .text -O binary user-sample.elf user-sample.bin

loongarch32r-linux-gnusf-objdump -d user-sample.elf > user-sample.asm
```

不要省略下列参数：

- `-march=loongarch32r`：只生成你的 C3 已实现的 LA32R 基础指令风格。
- `-mabi=ilp32s`：32 位 ABI；与当前 32 位 CPU 和发布包一致。
- `-nostdlib -nostdinc -fno-builtin`：裸机程序没有 Linux 运行库，避免编译器偷偷引入库函数。
- `-Wl,-Ttext=0x1c000000`：代码链接到复位后从 BaseRAM 开始执行的位置。
- `-Wl,-e,_start`：入口标签固定为 `_start`。
- `objcopy -j .text -O binary`：剥除 ELF 文件头，只保留需要被 RAM 初始化的指令字节。

## 5. 最小可编译汇编模板

保存为 `user-sample.s`：

```asm
    .section .text
    .globl _start

_start:
    # ExtRAM 起始地址：0x1c400000
    lu12i.w $a0, 0x1c400

    # 示例：读取第一个 32 位无符号数，再写回另一个位置
    ld.w   $t0, $a0, 0
    lu12i.w $a1, 0x1c401       # 0x1c401000
    st.w   $t0, $a1, 0

.Lhalt:
    b .Lhalt                   # 裸机结束：原地循环
```

### 当前工具链的语法要点

- **寄存器前必须有 `$`**：`$a0`、`$t0`、`$r0`、`$ra`。例如 `ld.w $t0,$a0,0`。
- 32 位算术/移位写 `.w`：`add.w`、`addi.w`、`slli.w`、`srli.w`、`srai.w`。
- `r0` 恒为零。构造零或复制寄存器通常写 `addi.w $a0,$r0,0`、`addi.w $a0,$t0,0`。
- 分支应使用标签，避免手算 PC 偏移：`bne $a0,$a1,.Lloop`。
- `bl label` 调用，返回地址写入 `$ra`；返回用 `jirl $r0,$ra,0`。
- 立即数范围有限。特别是 `lu12i.w` 的立即数是 **有符号 20 位**；构造 `0x80000000` 应写 `lu12i.w $t0,-0x80000`，不能写正的 `0x80000`。

## 6. 地址、加载与仿真的关系

当前 `Final/` 正式练习题的约定：

| 内容 | 地址 | 加载文件 |
| --- | --- | --- |
| 程序入口 / BaseRAM | `0x1c000000` | `user-sample.bin` |
| 输入、输出 / ExtRAM | 通常 `0x1c400000` 起 | 题目提供的 `extram_init.bin` |

因此通常是：

1. 顶层测试文件把 `user-sample.bin` 初始化进 BaseRAM；
2. 把题目数据镜像初始化进 ExtRAM；
3. CPU 从 `0x1c000000` 复位运行；
4. 程序读 ExtRAM 输入、写规定的 ExtRAM 输出地址；
5. 测试平台导出 ExtRAM，再运行题目的 `answer/check_output.py`。

`.bin` 是原始二进制而非文本 `.mem`。若 Verilog 顶层只支持 `$readmemh`，要先按你的顶层字节序转换；不要把 `.bin` 直接当作十六进制文本加载。

## 7. 常见报错速查

| 现象 | 原因与处理 |
| --- | --- |
| `no match insn: lu12i.w a0,...` | 漏写 `$`；改为 `lu12i.w $a0,...`。 |
| `immediate overflow` | 立即数超出编码范围；检查 `addi.w`、逻辑立即数以及 `lu12i.w` 的有符号 20 位限制。 |
| `no match insn: srli ...` | 当前工具链要求 `srli.w`，同理使用 `slli.w`、`srai.w`。 |
| `command not found: loongarch32r...` | 没有 `source ~/.bashrc`，或 `LA_TOOLCHAIN` 路径不对；用 `ls "$LA_TOOLCHAIN/bin"` 核实。 |
| ELF 能生成但 CPU 不跑 | 检查 `.text`、`_start`、链接地址 `0x1c000000`、以及加载的是 `.bin` 而不是 `.elf`。 |
| 输出地址全零或错位 | 对照题目 README 的 ExtRAM 绝对地址；确认 `st.w` 的基址和字节偏移（下一个 `u32` 是 `+4`）。 |
| Windows 路径在 WSL 找不到 | `C:\\Users\\name` 对应 `/mnt/c/Users/name`。 |

## 8. 比赛中的推荐流程

```text
读题，写清地址/输入输出/边界
        ↓
先用 C 伪代码或纸面推导算法
        ↓
按寄存器分工写 user-sample.s
        ↓
make 生成 elf、asm、bin
        ↓
看 asm：确认没有未实现指令和意外库调用
        ↓
把 bin 与题目数据装入测试平台
        ↓
导出结果，用 checker 验证
        ↓
再做循环展开与 load-use 调度优化
```

先保证正确，再测性能。每次优化后保留一个能通过 checker 的版本；尤其不要为了减少几条指令而改变输出布局或越过数组边界。

## 9. C 代码的编译补充

若题目允许 C，仍使用同一工具链，但需要一个汇编启动文件 `start.s`，由它设置栈、调用 `c_main`。C 文件应使用固定宽度的自定义类型、`volatile` 的内存映射指针，并避免 `/` 与 `%`（你的 CPU 没实现 `div/mod` 时可能生成不支持的指令或库调用）。编译后务必检查：

```bash
grep -E 'div|mod|__udiv|__umod|memcpy|memset' user-sample.asm
```

命中后应回到 C 源码改写算法，或手写对应的汇编例程。
