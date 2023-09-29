
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	b5010113          	addi	sp,sp,-1200 # 80008b50 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	ra,8000008c <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9732                	add	a4,a4,a2
    80000046:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00259693          	slli	a3,a1,0x2
    8000004c:	96ae                	add	a3,a3,a1
    8000004e:	068e                	slli	a3,a3,0x3
    80000050:	00009717          	auipc	a4,0x9
    80000054:	9c070713          	addi	a4,a4,-1600 # 80008a10 <timer_scratch>
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	0be78793          	addi	a5,a5,190 # 80006120 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	addi	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	addi	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdc97f>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	dc678793          	addi	a5,a5,-570 # 80000e72 <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d6:	57fd                	li	a5,-1
    800000d8:	83a9                	srli	a5,a5,0xa
    800000da:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000de:	47bd                	li	a5,15
    800000e0:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e4:	00000097          	auipc	ra,0x0
    800000e8:	f38080e7          	jalr	-200(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ec:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f4:	30200073          	mret
}
    800000f8:	60a2                	ld	ra,8(sp)
    800000fa:	6402                	ld	s0,0(sp)
    800000fc:	0141                	addi	sp,sp,16
    800000fe:	8082                	ret

0000000080000100 <consolewrite>:

//
// user write()s to the console go here.
//
int consolewrite(int user_src, uint64 src, int n)
{
    80000100:	715d                	addi	sp,sp,-80
    80000102:	e486                	sd	ra,72(sp)
    80000104:	e0a2                	sd	s0,64(sp)
    80000106:	fc26                	sd	s1,56(sp)
    80000108:	f84a                	sd	s2,48(sp)
    8000010a:	f44e                	sd	s3,40(sp)
    8000010c:	f052                	sd	s4,32(sp)
    8000010e:	ec56                	sd	s5,24(sp)
    80000110:	0880                	addi	s0,sp,80
    int i;

    for (i = 0; i < n; i++)
    80000112:	04c05763          	blez	a2,80000160 <consolewrite+0x60>
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    {
        char c;
        if (either_copyin(&c, user_src, src + i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	addi	a0,s0,-65
    8000012a:	00002097          	auipc	ra,0x2
    8000012e:	786080e7          	jalr	1926(ra) # 800028b0 <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
            break;
        uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	780080e7          	jalr	1920(ra) # 800008ba <uartputc>
    for (i = 0; i < n; i++)
    80000142:	2905                	addiw	s2,s2,1
    80000144:	0485                	addi	s1,s1,1
    80000146:	fd299de3          	bne	s3,s2,80000120 <consolewrite+0x20>
    8000014a:	894e                	mv	s2,s3
    }

    return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
    for (i = 0; i < n; i++)
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4c>

0000000080000164 <consoleread>:
// copy (up to) a whole input line to dst.
// user_dist indicates whether dst is a user
// or kernel address.
//
int consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	711d                	addi	sp,sp,-96
    80000166:	ec86                	sd	ra,88(sp)
    80000168:	e8a2                	sd	s0,80(sp)
    8000016a:	e4a6                	sd	s1,72(sp)
    8000016c:	e0ca                	sd	s2,64(sp)
    8000016e:	fc4e                	sd	s3,56(sp)
    80000170:	f852                	sd	s4,48(sp)
    80000172:	f456                	sd	s5,40(sp)
    80000174:	f05a                	sd	s6,32(sp)
    80000176:	ec5e                	sd	s7,24(sp)
    80000178:	1080                	addi	s0,sp,96
    8000017a:	8aaa                	mv	s5,a0
    8000017c:	8a2e                	mv	s4,a1
    8000017e:	89b2                	mv	s3,a2
    uint target;
    int c;
    char cbuf;

    target = n;
    80000180:	00060b1b          	sext.w	s6,a2
    acquire(&cons.lock);
    80000184:	00011517          	auipc	a0,0x11
    80000188:	9cc50513          	addi	a0,a0,-1588 # 80010b50 <cons>
    8000018c:	00001097          	auipc	ra,0x1
    80000190:	a46080e7          	jalr	-1466(ra) # 80000bd2 <acquire>
    while (n > 0)
    {
        // wait until interrupt handler has put some
        // input into cons.buffer.
        while (cons.r == cons.w)
    80000194:	00011497          	auipc	s1,0x11
    80000198:	9bc48493          	addi	s1,s1,-1604 # 80010b50 <cons>
            if (killed(myproc()))
            {
                release(&cons.lock);
                return -1;
            }
            sleep(&cons.r, &cons.lock);
    8000019c:	00011917          	auipc	s2,0x11
    800001a0:	a4c90913          	addi	s2,s2,-1460 # 80010be8 <cons+0x98>
    while (n > 0)
    800001a4:	09305263          	blez	s3,80000228 <consoleread+0xc4>
        while (cons.r == cons.w)
    800001a8:	0984a783          	lw	a5,152(s1)
    800001ac:	09c4a703          	lw	a4,156(s1)
    800001b0:	02f71763          	bne	a4,a5,800001de <consoleread+0x7a>
            if (killed(myproc()))
    800001b4:	00002097          	auipc	ra,0x2
    800001b8:	ae0080e7          	jalr	-1312(ra) # 80001c94 <myproc>
    800001bc:	00002097          	auipc	ra,0x2
    800001c0:	53e080e7          	jalr	1342(ra) # 800026fa <killed>
    800001c4:	ed2d                	bnez	a0,8000023e <consoleread+0xda>
            sleep(&cons.r, &cons.lock);
    800001c6:	85a6                	mv	a1,s1
    800001c8:	854a                	mv	a0,s2
    800001ca:	00002097          	auipc	ra,0x2
    800001ce:	288080e7          	jalr	648(ra) # 80002452 <sleep>
        while (cons.r == cons.w)
    800001d2:	0984a783          	lw	a5,152(s1)
    800001d6:	09c4a703          	lw	a4,156(s1)
    800001da:	fcf70de3          	beq	a4,a5,800001b4 <consoleread+0x50>
        }

        c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001de:	00011717          	auipc	a4,0x11
    800001e2:	97270713          	addi	a4,a4,-1678 # 80010b50 <cons>
    800001e6:	0017869b          	addiw	a3,a5,1
    800001ea:	08d72c23          	sw	a3,152(a4)
    800001ee:	07f7f693          	andi	a3,a5,127
    800001f2:	9736                	add	a4,a4,a3
    800001f4:	01874703          	lbu	a4,24(a4)
    800001f8:	00070b9b          	sext.w	s7,a4

        if (c == C('D'))
    800001fc:	4691                	li	a3,4
    800001fe:	06db8463          	beq	s7,a3,80000266 <consoleread+0x102>
            }
            break;
        }

        // copy the input byte to the user-space buffer.
        cbuf = c;
    80000202:	fae407a3          	sb	a4,-81(s0)
        if (either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000206:	4685                	li	a3,1
    80000208:	faf40613          	addi	a2,s0,-81
    8000020c:	85d2                	mv	a1,s4
    8000020e:	8556                	mv	a0,s5
    80000210:	00002097          	auipc	ra,0x2
    80000214:	64a080e7          	jalr	1610(ra) # 8000285a <either_copyout>
    80000218:	57fd                	li	a5,-1
    8000021a:	00f50763          	beq	a0,a5,80000228 <consoleread+0xc4>
            break;

        dst++;
    8000021e:	0a05                	addi	s4,s4,1
        --n;
    80000220:	39fd                	addiw	s3,s3,-1

        if (c == '\n')
    80000222:	47a9                	li	a5,10
    80000224:	f8fb90e3          	bne	s7,a5,800001a4 <consoleread+0x40>
            // a whole line has arrived, return to
            // the user-level read().
            break;
        }
    }
    release(&cons.lock);
    80000228:	00011517          	auipc	a0,0x11
    8000022c:	92850513          	addi	a0,a0,-1752 # 80010b50 <cons>
    80000230:	00001097          	auipc	ra,0x1
    80000234:	a56080e7          	jalr	-1450(ra) # 80000c86 <release>

    return target - n;
    80000238:	413b053b          	subw	a0,s6,s3
    8000023c:	a811                	j	80000250 <consoleread+0xec>
                release(&cons.lock);
    8000023e:	00011517          	auipc	a0,0x11
    80000242:	91250513          	addi	a0,a0,-1774 # 80010b50 <cons>
    80000246:	00001097          	auipc	ra,0x1
    8000024a:	a40080e7          	jalr	-1472(ra) # 80000c86 <release>
                return -1;
    8000024e:	557d                	li	a0,-1
}
    80000250:	60e6                	ld	ra,88(sp)
    80000252:	6446                	ld	s0,80(sp)
    80000254:	64a6                	ld	s1,72(sp)
    80000256:	6906                	ld	s2,64(sp)
    80000258:	79e2                	ld	s3,56(sp)
    8000025a:	7a42                	ld	s4,48(sp)
    8000025c:	7aa2                	ld	s5,40(sp)
    8000025e:	7b02                	ld	s6,32(sp)
    80000260:	6be2                	ld	s7,24(sp)
    80000262:	6125                	addi	sp,sp,96
    80000264:	8082                	ret
            if (n < target)
    80000266:	0009871b          	sext.w	a4,s3
    8000026a:	fb677fe3          	bgeu	a4,s6,80000228 <consoleread+0xc4>
                cons.r--;
    8000026e:	00011717          	auipc	a4,0x11
    80000272:	96f72d23          	sw	a5,-1670(a4) # 80010be8 <cons+0x98>
    80000276:	bf4d                	j	80000228 <consoleread+0xc4>

0000000080000278 <consputc>:
{
    80000278:	1141                	addi	sp,sp,-16
    8000027a:	e406                	sd	ra,8(sp)
    8000027c:	e022                	sd	s0,0(sp)
    8000027e:	0800                	addi	s0,sp,16
    if (c == BACKSPACE)
    80000280:	10000793          	li	a5,256
    80000284:	00f50a63          	beq	a0,a5,80000298 <consputc+0x20>
        uartputc_sync(c);
    80000288:	00000097          	auipc	ra,0x0
    8000028c:	560080e7          	jalr	1376(ra) # 800007e8 <uartputc_sync>
}
    80000290:	60a2                	ld	ra,8(sp)
    80000292:	6402                	ld	s0,0(sp)
    80000294:	0141                	addi	sp,sp,16
    80000296:	8082                	ret
        uartputc_sync('\b');
    80000298:	4521                	li	a0,8
    8000029a:	00000097          	auipc	ra,0x0
    8000029e:	54e080e7          	jalr	1358(ra) # 800007e8 <uartputc_sync>
        uartputc_sync(' ');
    800002a2:	02000513          	li	a0,32
    800002a6:	00000097          	auipc	ra,0x0
    800002aa:	542080e7          	jalr	1346(ra) # 800007e8 <uartputc_sync>
        uartputc_sync('\b');
    800002ae:	4521                	li	a0,8
    800002b0:	00000097          	auipc	ra,0x0
    800002b4:	538080e7          	jalr	1336(ra) # 800007e8 <uartputc_sync>
    800002b8:	bfe1                	j	80000290 <consputc+0x18>

00000000800002ba <consoleintr>:
// uartintr() calls this for input character.
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void consoleintr(int c)
{
    800002ba:	1101                	addi	sp,sp,-32
    800002bc:	ec06                	sd	ra,24(sp)
    800002be:	e822                	sd	s0,16(sp)
    800002c0:	e426                	sd	s1,8(sp)
    800002c2:	e04a                	sd	s2,0(sp)
    800002c4:	1000                	addi	s0,sp,32
    800002c6:	84aa                	mv	s1,a0
    acquire(&cons.lock);
    800002c8:	00011517          	auipc	a0,0x11
    800002cc:	88850513          	addi	a0,a0,-1912 # 80010b50 <cons>
    800002d0:	00001097          	auipc	ra,0x1
    800002d4:	902080e7          	jalr	-1790(ra) # 80000bd2 <acquire>

    switch (c)
    800002d8:	47d5                	li	a5,21
    800002da:	0af48663          	beq	s1,a5,80000386 <consoleintr+0xcc>
    800002de:	0297ca63          	blt	a5,s1,80000312 <consoleintr+0x58>
    800002e2:	47a1                	li	a5,8
    800002e4:	0ef48763          	beq	s1,a5,800003d2 <consoleintr+0x118>
    800002e8:	47c1                	li	a5,16
    800002ea:	10f49a63          	bne	s1,a5,800003fe <consoleintr+0x144>
    {
    case C('P'): // Print process list.
        procdump();
    800002ee:	00002097          	auipc	ra,0x2
    800002f2:	618080e7          	jalr	1560(ra) # 80002906 <procdump>
            }
        }
        break;
    }

    release(&cons.lock);
    800002f6:	00011517          	auipc	a0,0x11
    800002fa:	85a50513          	addi	a0,a0,-1958 # 80010b50 <cons>
    800002fe:	00001097          	auipc	ra,0x1
    80000302:	988080e7          	jalr	-1656(ra) # 80000c86 <release>
}
    80000306:	60e2                	ld	ra,24(sp)
    80000308:	6442                	ld	s0,16(sp)
    8000030a:	64a2                	ld	s1,8(sp)
    8000030c:	6902                	ld	s2,0(sp)
    8000030e:	6105                	addi	sp,sp,32
    80000310:	8082                	ret
    switch (c)
    80000312:	07f00793          	li	a5,127
    80000316:	0af48e63          	beq	s1,a5,800003d2 <consoleintr+0x118>
        if (c != 0 && cons.e - cons.r < INPUT_BUF_SIZE)
    8000031a:	00011717          	auipc	a4,0x11
    8000031e:	83670713          	addi	a4,a4,-1994 # 80010b50 <cons>
    80000322:	0a072783          	lw	a5,160(a4)
    80000326:	09872703          	lw	a4,152(a4)
    8000032a:	9f99                	subw	a5,a5,a4
    8000032c:	07f00713          	li	a4,127
    80000330:	fcf763e3          	bltu	a4,a5,800002f6 <consoleintr+0x3c>
            c = (c == '\r') ? '\n' : c;
    80000334:	47b5                	li	a5,13
    80000336:	0cf48763          	beq	s1,a5,80000404 <consoleintr+0x14a>
            consputc(c);
    8000033a:	8526                	mv	a0,s1
    8000033c:	00000097          	auipc	ra,0x0
    80000340:	f3c080e7          	jalr	-196(ra) # 80000278 <consputc>
            cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000344:	00011797          	auipc	a5,0x11
    80000348:	80c78793          	addi	a5,a5,-2036 # 80010b50 <cons>
    8000034c:	0a07a683          	lw	a3,160(a5)
    80000350:	0016871b          	addiw	a4,a3,1
    80000354:	0007061b          	sext.w	a2,a4
    80000358:	0ae7a023          	sw	a4,160(a5)
    8000035c:	07f6f693          	andi	a3,a3,127
    80000360:	97b6                	add	a5,a5,a3
    80000362:	00978c23          	sb	s1,24(a5)
            if (c == '\n' || c == C('D') || cons.e - cons.r == INPUT_BUF_SIZE)
    80000366:	47a9                	li	a5,10
    80000368:	0cf48563          	beq	s1,a5,80000432 <consoleintr+0x178>
    8000036c:	4791                	li	a5,4
    8000036e:	0cf48263          	beq	s1,a5,80000432 <consoleintr+0x178>
    80000372:	00011797          	auipc	a5,0x11
    80000376:	8767a783          	lw	a5,-1930(a5) # 80010be8 <cons+0x98>
    8000037a:	9f1d                	subw	a4,a4,a5
    8000037c:	08000793          	li	a5,128
    80000380:	f6f71be3          	bne	a4,a5,800002f6 <consoleintr+0x3c>
    80000384:	a07d                	j	80000432 <consoleintr+0x178>
        while (cons.e != cons.w &&
    80000386:	00010717          	auipc	a4,0x10
    8000038a:	7ca70713          	addi	a4,a4,1994 # 80010b50 <cons>
    8000038e:	0a072783          	lw	a5,160(a4)
    80000392:	09c72703          	lw	a4,156(a4)
               cons.buf[(cons.e - 1) % INPUT_BUF_SIZE] != '\n')
    80000396:	00010497          	auipc	s1,0x10
    8000039a:	7ba48493          	addi	s1,s1,1978 # 80010b50 <cons>
        while (cons.e != cons.w &&
    8000039e:	4929                	li	s2,10
    800003a0:	f4f70be3          	beq	a4,a5,800002f6 <consoleintr+0x3c>
               cons.buf[(cons.e - 1) % INPUT_BUF_SIZE] != '\n')
    800003a4:	37fd                	addiw	a5,a5,-1
    800003a6:	07f7f713          	andi	a4,a5,127
    800003aa:	9726                	add	a4,a4,s1
        while (cons.e != cons.w &&
    800003ac:	01874703          	lbu	a4,24(a4)
    800003b0:	f52703e3          	beq	a4,s2,800002f6 <consoleintr+0x3c>
            cons.e--;
    800003b4:	0af4a023          	sw	a5,160(s1)
            consputc(BACKSPACE);
    800003b8:	10000513          	li	a0,256
    800003bc:	00000097          	auipc	ra,0x0
    800003c0:	ebc080e7          	jalr	-324(ra) # 80000278 <consputc>
        while (cons.e != cons.w &&
    800003c4:	0a04a783          	lw	a5,160(s1)
    800003c8:	09c4a703          	lw	a4,156(s1)
    800003cc:	fcf71ce3          	bne	a4,a5,800003a4 <consoleintr+0xea>
    800003d0:	b71d                	j	800002f6 <consoleintr+0x3c>
        if (cons.e != cons.w)
    800003d2:	00010717          	auipc	a4,0x10
    800003d6:	77e70713          	addi	a4,a4,1918 # 80010b50 <cons>
    800003da:	0a072783          	lw	a5,160(a4)
    800003de:	09c72703          	lw	a4,156(a4)
    800003e2:	f0f70ae3          	beq	a4,a5,800002f6 <consoleintr+0x3c>
            cons.e--;
    800003e6:	37fd                	addiw	a5,a5,-1
    800003e8:	00011717          	auipc	a4,0x11
    800003ec:	80f72423          	sw	a5,-2040(a4) # 80010bf0 <cons+0xa0>
            consputc(BACKSPACE);
    800003f0:	10000513          	li	a0,256
    800003f4:	00000097          	auipc	ra,0x0
    800003f8:	e84080e7          	jalr	-380(ra) # 80000278 <consputc>
    800003fc:	bded                	j	800002f6 <consoleintr+0x3c>
        if (c != 0 && cons.e - cons.r < INPUT_BUF_SIZE)
    800003fe:	ee048ce3          	beqz	s1,800002f6 <consoleintr+0x3c>
    80000402:	bf21                	j	8000031a <consoleintr+0x60>
            consputc(c);
    80000404:	4529                	li	a0,10
    80000406:	00000097          	auipc	ra,0x0
    8000040a:	e72080e7          	jalr	-398(ra) # 80000278 <consputc>
            cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    8000040e:	00010797          	auipc	a5,0x10
    80000412:	74278793          	addi	a5,a5,1858 # 80010b50 <cons>
    80000416:	0a07a703          	lw	a4,160(a5)
    8000041a:	0017069b          	addiw	a3,a4,1
    8000041e:	0006861b          	sext.w	a2,a3
    80000422:	0ad7a023          	sw	a3,160(a5)
    80000426:	07f77713          	andi	a4,a4,127
    8000042a:	97ba                	add	a5,a5,a4
    8000042c:	4729                	li	a4,10
    8000042e:	00e78c23          	sb	a4,24(a5)
                cons.w = cons.e;
    80000432:	00010797          	auipc	a5,0x10
    80000436:	7ac7ad23          	sw	a2,1978(a5) # 80010bec <cons+0x9c>
                wakeup(&cons.r);
    8000043a:	00010517          	auipc	a0,0x10
    8000043e:	7ae50513          	addi	a0,a0,1966 # 80010be8 <cons+0x98>
    80000442:	00002097          	auipc	ra,0x2
    80000446:	074080e7          	jalr	116(ra) # 800024b6 <wakeup>
    8000044a:	b575                	j	800002f6 <consoleintr+0x3c>

000000008000044c <consoleinit>:

void consoleinit(void)
{
    8000044c:	1141                	addi	sp,sp,-16
    8000044e:	e406                	sd	ra,8(sp)
    80000450:	e022                	sd	s0,0(sp)
    80000452:	0800                	addi	s0,sp,16
    initlock(&cons.lock, "cons");
    80000454:	00008597          	auipc	a1,0x8
    80000458:	bbc58593          	addi	a1,a1,-1092 # 80008010 <etext+0x10>
    8000045c:	00010517          	auipc	a0,0x10
    80000460:	6f450513          	addi	a0,a0,1780 # 80010b50 <cons>
    80000464:	00000097          	auipc	ra,0x0
    80000468:	6de080e7          	jalr	1758(ra) # 80000b42 <initlock>

    uartinit();
    8000046c:	00000097          	auipc	ra,0x0
    80000470:	32c080e7          	jalr	812(ra) # 80000798 <uartinit>

    // connect read and write system calls
    // to consoleread and consolewrite.
    devsw[CONSOLE].read = consoleread;
    80000474:	00021797          	auipc	a5,0x21
    80000478:	87478793          	addi	a5,a5,-1932 # 80020ce8 <devsw>
    8000047c:	00000717          	auipc	a4,0x0
    80000480:	ce870713          	addi	a4,a4,-792 # 80000164 <consoleread>
    80000484:	eb98                	sd	a4,16(a5)
    devsw[CONSOLE].write = consolewrite;
    80000486:	00000717          	auipc	a4,0x0
    8000048a:	c7a70713          	addi	a4,a4,-902 # 80000100 <consolewrite>
    8000048e:	ef98                	sd	a4,24(a5)
}
    80000490:	60a2                	ld	ra,8(sp)
    80000492:	6402                	ld	s0,0(sp)
    80000494:	0141                	addi	sp,sp,16
    80000496:	8082                	ret

0000000080000498 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    80000498:	7179                	addi	sp,sp,-48
    8000049a:	f406                	sd	ra,40(sp)
    8000049c:	f022                	sd	s0,32(sp)
    8000049e:	ec26                	sd	s1,24(sp)
    800004a0:	e84a                	sd	s2,16(sp)
    800004a2:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a4:	c219                	beqz	a2,800004aa <printint+0x12>
    800004a6:	08054763          	bltz	a0,80000534 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004aa:	2501                	sext.w	a0,a0
    800004ac:	4881                	li	a7,0
    800004ae:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b2:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b4:	2581                	sext.w	a1,a1
    800004b6:	00008617          	auipc	a2,0x8
    800004ba:	b8a60613          	addi	a2,a2,-1142 # 80008040 <digits>
    800004be:	883a                	mv	a6,a4
    800004c0:	2705                	addiw	a4,a4,1
    800004c2:	02b577bb          	remuw	a5,a0,a1
    800004c6:	1782                	slli	a5,a5,0x20
    800004c8:	9381                	srli	a5,a5,0x20
    800004ca:	97b2                	add	a5,a5,a2
    800004cc:	0007c783          	lbu	a5,0(a5)
    800004d0:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d4:	0005079b          	sext.w	a5,a0
    800004d8:	02b5553b          	divuw	a0,a0,a1
    800004dc:	0685                	addi	a3,a3,1
    800004de:	feb7f0e3          	bgeu	a5,a1,800004be <printint+0x26>

  if(sign)
    800004e2:	00088c63          	beqz	a7,800004fa <printint+0x62>
    buf[i++] = '-';
    800004e6:	fe070793          	addi	a5,a4,-32
    800004ea:	00878733          	add	a4,a5,s0
    800004ee:	02d00793          	li	a5,45
    800004f2:	fef70823          	sb	a5,-16(a4)
    800004f6:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fa:	02e05763          	blez	a4,80000528 <printint+0x90>
    800004fe:	fd040793          	addi	a5,s0,-48
    80000502:	00e784b3          	add	s1,a5,a4
    80000506:	fff78913          	addi	s2,a5,-1
    8000050a:	993a                	add	s2,s2,a4
    8000050c:	377d                	addiw	a4,a4,-1
    8000050e:	1702                	slli	a4,a4,0x20
    80000510:	9301                	srli	a4,a4,0x20
    80000512:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000516:	fff4c503          	lbu	a0,-1(s1)
    8000051a:	00000097          	auipc	ra,0x0
    8000051e:	d5e080e7          	jalr	-674(ra) # 80000278 <consputc>
  while(--i >= 0)
    80000522:	14fd                	addi	s1,s1,-1
    80000524:	ff2499e3          	bne	s1,s2,80000516 <printint+0x7e>
}
    80000528:	70a2                	ld	ra,40(sp)
    8000052a:	7402                	ld	s0,32(sp)
    8000052c:	64e2                	ld	s1,24(sp)
    8000052e:	6942                	ld	s2,16(sp)
    80000530:	6145                	addi	sp,sp,48
    80000532:	8082                	ret
    x = -xx;
    80000534:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000538:	4885                	li	a7,1
    x = -xx;
    8000053a:	bf95                	j	800004ae <printint+0x16>

000000008000053c <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053c:	1101                	addi	sp,sp,-32
    8000053e:	ec06                	sd	ra,24(sp)
    80000540:	e822                	sd	s0,16(sp)
    80000542:	e426                	sd	s1,8(sp)
    80000544:	1000                	addi	s0,sp,32
    80000546:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000548:	00010797          	auipc	a5,0x10
    8000054c:	6c07a423          	sw	zero,1736(a5) # 80010c10 <pr+0x18>
  printf("panic: ");
    80000550:	00008517          	auipc	a0,0x8
    80000554:	ac850513          	addi	a0,a0,-1336 # 80008018 <etext+0x18>
    80000558:	00000097          	auipc	ra,0x0
    8000055c:	02e080e7          	jalr	46(ra) # 80000586 <printf>
  printf(s);
    80000560:	8526                	mv	a0,s1
    80000562:	00000097          	auipc	ra,0x0
    80000566:	024080e7          	jalr	36(ra) # 80000586 <printf>
  printf("\n");
    8000056a:	00008517          	auipc	a0,0x8
    8000056e:	b5e50513          	addi	a0,a0,-1186 # 800080c8 <digits+0x88>
    80000572:	00000097          	auipc	ra,0x0
    80000576:	014080e7          	jalr	20(ra) # 80000586 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057a:	4785                	li	a5,1
    8000057c:	00008717          	auipc	a4,0x8
    80000580:	44f72a23          	sw	a5,1108(a4) # 800089d0 <panicked>
  for(;;)
    80000584:	a001                	j	80000584 <panic+0x48>

0000000080000586 <printf>:
{
    80000586:	7131                	addi	sp,sp,-192
    80000588:	fc86                	sd	ra,120(sp)
    8000058a:	f8a2                	sd	s0,112(sp)
    8000058c:	f4a6                	sd	s1,104(sp)
    8000058e:	f0ca                	sd	s2,96(sp)
    80000590:	ecce                	sd	s3,88(sp)
    80000592:	e8d2                	sd	s4,80(sp)
    80000594:	e4d6                	sd	s5,72(sp)
    80000596:	e0da                	sd	s6,64(sp)
    80000598:	fc5e                	sd	s7,56(sp)
    8000059a:	f862                	sd	s8,48(sp)
    8000059c:	f466                	sd	s9,40(sp)
    8000059e:	f06a                	sd	s10,32(sp)
    800005a0:	ec6e                	sd	s11,24(sp)
    800005a2:	0100                	addi	s0,sp,128
    800005a4:	8a2a                	mv	s4,a0
    800005a6:	e40c                	sd	a1,8(s0)
    800005a8:	e810                	sd	a2,16(s0)
    800005aa:	ec14                	sd	a3,24(s0)
    800005ac:	f018                	sd	a4,32(s0)
    800005ae:	f41c                	sd	a5,40(s0)
    800005b0:	03043823          	sd	a6,48(s0)
    800005b4:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005b8:	00010d97          	auipc	s11,0x10
    800005bc:	658dad83          	lw	s11,1624(s11) # 80010c10 <pr+0x18>
  if(locking)
    800005c0:	020d9b63          	bnez	s11,800005f6 <printf+0x70>
  if (fmt == 0)
    800005c4:	040a0263          	beqz	s4,80000608 <printf+0x82>
  va_start(ap, fmt);
    800005c8:	00840793          	addi	a5,s0,8
    800005cc:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d0:	000a4503          	lbu	a0,0(s4)
    800005d4:	14050f63          	beqz	a0,80000732 <printf+0x1ac>
    800005d8:	4981                	li	s3,0
    if(c != '%'){
    800005da:	02500a93          	li	s5,37
    switch(c){
    800005de:	07000b93          	li	s7,112
  consputc('x');
    800005e2:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e4:	00008b17          	auipc	s6,0x8
    800005e8:	a5cb0b13          	addi	s6,s6,-1444 # 80008040 <digits>
    switch(c){
    800005ec:	07300c93          	li	s9,115
    800005f0:	06400c13          	li	s8,100
    800005f4:	a82d                	j	8000062e <printf+0xa8>
    acquire(&pr.lock);
    800005f6:	00010517          	auipc	a0,0x10
    800005fa:	60250513          	addi	a0,a0,1538 # 80010bf8 <pr>
    800005fe:	00000097          	auipc	ra,0x0
    80000602:	5d4080e7          	jalr	1492(ra) # 80000bd2 <acquire>
    80000606:	bf7d                	j	800005c4 <printf+0x3e>
    panic("null fmt");
    80000608:	00008517          	auipc	a0,0x8
    8000060c:	a2050513          	addi	a0,a0,-1504 # 80008028 <etext+0x28>
    80000610:	00000097          	auipc	ra,0x0
    80000614:	f2c080e7          	jalr	-212(ra) # 8000053c <panic>
      consputc(c);
    80000618:	00000097          	auipc	ra,0x0
    8000061c:	c60080e7          	jalr	-928(ra) # 80000278 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000620:	2985                	addiw	s3,s3,1
    80000622:	013a07b3          	add	a5,s4,s3
    80000626:	0007c503          	lbu	a0,0(a5)
    8000062a:	10050463          	beqz	a0,80000732 <printf+0x1ac>
    if(c != '%'){
    8000062e:	ff5515e3          	bne	a0,s5,80000618 <printf+0x92>
    c = fmt[++i] & 0xff;
    80000632:	2985                	addiw	s3,s3,1
    80000634:	013a07b3          	add	a5,s4,s3
    80000638:	0007c783          	lbu	a5,0(a5)
    8000063c:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000640:	cbed                	beqz	a5,80000732 <printf+0x1ac>
    switch(c){
    80000642:	05778a63          	beq	a5,s7,80000696 <printf+0x110>
    80000646:	02fbf663          	bgeu	s7,a5,80000672 <printf+0xec>
    8000064a:	09978863          	beq	a5,s9,800006da <printf+0x154>
    8000064e:	07800713          	li	a4,120
    80000652:	0ce79563          	bne	a5,a4,8000071c <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000656:	f8843783          	ld	a5,-120(s0)
    8000065a:	00878713          	addi	a4,a5,8
    8000065e:	f8e43423          	sd	a4,-120(s0)
    80000662:	4605                	li	a2,1
    80000664:	85ea                	mv	a1,s10
    80000666:	4388                	lw	a0,0(a5)
    80000668:	00000097          	auipc	ra,0x0
    8000066c:	e30080e7          	jalr	-464(ra) # 80000498 <printint>
      break;
    80000670:	bf45                	j	80000620 <printf+0x9a>
    switch(c){
    80000672:	09578f63          	beq	a5,s5,80000710 <printf+0x18a>
    80000676:	0b879363          	bne	a5,s8,8000071c <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067a:	f8843783          	ld	a5,-120(s0)
    8000067e:	00878713          	addi	a4,a5,8
    80000682:	f8e43423          	sd	a4,-120(s0)
    80000686:	4605                	li	a2,1
    80000688:	45a9                	li	a1,10
    8000068a:	4388                	lw	a0,0(a5)
    8000068c:	00000097          	auipc	ra,0x0
    80000690:	e0c080e7          	jalr	-500(ra) # 80000498 <printint>
      break;
    80000694:	b771                	j	80000620 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000696:	f8843783          	ld	a5,-120(s0)
    8000069a:	00878713          	addi	a4,a5,8
    8000069e:	f8e43423          	sd	a4,-120(s0)
    800006a2:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006a6:	03000513          	li	a0,48
    800006aa:	00000097          	auipc	ra,0x0
    800006ae:	bce080e7          	jalr	-1074(ra) # 80000278 <consputc>
  consputc('x');
    800006b2:	07800513          	li	a0,120
    800006b6:	00000097          	auipc	ra,0x0
    800006ba:	bc2080e7          	jalr	-1086(ra) # 80000278 <consputc>
    800006be:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c0:	03c95793          	srli	a5,s2,0x3c
    800006c4:	97da                	add	a5,a5,s6
    800006c6:	0007c503          	lbu	a0,0(a5)
    800006ca:	00000097          	auipc	ra,0x0
    800006ce:	bae080e7          	jalr	-1106(ra) # 80000278 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d2:	0912                	slli	s2,s2,0x4
    800006d4:	34fd                	addiw	s1,s1,-1
    800006d6:	f4ed                	bnez	s1,800006c0 <printf+0x13a>
    800006d8:	b7a1                	j	80000620 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006da:	f8843783          	ld	a5,-120(s0)
    800006de:	00878713          	addi	a4,a5,8
    800006e2:	f8e43423          	sd	a4,-120(s0)
    800006e6:	6384                	ld	s1,0(a5)
    800006e8:	cc89                	beqz	s1,80000702 <printf+0x17c>
      for(; *s; s++)
    800006ea:	0004c503          	lbu	a0,0(s1)
    800006ee:	d90d                	beqz	a0,80000620 <printf+0x9a>
        consputc(*s);
    800006f0:	00000097          	auipc	ra,0x0
    800006f4:	b88080e7          	jalr	-1144(ra) # 80000278 <consputc>
      for(; *s; s++)
    800006f8:	0485                	addi	s1,s1,1
    800006fa:	0004c503          	lbu	a0,0(s1)
    800006fe:	f96d                	bnez	a0,800006f0 <printf+0x16a>
    80000700:	b705                	j	80000620 <printf+0x9a>
        s = "(null)";
    80000702:	00008497          	auipc	s1,0x8
    80000706:	91e48493          	addi	s1,s1,-1762 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070a:	02800513          	li	a0,40
    8000070e:	b7cd                	j	800006f0 <printf+0x16a>
      consputc('%');
    80000710:	8556                	mv	a0,s5
    80000712:	00000097          	auipc	ra,0x0
    80000716:	b66080e7          	jalr	-1178(ra) # 80000278 <consputc>
      break;
    8000071a:	b719                	j	80000620 <printf+0x9a>
      consputc('%');
    8000071c:	8556                	mv	a0,s5
    8000071e:	00000097          	auipc	ra,0x0
    80000722:	b5a080e7          	jalr	-1190(ra) # 80000278 <consputc>
      consputc(c);
    80000726:	8526                	mv	a0,s1
    80000728:	00000097          	auipc	ra,0x0
    8000072c:	b50080e7          	jalr	-1200(ra) # 80000278 <consputc>
      break;
    80000730:	bdc5                	j	80000620 <printf+0x9a>
  if(locking)
    80000732:	020d9163          	bnez	s11,80000754 <printf+0x1ce>
}
    80000736:	70e6                	ld	ra,120(sp)
    80000738:	7446                	ld	s0,112(sp)
    8000073a:	74a6                	ld	s1,104(sp)
    8000073c:	7906                	ld	s2,96(sp)
    8000073e:	69e6                	ld	s3,88(sp)
    80000740:	6a46                	ld	s4,80(sp)
    80000742:	6aa6                	ld	s5,72(sp)
    80000744:	6b06                	ld	s6,64(sp)
    80000746:	7be2                	ld	s7,56(sp)
    80000748:	7c42                	ld	s8,48(sp)
    8000074a:	7ca2                	ld	s9,40(sp)
    8000074c:	7d02                	ld	s10,32(sp)
    8000074e:	6de2                	ld	s11,24(sp)
    80000750:	6129                	addi	sp,sp,192
    80000752:	8082                	ret
    release(&pr.lock);
    80000754:	00010517          	auipc	a0,0x10
    80000758:	4a450513          	addi	a0,a0,1188 # 80010bf8 <pr>
    8000075c:	00000097          	auipc	ra,0x0
    80000760:	52a080e7          	jalr	1322(ra) # 80000c86 <release>
}
    80000764:	bfc9                	j	80000736 <printf+0x1b0>

0000000080000766 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000766:	1101                	addi	sp,sp,-32
    80000768:	ec06                	sd	ra,24(sp)
    8000076a:	e822                	sd	s0,16(sp)
    8000076c:	e426                	sd	s1,8(sp)
    8000076e:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000770:	00010497          	auipc	s1,0x10
    80000774:	48848493          	addi	s1,s1,1160 # 80010bf8 <pr>
    80000778:	00008597          	auipc	a1,0x8
    8000077c:	8c058593          	addi	a1,a1,-1856 # 80008038 <etext+0x38>
    80000780:	8526                	mv	a0,s1
    80000782:	00000097          	auipc	ra,0x0
    80000786:	3c0080e7          	jalr	960(ra) # 80000b42 <initlock>
  pr.locking = 1;
    8000078a:	4785                	li	a5,1
    8000078c:	cc9c                	sw	a5,24(s1)
}
    8000078e:	60e2                	ld	ra,24(sp)
    80000790:	6442                	ld	s0,16(sp)
    80000792:	64a2                	ld	s1,8(sp)
    80000794:	6105                	addi	sp,sp,32
    80000796:	8082                	ret

0000000080000798 <uartinit>:

void uartstart();

void
uartinit(void)
{
    80000798:	1141                	addi	sp,sp,-16
    8000079a:	e406                	sd	ra,8(sp)
    8000079c:	e022                	sd	s0,0(sp)
    8000079e:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a0:	100007b7          	lui	a5,0x10000
    800007a4:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007a8:	f8000713          	li	a4,-128
    800007ac:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b0:	470d                	li	a4,3
    800007b2:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007b6:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007ba:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007be:	469d                	li	a3,7
    800007c0:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c4:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007c8:	00008597          	auipc	a1,0x8
    800007cc:	89058593          	addi	a1,a1,-1904 # 80008058 <digits+0x18>
    800007d0:	00010517          	auipc	a0,0x10
    800007d4:	44850513          	addi	a0,a0,1096 # 80010c18 <uart_tx_lock>
    800007d8:	00000097          	auipc	ra,0x0
    800007dc:	36a080e7          	jalr	874(ra) # 80000b42 <initlock>
}
    800007e0:	60a2                	ld	ra,8(sp)
    800007e2:	6402                	ld	s0,0(sp)
    800007e4:	0141                	addi	sp,sp,16
    800007e6:	8082                	ret

00000000800007e8 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007e8:	1101                	addi	sp,sp,-32
    800007ea:	ec06                	sd	ra,24(sp)
    800007ec:	e822                	sd	s0,16(sp)
    800007ee:	e426                	sd	s1,8(sp)
    800007f0:	1000                	addi	s0,sp,32
    800007f2:	84aa                	mv	s1,a0
  push_off();
    800007f4:	00000097          	auipc	ra,0x0
    800007f8:	392080e7          	jalr	914(ra) # 80000b86 <push_off>

  if(panicked){
    800007fc:	00008797          	auipc	a5,0x8
    80000800:	1d47a783          	lw	a5,468(a5) # 800089d0 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000804:	10000737          	lui	a4,0x10000
  if(panicked){
    80000808:	c391                	beqz	a5,8000080c <uartputc_sync+0x24>
    for(;;)
    8000080a:	a001                	j	8000080a <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080c:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000810:	0207f793          	andi	a5,a5,32
    80000814:	dfe5                	beqz	a5,8000080c <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000816:	0ff4f513          	zext.b	a0,s1
    8000081a:	100007b7          	lui	a5,0x10000
    8000081e:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000822:	00000097          	auipc	ra,0x0
    80000826:	404080e7          	jalr	1028(ra) # 80000c26 <pop_off>
}
    8000082a:	60e2                	ld	ra,24(sp)
    8000082c:	6442                	ld	s0,16(sp)
    8000082e:	64a2                	ld	s1,8(sp)
    80000830:	6105                	addi	sp,sp,32
    80000832:	8082                	ret

0000000080000834 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000834:	00008797          	auipc	a5,0x8
    80000838:	1a47b783          	ld	a5,420(a5) # 800089d8 <uart_tx_r>
    8000083c:	00008717          	auipc	a4,0x8
    80000840:	1a473703          	ld	a4,420(a4) # 800089e0 <uart_tx_w>
    80000844:	06f70a63          	beq	a4,a5,800008b8 <uartstart+0x84>
{
    80000848:	7139                	addi	sp,sp,-64
    8000084a:	fc06                	sd	ra,56(sp)
    8000084c:	f822                	sd	s0,48(sp)
    8000084e:	f426                	sd	s1,40(sp)
    80000850:	f04a                	sd	s2,32(sp)
    80000852:	ec4e                	sd	s3,24(sp)
    80000854:	e852                	sd	s4,16(sp)
    80000856:	e456                	sd	s5,8(sp)
    80000858:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085a:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000085e:	00010a17          	auipc	s4,0x10
    80000862:	3baa0a13          	addi	s4,s4,954 # 80010c18 <uart_tx_lock>
    uart_tx_r += 1;
    80000866:	00008497          	auipc	s1,0x8
    8000086a:	17248493          	addi	s1,s1,370 # 800089d8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000086e:	00008997          	auipc	s3,0x8
    80000872:	17298993          	addi	s3,s3,370 # 800089e0 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000876:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087a:	02077713          	andi	a4,a4,32
    8000087e:	c705                	beqz	a4,800008a6 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000880:	01f7f713          	andi	a4,a5,31
    80000884:	9752                	add	a4,a4,s4
    80000886:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088a:	0785                	addi	a5,a5,1
    8000088c:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000088e:	8526                	mv	a0,s1
    80000890:	00002097          	auipc	ra,0x2
    80000894:	c26080e7          	jalr	-986(ra) # 800024b6 <wakeup>
    
    WriteReg(THR, c);
    80000898:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000089c:	609c                	ld	a5,0(s1)
    8000089e:	0009b703          	ld	a4,0(s3)
    800008a2:	fcf71ae3          	bne	a4,a5,80000876 <uartstart+0x42>
  }
}
    800008a6:	70e2                	ld	ra,56(sp)
    800008a8:	7442                	ld	s0,48(sp)
    800008aa:	74a2                	ld	s1,40(sp)
    800008ac:	7902                	ld	s2,32(sp)
    800008ae:	69e2                	ld	s3,24(sp)
    800008b0:	6a42                	ld	s4,16(sp)
    800008b2:	6aa2                	ld	s5,8(sp)
    800008b4:	6121                	addi	sp,sp,64
    800008b6:	8082                	ret
    800008b8:	8082                	ret

00000000800008ba <uartputc>:
{
    800008ba:	7179                	addi	sp,sp,-48
    800008bc:	f406                	sd	ra,40(sp)
    800008be:	f022                	sd	s0,32(sp)
    800008c0:	ec26                	sd	s1,24(sp)
    800008c2:	e84a                	sd	s2,16(sp)
    800008c4:	e44e                	sd	s3,8(sp)
    800008c6:	e052                	sd	s4,0(sp)
    800008c8:	1800                	addi	s0,sp,48
    800008ca:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008cc:	00010517          	auipc	a0,0x10
    800008d0:	34c50513          	addi	a0,a0,844 # 80010c18 <uart_tx_lock>
    800008d4:	00000097          	auipc	ra,0x0
    800008d8:	2fe080e7          	jalr	766(ra) # 80000bd2 <acquire>
  if(panicked){
    800008dc:	00008797          	auipc	a5,0x8
    800008e0:	0f47a783          	lw	a5,244(a5) # 800089d0 <panicked>
    800008e4:	e7c9                	bnez	a5,8000096e <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e6:	00008717          	auipc	a4,0x8
    800008ea:	0fa73703          	ld	a4,250(a4) # 800089e0 <uart_tx_w>
    800008ee:	00008797          	auipc	a5,0x8
    800008f2:	0ea7b783          	ld	a5,234(a5) # 800089d8 <uart_tx_r>
    800008f6:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fa:	00010997          	auipc	s3,0x10
    800008fe:	31e98993          	addi	s3,s3,798 # 80010c18 <uart_tx_lock>
    80000902:	00008497          	auipc	s1,0x8
    80000906:	0d648493          	addi	s1,s1,214 # 800089d8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090a:	00008917          	auipc	s2,0x8
    8000090e:	0d690913          	addi	s2,s2,214 # 800089e0 <uart_tx_w>
    80000912:	00e79f63          	bne	a5,a4,80000930 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000916:	85ce                	mv	a1,s3
    80000918:	8526                	mv	a0,s1
    8000091a:	00002097          	auipc	ra,0x2
    8000091e:	b38080e7          	jalr	-1224(ra) # 80002452 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000922:	00093703          	ld	a4,0(s2)
    80000926:	609c                	ld	a5,0(s1)
    80000928:	02078793          	addi	a5,a5,32
    8000092c:	fee785e3          	beq	a5,a4,80000916 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000930:	00010497          	auipc	s1,0x10
    80000934:	2e848493          	addi	s1,s1,744 # 80010c18 <uart_tx_lock>
    80000938:	01f77793          	andi	a5,a4,31
    8000093c:	97a6                	add	a5,a5,s1
    8000093e:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000942:	0705                	addi	a4,a4,1
    80000944:	00008797          	auipc	a5,0x8
    80000948:	08e7be23          	sd	a4,156(a5) # 800089e0 <uart_tx_w>
  uartstart();
    8000094c:	00000097          	auipc	ra,0x0
    80000950:	ee8080e7          	jalr	-280(ra) # 80000834 <uartstart>
  release(&uart_tx_lock);
    80000954:	8526                	mv	a0,s1
    80000956:	00000097          	auipc	ra,0x0
    8000095a:	330080e7          	jalr	816(ra) # 80000c86 <release>
}
    8000095e:	70a2                	ld	ra,40(sp)
    80000960:	7402                	ld	s0,32(sp)
    80000962:	64e2                	ld	s1,24(sp)
    80000964:	6942                	ld	s2,16(sp)
    80000966:	69a2                	ld	s3,8(sp)
    80000968:	6a02                	ld	s4,0(sp)
    8000096a:	6145                	addi	sp,sp,48
    8000096c:	8082                	ret
    for(;;)
    8000096e:	a001                	j	8000096e <uartputc+0xb4>

0000000080000970 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000970:	1141                	addi	sp,sp,-16
    80000972:	e422                	sd	s0,8(sp)
    80000974:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000976:	100007b7          	lui	a5,0x10000
    8000097a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000097e:	8b85                	andi	a5,a5,1
    80000980:	cb81                	beqz	a5,80000990 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000982:	100007b7          	lui	a5,0x10000
    80000986:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    8000098a:	6422                	ld	s0,8(sp)
    8000098c:	0141                	addi	sp,sp,16
    8000098e:	8082                	ret
    return -1;
    80000990:	557d                	li	a0,-1
    80000992:	bfe5                	j	8000098a <uartgetc+0x1a>

0000000080000994 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    80000994:	1101                	addi	sp,sp,-32
    80000996:	ec06                	sd	ra,24(sp)
    80000998:	e822                	sd	s0,16(sp)
    8000099a:	e426                	sd	s1,8(sp)
    8000099c:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    8000099e:	54fd                	li	s1,-1
    800009a0:	a029                	j	800009aa <uartintr+0x16>
      break;
    consoleintr(c);
    800009a2:	00000097          	auipc	ra,0x0
    800009a6:	918080e7          	jalr	-1768(ra) # 800002ba <consoleintr>
    int c = uartgetc();
    800009aa:	00000097          	auipc	ra,0x0
    800009ae:	fc6080e7          	jalr	-58(ra) # 80000970 <uartgetc>
    if(c == -1)
    800009b2:	fe9518e3          	bne	a0,s1,800009a2 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009b6:	00010497          	auipc	s1,0x10
    800009ba:	26248493          	addi	s1,s1,610 # 80010c18 <uart_tx_lock>
    800009be:	8526                	mv	a0,s1
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	212080e7          	jalr	530(ra) # 80000bd2 <acquire>
  uartstart();
    800009c8:	00000097          	auipc	ra,0x0
    800009cc:	e6c080e7          	jalr	-404(ra) # 80000834 <uartstart>
  release(&uart_tx_lock);
    800009d0:	8526                	mv	a0,s1
    800009d2:	00000097          	auipc	ra,0x0
    800009d6:	2b4080e7          	jalr	692(ra) # 80000c86 <release>
}
    800009da:	60e2                	ld	ra,24(sp)
    800009dc:	6442                	ld	s0,16(sp)
    800009de:	64a2                	ld	s1,8(sp)
    800009e0:	6105                	addi	sp,sp,32
    800009e2:	8082                	ret

00000000800009e4 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009e4:	1101                	addi	sp,sp,-32
    800009e6:	ec06                	sd	ra,24(sp)
    800009e8:	e822                	sd	s0,16(sp)
    800009ea:	e426                	sd	s1,8(sp)
    800009ec:	e04a                	sd	s2,0(sp)
    800009ee:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f0:	03451793          	slli	a5,a0,0x34
    800009f4:	ebb9                	bnez	a5,80000a4a <kfree+0x66>
    800009f6:	84aa                	mv	s1,a0
    800009f8:	00021797          	auipc	a5,0x21
    800009fc:	48878793          	addi	a5,a5,1160 # 80021e80 <end>
    80000a00:	04f56563          	bltu	a0,a5,80000a4a <kfree+0x66>
    80000a04:	47c5                	li	a5,17
    80000a06:	07ee                	slli	a5,a5,0x1b
    80000a08:	04f57163          	bgeu	a0,a5,80000a4a <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a0c:	6605                	lui	a2,0x1
    80000a0e:	4585                	li	a1,1
    80000a10:	00000097          	auipc	ra,0x0
    80000a14:	2be080e7          	jalr	702(ra) # 80000cce <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a18:	00010917          	auipc	s2,0x10
    80000a1c:	23890913          	addi	s2,s2,568 # 80010c50 <kmem>
    80000a20:	854a                	mv	a0,s2
    80000a22:	00000097          	auipc	ra,0x0
    80000a26:	1b0080e7          	jalr	432(ra) # 80000bd2 <acquire>
  r->next = kmem.freelist;
    80000a2a:	01893783          	ld	a5,24(s2)
    80000a2e:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a30:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a34:	854a                	mv	a0,s2
    80000a36:	00000097          	auipc	ra,0x0
    80000a3a:	250080e7          	jalr	592(ra) # 80000c86 <release>
}
    80000a3e:	60e2                	ld	ra,24(sp)
    80000a40:	6442                	ld	s0,16(sp)
    80000a42:	64a2                	ld	s1,8(sp)
    80000a44:	6902                	ld	s2,0(sp)
    80000a46:	6105                	addi	sp,sp,32
    80000a48:	8082                	ret
    panic("kfree");
    80000a4a:	00007517          	auipc	a0,0x7
    80000a4e:	61650513          	addi	a0,a0,1558 # 80008060 <digits+0x20>
    80000a52:	00000097          	auipc	ra,0x0
    80000a56:	aea080e7          	jalr	-1302(ra) # 8000053c <panic>

0000000080000a5a <freerange>:
{
    80000a5a:	7179                	addi	sp,sp,-48
    80000a5c:	f406                	sd	ra,40(sp)
    80000a5e:	f022                	sd	s0,32(sp)
    80000a60:	ec26                	sd	s1,24(sp)
    80000a62:	e84a                	sd	s2,16(sp)
    80000a64:	e44e                	sd	s3,8(sp)
    80000a66:	e052                	sd	s4,0(sp)
    80000a68:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a6a:	6785                	lui	a5,0x1
    80000a6c:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000a70:	00e504b3          	add	s1,a0,a4
    80000a74:	777d                	lui	a4,0xfffff
    80000a76:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a78:	94be                	add	s1,s1,a5
    80000a7a:	0095ee63          	bltu	a1,s1,80000a96 <freerange+0x3c>
    80000a7e:	892e                	mv	s2,a1
    kfree(p);
    80000a80:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a82:	6985                	lui	s3,0x1
    kfree(p);
    80000a84:	01448533          	add	a0,s1,s4
    80000a88:	00000097          	auipc	ra,0x0
    80000a8c:	f5c080e7          	jalr	-164(ra) # 800009e4 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a90:	94ce                	add	s1,s1,s3
    80000a92:	fe9979e3          	bgeu	s2,s1,80000a84 <freerange+0x2a>
}
    80000a96:	70a2                	ld	ra,40(sp)
    80000a98:	7402                	ld	s0,32(sp)
    80000a9a:	64e2                	ld	s1,24(sp)
    80000a9c:	6942                	ld	s2,16(sp)
    80000a9e:	69a2                	ld	s3,8(sp)
    80000aa0:	6a02                	ld	s4,0(sp)
    80000aa2:	6145                	addi	sp,sp,48
    80000aa4:	8082                	ret

0000000080000aa6 <kinit>:
{
    80000aa6:	1141                	addi	sp,sp,-16
    80000aa8:	e406                	sd	ra,8(sp)
    80000aaa:	e022                	sd	s0,0(sp)
    80000aac:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000aae:	00007597          	auipc	a1,0x7
    80000ab2:	5ba58593          	addi	a1,a1,1466 # 80008068 <digits+0x28>
    80000ab6:	00010517          	auipc	a0,0x10
    80000aba:	19a50513          	addi	a0,a0,410 # 80010c50 <kmem>
    80000abe:	00000097          	auipc	ra,0x0
    80000ac2:	084080e7          	jalr	132(ra) # 80000b42 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ac6:	45c5                	li	a1,17
    80000ac8:	05ee                	slli	a1,a1,0x1b
    80000aca:	00021517          	auipc	a0,0x21
    80000ace:	3b650513          	addi	a0,a0,950 # 80021e80 <end>
    80000ad2:	00000097          	auipc	ra,0x0
    80000ad6:	f88080e7          	jalr	-120(ra) # 80000a5a <freerange>
}
    80000ada:	60a2                	ld	ra,8(sp)
    80000adc:	6402                	ld	s0,0(sp)
    80000ade:	0141                	addi	sp,sp,16
    80000ae0:	8082                	ret

0000000080000ae2 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae2:	1101                	addi	sp,sp,-32
    80000ae4:	ec06                	sd	ra,24(sp)
    80000ae6:	e822                	sd	s0,16(sp)
    80000ae8:	e426                	sd	s1,8(sp)
    80000aea:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000aec:	00010497          	auipc	s1,0x10
    80000af0:	16448493          	addi	s1,s1,356 # 80010c50 <kmem>
    80000af4:	8526                	mv	a0,s1
    80000af6:	00000097          	auipc	ra,0x0
    80000afa:	0dc080e7          	jalr	220(ra) # 80000bd2 <acquire>
  r = kmem.freelist;
    80000afe:	6c84                	ld	s1,24(s1)
  if(r)
    80000b00:	c885                	beqz	s1,80000b30 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b02:	609c                	ld	a5,0(s1)
    80000b04:	00010517          	auipc	a0,0x10
    80000b08:	14c50513          	addi	a0,a0,332 # 80010c50 <kmem>
    80000b0c:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b0e:	00000097          	auipc	ra,0x0
    80000b12:	178080e7          	jalr	376(ra) # 80000c86 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b16:	6605                	lui	a2,0x1
    80000b18:	4595                	li	a1,5
    80000b1a:	8526                	mv	a0,s1
    80000b1c:	00000097          	auipc	ra,0x0
    80000b20:	1b2080e7          	jalr	434(ra) # 80000cce <memset>
  return (void*)r;
}
    80000b24:	8526                	mv	a0,s1
    80000b26:	60e2                	ld	ra,24(sp)
    80000b28:	6442                	ld	s0,16(sp)
    80000b2a:	64a2                	ld	s1,8(sp)
    80000b2c:	6105                	addi	sp,sp,32
    80000b2e:	8082                	ret
  release(&kmem.lock);
    80000b30:	00010517          	auipc	a0,0x10
    80000b34:	12050513          	addi	a0,a0,288 # 80010c50 <kmem>
    80000b38:	00000097          	auipc	ra,0x0
    80000b3c:	14e080e7          	jalr	334(ra) # 80000c86 <release>
  if(r)
    80000b40:	b7d5                	j	80000b24 <kalloc+0x42>

0000000080000b42 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b42:	1141                	addi	sp,sp,-16
    80000b44:	e422                	sd	s0,8(sp)
    80000b46:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b48:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b4a:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b4e:	00053823          	sd	zero,16(a0)
}
    80000b52:	6422                	ld	s0,8(sp)
    80000b54:	0141                	addi	sp,sp,16
    80000b56:	8082                	ret

0000000080000b58 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b58:	411c                	lw	a5,0(a0)
    80000b5a:	e399                	bnez	a5,80000b60 <holding+0x8>
    80000b5c:	4501                	li	a0,0
  return r;
}
    80000b5e:	8082                	ret
{
    80000b60:	1101                	addi	sp,sp,-32
    80000b62:	ec06                	sd	ra,24(sp)
    80000b64:	e822                	sd	s0,16(sp)
    80000b66:	e426                	sd	s1,8(sp)
    80000b68:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b6a:	6904                	ld	s1,16(a0)
    80000b6c:	00001097          	auipc	ra,0x1
    80000b70:	10c080e7          	jalr	268(ra) # 80001c78 <mycpu>
    80000b74:	40a48533          	sub	a0,s1,a0
    80000b78:	00153513          	seqz	a0,a0
}
    80000b7c:	60e2                	ld	ra,24(sp)
    80000b7e:	6442                	ld	s0,16(sp)
    80000b80:	64a2                	ld	s1,8(sp)
    80000b82:	6105                	addi	sp,sp,32
    80000b84:	8082                	ret

0000000080000b86 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b86:	1101                	addi	sp,sp,-32
    80000b88:	ec06                	sd	ra,24(sp)
    80000b8a:	e822                	sd	s0,16(sp)
    80000b8c:	e426                	sd	s1,8(sp)
    80000b8e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b90:	100024f3          	csrr	s1,sstatus
    80000b94:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b98:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b9a:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000b9e:	00001097          	auipc	ra,0x1
    80000ba2:	0da080e7          	jalr	218(ra) # 80001c78 <mycpu>
    80000ba6:	5d3c                	lw	a5,120(a0)
    80000ba8:	cf89                	beqz	a5,80000bc2 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000baa:	00001097          	auipc	ra,0x1
    80000bae:	0ce080e7          	jalr	206(ra) # 80001c78 <mycpu>
    80000bb2:	5d3c                	lw	a5,120(a0)
    80000bb4:	2785                	addiw	a5,a5,1
    80000bb6:	dd3c                	sw	a5,120(a0)
}
    80000bb8:	60e2                	ld	ra,24(sp)
    80000bba:	6442                	ld	s0,16(sp)
    80000bbc:	64a2                	ld	s1,8(sp)
    80000bbe:	6105                	addi	sp,sp,32
    80000bc0:	8082                	ret
    mycpu()->intena = old;
    80000bc2:	00001097          	auipc	ra,0x1
    80000bc6:	0b6080e7          	jalr	182(ra) # 80001c78 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bca:	8085                	srli	s1,s1,0x1
    80000bcc:	8885                	andi	s1,s1,1
    80000bce:	dd64                	sw	s1,124(a0)
    80000bd0:	bfe9                	j	80000baa <push_off+0x24>

0000000080000bd2 <acquire>:
{
    80000bd2:	1101                	addi	sp,sp,-32
    80000bd4:	ec06                	sd	ra,24(sp)
    80000bd6:	e822                	sd	s0,16(sp)
    80000bd8:	e426                	sd	s1,8(sp)
    80000bda:	1000                	addi	s0,sp,32
    80000bdc:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bde:	00000097          	auipc	ra,0x0
    80000be2:	fa8080e7          	jalr	-88(ra) # 80000b86 <push_off>
  if(holding(lk))
    80000be6:	8526                	mv	a0,s1
    80000be8:	00000097          	auipc	ra,0x0
    80000bec:	f70080e7          	jalr	-144(ra) # 80000b58 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf0:	4705                	li	a4,1
  if(holding(lk))
    80000bf2:	e115                	bnez	a0,80000c16 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf4:	87ba                	mv	a5,a4
    80000bf6:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bfa:	2781                	sext.w	a5,a5
    80000bfc:	ffe5                	bnez	a5,80000bf4 <acquire+0x22>
  __sync_synchronize();
    80000bfe:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c02:	00001097          	auipc	ra,0x1
    80000c06:	076080e7          	jalr	118(ra) # 80001c78 <mycpu>
    80000c0a:	e888                	sd	a0,16(s1)
}
    80000c0c:	60e2                	ld	ra,24(sp)
    80000c0e:	6442                	ld	s0,16(sp)
    80000c10:	64a2                	ld	s1,8(sp)
    80000c12:	6105                	addi	sp,sp,32
    80000c14:	8082                	ret
    panic("acquire");
    80000c16:	00007517          	auipc	a0,0x7
    80000c1a:	45a50513          	addi	a0,a0,1114 # 80008070 <digits+0x30>
    80000c1e:	00000097          	auipc	ra,0x0
    80000c22:	91e080e7          	jalr	-1762(ra) # 8000053c <panic>

0000000080000c26 <pop_off>:

void
pop_off(void)
{
    80000c26:	1141                	addi	sp,sp,-16
    80000c28:	e406                	sd	ra,8(sp)
    80000c2a:	e022                	sd	s0,0(sp)
    80000c2c:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c2e:	00001097          	auipc	ra,0x1
    80000c32:	04a080e7          	jalr	74(ra) # 80001c78 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c36:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c3a:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c3c:	e78d                	bnez	a5,80000c66 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c3e:	5d3c                	lw	a5,120(a0)
    80000c40:	02f05b63          	blez	a5,80000c76 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c44:	37fd                	addiw	a5,a5,-1
    80000c46:	0007871b          	sext.w	a4,a5
    80000c4a:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c4c:	eb09                	bnez	a4,80000c5e <pop_off+0x38>
    80000c4e:	5d7c                	lw	a5,124(a0)
    80000c50:	c799                	beqz	a5,80000c5e <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c52:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c56:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c5a:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c5e:	60a2                	ld	ra,8(sp)
    80000c60:	6402                	ld	s0,0(sp)
    80000c62:	0141                	addi	sp,sp,16
    80000c64:	8082                	ret
    panic("pop_off - interruptible");
    80000c66:	00007517          	auipc	a0,0x7
    80000c6a:	41250513          	addi	a0,a0,1042 # 80008078 <digits+0x38>
    80000c6e:	00000097          	auipc	ra,0x0
    80000c72:	8ce080e7          	jalr	-1842(ra) # 8000053c <panic>
    panic("pop_off");
    80000c76:	00007517          	auipc	a0,0x7
    80000c7a:	41a50513          	addi	a0,a0,1050 # 80008090 <digits+0x50>
    80000c7e:	00000097          	auipc	ra,0x0
    80000c82:	8be080e7          	jalr	-1858(ra) # 8000053c <panic>

0000000080000c86 <release>:
{
    80000c86:	1101                	addi	sp,sp,-32
    80000c88:	ec06                	sd	ra,24(sp)
    80000c8a:	e822                	sd	s0,16(sp)
    80000c8c:	e426                	sd	s1,8(sp)
    80000c8e:	1000                	addi	s0,sp,32
    80000c90:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c92:	00000097          	auipc	ra,0x0
    80000c96:	ec6080e7          	jalr	-314(ra) # 80000b58 <holding>
    80000c9a:	c115                	beqz	a0,80000cbe <release+0x38>
  lk->cpu = 0;
    80000c9c:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ca0:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca4:	0f50000f          	fence	iorw,ow
    80000ca8:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cac:	00000097          	auipc	ra,0x0
    80000cb0:	f7a080e7          	jalr	-134(ra) # 80000c26 <pop_off>
}
    80000cb4:	60e2                	ld	ra,24(sp)
    80000cb6:	6442                	ld	s0,16(sp)
    80000cb8:	64a2                	ld	s1,8(sp)
    80000cba:	6105                	addi	sp,sp,32
    80000cbc:	8082                	ret
    panic("release");
    80000cbe:	00007517          	auipc	a0,0x7
    80000cc2:	3da50513          	addi	a0,a0,986 # 80008098 <digits+0x58>
    80000cc6:	00000097          	auipc	ra,0x0
    80000cca:	876080e7          	jalr	-1930(ra) # 8000053c <panic>

0000000080000cce <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cce:	1141                	addi	sp,sp,-16
    80000cd0:	e422                	sd	s0,8(sp)
    80000cd2:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd4:	ca19                	beqz	a2,80000cea <memset+0x1c>
    80000cd6:	87aa                	mv	a5,a0
    80000cd8:	1602                	slli	a2,a2,0x20
    80000cda:	9201                	srli	a2,a2,0x20
    80000cdc:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000ce0:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce4:	0785                	addi	a5,a5,1
    80000ce6:	fee79de3          	bne	a5,a4,80000ce0 <memset+0x12>
  }
  return dst;
}
    80000cea:	6422                	ld	s0,8(sp)
    80000cec:	0141                	addi	sp,sp,16
    80000cee:	8082                	ret

0000000080000cf0 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cf0:	1141                	addi	sp,sp,-16
    80000cf2:	e422                	sd	s0,8(sp)
    80000cf4:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cf6:	ca05                	beqz	a2,80000d26 <memcmp+0x36>
    80000cf8:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000cfc:	1682                	slli	a3,a3,0x20
    80000cfe:	9281                	srli	a3,a3,0x20
    80000d00:	0685                	addi	a3,a3,1
    80000d02:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d04:	00054783          	lbu	a5,0(a0)
    80000d08:	0005c703          	lbu	a4,0(a1)
    80000d0c:	00e79863          	bne	a5,a4,80000d1c <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d10:	0505                	addi	a0,a0,1
    80000d12:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d14:	fed518e3          	bne	a0,a3,80000d04 <memcmp+0x14>
  }

  return 0;
    80000d18:	4501                	li	a0,0
    80000d1a:	a019                	j	80000d20 <memcmp+0x30>
      return *s1 - *s2;
    80000d1c:	40e7853b          	subw	a0,a5,a4
}
    80000d20:	6422                	ld	s0,8(sp)
    80000d22:	0141                	addi	sp,sp,16
    80000d24:	8082                	ret
  return 0;
    80000d26:	4501                	li	a0,0
    80000d28:	bfe5                	j	80000d20 <memcmp+0x30>

0000000080000d2a <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d2a:	1141                	addi	sp,sp,-16
    80000d2c:	e422                	sd	s0,8(sp)
    80000d2e:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d30:	c205                	beqz	a2,80000d50 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d32:	02a5e263          	bltu	a1,a0,80000d56 <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d36:	1602                	slli	a2,a2,0x20
    80000d38:	9201                	srli	a2,a2,0x20
    80000d3a:	00c587b3          	add	a5,a1,a2
{
    80000d3e:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d40:	0585                	addi	a1,a1,1
    80000d42:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffdd181>
    80000d44:	fff5c683          	lbu	a3,-1(a1)
    80000d48:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d4c:	fef59ae3          	bne	a1,a5,80000d40 <memmove+0x16>

  return dst;
}
    80000d50:	6422                	ld	s0,8(sp)
    80000d52:	0141                	addi	sp,sp,16
    80000d54:	8082                	ret
  if(s < d && s + n > d){
    80000d56:	02061693          	slli	a3,a2,0x20
    80000d5a:	9281                	srli	a3,a3,0x20
    80000d5c:	00d58733          	add	a4,a1,a3
    80000d60:	fce57be3          	bgeu	a0,a4,80000d36 <memmove+0xc>
    d += n;
    80000d64:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d66:	fff6079b          	addiw	a5,a2,-1
    80000d6a:	1782                	slli	a5,a5,0x20
    80000d6c:	9381                	srli	a5,a5,0x20
    80000d6e:	fff7c793          	not	a5,a5
    80000d72:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d74:	177d                	addi	a4,a4,-1
    80000d76:	16fd                	addi	a3,a3,-1
    80000d78:	00074603          	lbu	a2,0(a4)
    80000d7c:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d80:	fee79ae3          	bne	a5,a4,80000d74 <memmove+0x4a>
    80000d84:	b7f1                	j	80000d50 <memmove+0x26>

0000000080000d86 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d86:	1141                	addi	sp,sp,-16
    80000d88:	e406                	sd	ra,8(sp)
    80000d8a:	e022                	sd	s0,0(sp)
    80000d8c:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d8e:	00000097          	auipc	ra,0x0
    80000d92:	f9c080e7          	jalr	-100(ra) # 80000d2a <memmove>
}
    80000d96:	60a2                	ld	ra,8(sp)
    80000d98:	6402                	ld	s0,0(sp)
    80000d9a:	0141                	addi	sp,sp,16
    80000d9c:	8082                	ret

0000000080000d9e <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000d9e:	1141                	addi	sp,sp,-16
    80000da0:	e422                	sd	s0,8(sp)
    80000da2:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da4:	ce11                	beqz	a2,80000dc0 <strncmp+0x22>
    80000da6:	00054783          	lbu	a5,0(a0)
    80000daa:	cf89                	beqz	a5,80000dc4 <strncmp+0x26>
    80000dac:	0005c703          	lbu	a4,0(a1)
    80000db0:	00f71a63          	bne	a4,a5,80000dc4 <strncmp+0x26>
    n--, p++, q++;
    80000db4:	367d                	addiw	a2,a2,-1
    80000db6:	0505                	addi	a0,a0,1
    80000db8:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dba:	f675                	bnez	a2,80000da6 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dbc:	4501                	li	a0,0
    80000dbe:	a809                	j	80000dd0 <strncmp+0x32>
    80000dc0:	4501                	li	a0,0
    80000dc2:	a039                	j	80000dd0 <strncmp+0x32>
  if(n == 0)
    80000dc4:	ca09                	beqz	a2,80000dd6 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dc6:	00054503          	lbu	a0,0(a0)
    80000dca:	0005c783          	lbu	a5,0(a1)
    80000dce:	9d1d                	subw	a0,a0,a5
}
    80000dd0:	6422                	ld	s0,8(sp)
    80000dd2:	0141                	addi	sp,sp,16
    80000dd4:	8082                	ret
    return 0;
    80000dd6:	4501                	li	a0,0
    80000dd8:	bfe5                	j	80000dd0 <strncmp+0x32>

0000000080000dda <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dda:	1141                	addi	sp,sp,-16
    80000ddc:	e422                	sd	s0,8(sp)
    80000dde:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000de0:	87aa                	mv	a5,a0
    80000de2:	86b2                	mv	a3,a2
    80000de4:	367d                	addiw	a2,a2,-1
    80000de6:	00d05963          	blez	a3,80000df8 <strncpy+0x1e>
    80000dea:	0785                	addi	a5,a5,1
    80000dec:	0005c703          	lbu	a4,0(a1)
    80000df0:	fee78fa3          	sb	a4,-1(a5)
    80000df4:	0585                	addi	a1,a1,1
    80000df6:	f775                	bnez	a4,80000de2 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000df8:	873e                	mv	a4,a5
    80000dfa:	9fb5                	addw	a5,a5,a3
    80000dfc:	37fd                	addiw	a5,a5,-1
    80000dfe:	00c05963          	blez	a2,80000e10 <strncpy+0x36>
    *s++ = 0;
    80000e02:	0705                	addi	a4,a4,1
    80000e04:	fe070fa3          	sb	zero,-1(a4)
  while(n-- > 0)
    80000e08:	40e786bb          	subw	a3,a5,a4
    80000e0c:	fed04be3          	bgtz	a3,80000e02 <strncpy+0x28>
  return os;
}
    80000e10:	6422                	ld	s0,8(sp)
    80000e12:	0141                	addi	sp,sp,16
    80000e14:	8082                	ret

0000000080000e16 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e16:	1141                	addi	sp,sp,-16
    80000e18:	e422                	sd	s0,8(sp)
    80000e1a:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e1c:	02c05363          	blez	a2,80000e42 <safestrcpy+0x2c>
    80000e20:	fff6069b          	addiw	a3,a2,-1
    80000e24:	1682                	slli	a3,a3,0x20
    80000e26:	9281                	srli	a3,a3,0x20
    80000e28:	96ae                	add	a3,a3,a1
    80000e2a:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e2c:	00d58963          	beq	a1,a3,80000e3e <safestrcpy+0x28>
    80000e30:	0585                	addi	a1,a1,1
    80000e32:	0785                	addi	a5,a5,1
    80000e34:	fff5c703          	lbu	a4,-1(a1)
    80000e38:	fee78fa3          	sb	a4,-1(a5)
    80000e3c:	fb65                	bnez	a4,80000e2c <safestrcpy+0x16>
    ;
  *s = 0;
    80000e3e:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e42:	6422                	ld	s0,8(sp)
    80000e44:	0141                	addi	sp,sp,16
    80000e46:	8082                	ret

0000000080000e48 <strlen>:

int
strlen(const char *s)
{
    80000e48:	1141                	addi	sp,sp,-16
    80000e4a:	e422                	sd	s0,8(sp)
    80000e4c:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e4e:	00054783          	lbu	a5,0(a0)
    80000e52:	cf91                	beqz	a5,80000e6e <strlen+0x26>
    80000e54:	0505                	addi	a0,a0,1
    80000e56:	87aa                	mv	a5,a0
    80000e58:	86be                	mv	a3,a5
    80000e5a:	0785                	addi	a5,a5,1
    80000e5c:	fff7c703          	lbu	a4,-1(a5)
    80000e60:	ff65                	bnez	a4,80000e58 <strlen+0x10>
    80000e62:	40a6853b          	subw	a0,a3,a0
    80000e66:	2505                	addiw	a0,a0,1
    ;
  return n;
}
    80000e68:	6422                	ld	s0,8(sp)
    80000e6a:	0141                	addi	sp,sp,16
    80000e6c:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e6e:	4501                	li	a0,0
    80000e70:	bfe5                	j	80000e68 <strlen+0x20>

0000000080000e72 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e72:	1141                	addi	sp,sp,-16
    80000e74:	e406                	sd	ra,8(sp)
    80000e76:	e022                	sd	s0,0(sp)
    80000e78:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e7a:	00001097          	auipc	ra,0x1
    80000e7e:	dee080e7          	jalr	-530(ra) # 80001c68 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e82:	00008717          	auipc	a4,0x8
    80000e86:	b6670713          	addi	a4,a4,-1178 # 800089e8 <started>
  if(cpuid() == 0){
    80000e8a:	c139                	beqz	a0,80000ed0 <main+0x5e>
    while(started == 0)
    80000e8c:	431c                	lw	a5,0(a4)
    80000e8e:	2781                	sext.w	a5,a5
    80000e90:	dff5                	beqz	a5,80000e8c <main+0x1a>
      ;
    __sync_synchronize();
    80000e92:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e96:	00001097          	auipc	ra,0x1
    80000e9a:	dd2080e7          	jalr	-558(ra) # 80001c68 <cpuid>
    80000e9e:	85aa                	mv	a1,a0
    80000ea0:	00007517          	auipc	a0,0x7
    80000ea4:	21850513          	addi	a0,a0,536 # 800080b8 <digits+0x78>
    80000ea8:	fffff097          	auipc	ra,0xfffff
    80000eac:	6de080e7          	jalr	1758(ra) # 80000586 <printf>
    kvminithart();    // turn on paging
    80000eb0:	00000097          	auipc	ra,0x0
    80000eb4:	0d8080e7          	jalr	216(ra) # 80000f88 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eb8:	00002097          	auipc	ra,0x2
    80000ebc:	cd6080e7          	jalr	-810(ra) # 80002b8e <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec0:	00005097          	auipc	ra,0x5
    80000ec4:	2a0080e7          	jalr	672(ra) # 80006160 <plicinithart>
  }

  scheduler();        
    80000ec8:	00001097          	auipc	ra,0x1
    80000ecc:	412080e7          	jalr	1042(ra) # 800022da <scheduler>
    consoleinit();
    80000ed0:	fffff097          	auipc	ra,0xfffff
    80000ed4:	57c080e7          	jalr	1404(ra) # 8000044c <consoleinit>
    printfinit();
    80000ed8:	00000097          	auipc	ra,0x0
    80000edc:	88e080e7          	jalr	-1906(ra) # 80000766 <printfinit>
    printf("\n");
    80000ee0:	00007517          	auipc	a0,0x7
    80000ee4:	1e850513          	addi	a0,a0,488 # 800080c8 <digits+0x88>
    80000ee8:	fffff097          	auipc	ra,0xfffff
    80000eec:	69e080e7          	jalr	1694(ra) # 80000586 <printf>
    printf("xv6 kernel is booting\n");
    80000ef0:	00007517          	auipc	a0,0x7
    80000ef4:	1b050513          	addi	a0,a0,432 # 800080a0 <digits+0x60>
    80000ef8:	fffff097          	auipc	ra,0xfffff
    80000efc:	68e080e7          	jalr	1678(ra) # 80000586 <printf>
    printf("\n");
    80000f00:	00007517          	auipc	a0,0x7
    80000f04:	1c850513          	addi	a0,a0,456 # 800080c8 <digits+0x88>
    80000f08:	fffff097          	auipc	ra,0xfffff
    80000f0c:	67e080e7          	jalr	1662(ra) # 80000586 <printf>
    kinit();         // physical page allocator
    80000f10:	00000097          	auipc	ra,0x0
    80000f14:	b96080e7          	jalr	-1130(ra) # 80000aa6 <kinit>
    kvminit();       // create kernel page table
    80000f18:	00000097          	auipc	ra,0x0
    80000f1c:	326080e7          	jalr	806(ra) # 8000123e <kvminit>
    kvminithart();   // turn on paging
    80000f20:	00000097          	auipc	ra,0x0
    80000f24:	068080e7          	jalr	104(ra) # 80000f88 <kvminithart>
    procinit();      // process table
    80000f28:	00001097          	auipc	ra,0x1
    80000f2c:	c68080e7          	jalr	-920(ra) # 80001b90 <procinit>
    trapinit();      // trap vectors
    80000f30:	00002097          	auipc	ra,0x2
    80000f34:	c36080e7          	jalr	-970(ra) # 80002b66 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f38:	00002097          	auipc	ra,0x2
    80000f3c:	c56080e7          	jalr	-938(ra) # 80002b8e <trapinithart>
    plicinit();      // set up interrupt controller
    80000f40:	00005097          	auipc	ra,0x5
    80000f44:	20a080e7          	jalr	522(ra) # 8000614a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f48:	00005097          	auipc	ra,0x5
    80000f4c:	218080e7          	jalr	536(ra) # 80006160 <plicinithart>
    binit();         // buffer cache
    80000f50:	00002097          	auipc	ra,0x2
    80000f54:	40e080e7          	jalr	1038(ra) # 8000335e <binit>
    iinit();         // inode table
    80000f58:	00003097          	auipc	ra,0x3
    80000f5c:	aac080e7          	jalr	-1364(ra) # 80003a04 <iinit>
    fileinit();      // file table
    80000f60:	00004097          	auipc	ra,0x4
    80000f64:	a22080e7          	jalr	-1502(ra) # 80004982 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f68:	00005097          	auipc	ra,0x5
    80000f6c:	300080e7          	jalr	768(ra) # 80006268 <virtio_disk_init>
    userinit();      // first user process
    80000f70:	00001097          	auipc	ra,0x1
    80000f74:	ffc080e7          	jalr	-4(ra) # 80001f6c <userinit>
    __sync_synchronize();
    80000f78:	0ff0000f          	fence
    started = 1;
    80000f7c:	4785                	li	a5,1
    80000f7e:	00008717          	auipc	a4,0x8
    80000f82:	a6f72523          	sw	a5,-1430(a4) # 800089e8 <started>
    80000f86:	b789                	j	80000ec8 <main+0x56>

0000000080000f88 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f88:	1141                	addi	sp,sp,-16
    80000f8a:	e422                	sd	s0,8(sp)
    80000f8c:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f8e:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000f92:	00008797          	auipc	a5,0x8
    80000f96:	a5e7b783          	ld	a5,-1442(a5) # 800089f0 <kernel_pagetable>
    80000f9a:	83b1                	srli	a5,a5,0xc
    80000f9c:	577d                	li	a4,-1
    80000f9e:	177e                	slli	a4,a4,0x3f
    80000fa0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fa2:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fa6:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000faa:	6422                	ld	s0,8(sp)
    80000fac:	0141                	addi	sp,sp,16
    80000fae:	8082                	ret

0000000080000fb0 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fb0:	7139                	addi	sp,sp,-64
    80000fb2:	fc06                	sd	ra,56(sp)
    80000fb4:	f822                	sd	s0,48(sp)
    80000fb6:	f426                	sd	s1,40(sp)
    80000fb8:	f04a                	sd	s2,32(sp)
    80000fba:	ec4e                	sd	s3,24(sp)
    80000fbc:	e852                	sd	s4,16(sp)
    80000fbe:	e456                	sd	s5,8(sp)
    80000fc0:	e05a                	sd	s6,0(sp)
    80000fc2:	0080                	addi	s0,sp,64
    80000fc4:	84aa                	mv	s1,a0
    80000fc6:	89ae                	mv	s3,a1
    80000fc8:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fca:	57fd                	li	a5,-1
    80000fcc:	83e9                	srli	a5,a5,0x1a
    80000fce:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fd0:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fd2:	04b7f263          	bgeu	a5,a1,80001016 <walk+0x66>
    panic("walk");
    80000fd6:	00007517          	auipc	a0,0x7
    80000fda:	0fa50513          	addi	a0,a0,250 # 800080d0 <digits+0x90>
    80000fde:	fffff097          	auipc	ra,0xfffff
    80000fe2:	55e080e7          	jalr	1374(ra) # 8000053c <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fe6:	060a8663          	beqz	s5,80001052 <walk+0xa2>
    80000fea:	00000097          	auipc	ra,0x0
    80000fee:	af8080e7          	jalr	-1288(ra) # 80000ae2 <kalloc>
    80000ff2:	84aa                	mv	s1,a0
    80000ff4:	c529                	beqz	a0,8000103e <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000ff6:	6605                	lui	a2,0x1
    80000ff8:	4581                	li	a1,0
    80000ffa:	00000097          	auipc	ra,0x0
    80000ffe:	cd4080e7          	jalr	-812(ra) # 80000cce <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001002:	00c4d793          	srli	a5,s1,0xc
    80001006:	07aa                	slli	a5,a5,0xa
    80001008:	0017e793          	ori	a5,a5,1
    8000100c:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001010:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffdd177>
    80001012:	036a0063          	beq	s4,s6,80001032 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001016:	0149d933          	srl	s2,s3,s4
    8000101a:	1ff97913          	andi	s2,s2,511
    8000101e:	090e                	slli	s2,s2,0x3
    80001020:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001022:	00093483          	ld	s1,0(s2)
    80001026:	0014f793          	andi	a5,s1,1
    8000102a:	dfd5                	beqz	a5,80000fe6 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000102c:	80a9                	srli	s1,s1,0xa
    8000102e:	04b2                	slli	s1,s1,0xc
    80001030:	b7c5                	j	80001010 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001032:	00c9d513          	srli	a0,s3,0xc
    80001036:	1ff57513          	andi	a0,a0,511
    8000103a:	050e                	slli	a0,a0,0x3
    8000103c:	9526                	add	a0,a0,s1
}
    8000103e:	70e2                	ld	ra,56(sp)
    80001040:	7442                	ld	s0,48(sp)
    80001042:	74a2                	ld	s1,40(sp)
    80001044:	7902                	ld	s2,32(sp)
    80001046:	69e2                	ld	s3,24(sp)
    80001048:	6a42                	ld	s4,16(sp)
    8000104a:	6aa2                	ld	s5,8(sp)
    8000104c:	6b02                	ld	s6,0(sp)
    8000104e:	6121                	addi	sp,sp,64
    80001050:	8082                	ret
        return 0;
    80001052:	4501                	li	a0,0
    80001054:	b7ed                	j	8000103e <walk+0x8e>

0000000080001056 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001056:	57fd                	li	a5,-1
    80001058:	83e9                	srli	a5,a5,0x1a
    8000105a:	00b7f463          	bgeu	a5,a1,80001062 <walkaddr+0xc>
    return 0;
    8000105e:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001060:	8082                	ret
{
    80001062:	1141                	addi	sp,sp,-16
    80001064:	e406                	sd	ra,8(sp)
    80001066:	e022                	sd	s0,0(sp)
    80001068:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    8000106a:	4601                	li	a2,0
    8000106c:	00000097          	auipc	ra,0x0
    80001070:	f44080e7          	jalr	-188(ra) # 80000fb0 <walk>
  if(pte == 0)
    80001074:	c105                	beqz	a0,80001094 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001076:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001078:	0117f693          	andi	a3,a5,17
    8000107c:	4745                	li	a4,17
    return 0;
    8000107e:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001080:	00e68663          	beq	a3,a4,8000108c <walkaddr+0x36>
}
    80001084:	60a2                	ld	ra,8(sp)
    80001086:	6402                	ld	s0,0(sp)
    80001088:	0141                	addi	sp,sp,16
    8000108a:	8082                	ret
  pa = PTE2PA(*pte);
    8000108c:	83a9                	srli	a5,a5,0xa
    8000108e:	00c79513          	slli	a0,a5,0xc
  return pa;
    80001092:	bfcd                	j	80001084 <walkaddr+0x2e>
    return 0;
    80001094:	4501                	li	a0,0
    80001096:	b7fd                	j	80001084 <walkaddr+0x2e>

0000000080001098 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001098:	715d                	addi	sp,sp,-80
    8000109a:	e486                	sd	ra,72(sp)
    8000109c:	e0a2                	sd	s0,64(sp)
    8000109e:	fc26                	sd	s1,56(sp)
    800010a0:	f84a                	sd	s2,48(sp)
    800010a2:	f44e                	sd	s3,40(sp)
    800010a4:	f052                	sd	s4,32(sp)
    800010a6:	ec56                	sd	s5,24(sp)
    800010a8:	e85a                	sd	s6,16(sp)
    800010aa:	e45e                	sd	s7,8(sp)
    800010ac:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010ae:	c639                	beqz	a2,800010fc <mappages+0x64>
    800010b0:	8aaa                	mv	s5,a0
    800010b2:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010b4:	777d                	lui	a4,0xfffff
    800010b6:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010ba:	fff58993          	addi	s3,a1,-1
    800010be:	99b2                	add	s3,s3,a2
    800010c0:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010c4:	893e                	mv	s2,a5
    800010c6:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010ca:	6b85                	lui	s7,0x1
    800010cc:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010d0:	4605                	li	a2,1
    800010d2:	85ca                	mv	a1,s2
    800010d4:	8556                	mv	a0,s5
    800010d6:	00000097          	auipc	ra,0x0
    800010da:	eda080e7          	jalr	-294(ra) # 80000fb0 <walk>
    800010de:	cd1d                	beqz	a0,8000111c <mappages+0x84>
    if(*pte & PTE_V)
    800010e0:	611c                	ld	a5,0(a0)
    800010e2:	8b85                	andi	a5,a5,1
    800010e4:	e785                	bnez	a5,8000110c <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010e6:	80b1                	srli	s1,s1,0xc
    800010e8:	04aa                	slli	s1,s1,0xa
    800010ea:	0164e4b3          	or	s1,s1,s6
    800010ee:	0014e493          	ori	s1,s1,1
    800010f2:	e104                	sd	s1,0(a0)
    if(a == last)
    800010f4:	05390063          	beq	s2,s3,80001134 <mappages+0x9c>
    a += PGSIZE;
    800010f8:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800010fa:	bfc9                	j	800010cc <mappages+0x34>
    panic("mappages: size");
    800010fc:	00007517          	auipc	a0,0x7
    80001100:	fdc50513          	addi	a0,a0,-36 # 800080d8 <digits+0x98>
    80001104:	fffff097          	auipc	ra,0xfffff
    80001108:	438080e7          	jalr	1080(ra) # 8000053c <panic>
      panic("mappages: remap");
    8000110c:	00007517          	auipc	a0,0x7
    80001110:	fdc50513          	addi	a0,a0,-36 # 800080e8 <digits+0xa8>
    80001114:	fffff097          	auipc	ra,0xfffff
    80001118:	428080e7          	jalr	1064(ra) # 8000053c <panic>
      return -1;
    8000111c:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000111e:	60a6                	ld	ra,72(sp)
    80001120:	6406                	ld	s0,64(sp)
    80001122:	74e2                	ld	s1,56(sp)
    80001124:	7942                	ld	s2,48(sp)
    80001126:	79a2                	ld	s3,40(sp)
    80001128:	7a02                	ld	s4,32(sp)
    8000112a:	6ae2                	ld	s5,24(sp)
    8000112c:	6b42                	ld	s6,16(sp)
    8000112e:	6ba2                	ld	s7,8(sp)
    80001130:	6161                	addi	sp,sp,80
    80001132:	8082                	ret
  return 0;
    80001134:	4501                	li	a0,0
    80001136:	b7e5                	j	8000111e <mappages+0x86>

0000000080001138 <kvmmap>:
{
    80001138:	1141                	addi	sp,sp,-16
    8000113a:	e406                	sd	ra,8(sp)
    8000113c:	e022                	sd	s0,0(sp)
    8000113e:	0800                	addi	s0,sp,16
    80001140:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001142:	86b2                	mv	a3,a2
    80001144:	863e                	mv	a2,a5
    80001146:	00000097          	auipc	ra,0x0
    8000114a:	f52080e7          	jalr	-174(ra) # 80001098 <mappages>
    8000114e:	e509                	bnez	a0,80001158 <kvmmap+0x20>
}
    80001150:	60a2                	ld	ra,8(sp)
    80001152:	6402                	ld	s0,0(sp)
    80001154:	0141                	addi	sp,sp,16
    80001156:	8082                	ret
    panic("kvmmap");
    80001158:	00007517          	auipc	a0,0x7
    8000115c:	fa050513          	addi	a0,a0,-96 # 800080f8 <digits+0xb8>
    80001160:	fffff097          	auipc	ra,0xfffff
    80001164:	3dc080e7          	jalr	988(ra) # 8000053c <panic>

0000000080001168 <kvmmake>:
{
    80001168:	1101                	addi	sp,sp,-32
    8000116a:	ec06                	sd	ra,24(sp)
    8000116c:	e822                	sd	s0,16(sp)
    8000116e:	e426                	sd	s1,8(sp)
    80001170:	e04a                	sd	s2,0(sp)
    80001172:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001174:	00000097          	auipc	ra,0x0
    80001178:	96e080e7          	jalr	-1682(ra) # 80000ae2 <kalloc>
    8000117c:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    8000117e:	6605                	lui	a2,0x1
    80001180:	4581                	li	a1,0
    80001182:	00000097          	auipc	ra,0x0
    80001186:	b4c080e7          	jalr	-1204(ra) # 80000cce <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    8000118a:	4719                	li	a4,6
    8000118c:	6685                	lui	a3,0x1
    8000118e:	10000637          	lui	a2,0x10000
    80001192:	100005b7          	lui	a1,0x10000
    80001196:	8526                	mv	a0,s1
    80001198:	00000097          	auipc	ra,0x0
    8000119c:	fa0080e7          	jalr	-96(ra) # 80001138 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011a0:	4719                	li	a4,6
    800011a2:	6685                	lui	a3,0x1
    800011a4:	10001637          	lui	a2,0x10001
    800011a8:	100015b7          	lui	a1,0x10001
    800011ac:	8526                	mv	a0,s1
    800011ae:	00000097          	auipc	ra,0x0
    800011b2:	f8a080e7          	jalr	-118(ra) # 80001138 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011b6:	4719                	li	a4,6
    800011b8:	004006b7          	lui	a3,0x400
    800011bc:	0c000637          	lui	a2,0xc000
    800011c0:	0c0005b7          	lui	a1,0xc000
    800011c4:	8526                	mv	a0,s1
    800011c6:	00000097          	auipc	ra,0x0
    800011ca:	f72080e7          	jalr	-142(ra) # 80001138 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011ce:	00007917          	auipc	s2,0x7
    800011d2:	e3290913          	addi	s2,s2,-462 # 80008000 <etext>
    800011d6:	4729                	li	a4,10
    800011d8:	80007697          	auipc	a3,0x80007
    800011dc:	e2868693          	addi	a3,a3,-472 # 8000 <_entry-0x7fff8000>
    800011e0:	4605                	li	a2,1
    800011e2:	067e                	slli	a2,a2,0x1f
    800011e4:	85b2                	mv	a1,a2
    800011e6:	8526                	mv	a0,s1
    800011e8:	00000097          	auipc	ra,0x0
    800011ec:	f50080e7          	jalr	-176(ra) # 80001138 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011f0:	4719                	li	a4,6
    800011f2:	46c5                	li	a3,17
    800011f4:	06ee                	slli	a3,a3,0x1b
    800011f6:	412686b3          	sub	a3,a3,s2
    800011fa:	864a                	mv	a2,s2
    800011fc:	85ca                	mv	a1,s2
    800011fe:	8526                	mv	a0,s1
    80001200:	00000097          	auipc	ra,0x0
    80001204:	f38080e7          	jalr	-200(ra) # 80001138 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001208:	4729                	li	a4,10
    8000120a:	6685                	lui	a3,0x1
    8000120c:	00006617          	auipc	a2,0x6
    80001210:	df460613          	addi	a2,a2,-524 # 80007000 <_trampoline>
    80001214:	040005b7          	lui	a1,0x4000
    80001218:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    8000121a:	05b2                	slli	a1,a1,0xc
    8000121c:	8526                	mv	a0,s1
    8000121e:	00000097          	auipc	ra,0x0
    80001222:	f1a080e7          	jalr	-230(ra) # 80001138 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001226:	8526                	mv	a0,s1
    80001228:	00001097          	auipc	ra,0x1
    8000122c:	8d2080e7          	jalr	-1838(ra) # 80001afa <proc_mapstacks>
}
    80001230:	8526                	mv	a0,s1
    80001232:	60e2                	ld	ra,24(sp)
    80001234:	6442                	ld	s0,16(sp)
    80001236:	64a2                	ld	s1,8(sp)
    80001238:	6902                	ld	s2,0(sp)
    8000123a:	6105                	addi	sp,sp,32
    8000123c:	8082                	ret

000000008000123e <kvminit>:
{
    8000123e:	1141                	addi	sp,sp,-16
    80001240:	e406                	sd	ra,8(sp)
    80001242:	e022                	sd	s0,0(sp)
    80001244:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001246:	00000097          	auipc	ra,0x0
    8000124a:	f22080e7          	jalr	-222(ra) # 80001168 <kvmmake>
    8000124e:	00007797          	auipc	a5,0x7
    80001252:	7aa7b123          	sd	a0,1954(a5) # 800089f0 <kernel_pagetable>
}
    80001256:	60a2                	ld	ra,8(sp)
    80001258:	6402                	ld	s0,0(sp)
    8000125a:	0141                	addi	sp,sp,16
    8000125c:	8082                	ret

000000008000125e <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000125e:	715d                	addi	sp,sp,-80
    80001260:	e486                	sd	ra,72(sp)
    80001262:	e0a2                	sd	s0,64(sp)
    80001264:	fc26                	sd	s1,56(sp)
    80001266:	f84a                	sd	s2,48(sp)
    80001268:	f44e                	sd	s3,40(sp)
    8000126a:	f052                	sd	s4,32(sp)
    8000126c:	ec56                	sd	s5,24(sp)
    8000126e:	e85a                	sd	s6,16(sp)
    80001270:	e45e                	sd	s7,8(sp)
    80001272:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001274:	03459793          	slli	a5,a1,0x34
    80001278:	e795                	bnez	a5,800012a4 <uvmunmap+0x46>
    8000127a:	8a2a                	mv	s4,a0
    8000127c:	892e                	mv	s2,a1
    8000127e:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001280:	0632                	slli	a2,a2,0xc
    80001282:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001286:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001288:	6b05                	lui	s6,0x1
    8000128a:	0735e263          	bltu	a1,s3,800012ee <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000128e:	60a6                	ld	ra,72(sp)
    80001290:	6406                	ld	s0,64(sp)
    80001292:	74e2                	ld	s1,56(sp)
    80001294:	7942                	ld	s2,48(sp)
    80001296:	79a2                	ld	s3,40(sp)
    80001298:	7a02                	ld	s4,32(sp)
    8000129a:	6ae2                	ld	s5,24(sp)
    8000129c:	6b42                	ld	s6,16(sp)
    8000129e:	6ba2                	ld	s7,8(sp)
    800012a0:	6161                	addi	sp,sp,80
    800012a2:	8082                	ret
    panic("uvmunmap: not aligned");
    800012a4:	00007517          	auipc	a0,0x7
    800012a8:	e5c50513          	addi	a0,a0,-420 # 80008100 <digits+0xc0>
    800012ac:	fffff097          	auipc	ra,0xfffff
    800012b0:	290080e7          	jalr	656(ra) # 8000053c <panic>
      panic("uvmunmap: walk");
    800012b4:	00007517          	auipc	a0,0x7
    800012b8:	e6450513          	addi	a0,a0,-412 # 80008118 <digits+0xd8>
    800012bc:	fffff097          	auipc	ra,0xfffff
    800012c0:	280080e7          	jalr	640(ra) # 8000053c <panic>
      panic("uvmunmap: not mapped");
    800012c4:	00007517          	auipc	a0,0x7
    800012c8:	e6450513          	addi	a0,a0,-412 # 80008128 <digits+0xe8>
    800012cc:	fffff097          	auipc	ra,0xfffff
    800012d0:	270080e7          	jalr	624(ra) # 8000053c <panic>
      panic("uvmunmap: not a leaf");
    800012d4:	00007517          	auipc	a0,0x7
    800012d8:	e6c50513          	addi	a0,a0,-404 # 80008140 <digits+0x100>
    800012dc:	fffff097          	auipc	ra,0xfffff
    800012e0:	260080e7          	jalr	608(ra) # 8000053c <panic>
    *pte = 0;
    800012e4:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012e8:	995a                	add	s2,s2,s6
    800012ea:	fb3972e3          	bgeu	s2,s3,8000128e <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012ee:	4601                	li	a2,0
    800012f0:	85ca                	mv	a1,s2
    800012f2:	8552                	mv	a0,s4
    800012f4:	00000097          	auipc	ra,0x0
    800012f8:	cbc080e7          	jalr	-836(ra) # 80000fb0 <walk>
    800012fc:	84aa                	mv	s1,a0
    800012fe:	d95d                	beqz	a0,800012b4 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001300:	6108                	ld	a0,0(a0)
    80001302:	00157793          	andi	a5,a0,1
    80001306:	dfdd                	beqz	a5,800012c4 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001308:	3ff57793          	andi	a5,a0,1023
    8000130c:	fd7784e3          	beq	a5,s7,800012d4 <uvmunmap+0x76>
    if(do_free){
    80001310:	fc0a8ae3          	beqz	s5,800012e4 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    80001314:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001316:	0532                	slli	a0,a0,0xc
    80001318:	fffff097          	auipc	ra,0xfffff
    8000131c:	6cc080e7          	jalr	1740(ra) # 800009e4 <kfree>
    80001320:	b7d1                	j	800012e4 <uvmunmap+0x86>

0000000080001322 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001322:	1101                	addi	sp,sp,-32
    80001324:	ec06                	sd	ra,24(sp)
    80001326:	e822                	sd	s0,16(sp)
    80001328:	e426                	sd	s1,8(sp)
    8000132a:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000132c:	fffff097          	auipc	ra,0xfffff
    80001330:	7b6080e7          	jalr	1974(ra) # 80000ae2 <kalloc>
    80001334:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001336:	c519                	beqz	a0,80001344 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001338:	6605                	lui	a2,0x1
    8000133a:	4581                	li	a1,0
    8000133c:	00000097          	auipc	ra,0x0
    80001340:	992080e7          	jalr	-1646(ra) # 80000cce <memset>
  return pagetable;
}
    80001344:	8526                	mv	a0,s1
    80001346:	60e2                	ld	ra,24(sp)
    80001348:	6442                	ld	s0,16(sp)
    8000134a:	64a2                	ld	s1,8(sp)
    8000134c:	6105                	addi	sp,sp,32
    8000134e:	8082                	ret

0000000080001350 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001350:	7179                	addi	sp,sp,-48
    80001352:	f406                	sd	ra,40(sp)
    80001354:	f022                	sd	s0,32(sp)
    80001356:	ec26                	sd	s1,24(sp)
    80001358:	e84a                	sd	s2,16(sp)
    8000135a:	e44e                	sd	s3,8(sp)
    8000135c:	e052                	sd	s4,0(sp)
    8000135e:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001360:	6785                	lui	a5,0x1
    80001362:	04f67863          	bgeu	a2,a5,800013b2 <uvmfirst+0x62>
    80001366:	8a2a                	mv	s4,a0
    80001368:	89ae                	mv	s3,a1
    8000136a:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    8000136c:	fffff097          	auipc	ra,0xfffff
    80001370:	776080e7          	jalr	1910(ra) # 80000ae2 <kalloc>
    80001374:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001376:	6605                	lui	a2,0x1
    80001378:	4581                	li	a1,0
    8000137a:	00000097          	auipc	ra,0x0
    8000137e:	954080e7          	jalr	-1708(ra) # 80000cce <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001382:	4779                	li	a4,30
    80001384:	86ca                	mv	a3,s2
    80001386:	6605                	lui	a2,0x1
    80001388:	4581                	li	a1,0
    8000138a:	8552                	mv	a0,s4
    8000138c:	00000097          	auipc	ra,0x0
    80001390:	d0c080e7          	jalr	-756(ra) # 80001098 <mappages>
  memmove(mem, src, sz);
    80001394:	8626                	mv	a2,s1
    80001396:	85ce                	mv	a1,s3
    80001398:	854a                	mv	a0,s2
    8000139a:	00000097          	auipc	ra,0x0
    8000139e:	990080e7          	jalr	-1648(ra) # 80000d2a <memmove>
}
    800013a2:	70a2                	ld	ra,40(sp)
    800013a4:	7402                	ld	s0,32(sp)
    800013a6:	64e2                	ld	s1,24(sp)
    800013a8:	6942                	ld	s2,16(sp)
    800013aa:	69a2                	ld	s3,8(sp)
    800013ac:	6a02                	ld	s4,0(sp)
    800013ae:	6145                	addi	sp,sp,48
    800013b0:	8082                	ret
    panic("uvmfirst: more than a page");
    800013b2:	00007517          	auipc	a0,0x7
    800013b6:	da650513          	addi	a0,a0,-602 # 80008158 <digits+0x118>
    800013ba:	fffff097          	auipc	ra,0xfffff
    800013be:	182080e7          	jalr	386(ra) # 8000053c <panic>

00000000800013c2 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013c2:	1101                	addi	sp,sp,-32
    800013c4:	ec06                	sd	ra,24(sp)
    800013c6:	e822                	sd	s0,16(sp)
    800013c8:	e426                	sd	s1,8(sp)
    800013ca:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013cc:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013ce:	00b67d63          	bgeu	a2,a1,800013e8 <uvmdealloc+0x26>
    800013d2:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013d4:	6785                	lui	a5,0x1
    800013d6:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800013d8:	00f60733          	add	a4,a2,a5
    800013dc:	76fd                	lui	a3,0xfffff
    800013de:	8f75                	and	a4,a4,a3
    800013e0:	97ae                	add	a5,a5,a1
    800013e2:	8ff5                	and	a5,a5,a3
    800013e4:	00f76863          	bltu	a4,a5,800013f4 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013e8:	8526                	mv	a0,s1
    800013ea:	60e2                	ld	ra,24(sp)
    800013ec:	6442                	ld	s0,16(sp)
    800013ee:	64a2                	ld	s1,8(sp)
    800013f0:	6105                	addi	sp,sp,32
    800013f2:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013f4:	8f99                	sub	a5,a5,a4
    800013f6:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013f8:	4685                	li	a3,1
    800013fa:	0007861b          	sext.w	a2,a5
    800013fe:	85ba                	mv	a1,a4
    80001400:	00000097          	auipc	ra,0x0
    80001404:	e5e080e7          	jalr	-418(ra) # 8000125e <uvmunmap>
    80001408:	b7c5                	j	800013e8 <uvmdealloc+0x26>

000000008000140a <uvmalloc>:
  if(newsz < oldsz)
    8000140a:	0ab66563          	bltu	a2,a1,800014b4 <uvmalloc+0xaa>
{
    8000140e:	7139                	addi	sp,sp,-64
    80001410:	fc06                	sd	ra,56(sp)
    80001412:	f822                	sd	s0,48(sp)
    80001414:	f426                	sd	s1,40(sp)
    80001416:	f04a                	sd	s2,32(sp)
    80001418:	ec4e                	sd	s3,24(sp)
    8000141a:	e852                	sd	s4,16(sp)
    8000141c:	e456                	sd	s5,8(sp)
    8000141e:	e05a                	sd	s6,0(sp)
    80001420:	0080                	addi	s0,sp,64
    80001422:	8aaa                	mv	s5,a0
    80001424:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001426:	6785                	lui	a5,0x1
    80001428:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000142a:	95be                	add	a1,a1,a5
    8000142c:	77fd                	lui	a5,0xfffff
    8000142e:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001432:	08c9f363          	bgeu	s3,a2,800014b8 <uvmalloc+0xae>
    80001436:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001438:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    8000143c:	fffff097          	auipc	ra,0xfffff
    80001440:	6a6080e7          	jalr	1702(ra) # 80000ae2 <kalloc>
    80001444:	84aa                	mv	s1,a0
    if(mem == 0){
    80001446:	c51d                	beqz	a0,80001474 <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    80001448:	6605                	lui	a2,0x1
    8000144a:	4581                	li	a1,0
    8000144c:	00000097          	auipc	ra,0x0
    80001450:	882080e7          	jalr	-1918(ra) # 80000cce <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001454:	875a                	mv	a4,s6
    80001456:	86a6                	mv	a3,s1
    80001458:	6605                	lui	a2,0x1
    8000145a:	85ca                	mv	a1,s2
    8000145c:	8556                	mv	a0,s5
    8000145e:	00000097          	auipc	ra,0x0
    80001462:	c3a080e7          	jalr	-966(ra) # 80001098 <mappages>
    80001466:	e90d                	bnez	a0,80001498 <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001468:	6785                	lui	a5,0x1
    8000146a:	993e                	add	s2,s2,a5
    8000146c:	fd4968e3          	bltu	s2,s4,8000143c <uvmalloc+0x32>
  return newsz;
    80001470:	8552                	mv	a0,s4
    80001472:	a809                	j	80001484 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    80001474:	864e                	mv	a2,s3
    80001476:	85ca                	mv	a1,s2
    80001478:	8556                	mv	a0,s5
    8000147a:	00000097          	auipc	ra,0x0
    8000147e:	f48080e7          	jalr	-184(ra) # 800013c2 <uvmdealloc>
      return 0;
    80001482:	4501                	li	a0,0
}
    80001484:	70e2                	ld	ra,56(sp)
    80001486:	7442                	ld	s0,48(sp)
    80001488:	74a2                	ld	s1,40(sp)
    8000148a:	7902                	ld	s2,32(sp)
    8000148c:	69e2                	ld	s3,24(sp)
    8000148e:	6a42                	ld	s4,16(sp)
    80001490:	6aa2                	ld	s5,8(sp)
    80001492:	6b02                	ld	s6,0(sp)
    80001494:	6121                	addi	sp,sp,64
    80001496:	8082                	ret
      kfree(mem);
    80001498:	8526                	mv	a0,s1
    8000149a:	fffff097          	auipc	ra,0xfffff
    8000149e:	54a080e7          	jalr	1354(ra) # 800009e4 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014a2:	864e                	mv	a2,s3
    800014a4:	85ca                	mv	a1,s2
    800014a6:	8556                	mv	a0,s5
    800014a8:	00000097          	auipc	ra,0x0
    800014ac:	f1a080e7          	jalr	-230(ra) # 800013c2 <uvmdealloc>
      return 0;
    800014b0:	4501                	li	a0,0
    800014b2:	bfc9                	j	80001484 <uvmalloc+0x7a>
    return oldsz;
    800014b4:	852e                	mv	a0,a1
}
    800014b6:	8082                	ret
  return newsz;
    800014b8:	8532                	mv	a0,a2
    800014ba:	b7e9                	j	80001484 <uvmalloc+0x7a>

00000000800014bc <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014bc:	7179                	addi	sp,sp,-48
    800014be:	f406                	sd	ra,40(sp)
    800014c0:	f022                	sd	s0,32(sp)
    800014c2:	ec26                	sd	s1,24(sp)
    800014c4:	e84a                	sd	s2,16(sp)
    800014c6:	e44e                	sd	s3,8(sp)
    800014c8:	e052                	sd	s4,0(sp)
    800014ca:	1800                	addi	s0,sp,48
    800014cc:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014ce:	84aa                	mv	s1,a0
    800014d0:	6905                	lui	s2,0x1
    800014d2:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014d4:	4985                	li	s3,1
    800014d6:	a829                	j	800014f0 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014d8:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    800014da:	00c79513          	slli	a0,a5,0xc
    800014de:	00000097          	auipc	ra,0x0
    800014e2:	fde080e7          	jalr	-34(ra) # 800014bc <freewalk>
      pagetable[i] = 0;
    800014e6:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014ea:	04a1                	addi	s1,s1,8
    800014ec:	03248163          	beq	s1,s2,8000150e <freewalk+0x52>
    pte_t pte = pagetable[i];
    800014f0:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f2:	00f7f713          	andi	a4,a5,15
    800014f6:	ff3701e3          	beq	a4,s3,800014d8 <freewalk+0x1c>
    } else if(pte & PTE_V){
    800014fa:	8b85                	andi	a5,a5,1
    800014fc:	d7fd                	beqz	a5,800014ea <freewalk+0x2e>
      panic("freewalk: leaf");
    800014fe:	00007517          	auipc	a0,0x7
    80001502:	c7a50513          	addi	a0,a0,-902 # 80008178 <digits+0x138>
    80001506:	fffff097          	auipc	ra,0xfffff
    8000150a:	036080e7          	jalr	54(ra) # 8000053c <panic>
    }
  }
  kfree((void*)pagetable);
    8000150e:	8552                	mv	a0,s4
    80001510:	fffff097          	auipc	ra,0xfffff
    80001514:	4d4080e7          	jalr	1236(ra) # 800009e4 <kfree>
}
    80001518:	70a2                	ld	ra,40(sp)
    8000151a:	7402                	ld	s0,32(sp)
    8000151c:	64e2                	ld	s1,24(sp)
    8000151e:	6942                	ld	s2,16(sp)
    80001520:	69a2                	ld	s3,8(sp)
    80001522:	6a02                	ld	s4,0(sp)
    80001524:	6145                	addi	sp,sp,48
    80001526:	8082                	ret

0000000080001528 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001528:	1101                	addi	sp,sp,-32
    8000152a:	ec06                	sd	ra,24(sp)
    8000152c:	e822                	sd	s0,16(sp)
    8000152e:	e426                	sd	s1,8(sp)
    80001530:	1000                	addi	s0,sp,32
    80001532:	84aa                	mv	s1,a0
  if(sz > 0)
    80001534:	e999                	bnez	a1,8000154a <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001536:	8526                	mv	a0,s1
    80001538:	00000097          	auipc	ra,0x0
    8000153c:	f84080e7          	jalr	-124(ra) # 800014bc <freewalk>
}
    80001540:	60e2                	ld	ra,24(sp)
    80001542:	6442                	ld	s0,16(sp)
    80001544:	64a2                	ld	s1,8(sp)
    80001546:	6105                	addi	sp,sp,32
    80001548:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000154a:	6785                	lui	a5,0x1
    8000154c:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000154e:	95be                	add	a1,a1,a5
    80001550:	4685                	li	a3,1
    80001552:	00c5d613          	srli	a2,a1,0xc
    80001556:	4581                	li	a1,0
    80001558:	00000097          	auipc	ra,0x0
    8000155c:	d06080e7          	jalr	-762(ra) # 8000125e <uvmunmap>
    80001560:	bfd9                	j	80001536 <uvmfree+0xe>

0000000080001562 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001562:	c679                	beqz	a2,80001630 <uvmcopy+0xce>
{
    80001564:	715d                	addi	sp,sp,-80
    80001566:	e486                	sd	ra,72(sp)
    80001568:	e0a2                	sd	s0,64(sp)
    8000156a:	fc26                	sd	s1,56(sp)
    8000156c:	f84a                	sd	s2,48(sp)
    8000156e:	f44e                	sd	s3,40(sp)
    80001570:	f052                	sd	s4,32(sp)
    80001572:	ec56                	sd	s5,24(sp)
    80001574:	e85a                	sd	s6,16(sp)
    80001576:	e45e                	sd	s7,8(sp)
    80001578:	0880                	addi	s0,sp,80
    8000157a:	8b2a                	mv	s6,a0
    8000157c:	8aae                	mv	s5,a1
    8000157e:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001580:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001582:	4601                	li	a2,0
    80001584:	85ce                	mv	a1,s3
    80001586:	855a                	mv	a0,s6
    80001588:	00000097          	auipc	ra,0x0
    8000158c:	a28080e7          	jalr	-1496(ra) # 80000fb0 <walk>
    80001590:	c531                	beqz	a0,800015dc <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001592:	6118                	ld	a4,0(a0)
    80001594:	00177793          	andi	a5,a4,1
    80001598:	cbb1                	beqz	a5,800015ec <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    8000159a:	00a75593          	srli	a1,a4,0xa
    8000159e:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015a2:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015a6:	fffff097          	auipc	ra,0xfffff
    800015aa:	53c080e7          	jalr	1340(ra) # 80000ae2 <kalloc>
    800015ae:	892a                	mv	s2,a0
    800015b0:	c939                	beqz	a0,80001606 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015b2:	6605                	lui	a2,0x1
    800015b4:	85de                	mv	a1,s7
    800015b6:	fffff097          	auipc	ra,0xfffff
    800015ba:	774080e7          	jalr	1908(ra) # 80000d2a <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015be:	8726                	mv	a4,s1
    800015c0:	86ca                	mv	a3,s2
    800015c2:	6605                	lui	a2,0x1
    800015c4:	85ce                	mv	a1,s3
    800015c6:	8556                	mv	a0,s5
    800015c8:	00000097          	auipc	ra,0x0
    800015cc:	ad0080e7          	jalr	-1328(ra) # 80001098 <mappages>
    800015d0:	e515                	bnez	a0,800015fc <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015d2:	6785                	lui	a5,0x1
    800015d4:	99be                	add	s3,s3,a5
    800015d6:	fb49e6e3          	bltu	s3,s4,80001582 <uvmcopy+0x20>
    800015da:	a081                	j	8000161a <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015dc:	00007517          	auipc	a0,0x7
    800015e0:	bac50513          	addi	a0,a0,-1108 # 80008188 <digits+0x148>
    800015e4:	fffff097          	auipc	ra,0xfffff
    800015e8:	f58080e7          	jalr	-168(ra) # 8000053c <panic>
      panic("uvmcopy: page not present");
    800015ec:	00007517          	auipc	a0,0x7
    800015f0:	bbc50513          	addi	a0,a0,-1092 # 800081a8 <digits+0x168>
    800015f4:	fffff097          	auipc	ra,0xfffff
    800015f8:	f48080e7          	jalr	-184(ra) # 8000053c <panic>
      kfree(mem);
    800015fc:	854a                	mv	a0,s2
    800015fe:	fffff097          	auipc	ra,0xfffff
    80001602:	3e6080e7          	jalr	998(ra) # 800009e4 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001606:	4685                	li	a3,1
    80001608:	00c9d613          	srli	a2,s3,0xc
    8000160c:	4581                	li	a1,0
    8000160e:	8556                	mv	a0,s5
    80001610:	00000097          	auipc	ra,0x0
    80001614:	c4e080e7          	jalr	-946(ra) # 8000125e <uvmunmap>
  return -1;
    80001618:	557d                	li	a0,-1
}
    8000161a:	60a6                	ld	ra,72(sp)
    8000161c:	6406                	ld	s0,64(sp)
    8000161e:	74e2                	ld	s1,56(sp)
    80001620:	7942                	ld	s2,48(sp)
    80001622:	79a2                	ld	s3,40(sp)
    80001624:	7a02                	ld	s4,32(sp)
    80001626:	6ae2                	ld	s5,24(sp)
    80001628:	6b42                	ld	s6,16(sp)
    8000162a:	6ba2                	ld	s7,8(sp)
    8000162c:	6161                	addi	sp,sp,80
    8000162e:	8082                	ret
  return 0;
    80001630:	4501                	li	a0,0
}
    80001632:	8082                	ret

0000000080001634 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001634:	1141                	addi	sp,sp,-16
    80001636:	e406                	sd	ra,8(sp)
    80001638:	e022                	sd	s0,0(sp)
    8000163a:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000163c:	4601                	li	a2,0
    8000163e:	00000097          	auipc	ra,0x0
    80001642:	972080e7          	jalr	-1678(ra) # 80000fb0 <walk>
  if(pte == 0)
    80001646:	c901                	beqz	a0,80001656 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001648:	611c                	ld	a5,0(a0)
    8000164a:	9bbd                	andi	a5,a5,-17
    8000164c:	e11c                	sd	a5,0(a0)
}
    8000164e:	60a2                	ld	ra,8(sp)
    80001650:	6402                	ld	s0,0(sp)
    80001652:	0141                	addi	sp,sp,16
    80001654:	8082                	ret
    panic("uvmclear");
    80001656:	00007517          	auipc	a0,0x7
    8000165a:	b7250513          	addi	a0,a0,-1166 # 800081c8 <digits+0x188>
    8000165e:	fffff097          	auipc	ra,0xfffff
    80001662:	ede080e7          	jalr	-290(ra) # 8000053c <panic>

0000000080001666 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001666:	c6bd                	beqz	a3,800016d4 <copyout+0x6e>
{
    80001668:	715d                	addi	sp,sp,-80
    8000166a:	e486                	sd	ra,72(sp)
    8000166c:	e0a2                	sd	s0,64(sp)
    8000166e:	fc26                	sd	s1,56(sp)
    80001670:	f84a                	sd	s2,48(sp)
    80001672:	f44e                	sd	s3,40(sp)
    80001674:	f052                	sd	s4,32(sp)
    80001676:	ec56                	sd	s5,24(sp)
    80001678:	e85a                	sd	s6,16(sp)
    8000167a:	e45e                	sd	s7,8(sp)
    8000167c:	e062                	sd	s8,0(sp)
    8000167e:	0880                	addi	s0,sp,80
    80001680:	8b2a                	mv	s6,a0
    80001682:	8c2e                	mv	s8,a1
    80001684:	8a32                	mv	s4,a2
    80001686:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001688:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    8000168a:	6a85                	lui	s5,0x1
    8000168c:	a015                	j	800016b0 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000168e:	9562                	add	a0,a0,s8
    80001690:	0004861b          	sext.w	a2,s1
    80001694:	85d2                	mv	a1,s4
    80001696:	41250533          	sub	a0,a0,s2
    8000169a:	fffff097          	auipc	ra,0xfffff
    8000169e:	690080e7          	jalr	1680(ra) # 80000d2a <memmove>

    len -= n;
    800016a2:	409989b3          	sub	s3,s3,s1
    src += n;
    800016a6:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016a8:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016ac:	02098263          	beqz	s3,800016d0 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016b0:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016b4:	85ca                	mv	a1,s2
    800016b6:	855a                	mv	a0,s6
    800016b8:	00000097          	auipc	ra,0x0
    800016bc:	99e080e7          	jalr	-1634(ra) # 80001056 <walkaddr>
    if(pa0 == 0)
    800016c0:	cd01                	beqz	a0,800016d8 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016c2:	418904b3          	sub	s1,s2,s8
    800016c6:	94d6                	add	s1,s1,s5
    800016c8:	fc99f3e3          	bgeu	s3,s1,8000168e <copyout+0x28>
    800016cc:	84ce                	mv	s1,s3
    800016ce:	b7c1                	j	8000168e <copyout+0x28>
  }
  return 0;
    800016d0:	4501                	li	a0,0
    800016d2:	a021                	j	800016da <copyout+0x74>
    800016d4:	4501                	li	a0,0
}
    800016d6:	8082                	ret
      return -1;
    800016d8:	557d                	li	a0,-1
}
    800016da:	60a6                	ld	ra,72(sp)
    800016dc:	6406                	ld	s0,64(sp)
    800016de:	74e2                	ld	s1,56(sp)
    800016e0:	7942                	ld	s2,48(sp)
    800016e2:	79a2                	ld	s3,40(sp)
    800016e4:	7a02                	ld	s4,32(sp)
    800016e6:	6ae2                	ld	s5,24(sp)
    800016e8:	6b42                	ld	s6,16(sp)
    800016ea:	6ba2                	ld	s7,8(sp)
    800016ec:	6c02                	ld	s8,0(sp)
    800016ee:	6161                	addi	sp,sp,80
    800016f0:	8082                	ret

00000000800016f2 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016f2:	caa5                	beqz	a3,80001762 <copyin+0x70>
{
    800016f4:	715d                	addi	sp,sp,-80
    800016f6:	e486                	sd	ra,72(sp)
    800016f8:	e0a2                	sd	s0,64(sp)
    800016fa:	fc26                	sd	s1,56(sp)
    800016fc:	f84a                	sd	s2,48(sp)
    800016fe:	f44e                	sd	s3,40(sp)
    80001700:	f052                	sd	s4,32(sp)
    80001702:	ec56                	sd	s5,24(sp)
    80001704:	e85a                	sd	s6,16(sp)
    80001706:	e45e                	sd	s7,8(sp)
    80001708:	e062                	sd	s8,0(sp)
    8000170a:	0880                	addi	s0,sp,80
    8000170c:	8b2a                	mv	s6,a0
    8000170e:	8a2e                	mv	s4,a1
    80001710:	8c32                	mv	s8,a2
    80001712:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001714:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001716:	6a85                	lui	s5,0x1
    80001718:	a01d                	j	8000173e <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000171a:	018505b3          	add	a1,a0,s8
    8000171e:	0004861b          	sext.w	a2,s1
    80001722:	412585b3          	sub	a1,a1,s2
    80001726:	8552                	mv	a0,s4
    80001728:	fffff097          	auipc	ra,0xfffff
    8000172c:	602080e7          	jalr	1538(ra) # 80000d2a <memmove>

    len -= n;
    80001730:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001734:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001736:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000173a:	02098263          	beqz	s3,8000175e <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    8000173e:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001742:	85ca                	mv	a1,s2
    80001744:	855a                	mv	a0,s6
    80001746:	00000097          	auipc	ra,0x0
    8000174a:	910080e7          	jalr	-1776(ra) # 80001056 <walkaddr>
    if(pa0 == 0)
    8000174e:	cd01                	beqz	a0,80001766 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001750:	418904b3          	sub	s1,s2,s8
    80001754:	94d6                	add	s1,s1,s5
    80001756:	fc99f2e3          	bgeu	s3,s1,8000171a <copyin+0x28>
    8000175a:	84ce                	mv	s1,s3
    8000175c:	bf7d                	j	8000171a <copyin+0x28>
  }
  return 0;
    8000175e:	4501                	li	a0,0
    80001760:	a021                	j	80001768 <copyin+0x76>
    80001762:	4501                	li	a0,0
}
    80001764:	8082                	ret
      return -1;
    80001766:	557d                	li	a0,-1
}
    80001768:	60a6                	ld	ra,72(sp)
    8000176a:	6406                	ld	s0,64(sp)
    8000176c:	74e2                	ld	s1,56(sp)
    8000176e:	7942                	ld	s2,48(sp)
    80001770:	79a2                	ld	s3,40(sp)
    80001772:	7a02                	ld	s4,32(sp)
    80001774:	6ae2                	ld	s5,24(sp)
    80001776:	6b42                	ld	s6,16(sp)
    80001778:	6ba2                	ld	s7,8(sp)
    8000177a:	6c02                	ld	s8,0(sp)
    8000177c:	6161                	addi	sp,sp,80
    8000177e:	8082                	ret

0000000080001780 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001780:	c2dd                	beqz	a3,80001826 <copyinstr+0xa6>
{
    80001782:	715d                	addi	sp,sp,-80
    80001784:	e486                	sd	ra,72(sp)
    80001786:	e0a2                	sd	s0,64(sp)
    80001788:	fc26                	sd	s1,56(sp)
    8000178a:	f84a                	sd	s2,48(sp)
    8000178c:	f44e                	sd	s3,40(sp)
    8000178e:	f052                	sd	s4,32(sp)
    80001790:	ec56                	sd	s5,24(sp)
    80001792:	e85a                	sd	s6,16(sp)
    80001794:	e45e                	sd	s7,8(sp)
    80001796:	0880                	addi	s0,sp,80
    80001798:	8a2a                	mv	s4,a0
    8000179a:	8b2e                	mv	s6,a1
    8000179c:	8bb2                	mv	s7,a2
    8000179e:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017a0:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017a2:	6985                	lui	s3,0x1
    800017a4:	a02d                	j	800017ce <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017a6:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017aa:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017ac:	37fd                	addiw	a5,a5,-1
    800017ae:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017b2:	60a6                	ld	ra,72(sp)
    800017b4:	6406                	ld	s0,64(sp)
    800017b6:	74e2                	ld	s1,56(sp)
    800017b8:	7942                	ld	s2,48(sp)
    800017ba:	79a2                	ld	s3,40(sp)
    800017bc:	7a02                	ld	s4,32(sp)
    800017be:	6ae2                	ld	s5,24(sp)
    800017c0:	6b42                	ld	s6,16(sp)
    800017c2:	6ba2                	ld	s7,8(sp)
    800017c4:	6161                	addi	sp,sp,80
    800017c6:	8082                	ret
    srcva = va0 + PGSIZE;
    800017c8:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017cc:	c8a9                	beqz	s1,8000181e <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    800017ce:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017d2:	85ca                	mv	a1,s2
    800017d4:	8552                	mv	a0,s4
    800017d6:	00000097          	auipc	ra,0x0
    800017da:	880080e7          	jalr	-1920(ra) # 80001056 <walkaddr>
    if(pa0 == 0)
    800017de:	c131                	beqz	a0,80001822 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    800017e0:	417906b3          	sub	a3,s2,s7
    800017e4:	96ce                	add	a3,a3,s3
    800017e6:	00d4f363          	bgeu	s1,a3,800017ec <copyinstr+0x6c>
    800017ea:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017ec:	955e                	add	a0,a0,s7
    800017ee:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017f2:	daf9                	beqz	a3,800017c8 <copyinstr+0x48>
    800017f4:	87da                	mv	a5,s6
    800017f6:	885a                	mv	a6,s6
      if(*p == '\0'){
    800017f8:	41650633          	sub	a2,a0,s6
    while(n > 0){
    800017fc:	96da                	add	a3,a3,s6
    800017fe:	85be                	mv	a1,a5
      if(*p == '\0'){
    80001800:	00f60733          	add	a4,a2,a5
    80001804:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffdd180>
    80001808:	df59                	beqz	a4,800017a6 <copyinstr+0x26>
        *dst = *p;
    8000180a:	00e78023          	sb	a4,0(a5)
      dst++;
    8000180e:	0785                	addi	a5,a5,1
    while(n > 0){
    80001810:	fed797e3          	bne	a5,a3,800017fe <copyinstr+0x7e>
    80001814:	14fd                	addi	s1,s1,-1
    80001816:	94c2                	add	s1,s1,a6
      --max;
    80001818:	8c8d                	sub	s1,s1,a1
      dst++;
    8000181a:	8b3e                	mv	s6,a5
    8000181c:	b775                	j	800017c8 <copyinstr+0x48>
    8000181e:	4781                	li	a5,0
    80001820:	b771                	j	800017ac <copyinstr+0x2c>
      return -1;
    80001822:	557d                	li	a0,-1
    80001824:	b779                	j	800017b2 <copyinstr+0x32>
  int got_null = 0;
    80001826:	4781                	li	a5,0
  if(got_null){
    80001828:	37fd                	addiw	a5,a5,-1
    8000182a:	0007851b          	sext.w	a0,a5
}
    8000182e:	8082                	ret

0000000080001830 <rr_scheduler>:
        (*sched_pointer)();
    }
}

void rr_scheduler(void)
{
    80001830:	7139                	addi	sp,sp,-64
    80001832:	fc06                	sd	ra,56(sp)
    80001834:	f822                	sd	s0,48(sp)
    80001836:	f426                	sd	s1,40(sp)
    80001838:	f04a                	sd	s2,32(sp)
    8000183a:	ec4e                	sd	s3,24(sp)
    8000183c:	e852                	sd	s4,16(sp)
    8000183e:	e456                	sd	s5,8(sp)
    80001840:	e05a                	sd	s6,0(sp)
    80001842:	0080                	addi	s0,sp,64
  asm volatile("mv %0, tp" : "=r" (x) );
    80001844:	8792                	mv	a5,tp
    int id = r_tp();
    80001846:	2781                	sext.w	a5,a5
    struct proc *p;
    struct cpu *c = mycpu();

    c->proc = 0;
    80001848:	0000fa97          	auipc	s5,0xf
    8000184c:	428a8a93          	addi	s5,s5,1064 # 80010c70 <cpus>
    80001850:	00779713          	slli	a4,a5,0x7
    80001854:	00ea86b3          	add	a3,s5,a4
    80001858:	0006b023          	sd	zero,0(a3) # fffffffffffff000 <end+0xffffffff7ffdd180>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000185c:	100026f3          	csrr	a3,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001860:	0026e693          	ori	a3,a3,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001864:	10069073          	csrw	sstatus,a3
            // Switch to chosen process.  It is the process's job
            // to release its lock and then reacquire it
            // before jumping back to us.
            p->state = RUNNING;
            c->proc = p;
            swtch(&c->context, &p->context);
    80001868:	0721                	addi	a4,a4,8
    8000186a:	9aba                	add	s5,s5,a4
    for (p = proc; p < &proc[NPROC]; p++)
    8000186c:	00010497          	auipc	s1,0x10
    80001870:	83448493          	addi	s1,s1,-1996 # 800110a0 <proc>
        if (p->state == RUNNABLE)
    80001874:	498d                	li	s3,3
            p->state = RUNNING;
    80001876:	4b11                	li	s6,4
            c->proc = p;
    80001878:	079e                	slli	a5,a5,0x7
    8000187a:	0000fa17          	auipc	s4,0xf
    8000187e:	3f6a0a13          	addi	s4,s4,1014 # 80010c70 <cpus>
    80001882:	9a3e                	add	s4,s4,a5
    for (p = proc; p < &proc[NPROC]; p++)
    80001884:	00015917          	auipc	s2,0x15
    80001888:	21c90913          	addi	s2,s2,540 # 80016aa0 <tickslock>
    8000188c:	a811                	j	800018a0 <rr_scheduler+0x70>

            // Process is done running for now.
            // It should have changed its p->state before coming back.
            c->proc = 0;
        }
        release(&p->lock);
    8000188e:	8526                	mv	a0,s1
    80001890:	fffff097          	auipc	ra,0xfffff
    80001894:	3f6080e7          	jalr	1014(ra) # 80000c86 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001898:	16848493          	addi	s1,s1,360
    8000189c:	03248863          	beq	s1,s2,800018cc <rr_scheduler+0x9c>
        acquire(&p->lock);
    800018a0:	8526                	mv	a0,s1
    800018a2:	fffff097          	auipc	ra,0xfffff
    800018a6:	330080e7          	jalr	816(ra) # 80000bd2 <acquire>
        if (p->state == RUNNABLE)
    800018aa:	4c9c                	lw	a5,24(s1)
    800018ac:	ff3791e3          	bne	a5,s3,8000188e <rr_scheduler+0x5e>
            p->state = RUNNING;
    800018b0:	0164ac23          	sw	s6,24(s1)
            c->proc = p;
    800018b4:	009a3023          	sd	s1,0(s4)
            swtch(&c->context, &p->context);
    800018b8:	06048593          	addi	a1,s1,96
    800018bc:	8556                	mv	a0,s5
    800018be:	00001097          	auipc	ra,0x1
    800018c2:	23e080e7          	jalr	574(ra) # 80002afc <swtch>
            c->proc = 0;
    800018c6:	000a3023          	sd	zero,0(s4)
    800018ca:	b7d1                	j	8000188e <rr_scheduler+0x5e>
    }
    // In case a setsched happened, we will switch to the new scheduler after one
    // Round Robin round has completed.
}
    800018cc:	70e2                	ld	ra,56(sp)
    800018ce:	7442                	ld	s0,48(sp)
    800018d0:	74a2                	ld	s1,40(sp)
    800018d2:	7902                	ld	s2,32(sp)
    800018d4:	69e2                	ld	s3,24(sp)
    800018d6:	6a42                	ld	s4,16(sp)
    800018d8:	6aa2                	ld	s5,8(sp)
    800018da:	6b02                	ld	s6,0(sp)
    800018dc:	6121                	addi	sp,sp,64
    800018de:	8082                	ret

00000000800018e0 <mlfq_scheduler>:

int time = 0; // 

void mlfq_scheduler(void) {
    800018e0:	711d                	addi	sp,sp,-96
    800018e2:	ec86                	sd	ra,88(sp)
    800018e4:	e8a2                	sd	s0,80(sp)
    800018e6:	e4a6                	sd	s1,72(sp)
    800018e8:	e0ca                	sd	s2,64(sp)
    800018ea:	fc4e                	sd	s3,56(sp)
    800018ec:	f852                	sd	s4,48(sp)
    800018ee:	f456                	sd	s5,40(sp)
    800018f0:	f05a                	sd	s6,32(sp)
    800018f2:	ec5e                	sd	s7,24(sp)
    800018f4:	e862                	sd	s8,16(sp)
    800018f6:	e466                	sd	s9,8(sp)
    800018f8:	e06a                	sd	s10,0(sp)
    800018fa:	1080                	addi	s0,sp,96
  asm volatile("mv %0, tp" : "=r" (x) );
    800018fc:	8a92                	mv	s5,tp
    int id = r_tp();
    800018fe:	2a81                	sext.w	s5,s5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001900:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001904:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001908:	10079073          	csrw	sstatus,a5
    struct cpu *c = mycpu(); // Get the current CPU

    // Avoid deadlock by ensuring that devices can interrupt.
    intr_on();

    c->proc = 0; // No process is running on this CPU
    8000190c:	007a9713          	slli	a4,s5,0x7
    80001910:	0000f797          	auipc	a5,0xf
    80001914:	36078793          	addi	a5,a5,864 # 80010c70 <cpus>
    80001918:	97ba                	add	a5,a5,a4
    8000191a:	0007b023          	sd	zero,0(a5)

    int upTime = ticks; // Get the uptime
    8000191e:	00007a17          	auipc	s4,0x7
    80001922:	0eaa2a03          	lw	s4,234(s4) # 80008a08 <ticks>

    //Topmost queue is empty
    int topmost_empty = 1;
    80001926:	4b05                	li	s6,1
    
    //Iterate through all the processes and check if there are any in the topmost queue
    for (p = proc; p < &proc[NPROC]; p++)
    80001928:	0000f497          	auipc	s1,0xf
    8000192c:	77848493          	addi	s1,s1,1912 # 800110a0 <proc>
    {
        acquire(&p->lock);
        if (p->queue == 0 && p->state == RUNNABLE)
    80001930:	498d                	li	s3,3
    for (p = proc; p < &proc[NPROC]; p++)
    80001932:	00015917          	auipc	s2,0x15
    80001936:	16e90913          	addi	s2,s2,366 # 80016aa0 <tickslock>
    8000193a:	a811                	j	8000194e <mlfq_scheduler+0x6e>
        {
            topmost_empty = 0;
        }
        release(&p->lock);
    8000193c:	8526                	mv	a0,s1
    8000193e:	fffff097          	auipc	ra,0xfffff
    80001942:	348080e7          	jalr	840(ra) # 80000c86 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001946:	16848493          	addi	s1,s1,360
    8000194a:	01248e63          	beq	s1,s2,80001966 <mlfq_scheduler+0x86>
        acquire(&p->lock);
    8000194e:	8526                	mv	a0,s1
    80001950:	fffff097          	auipc	ra,0xfffff
    80001954:	282080e7          	jalr	642(ra) # 80000bd2 <acquire>
        if (p->queue == 0 && p->state == RUNNABLE)
    80001958:	58dc                	lw	a5,52(s1)
    8000195a:	f3ed                	bnez	a5,8000193c <mlfq_scheduler+0x5c>
    8000195c:	4c98                	lw	a4,24(s1)
    8000195e:	fd371fe3          	bne	a4,s3,8000193c <mlfq_scheduler+0x5c>
            topmost_empty = 0;
    80001962:	8b3e                	mv	s6,a5
    80001964:	bfe1                	j	8000193c <mlfq_scheduler+0x5c>
    }
    // If the topmost queue is not empty, then we will iterate through the processes
    if (!topmost_empty)
    80001966:	080b1b63          	bnez	s6,800019fc <mlfq_scheduler+0x11c>
            
                int processUptime = ticks;

                //printf("%d \n",processUptime);
            
                swtch(&c->context, &p->context);
    8000196a:	007a9b93          	slli	s7,s5,0x7
    8000196e:	0000f797          	auipc	a5,0xf
    80001972:	30a78793          	addi	a5,a5,778 # 80010c78 <cpus+0x8>
    80001976:	9bbe                	add	s7,s7,a5
        for (p = proc; p < &proc[NPROC]; p++) {
    80001978:	0000f497          	auipc	s1,0xf
    8000197c:	72848493          	addi	s1,s1,1832 # 800110a0 <proc>
            if (p->state == RUNNABLE && p->queue == 0) { // If the process is runnable and is in the topmost queue
    80001980:	498d                	li	s3,3
                p->state = RUNNING;
    80001982:	4c11                	li	s8,4
                c->proc = p;
    80001984:	007a9793          	slli	a5,s5,0x7
    80001988:	0000fa97          	auipc	s5,0xf
    8000198c:	2e8a8a93          	addi	s5,s5,744 # 80010c70 <cpus>
    80001990:	9abe                	add	s5,s5,a5
                int processUptime = ticks;
    80001992:	00007b17          	auipc	s6,0x7
    80001996:	076b0b13          	addi	s6,s6,118 # 80008a08 <ticks>
                //     p->queue = 1;
                // }

                //printf("%d \n",processUptime);

                if (processUptime > 10) {
    8000199a:	4ca9                	li	s9,10
        for (p = proc; p < &proc[NPROC]; p++) {
    8000199c:	00015917          	auipc	s2,0x15
    800019a0:	10490913          	addi	s2,s2,260 # 80016aa0 <tickslock>
    800019a4:	a821                	j	800019bc <mlfq_scheduler+0xdc>
                    p->queue = 1;
                }

                // Process is done running for now.
                // It should have changed its p->state before coming back.
                c->proc = 0;
    800019a6:	000ab023          	sd	zero,0(s5)
            }
            release(&p->lock); // Release the lock for the process
    800019aa:	8526                	mv	a0,s1
    800019ac:	fffff097          	auipc	ra,0xfffff
    800019b0:	2da080e7          	jalr	730(ra) # 80000c86 <release>
        for (p = proc; p < &proc[NPROC]; p++) {
    800019b4:	16848493          	addi	s1,s1,360
    800019b8:	0b248d63          	beq	s1,s2,80001a72 <mlfq_scheduler+0x192>
            acquire(&p->lock); // Acquire the lock for the process
    800019bc:	8526                	mv	a0,s1
    800019be:	fffff097          	auipc	ra,0xfffff
    800019c2:	214080e7          	jalr	532(ra) # 80000bd2 <acquire>
            if (p->state == RUNNABLE && p->queue == 0) { // If the process is runnable and is in the topmost queue
    800019c6:	4c9c                	lw	a5,24(s1)
    800019c8:	ff3791e3          	bne	a5,s3,800019aa <mlfq_scheduler+0xca>
    800019cc:	58dc                	lw	a5,52(s1)
    800019ce:	fff1                	bnez	a5,800019aa <mlfq_scheduler+0xca>
                p->state = RUNNING;
    800019d0:	0184ac23          	sw	s8,24(s1)
                c->proc = p;
    800019d4:	009ab023          	sd	s1,0(s5)
                int processUptime = ticks;
    800019d8:	000b2d03          	lw	s10,0(s6)
                swtch(&c->context, &p->context);
    800019dc:	06048593          	addi	a1,s1,96
    800019e0:	855e                	mv	a0,s7
    800019e2:	00001097          	auipc	ra,0x1
    800019e6:	11a080e7          	jalr	282(ra) # 80002afc <swtch>
                processUptime = ticks - processUptime;
    800019ea:	000b2783          	lw	a5,0(s6)
                if (processUptime > 10) {
    800019ee:	41a787bb          	subw	a5,a5,s10
    800019f2:	fafcdae3          	bge	s9,a5,800019a6 <mlfq_scheduler+0xc6>
                    p->queue = 1;
    800019f6:	4785                	li	a5,1
    800019f8:	d8dc                	sw	a5,52(s1)
    800019fa:	b775                	j	800019a6 <mlfq_scheduler+0xc6>
                // Switch to chosen process.  It is the process's job
                // to release its lock and then reacquire it
                // before jumping back to us.
                p->state = RUNNING;
                c->proc = p;
                swtch(&c->context, &p->context);
    800019fc:	007a9b93          	slli	s7,s5,0x7
    80001a00:	0000f797          	auipc	a5,0xf
    80001a04:	27878793          	addi	a5,a5,632 # 80010c78 <cpus+0x8>
    80001a08:	9bbe                	add	s7,s7,a5
        for (p = proc; p < &proc[NPROC]; p++) {
    80001a0a:	0000f497          	auipc	s1,0xf
    80001a0e:	69648493          	addi	s1,s1,1686 # 800110a0 <proc>
            if (p->state == RUNNABLE && p->queue == 1) { // If the process is runnable and is in the topmost queue
    80001a12:	498d                	li	s3,3
    80001a14:	4b05                	li	s6,1
                p->state = RUNNING;
    80001a16:	4c11                	li	s8,4
                c->proc = p;
    80001a18:	0a9e                	slli	s5,s5,0x7
    80001a1a:	0000f797          	auipc	a5,0xf
    80001a1e:	25678793          	addi	a5,a5,598 # 80010c70 <cpus>
    80001a22:	9abe                	add	s5,s5,a5
        for (p = proc; p < &proc[NPROC]; p++) {
    80001a24:	00015917          	auipc	s2,0x15
    80001a28:	07c90913          	addi	s2,s2,124 # 80016aa0 <tickslock>
    80001a2c:	a811                	j	80001a40 <mlfq_scheduler+0x160>

                // Process is done running for now.
                // It should have changed its p->state before coming back.
                c->proc = 0;
            }
            release(&p->lock); // Release the lock for the process
    80001a2e:	8526                	mv	a0,s1
    80001a30:	fffff097          	auipc	ra,0xfffff
    80001a34:	256080e7          	jalr	598(ra) # 80000c86 <release>
        for (p = proc; p < &proc[NPROC]; p++) {
    80001a38:	16848493          	addi	s1,s1,360
    80001a3c:	03248b63          	beq	s1,s2,80001a72 <mlfq_scheduler+0x192>
            acquire(&p->lock); // Acquire the lock for the process
    80001a40:	8526                	mv	a0,s1
    80001a42:	fffff097          	auipc	ra,0xfffff
    80001a46:	190080e7          	jalr	400(ra) # 80000bd2 <acquire>
            if (p->state == RUNNABLE && p->queue == 1) { // If the process is runnable and is in the topmost queue
    80001a4a:	4c9c                	lw	a5,24(s1)
    80001a4c:	ff3791e3          	bne	a5,s3,80001a2e <mlfq_scheduler+0x14e>
    80001a50:	58dc                	lw	a5,52(s1)
    80001a52:	fd679ee3          	bne	a5,s6,80001a2e <mlfq_scheduler+0x14e>
                p->state = RUNNING;
    80001a56:	0184ac23          	sw	s8,24(s1)
                c->proc = p;
    80001a5a:	009ab023          	sd	s1,0(s5)
                swtch(&c->context, &p->context);
    80001a5e:	06048593          	addi	a1,s1,96
    80001a62:	855e                	mv	a0,s7
    80001a64:	00001097          	auipc	ra,0x1
    80001a68:	098080e7          	jalr	152(ra) # 80002afc <swtch>
                c->proc = 0;
    80001a6c:	000ab023          	sd	zero,0(s5)
    80001a70:	bf7d                	j	80001a2e <mlfq_scheduler+0x14e>
        }
    }

    upTime += ticks;
    80001a72:	00007797          	auipc	a5,0x7
    80001a76:	f967a783          	lw	a5,-106(a5) # 80008a08 <ticks>
    80001a7a:	014787bb          	addw	a5,a5,s4
    time += upTime;
    80001a7e:	00007717          	auipc	a4,0x7
    80001a82:	f7a72703          	lw	a4,-134(a4) # 800089f8 <time>
    80001a86:	9fb9                	addw	a5,a5,a4
    80001a88:	0007869b          	sext.w	a3,a5

    if (time == 10) {
    80001a8c:	4729                	li	a4,10
    80001a8e:	02e68463          	beq	a3,a4,80001ab6 <mlfq_scheduler+0x1d6>
    time += upTime;
    80001a92:	00007717          	auipc	a4,0x7
    80001a96:	f6f72323          	sw	a5,-154(a4) # 800089f8 <time>
                p->queue = 0;
            }
            release(&p->lock); // Release the lock for the process
        }
    }
}
    80001a9a:	60e6                	ld	ra,88(sp)
    80001a9c:	6446                	ld	s0,80(sp)
    80001a9e:	64a6                	ld	s1,72(sp)
    80001aa0:	6906                	ld	s2,64(sp)
    80001aa2:	79e2                	ld	s3,56(sp)
    80001aa4:	7a42                	ld	s4,48(sp)
    80001aa6:	7aa2                	ld	s5,40(sp)
    80001aa8:	7b02                	ld	s6,32(sp)
    80001aaa:	6be2                	ld	s7,24(sp)
    80001aac:	6c42                	ld	s8,16(sp)
    80001aae:	6ca2                	ld	s9,8(sp)
    80001ab0:	6d02                	ld	s10,0(sp)
    80001ab2:	6125                	addi	sp,sp,96
    80001ab4:	8082                	ret
        time = 0;
    80001ab6:	00007797          	auipc	a5,0x7
    80001aba:	f407a123          	sw	zero,-190(a5) # 800089f8 <time>
        for (p = proc; p < &proc[NPROC]; p++) {
    80001abe:	0000f497          	auipc	s1,0xf
    80001ac2:	5e248493          	addi	s1,s1,1506 # 800110a0 <proc>
            if (p->state == RUNNABLE) { // If the process is runnable and is in the topmost queue
    80001ac6:	498d                	li	s3,3
        for (p = proc; p < &proc[NPROC]; p++) {
    80001ac8:	00015917          	auipc	s2,0x15
    80001acc:	fd890913          	addi	s2,s2,-40 # 80016aa0 <tickslock>
    80001ad0:	a811                	j	80001ae4 <mlfq_scheduler+0x204>
            release(&p->lock); // Release the lock for the process
    80001ad2:	8526                	mv	a0,s1
    80001ad4:	fffff097          	auipc	ra,0xfffff
    80001ad8:	1b2080e7          	jalr	434(ra) # 80000c86 <release>
        for (p = proc; p < &proc[NPROC]; p++) {
    80001adc:	16848493          	addi	s1,s1,360
    80001ae0:	fb248de3          	beq	s1,s2,80001a9a <mlfq_scheduler+0x1ba>
            acquire(&p->lock); // Acquire the lock for the process
    80001ae4:	8526                	mv	a0,s1
    80001ae6:	fffff097          	auipc	ra,0xfffff
    80001aea:	0ec080e7          	jalr	236(ra) # 80000bd2 <acquire>
            if (p->state == RUNNABLE) { // If the process is runnable and is in the topmost queue
    80001aee:	4c9c                	lw	a5,24(s1)
    80001af0:	ff3791e3          	bne	a5,s3,80001ad2 <mlfq_scheduler+0x1f2>
                p->queue = 0;
    80001af4:	0204aa23          	sw	zero,52(s1)
    80001af8:	bfe9                	j	80001ad2 <mlfq_scheduler+0x1f2>

0000000080001afa <proc_mapstacks>:
{
    80001afa:	7139                	addi	sp,sp,-64
    80001afc:	fc06                	sd	ra,56(sp)
    80001afe:	f822                	sd	s0,48(sp)
    80001b00:	f426                	sd	s1,40(sp)
    80001b02:	f04a                	sd	s2,32(sp)
    80001b04:	ec4e                	sd	s3,24(sp)
    80001b06:	e852                	sd	s4,16(sp)
    80001b08:	e456                	sd	s5,8(sp)
    80001b0a:	e05a                	sd	s6,0(sp)
    80001b0c:	0080                	addi	s0,sp,64
    80001b0e:	89aa                	mv	s3,a0
    for (p = proc; p < &proc[NPROC]; p++)
    80001b10:	0000f497          	auipc	s1,0xf
    80001b14:	59048493          	addi	s1,s1,1424 # 800110a0 <proc>
        uint64 va = KSTACK((int)(p - proc));
    80001b18:	8b26                	mv	s6,s1
    80001b1a:	00006a97          	auipc	s5,0x6
    80001b1e:	4e6a8a93          	addi	s5,s5,1254 # 80008000 <etext>
    80001b22:	04000937          	lui	s2,0x4000
    80001b26:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001b28:	0932                	slli	s2,s2,0xc
    for (p = proc; p < &proc[NPROC]; p++)
    80001b2a:	00015a17          	auipc	s4,0x15
    80001b2e:	f76a0a13          	addi	s4,s4,-138 # 80016aa0 <tickslock>
        char *pa = kalloc();
    80001b32:	fffff097          	auipc	ra,0xfffff
    80001b36:	fb0080e7          	jalr	-80(ra) # 80000ae2 <kalloc>
    80001b3a:	862a                	mv	a2,a0
        if (pa == 0)
    80001b3c:	c131                	beqz	a0,80001b80 <proc_mapstacks+0x86>
        uint64 va = KSTACK((int)(p - proc));
    80001b3e:	416485b3          	sub	a1,s1,s6
    80001b42:	858d                	srai	a1,a1,0x3
    80001b44:	000ab783          	ld	a5,0(s5)
    80001b48:	02f585b3          	mul	a1,a1,a5
    80001b4c:	2585                	addiw	a1,a1,1
    80001b4e:	00d5959b          	slliw	a1,a1,0xd
        kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001b52:	4719                	li	a4,6
    80001b54:	6685                	lui	a3,0x1
    80001b56:	40b905b3          	sub	a1,s2,a1
    80001b5a:	854e                	mv	a0,s3
    80001b5c:	fffff097          	auipc	ra,0xfffff
    80001b60:	5dc080e7          	jalr	1500(ra) # 80001138 <kvmmap>
    for (p = proc; p < &proc[NPROC]; p++)
    80001b64:	16848493          	addi	s1,s1,360
    80001b68:	fd4495e3          	bne	s1,s4,80001b32 <proc_mapstacks+0x38>
}
    80001b6c:	70e2                	ld	ra,56(sp)
    80001b6e:	7442                	ld	s0,48(sp)
    80001b70:	74a2                	ld	s1,40(sp)
    80001b72:	7902                	ld	s2,32(sp)
    80001b74:	69e2                	ld	s3,24(sp)
    80001b76:	6a42                	ld	s4,16(sp)
    80001b78:	6aa2                	ld	s5,8(sp)
    80001b7a:	6b02                	ld	s6,0(sp)
    80001b7c:	6121                	addi	sp,sp,64
    80001b7e:	8082                	ret
            panic("kalloc");
    80001b80:	00006517          	auipc	a0,0x6
    80001b84:	65850513          	addi	a0,a0,1624 # 800081d8 <digits+0x198>
    80001b88:	fffff097          	auipc	ra,0xfffff
    80001b8c:	9b4080e7          	jalr	-1612(ra) # 8000053c <panic>

0000000080001b90 <procinit>:
{
    80001b90:	7139                	addi	sp,sp,-64
    80001b92:	fc06                	sd	ra,56(sp)
    80001b94:	f822                	sd	s0,48(sp)
    80001b96:	f426                	sd	s1,40(sp)
    80001b98:	f04a                	sd	s2,32(sp)
    80001b9a:	ec4e                	sd	s3,24(sp)
    80001b9c:	e852                	sd	s4,16(sp)
    80001b9e:	e456                	sd	s5,8(sp)
    80001ba0:	e05a                	sd	s6,0(sp)
    80001ba2:	0080                	addi	s0,sp,64
    initlock(&pid_lock, "nextpid");
    80001ba4:	00006597          	auipc	a1,0x6
    80001ba8:	63c58593          	addi	a1,a1,1596 # 800081e0 <digits+0x1a0>
    80001bac:	0000f517          	auipc	a0,0xf
    80001bb0:	4c450513          	addi	a0,a0,1220 # 80011070 <pid_lock>
    80001bb4:	fffff097          	auipc	ra,0xfffff
    80001bb8:	f8e080e7          	jalr	-114(ra) # 80000b42 <initlock>
    initlock(&wait_lock, "wait_lock");
    80001bbc:	00006597          	auipc	a1,0x6
    80001bc0:	62c58593          	addi	a1,a1,1580 # 800081e8 <digits+0x1a8>
    80001bc4:	0000f517          	auipc	a0,0xf
    80001bc8:	4c450513          	addi	a0,a0,1220 # 80011088 <wait_lock>
    80001bcc:	fffff097          	auipc	ra,0xfffff
    80001bd0:	f76080e7          	jalr	-138(ra) # 80000b42 <initlock>
    for (p = proc; p < &proc[NPROC]; p++)
    80001bd4:	0000f497          	auipc	s1,0xf
    80001bd8:	4cc48493          	addi	s1,s1,1228 # 800110a0 <proc>
        initlock(&p->lock, "proc");
    80001bdc:	00006b17          	auipc	s6,0x6
    80001be0:	61cb0b13          	addi	s6,s6,1564 # 800081f8 <digits+0x1b8>
        p->kstack = KSTACK((int)(p - proc));
    80001be4:	8aa6                	mv	s5,s1
    80001be6:	00006a17          	auipc	s4,0x6
    80001bea:	41aa0a13          	addi	s4,s4,1050 # 80008000 <etext>
    80001bee:	04000937          	lui	s2,0x4000
    80001bf2:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001bf4:	0932                	slli	s2,s2,0xc
    for (p = proc; p < &proc[NPROC]; p++)
    80001bf6:	00015997          	auipc	s3,0x15
    80001bfa:	eaa98993          	addi	s3,s3,-342 # 80016aa0 <tickslock>
        initlock(&p->lock, "proc");
    80001bfe:	85da                	mv	a1,s6
    80001c00:	8526                	mv	a0,s1
    80001c02:	fffff097          	auipc	ra,0xfffff
    80001c06:	f40080e7          	jalr	-192(ra) # 80000b42 <initlock>
        p->state = UNUSED;
    80001c0a:	0004ac23          	sw	zero,24(s1)
        p->kstack = KSTACK((int)(p - proc));
    80001c0e:	415487b3          	sub	a5,s1,s5
    80001c12:	878d                	srai	a5,a5,0x3
    80001c14:	000a3703          	ld	a4,0(s4)
    80001c18:	02e787b3          	mul	a5,a5,a4
    80001c1c:	2785                	addiw	a5,a5,1
    80001c1e:	00d7979b          	slliw	a5,a5,0xd
    80001c22:	40f907b3          	sub	a5,s2,a5
    80001c26:	e0bc                	sd	a5,64(s1)
    for (p = proc; p < &proc[NPROC]; p++)
    80001c28:	16848493          	addi	s1,s1,360
    80001c2c:	fd3499e3          	bne	s1,s3,80001bfe <procinit+0x6e>
}
    80001c30:	70e2                	ld	ra,56(sp)
    80001c32:	7442                	ld	s0,48(sp)
    80001c34:	74a2                	ld	s1,40(sp)
    80001c36:	7902                	ld	s2,32(sp)
    80001c38:	69e2                	ld	s3,24(sp)
    80001c3a:	6a42                	ld	s4,16(sp)
    80001c3c:	6aa2                	ld	s5,8(sp)
    80001c3e:	6b02                	ld	s6,0(sp)
    80001c40:	6121                	addi	sp,sp,64
    80001c42:	8082                	ret

0000000080001c44 <copy_array>:
{
    80001c44:	1141                	addi	sp,sp,-16
    80001c46:	e422                	sd	s0,8(sp)
    80001c48:	0800                	addi	s0,sp,16
    for (int i = 0; i < len; i++)
    80001c4a:	00c05c63          	blez	a2,80001c62 <copy_array+0x1e>
    80001c4e:	87aa                	mv	a5,a0
    80001c50:	9532                	add	a0,a0,a2
        dst[i] = src[i];
    80001c52:	0007c703          	lbu	a4,0(a5)
    80001c56:	00e58023          	sb	a4,0(a1)
    for (int i = 0; i < len; i++)
    80001c5a:	0785                	addi	a5,a5,1
    80001c5c:	0585                	addi	a1,a1,1
    80001c5e:	fea79ae3          	bne	a5,a0,80001c52 <copy_array+0xe>
}
    80001c62:	6422                	ld	s0,8(sp)
    80001c64:	0141                	addi	sp,sp,16
    80001c66:	8082                	ret

0000000080001c68 <cpuid>:
{
    80001c68:	1141                	addi	sp,sp,-16
    80001c6a:	e422                	sd	s0,8(sp)
    80001c6c:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001c6e:	8512                	mv	a0,tp
}
    80001c70:	2501                	sext.w	a0,a0
    80001c72:	6422                	ld	s0,8(sp)
    80001c74:	0141                	addi	sp,sp,16
    80001c76:	8082                	ret

0000000080001c78 <mycpu>:
{
    80001c78:	1141                	addi	sp,sp,-16
    80001c7a:	e422                	sd	s0,8(sp)
    80001c7c:	0800                	addi	s0,sp,16
    80001c7e:	8792                	mv	a5,tp
    struct cpu *c = &cpus[id];
    80001c80:	2781                	sext.w	a5,a5
    80001c82:	079e                	slli	a5,a5,0x7
}
    80001c84:	0000f517          	auipc	a0,0xf
    80001c88:	fec50513          	addi	a0,a0,-20 # 80010c70 <cpus>
    80001c8c:	953e                	add	a0,a0,a5
    80001c8e:	6422                	ld	s0,8(sp)
    80001c90:	0141                	addi	sp,sp,16
    80001c92:	8082                	ret

0000000080001c94 <myproc>:
{
    80001c94:	1101                	addi	sp,sp,-32
    80001c96:	ec06                	sd	ra,24(sp)
    80001c98:	e822                	sd	s0,16(sp)
    80001c9a:	e426                	sd	s1,8(sp)
    80001c9c:	1000                	addi	s0,sp,32
    push_off();
    80001c9e:	fffff097          	auipc	ra,0xfffff
    80001ca2:	ee8080e7          	jalr	-280(ra) # 80000b86 <push_off>
    80001ca6:	8792                	mv	a5,tp
    struct proc *p = c->proc;
    80001ca8:	2781                	sext.w	a5,a5
    80001caa:	079e                	slli	a5,a5,0x7
    80001cac:	0000f717          	auipc	a4,0xf
    80001cb0:	fc470713          	addi	a4,a4,-60 # 80010c70 <cpus>
    80001cb4:	97ba                	add	a5,a5,a4
    80001cb6:	6384                	ld	s1,0(a5)
    pop_off();
    80001cb8:	fffff097          	auipc	ra,0xfffff
    80001cbc:	f6e080e7          	jalr	-146(ra) # 80000c26 <pop_off>
}
    80001cc0:	8526                	mv	a0,s1
    80001cc2:	60e2                	ld	ra,24(sp)
    80001cc4:	6442                	ld	s0,16(sp)
    80001cc6:	64a2                	ld	s1,8(sp)
    80001cc8:	6105                	addi	sp,sp,32
    80001cca:	8082                	ret

0000000080001ccc <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001ccc:	1141                	addi	sp,sp,-16
    80001cce:	e406                	sd	ra,8(sp)
    80001cd0:	e022                	sd	s0,0(sp)
    80001cd2:	0800                	addi	s0,sp,16
    static int first = 1;

    // Still holding p->lock from scheduler.
    release(&myproc()->lock);
    80001cd4:	00000097          	auipc	ra,0x0
    80001cd8:	fc0080e7          	jalr	-64(ra) # 80001c94 <myproc>
    80001cdc:	fffff097          	auipc	ra,0xfffff
    80001ce0:	faa080e7          	jalr	-86(ra) # 80000c86 <release>

    if (first)
    80001ce4:	00007797          	auipc	a5,0x7
    80001ce8:	c4c7a783          	lw	a5,-948(a5) # 80008930 <first.1>
    80001cec:	eb89                	bnez	a5,80001cfe <forkret+0x32>
        // be run from main().
        first = 0;
        fsinit(ROOTDEV);
    }

    usertrapret();
    80001cee:	00001097          	auipc	ra,0x1
    80001cf2:	eb8080e7          	jalr	-328(ra) # 80002ba6 <usertrapret>
}
    80001cf6:	60a2                	ld	ra,8(sp)
    80001cf8:	6402                	ld	s0,0(sp)
    80001cfa:	0141                	addi	sp,sp,16
    80001cfc:	8082                	ret
        first = 0;
    80001cfe:	00007797          	auipc	a5,0x7
    80001d02:	c207a923          	sw	zero,-974(a5) # 80008930 <first.1>
        fsinit(ROOTDEV);
    80001d06:	4505                	li	a0,1
    80001d08:	00002097          	auipc	ra,0x2
    80001d0c:	c7c080e7          	jalr	-900(ra) # 80003984 <fsinit>
    80001d10:	bff9                	j	80001cee <forkret+0x22>

0000000080001d12 <allocpid>:
{
    80001d12:	1101                	addi	sp,sp,-32
    80001d14:	ec06                	sd	ra,24(sp)
    80001d16:	e822                	sd	s0,16(sp)
    80001d18:	e426                	sd	s1,8(sp)
    80001d1a:	e04a                	sd	s2,0(sp)
    80001d1c:	1000                	addi	s0,sp,32
    acquire(&pid_lock);
    80001d1e:	0000f917          	auipc	s2,0xf
    80001d22:	35290913          	addi	s2,s2,850 # 80011070 <pid_lock>
    80001d26:	854a                	mv	a0,s2
    80001d28:	fffff097          	auipc	ra,0xfffff
    80001d2c:	eaa080e7          	jalr	-342(ra) # 80000bd2 <acquire>
    pid = nextpid;
    80001d30:	00007797          	auipc	a5,0x7
    80001d34:	c1078793          	addi	a5,a5,-1008 # 80008940 <nextpid>
    80001d38:	4384                	lw	s1,0(a5)
    nextpid = nextpid + 1;
    80001d3a:	0014871b          	addiw	a4,s1,1
    80001d3e:	c398                	sw	a4,0(a5)
    release(&pid_lock);
    80001d40:	854a                	mv	a0,s2
    80001d42:	fffff097          	auipc	ra,0xfffff
    80001d46:	f44080e7          	jalr	-188(ra) # 80000c86 <release>
}
    80001d4a:	8526                	mv	a0,s1
    80001d4c:	60e2                	ld	ra,24(sp)
    80001d4e:	6442                	ld	s0,16(sp)
    80001d50:	64a2                	ld	s1,8(sp)
    80001d52:	6902                	ld	s2,0(sp)
    80001d54:	6105                	addi	sp,sp,32
    80001d56:	8082                	ret

0000000080001d58 <proc_pagetable>:
{
    80001d58:	1101                	addi	sp,sp,-32
    80001d5a:	ec06                	sd	ra,24(sp)
    80001d5c:	e822                	sd	s0,16(sp)
    80001d5e:	e426                	sd	s1,8(sp)
    80001d60:	e04a                	sd	s2,0(sp)
    80001d62:	1000                	addi	s0,sp,32
    80001d64:	892a                	mv	s2,a0
    pagetable = uvmcreate();
    80001d66:	fffff097          	auipc	ra,0xfffff
    80001d6a:	5bc080e7          	jalr	1468(ra) # 80001322 <uvmcreate>
    80001d6e:	84aa                	mv	s1,a0
    if (pagetable == 0)
    80001d70:	c121                	beqz	a0,80001db0 <proc_pagetable+0x58>
    if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001d72:	4729                	li	a4,10
    80001d74:	00005697          	auipc	a3,0x5
    80001d78:	28c68693          	addi	a3,a3,652 # 80007000 <_trampoline>
    80001d7c:	6605                	lui	a2,0x1
    80001d7e:	040005b7          	lui	a1,0x4000
    80001d82:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001d84:	05b2                	slli	a1,a1,0xc
    80001d86:	fffff097          	auipc	ra,0xfffff
    80001d8a:	312080e7          	jalr	786(ra) # 80001098 <mappages>
    80001d8e:	02054863          	bltz	a0,80001dbe <proc_pagetable+0x66>
    if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001d92:	4719                	li	a4,6
    80001d94:	05893683          	ld	a3,88(s2)
    80001d98:	6605                	lui	a2,0x1
    80001d9a:	020005b7          	lui	a1,0x2000
    80001d9e:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001da0:	05b6                	slli	a1,a1,0xd
    80001da2:	8526                	mv	a0,s1
    80001da4:	fffff097          	auipc	ra,0xfffff
    80001da8:	2f4080e7          	jalr	756(ra) # 80001098 <mappages>
    80001dac:	02054163          	bltz	a0,80001dce <proc_pagetable+0x76>
}
    80001db0:	8526                	mv	a0,s1
    80001db2:	60e2                	ld	ra,24(sp)
    80001db4:	6442                	ld	s0,16(sp)
    80001db6:	64a2                	ld	s1,8(sp)
    80001db8:	6902                	ld	s2,0(sp)
    80001dba:	6105                	addi	sp,sp,32
    80001dbc:	8082                	ret
        uvmfree(pagetable, 0);
    80001dbe:	4581                	li	a1,0
    80001dc0:	8526                	mv	a0,s1
    80001dc2:	fffff097          	auipc	ra,0xfffff
    80001dc6:	766080e7          	jalr	1894(ra) # 80001528 <uvmfree>
        return 0;
    80001dca:	4481                	li	s1,0
    80001dcc:	b7d5                	j	80001db0 <proc_pagetable+0x58>
        uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001dce:	4681                	li	a3,0
    80001dd0:	4605                	li	a2,1
    80001dd2:	040005b7          	lui	a1,0x4000
    80001dd6:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001dd8:	05b2                	slli	a1,a1,0xc
    80001dda:	8526                	mv	a0,s1
    80001ddc:	fffff097          	auipc	ra,0xfffff
    80001de0:	482080e7          	jalr	1154(ra) # 8000125e <uvmunmap>
        uvmfree(pagetable, 0);
    80001de4:	4581                	li	a1,0
    80001de6:	8526                	mv	a0,s1
    80001de8:	fffff097          	auipc	ra,0xfffff
    80001dec:	740080e7          	jalr	1856(ra) # 80001528 <uvmfree>
        return 0;
    80001df0:	4481                	li	s1,0
    80001df2:	bf7d                	j	80001db0 <proc_pagetable+0x58>

0000000080001df4 <proc_freepagetable>:
{
    80001df4:	1101                	addi	sp,sp,-32
    80001df6:	ec06                	sd	ra,24(sp)
    80001df8:	e822                	sd	s0,16(sp)
    80001dfa:	e426                	sd	s1,8(sp)
    80001dfc:	e04a                	sd	s2,0(sp)
    80001dfe:	1000                	addi	s0,sp,32
    80001e00:	84aa                	mv	s1,a0
    80001e02:	892e                	mv	s2,a1
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001e04:	4681                	li	a3,0
    80001e06:	4605                	li	a2,1
    80001e08:	040005b7          	lui	a1,0x4000
    80001e0c:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001e0e:	05b2                	slli	a1,a1,0xc
    80001e10:	fffff097          	auipc	ra,0xfffff
    80001e14:	44e080e7          	jalr	1102(ra) # 8000125e <uvmunmap>
    uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001e18:	4681                	li	a3,0
    80001e1a:	4605                	li	a2,1
    80001e1c:	020005b7          	lui	a1,0x2000
    80001e20:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001e22:	05b6                	slli	a1,a1,0xd
    80001e24:	8526                	mv	a0,s1
    80001e26:	fffff097          	auipc	ra,0xfffff
    80001e2a:	438080e7          	jalr	1080(ra) # 8000125e <uvmunmap>
    uvmfree(pagetable, sz);
    80001e2e:	85ca                	mv	a1,s2
    80001e30:	8526                	mv	a0,s1
    80001e32:	fffff097          	auipc	ra,0xfffff
    80001e36:	6f6080e7          	jalr	1782(ra) # 80001528 <uvmfree>
}
    80001e3a:	60e2                	ld	ra,24(sp)
    80001e3c:	6442                	ld	s0,16(sp)
    80001e3e:	64a2                	ld	s1,8(sp)
    80001e40:	6902                	ld	s2,0(sp)
    80001e42:	6105                	addi	sp,sp,32
    80001e44:	8082                	ret

0000000080001e46 <freeproc>:
{
    80001e46:	1101                	addi	sp,sp,-32
    80001e48:	ec06                	sd	ra,24(sp)
    80001e4a:	e822                	sd	s0,16(sp)
    80001e4c:	e426                	sd	s1,8(sp)
    80001e4e:	1000                	addi	s0,sp,32
    80001e50:	84aa                	mv	s1,a0
    if (p->trapframe)
    80001e52:	6d28                	ld	a0,88(a0)
    80001e54:	c509                	beqz	a0,80001e5e <freeproc+0x18>
        kfree((void *)p->trapframe);
    80001e56:	fffff097          	auipc	ra,0xfffff
    80001e5a:	b8e080e7          	jalr	-1138(ra) # 800009e4 <kfree>
    p->trapframe = 0;
    80001e5e:	0404bc23          	sd	zero,88(s1)
    if (p->pagetable)
    80001e62:	68a8                	ld	a0,80(s1)
    80001e64:	c511                	beqz	a0,80001e70 <freeproc+0x2a>
        proc_freepagetable(p->pagetable, p->sz);
    80001e66:	64ac                	ld	a1,72(s1)
    80001e68:	00000097          	auipc	ra,0x0
    80001e6c:	f8c080e7          	jalr	-116(ra) # 80001df4 <proc_freepagetable>
    p->pagetable = 0;
    80001e70:	0404b823          	sd	zero,80(s1)
    p->sz = 0;
    80001e74:	0404b423          	sd	zero,72(s1)
    p->pid = 0;
    80001e78:	0204a823          	sw	zero,48(s1)
    p->parent = 0;
    80001e7c:	0204bc23          	sd	zero,56(s1)
    p->name[0] = 0;
    80001e80:	14048c23          	sb	zero,344(s1)
    p->chan = 0;
    80001e84:	0204b023          	sd	zero,32(s1)
    p->killed = 0;
    80001e88:	0204a423          	sw	zero,40(s1)
    p->xstate = 0;
    80001e8c:	0204a623          	sw	zero,44(s1)
    p->state = UNUSED;
    80001e90:	0004ac23          	sw	zero,24(s1)
}
    80001e94:	60e2                	ld	ra,24(sp)
    80001e96:	6442                	ld	s0,16(sp)
    80001e98:	64a2                	ld	s1,8(sp)
    80001e9a:	6105                	addi	sp,sp,32
    80001e9c:	8082                	ret

0000000080001e9e <allocproc>:
{
    80001e9e:	1101                	addi	sp,sp,-32
    80001ea0:	ec06                	sd	ra,24(sp)
    80001ea2:	e822                	sd	s0,16(sp)
    80001ea4:	e426                	sd	s1,8(sp)
    80001ea6:	e04a                	sd	s2,0(sp)
    80001ea8:	1000                	addi	s0,sp,32
    for (p = proc; p < &proc[NPROC]; p++)
    80001eaa:	0000f497          	auipc	s1,0xf
    80001eae:	1f648493          	addi	s1,s1,502 # 800110a0 <proc>
    80001eb2:	00015917          	auipc	s2,0x15
    80001eb6:	bee90913          	addi	s2,s2,-1042 # 80016aa0 <tickslock>
        acquire(&p->lock);
    80001eba:	8526                	mv	a0,s1
    80001ebc:	fffff097          	auipc	ra,0xfffff
    80001ec0:	d16080e7          	jalr	-746(ra) # 80000bd2 <acquire>
        if (p->state == UNUSED)
    80001ec4:	4c9c                	lw	a5,24(s1)
    80001ec6:	cf81                	beqz	a5,80001ede <allocproc+0x40>
            release(&p->lock);
    80001ec8:	8526                	mv	a0,s1
    80001eca:	fffff097          	auipc	ra,0xfffff
    80001ece:	dbc080e7          	jalr	-580(ra) # 80000c86 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001ed2:	16848493          	addi	s1,s1,360
    80001ed6:	ff2492e3          	bne	s1,s2,80001eba <allocproc+0x1c>
    return 0;
    80001eda:	4481                	li	s1,0
    80001edc:	a889                	j	80001f2e <allocproc+0x90>
    p->pid = allocpid();
    80001ede:	00000097          	auipc	ra,0x0
    80001ee2:	e34080e7          	jalr	-460(ra) # 80001d12 <allocpid>
    80001ee6:	d888                	sw	a0,48(s1)
    p->state = USED;
    80001ee8:	4785                	li	a5,1
    80001eea:	cc9c                	sw	a5,24(s1)
    if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001eec:	fffff097          	auipc	ra,0xfffff
    80001ef0:	bf6080e7          	jalr	-1034(ra) # 80000ae2 <kalloc>
    80001ef4:	892a                	mv	s2,a0
    80001ef6:	eca8                	sd	a0,88(s1)
    80001ef8:	c131                	beqz	a0,80001f3c <allocproc+0x9e>
    p->pagetable = proc_pagetable(p);
    80001efa:	8526                	mv	a0,s1
    80001efc:	00000097          	auipc	ra,0x0
    80001f00:	e5c080e7          	jalr	-420(ra) # 80001d58 <proc_pagetable>
    80001f04:	892a                	mv	s2,a0
    80001f06:	e8a8                	sd	a0,80(s1)
    if (p->pagetable == 0)
    80001f08:	c531                	beqz	a0,80001f54 <allocproc+0xb6>
    memset(&p->context, 0, sizeof(p->context));
    80001f0a:	07000613          	li	a2,112
    80001f0e:	4581                	li	a1,0
    80001f10:	06048513          	addi	a0,s1,96
    80001f14:	fffff097          	auipc	ra,0xfffff
    80001f18:	dba080e7          	jalr	-582(ra) # 80000cce <memset>
    p->context.ra = (uint64)forkret;
    80001f1c:	00000797          	auipc	a5,0x0
    80001f20:	db078793          	addi	a5,a5,-592 # 80001ccc <forkret>
    80001f24:	f0bc                	sd	a5,96(s1)
    p->context.sp = p->kstack + PGSIZE;
    80001f26:	60bc                	ld	a5,64(s1)
    80001f28:	6705                	lui	a4,0x1
    80001f2a:	97ba                	add	a5,a5,a4
    80001f2c:	f4bc                	sd	a5,104(s1)
}
    80001f2e:	8526                	mv	a0,s1
    80001f30:	60e2                	ld	ra,24(sp)
    80001f32:	6442                	ld	s0,16(sp)
    80001f34:	64a2                	ld	s1,8(sp)
    80001f36:	6902                	ld	s2,0(sp)
    80001f38:	6105                	addi	sp,sp,32
    80001f3a:	8082                	ret
        freeproc(p);
    80001f3c:	8526                	mv	a0,s1
    80001f3e:	00000097          	auipc	ra,0x0
    80001f42:	f08080e7          	jalr	-248(ra) # 80001e46 <freeproc>
        release(&p->lock);
    80001f46:	8526                	mv	a0,s1
    80001f48:	fffff097          	auipc	ra,0xfffff
    80001f4c:	d3e080e7          	jalr	-706(ra) # 80000c86 <release>
        return 0;
    80001f50:	84ca                	mv	s1,s2
    80001f52:	bff1                	j	80001f2e <allocproc+0x90>
        freeproc(p);
    80001f54:	8526                	mv	a0,s1
    80001f56:	00000097          	auipc	ra,0x0
    80001f5a:	ef0080e7          	jalr	-272(ra) # 80001e46 <freeproc>
        release(&p->lock);
    80001f5e:	8526                	mv	a0,s1
    80001f60:	fffff097          	auipc	ra,0xfffff
    80001f64:	d26080e7          	jalr	-730(ra) # 80000c86 <release>
        return 0;
    80001f68:	84ca                	mv	s1,s2
    80001f6a:	b7d1                	j	80001f2e <allocproc+0x90>

0000000080001f6c <userinit>:
{
    80001f6c:	1101                	addi	sp,sp,-32
    80001f6e:	ec06                	sd	ra,24(sp)
    80001f70:	e822                	sd	s0,16(sp)
    80001f72:	e426                	sd	s1,8(sp)
    80001f74:	1000                	addi	s0,sp,32
    p = allocproc();
    80001f76:	00000097          	auipc	ra,0x0
    80001f7a:	f28080e7          	jalr	-216(ra) # 80001e9e <allocproc>
    80001f7e:	84aa                	mv	s1,a0
    initproc = p;
    80001f80:	00007797          	auipc	a5,0x7
    80001f84:	a8a7b023          	sd	a0,-1408(a5) # 80008a00 <initproc>
    uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001f88:	03400613          	li	a2,52
    80001f8c:	00007597          	auipc	a1,0x7
    80001f90:	9c458593          	addi	a1,a1,-1596 # 80008950 <initcode>
    80001f94:	6928                	ld	a0,80(a0)
    80001f96:	fffff097          	auipc	ra,0xfffff
    80001f9a:	3ba080e7          	jalr	954(ra) # 80001350 <uvmfirst>
    p->sz = PGSIZE;
    80001f9e:	6785                	lui	a5,0x1
    80001fa0:	e4bc                	sd	a5,72(s1)
    p->trapframe->epc = 0;     // user program counter
    80001fa2:	6cb8                	ld	a4,88(s1)
    80001fa4:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
    p->trapframe->sp = PGSIZE; // user stack pointer
    80001fa8:	6cb8                	ld	a4,88(s1)
    80001faa:	fb1c                	sd	a5,48(a4)
    safestrcpy(p->name, "initcode", sizeof(p->name));
    80001fac:	4641                	li	a2,16
    80001fae:	00006597          	auipc	a1,0x6
    80001fb2:	25258593          	addi	a1,a1,594 # 80008200 <digits+0x1c0>
    80001fb6:	15848513          	addi	a0,s1,344
    80001fba:	fffff097          	auipc	ra,0xfffff
    80001fbe:	e5c080e7          	jalr	-420(ra) # 80000e16 <safestrcpy>
    p->cwd = namei("/");
    80001fc2:	00006517          	auipc	a0,0x6
    80001fc6:	24e50513          	addi	a0,a0,590 # 80008210 <digits+0x1d0>
    80001fca:	00002097          	auipc	ra,0x2
    80001fce:	3d8080e7          	jalr	984(ra) # 800043a2 <namei>
    80001fd2:	14a4b823          	sd	a0,336(s1)
    p->state = RUNNABLE;
    80001fd6:	478d                	li	a5,3
    80001fd8:	cc9c                	sw	a5,24(s1)
    release(&p->lock);
    80001fda:	8526                	mv	a0,s1
    80001fdc:	fffff097          	auipc	ra,0xfffff
    80001fe0:	caa080e7          	jalr	-854(ra) # 80000c86 <release>
}
    80001fe4:	60e2                	ld	ra,24(sp)
    80001fe6:	6442                	ld	s0,16(sp)
    80001fe8:	64a2                	ld	s1,8(sp)
    80001fea:	6105                	addi	sp,sp,32
    80001fec:	8082                	ret

0000000080001fee <growproc>:
{
    80001fee:	1101                	addi	sp,sp,-32
    80001ff0:	ec06                	sd	ra,24(sp)
    80001ff2:	e822                	sd	s0,16(sp)
    80001ff4:	e426                	sd	s1,8(sp)
    80001ff6:	e04a                	sd	s2,0(sp)
    80001ff8:	1000                	addi	s0,sp,32
    80001ffa:	892a                	mv	s2,a0
    struct proc *p = myproc();
    80001ffc:	00000097          	auipc	ra,0x0
    80002000:	c98080e7          	jalr	-872(ra) # 80001c94 <myproc>
    80002004:	84aa                	mv	s1,a0
    sz = p->sz;
    80002006:	652c                	ld	a1,72(a0)
    if (n > 0)
    80002008:	01204c63          	bgtz	s2,80002020 <growproc+0x32>
    else if (n < 0)
    8000200c:	02094663          	bltz	s2,80002038 <growproc+0x4a>
    p->sz = sz;
    80002010:	e4ac                	sd	a1,72(s1)
    return 0;
    80002012:	4501                	li	a0,0
}
    80002014:	60e2                	ld	ra,24(sp)
    80002016:	6442                	ld	s0,16(sp)
    80002018:	64a2                	ld	s1,8(sp)
    8000201a:	6902                	ld	s2,0(sp)
    8000201c:	6105                	addi	sp,sp,32
    8000201e:	8082                	ret
        if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80002020:	4691                	li	a3,4
    80002022:	00b90633          	add	a2,s2,a1
    80002026:	6928                	ld	a0,80(a0)
    80002028:	fffff097          	auipc	ra,0xfffff
    8000202c:	3e2080e7          	jalr	994(ra) # 8000140a <uvmalloc>
    80002030:	85aa                	mv	a1,a0
    80002032:	fd79                	bnez	a0,80002010 <growproc+0x22>
            return -1;
    80002034:	557d                	li	a0,-1
    80002036:	bff9                	j	80002014 <growproc+0x26>
        sz = uvmdealloc(p->pagetable, sz, sz + n);
    80002038:	00b90633          	add	a2,s2,a1
    8000203c:	6928                	ld	a0,80(a0)
    8000203e:	fffff097          	auipc	ra,0xfffff
    80002042:	384080e7          	jalr	900(ra) # 800013c2 <uvmdealloc>
    80002046:	85aa                	mv	a1,a0
    80002048:	b7e1                	j	80002010 <growproc+0x22>

000000008000204a <ps>:
{
    8000204a:	715d                	addi	sp,sp,-80
    8000204c:	e486                	sd	ra,72(sp)
    8000204e:	e0a2                	sd	s0,64(sp)
    80002050:	fc26                	sd	s1,56(sp)
    80002052:	f84a                	sd	s2,48(sp)
    80002054:	f44e                	sd	s3,40(sp)
    80002056:	f052                	sd	s4,32(sp)
    80002058:	ec56                	sd	s5,24(sp)
    8000205a:	e85a                	sd	s6,16(sp)
    8000205c:	e45e                	sd	s7,8(sp)
    8000205e:	e062                	sd	s8,0(sp)
    80002060:	0880                	addi	s0,sp,80
    80002062:	84aa                	mv	s1,a0
    80002064:	8bae                	mv	s7,a1
    void *result = (void *)myproc()->sz;
    80002066:	00000097          	auipc	ra,0x0
    8000206a:	c2e080e7          	jalr	-978(ra) # 80001c94 <myproc>
    if (count == 0)
    8000206e:	120b8063          	beqz	s7,8000218e <ps+0x144>
    void *result = (void *)myproc()->sz;
    80002072:	04853b03          	ld	s6,72(a0)
    if (growproc(count * sizeof(struct user_proc)) < 0)
    80002076:	003b951b          	slliw	a0,s7,0x3
    8000207a:	0175053b          	addw	a0,a0,s7
    8000207e:	0025151b          	slliw	a0,a0,0x2
    80002082:	00000097          	auipc	ra,0x0
    80002086:	f6c080e7          	jalr	-148(ra) # 80001fee <growproc>
    8000208a:	10054463          	bltz	a0,80002192 <ps+0x148>
    struct user_proc loc_result[count];
    8000208e:	003b9a13          	slli	s4,s7,0x3
    80002092:	9a5e                	add	s4,s4,s7
    80002094:	0a0a                	slli	s4,s4,0x2
    80002096:	00fa0793          	addi	a5,s4,15
    8000209a:	8391                	srli	a5,a5,0x4
    8000209c:	0792                	slli	a5,a5,0x4
    8000209e:	40f10133          	sub	sp,sp,a5
    800020a2:	8a8a                	mv	s5,sp
    struct proc *p = proc + (start * sizeof(proc));
    800020a4:	007e97b7          	lui	a5,0x7e9
    800020a8:	02f484b3          	mul	s1,s1,a5
    800020ac:	0000f797          	auipc	a5,0xf
    800020b0:	ff478793          	addi	a5,a5,-12 # 800110a0 <proc>
    800020b4:	94be                	add	s1,s1,a5
    if (p >= &proc[NPROC])
    800020b6:	00015797          	auipc	a5,0x15
    800020ba:	9ea78793          	addi	a5,a5,-1558 # 80016aa0 <tickslock>
    800020be:	0cf4fc63          	bgeu	s1,a5,80002196 <ps+0x14c>
        if (localCount == count)
    800020c2:	014a8913          	addi	s2,s5,20
    uint8 localCount = 0;
    800020c6:	4981                	li	s3,0
    for (; p < &proc[NPROC]; p++)
    800020c8:	8c3e                	mv	s8,a5
    800020ca:	a069                	j	80002154 <ps+0x10a>
            loc_result[localCount].state = UNUSED;
    800020cc:	00399793          	slli	a5,s3,0x3
    800020d0:	97ce                	add	a5,a5,s3
    800020d2:	078a                	slli	a5,a5,0x2
    800020d4:	97d6                	add	a5,a5,s5
    800020d6:	0007a023          	sw	zero,0(a5)
            release(&p->lock);
    800020da:	8526                	mv	a0,s1
    800020dc:	fffff097          	auipc	ra,0xfffff
    800020e0:	baa080e7          	jalr	-1110(ra) # 80000c86 <release>
    if (localCount < count)
    800020e4:	0179f963          	bgeu	s3,s7,800020f6 <ps+0xac>
        loc_result[localCount].state = UNUSED; // if we reach the end of processes
    800020e8:	00399793          	slli	a5,s3,0x3
    800020ec:	97ce                	add	a5,a5,s3
    800020ee:	078a                	slli	a5,a5,0x2
    800020f0:	97d6                	add	a5,a5,s5
    800020f2:	0007a023          	sw	zero,0(a5)
    void *result = (void *)myproc()->sz;
    800020f6:	84da                	mv	s1,s6
    copyout(myproc()->pagetable, (uint64)result, (void *)loc_result, count * sizeof(struct user_proc));
    800020f8:	00000097          	auipc	ra,0x0
    800020fc:	b9c080e7          	jalr	-1124(ra) # 80001c94 <myproc>
    80002100:	86d2                	mv	a3,s4
    80002102:	8656                	mv	a2,s5
    80002104:	85da                	mv	a1,s6
    80002106:	6928                	ld	a0,80(a0)
    80002108:	fffff097          	auipc	ra,0xfffff
    8000210c:	55e080e7          	jalr	1374(ra) # 80001666 <copyout>
}
    80002110:	8526                	mv	a0,s1
    80002112:	fb040113          	addi	sp,s0,-80
    80002116:	60a6                	ld	ra,72(sp)
    80002118:	6406                	ld	s0,64(sp)
    8000211a:	74e2                	ld	s1,56(sp)
    8000211c:	7942                	ld	s2,48(sp)
    8000211e:	79a2                	ld	s3,40(sp)
    80002120:	7a02                	ld	s4,32(sp)
    80002122:	6ae2                	ld	s5,24(sp)
    80002124:	6b42                	ld	s6,16(sp)
    80002126:	6ba2                	ld	s7,8(sp)
    80002128:	6c02                	ld	s8,0(sp)
    8000212a:	6161                	addi	sp,sp,80
    8000212c:	8082                	ret
            loc_result[localCount].parent_id = p->parent->pid;
    8000212e:	5b9c                	lw	a5,48(a5)
    80002130:	fef92e23          	sw	a5,-4(s2)
        release(&p->lock);
    80002134:	8526                	mv	a0,s1
    80002136:	fffff097          	auipc	ra,0xfffff
    8000213a:	b50080e7          	jalr	-1200(ra) # 80000c86 <release>
        localCount++;
    8000213e:	2985                	addiw	s3,s3,1
    80002140:	0ff9f993          	zext.b	s3,s3
    for (; p < &proc[NPROC]; p++)
    80002144:	16848493          	addi	s1,s1,360
    80002148:	f984fee3          	bgeu	s1,s8,800020e4 <ps+0x9a>
        if (localCount == count)
    8000214c:	02490913          	addi	s2,s2,36
    80002150:	fb3b83e3          	beq	s7,s3,800020f6 <ps+0xac>
        acquire(&p->lock);
    80002154:	8526                	mv	a0,s1
    80002156:	fffff097          	auipc	ra,0xfffff
    8000215a:	a7c080e7          	jalr	-1412(ra) # 80000bd2 <acquire>
        if (p->state == UNUSED)
    8000215e:	4c9c                	lw	a5,24(s1)
    80002160:	d7b5                	beqz	a5,800020cc <ps+0x82>
        loc_result[localCount].state = p->state;
    80002162:	fef92623          	sw	a5,-20(s2)
        loc_result[localCount].killed = p->killed;
    80002166:	549c                	lw	a5,40(s1)
    80002168:	fef92823          	sw	a5,-16(s2)
        loc_result[localCount].xstate = p->xstate;
    8000216c:	54dc                	lw	a5,44(s1)
    8000216e:	fef92a23          	sw	a5,-12(s2)
        loc_result[localCount].pid = p->pid;
    80002172:	589c                	lw	a5,48(s1)
    80002174:	fef92c23          	sw	a5,-8(s2)
        copy_array(p->name, loc_result[localCount].name, 16);
    80002178:	4641                	li	a2,16
    8000217a:	85ca                	mv	a1,s2
    8000217c:	15848513          	addi	a0,s1,344
    80002180:	00000097          	auipc	ra,0x0
    80002184:	ac4080e7          	jalr	-1340(ra) # 80001c44 <copy_array>
        if (p->parent != 0) // init
    80002188:	7c9c                	ld	a5,56(s1)
    8000218a:	f3d5                	bnez	a5,8000212e <ps+0xe4>
    8000218c:	b765                	j	80002134 <ps+0xea>
        return result;
    8000218e:	4481                	li	s1,0
    80002190:	b741                	j	80002110 <ps+0xc6>
        return result;
    80002192:	4481                	li	s1,0
    80002194:	bfb5                	j	80002110 <ps+0xc6>
        return result;
    80002196:	4481                	li	s1,0
    80002198:	bfa5                	j	80002110 <ps+0xc6>

000000008000219a <fork>:
{
    8000219a:	7139                	addi	sp,sp,-64
    8000219c:	fc06                	sd	ra,56(sp)
    8000219e:	f822                	sd	s0,48(sp)
    800021a0:	f426                	sd	s1,40(sp)
    800021a2:	f04a                	sd	s2,32(sp)
    800021a4:	ec4e                	sd	s3,24(sp)
    800021a6:	e852                	sd	s4,16(sp)
    800021a8:	e456                	sd	s5,8(sp)
    800021aa:	0080                	addi	s0,sp,64
    struct proc *p = myproc();
    800021ac:	00000097          	auipc	ra,0x0
    800021b0:	ae8080e7          	jalr	-1304(ra) # 80001c94 <myproc>
    800021b4:	8aaa                	mv	s5,a0
    if ((np = allocproc()) == 0)
    800021b6:	00000097          	auipc	ra,0x0
    800021ba:	ce8080e7          	jalr	-792(ra) # 80001e9e <allocproc>
    800021be:	10050c63          	beqz	a0,800022d6 <fork+0x13c>
    800021c2:	8a2a                	mv	s4,a0
    if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    800021c4:	048ab603          	ld	a2,72(s5)
    800021c8:	692c                	ld	a1,80(a0)
    800021ca:	050ab503          	ld	a0,80(s5)
    800021ce:	fffff097          	auipc	ra,0xfffff
    800021d2:	394080e7          	jalr	916(ra) # 80001562 <uvmcopy>
    800021d6:	04054863          	bltz	a0,80002226 <fork+0x8c>
    np->sz = p->sz;
    800021da:	048ab783          	ld	a5,72(s5)
    800021de:	04fa3423          	sd	a5,72(s4)
    *(np->trapframe) = *(p->trapframe);
    800021e2:	058ab683          	ld	a3,88(s5)
    800021e6:	87b6                	mv	a5,a3
    800021e8:	058a3703          	ld	a4,88(s4)
    800021ec:	12068693          	addi	a3,a3,288
    800021f0:	0007b803          	ld	a6,0(a5)
    800021f4:	6788                	ld	a0,8(a5)
    800021f6:	6b8c                	ld	a1,16(a5)
    800021f8:	6f90                	ld	a2,24(a5)
    800021fa:	01073023          	sd	a6,0(a4)
    800021fe:	e708                	sd	a0,8(a4)
    80002200:	eb0c                	sd	a1,16(a4)
    80002202:	ef10                	sd	a2,24(a4)
    80002204:	02078793          	addi	a5,a5,32
    80002208:	02070713          	addi	a4,a4,32
    8000220c:	fed792e3          	bne	a5,a3,800021f0 <fork+0x56>
    np->trapframe->a0 = 0;
    80002210:	058a3783          	ld	a5,88(s4)
    80002214:	0607b823          	sd	zero,112(a5)
    for (i = 0; i < NOFILE; i++)
    80002218:	0d0a8493          	addi	s1,s5,208
    8000221c:	0d0a0913          	addi	s2,s4,208
    80002220:	150a8993          	addi	s3,s5,336
    80002224:	a00d                	j	80002246 <fork+0xac>
        freeproc(np);
    80002226:	8552                	mv	a0,s4
    80002228:	00000097          	auipc	ra,0x0
    8000222c:	c1e080e7          	jalr	-994(ra) # 80001e46 <freeproc>
        release(&np->lock);
    80002230:	8552                	mv	a0,s4
    80002232:	fffff097          	auipc	ra,0xfffff
    80002236:	a54080e7          	jalr	-1452(ra) # 80000c86 <release>
        return -1;
    8000223a:	597d                	li	s2,-1
    8000223c:	a059                	j	800022c2 <fork+0x128>
    for (i = 0; i < NOFILE; i++)
    8000223e:	04a1                	addi	s1,s1,8
    80002240:	0921                	addi	s2,s2,8
    80002242:	01348b63          	beq	s1,s3,80002258 <fork+0xbe>
        if (p->ofile[i])
    80002246:	6088                	ld	a0,0(s1)
    80002248:	d97d                	beqz	a0,8000223e <fork+0xa4>
            np->ofile[i] = filedup(p->ofile[i]);
    8000224a:	00002097          	auipc	ra,0x2
    8000224e:	7ca080e7          	jalr	1994(ra) # 80004a14 <filedup>
    80002252:	00a93023          	sd	a0,0(s2)
    80002256:	b7e5                	j	8000223e <fork+0xa4>
    np->cwd = idup(p->cwd);
    80002258:	150ab503          	ld	a0,336(s5)
    8000225c:	00002097          	auipc	ra,0x2
    80002260:	962080e7          	jalr	-1694(ra) # 80003bbe <idup>
    80002264:	14aa3823          	sd	a0,336(s4)
    safestrcpy(np->name, p->name, sizeof(p->name));
    80002268:	4641                	li	a2,16
    8000226a:	158a8593          	addi	a1,s5,344
    8000226e:	158a0513          	addi	a0,s4,344
    80002272:	fffff097          	auipc	ra,0xfffff
    80002276:	ba4080e7          	jalr	-1116(ra) # 80000e16 <safestrcpy>
    pid = np->pid;
    8000227a:	030a2903          	lw	s2,48(s4)
    release(&np->lock);
    8000227e:	8552                	mv	a0,s4
    80002280:	fffff097          	auipc	ra,0xfffff
    80002284:	a06080e7          	jalr	-1530(ra) # 80000c86 <release>
    acquire(&wait_lock);
    80002288:	0000f497          	auipc	s1,0xf
    8000228c:	e0048493          	addi	s1,s1,-512 # 80011088 <wait_lock>
    80002290:	8526                	mv	a0,s1
    80002292:	fffff097          	auipc	ra,0xfffff
    80002296:	940080e7          	jalr	-1728(ra) # 80000bd2 <acquire>
    np->parent = p;
    8000229a:	035a3c23          	sd	s5,56(s4)
    release(&wait_lock);
    8000229e:	8526                	mv	a0,s1
    800022a0:	fffff097          	auipc	ra,0xfffff
    800022a4:	9e6080e7          	jalr	-1562(ra) # 80000c86 <release>
    acquire(&np->lock);
    800022a8:	8552                	mv	a0,s4
    800022aa:	fffff097          	auipc	ra,0xfffff
    800022ae:	928080e7          	jalr	-1752(ra) # 80000bd2 <acquire>
    np->state = RUNNABLE;
    800022b2:	478d                	li	a5,3
    800022b4:	00fa2c23          	sw	a5,24(s4)
    release(&np->lock);
    800022b8:	8552                	mv	a0,s4
    800022ba:	fffff097          	auipc	ra,0xfffff
    800022be:	9cc080e7          	jalr	-1588(ra) # 80000c86 <release>
}
    800022c2:	854a                	mv	a0,s2
    800022c4:	70e2                	ld	ra,56(sp)
    800022c6:	7442                	ld	s0,48(sp)
    800022c8:	74a2                	ld	s1,40(sp)
    800022ca:	7902                	ld	s2,32(sp)
    800022cc:	69e2                	ld	s3,24(sp)
    800022ce:	6a42                	ld	s4,16(sp)
    800022d0:	6aa2                	ld	s5,8(sp)
    800022d2:	6121                	addi	sp,sp,64
    800022d4:	8082                	ret
        return -1;
    800022d6:	597d                	li	s2,-1
    800022d8:	b7ed                	j	800022c2 <fork+0x128>

00000000800022da <scheduler>:
{
    800022da:	7179                	addi	sp,sp,-48
    800022dc:	f406                	sd	ra,40(sp)
    800022de:	f022                	sd	s0,32(sp)
    800022e0:	ec26                	sd	s1,24(sp)
    800022e2:	e84a                	sd	s2,16(sp)
    800022e4:	e44e                	sd	s3,8(sp)
    800022e6:	e052                	sd	s4,0(sp)
    800022e8:	1800                	addi	s0,sp,48
    for (struct proc *p = proc; p < &proc[NPROC]; p++) {
    800022ea:	0000f497          	auipc	s1,0xf
    800022ee:	db648493          	addi	s1,s1,-586 # 800110a0 <proc>
        if (p->queue != -1) {
    800022f2:	59fd                	li	s3,-1
        if (p->state == RUNNABLE) { // If the process is runnable
    800022f4:	4a0d                	li	s4,3
    for (struct proc *p = proc; p < &proc[NPROC]; p++) {
    800022f6:	00014917          	auipc	s2,0x14
    800022fa:	7aa90913          	addi	s2,s2,1962 # 80016aa0 <tickslock>
    800022fe:	a005                	j	8000231e <scheduler+0x44>
            release(&p->lock);
    80002300:	8526                	mv	a0,s1
    80002302:	fffff097          	auipc	ra,0xfffff
    80002306:	984080e7          	jalr	-1660(ra) # 80000c86 <release>
            continue;
    8000230a:	a031                	j	80002316 <scheduler+0x3c>
        release(&p->lock); // Release the lock for the process
    8000230c:	8526                	mv	a0,s1
    8000230e:	fffff097          	auipc	ra,0xfffff
    80002312:	978080e7          	jalr	-1672(ra) # 80000c86 <release>
    for (struct proc *p = proc; p < &proc[NPROC]; p++) {
    80002316:	16848493          	addi	s1,s1,360
    8000231a:	03248063          	beq	s1,s2,8000233a <scheduler+0x60>
        acquire(&p->lock); // Acquire the lock for the process
    8000231e:	8526                	mv	a0,s1
    80002320:	fffff097          	auipc	ra,0xfffff
    80002324:	8b2080e7          	jalr	-1870(ra) # 80000bd2 <acquire>
        if (p->queue != -1) {
    80002328:	58dc                	lw	a5,52(s1)
    8000232a:	fd379be3          	bne	a5,s3,80002300 <scheduler+0x26>
        if (p->state == RUNNABLE) { // If the process is runnable
    8000232e:	4c9c                	lw	a5,24(s1)
    80002330:	fd479ee3          	bne	a5,s4,8000230c <scheduler+0x32>
            p->queue = 0; // Set the queue of the process to the topmost queue
    80002334:	0204aa23          	sw	zero,52(s1)
    80002338:	bfd1                	j	8000230c <scheduler+0x32>
        (*sched_pointer)();
    8000233a:	00006497          	auipc	s1,0x6
    8000233e:	5fe48493          	addi	s1,s1,1534 # 80008938 <sched_pointer>
    80002342:	609c                	ld	a5,0(s1)
    80002344:	9782                	jalr	a5
    while (1)
    80002346:	bff5                	j	80002342 <scheduler+0x68>

0000000080002348 <sched>:
{
    80002348:	7179                	addi	sp,sp,-48
    8000234a:	f406                	sd	ra,40(sp)
    8000234c:	f022                	sd	s0,32(sp)
    8000234e:	ec26                	sd	s1,24(sp)
    80002350:	e84a                	sd	s2,16(sp)
    80002352:	e44e                	sd	s3,8(sp)
    80002354:	1800                	addi	s0,sp,48
    struct proc *p = myproc();
    80002356:	00000097          	auipc	ra,0x0
    8000235a:	93e080e7          	jalr	-1730(ra) # 80001c94 <myproc>
    8000235e:	84aa                	mv	s1,a0
    if (!holding(&p->lock))
    80002360:	ffffe097          	auipc	ra,0xffffe
    80002364:	7f8080e7          	jalr	2040(ra) # 80000b58 <holding>
    80002368:	c53d                	beqz	a0,800023d6 <sched+0x8e>
    8000236a:	8792                	mv	a5,tp
    if (mycpu()->noff != 1)
    8000236c:	2781                	sext.w	a5,a5
    8000236e:	079e                	slli	a5,a5,0x7
    80002370:	0000f717          	auipc	a4,0xf
    80002374:	90070713          	addi	a4,a4,-1792 # 80010c70 <cpus>
    80002378:	97ba                	add	a5,a5,a4
    8000237a:	5fb8                	lw	a4,120(a5)
    8000237c:	4785                	li	a5,1
    8000237e:	06f71463          	bne	a4,a5,800023e6 <sched+0x9e>
    if (p->state == RUNNING)
    80002382:	4c98                	lw	a4,24(s1)
    80002384:	4791                	li	a5,4
    80002386:	06f70863          	beq	a4,a5,800023f6 <sched+0xae>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000238a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000238e:	8b89                	andi	a5,a5,2
    if (intr_get())
    80002390:	ebbd                	bnez	a5,80002406 <sched+0xbe>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002392:	8792                	mv	a5,tp
    intena = mycpu()->intena;
    80002394:	0000f917          	auipc	s2,0xf
    80002398:	8dc90913          	addi	s2,s2,-1828 # 80010c70 <cpus>
    8000239c:	2781                	sext.w	a5,a5
    8000239e:	079e                	slli	a5,a5,0x7
    800023a0:	97ca                	add	a5,a5,s2
    800023a2:	07c7a983          	lw	s3,124(a5)
    800023a6:	8592                	mv	a1,tp
    swtch(&p->context, &mycpu()->context);
    800023a8:	2581                	sext.w	a1,a1
    800023aa:	059e                	slli	a1,a1,0x7
    800023ac:	05a1                	addi	a1,a1,8
    800023ae:	95ca                	add	a1,a1,s2
    800023b0:	06048513          	addi	a0,s1,96
    800023b4:	00000097          	auipc	ra,0x0
    800023b8:	748080e7          	jalr	1864(ra) # 80002afc <swtch>
    800023bc:	8792                	mv	a5,tp
    mycpu()->intena = intena;
    800023be:	2781                	sext.w	a5,a5
    800023c0:	079e                	slli	a5,a5,0x7
    800023c2:	993e                	add	s2,s2,a5
    800023c4:	07392e23          	sw	s3,124(s2)
}
    800023c8:	70a2                	ld	ra,40(sp)
    800023ca:	7402                	ld	s0,32(sp)
    800023cc:	64e2                	ld	s1,24(sp)
    800023ce:	6942                	ld	s2,16(sp)
    800023d0:	69a2                	ld	s3,8(sp)
    800023d2:	6145                	addi	sp,sp,48
    800023d4:	8082                	ret
        panic("sched p->lock");
    800023d6:	00006517          	auipc	a0,0x6
    800023da:	e4250513          	addi	a0,a0,-446 # 80008218 <digits+0x1d8>
    800023de:	ffffe097          	auipc	ra,0xffffe
    800023e2:	15e080e7          	jalr	350(ra) # 8000053c <panic>
        panic("sched locks");
    800023e6:	00006517          	auipc	a0,0x6
    800023ea:	e4250513          	addi	a0,a0,-446 # 80008228 <digits+0x1e8>
    800023ee:	ffffe097          	auipc	ra,0xffffe
    800023f2:	14e080e7          	jalr	334(ra) # 8000053c <panic>
        panic("sched running");
    800023f6:	00006517          	auipc	a0,0x6
    800023fa:	e4250513          	addi	a0,a0,-446 # 80008238 <digits+0x1f8>
    800023fe:	ffffe097          	auipc	ra,0xffffe
    80002402:	13e080e7          	jalr	318(ra) # 8000053c <panic>
        panic("sched interruptible");
    80002406:	00006517          	auipc	a0,0x6
    8000240a:	e4250513          	addi	a0,a0,-446 # 80008248 <digits+0x208>
    8000240e:	ffffe097          	auipc	ra,0xffffe
    80002412:	12e080e7          	jalr	302(ra) # 8000053c <panic>

0000000080002416 <yield>:
{
    80002416:	1101                	addi	sp,sp,-32
    80002418:	ec06                	sd	ra,24(sp)
    8000241a:	e822                	sd	s0,16(sp)
    8000241c:	e426                	sd	s1,8(sp)
    8000241e:	1000                	addi	s0,sp,32
    struct proc *p = myproc();
    80002420:	00000097          	auipc	ra,0x0
    80002424:	874080e7          	jalr	-1932(ra) # 80001c94 <myproc>
    80002428:	84aa                	mv	s1,a0
    acquire(&p->lock);
    8000242a:	ffffe097          	auipc	ra,0xffffe
    8000242e:	7a8080e7          	jalr	1960(ra) # 80000bd2 <acquire>
    p->state = RUNNABLE;
    80002432:	478d                	li	a5,3
    80002434:	cc9c                	sw	a5,24(s1)
    sched();
    80002436:	00000097          	auipc	ra,0x0
    8000243a:	f12080e7          	jalr	-238(ra) # 80002348 <sched>
    release(&p->lock);
    8000243e:	8526                	mv	a0,s1
    80002440:	fffff097          	auipc	ra,0xfffff
    80002444:	846080e7          	jalr	-1978(ra) # 80000c86 <release>
}
    80002448:	60e2                	ld	ra,24(sp)
    8000244a:	6442                	ld	s0,16(sp)
    8000244c:	64a2                	ld	s1,8(sp)
    8000244e:	6105                	addi	sp,sp,32
    80002450:	8082                	ret

0000000080002452 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    80002452:	7179                	addi	sp,sp,-48
    80002454:	f406                	sd	ra,40(sp)
    80002456:	f022                	sd	s0,32(sp)
    80002458:	ec26                	sd	s1,24(sp)
    8000245a:	e84a                	sd	s2,16(sp)
    8000245c:	e44e                	sd	s3,8(sp)
    8000245e:	1800                	addi	s0,sp,48
    80002460:	89aa                	mv	s3,a0
    80002462:	892e                	mv	s2,a1
    struct proc *p = myproc();
    80002464:	00000097          	auipc	ra,0x0
    80002468:	830080e7          	jalr	-2000(ra) # 80001c94 <myproc>
    8000246c:	84aa                	mv	s1,a0
    // Once we hold p->lock, we can be
    // guaranteed that we won't miss any wakeup
    // (wakeup locks p->lock),
    // so it's okay to release lk.

    acquire(&p->lock); // DOC: sleeplock1
    8000246e:	ffffe097          	auipc	ra,0xffffe
    80002472:	764080e7          	jalr	1892(ra) # 80000bd2 <acquire>
    release(lk);
    80002476:	854a                	mv	a0,s2
    80002478:	fffff097          	auipc	ra,0xfffff
    8000247c:	80e080e7          	jalr	-2034(ra) # 80000c86 <release>

    // Go to sleep.
    p->chan = chan;
    80002480:	0334b023          	sd	s3,32(s1)
    p->state = SLEEPING;
    80002484:	4789                	li	a5,2
    80002486:	cc9c                	sw	a5,24(s1)

    sched();
    80002488:	00000097          	auipc	ra,0x0
    8000248c:	ec0080e7          	jalr	-320(ra) # 80002348 <sched>

    // Tidy up.
    p->chan = 0;
    80002490:	0204b023          	sd	zero,32(s1)

    // Reacquire original lock.
    release(&p->lock);
    80002494:	8526                	mv	a0,s1
    80002496:	ffffe097          	auipc	ra,0xffffe
    8000249a:	7f0080e7          	jalr	2032(ra) # 80000c86 <release>
    acquire(lk);
    8000249e:	854a                	mv	a0,s2
    800024a0:	ffffe097          	auipc	ra,0xffffe
    800024a4:	732080e7          	jalr	1842(ra) # 80000bd2 <acquire>
}
    800024a8:	70a2                	ld	ra,40(sp)
    800024aa:	7402                	ld	s0,32(sp)
    800024ac:	64e2                	ld	s1,24(sp)
    800024ae:	6942                	ld	s2,16(sp)
    800024b0:	69a2                	ld	s3,8(sp)
    800024b2:	6145                	addi	sp,sp,48
    800024b4:	8082                	ret

00000000800024b6 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    800024b6:	7139                	addi	sp,sp,-64
    800024b8:	fc06                	sd	ra,56(sp)
    800024ba:	f822                	sd	s0,48(sp)
    800024bc:	f426                	sd	s1,40(sp)
    800024be:	f04a                	sd	s2,32(sp)
    800024c0:	ec4e                	sd	s3,24(sp)
    800024c2:	e852                	sd	s4,16(sp)
    800024c4:	e456                	sd	s5,8(sp)
    800024c6:	0080                	addi	s0,sp,64
    800024c8:	8a2a                	mv	s4,a0
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++)
    800024ca:	0000f497          	auipc	s1,0xf
    800024ce:	bd648493          	addi	s1,s1,-1066 # 800110a0 <proc>
    {
        if (p != myproc())
        {
            acquire(&p->lock);
            if (p->state == SLEEPING && p->chan == chan)
    800024d2:	4989                	li	s3,2
            {
                p->state = RUNNABLE;
    800024d4:	4a8d                	li	s5,3
    for (p = proc; p < &proc[NPROC]; p++)
    800024d6:	00014917          	auipc	s2,0x14
    800024da:	5ca90913          	addi	s2,s2,1482 # 80016aa0 <tickslock>
    800024de:	a811                	j	800024f2 <wakeup+0x3c>
            }
            release(&p->lock);
    800024e0:	8526                	mv	a0,s1
    800024e2:	ffffe097          	auipc	ra,0xffffe
    800024e6:	7a4080e7          	jalr	1956(ra) # 80000c86 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    800024ea:	16848493          	addi	s1,s1,360
    800024ee:	03248663          	beq	s1,s2,8000251a <wakeup+0x64>
        if (p != myproc())
    800024f2:	fffff097          	auipc	ra,0xfffff
    800024f6:	7a2080e7          	jalr	1954(ra) # 80001c94 <myproc>
    800024fa:	fea488e3          	beq	s1,a0,800024ea <wakeup+0x34>
            acquire(&p->lock);
    800024fe:	8526                	mv	a0,s1
    80002500:	ffffe097          	auipc	ra,0xffffe
    80002504:	6d2080e7          	jalr	1746(ra) # 80000bd2 <acquire>
            if (p->state == SLEEPING && p->chan == chan)
    80002508:	4c9c                	lw	a5,24(s1)
    8000250a:	fd379be3          	bne	a5,s3,800024e0 <wakeup+0x2a>
    8000250e:	709c                	ld	a5,32(s1)
    80002510:	fd4798e3          	bne	a5,s4,800024e0 <wakeup+0x2a>
                p->state = RUNNABLE;
    80002514:	0154ac23          	sw	s5,24(s1)
    80002518:	b7e1                	j	800024e0 <wakeup+0x2a>
        }
    }
}
    8000251a:	70e2                	ld	ra,56(sp)
    8000251c:	7442                	ld	s0,48(sp)
    8000251e:	74a2                	ld	s1,40(sp)
    80002520:	7902                	ld	s2,32(sp)
    80002522:	69e2                	ld	s3,24(sp)
    80002524:	6a42                	ld	s4,16(sp)
    80002526:	6aa2                	ld	s5,8(sp)
    80002528:	6121                	addi	sp,sp,64
    8000252a:	8082                	ret

000000008000252c <reparent>:
{
    8000252c:	7179                	addi	sp,sp,-48
    8000252e:	f406                	sd	ra,40(sp)
    80002530:	f022                	sd	s0,32(sp)
    80002532:	ec26                	sd	s1,24(sp)
    80002534:	e84a                	sd	s2,16(sp)
    80002536:	e44e                	sd	s3,8(sp)
    80002538:	e052                	sd	s4,0(sp)
    8000253a:	1800                	addi	s0,sp,48
    8000253c:	892a                	mv	s2,a0
    for (pp = proc; pp < &proc[NPROC]; pp++)
    8000253e:	0000f497          	auipc	s1,0xf
    80002542:	b6248493          	addi	s1,s1,-1182 # 800110a0 <proc>
            pp->parent = initproc;
    80002546:	00006a17          	auipc	s4,0x6
    8000254a:	4baa0a13          	addi	s4,s4,1210 # 80008a00 <initproc>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    8000254e:	00014997          	auipc	s3,0x14
    80002552:	55298993          	addi	s3,s3,1362 # 80016aa0 <tickslock>
    80002556:	a029                	j	80002560 <reparent+0x34>
    80002558:	16848493          	addi	s1,s1,360
    8000255c:	01348d63          	beq	s1,s3,80002576 <reparent+0x4a>
        if (pp->parent == p)
    80002560:	7c9c                	ld	a5,56(s1)
    80002562:	ff279be3          	bne	a5,s2,80002558 <reparent+0x2c>
            pp->parent = initproc;
    80002566:	000a3503          	ld	a0,0(s4)
    8000256a:	fc88                	sd	a0,56(s1)
            wakeup(initproc);
    8000256c:	00000097          	auipc	ra,0x0
    80002570:	f4a080e7          	jalr	-182(ra) # 800024b6 <wakeup>
    80002574:	b7d5                	j	80002558 <reparent+0x2c>
}
    80002576:	70a2                	ld	ra,40(sp)
    80002578:	7402                	ld	s0,32(sp)
    8000257a:	64e2                	ld	s1,24(sp)
    8000257c:	6942                	ld	s2,16(sp)
    8000257e:	69a2                	ld	s3,8(sp)
    80002580:	6a02                	ld	s4,0(sp)
    80002582:	6145                	addi	sp,sp,48
    80002584:	8082                	ret

0000000080002586 <exit>:
{
    80002586:	7179                	addi	sp,sp,-48
    80002588:	f406                	sd	ra,40(sp)
    8000258a:	f022                	sd	s0,32(sp)
    8000258c:	ec26                	sd	s1,24(sp)
    8000258e:	e84a                	sd	s2,16(sp)
    80002590:	e44e                	sd	s3,8(sp)
    80002592:	e052                	sd	s4,0(sp)
    80002594:	1800                	addi	s0,sp,48
    80002596:	8a2a                	mv	s4,a0
    struct proc *p = myproc();
    80002598:	fffff097          	auipc	ra,0xfffff
    8000259c:	6fc080e7          	jalr	1788(ra) # 80001c94 <myproc>
    800025a0:	89aa                	mv	s3,a0
    if (p == initproc)
    800025a2:	00006797          	auipc	a5,0x6
    800025a6:	45e7b783          	ld	a5,1118(a5) # 80008a00 <initproc>
    800025aa:	0d050493          	addi	s1,a0,208
    800025ae:	15050913          	addi	s2,a0,336
    800025b2:	02a79363          	bne	a5,a0,800025d8 <exit+0x52>
        panic("init exiting");
    800025b6:	00006517          	auipc	a0,0x6
    800025ba:	caa50513          	addi	a0,a0,-854 # 80008260 <digits+0x220>
    800025be:	ffffe097          	auipc	ra,0xffffe
    800025c2:	f7e080e7          	jalr	-130(ra) # 8000053c <panic>
            fileclose(f);
    800025c6:	00002097          	auipc	ra,0x2
    800025ca:	4a0080e7          	jalr	1184(ra) # 80004a66 <fileclose>
            p->ofile[fd] = 0;
    800025ce:	0004b023          	sd	zero,0(s1)
    for (int fd = 0; fd < NOFILE; fd++)
    800025d2:	04a1                	addi	s1,s1,8
    800025d4:	01248563          	beq	s1,s2,800025de <exit+0x58>
        if (p->ofile[fd])
    800025d8:	6088                	ld	a0,0(s1)
    800025da:	f575                	bnez	a0,800025c6 <exit+0x40>
    800025dc:	bfdd                	j	800025d2 <exit+0x4c>
    begin_op();
    800025de:	00002097          	auipc	ra,0x2
    800025e2:	fc4080e7          	jalr	-60(ra) # 800045a2 <begin_op>
    iput(p->cwd);
    800025e6:	1509b503          	ld	a0,336(s3)
    800025ea:	00001097          	auipc	ra,0x1
    800025ee:	7cc080e7          	jalr	1996(ra) # 80003db6 <iput>
    end_op();
    800025f2:	00002097          	auipc	ra,0x2
    800025f6:	02a080e7          	jalr	42(ra) # 8000461c <end_op>
    p->cwd = 0;
    800025fa:	1409b823          	sd	zero,336(s3)
    acquire(&wait_lock);
    800025fe:	0000f497          	auipc	s1,0xf
    80002602:	a8a48493          	addi	s1,s1,-1398 # 80011088 <wait_lock>
    80002606:	8526                	mv	a0,s1
    80002608:	ffffe097          	auipc	ra,0xffffe
    8000260c:	5ca080e7          	jalr	1482(ra) # 80000bd2 <acquire>
    reparent(p);
    80002610:	854e                	mv	a0,s3
    80002612:	00000097          	auipc	ra,0x0
    80002616:	f1a080e7          	jalr	-230(ra) # 8000252c <reparent>
    wakeup(p->parent);
    8000261a:	0389b503          	ld	a0,56(s3)
    8000261e:	00000097          	auipc	ra,0x0
    80002622:	e98080e7          	jalr	-360(ra) # 800024b6 <wakeup>
    acquire(&p->lock);
    80002626:	854e                	mv	a0,s3
    80002628:	ffffe097          	auipc	ra,0xffffe
    8000262c:	5aa080e7          	jalr	1450(ra) # 80000bd2 <acquire>
    p->xstate = status;
    80002630:	0349a623          	sw	s4,44(s3)
    p->state = ZOMBIE;
    80002634:	4795                	li	a5,5
    80002636:	00f9ac23          	sw	a5,24(s3)
    release(&wait_lock);
    8000263a:	8526                	mv	a0,s1
    8000263c:	ffffe097          	auipc	ra,0xffffe
    80002640:	64a080e7          	jalr	1610(ra) # 80000c86 <release>
    sched();
    80002644:	00000097          	auipc	ra,0x0
    80002648:	d04080e7          	jalr	-764(ra) # 80002348 <sched>
    panic("zombie exit");
    8000264c:	00006517          	auipc	a0,0x6
    80002650:	c2450513          	addi	a0,a0,-988 # 80008270 <digits+0x230>
    80002654:	ffffe097          	auipc	ra,0xffffe
    80002658:	ee8080e7          	jalr	-280(ra) # 8000053c <panic>

000000008000265c <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    8000265c:	7179                	addi	sp,sp,-48
    8000265e:	f406                	sd	ra,40(sp)
    80002660:	f022                	sd	s0,32(sp)
    80002662:	ec26                	sd	s1,24(sp)
    80002664:	e84a                	sd	s2,16(sp)
    80002666:	e44e                	sd	s3,8(sp)
    80002668:	1800                	addi	s0,sp,48
    8000266a:	892a                	mv	s2,a0
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++)
    8000266c:	0000f497          	auipc	s1,0xf
    80002670:	a3448493          	addi	s1,s1,-1484 # 800110a0 <proc>
    80002674:	00014997          	auipc	s3,0x14
    80002678:	42c98993          	addi	s3,s3,1068 # 80016aa0 <tickslock>
    {
        acquire(&p->lock);
    8000267c:	8526                	mv	a0,s1
    8000267e:	ffffe097          	auipc	ra,0xffffe
    80002682:	554080e7          	jalr	1364(ra) # 80000bd2 <acquire>
        if (p->pid == pid)
    80002686:	589c                	lw	a5,48(s1)
    80002688:	01278d63          	beq	a5,s2,800026a2 <kill+0x46>
                p->state = RUNNABLE;
            }
            release(&p->lock);
            return 0;
        }
        release(&p->lock);
    8000268c:	8526                	mv	a0,s1
    8000268e:	ffffe097          	auipc	ra,0xffffe
    80002692:	5f8080e7          	jalr	1528(ra) # 80000c86 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80002696:	16848493          	addi	s1,s1,360
    8000269a:	ff3491e3          	bne	s1,s3,8000267c <kill+0x20>
    }
    return -1;
    8000269e:	557d                	li	a0,-1
    800026a0:	a829                	j	800026ba <kill+0x5e>
            p->killed = 1;
    800026a2:	4785                	li	a5,1
    800026a4:	d49c                	sw	a5,40(s1)
            if (p->state == SLEEPING)
    800026a6:	4c98                	lw	a4,24(s1)
    800026a8:	4789                	li	a5,2
    800026aa:	00f70f63          	beq	a4,a5,800026c8 <kill+0x6c>
            release(&p->lock);
    800026ae:	8526                	mv	a0,s1
    800026b0:	ffffe097          	auipc	ra,0xffffe
    800026b4:	5d6080e7          	jalr	1494(ra) # 80000c86 <release>
            return 0;
    800026b8:	4501                	li	a0,0
}
    800026ba:	70a2                	ld	ra,40(sp)
    800026bc:	7402                	ld	s0,32(sp)
    800026be:	64e2                	ld	s1,24(sp)
    800026c0:	6942                	ld	s2,16(sp)
    800026c2:	69a2                	ld	s3,8(sp)
    800026c4:	6145                	addi	sp,sp,48
    800026c6:	8082                	ret
                p->state = RUNNABLE;
    800026c8:	478d                	li	a5,3
    800026ca:	cc9c                	sw	a5,24(s1)
    800026cc:	b7cd                	j	800026ae <kill+0x52>

00000000800026ce <setkilled>:

void setkilled(struct proc *p)
{
    800026ce:	1101                	addi	sp,sp,-32
    800026d0:	ec06                	sd	ra,24(sp)
    800026d2:	e822                	sd	s0,16(sp)
    800026d4:	e426                	sd	s1,8(sp)
    800026d6:	1000                	addi	s0,sp,32
    800026d8:	84aa                	mv	s1,a0
    acquire(&p->lock);
    800026da:	ffffe097          	auipc	ra,0xffffe
    800026de:	4f8080e7          	jalr	1272(ra) # 80000bd2 <acquire>
    p->killed = 1;
    800026e2:	4785                	li	a5,1
    800026e4:	d49c                	sw	a5,40(s1)
    release(&p->lock);
    800026e6:	8526                	mv	a0,s1
    800026e8:	ffffe097          	auipc	ra,0xffffe
    800026ec:	59e080e7          	jalr	1438(ra) # 80000c86 <release>
}
    800026f0:	60e2                	ld	ra,24(sp)
    800026f2:	6442                	ld	s0,16(sp)
    800026f4:	64a2                	ld	s1,8(sp)
    800026f6:	6105                	addi	sp,sp,32
    800026f8:	8082                	ret

00000000800026fa <killed>:

int killed(struct proc *p)
{
    800026fa:	1101                	addi	sp,sp,-32
    800026fc:	ec06                	sd	ra,24(sp)
    800026fe:	e822                	sd	s0,16(sp)
    80002700:	e426                	sd	s1,8(sp)
    80002702:	e04a                	sd	s2,0(sp)
    80002704:	1000                	addi	s0,sp,32
    80002706:	84aa                	mv	s1,a0
    int k;

    acquire(&p->lock);
    80002708:	ffffe097          	auipc	ra,0xffffe
    8000270c:	4ca080e7          	jalr	1226(ra) # 80000bd2 <acquire>
    k = p->killed;
    80002710:	0284a903          	lw	s2,40(s1)
    release(&p->lock);
    80002714:	8526                	mv	a0,s1
    80002716:	ffffe097          	auipc	ra,0xffffe
    8000271a:	570080e7          	jalr	1392(ra) # 80000c86 <release>
    return k;
}
    8000271e:	854a                	mv	a0,s2
    80002720:	60e2                	ld	ra,24(sp)
    80002722:	6442                	ld	s0,16(sp)
    80002724:	64a2                	ld	s1,8(sp)
    80002726:	6902                	ld	s2,0(sp)
    80002728:	6105                	addi	sp,sp,32
    8000272a:	8082                	ret

000000008000272c <wait>:
{
    8000272c:	715d                	addi	sp,sp,-80
    8000272e:	e486                	sd	ra,72(sp)
    80002730:	e0a2                	sd	s0,64(sp)
    80002732:	fc26                	sd	s1,56(sp)
    80002734:	f84a                	sd	s2,48(sp)
    80002736:	f44e                	sd	s3,40(sp)
    80002738:	f052                	sd	s4,32(sp)
    8000273a:	ec56                	sd	s5,24(sp)
    8000273c:	e85a                	sd	s6,16(sp)
    8000273e:	e45e                	sd	s7,8(sp)
    80002740:	e062                	sd	s8,0(sp)
    80002742:	0880                	addi	s0,sp,80
    80002744:	8b2a                	mv	s6,a0
    struct proc *p = myproc();
    80002746:	fffff097          	auipc	ra,0xfffff
    8000274a:	54e080e7          	jalr	1358(ra) # 80001c94 <myproc>
    8000274e:	892a                	mv	s2,a0
    acquire(&wait_lock);
    80002750:	0000f517          	auipc	a0,0xf
    80002754:	93850513          	addi	a0,a0,-1736 # 80011088 <wait_lock>
    80002758:	ffffe097          	auipc	ra,0xffffe
    8000275c:	47a080e7          	jalr	1146(ra) # 80000bd2 <acquire>
        havekids = 0;
    80002760:	4b81                	li	s7,0
                if (pp->state == ZOMBIE)
    80002762:	4a15                	li	s4,5
                havekids = 1;
    80002764:	4a85                	li	s5,1
        for (pp = proc; pp < &proc[NPROC]; pp++)
    80002766:	00014997          	auipc	s3,0x14
    8000276a:	33a98993          	addi	s3,s3,826 # 80016aa0 <tickslock>
        sleep(p, &wait_lock); // DOC: wait-sleep
    8000276e:	0000fc17          	auipc	s8,0xf
    80002772:	91ac0c13          	addi	s8,s8,-1766 # 80011088 <wait_lock>
    80002776:	a0d1                	j	8000283a <wait+0x10e>
                    pid = pp->pid;
    80002778:	0304a983          	lw	s3,48(s1)
                    if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    8000277c:	000b0e63          	beqz	s6,80002798 <wait+0x6c>
    80002780:	4691                	li	a3,4
    80002782:	02c48613          	addi	a2,s1,44
    80002786:	85da                	mv	a1,s6
    80002788:	05093503          	ld	a0,80(s2)
    8000278c:	fffff097          	auipc	ra,0xfffff
    80002790:	eda080e7          	jalr	-294(ra) # 80001666 <copyout>
    80002794:	04054163          	bltz	a0,800027d6 <wait+0xaa>
                    freeproc(pp);
    80002798:	8526                	mv	a0,s1
    8000279a:	fffff097          	auipc	ra,0xfffff
    8000279e:	6ac080e7          	jalr	1708(ra) # 80001e46 <freeproc>
                    release(&pp->lock);
    800027a2:	8526                	mv	a0,s1
    800027a4:	ffffe097          	auipc	ra,0xffffe
    800027a8:	4e2080e7          	jalr	1250(ra) # 80000c86 <release>
                    release(&wait_lock);
    800027ac:	0000f517          	auipc	a0,0xf
    800027b0:	8dc50513          	addi	a0,a0,-1828 # 80011088 <wait_lock>
    800027b4:	ffffe097          	auipc	ra,0xffffe
    800027b8:	4d2080e7          	jalr	1234(ra) # 80000c86 <release>
}
    800027bc:	854e                	mv	a0,s3
    800027be:	60a6                	ld	ra,72(sp)
    800027c0:	6406                	ld	s0,64(sp)
    800027c2:	74e2                	ld	s1,56(sp)
    800027c4:	7942                	ld	s2,48(sp)
    800027c6:	79a2                	ld	s3,40(sp)
    800027c8:	7a02                	ld	s4,32(sp)
    800027ca:	6ae2                	ld	s5,24(sp)
    800027cc:	6b42                	ld	s6,16(sp)
    800027ce:	6ba2                	ld	s7,8(sp)
    800027d0:	6c02                	ld	s8,0(sp)
    800027d2:	6161                	addi	sp,sp,80
    800027d4:	8082                	ret
                        release(&pp->lock);
    800027d6:	8526                	mv	a0,s1
    800027d8:	ffffe097          	auipc	ra,0xffffe
    800027dc:	4ae080e7          	jalr	1198(ra) # 80000c86 <release>
                        release(&wait_lock);
    800027e0:	0000f517          	auipc	a0,0xf
    800027e4:	8a850513          	addi	a0,a0,-1880 # 80011088 <wait_lock>
    800027e8:	ffffe097          	auipc	ra,0xffffe
    800027ec:	49e080e7          	jalr	1182(ra) # 80000c86 <release>
                        return -1;
    800027f0:	59fd                	li	s3,-1
    800027f2:	b7e9                	j	800027bc <wait+0x90>
        for (pp = proc; pp < &proc[NPROC]; pp++)
    800027f4:	16848493          	addi	s1,s1,360
    800027f8:	03348463          	beq	s1,s3,80002820 <wait+0xf4>
            if (pp->parent == p)
    800027fc:	7c9c                	ld	a5,56(s1)
    800027fe:	ff279be3          	bne	a5,s2,800027f4 <wait+0xc8>
                acquire(&pp->lock);
    80002802:	8526                	mv	a0,s1
    80002804:	ffffe097          	auipc	ra,0xffffe
    80002808:	3ce080e7          	jalr	974(ra) # 80000bd2 <acquire>
                if (pp->state == ZOMBIE)
    8000280c:	4c9c                	lw	a5,24(s1)
    8000280e:	f74785e3          	beq	a5,s4,80002778 <wait+0x4c>
                release(&pp->lock);
    80002812:	8526                	mv	a0,s1
    80002814:	ffffe097          	auipc	ra,0xffffe
    80002818:	472080e7          	jalr	1138(ra) # 80000c86 <release>
                havekids = 1;
    8000281c:	8756                	mv	a4,s5
    8000281e:	bfd9                	j	800027f4 <wait+0xc8>
        if (!havekids || killed(p))
    80002820:	c31d                	beqz	a4,80002846 <wait+0x11a>
    80002822:	854a                	mv	a0,s2
    80002824:	00000097          	auipc	ra,0x0
    80002828:	ed6080e7          	jalr	-298(ra) # 800026fa <killed>
    8000282c:	ed09                	bnez	a0,80002846 <wait+0x11a>
        sleep(p, &wait_lock); // DOC: wait-sleep
    8000282e:	85e2                	mv	a1,s8
    80002830:	854a                	mv	a0,s2
    80002832:	00000097          	auipc	ra,0x0
    80002836:	c20080e7          	jalr	-992(ra) # 80002452 <sleep>
        havekids = 0;
    8000283a:	875e                	mv	a4,s7
        for (pp = proc; pp < &proc[NPROC]; pp++)
    8000283c:	0000f497          	auipc	s1,0xf
    80002840:	86448493          	addi	s1,s1,-1948 # 800110a0 <proc>
    80002844:	bf65                	j	800027fc <wait+0xd0>
            release(&wait_lock);
    80002846:	0000f517          	auipc	a0,0xf
    8000284a:	84250513          	addi	a0,a0,-1982 # 80011088 <wait_lock>
    8000284e:	ffffe097          	auipc	ra,0xffffe
    80002852:	438080e7          	jalr	1080(ra) # 80000c86 <release>
            return -1;
    80002856:	59fd                	li	s3,-1
    80002858:	b795                	j	800027bc <wait+0x90>

000000008000285a <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000285a:	7179                	addi	sp,sp,-48
    8000285c:	f406                	sd	ra,40(sp)
    8000285e:	f022                	sd	s0,32(sp)
    80002860:	ec26                	sd	s1,24(sp)
    80002862:	e84a                	sd	s2,16(sp)
    80002864:	e44e                	sd	s3,8(sp)
    80002866:	e052                	sd	s4,0(sp)
    80002868:	1800                	addi	s0,sp,48
    8000286a:	84aa                	mv	s1,a0
    8000286c:	892e                	mv	s2,a1
    8000286e:	89b2                	mv	s3,a2
    80002870:	8a36                	mv	s4,a3
    struct proc *p = myproc();
    80002872:	fffff097          	auipc	ra,0xfffff
    80002876:	422080e7          	jalr	1058(ra) # 80001c94 <myproc>
    if (user_dst)
    8000287a:	c08d                	beqz	s1,8000289c <either_copyout+0x42>
    {
        return copyout(p->pagetable, dst, src, len);
    8000287c:	86d2                	mv	a3,s4
    8000287e:	864e                	mv	a2,s3
    80002880:	85ca                	mv	a1,s2
    80002882:	6928                	ld	a0,80(a0)
    80002884:	fffff097          	auipc	ra,0xfffff
    80002888:	de2080e7          	jalr	-542(ra) # 80001666 <copyout>
    else
    {
        memmove((char *)dst, src, len);
        return 0;
    }
}
    8000288c:	70a2                	ld	ra,40(sp)
    8000288e:	7402                	ld	s0,32(sp)
    80002890:	64e2                	ld	s1,24(sp)
    80002892:	6942                	ld	s2,16(sp)
    80002894:	69a2                	ld	s3,8(sp)
    80002896:	6a02                	ld	s4,0(sp)
    80002898:	6145                	addi	sp,sp,48
    8000289a:	8082                	ret
        memmove((char *)dst, src, len);
    8000289c:	000a061b          	sext.w	a2,s4
    800028a0:	85ce                	mv	a1,s3
    800028a2:	854a                	mv	a0,s2
    800028a4:	ffffe097          	auipc	ra,0xffffe
    800028a8:	486080e7          	jalr	1158(ra) # 80000d2a <memmove>
        return 0;
    800028ac:	8526                	mv	a0,s1
    800028ae:	bff9                	j	8000288c <either_copyout+0x32>

00000000800028b0 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800028b0:	7179                	addi	sp,sp,-48
    800028b2:	f406                	sd	ra,40(sp)
    800028b4:	f022                	sd	s0,32(sp)
    800028b6:	ec26                	sd	s1,24(sp)
    800028b8:	e84a                	sd	s2,16(sp)
    800028ba:	e44e                	sd	s3,8(sp)
    800028bc:	e052                	sd	s4,0(sp)
    800028be:	1800                	addi	s0,sp,48
    800028c0:	892a                	mv	s2,a0
    800028c2:	84ae                	mv	s1,a1
    800028c4:	89b2                	mv	s3,a2
    800028c6:	8a36                	mv	s4,a3
    struct proc *p = myproc();
    800028c8:	fffff097          	auipc	ra,0xfffff
    800028cc:	3cc080e7          	jalr	972(ra) # 80001c94 <myproc>
    if (user_src)
    800028d0:	c08d                	beqz	s1,800028f2 <either_copyin+0x42>
    {
        return copyin(p->pagetable, dst, src, len);
    800028d2:	86d2                	mv	a3,s4
    800028d4:	864e                	mv	a2,s3
    800028d6:	85ca                	mv	a1,s2
    800028d8:	6928                	ld	a0,80(a0)
    800028da:	fffff097          	auipc	ra,0xfffff
    800028de:	e18080e7          	jalr	-488(ra) # 800016f2 <copyin>
    else
    {
        memmove(dst, (char *)src, len);
        return 0;
    }
}
    800028e2:	70a2                	ld	ra,40(sp)
    800028e4:	7402                	ld	s0,32(sp)
    800028e6:	64e2                	ld	s1,24(sp)
    800028e8:	6942                	ld	s2,16(sp)
    800028ea:	69a2                	ld	s3,8(sp)
    800028ec:	6a02                	ld	s4,0(sp)
    800028ee:	6145                	addi	sp,sp,48
    800028f0:	8082                	ret
        memmove(dst, (char *)src, len);
    800028f2:	000a061b          	sext.w	a2,s4
    800028f6:	85ce                	mv	a1,s3
    800028f8:	854a                	mv	a0,s2
    800028fa:	ffffe097          	auipc	ra,0xffffe
    800028fe:	430080e7          	jalr	1072(ra) # 80000d2a <memmove>
        return 0;
    80002902:	8526                	mv	a0,s1
    80002904:	bff9                	j	800028e2 <either_copyin+0x32>

0000000080002906 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002906:	715d                	addi	sp,sp,-80
    80002908:	e486                	sd	ra,72(sp)
    8000290a:	e0a2                	sd	s0,64(sp)
    8000290c:	fc26                	sd	s1,56(sp)
    8000290e:	f84a                	sd	s2,48(sp)
    80002910:	f44e                	sd	s3,40(sp)
    80002912:	f052                	sd	s4,32(sp)
    80002914:	ec56                	sd	s5,24(sp)
    80002916:	e85a                	sd	s6,16(sp)
    80002918:	e45e                	sd	s7,8(sp)
    8000291a:	0880                	addi	s0,sp,80
        [RUNNING] "run   ",
        [ZOMBIE] "zombie"};
    struct proc *p;
    char *state;

    printf("\n");
    8000291c:	00005517          	auipc	a0,0x5
    80002920:	7ac50513          	addi	a0,a0,1964 # 800080c8 <digits+0x88>
    80002924:	ffffe097          	auipc	ra,0xffffe
    80002928:	c62080e7          	jalr	-926(ra) # 80000586 <printf>
    for (p = proc; p < &proc[NPROC]; p++)
    8000292c:	0000f497          	auipc	s1,0xf
    80002930:	8cc48493          	addi	s1,s1,-1844 # 800111f8 <proc+0x158>
    80002934:	00014917          	auipc	s2,0x14
    80002938:	2c490913          	addi	s2,s2,708 # 80016bf8 <bcache+0x140>
    {
        if (p->state == UNUSED)
            continue;
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000293c:	4b15                	li	s6,5
            state = states[p->state];
        else
            state = "???";
    8000293e:	00006997          	auipc	s3,0x6
    80002942:	94298993          	addi	s3,s3,-1726 # 80008280 <digits+0x240>
        printf("%d <%s %s", p->pid, state, p->name);
    80002946:	00006a97          	auipc	s5,0x6
    8000294a:	942a8a93          	addi	s5,s5,-1726 # 80008288 <digits+0x248>
        printf("\n");
    8000294e:	00005a17          	auipc	s4,0x5
    80002952:	77aa0a13          	addi	s4,s4,1914 # 800080c8 <digits+0x88>
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002956:	00006b97          	auipc	s7,0x6
    8000295a:	a42b8b93          	addi	s7,s7,-1470 # 80008398 <states.0>
    8000295e:	a00d                	j	80002980 <procdump+0x7a>
        printf("%d <%s %s", p->pid, state, p->name);
    80002960:	ed86a583          	lw	a1,-296(a3)
    80002964:	8556                	mv	a0,s5
    80002966:	ffffe097          	auipc	ra,0xffffe
    8000296a:	c20080e7          	jalr	-992(ra) # 80000586 <printf>
        printf("\n");
    8000296e:	8552                	mv	a0,s4
    80002970:	ffffe097          	auipc	ra,0xffffe
    80002974:	c16080e7          	jalr	-1002(ra) # 80000586 <printf>
    for (p = proc; p < &proc[NPROC]; p++)
    80002978:	16848493          	addi	s1,s1,360
    8000297c:	03248263          	beq	s1,s2,800029a0 <procdump+0x9a>
        if (p->state == UNUSED)
    80002980:	86a6                	mv	a3,s1
    80002982:	ec04a783          	lw	a5,-320(s1)
    80002986:	dbed                	beqz	a5,80002978 <procdump+0x72>
            state = "???";
    80002988:	864e                	mv	a2,s3
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000298a:	fcfb6be3          	bltu	s6,a5,80002960 <procdump+0x5a>
    8000298e:	02079713          	slli	a4,a5,0x20
    80002992:	01d75793          	srli	a5,a4,0x1d
    80002996:	97de                	add	a5,a5,s7
    80002998:	6390                	ld	a2,0(a5)
    8000299a:	f279                	bnez	a2,80002960 <procdump+0x5a>
            state = "???";
    8000299c:	864e                	mv	a2,s3
    8000299e:	b7c9                	j	80002960 <procdump+0x5a>
    }
}
    800029a0:	60a6                	ld	ra,72(sp)
    800029a2:	6406                	ld	s0,64(sp)
    800029a4:	74e2                	ld	s1,56(sp)
    800029a6:	7942                	ld	s2,48(sp)
    800029a8:	79a2                	ld	s3,40(sp)
    800029aa:	7a02                	ld	s4,32(sp)
    800029ac:	6ae2                	ld	s5,24(sp)
    800029ae:	6b42                	ld	s6,16(sp)
    800029b0:	6ba2                	ld	s7,8(sp)
    800029b2:	6161                	addi	sp,sp,80
    800029b4:	8082                	ret

00000000800029b6 <schedls>:

void schedls()
{
    800029b6:	1101                	addi	sp,sp,-32
    800029b8:	ec06                	sd	ra,24(sp)
    800029ba:	e822                	sd	s0,16(sp)
    800029bc:	e426                	sd	s1,8(sp)
    800029be:	1000                	addi	s0,sp,32
    printf("[ ]\tScheduler Name\tScheduler ID\n");
    800029c0:	00006517          	auipc	a0,0x6
    800029c4:	8d850513          	addi	a0,a0,-1832 # 80008298 <digits+0x258>
    800029c8:	ffffe097          	auipc	ra,0xffffe
    800029cc:	bbe080e7          	jalr	-1090(ra) # 80000586 <printf>
    printf("====================================\n");
    800029d0:	00006517          	auipc	a0,0x6
    800029d4:	8f050513          	addi	a0,a0,-1808 # 800082c0 <digits+0x280>
    800029d8:	ffffe097          	auipc	ra,0xffffe
    800029dc:	bae080e7          	jalr	-1106(ra) # 80000586 <printf>
    for (int i = 0; i < SCHEDC; i++)
    {
        if (available_schedulers[i].impl == sched_pointer)
    800029e0:	00006717          	auipc	a4,0x6
    800029e4:	fb873703          	ld	a4,-72(a4) # 80008998 <available_schedulers+0x10>
    800029e8:	00006797          	auipc	a5,0x6
    800029ec:	f507b783          	ld	a5,-176(a5) # 80008938 <sched_pointer>
    800029f0:	08f70763          	beq	a4,a5,80002a7e <schedls+0xc8>
        {
            printf("[*]\t");
        }
        else
        {
            printf("   \t");
    800029f4:	00006517          	auipc	a0,0x6
    800029f8:	8f450513          	addi	a0,a0,-1804 # 800082e8 <digits+0x2a8>
    800029fc:	ffffe097          	auipc	ra,0xffffe
    80002a00:	b8a080e7          	jalr	-1142(ra) # 80000586 <printf>
        }
        printf("%s\t%d\n", available_schedulers[i].name, available_schedulers[i].id);
    80002a04:	00006497          	auipc	s1,0x6
    80002a08:	f4c48493          	addi	s1,s1,-180 # 80008950 <initcode>
    80002a0c:	48b0                	lw	a2,80(s1)
    80002a0e:	00006597          	auipc	a1,0x6
    80002a12:	f7a58593          	addi	a1,a1,-134 # 80008988 <available_schedulers>
    80002a16:	00006517          	auipc	a0,0x6
    80002a1a:	8e250513          	addi	a0,a0,-1822 # 800082f8 <digits+0x2b8>
    80002a1e:	ffffe097          	auipc	ra,0xffffe
    80002a22:	b68080e7          	jalr	-1176(ra) # 80000586 <printf>
        if (available_schedulers[i].impl == sched_pointer)
    80002a26:	74b8                	ld	a4,104(s1)
    80002a28:	00006797          	auipc	a5,0x6
    80002a2c:	f107b783          	ld	a5,-240(a5) # 80008938 <sched_pointer>
    80002a30:	06f70063          	beq	a4,a5,80002a90 <schedls+0xda>
            printf("   \t");
    80002a34:	00006517          	auipc	a0,0x6
    80002a38:	8b450513          	addi	a0,a0,-1868 # 800082e8 <digits+0x2a8>
    80002a3c:	ffffe097          	auipc	ra,0xffffe
    80002a40:	b4a080e7          	jalr	-1206(ra) # 80000586 <printf>
        printf("%s\t%d\n", available_schedulers[i].name, available_schedulers[i].id);
    80002a44:	00006617          	auipc	a2,0x6
    80002a48:	f7c62603          	lw	a2,-132(a2) # 800089c0 <available_schedulers+0x38>
    80002a4c:	00006597          	auipc	a1,0x6
    80002a50:	f5c58593          	addi	a1,a1,-164 # 800089a8 <available_schedulers+0x20>
    80002a54:	00006517          	auipc	a0,0x6
    80002a58:	8a450513          	addi	a0,a0,-1884 # 800082f8 <digits+0x2b8>
    80002a5c:	ffffe097          	auipc	ra,0xffffe
    80002a60:	b2a080e7          	jalr	-1238(ra) # 80000586 <printf>
    }
    printf("\n*: current scheduler\n\n");
    80002a64:	00006517          	auipc	a0,0x6
    80002a68:	89c50513          	addi	a0,a0,-1892 # 80008300 <digits+0x2c0>
    80002a6c:	ffffe097          	auipc	ra,0xffffe
    80002a70:	b1a080e7          	jalr	-1254(ra) # 80000586 <printf>
}
    80002a74:	60e2                	ld	ra,24(sp)
    80002a76:	6442                	ld	s0,16(sp)
    80002a78:	64a2                	ld	s1,8(sp)
    80002a7a:	6105                	addi	sp,sp,32
    80002a7c:	8082                	ret
            printf("[*]\t");
    80002a7e:	00006517          	auipc	a0,0x6
    80002a82:	87250513          	addi	a0,a0,-1934 # 800082f0 <digits+0x2b0>
    80002a86:	ffffe097          	auipc	ra,0xffffe
    80002a8a:	b00080e7          	jalr	-1280(ra) # 80000586 <printf>
    80002a8e:	bf9d                	j	80002a04 <schedls+0x4e>
    80002a90:	00006517          	auipc	a0,0x6
    80002a94:	86050513          	addi	a0,a0,-1952 # 800082f0 <digits+0x2b0>
    80002a98:	ffffe097          	auipc	ra,0xffffe
    80002a9c:	aee080e7          	jalr	-1298(ra) # 80000586 <printf>
    80002aa0:	b755                	j	80002a44 <schedls+0x8e>

0000000080002aa2 <schedset>:

void schedset(int id)
{
    80002aa2:	1141                	addi	sp,sp,-16
    80002aa4:	e406                	sd	ra,8(sp)
    80002aa6:	e022                	sd	s0,0(sp)
    80002aa8:	0800                	addi	s0,sp,16
    if (id < 0 || SCHEDC <= id)
    80002aaa:	4705                	li	a4,1
    80002aac:	02a76f63          	bltu	a4,a0,80002aea <schedset+0x48>
    {
        printf("Scheduler unchanged: ID out of range\n");
        return;
    }
    sched_pointer = available_schedulers[id].impl;
    80002ab0:	00551793          	slli	a5,a0,0x5
    80002ab4:	00006717          	auipc	a4,0x6
    80002ab8:	e9c70713          	addi	a4,a4,-356 # 80008950 <initcode>
    80002abc:	973e                	add	a4,a4,a5
    80002abe:	6738                	ld	a4,72(a4)
    80002ac0:	00006697          	auipc	a3,0x6
    80002ac4:	e6e6bc23          	sd	a4,-392(a3) # 80008938 <sched_pointer>
    printf("Scheduler successfully changed to %s\n", available_schedulers[id].name);
    80002ac8:	00006597          	auipc	a1,0x6
    80002acc:	ec058593          	addi	a1,a1,-320 # 80008988 <available_schedulers>
    80002ad0:	95be                	add	a1,a1,a5
    80002ad2:	00006517          	auipc	a0,0x6
    80002ad6:	86e50513          	addi	a0,a0,-1938 # 80008340 <digits+0x300>
    80002ada:	ffffe097          	auipc	ra,0xffffe
    80002ade:	aac080e7          	jalr	-1364(ra) # 80000586 <printf>
    80002ae2:	60a2                	ld	ra,8(sp)
    80002ae4:	6402                	ld	s0,0(sp)
    80002ae6:	0141                	addi	sp,sp,16
    80002ae8:	8082                	ret
        printf("Scheduler unchanged: ID out of range\n");
    80002aea:	00006517          	auipc	a0,0x6
    80002aee:	82e50513          	addi	a0,a0,-2002 # 80008318 <digits+0x2d8>
    80002af2:	ffffe097          	auipc	ra,0xffffe
    80002af6:	a94080e7          	jalr	-1388(ra) # 80000586 <printf>
        return;
    80002afa:	b7e5                	j	80002ae2 <schedset+0x40>

0000000080002afc <swtch>:
    80002afc:	00153023          	sd	ra,0(a0)
    80002b00:	00253423          	sd	sp,8(a0)
    80002b04:	e900                	sd	s0,16(a0)
    80002b06:	ed04                	sd	s1,24(a0)
    80002b08:	03253023          	sd	s2,32(a0)
    80002b0c:	03353423          	sd	s3,40(a0)
    80002b10:	03453823          	sd	s4,48(a0)
    80002b14:	03553c23          	sd	s5,56(a0)
    80002b18:	05653023          	sd	s6,64(a0)
    80002b1c:	05753423          	sd	s7,72(a0)
    80002b20:	05853823          	sd	s8,80(a0)
    80002b24:	05953c23          	sd	s9,88(a0)
    80002b28:	07a53023          	sd	s10,96(a0)
    80002b2c:	07b53423          	sd	s11,104(a0)
    80002b30:	0005b083          	ld	ra,0(a1)
    80002b34:	0085b103          	ld	sp,8(a1)
    80002b38:	6980                	ld	s0,16(a1)
    80002b3a:	6d84                	ld	s1,24(a1)
    80002b3c:	0205b903          	ld	s2,32(a1)
    80002b40:	0285b983          	ld	s3,40(a1)
    80002b44:	0305ba03          	ld	s4,48(a1)
    80002b48:	0385ba83          	ld	s5,56(a1)
    80002b4c:	0405bb03          	ld	s6,64(a1)
    80002b50:	0485bb83          	ld	s7,72(a1)
    80002b54:	0505bc03          	ld	s8,80(a1)
    80002b58:	0585bc83          	ld	s9,88(a1)
    80002b5c:	0605bd03          	ld	s10,96(a1)
    80002b60:	0685bd83          	ld	s11,104(a1)
    80002b64:	8082                	ret

0000000080002b66 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002b66:	1141                	addi	sp,sp,-16
    80002b68:	e406                	sd	ra,8(sp)
    80002b6a:	e022                	sd	s0,0(sp)
    80002b6c:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002b6e:	00006597          	auipc	a1,0x6
    80002b72:	85a58593          	addi	a1,a1,-1958 # 800083c8 <states.0+0x30>
    80002b76:	00014517          	auipc	a0,0x14
    80002b7a:	f2a50513          	addi	a0,a0,-214 # 80016aa0 <tickslock>
    80002b7e:	ffffe097          	auipc	ra,0xffffe
    80002b82:	fc4080e7          	jalr	-60(ra) # 80000b42 <initlock>
}
    80002b86:	60a2                	ld	ra,8(sp)
    80002b88:	6402                	ld	s0,0(sp)
    80002b8a:	0141                	addi	sp,sp,16
    80002b8c:	8082                	ret

0000000080002b8e <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002b8e:	1141                	addi	sp,sp,-16
    80002b90:	e422                	sd	s0,8(sp)
    80002b92:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b94:	00003797          	auipc	a5,0x3
    80002b98:	4fc78793          	addi	a5,a5,1276 # 80006090 <kernelvec>
    80002b9c:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002ba0:	6422                	ld	s0,8(sp)
    80002ba2:	0141                	addi	sp,sp,16
    80002ba4:	8082                	ret

0000000080002ba6 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002ba6:	1141                	addi	sp,sp,-16
    80002ba8:	e406                	sd	ra,8(sp)
    80002baa:	e022                	sd	s0,0(sp)
    80002bac:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002bae:	fffff097          	auipc	ra,0xfffff
    80002bb2:	0e6080e7          	jalr	230(ra) # 80001c94 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bb6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002bba:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002bbc:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002bc0:	00004697          	auipc	a3,0x4
    80002bc4:	44068693          	addi	a3,a3,1088 # 80007000 <_trampoline>
    80002bc8:	00004717          	auipc	a4,0x4
    80002bcc:	43870713          	addi	a4,a4,1080 # 80007000 <_trampoline>
    80002bd0:	8f15                	sub	a4,a4,a3
    80002bd2:	040007b7          	lui	a5,0x4000
    80002bd6:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002bd8:	07b2                	slli	a5,a5,0xc
    80002bda:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002bdc:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002be0:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002be2:	18002673          	csrr	a2,satp
    80002be6:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002be8:	6d30                	ld	a2,88(a0)
    80002bea:	6138                	ld	a4,64(a0)
    80002bec:	6585                	lui	a1,0x1
    80002bee:	972e                	add	a4,a4,a1
    80002bf0:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002bf2:	6d38                	ld	a4,88(a0)
    80002bf4:	00000617          	auipc	a2,0x0
    80002bf8:	13460613          	addi	a2,a2,308 # 80002d28 <usertrap>
    80002bfc:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002bfe:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002c00:	8612                	mv	a2,tp
    80002c02:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c04:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002c08:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002c0c:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c10:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002c14:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c16:	6f18                	ld	a4,24(a4)
    80002c18:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002c1c:	6928                	ld	a0,80(a0)
    80002c1e:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002c20:	00004717          	auipc	a4,0x4
    80002c24:	47c70713          	addi	a4,a4,1148 # 8000709c <userret>
    80002c28:	8f15                	sub	a4,a4,a3
    80002c2a:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002c2c:	577d                	li	a4,-1
    80002c2e:	177e                	slli	a4,a4,0x3f
    80002c30:	8d59                	or	a0,a0,a4
    80002c32:	9782                	jalr	a5
}
    80002c34:	60a2                	ld	ra,8(sp)
    80002c36:	6402                	ld	s0,0(sp)
    80002c38:	0141                	addi	sp,sp,16
    80002c3a:	8082                	ret

0000000080002c3c <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002c3c:	1101                	addi	sp,sp,-32
    80002c3e:	ec06                	sd	ra,24(sp)
    80002c40:	e822                	sd	s0,16(sp)
    80002c42:	e426                	sd	s1,8(sp)
    80002c44:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002c46:	00014497          	auipc	s1,0x14
    80002c4a:	e5a48493          	addi	s1,s1,-422 # 80016aa0 <tickslock>
    80002c4e:	8526                	mv	a0,s1
    80002c50:	ffffe097          	auipc	ra,0xffffe
    80002c54:	f82080e7          	jalr	-126(ra) # 80000bd2 <acquire>
  ticks++;
    80002c58:	00006517          	auipc	a0,0x6
    80002c5c:	db050513          	addi	a0,a0,-592 # 80008a08 <ticks>
    80002c60:	411c                	lw	a5,0(a0)
    80002c62:	2785                	addiw	a5,a5,1
    80002c64:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002c66:	00000097          	auipc	ra,0x0
    80002c6a:	850080e7          	jalr	-1968(ra) # 800024b6 <wakeup>
  release(&tickslock);
    80002c6e:	8526                	mv	a0,s1
    80002c70:	ffffe097          	auipc	ra,0xffffe
    80002c74:	016080e7          	jalr	22(ra) # 80000c86 <release>
}
    80002c78:	60e2                	ld	ra,24(sp)
    80002c7a:	6442                	ld	s0,16(sp)
    80002c7c:	64a2                	ld	s1,8(sp)
    80002c7e:	6105                	addi	sp,sp,32
    80002c80:	8082                	ret

0000000080002c82 <devintr>:
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c82:	142027f3          	csrr	a5,scause
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002c86:	4501                	li	a0,0
  if((scause & 0x8000000000000000L) &&
    80002c88:	0807df63          	bgez	a5,80002d26 <devintr+0xa4>
{
    80002c8c:	1101                	addi	sp,sp,-32
    80002c8e:	ec06                	sd	ra,24(sp)
    80002c90:	e822                	sd	s0,16(sp)
    80002c92:	e426                	sd	s1,8(sp)
    80002c94:	1000                	addi	s0,sp,32
     (scause & 0xff) == 9){
    80002c96:	0ff7f713          	zext.b	a4,a5
  if((scause & 0x8000000000000000L) &&
    80002c9a:	46a5                	li	a3,9
    80002c9c:	00d70d63          	beq	a4,a3,80002cb6 <devintr+0x34>
  } else if(scause == 0x8000000000000001L){
    80002ca0:	577d                	li	a4,-1
    80002ca2:	177e                	slli	a4,a4,0x3f
    80002ca4:	0705                	addi	a4,a4,1
    return 0;
    80002ca6:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002ca8:	04e78e63          	beq	a5,a4,80002d04 <devintr+0x82>
  }
}
    80002cac:	60e2                	ld	ra,24(sp)
    80002cae:	6442                	ld	s0,16(sp)
    80002cb0:	64a2                	ld	s1,8(sp)
    80002cb2:	6105                	addi	sp,sp,32
    80002cb4:	8082                	ret
    int irq = plic_claim();
    80002cb6:	00003097          	auipc	ra,0x3
    80002cba:	4e2080e7          	jalr	1250(ra) # 80006198 <plic_claim>
    80002cbe:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002cc0:	47a9                	li	a5,10
    80002cc2:	02f50763          	beq	a0,a5,80002cf0 <devintr+0x6e>
    } else if(irq == VIRTIO0_IRQ){
    80002cc6:	4785                	li	a5,1
    80002cc8:	02f50963          	beq	a0,a5,80002cfa <devintr+0x78>
    return 1;
    80002ccc:	4505                	li	a0,1
    } else if(irq){
    80002cce:	dcf9                	beqz	s1,80002cac <devintr+0x2a>
      printf("unexpected interrupt irq=%d\n", irq);
    80002cd0:	85a6                	mv	a1,s1
    80002cd2:	00005517          	auipc	a0,0x5
    80002cd6:	6fe50513          	addi	a0,a0,1790 # 800083d0 <states.0+0x38>
    80002cda:	ffffe097          	auipc	ra,0xffffe
    80002cde:	8ac080e7          	jalr	-1876(ra) # 80000586 <printf>
      plic_complete(irq);
    80002ce2:	8526                	mv	a0,s1
    80002ce4:	00003097          	auipc	ra,0x3
    80002ce8:	4d8080e7          	jalr	1240(ra) # 800061bc <plic_complete>
    return 1;
    80002cec:	4505                	li	a0,1
    80002cee:	bf7d                	j	80002cac <devintr+0x2a>
      uartintr();
    80002cf0:	ffffe097          	auipc	ra,0xffffe
    80002cf4:	ca4080e7          	jalr	-860(ra) # 80000994 <uartintr>
    if(irq)
    80002cf8:	b7ed                	j	80002ce2 <devintr+0x60>
      virtio_disk_intr();
    80002cfa:	00004097          	auipc	ra,0x4
    80002cfe:	988080e7          	jalr	-1656(ra) # 80006682 <virtio_disk_intr>
    if(irq)
    80002d02:	b7c5                	j	80002ce2 <devintr+0x60>
    if(cpuid() == 0){
    80002d04:	fffff097          	auipc	ra,0xfffff
    80002d08:	f64080e7          	jalr	-156(ra) # 80001c68 <cpuid>
    80002d0c:	c901                	beqz	a0,80002d1c <devintr+0x9a>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002d0e:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002d12:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002d14:	14479073          	csrw	sip,a5
    return 2;
    80002d18:	4509                	li	a0,2
    80002d1a:	bf49                	j	80002cac <devintr+0x2a>
      clockintr();
    80002d1c:	00000097          	auipc	ra,0x0
    80002d20:	f20080e7          	jalr	-224(ra) # 80002c3c <clockintr>
    80002d24:	b7ed                	j	80002d0e <devintr+0x8c>
}
    80002d26:	8082                	ret

0000000080002d28 <usertrap>:
{
    80002d28:	1101                	addi	sp,sp,-32
    80002d2a:	ec06                	sd	ra,24(sp)
    80002d2c:	e822                	sd	s0,16(sp)
    80002d2e:	e426                	sd	s1,8(sp)
    80002d30:	e04a                	sd	s2,0(sp)
    80002d32:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d34:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002d38:	1007f793          	andi	a5,a5,256
    80002d3c:	e3b1                	bnez	a5,80002d80 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002d3e:	00003797          	auipc	a5,0x3
    80002d42:	35278793          	addi	a5,a5,850 # 80006090 <kernelvec>
    80002d46:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002d4a:	fffff097          	auipc	ra,0xfffff
    80002d4e:	f4a080e7          	jalr	-182(ra) # 80001c94 <myproc>
    80002d52:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002d54:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d56:	14102773          	csrr	a4,sepc
    80002d5a:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d5c:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002d60:	47a1                	li	a5,8
    80002d62:	02f70763          	beq	a4,a5,80002d90 <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    80002d66:	00000097          	auipc	ra,0x0
    80002d6a:	f1c080e7          	jalr	-228(ra) # 80002c82 <devintr>
    80002d6e:	892a                	mv	s2,a0
    80002d70:	c151                	beqz	a0,80002df4 <usertrap+0xcc>
  if(killed(p))
    80002d72:	8526                	mv	a0,s1
    80002d74:	00000097          	auipc	ra,0x0
    80002d78:	986080e7          	jalr	-1658(ra) # 800026fa <killed>
    80002d7c:	c929                	beqz	a0,80002dce <usertrap+0xa6>
    80002d7e:	a099                	j	80002dc4 <usertrap+0x9c>
    panic("usertrap: not from user mode");
    80002d80:	00005517          	auipc	a0,0x5
    80002d84:	67050513          	addi	a0,a0,1648 # 800083f0 <states.0+0x58>
    80002d88:	ffffd097          	auipc	ra,0xffffd
    80002d8c:	7b4080e7          	jalr	1972(ra) # 8000053c <panic>
    if(killed(p))
    80002d90:	00000097          	auipc	ra,0x0
    80002d94:	96a080e7          	jalr	-1686(ra) # 800026fa <killed>
    80002d98:	e921                	bnez	a0,80002de8 <usertrap+0xc0>
    p->trapframe->epc += 4;
    80002d9a:	6cb8                	ld	a4,88(s1)
    80002d9c:	6f1c                	ld	a5,24(a4)
    80002d9e:	0791                	addi	a5,a5,4
    80002da0:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002da2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002da6:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002daa:	10079073          	csrw	sstatus,a5
    syscall();
    80002dae:	00000097          	auipc	ra,0x0
    80002db2:	2d4080e7          	jalr	724(ra) # 80003082 <syscall>
  if(killed(p))
    80002db6:	8526                	mv	a0,s1
    80002db8:	00000097          	auipc	ra,0x0
    80002dbc:	942080e7          	jalr	-1726(ra) # 800026fa <killed>
    80002dc0:	c911                	beqz	a0,80002dd4 <usertrap+0xac>
    80002dc2:	4901                	li	s2,0
    exit(-1);
    80002dc4:	557d                	li	a0,-1
    80002dc6:	fffff097          	auipc	ra,0xfffff
    80002dca:	7c0080e7          	jalr	1984(ra) # 80002586 <exit>
  if(which_dev == 2)
    80002dce:	4789                	li	a5,2
    80002dd0:	04f90f63          	beq	s2,a5,80002e2e <usertrap+0x106>
  usertrapret();
    80002dd4:	00000097          	auipc	ra,0x0
    80002dd8:	dd2080e7          	jalr	-558(ra) # 80002ba6 <usertrapret>
}
    80002ddc:	60e2                	ld	ra,24(sp)
    80002dde:	6442                	ld	s0,16(sp)
    80002de0:	64a2                	ld	s1,8(sp)
    80002de2:	6902                	ld	s2,0(sp)
    80002de4:	6105                	addi	sp,sp,32
    80002de6:	8082                	ret
      exit(-1);
    80002de8:	557d                	li	a0,-1
    80002dea:	fffff097          	auipc	ra,0xfffff
    80002dee:	79c080e7          	jalr	1948(ra) # 80002586 <exit>
    80002df2:	b765                	j	80002d9a <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002df4:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002df8:	5890                	lw	a2,48(s1)
    80002dfa:	00005517          	auipc	a0,0x5
    80002dfe:	61650513          	addi	a0,a0,1558 # 80008410 <states.0+0x78>
    80002e02:	ffffd097          	auipc	ra,0xffffd
    80002e06:	784080e7          	jalr	1924(ra) # 80000586 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e0a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002e0e:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002e12:	00005517          	auipc	a0,0x5
    80002e16:	62e50513          	addi	a0,a0,1582 # 80008440 <states.0+0xa8>
    80002e1a:	ffffd097          	auipc	ra,0xffffd
    80002e1e:	76c080e7          	jalr	1900(ra) # 80000586 <printf>
    setkilled(p);
    80002e22:	8526                	mv	a0,s1
    80002e24:	00000097          	auipc	ra,0x0
    80002e28:	8aa080e7          	jalr	-1878(ra) # 800026ce <setkilled>
    80002e2c:	b769                	j	80002db6 <usertrap+0x8e>
    yield();
    80002e2e:	fffff097          	auipc	ra,0xfffff
    80002e32:	5e8080e7          	jalr	1512(ra) # 80002416 <yield>
    80002e36:	bf79                	j	80002dd4 <usertrap+0xac>

0000000080002e38 <kerneltrap>:
{
    80002e38:	7179                	addi	sp,sp,-48
    80002e3a:	f406                	sd	ra,40(sp)
    80002e3c:	f022                	sd	s0,32(sp)
    80002e3e:	ec26                	sd	s1,24(sp)
    80002e40:	e84a                	sd	s2,16(sp)
    80002e42:	e44e                	sd	s3,8(sp)
    80002e44:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e46:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e4a:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e4e:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002e52:	1004f793          	andi	a5,s1,256
    80002e56:	cb85                	beqz	a5,80002e86 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e58:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002e5c:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002e5e:	ef85                	bnez	a5,80002e96 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002e60:	00000097          	auipc	ra,0x0
    80002e64:	e22080e7          	jalr	-478(ra) # 80002c82 <devintr>
    80002e68:	cd1d                	beqz	a0,80002ea6 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002e6a:	4789                	li	a5,2
    80002e6c:	06f50a63          	beq	a0,a5,80002ee0 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002e70:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e74:	10049073          	csrw	sstatus,s1
}
    80002e78:	70a2                	ld	ra,40(sp)
    80002e7a:	7402                	ld	s0,32(sp)
    80002e7c:	64e2                	ld	s1,24(sp)
    80002e7e:	6942                	ld	s2,16(sp)
    80002e80:	69a2                	ld	s3,8(sp)
    80002e82:	6145                	addi	sp,sp,48
    80002e84:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002e86:	00005517          	auipc	a0,0x5
    80002e8a:	5da50513          	addi	a0,a0,1498 # 80008460 <states.0+0xc8>
    80002e8e:	ffffd097          	auipc	ra,0xffffd
    80002e92:	6ae080e7          	jalr	1710(ra) # 8000053c <panic>
    panic("kerneltrap: interrupts enabled");
    80002e96:	00005517          	auipc	a0,0x5
    80002e9a:	5f250513          	addi	a0,a0,1522 # 80008488 <states.0+0xf0>
    80002e9e:	ffffd097          	auipc	ra,0xffffd
    80002ea2:	69e080e7          	jalr	1694(ra) # 8000053c <panic>
    printf("scause %p\n", scause);
    80002ea6:	85ce                	mv	a1,s3
    80002ea8:	00005517          	auipc	a0,0x5
    80002eac:	60050513          	addi	a0,a0,1536 # 800084a8 <states.0+0x110>
    80002eb0:	ffffd097          	auipc	ra,0xffffd
    80002eb4:	6d6080e7          	jalr	1750(ra) # 80000586 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002eb8:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ebc:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ec0:	00005517          	auipc	a0,0x5
    80002ec4:	5f850513          	addi	a0,a0,1528 # 800084b8 <states.0+0x120>
    80002ec8:	ffffd097          	auipc	ra,0xffffd
    80002ecc:	6be080e7          	jalr	1726(ra) # 80000586 <printf>
    panic("kerneltrap");
    80002ed0:	00005517          	auipc	a0,0x5
    80002ed4:	60050513          	addi	a0,a0,1536 # 800084d0 <states.0+0x138>
    80002ed8:	ffffd097          	auipc	ra,0xffffd
    80002edc:	664080e7          	jalr	1636(ra) # 8000053c <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002ee0:	fffff097          	auipc	ra,0xfffff
    80002ee4:	db4080e7          	jalr	-588(ra) # 80001c94 <myproc>
    80002ee8:	d541                	beqz	a0,80002e70 <kerneltrap+0x38>
    80002eea:	fffff097          	auipc	ra,0xfffff
    80002eee:	daa080e7          	jalr	-598(ra) # 80001c94 <myproc>
    80002ef2:	4d18                	lw	a4,24(a0)
    80002ef4:	4791                	li	a5,4
    80002ef6:	f6f71de3          	bne	a4,a5,80002e70 <kerneltrap+0x38>
    yield();
    80002efa:	fffff097          	auipc	ra,0xfffff
    80002efe:	51c080e7          	jalr	1308(ra) # 80002416 <yield>
    80002f02:	b7bd                	j	80002e70 <kerneltrap+0x38>

0000000080002f04 <argraw>:
    return strlen(buf);
}

static uint64
argraw(int n)
{
    80002f04:	1101                	addi	sp,sp,-32
    80002f06:	ec06                	sd	ra,24(sp)
    80002f08:	e822                	sd	s0,16(sp)
    80002f0a:	e426                	sd	s1,8(sp)
    80002f0c:	1000                	addi	s0,sp,32
    80002f0e:	84aa                	mv	s1,a0
    struct proc *p = myproc();
    80002f10:	fffff097          	auipc	ra,0xfffff
    80002f14:	d84080e7          	jalr	-636(ra) # 80001c94 <myproc>
    switch (n)
    80002f18:	4795                	li	a5,5
    80002f1a:	0497e163          	bltu	a5,s1,80002f5c <argraw+0x58>
    80002f1e:	048a                	slli	s1,s1,0x2
    80002f20:	00005717          	auipc	a4,0x5
    80002f24:	5e870713          	addi	a4,a4,1512 # 80008508 <states.0+0x170>
    80002f28:	94ba                	add	s1,s1,a4
    80002f2a:	409c                	lw	a5,0(s1)
    80002f2c:	97ba                	add	a5,a5,a4
    80002f2e:	8782                	jr	a5
    {
    case 0:
        return p->trapframe->a0;
    80002f30:	6d3c                	ld	a5,88(a0)
    80002f32:	7ba8                	ld	a0,112(a5)
    case 5:
        return p->trapframe->a5;
    }
    panic("argraw");
    return -1;
}
    80002f34:	60e2                	ld	ra,24(sp)
    80002f36:	6442                	ld	s0,16(sp)
    80002f38:	64a2                	ld	s1,8(sp)
    80002f3a:	6105                	addi	sp,sp,32
    80002f3c:	8082                	ret
        return p->trapframe->a1;
    80002f3e:	6d3c                	ld	a5,88(a0)
    80002f40:	7fa8                	ld	a0,120(a5)
    80002f42:	bfcd                	j	80002f34 <argraw+0x30>
        return p->trapframe->a2;
    80002f44:	6d3c                	ld	a5,88(a0)
    80002f46:	63c8                	ld	a0,128(a5)
    80002f48:	b7f5                	j	80002f34 <argraw+0x30>
        return p->trapframe->a3;
    80002f4a:	6d3c                	ld	a5,88(a0)
    80002f4c:	67c8                	ld	a0,136(a5)
    80002f4e:	b7dd                	j	80002f34 <argraw+0x30>
        return p->trapframe->a4;
    80002f50:	6d3c                	ld	a5,88(a0)
    80002f52:	6bc8                	ld	a0,144(a5)
    80002f54:	b7c5                	j	80002f34 <argraw+0x30>
        return p->trapframe->a5;
    80002f56:	6d3c                	ld	a5,88(a0)
    80002f58:	6fc8                	ld	a0,152(a5)
    80002f5a:	bfe9                	j	80002f34 <argraw+0x30>
    panic("argraw");
    80002f5c:	00005517          	auipc	a0,0x5
    80002f60:	58450513          	addi	a0,a0,1412 # 800084e0 <states.0+0x148>
    80002f64:	ffffd097          	auipc	ra,0xffffd
    80002f68:	5d8080e7          	jalr	1496(ra) # 8000053c <panic>

0000000080002f6c <fetchaddr>:
{
    80002f6c:	1101                	addi	sp,sp,-32
    80002f6e:	ec06                	sd	ra,24(sp)
    80002f70:	e822                	sd	s0,16(sp)
    80002f72:	e426                	sd	s1,8(sp)
    80002f74:	e04a                	sd	s2,0(sp)
    80002f76:	1000                	addi	s0,sp,32
    80002f78:	84aa                	mv	s1,a0
    80002f7a:	892e                	mv	s2,a1
    struct proc *p = myproc();
    80002f7c:	fffff097          	auipc	ra,0xfffff
    80002f80:	d18080e7          	jalr	-744(ra) # 80001c94 <myproc>
    if (addr >= p->sz || addr + sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002f84:	653c                	ld	a5,72(a0)
    80002f86:	02f4f863          	bgeu	s1,a5,80002fb6 <fetchaddr+0x4a>
    80002f8a:	00848713          	addi	a4,s1,8
    80002f8e:	02e7e663          	bltu	a5,a4,80002fba <fetchaddr+0x4e>
    if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002f92:	46a1                	li	a3,8
    80002f94:	8626                	mv	a2,s1
    80002f96:	85ca                	mv	a1,s2
    80002f98:	6928                	ld	a0,80(a0)
    80002f9a:	ffffe097          	auipc	ra,0xffffe
    80002f9e:	758080e7          	jalr	1880(ra) # 800016f2 <copyin>
    80002fa2:	00a03533          	snez	a0,a0
    80002fa6:	40a00533          	neg	a0,a0
}
    80002faa:	60e2                	ld	ra,24(sp)
    80002fac:	6442                	ld	s0,16(sp)
    80002fae:	64a2                	ld	s1,8(sp)
    80002fb0:	6902                	ld	s2,0(sp)
    80002fb2:	6105                	addi	sp,sp,32
    80002fb4:	8082                	ret
        return -1;
    80002fb6:	557d                	li	a0,-1
    80002fb8:	bfcd                	j	80002faa <fetchaddr+0x3e>
    80002fba:	557d                	li	a0,-1
    80002fbc:	b7fd                	j	80002faa <fetchaddr+0x3e>

0000000080002fbe <fetchstr>:
{
    80002fbe:	7179                	addi	sp,sp,-48
    80002fc0:	f406                	sd	ra,40(sp)
    80002fc2:	f022                	sd	s0,32(sp)
    80002fc4:	ec26                	sd	s1,24(sp)
    80002fc6:	e84a                	sd	s2,16(sp)
    80002fc8:	e44e                	sd	s3,8(sp)
    80002fca:	1800                	addi	s0,sp,48
    80002fcc:	892a                	mv	s2,a0
    80002fce:	84ae                	mv	s1,a1
    80002fd0:	89b2                	mv	s3,a2
    struct proc *p = myproc();
    80002fd2:	fffff097          	auipc	ra,0xfffff
    80002fd6:	cc2080e7          	jalr	-830(ra) # 80001c94 <myproc>
    if (copyinstr(p->pagetable, buf, addr, max) < 0)
    80002fda:	86ce                	mv	a3,s3
    80002fdc:	864a                	mv	a2,s2
    80002fde:	85a6                	mv	a1,s1
    80002fe0:	6928                	ld	a0,80(a0)
    80002fe2:	ffffe097          	auipc	ra,0xffffe
    80002fe6:	79e080e7          	jalr	1950(ra) # 80001780 <copyinstr>
    80002fea:	00054e63          	bltz	a0,80003006 <fetchstr+0x48>
    return strlen(buf);
    80002fee:	8526                	mv	a0,s1
    80002ff0:	ffffe097          	auipc	ra,0xffffe
    80002ff4:	e58080e7          	jalr	-424(ra) # 80000e48 <strlen>
}
    80002ff8:	70a2                	ld	ra,40(sp)
    80002ffa:	7402                	ld	s0,32(sp)
    80002ffc:	64e2                	ld	s1,24(sp)
    80002ffe:	6942                	ld	s2,16(sp)
    80003000:	69a2                	ld	s3,8(sp)
    80003002:	6145                	addi	sp,sp,48
    80003004:	8082                	ret
        return -1;
    80003006:	557d                	li	a0,-1
    80003008:	bfc5                	j	80002ff8 <fetchstr+0x3a>

000000008000300a <argint>:

// Fetch the nth 32-bit system call argument.
void argint(int n, int *ip)
{
    8000300a:	1101                	addi	sp,sp,-32
    8000300c:	ec06                	sd	ra,24(sp)
    8000300e:	e822                	sd	s0,16(sp)
    80003010:	e426                	sd	s1,8(sp)
    80003012:	1000                	addi	s0,sp,32
    80003014:	84ae                	mv	s1,a1
    *ip = argraw(n);
    80003016:	00000097          	auipc	ra,0x0
    8000301a:	eee080e7          	jalr	-274(ra) # 80002f04 <argraw>
    8000301e:	c088                	sw	a0,0(s1)
}
    80003020:	60e2                	ld	ra,24(sp)
    80003022:	6442                	ld	s0,16(sp)
    80003024:	64a2                	ld	s1,8(sp)
    80003026:	6105                	addi	sp,sp,32
    80003028:	8082                	ret

000000008000302a <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void argaddr(int n, uint64 *ip)
{
    8000302a:	1101                	addi	sp,sp,-32
    8000302c:	ec06                	sd	ra,24(sp)
    8000302e:	e822                	sd	s0,16(sp)
    80003030:	e426                	sd	s1,8(sp)
    80003032:	1000                	addi	s0,sp,32
    80003034:	84ae                	mv	s1,a1
    *ip = argraw(n);
    80003036:	00000097          	auipc	ra,0x0
    8000303a:	ece080e7          	jalr	-306(ra) # 80002f04 <argraw>
    8000303e:	e088                	sd	a0,0(s1)
}
    80003040:	60e2                	ld	ra,24(sp)
    80003042:	6442                	ld	s0,16(sp)
    80003044:	64a2                	ld	s1,8(sp)
    80003046:	6105                	addi	sp,sp,32
    80003048:	8082                	ret

000000008000304a <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    8000304a:	7179                	addi	sp,sp,-48
    8000304c:	f406                	sd	ra,40(sp)
    8000304e:	f022                	sd	s0,32(sp)
    80003050:	ec26                	sd	s1,24(sp)
    80003052:	e84a                	sd	s2,16(sp)
    80003054:	1800                	addi	s0,sp,48
    80003056:	84ae                	mv	s1,a1
    80003058:	8932                	mv	s2,a2
    uint64 addr;
    argaddr(n, &addr);
    8000305a:	fd840593          	addi	a1,s0,-40
    8000305e:	00000097          	auipc	ra,0x0
    80003062:	fcc080e7          	jalr	-52(ra) # 8000302a <argaddr>
    return fetchstr(addr, buf, max);
    80003066:	864a                	mv	a2,s2
    80003068:	85a6                	mv	a1,s1
    8000306a:	fd843503          	ld	a0,-40(s0)
    8000306e:	00000097          	auipc	ra,0x0
    80003072:	f50080e7          	jalr	-176(ra) # 80002fbe <fetchstr>
}
    80003076:	70a2                	ld	ra,40(sp)
    80003078:	7402                	ld	s0,32(sp)
    8000307a:	64e2                	ld	s1,24(sp)
    8000307c:	6942                	ld	s2,16(sp)
    8000307e:	6145                	addi	sp,sp,48
    80003080:	8082                	ret

0000000080003082 <syscall>:
    [SYS_schedls] sys_schedls,
    [SYS_schedset] sys_schedset,
};

void syscall(void)
{
    80003082:	1101                	addi	sp,sp,-32
    80003084:	ec06                	sd	ra,24(sp)
    80003086:	e822                	sd	s0,16(sp)
    80003088:	e426                	sd	s1,8(sp)
    8000308a:	e04a                	sd	s2,0(sp)
    8000308c:	1000                	addi	s0,sp,32
    int num;
    struct proc *p = myproc();
    8000308e:	fffff097          	auipc	ra,0xfffff
    80003092:	c06080e7          	jalr	-1018(ra) # 80001c94 <myproc>
    80003096:	84aa                	mv	s1,a0

    num = p->trapframe->a7;
    80003098:	05853903          	ld	s2,88(a0)
    8000309c:	0a893783          	ld	a5,168(s2)
    800030a0:	0007869b          	sext.w	a3,a5
    if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    800030a4:	37fd                	addiw	a5,a5,-1
    800030a6:	475d                	li	a4,23
    800030a8:	00f76f63          	bltu	a4,a5,800030c6 <syscall+0x44>
    800030ac:	00369713          	slli	a4,a3,0x3
    800030b0:	00005797          	auipc	a5,0x5
    800030b4:	47078793          	addi	a5,a5,1136 # 80008520 <syscalls>
    800030b8:	97ba                	add	a5,a5,a4
    800030ba:	639c                	ld	a5,0(a5)
    800030bc:	c789                	beqz	a5,800030c6 <syscall+0x44>
    {
        // Use num to lookup the system call function for num, call it,
        // and store its return value in p->trapframe->a0
        p->trapframe->a0 = syscalls[num]();
    800030be:	9782                	jalr	a5
    800030c0:	06a93823          	sd	a0,112(s2)
    800030c4:	a839                	j	800030e2 <syscall+0x60>
    }
    else
    {
        printf("%d %s: unknown sys call %d\n",
    800030c6:	15848613          	addi	a2,s1,344
    800030ca:	588c                	lw	a1,48(s1)
    800030cc:	00005517          	auipc	a0,0x5
    800030d0:	41c50513          	addi	a0,a0,1052 # 800084e8 <states.0+0x150>
    800030d4:	ffffd097          	auipc	ra,0xffffd
    800030d8:	4b2080e7          	jalr	1202(ra) # 80000586 <printf>
               p->pid, p->name, num);
        p->trapframe->a0 = -1;
    800030dc:	6cbc                	ld	a5,88(s1)
    800030de:	577d                	li	a4,-1
    800030e0:	fbb8                	sd	a4,112(a5)
    }
}
    800030e2:	60e2                	ld	ra,24(sp)
    800030e4:	6442                	ld	s0,16(sp)
    800030e6:	64a2                	ld	s1,8(sp)
    800030e8:	6902                	ld	s2,0(sp)
    800030ea:	6105                	addi	sp,sp,32
    800030ec:	8082                	ret

00000000800030ee <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    800030ee:	1101                	addi	sp,sp,-32
    800030f0:	ec06                	sd	ra,24(sp)
    800030f2:	e822                	sd	s0,16(sp)
    800030f4:	1000                	addi	s0,sp,32
    int n;
    argint(0, &n);
    800030f6:	fec40593          	addi	a1,s0,-20
    800030fa:	4501                	li	a0,0
    800030fc:	00000097          	auipc	ra,0x0
    80003100:	f0e080e7          	jalr	-242(ra) # 8000300a <argint>
    exit(n);
    80003104:	fec42503          	lw	a0,-20(s0)
    80003108:	fffff097          	auipc	ra,0xfffff
    8000310c:	47e080e7          	jalr	1150(ra) # 80002586 <exit>
    return 0; // not reached
}
    80003110:	4501                	li	a0,0
    80003112:	60e2                	ld	ra,24(sp)
    80003114:	6442                	ld	s0,16(sp)
    80003116:	6105                	addi	sp,sp,32
    80003118:	8082                	ret

000000008000311a <sys_getpid>:

uint64
sys_getpid(void)
{
    8000311a:	1141                	addi	sp,sp,-16
    8000311c:	e406                	sd	ra,8(sp)
    8000311e:	e022                	sd	s0,0(sp)
    80003120:	0800                	addi	s0,sp,16
    return myproc()->pid;
    80003122:	fffff097          	auipc	ra,0xfffff
    80003126:	b72080e7          	jalr	-1166(ra) # 80001c94 <myproc>
}
    8000312a:	5908                	lw	a0,48(a0)
    8000312c:	60a2                	ld	ra,8(sp)
    8000312e:	6402                	ld	s0,0(sp)
    80003130:	0141                	addi	sp,sp,16
    80003132:	8082                	ret

0000000080003134 <sys_fork>:

uint64
sys_fork(void)
{
    80003134:	1141                	addi	sp,sp,-16
    80003136:	e406                	sd	ra,8(sp)
    80003138:	e022                	sd	s0,0(sp)
    8000313a:	0800                	addi	s0,sp,16
    return fork();
    8000313c:	fffff097          	auipc	ra,0xfffff
    80003140:	05e080e7          	jalr	94(ra) # 8000219a <fork>
}
    80003144:	60a2                	ld	ra,8(sp)
    80003146:	6402                	ld	s0,0(sp)
    80003148:	0141                	addi	sp,sp,16
    8000314a:	8082                	ret

000000008000314c <sys_wait>:

uint64
sys_wait(void)
{
    8000314c:	1101                	addi	sp,sp,-32
    8000314e:	ec06                	sd	ra,24(sp)
    80003150:	e822                	sd	s0,16(sp)
    80003152:	1000                	addi	s0,sp,32
    uint64 p;
    argaddr(0, &p);
    80003154:	fe840593          	addi	a1,s0,-24
    80003158:	4501                	li	a0,0
    8000315a:	00000097          	auipc	ra,0x0
    8000315e:	ed0080e7          	jalr	-304(ra) # 8000302a <argaddr>
    return wait(p);
    80003162:	fe843503          	ld	a0,-24(s0)
    80003166:	fffff097          	auipc	ra,0xfffff
    8000316a:	5c6080e7          	jalr	1478(ra) # 8000272c <wait>
}
    8000316e:	60e2                	ld	ra,24(sp)
    80003170:	6442                	ld	s0,16(sp)
    80003172:	6105                	addi	sp,sp,32
    80003174:	8082                	ret

0000000080003176 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003176:	7179                	addi	sp,sp,-48
    80003178:	f406                	sd	ra,40(sp)
    8000317a:	f022                	sd	s0,32(sp)
    8000317c:	ec26                	sd	s1,24(sp)
    8000317e:	1800                	addi	s0,sp,48
    uint64 addr;
    int n;

    argint(0, &n);
    80003180:	fdc40593          	addi	a1,s0,-36
    80003184:	4501                	li	a0,0
    80003186:	00000097          	auipc	ra,0x0
    8000318a:	e84080e7          	jalr	-380(ra) # 8000300a <argint>
    addr = myproc()->sz;
    8000318e:	fffff097          	auipc	ra,0xfffff
    80003192:	b06080e7          	jalr	-1274(ra) # 80001c94 <myproc>
    80003196:	6524                	ld	s1,72(a0)
    if (growproc(n) < 0)
    80003198:	fdc42503          	lw	a0,-36(s0)
    8000319c:	fffff097          	auipc	ra,0xfffff
    800031a0:	e52080e7          	jalr	-430(ra) # 80001fee <growproc>
    800031a4:	00054863          	bltz	a0,800031b4 <sys_sbrk+0x3e>
        return -1;
    return addr;
}
    800031a8:	8526                	mv	a0,s1
    800031aa:	70a2                	ld	ra,40(sp)
    800031ac:	7402                	ld	s0,32(sp)
    800031ae:	64e2                	ld	s1,24(sp)
    800031b0:	6145                	addi	sp,sp,48
    800031b2:	8082                	ret
        return -1;
    800031b4:	54fd                	li	s1,-1
    800031b6:	bfcd                	j	800031a8 <sys_sbrk+0x32>

00000000800031b8 <sys_sleep>:

uint64
sys_sleep(void)
{
    800031b8:	7139                	addi	sp,sp,-64
    800031ba:	fc06                	sd	ra,56(sp)
    800031bc:	f822                	sd	s0,48(sp)
    800031be:	f426                	sd	s1,40(sp)
    800031c0:	f04a                	sd	s2,32(sp)
    800031c2:	ec4e                	sd	s3,24(sp)
    800031c4:	0080                	addi	s0,sp,64
    int n;
    uint ticks0;

    argint(0, &n);
    800031c6:	fcc40593          	addi	a1,s0,-52
    800031ca:	4501                	li	a0,0
    800031cc:	00000097          	auipc	ra,0x0
    800031d0:	e3e080e7          	jalr	-450(ra) # 8000300a <argint>
    acquire(&tickslock);
    800031d4:	00014517          	auipc	a0,0x14
    800031d8:	8cc50513          	addi	a0,a0,-1844 # 80016aa0 <tickslock>
    800031dc:	ffffe097          	auipc	ra,0xffffe
    800031e0:	9f6080e7          	jalr	-1546(ra) # 80000bd2 <acquire>
    ticks0 = ticks;
    800031e4:	00006917          	auipc	s2,0x6
    800031e8:	82492903          	lw	s2,-2012(s2) # 80008a08 <ticks>
    while (ticks - ticks0 < n)
    800031ec:	fcc42783          	lw	a5,-52(s0)
    800031f0:	cf9d                	beqz	a5,8000322e <sys_sleep+0x76>
        if (killed(myproc()))
        {
            release(&tickslock);
            return -1;
        }
        sleep(&ticks, &tickslock);
    800031f2:	00014997          	auipc	s3,0x14
    800031f6:	8ae98993          	addi	s3,s3,-1874 # 80016aa0 <tickslock>
    800031fa:	00006497          	auipc	s1,0x6
    800031fe:	80e48493          	addi	s1,s1,-2034 # 80008a08 <ticks>
        if (killed(myproc()))
    80003202:	fffff097          	auipc	ra,0xfffff
    80003206:	a92080e7          	jalr	-1390(ra) # 80001c94 <myproc>
    8000320a:	fffff097          	auipc	ra,0xfffff
    8000320e:	4f0080e7          	jalr	1264(ra) # 800026fa <killed>
    80003212:	ed15                	bnez	a0,8000324e <sys_sleep+0x96>
        sleep(&ticks, &tickslock);
    80003214:	85ce                	mv	a1,s3
    80003216:	8526                	mv	a0,s1
    80003218:	fffff097          	auipc	ra,0xfffff
    8000321c:	23a080e7          	jalr	570(ra) # 80002452 <sleep>
    while (ticks - ticks0 < n)
    80003220:	409c                	lw	a5,0(s1)
    80003222:	412787bb          	subw	a5,a5,s2
    80003226:	fcc42703          	lw	a4,-52(s0)
    8000322a:	fce7ece3          	bltu	a5,a4,80003202 <sys_sleep+0x4a>
    }
    release(&tickslock);
    8000322e:	00014517          	auipc	a0,0x14
    80003232:	87250513          	addi	a0,a0,-1934 # 80016aa0 <tickslock>
    80003236:	ffffe097          	auipc	ra,0xffffe
    8000323a:	a50080e7          	jalr	-1456(ra) # 80000c86 <release>
    return 0;
    8000323e:	4501                	li	a0,0
}
    80003240:	70e2                	ld	ra,56(sp)
    80003242:	7442                	ld	s0,48(sp)
    80003244:	74a2                	ld	s1,40(sp)
    80003246:	7902                	ld	s2,32(sp)
    80003248:	69e2                	ld	s3,24(sp)
    8000324a:	6121                	addi	sp,sp,64
    8000324c:	8082                	ret
            release(&tickslock);
    8000324e:	00014517          	auipc	a0,0x14
    80003252:	85250513          	addi	a0,a0,-1966 # 80016aa0 <tickslock>
    80003256:	ffffe097          	auipc	ra,0xffffe
    8000325a:	a30080e7          	jalr	-1488(ra) # 80000c86 <release>
            return -1;
    8000325e:	557d                	li	a0,-1
    80003260:	b7c5                	j	80003240 <sys_sleep+0x88>

0000000080003262 <sys_kill>:

uint64
sys_kill(void)
{
    80003262:	1101                	addi	sp,sp,-32
    80003264:	ec06                	sd	ra,24(sp)
    80003266:	e822                	sd	s0,16(sp)
    80003268:	1000                	addi	s0,sp,32
    int pid;

    argint(0, &pid);
    8000326a:	fec40593          	addi	a1,s0,-20
    8000326e:	4501                	li	a0,0
    80003270:	00000097          	auipc	ra,0x0
    80003274:	d9a080e7          	jalr	-614(ra) # 8000300a <argint>
    return kill(pid);
    80003278:	fec42503          	lw	a0,-20(s0)
    8000327c:	fffff097          	auipc	ra,0xfffff
    80003280:	3e0080e7          	jalr	992(ra) # 8000265c <kill>
}
    80003284:	60e2                	ld	ra,24(sp)
    80003286:	6442                	ld	s0,16(sp)
    80003288:	6105                	addi	sp,sp,32
    8000328a:	8082                	ret

000000008000328c <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    8000328c:	1101                	addi	sp,sp,-32
    8000328e:	ec06                	sd	ra,24(sp)
    80003290:	e822                	sd	s0,16(sp)
    80003292:	e426                	sd	s1,8(sp)
    80003294:	1000                	addi	s0,sp,32
    uint xticks;

    acquire(&tickslock);
    80003296:	00014517          	auipc	a0,0x14
    8000329a:	80a50513          	addi	a0,a0,-2038 # 80016aa0 <tickslock>
    8000329e:	ffffe097          	auipc	ra,0xffffe
    800032a2:	934080e7          	jalr	-1740(ra) # 80000bd2 <acquire>
    xticks = ticks;
    800032a6:	00005497          	auipc	s1,0x5
    800032aa:	7624a483          	lw	s1,1890(s1) # 80008a08 <ticks>
    release(&tickslock);
    800032ae:	00013517          	auipc	a0,0x13
    800032b2:	7f250513          	addi	a0,a0,2034 # 80016aa0 <tickslock>
    800032b6:	ffffe097          	auipc	ra,0xffffe
    800032ba:	9d0080e7          	jalr	-1584(ra) # 80000c86 <release>
    return xticks;
}
    800032be:	02049513          	slli	a0,s1,0x20
    800032c2:	9101                	srli	a0,a0,0x20
    800032c4:	60e2                	ld	ra,24(sp)
    800032c6:	6442                	ld	s0,16(sp)
    800032c8:	64a2                	ld	s1,8(sp)
    800032ca:	6105                	addi	sp,sp,32
    800032cc:	8082                	ret

00000000800032ce <sys_ps>:

void *
sys_ps(void)
{
    800032ce:	1101                	addi	sp,sp,-32
    800032d0:	ec06                	sd	ra,24(sp)
    800032d2:	e822                	sd	s0,16(sp)
    800032d4:	1000                	addi	s0,sp,32
    int start = 0, count = 0;
    800032d6:	fe042623          	sw	zero,-20(s0)
    800032da:	fe042423          	sw	zero,-24(s0)
    argint(0, &start);
    800032de:	fec40593          	addi	a1,s0,-20
    800032e2:	4501                	li	a0,0
    800032e4:	00000097          	auipc	ra,0x0
    800032e8:	d26080e7          	jalr	-730(ra) # 8000300a <argint>
    argint(1, &count);
    800032ec:	fe840593          	addi	a1,s0,-24
    800032f0:	4505                	li	a0,1
    800032f2:	00000097          	auipc	ra,0x0
    800032f6:	d18080e7          	jalr	-744(ra) # 8000300a <argint>
    return ps((uint8)start, (uint8)count);
    800032fa:	fe844583          	lbu	a1,-24(s0)
    800032fe:	fec44503          	lbu	a0,-20(s0)
    80003302:	fffff097          	auipc	ra,0xfffff
    80003306:	d48080e7          	jalr	-696(ra) # 8000204a <ps>
}
    8000330a:	60e2                	ld	ra,24(sp)
    8000330c:	6442                	ld	s0,16(sp)
    8000330e:	6105                	addi	sp,sp,32
    80003310:	8082                	ret

0000000080003312 <sys_schedls>:

uint64 sys_schedls(void)
{
    80003312:	1141                	addi	sp,sp,-16
    80003314:	e406                	sd	ra,8(sp)
    80003316:	e022                	sd	s0,0(sp)
    80003318:	0800                	addi	s0,sp,16
    schedls();
    8000331a:	fffff097          	auipc	ra,0xfffff
    8000331e:	69c080e7          	jalr	1692(ra) # 800029b6 <schedls>
    return 0;
}
    80003322:	4501                	li	a0,0
    80003324:	60a2                	ld	ra,8(sp)
    80003326:	6402                	ld	s0,0(sp)
    80003328:	0141                	addi	sp,sp,16
    8000332a:	8082                	ret

000000008000332c <sys_schedset>:

uint64 sys_schedset(void)
{
    8000332c:	1101                	addi	sp,sp,-32
    8000332e:	ec06                	sd	ra,24(sp)
    80003330:	e822                	sd	s0,16(sp)
    80003332:	1000                	addi	s0,sp,32
    int id = 0;
    80003334:	fe042623          	sw	zero,-20(s0)
    argint(0, &id);
    80003338:	fec40593          	addi	a1,s0,-20
    8000333c:	4501                	li	a0,0
    8000333e:	00000097          	auipc	ra,0x0
    80003342:	ccc080e7          	jalr	-820(ra) # 8000300a <argint>
    schedset(id - 1);
    80003346:	fec42503          	lw	a0,-20(s0)
    8000334a:	357d                	addiw	a0,a0,-1
    8000334c:	fffff097          	auipc	ra,0xfffff
    80003350:	756080e7          	jalr	1878(ra) # 80002aa2 <schedset>
    return 0;
    80003354:	4501                	li	a0,0
    80003356:	60e2                	ld	ra,24(sp)
    80003358:	6442                	ld	s0,16(sp)
    8000335a:	6105                	addi	sp,sp,32
    8000335c:	8082                	ret

000000008000335e <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000335e:	7179                	addi	sp,sp,-48
    80003360:	f406                	sd	ra,40(sp)
    80003362:	f022                	sd	s0,32(sp)
    80003364:	ec26                	sd	s1,24(sp)
    80003366:	e84a                	sd	s2,16(sp)
    80003368:	e44e                	sd	s3,8(sp)
    8000336a:	e052                	sd	s4,0(sp)
    8000336c:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000336e:	00005597          	auipc	a1,0x5
    80003372:	27a58593          	addi	a1,a1,634 # 800085e8 <syscalls+0xc8>
    80003376:	00013517          	auipc	a0,0x13
    8000337a:	74250513          	addi	a0,a0,1858 # 80016ab8 <bcache>
    8000337e:	ffffd097          	auipc	ra,0xffffd
    80003382:	7c4080e7          	jalr	1988(ra) # 80000b42 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003386:	0001b797          	auipc	a5,0x1b
    8000338a:	73278793          	addi	a5,a5,1842 # 8001eab8 <bcache+0x8000>
    8000338e:	0001c717          	auipc	a4,0x1c
    80003392:	99270713          	addi	a4,a4,-1646 # 8001ed20 <bcache+0x8268>
    80003396:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000339a:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000339e:	00013497          	auipc	s1,0x13
    800033a2:	73248493          	addi	s1,s1,1842 # 80016ad0 <bcache+0x18>
    b->next = bcache.head.next;
    800033a6:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800033a8:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800033aa:	00005a17          	auipc	s4,0x5
    800033ae:	246a0a13          	addi	s4,s4,582 # 800085f0 <syscalls+0xd0>
    b->next = bcache.head.next;
    800033b2:	2b893783          	ld	a5,696(s2)
    800033b6:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800033b8:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800033bc:	85d2                	mv	a1,s4
    800033be:	01048513          	addi	a0,s1,16
    800033c2:	00001097          	auipc	ra,0x1
    800033c6:	496080e7          	jalr	1174(ra) # 80004858 <initsleeplock>
    bcache.head.next->prev = b;
    800033ca:	2b893783          	ld	a5,696(s2)
    800033ce:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800033d0:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800033d4:	45848493          	addi	s1,s1,1112
    800033d8:	fd349de3          	bne	s1,s3,800033b2 <binit+0x54>
  }
}
    800033dc:	70a2                	ld	ra,40(sp)
    800033de:	7402                	ld	s0,32(sp)
    800033e0:	64e2                	ld	s1,24(sp)
    800033e2:	6942                	ld	s2,16(sp)
    800033e4:	69a2                	ld	s3,8(sp)
    800033e6:	6a02                	ld	s4,0(sp)
    800033e8:	6145                	addi	sp,sp,48
    800033ea:	8082                	ret

00000000800033ec <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800033ec:	7179                	addi	sp,sp,-48
    800033ee:	f406                	sd	ra,40(sp)
    800033f0:	f022                	sd	s0,32(sp)
    800033f2:	ec26                	sd	s1,24(sp)
    800033f4:	e84a                	sd	s2,16(sp)
    800033f6:	e44e                	sd	s3,8(sp)
    800033f8:	1800                	addi	s0,sp,48
    800033fa:	892a                	mv	s2,a0
    800033fc:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800033fe:	00013517          	auipc	a0,0x13
    80003402:	6ba50513          	addi	a0,a0,1722 # 80016ab8 <bcache>
    80003406:	ffffd097          	auipc	ra,0xffffd
    8000340a:	7cc080e7          	jalr	1996(ra) # 80000bd2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000340e:	0001c497          	auipc	s1,0x1c
    80003412:	9624b483          	ld	s1,-1694(s1) # 8001ed70 <bcache+0x82b8>
    80003416:	0001c797          	auipc	a5,0x1c
    8000341a:	90a78793          	addi	a5,a5,-1782 # 8001ed20 <bcache+0x8268>
    8000341e:	02f48f63          	beq	s1,a5,8000345c <bread+0x70>
    80003422:	873e                	mv	a4,a5
    80003424:	a021                	j	8000342c <bread+0x40>
    80003426:	68a4                	ld	s1,80(s1)
    80003428:	02e48a63          	beq	s1,a4,8000345c <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000342c:	449c                	lw	a5,8(s1)
    8000342e:	ff279ce3          	bne	a5,s2,80003426 <bread+0x3a>
    80003432:	44dc                	lw	a5,12(s1)
    80003434:	ff3799e3          	bne	a5,s3,80003426 <bread+0x3a>
      b->refcnt++;
    80003438:	40bc                	lw	a5,64(s1)
    8000343a:	2785                	addiw	a5,a5,1
    8000343c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000343e:	00013517          	auipc	a0,0x13
    80003442:	67a50513          	addi	a0,a0,1658 # 80016ab8 <bcache>
    80003446:	ffffe097          	auipc	ra,0xffffe
    8000344a:	840080e7          	jalr	-1984(ra) # 80000c86 <release>
      acquiresleep(&b->lock);
    8000344e:	01048513          	addi	a0,s1,16
    80003452:	00001097          	auipc	ra,0x1
    80003456:	440080e7          	jalr	1088(ra) # 80004892 <acquiresleep>
      return b;
    8000345a:	a8b9                	j	800034b8 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000345c:	0001c497          	auipc	s1,0x1c
    80003460:	90c4b483          	ld	s1,-1780(s1) # 8001ed68 <bcache+0x82b0>
    80003464:	0001c797          	auipc	a5,0x1c
    80003468:	8bc78793          	addi	a5,a5,-1860 # 8001ed20 <bcache+0x8268>
    8000346c:	00f48863          	beq	s1,a5,8000347c <bread+0x90>
    80003470:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003472:	40bc                	lw	a5,64(s1)
    80003474:	cf81                	beqz	a5,8000348c <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003476:	64a4                	ld	s1,72(s1)
    80003478:	fee49de3          	bne	s1,a4,80003472 <bread+0x86>
  panic("bget: no buffers");
    8000347c:	00005517          	auipc	a0,0x5
    80003480:	17c50513          	addi	a0,a0,380 # 800085f8 <syscalls+0xd8>
    80003484:	ffffd097          	auipc	ra,0xffffd
    80003488:	0b8080e7          	jalr	184(ra) # 8000053c <panic>
      b->dev = dev;
    8000348c:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003490:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003494:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003498:	4785                	li	a5,1
    8000349a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000349c:	00013517          	auipc	a0,0x13
    800034a0:	61c50513          	addi	a0,a0,1564 # 80016ab8 <bcache>
    800034a4:	ffffd097          	auipc	ra,0xffffd
    800034a8:	7e2080e7          	jalr	2018(ra) # 80000c86 <release>
      acquiresleep(&b->lock);
    800034ac:	01048513          	addi	a0,s1,16
    800034b0:	00001097          	auipc	ra,0x1
    800034b4:	3e2080e7          	jalr	994(ra) # 80004892 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800034b8:	409c                	lw	a5,0(s1)
    800034ba:	cb89                	beqz	a5,800034cc <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800034bc:	8526                	mv	a0,s1
    800034be:	70a2                	ld	ra,40(sp)
    800034c0:	7402                	ld	s0,32(sp)
    800034c2:	64e2                	ld	s1,24(sp)
    800034c4:	6942                	ld	s2,16(sp)
    800034c6:	69a2                	ld	s3,8(sp)
    800034c8:	6145                	addi	sp,sp,48
    800034ca:	8082                	ret
    virtio_disk_rw(b, 0);
    800034cc:	4581                	li	a1,0
    800034ce:	8526                	mv	a0,s1
    800034d0:	00003097          	auipc	ra,0x3
    800034d4:	f82080e7          	jalr	-126(ra) # 80006452 <virtio_disk_rw>
    b->valid = 1;
    800034d8:	4785                	li	a5,1
    800034da:	c09c                	sw	a5,0(s1)
  return b;
    800034dc:	b7c5                	j	800034bc <bread+0xd0>

00000000800034de <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800034de:	1101                	addi	sp,sp,-32
    800034e0:	ec06                	sd	ra,24(sp)
    800034e2:	e822                	sd	s0,16(sp)
    800034e4:	e426                	sd	s1,8(sp)
    800034e6:	1000                	addi	s0,sp,32
    800034e8:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800034ea:	0541                	addi	a0,a0,16
    800034ec:	00001097          	auipc	ra,0x1
    800034f0:	440080e7          	jalr	1088(ra) # 8000492c <holdingsleep>
    800034f4:	cd01                	beqz	a0,8000350c <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800034f6:	4585                	li	a1,1
    800034f8:	8526                	mv	a0,s1
    800034fa:	00003097          	auipc	ra,0x3
    800034fe:	f58080e7          	jalr	-168(ra) # 80006452 <virtio_disk_rw>
}
    80003502:	60e2                	ld	ra,24(sp)
    80003504:	6442                	ld	s0,16(sp)
    80003506:	64a2                	ld	s1,8(sp)
    80003508:	6105                	addi	sp,sp,32
    8000350a:	8082                	ret
    panic("bwrite");
    8000350c:	00005517          	auipc	a0,0x5
    80003510:	10450513          	addi	a0,a0,260 # 80008610 <syscalls+0xf0>
    80003514:	ffffd097          	auipc	ra,0xffffd
    80003518:	028080e7          	jalr	40(ra) # 8000053c <panic>

000000008000351c <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000351c:	1101                	addi	sp,sp,-32
    8000351e:	ec06                	sd	ra,24(sp)
    80003520:	e822                	sd	s0,16(sp)
    80003522:	e426                	sd	s1,8(sp)
    80003524:	e04a                	sd	s2,0(sp)
    80003526:	1000                	addi	s0,sp,32
    80003528:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000352a:	01050913          	addi	s2,a0,16
    8000352e:	854a                	mv	a0,s2
    80003530:	00001097          	auipc	ra,0x1
    80003534:	3fc080e7          	jalr	1020(ra) # 8000492c <holdingsleep>
    80003538:	c925                	beqz	a0,800035a8 <brelse+0x8c>
    panic("brelse");

  releasesleep(&b->lock);
    8000353a:	854a                	mv	a0,s2
    8000353c:	00001097          	auipc	ra,0x1
    80003540:	3ac080e7          	jalr	940(ra) # 800048e8 <releasesleep>

  acquire(&bcache.lock);
    80003544:	00013517          	auipc	a0,0x13
    80003548:	57450513          	addi	a0,a0,1396 # 80016ab8 <bcache>
    8000354c:	ffffd097          	auipc	ra,0xffffd
    80003550:	686080e7          	jalr	1670(ra) # 80000bd2 <acquire>
  b->refcnt--;
    80003554:	40bc                	lw	a5,64(s1)
    80003556:	37fd                	addiw	a5,a5,-1
    80003558:	0007871b          	sext.w	a4,a5
    8000355c:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000355e:	e71d                	bnez	a4,8000358c <brelse+0x70>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003560:	68b8                	ld	a4,80(s1)
    80003562:	64bc                	ld	a5,72(s1)
    80003564:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    80003566:	68b8                	ld	a4,80(s1)
    80003568:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000356a:	0001b797          	auipc	a5,0x1b
    8000356e:	54e78793          	addi	a5,a5,1358 # 8001eab8 <bcache+0x8000>
    80003572:	2b87b703          	ld	a4,696(a5)
    80003576:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003578:	0001b717          	auipc	a4,0x1b
    8000357c:	7a870713          	addi	a4,a4,1960 # 8001ed20 <bcache+0x8268>
    80003580:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003582:	2b87b703          	ld	a4,696(a5)
    80003586:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003588:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000358c:	00013517          	auipc	a0,0x13
    80003590:	52c50513          	addi	a0,a0,1324 # 80016ab8 <bcache>
    80003594:	ffffd097          	auipc	ra,0xffffd
    80003598:	6f2080e7          	jalr	1778(ra) # 80000c86 <release>
}
    8000359c:	60e2                	ld	ra,24(sp)
    8000359e:	6442                	ld	s0,16(sp)
    800035a0:	64a2                	ld	s1,8(sp)
    800035a2:	6902                	ld	s2,0(sp)
    800035a4:	6105                	addi	sp,sp,32
    800035a6:	8082                	ret
    panic("brelse");
    800035a8:	00005517          	auipc	a0,0x5
    800035ac:	07050513          	addi	a0,a0,112 # 80008618 <syscalls+0xf8>
    800035b0:	ffffd097          	auipc	ra,0xffffd
    800035b4:	f8c080e7          	jalr	-116(ra) # 8000053c <panic>

00000000800035b8 <bpin>:

void
bpin(struct buf *b) {
    800035b8:	1101                	addi	sp,sp,-32
    800035ba:	ec06                	sd	ra,24(sp)
    800035bc:	e822                	sd	s0,16(sp)
    800035be:	e426                	sd	s1,8(sp)
    800035c0:	1000                	addi	s0,sp,32
    800035c2:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800035c4:	00013517          	auipc	a0,0x13
    800035c8:	4f450513          	addi	a0,a0,1268 # 80016ab8 <bcache>
    800035cc:	ffffd097          	auipc	ra,0xffffd
    800035d0:	606080e7          	jalr	1542(ra) # 80000bd2 <acquire>
  b->refcnt++;
    800035d4:	40bc                	lw	a5,64(s1)
    800035d6:	2785                	addiw	a5,a5,1
    800035d8:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800035da:	00013517          	auipc	a0,0x13
    800035de:	4de50513          	addi	a0,a0,1246 # 80016ab8 <bcache>
    800035e2:	ffffd097          	auipc	ra,0xffffd
    800035e6:	6a4080e7          	jalr	1700(ra) # 80000c86 <release>
}
    800035ea:	60e2                	ld	ra,24(sp)
    800035ec:	6442                	ld	s0,16(sp)
    800035ee:	64a2                	ld	s1,8(sp)
    800035f0:	6105                	addi	sp,sp,32
    800035f2:	8082                	ret

00000000800035f4 <bunpin>:

void
bunpin(struct buf *b) {
    800035f4:	1101                	addi	sp,sp,-32
    800035f6:	ec06                	sd	ra,24(sp)
    800035f8:	e822                	sd	s0,16(sp)
    800035fa:	e426                	sd	s1,8(sp)
    800035fc:	1000                	addi	s0,sp,32
    800035fe:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003600:	00013517          	auipc	a0,0x13
    80003604:	4b850513          	addi	a0,a0,1208 # 80016ab8 <bcache>
    80003608:	ffffd097          	auipc	ra,0xffffd
    8000360c:	5ca080e7          	jalr	1482(ra) # 80000bd2 <acquire>
  b->refcnt--;
    80003610:	40bc                	lw	a5,64(s1)
    80003612:	37fd                	addiw	a5,a5,-1
    80003614:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003616:	00013517          	auipc	a0,0x13
    8000361a:	4a250513          	addi	a0,a0,1186 # 80016ab8 <bcache>
    8000361e:	ffffd097          	auipc	ra,0xffffd
    80003622:	668080e7          	jalr	1640(ra) # 80000c86 <release>
}
    80003626:	60e2                	ld	ra,24(sp)
    80003628:	6442                	ld	s0,16(sp)
    8000362a:	64a2                	ld	s1,8(sp)
    8000362c:	6105                	addi	sp,sp,32
    8000362e:	8082                	ret

0000000080003630 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003630:	1101                	addi	sp,sp,-32
    80003632:	ec06                	sd	ra,24(sp)
    80003634:	e822                	sd	s0,16(sp)
    80003636:	e426                	sd	s1,8(sp)
    80003638:	e04a                	sd	s2,0(sp)
    8000363a:	1000                	addi	s0,sp,32
    8000363c:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000363e:	00d5d59b          	srliw	a1,a1,0xd
    80003642:	0001c797          	auipc	a5,0x1c
    80003646:	b527a783          	lw	a5,-1198(a5) # 8001f194 <sb+0x1c>
    8000364a:	9dbd                	addw	a1,a1,a5
    8000364c:	00000097          	auipc	ra,0x0
    80003650:	da0080e7          	jalr	-608(ra) # 800033ec <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003654:	0074f713          	andi	a4,s1,7
    80003658:	4785                	li	a5,1
    8000365a:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000365e:	14ce                	slli	s1,s1,0x33
    80003660:	90d9                	srli	s1,s1,0x36
    80003662:	00950733          	add	a4,a0,s1
    80003666:	05874703          	lbu	a4,88(a4)
    8000366a:	00e7f6b3          	and	a3,a5,a4
    8000366e:	c69d                	beqz	a3,8000369c <bfree+0x6c>
    80003670:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003672:	94aa                	add	s1,s1,a0
    80003674:	fff7c793          	not	a5,a5
    80003678:	8f7d                	and	a4,a4,a5
    8000367a:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    8000367e:	00001097          	auipc	ra,0x1
    80003682:	0f6080e7          	jalr	246(ra) # 80004774 <log_write>
  brelse(bp);
    80003686:	854a                	mv	a0,s2
    80003688:	00000097          	auipc	ra,0x0
    8000368c:	e94080e7          	jalr	-364(ra) # 8000351c <brelse>
}
    80003690:	60e2                	ld	ra,24(sp)
    80003692:	6442                	ld	s0,16(sp)
    80003694:	64a2                	ld	s1,8(sp)
    80003696:	6902                	ld	s2,0(sp)
    80003698:	6105                	addi	sp,sp,32
    8000369a:	8082                	ret
    panic("freeing free block");
    8000369c:	00005517          	auipc	a0,0x5
    800036a0:	f8450513          	addi	a0,a0,-124 # 80008620 <syscalls+0x100>
    800036a4:	ffffd097          	auipc	ra,0xffffd
    800036a8:	e98080e7          	jalr	-360(ra) # 8000053c <panic>

00000000800036ac <balloc>:
{
    800036ac:	711d                	addi	sp,sp,-96
    800036ae:	ec86                	sd	ra,88(sp)
    800036b0:	e8a2                	sd	s0,80(sp)
    800036b2:	e4a6                	sd	s1,72(sp)
    800036b4:	e0ca                	sd	s2,64(sp)
    800036b6:	fc4e                	sd	s3,56(sp)
    800036b8:	f852                	sd	s4,48(sp)
    800036ba:	f456                	sd	s5,40(sp)
    800036bc:	f05a                	sd	s6,32(sp)
    800036be:	ec5e                	sd	s7,24(sp)
    800036c0:	e862                	sd	s8,16(sp)
    800036c2:	e466                	sd	s9,8(sp)
    800036c4:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800036c6:	0001c797          	auipc	a5,0x1c
    800036ca:	ab67a783          	lw	a5,-1354(a5) # 8001f17c <sb+0x4>
    800036ce:	cff5                	beqz	a5,800037ca <balloc+0x11e>
    800036d0:	8baa                	mv	s7,a0
    800036d2:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800036d4:	0001cb17          	auipc	s6,0x1c
    800036d8:	aa4b0b13          	addi	s6,s6,-1372 # 8001f178 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800036dc:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800036de:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800036e0:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800036e2:	6c89                	lui	s9,0x2
    800036e4:	a061                	j	8000376c <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    800036e6:	97ca                	add	a5,a5,s2
    800036e8:	8e55                	or	a2,a2,a3
    800036ea:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    800036ee:	854a                	mv	a0,s2
    800036f0:	00001097          	auipc	ra,0x1
    800036f4:	084080e7          	jalr	132(ra) # 80004774 <log_write>
        brelse(bp);
    800036f8:	854a                	mv	a0,s2
    800036fa:	00000097          	auipc	ra,0x0
    800036fe:	e22080e7          	jalr	-478(ra) # 8000351c <brelse>
  bp = bread(dev, bno);
    80003702:	85a6                	mv	a1,s1
    80003704:	855e                	mv	a0,s7
    80003706:	00000097          	auipc	ra,0x0
    8000370a:	ce6080e7          	jalr	-794(ra) # 800033ec <bread>
    8000370e:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003710:	40000613          	li	a2,1024
    80003714:	4581                	li	a1,0
    80003716:	05850513          	addi	a0,a0,88
    8000371a:	ffffd097          	auipc	ra,0xffffd
    8000371e:	5b4080e7          	jalr	1460(ra) # 80000cce <memset>
  log_write(bp);
    80003722:	854a                	mv	a0,s2
    80003724:	00001097          	auipc	ra,0x1
    80003728:	050080e7          	jalr	80(ra) # 80004774 <log_write>
  brelse(bp);
    8000372c:	854a                	mv	a0,s2
    8000372e:	00000097          	auipc	ra,0x0
    80003732:	dee080e7          	jalr	-530(ra) # 8000351c <brelse>
}
    80003736:	8526                	mv	a0,s1
    80003738:	60e6                	ld	ra,88(sp)
    8000373a:	6446                	ld	s0,80(sp)
    8000373c:	64a6                	ld	s1,72(sp)
    8000373e:	6906                	ld	s2,64(sp)
    80003740:	79e2                	ld	s3,56(sp)
    80003742:	7a42                	ld	s4,48(sp)
    80003744:	7aa2                	ld	s5,40(sp)
    80003746:	7b02                	ld	s6,32(sp)
    80003748:	6be2                	ld	s7,24(sp)
    8000374a:	6c42                	ld	s8,16(sp)
    8000374c:	6ca2                	ld	s9,8(sp)
    8000374e:	6125                	addi	sp,sp,96
    80003750:	8082                	ret
    brelse(bp);
    80003752:	854a                	mv	a0,s2
    80003754:	00000097          	auipc	ra,0x0
    80003758:	dc8080e7          	jalr	-568(ra) # 8000351c <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000375c:	015c87bb          	addw	a5,s9,s5
    80003760:	00078a9b          	sext.w	s5,a5
    80003764:	004b2703          	lw	a4,4(s6)
    80003768:	06eaf163          	bgeu	s5,a4,800037ca <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    8000376c:	41fad79b          	sraiw	a5,s5,0x1f
    80003770:	0137d79b          	srliw	a5,a5,0x13
    80003774:	015787bb          	addw	a5,a5,s5
    80003778:	40d7d79b          	sraiw	a5,a5,0xd
    8000377c:	01cb2583          	lw	a1,28(s6)
    80003780:	9dbd                	addw	a1,a1,a5
    80003782:	855e                	mv	a0,s7
    80003784:	00000097          	auipc	ra,0x0
    80003788:	c68080e7          	jalr	-920(ra) # 800033ec <bread>
    8000378c:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000378e:	004b2503          	lw	a0,4(s6)
    80003792:	000a849b          	sext.w	s1,s5
    80003796:	8762                	mv	a4,s8
    80003798:	faa4fde3          	bgeu	s1,a0,80003752 <balloc+0xa6>
      m = 1 << (bi % 8);
    8000379c:	00777693          	andi	a3,a4,7
    800037a0:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800037a4:	41f7579b          	sraiw	a5,a4,0x1f
    800037a8:	01d7d79b          	srliw	a5,a5,0x1d
    800037ac:	9fb9                	addw	a5,a5,a4
    800037ae:	4037d79b          	sraiw	a5,a5,0x3
    800037b2:	00f90633          	add	a2,s2,a5
    800037b6:	05864603          	lbu	a2,88(a2)
    800037ba:	00c6f5b3          	and	a1,a3,a2
    800037be:	d585                	beqz	a1,800036e6 <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800037c0:	2705                	addiw	a4,a4,1
    800037c2:	2485                	addiw	s1,s1,1
    800037c4:	fd471ae3          	bne	a4,s4,80003798 <balloc+0xec>
    800037c8:	b769                	j	80003752 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    800037ca:	00005517          	auipc	a0,0x5
    800037ce:	e6e50513          	addi	a0,a0,-402 # 80008638 <syscalls+0x118>
    800037d2:	ffffd097          	auipc	ra,0xffffd
    800037d6:	db4080e7          	jalr	-588(ra) # 80000586 <printf>
  return 0;
    800037da:	4481                	li	s1,0
    800037dc:	bfa9                	j	80003736 <balloc+0x8a>

00000000800037de <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    800037de:	7179                	addi	sp,sp,-48
    800037e0:	f406                	sd	ra,40(sp)
    800037e2:	f022                	sd	s0,32(sp)
    800037e4:	ec26                	sd	s1,24(sp)
    800037e6:	e84a                	sd	s2,16(sp)
    800037e8:	e44e                	sd	s3,8(sp)
    800037ea:	e052                	sd	s4,0(sp)
    800037ec:	1800                	addi	s0,sp,48
    800037ee:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800037f0:	47ad                	li	a5,11
    800037f2:	02b7e863          	bltu	a5,a1,80003822 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    800037f6:	02059793          	slli	a5,a1,0x20
    800037fa:	01e7d593          	srli	a1,a5,0x1e
    800037fe:	00b504b3          	add	s1,a0,a1
    80003802:	0504a903          	lw	s2,80(s1)
    80003806:	06091e63          	bnez	s2,80003882 <bmap+0xa4>
      addr = balloc(ip->dev);
    8000380a:	4108                	lw	a0,0(a0)
    8000380c:	00000097          	auipc	ra,0x0
    80003810:	ea0080e7          	jalr	-352(ra) # 800036ac <balloc>
    80003814:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003818:	06090563          	beqz	s2,80003882 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    8000381c:	0524a823          	sw	s2,80(s1)
    80003820:	a08d                	j	80003882 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003822:	ff45849b          	addiw	s1,a1,-12
    80003826:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000382a:	0ff00793          	li	a5,255
    8000382e:	08e7e563          	bltu	a5,a4,800038b8 <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003832:	08052903          	lw	s2,128(a0)
    80003836:	00091d63          	bnez	s2,80003850 <bmap+0x72>
      addr = balloc(ip->dev);
    8000383a:	4108                	lw	a0,0(a0)
    8000383c:	00000097          	auipc	ra,0x0
    80003840:	e70080e7          	jalr	-400(ra) # 800036ac <balloc>
    80003844:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003848:	02090d63          	beqz	s2,80003882 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    8000384c:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003850:	85ca                	mv	a1,s2
    80003852:	0009a503          	lw	a0,0(s3)
    80003856:	00000097          	auipc	ra,0x0
    8000385a:	b96080e7          	jalr	-1130(ra) # 800033ec <bread>
    8000385e:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003860:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003864:	02049713          	slli	a4,s1,0x20
    80003868:	01e75593          	srli	a1,a4,0x1e
    8000386c:	00b784b3          	add	s1,a5,a1
    80003870:	0004a903          	lw	s2,0(s1)
    80003874:	02090063          	beqz	s2,80003894 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003878:	8552                	mv	a0,s4
    8000387a:	00000097          	auipc	ra,0x0
    8000387e:	ca2080e7          	jalr	-862(ra) # 8000351c <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003882:	854a                	mv	a0,s2
    80003884:	70a2                	ld	ra,40(sp)
    80003886:	7402                	ld	s0,32(sp)
    80003888:	64e2                	ld	s1,24(sp)
    8000388a:	6942                	ld	s2,16(sp)
    8000388c:	69a2                	ld	s3,8(sp)
    8000388e:	6a02                	ld	s4,0(sp)
    80003890:	6145                	addi	sp,sp,48
    80003892:	8082                	ret
      addr = balloc(ip->dev);
    80003894:	0009a503          	lw	a0,0(s3)
    80003898:	00000097          	auipc	ra,0x0
    8000389c:	e14080e7          	jalr	-492(ra) # 800036ac <balloc>
    800038a0:	0005091b          	sext.w	s2,a0
      if(addr){
    800038a4:	fc090ae3          	beqz	s2,80003878 <bmap+0x9a>
        a[bn] = addr;
    800038a8:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    800038ac:	8552                	mv	a0,s4
    800038ae:	00001097          	auipc	ra,0x1
    800038b2:	ec6080e7          	jalr	-314(ra) # 80004774 <log_write>
    800038b6:	b7c9                	j	80003878 <bmap+0x9a>
  panic("bmap: out of range");
    800038b8:	00005517          	auipc	a0,0x5
    800038bc:	d9850513          	addi	a0,a0,-616 # 80008650 <syscalls+0x130>
    800038c0:	ffffd097          	auipc	ra,0xffffd
    800038c4:	c7c080e7          	jalr	-900(ra) # 8000053c <panic>

00000000800038c8 <iget>:
{
    800038c8:	7179                	addi	sp,sp,-48
    800038ca:	f406                	sd	ra,40(sp)
    800038cc:	f022                	sd	s0,32(sp)
    800038ce:	ec26                	sd	s1,24(sp)
    800038d0:	e84a                	sd	s2,16(sp)
    800038d2:	e44e                	sd	s3,8(sp)
    800038d4:	e052                	sd	s4,0(sp)
    800038d6:	1800                	addi	s0,sp,48
    800038d8:	89aa                	mv	s3,a0
    800038da:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800038dc:	0001c517          	auipc	a0,0x1c
    800038e0:	8bc50513          	addi	a0,a0,-1860 # 8001f198 <itable>
    800038e4:	ffffd097          	auipc	ra,0xffffd
    800038e8:	2ee080e7          	jalr	750(ra) # 80000bd2 <acquire>
  empty = 0;
    800038ec:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800038ee:	0001c497          	auipc	s1,0x1c
    800038f2:	8c248493          	addi	s1,s1,-1854 # 8001f1b0 <itable+0x18>
    800038f6:	0001d697          	auipc	a3,0x1d
    800038fa:	34a68693          	addi	a3,a3,842 # 80020c40 <log>
    800038fe:	a039                	j	8000390c <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003900:	02090b63          	beqz	s2,80003936 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003904:	08848493          	addi	s1,s1,136
    80003908:	02d48a63          	beq	s1,a3,8000393c <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000390c:	449c                	lw	a5,8(s1)
    8000390e:	fef059e3          	blez	a5,80003900 <iget+0x38>
    80003912:	4098                	lw	a4,0(s1)
    80003914:	ff3716e3          	bne	a4,s3,80003900 <iget+0x38>
    80003918:	40d8                	lw	a4,4(s1)
    8000391a:	ff4713e3          	bne	a4,s4,80003900 <iget+0x38>
      ip->ref++;
    8000391e:	2785                	addiw	a5,a5,1
    80003920:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003922:	0001c517          	auipc	a0,0x1c
    80003926:	87650513          	addi	a0,a0,-1930 # 8001f198 <itable>
    8000392a:	ffffd097          	auipc	ra,0xffffd
    8000392e:	35c080e7          	jalr	860(ra) # 80000c86 <release>
      return ip;
    80003932:	8926                	mv	s2,s1
    80003934:	a03d                	j	80003962 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003936:	f7f9                	bnez	a5,80003904 <iget+0x3c>
    80003938:	8926                	mv	s2,s1
    8000393a:	b7e9                	j	80003904 <iget+0x3c>
  if(empty == 0)
    8000393c:	02090c63          	beqz	s2,80003974 <iget+0xac>
  ip->dev = dev;
    80003940:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003944:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003948:	4785                	li	a5,1
    8000394a:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000394e:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003952:	0001c517          	auipc	a0,0x1c
    80003956:	84650513          	addi	a0,a0,-1978 # 8001f198 <itable>
    8000395a:	ffffd097          	auipc	ra,0xffffd
    8000395e:	32c080e7          	jalr	812(ra) # 80000c86 <release>
}
    80003962:	854a                	mv	a0,s2
    80003964:	70a2                	ld	ra,40(sp)
    80003966:	7402                	ld	s0,32(sp)
    80003968:	64e2                	ld	s1,24(sp)
    8000396a:	6942                	ld	s2,16(sp)
    8000396c:	69a2                	ld	s3,8(sp)
    8000396e:	6a02                	ld	s4,0(sp)
    80003970:	6145                	addi	sp,sp,48
    80003972:	8082                	ret
    panic("iget: no inodes");
    80003974:	00005517          	auipc	a0,0x5
    80003978:	cf450513          	addi	a0,a0,-780 # 80008668 <syscalls+0x148>
    8000397c:	ffffd097          	auipc	ra,0xffffd
    80003980:	bc0080e7          	jalr	-1088(ra) # 8000053c <panic>

0000000080003984 <fsinit>:
fsinit(int dev) {
    80003984:	7179                	addi	sp,sp,-48
    80003986:	f406                	sd	ra,40(sp)
    80003988:	f022                	sd	s0,32(sp)
    8000398a:	ec26                	sd	s1,24(sp)
    8000398c:	e84a                	sd	s2,16(sp)
    8000398e:	e44e                	sd	s3,8(sp)
    80003990:	1800                	addi	s0,sp,48
    80003992:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003994:	4585                	li	a1,1
    80003996:	00000097          	auipc	ra,0x0
    8000399a:	a56080e7          	jalr	-1450(ra) # 800033ec <bread>
    8000399e:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800039a0:	0001b997          	auipc	s3,0x1b
    800039a4:	7d898993          	addi	s3,s3,2008 # 8001f178 <sb>
    800039a8:	02000613          	li	a2,32
    800039ac:	05850593          	addi	a1,a0,88
    800039b0:	854e                	mv	a0,s3
    800039b2:	ffffd097          	auipc	ra,0xffffd
    800039b6:	378080e7          	jalr	888(ra) # 80000d2a <memmove>
  brelse(bp);
    800039ba:	8526                	mv	a0,s1
    800039bc:	00000097          	auipc	ra,0x0
    800039c0:	b60080e7          	jalr	-1184(ra) # 8000351c <brelse>
  if(sb.magic != FSMAGIC)
    800039c4:	0009a703          	lw	a4,0(s3)
    800039c8:	102037b7          	lui	a5,0x10203
    800039cc:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800039d0:	02f71263          	bne	a4,a5,800039f4 <fsinit+0x70>
  initlog(dev, &sb);
    800039d4:	0001b597          	auipc	a1,0x1b
    800039d8:	7a458593          	addi	a1,a1,1956 # 8001f178 <sb>
    800039dc:	854a                	mv	a0,s2
    800039de:	00001097          	auipc	ra,0x1
    800039e2:	b2c080e7          	jalr	-1236(ra) # 8000450a <initlog>
}
    800039e6:	70a2                	ld	ra,40(sp)
    800039e8:	7402                	ld	s0,32(sp)
    800039ea:	64e2                	ld	s1,24(sp)
    800039ec:	6942                	ld	s2,16(sp)
    800039ee:	69a2                	ld	s3,8(sp)
    800039f0:	6145                	addi	sp,sp,48
    800039f2:	8082                	ret
    panic("invalid file system");
    800039f4:	00005517          	auipc	a0,0x5
    800039f8:	c8450513          	addi	a0,a0,-892 # 80008678 <syscalls+0x158>
    800039fc:	ffffd097          	auipc	ra,0xffffd
    80003a00:	b40080e7          	jalr	-1216(ra) # 8000053c <panic>

0000000080003a04 <iinit>:
{
    80003a04:	7179                	addi	sp,sp,-48
    80003a06:	f406                	sd	ra,40(sp)
    80003a08:	f022                	sd	s0,32(sp)
    80003a0a:	ec26                	sd	s1,24(sp)
    80003a0c:	e84a                	sd	s2,16(sp)
    80003a0e:	e44e                	sd	s3,8(sp)
    80003a10:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003a12:	00005597          	auipc	a1,0x5
    80003a16:	c7e58593          	addi	a1,a1,-898 # 80008690 <syscalls+0x170>
    80003a1a:	0001b517          	auipc	a0,0x1b
    80003a1e:	77e50513          	addi	a0,a0,1918 # 8001f198 <itable>
    80003a22:	ffffd097          	auipc	ra,0xffffd
    80003a26:	120080e7          	jalr	288(ra) # 80000b42 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003a2a:	0001b497          	auipc	s1,0x1b
    80003a2e:	79648493          	addi	s1,s1,1942 # 8001f1c0 <itable+0x28>
    80003a32:	0001d997          	auipc	s3,0x1d
    80003a36:	21e98993          	addi	s3,s3,542 # 80020c50 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003a3a:	00005917          	auipc	s2,0x5
    80003a3e:	c5e90913          	addi	s2,s2,-930 # 80008698 <syscalls+0x178>
    80003a42:	85ca                	mv	a1,s2
    80003a44:	8526                	mv	a0,s1
    80003a46:	00001097          	auipc	ra,0x1
    80003a4a:	e12080e7          	jalr	-494(ra) # 80004858 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003a4e:	08848493          	addi	s1,s1,136
    80003a52:	ff3498e3          	bne	s1,s3,80003a42 <iinit+0x3e>
}
    80003a56:	70a2                	ld	ra,40(sp)
    80003a58:	7402                	ld	s0,32(sp)
    80003a5a:	64e2                	ld	s1,24(sp)
    80003a5c:	6942                	ld	s2,16(sp)
    80003a5e:	69a2                	ld	s3,8(sp)
    80003a60:	6145                	addi	sp,sp,48
    80003a62:	8082                	ret

0000000080003a64 <ialloc>:
{
    80003a64:	7139                	addi	sp,sp,-64
    80003a66:	fc06                	sd	ra,56(sp)
    80003a68:	f822                	sd	s0,48(sp)
    80003a6a:	f426                	sd	s1,40(sp)
    80003a6c:	f04a                	sd	s2,32(sp)
    80003a6e:	ec4e                	sd	s3,24(sp)
    80003a70:	e852                	sd	s4,16(sp)
    80003a72:	e456                	sd	s5,8(sp)
    80003a74:	e05a                	sd	s6,0(sp)
    80003a76:	0080                	addi	s0,sp,64
  for(inum = 1; inum < sb.ninodes; inum++){
    80003a78:	0001b717          	auipc	a4,0x1b
    80003a7c:	70c72703          	lw	a4,1804(a4) # 8001f184 <sb+0xc>
    80003a80:	4785                	li	a5,1
    80003a82:	04e7f863          	bgeu	a5,a4,80003ad2 <ialloc+0x6e>
    80003a86:	8aaa                	mv	s5,a0
    80003a88:	8b2e                	mv	s6,a1
    80003a8a:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003a8c:	0001ba17          	auipc	s4,0x1b
    80003a90:	6eca0a13          	addi	s4,s4,1772 # 8001f178 <sb>
    80003a94:	00495593          	srli	a1,s2,0x4
    80003a98:	018a2783          	lw	a5,24(s4)
    80003a9c:	9dbd                	addw	a1,a1,a5
    80003a9e:	8556                	mv	a0,s5
    80003aa0:	00000097          	auipc	ra,0x0
    80003aa4:	94c080e7          	jalr	-1716(ra) # 800033ec <bread>
    80003aa8:	84aa                	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003aaa:	05850993          	addi	s3,a0,88
    80003aae:	00f97793          	andi	a5,s2,15
    80003ab2:	079a                	slli	a5,a5,0x6
    80003ab4:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003ab6:	00099783          	lh	a5,0(s3)
    80003aba:	cf9d                	beqz	a5,80003af8 <ialloc+0x94>
    brelse(bp);
    80003abc:	00000097          	auipc	ra,0x0
    80003ac0:	a60080e7          	jalr	-1440(ra) # 8000351c <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003ac4:	0905                	addi	s2,s2,1
    80003ac6:	00ca2703          	lw	a4,12(s4)
    80003aca:	0009079b          	sext.w	a5,s2
    80003ace:	fce7e3e3          	bltu	a5,a4,80003a94 <ialloc+0x30>
  printf("ialloc: no inodes\n");
    80003ad2:	00005517          	auipc	a0,0x5
    80003ad6:	bce50513          	addi	a0,a0,-1074 # 800086a0 <syscalls+0x180>
    80003ada:	ffffd097          	auipc	ra,0xffffd
    80003ade:	aac080e7          	jalr	-1364(ra) # 80000586 <printf>
  return 0;
    80003ae2:	4501                	li	a0,0
}
    80003ae4:	70e2                	ld	ra,56(sp)
    80003ae6:	7442                	ld	s0,48(sp)
    80003ae8:	74a2                	ld	s1,40(sp)
    80003aea:	7902                	ld	s2,32(sp)
    80003aec:	69e2                	ld	s3,24(sp)
    80003aee:	6a42                	ld	s4,16(sp)
    80003af0:	6aa2                	ld	s5,8(sp)
    80003af2:	6b02                	ld	s6,0(sp)
    80003af4:	6121                	addi	sp,sp,64
    80003af6:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003af8:	04000613          	li	a2,64
    80003afc:	4581                	li	a1,0
    80003afe:	854e                	mv	a0,s3
    80003b00:	ffffd097          	auipc	ra,0xffffd
    80003b04:	1ce080e7          	jalr	462(ra) # 80000cce <memset>
      dip->type = type;
    80003b08:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003b0c:	8526                	mv	a0,s1
    80003b0e:	00001097          	auipc	ra,0x1
    80003b12:	c66080e7          	jalr	-922(ra) # 80004774 <log_write>
      brelse(bp);
    80003b16:	8526                	mv	a0,s1
    80003b18:	00000097          	auipc	ra,0x0
    80003b1c:	a04080e7          	jalr	-1532(ra) # 8000351c <brelse>
      return iget(dev, inum);
    80003b20:	0009059b          	sext.w	a1,s2
    80003b24:	8556                	mv	a0,s5
    80003b26:	00000097          	auipc	ra,0x0
    80003b2a:	da2080e7          	jalr	-606(ra) # 800038c8 <iget>
    80003b2e:	bf5d                	j	80003ae4 <ialloc+0x80>

0000000080003b30 <iupdate>:
{
    80003b30:	1101                	addi	sp,sp,-32
    80003b32:	ec06                	sd	ra,24(sp)
    80003b34:	e822                	sd	s0,16(sp)
    80003b36:	e426                	sd	s1,8(sp)
    80003b38:	e04a                	sd	s2,0(sp)
    80003b3a:	1000                	addi	s0,sp,32
    80003b3c:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003b3e:	415c                	lw	a5,4(a0)
    80003b40:	0047d79b          	srliw	a5,a5,0x4
    80003b44:	0001b597          	auipc	a1,0x1b
    80003b48:	64c5a583          	lw	a1,1612(a1) # 8001f190 <sb+0x18>
    80003b4c:	9dbd                	addw	a1,a1,a5
    80003b4e:	4108                	lw	a0,0(a0)
    80003b50:	00000097          	auipc	ra,0x0
    80003b54:	89c080e7          	jalr	-1892(ra) # 800033ec <bread>
    80003b58:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003b5a:	05850793          	addi	a5,a0,88
    80003b5e:	40d8                	lw	a4,4(s1)
    80003b60:	8b3d                	andi	a4,a4,15
    80003b62:	071a                	slli	a4,a4,0x6
    80003b64:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003b66:	04449703          	lh	a4,68(s1)
    80003b6a:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003b6e:	04649703          	lh	a4,70(s1)
    80003b72:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003b76:	04849703          	lh	a4,72(s1)
    80003b7a:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003b7e:	04a49703          	lh	a4,74(s1)
    80003b82:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003b86:	44f8                	lw	a4,76(s1)
    80003b88:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003b8a:	03400613          	li	a2,52
    80003b8e:	05048593          	addi	a1,s1,80
    80003b92:	00c78513          	addi	a0,a5,12
    80003b96:	ffffd097          	auipc	ra,0xffffd
    80003b9a:	194080e7          	jalr	404(ra) # 80000d2a <memmove>
  log_write(bp);
    80003b9e:	854a                	mv	a0,s2
    80003ba0:	00001097          	auipc	ra,0x1
    80003ba4:	bd4080e7          	jalr	-1068(ra) # 80004774 <log_write>
  brelse(bp);
    80003ba8:	854a                	mv	a0,s2
    80003baa:	00000097          	auipc	ra,0x0
    80003bae:	972080e7          	jalr	-1678(ra) # 8000351c <brelse>
}
    80003bb2:	60e2                	ld	ra,24(sp)
    80003bb4:	6442                	ld	s0,16(sp)
    80003bb6:	64a2                	ld	s1,8(sp)
    80003bb8:	6902                	ld	s2,0(sp)
    80003bba:	6105                	addi	sp,sp,32
    80003bbc:	8082                	ret

0000000080003bbe <idup>:
{
    80003bbe:	1101                	addi	sp,sp,-32
    80003bc0:	ec06                	sd	ra,24(sp)
    80003bc2:	e822                	sd	s0,16(sp)
    80003bc4:	e426                	sd	s1,8(sp)
    80003bc6:	1000                	addi	s0,sp,32
    80003bc8:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003bca:	0001b517          	auipc	a0,0x1b
    80003bce:	5ce50513          	addi	a0,a0,1486 # 8001f198 <itable>
    80003bd2:	ffffd097          	auipc	ra,0xffffd
    80003bd6:	000080e7          	jalr	ra # 80000bd2 <acquire>
  ip->ref++;
    80003bda:	449c                	lw	a5,8(s1)
    80003bdc:	2785                	addiw	a5,a5,1
    80003bde:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003be0:	0001b517          	auipc	a0,0x1b
    80003be4:	5b850513          	addi	a0,a0,1464 # 8001f198 <itable>
    80003be8:	ffffd097          	auipc	ra,0xffffd
    80003bec:	09e080e7          	jalr	158(ra) # 80000c86 <release>
}
    80003bf0:	8526                	mv	a0,s1
    80003bf2:	60e2                	ld	ra,24(sp)
    80003bf4:	6442                	ld	s0,16(sp)
    80003bf6:	64a2                	ld	s1,8(sp)
    80003bf8:	6105                	addi	sp,sp,32
    80003bfa:	8082                	ret

0000000080003bfc <ilock>:
{
    80003bfc:	1101                	addi	sp,sp,-32
    80003bfe:	ec06                	sd	ra,24(sp)
    80003c00:	e822                	sd	s0,16(sp)
    80003c02:	e426                	sd	s1,8(sp)
    80003c04:	e04a                	sd	s2,0(sp)
    80003c06:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003c08:	c115                	beqz	a0,80003c2c <ilock+0x30>
    80003c0a:	84aa                	mv	s1,a0
    80003c0c:	451c                	lw	a5,8(a0)
    80003c0e:	00f05f63          	blez	a5,80003c2c <ilock+0x30>
  acquiresleep(&ip->lock);
    80003c12:	0541                	addi	a0,a0,16
    80003c14:	00001097          	auipc	ra,0x1
    80003c18:	c7e080e7          	jalr	-898(ra) # 80004892 <acquiresleep>
  if(ip->valid == 0){
    80003c1c:	40bc                	lw	a5,64(s1)
    80003c1e:	cf99                	beqz	a5,80003c3c <ilock+0x40>
}
    80003c20:	60e2                	ld	ra,24(sp)
    80003c22:	6442                	ld	s0,16(sp)
    80003c24:	64a2                	ld	s1,8(sp)
    80003c26:	6902                	ld	s2,0(sp)
    80003c28:	6105                	addi	sp,sp,32
    80003c2a:	8082                	ret
    panic("ilock");
    80003c2c:	00005517          	auipc	a0,0x5
    80003c30:	a8c50513          	addi	a0,a0,-1396 # 800086b8 <syscalls+0x198>
    80003c34:	ffffd097          	auipc	ra,0xffffd
    80003c38:	908080e7          	jalr	-1784(ra) # 8000053c <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003c3c:	40dc                	lw	a5,4(s1)
    80003c3e:	0047d79b          	srliw	a5,a5,0x4
    80003c42:	0001b597          	auipc	a1,0x1b
    80003c46:	54e5a583          	lw	a1,1358(a1) # 8001f190 <sb+0x18>
    80003c4a:	9dbd                	addw	a1,a1,a5
    80003c4c:	4088                	lw	a0,0(s1)
    80003c4e:	fffff097          	auipc	ra,0xfffff
    80003c52:	79e080e7          	jalr	1950(ra) # 800033ec <bread>
    80003c56:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003c58:	05850593          	addi	a1,a0,88
    80003c5c:	40dc                	lw	a5,4(s1)
    80003c5e:	8bbd                	andi	a5,a5,15
    80003c60:	079a                	slli	a5,a5,0x6
    80003c62:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003c64:	00059783          	lh	a5,0(a1)
    80003c68:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003c6c:	00259783          	lh	a5,2(a1)
    80003c70:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003c74:	00459783          	lh	a5,4(a1)
    80003c78:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003c7c:	00659783          	lh	a5,6(a1)
    80003c80:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003c84:	459c                	lw	a5,8(a1)
    80003c86:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003c88:	03400613          	li	a2,52
    80003c8c:	05b1                	addi	a1,a1,12
    80003c8e:	05048513          	addi	a0,s1,80
    80003c92:	ffffd097          	auipc	ra,0xffffd
    80003c96:	098080e7          	jalr	152(ra) # 80000d2a <memmove>
    brelse(bp);
    80003c9a:	854a                	mv	a0,s2
    80003c9c:	00000097          	auipc	ra,0x0
    80003ca0:	880080e7          	jalr	-1920(ra) # 8000351c <brelse>
    ip->valid = 1;
    80003ca4:	4785                	li	a5,1
    80003ca6:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003ca8:	04449783          	lh	a5,68(s1)
    80003cac:	fbb5                	bnez	a5,80003c20 <ilock+0x24>
      panic("ilock: no type");
    80003cae:	00005517          	auipc	a0,0x5
    80003cb2:	a1250513          	addi	a0,a0,-1518 # 800086c0 <syscalls+0x1a0>
    80003cb6:	ffffd097          	auipc	ra,0xffffd
    80003cba:	886080e7          	jalr	-1914(ra) # 8000053c <panic>

0000000080003cbe <iunlock>:
{
    80003cbe:	1101                	addi	sp,sp,-32
    80003cc0:	ec06                	sd	ra,24(sp)
    80003cc2:	e822                	sd	s0,16(sp)
    80003cc4:	e426                	sd	s1,8(sp)
    80003cc6:	e04a                	sd	s2,0(sp)
    80003cc8:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003cca:	c905                	beqz	a0,80003cfa <iunlock+0x3c>
    80003ccc:	84aa                	mv	s1,a0
    80003cce:	01050913          	addi	s2,a0,16
    80003cd2:	854a                	mv	a0,s2
    80003cd4:	00001097          	auipc	ra,0x1
    80003cd8:	c58080e7          	jalr	-936(ra) # 8000492c <holdingsleep>
    80003cdc:	cd19                	beqz	a0,80003cfa <iunlock+0x3c>
    80003cde:	449c                	lw	a5,8(s1)
    80003ce0:	00f05d63          	blez	a5,80003cfa <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003ce4:	854a                	mv	a0,s2
    80003ce6:	00001097          	auipc	ra,0x1
    80003cea:	c02080e7          	jalr	-1022(ra) # 800048e8 <releasesleep>
}
    80003cee:	60e2                	ld	ra,24(sp)
    80003cf0:	6442                	ld	s0,16(sp)
    80003cf2:	64a2                	ld	s1,8(sp)
    80003cf4:	6902                	ld	s2,0(sp)
    80003cf6:	6105                	addi	sp,sp,32
    80003cf8:	8082                	ret
    panic("iunlock");
    80003cfa:	00005517          	auipc	a0,0x5
    80003cfe:	9d650513          	addi	a0,a0,-1578 # 800086d0 <syscalls+0x1b0>
    80003d02:	ffffd097          	auipc	ra,0xffffd
    80003d06:	83a080e7          	jalr	-1990(ra) # 8000053c <panic>

0000000080003d0a <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003d0a:	7179                	addi	sp,sp,-48
    80003d0c:	f406                	sd	ra,40(sp)
    80003d0e:	f022                	sd	s0,32(sp)
    80003d10:	ec26                	sd	s1,24(sp)
    80003d12:	e84a                	sd	s2,16(sp)
    80003d14:	e44e                	sd	s3,8(sp)
    80003d16:	e052                	sd	s4,0(sp)
    80003d18:	1800                	addi	s0,sp,48
    80003d1a:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003d1c:	05050493          	addi	s1,a0,80
    80003d20:	08050913          	addi	s2,a0,128
    80003d24:	a021                	j	80003d2c <itrunc+0x22>
    80003d26:	0491                	addi	s1,s1,4
    80003d28:	01248d63          	beq	s1,s2,80003d42 <itrunc+0x38>
    if(ip->addrs[i]){
    80003d2c:	408c                	lw	a1,0(s1)
    80003d2e:	dde5                	beqz	a1,80003d26 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003d30:	0009a503          	lw	a0,0(s3)
    80003d34:	00000097          	auipc	ra,0x0
    80003d38:	8fc080e7          	jalr	-1796(ra) # 80003630 <bfree>
      ip->addrs[i] = 0;
    80003d3c:	0004a023          	sw	zero,0(s1)
    80003d40:	b7dd                	j	80003d26 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003d42:	0809a583          	lw	a1,128(s3)
    80003d46:	e185                	bnez	a1,80003d66 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003d48:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003d4c:	854e                	mv	a0,s3
    80003d4e:	00000097          	auipc	ra,0x0
    80003d52:	de2080e7          	jalr	-542(ra) # 80003b30 <iupdate>
}
    80003d56:	70a2                	ld	ra,40(sp)
    80003d58:	7402                	ld	s0,32(sp)
    80003d5a:	64e2                	ld	s1,24(sp)
    80003d5c:	6942                	ld	s2,16(sp)
    80003d5e:	69a2                	ld	s3,8(sp)
    80003d60:	6a02                	ld	s4,0(sp)
    80003d62:	6145                	addi	sp,sp,48
    80003d64:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003d66:	0009a503          	lw	a0,0(s3)
    80003d6a:	fffff097          	auipc	ra,0xfffff
    80003d6e:	682080e7          	jalr	1666(ra) # 800033ec <bread>
    80003d72:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003d74:	05850493          	addi	s1,a0,88
    80003d78:	45850913          	addi	s2,a0,1112
    80003d7c:	a021                	j	80003d84 <itrunc+0x7a>
    80003d7e:	0491                	addi	s1,s1,4
    80003d80:	01248b63          	beq	s1,s2,80003d96 <itrunc+0x8c>
      if(a[j])
    80003d84:	408c                	lw	a1,0(s1)
    80003d86:	dde5                	beqz	a1,80003d7e <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003d88:	0009a503          	lw	a0,0(s3)
    80003d8c:	00000097          	auipc	ra,0x0
    80003d90:	8a4080e7          	jalr	-1884(ra) # 80003630 <bfree>
    80003d94:	b7ed                	j	80003d7e <itrunc+0x74>
    brelse(bp);
    80003d96:	8552                	mv	a0,s4
    80003d98:	fffff097          	auipc	ra,0xfffff
    80003d9c:	784080e7          	jalr	1924(ra) # 8000351c <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003da0:	0809a583          	lw	a1,128(s3)
    80003da4:	0009a503          	lw	a0,0(s3)
    80003da8:	00000097          	auipc	ra,0x0
    80003dac:	888080e7          	jalr	-1912(ra) # 80003630 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003db0:	0809a023          	sw	zero,128(s3)
    80003db4:	bf51                	j	80003d48 <itrunc+0x3e>

0000000080003db6 <iput>:
{
    80003db6:	1101                	addi	sp,sp,-32
    80003db8:	ec06                	sd	ra,24(sp)
    80003dba:	e822                	sd	s0,16(sp)
    80003dbc:	e426                	sd	s1,8(sp)
    80003dbe:	e04a                	sd	s2,0(sp)
    80003dc0:	1000                	addi	s0,sp,32
    80003dc2:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003dc4:	0001b517          	auipc	a0,0x1b
    80003dc8:	3d450513          	addi	a0,a0,980 # 8001f198 <itable>
    80003dcc:	ffffd097          	auipc	ra,0xffffd
    80003dd0:	e06080e7          	jalr	-506(ra) # 80000bd2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003dd4:	4498                	lw	a4,8(s1)
    80003dd6:	4785                	li	a5,1
    80003dd8:	02f70363          	beq	a4,a5,80003dfe <iput+0x48>
  ip->ref--;
    80003ddc:	449c                	lw	a5,8(s1)
    80003dde:	37fd                	addiw	a5,a5,-1
    80003de0:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003de2:	0001b517          	auipc	a0,0x1b
    80003de6:	3b650513          	addi	a0,a0,950 # 8001f198 <itable>
    80003dea:	ffffd097          	auipc	ra,0xffffd
    80003dee:	e9c080e7          	jalr	-356(ra) # 80000c86 <release>
}
    80003df2:	60e2                	ld	ra,24(sp)
    80003df4:	6442                	ld	s0,16(sp)
    80003df6:	64a2                	ld	s1,8(sp)
    80003df8:	6902                	ld	s2,0(sp)
    80003dfa:	6105                	addi	sp,sp,32
    80003dfc:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003dfe:	40bc                	lw	a5,64(s1)
    80003e00:	dff1                	beqz	a5,80003ddc <iput+0x26>
    80003e02:	04a49783          	lh	a5,74(s1)
    80003e06:	fbf9                	bnez	a5,80003ddc <iput+0x26>
    acquiresleep(&ip->lock);
    80003e08:	01048913          	addi	s2,s1,16
    80003e0c:	854a                	mv	a0,s2
    80003e0e:	00001097          	auipc	ra,0x1
    80003e12:	a84080e7          	jalr	-1404(ra) # 80004892 <acquiresleep>
    release(&itable.lock);
    80003e16:	0001b517          	auipc	a0,0x1b
    80003e1a:	38250513          	addi	a0,a0,898 # 8001f198 <itable>
    80003e1e:	ffffd097          	auipc	ra,0xffffd
    80003e22:	e68080e7          	jalr	-408(ra) # 80000c86 <release>
    itrunc(ip);
    80003e26:	8526                	mv	a0,s1
    80003e28:	00000097          	auipc	ra,0x0
    80003e2c:	ee2080e7          	jalr	-286(ra) # 80003d0a <itrunc>
    ip->type = 0;
    80003e30:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003e34:	8526                	mv	a0,s1
    80003e36:	00000097          	auipc	ra,0x0
    80003e3a:	cfa080e7          	jalr	-774(ra) # 80003b30 <iupdate>
    ip->valid = 0;
    80003e3e:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003e42:	854a                	mv	a0,s2
    80003e44:	00001097          	auipc	ra,0x1
    80003e48:	aa4080e7          	jalr	-1372(ra) # 800048e8 <releasesleep>
    acquire(&itable.lock);
    80003e4c:	0001b517          	auipc	a0,0x1b
    80003e50:	34c50513          	addi	a0,a0,844 # 8001f198 <itable>
    80003e54:	ffffd097          	auipc	ra,0xffffd
    80003e58:	d7e080e7          	jalr	-642(ra) # 80000bd2 <acquire>
    80003e5c:	b741                	j	80003ddc <iput+0x26>

0000000080003e5e <iunlockput>:
{
    80003e5e:	1101                	addi	sp,sp,-32
    80003e60:	ec06                	sd	ra,24(sp)
    80003e62:	e822                	sd	s0,16(sp)
    80003e64:	e426                	sd	s1,8(sp)
    80003e66:	1000                	addi	s0,sp,32
    80003e68:	84aa                	mv	s1,a0
  iunlock(ip);
    80003e6a:	00000097          	auipc	ra,0x0
    80003e6e:	e54080e7          	jalr	-428(ra) # 80003cbe <iunlock>
  iput(ip);
    80003e72:	8526                	mv	a0,s1
    80003e74:	00000097          	auipc	ra,0x0
    80003e78:	f42080e7          	jalr	-190(ra) # 80003db6 <iput>
}
    80003e7c:	60e2                	ld	ra,24(sp)
    80003e7e:	6442                	ld	s0,16(sp)
    80003e80:	64a2                	ld	s1,8(sp)
    80003e82:	6105                	addi	sp,sp,32
    80003e84:	8082                	ret

0000000080003e86 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003e86:	1141                	addi	sp,sp,-16
    80003e88:	e422                	sd	s0,8(sp)
    80003e8a:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003e8c:	411c                	lw	a5,0(a0)
    80003e8e:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003e90:	415c                	lw	a5,4(a0)
    80003e92:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003e94:	04451783          	lh	a5,68(a0)
    80003e98:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003e9c:	04a51783          	lh	a5,74(a0)
    80003ea0:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003ea4:	04c56783          	lwu	a5,76(a0)
    80003ea8:	e99c                	sd	a5,16(a1)
}
    80003eaa:	6422                	ld	s0,8(sp)
    80003eac:	0141                	addi	sp,sp,16
    80003eae:	8082                	ret

0000000080003eb0 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003eb0:	457c                	lw	a5,76(a0)
    80003eb2:	0ed7e963          	bltu	a5,a3,80003fa4 <readi+0xf4>
{
    80003eb6:	7159                	addi	sp,sp,-112
    80003eb8:	f486                	sd	ra,104(sp)
    80003eba:	f0a2                	sd	s0,96(sp)
    80003ebc:	eca6                	sd	s1,88(sp)
    80003ebe:	e8ca                	sd	s2,80(sp)
    80003ec0:	e4ce                	sd	s3,72(sp)
    80003ec2:	e0d2                	sd	s4,64(sp)
    80003ec4:	fc56                	sd	s5,56(sp)
    80003ec6:	f85a                	sd	s6,48(sp)
    80003ec8:	f45e                	sd	s7,40(sp)
    80003eca:	f062                	sd	s8,32(sp)
    80003ecc:	ec66                	sd	s9,24(sp)
    80003ece:	e86a                	sd	s10,16(sp)
    80003ed0:	e46e                	sd	s11,8(sp)
    80003ed2:	1880                	addi	s0,sp,112
    80003ed4:	8b2a                	mv	s6,a0
    80003ed6:	8bae                	mv	s7,a1
    80003ed8:	8a32                	mv	s4,a2
    80003eda:	84b6                	mv	s1,a3
    80003edc:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003ede:	9f35                	addw	a4,a4,a3
    return 0;
    80003ee0:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003ee2:	0ad76063          	bltu	a4,a3,80003f82 <readi+0xd2>
  if(off + n > ip->size)
    80003ee6:	00e7f463          	bgeu	a5,a4,80003eee <readi+0x3e>
    n = ip->size - off;
    80003eea:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003eee:	0a0a8963          	beqz	s5,80003fa0 <readi+0xf0>
    80003ef2:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ef4:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003ef8:	5c7d                	li	s8,-1
    80003efa:	a82d                	j	80003f34 <readi+0x84>
    80003efc:	020d1d93          	slli	s11,s10,0x20
    80003f00:	020ddd93          	srli	s11,s11,0x20
    80003f04:	05890613          	addi	a2,s2,88
    80003f08:	86ee                	mv	a3,s11
    80003f0a:	963a                	add	a2,a2,a4
    80003f0c:	85d2                	mv	a1,s4
    80003f0e:	855e                	mv	a0,s7
    80003f10:	fffff097          	auipc	ra,0xfffff
    80003f14:	94a080e7          	jalr	-1718(ra) # 8000285a <either_copyout>
    80003f18:	05850d63          	beq	a0,s8,80003f72 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003f1c:	854a                	mv	a0,s2
    80003f1e:	fffff097          	auipc	ra,0xfffff
    80003f22:	5fe080e7          	jalr	1534(ra) # 8000351c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f26:	013d09bb          	addw	s3,s10,s3
    80003f2a:	009d04bb          	addw	s1,s10,s1
    80003f2e:	9a6e                	add	s4,s4,s11
    80003f30:	0559f763          	bgeu	s3,s5,80003f7e <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003f34:	00a4d59b          	srliw	a1,s1,0xa
    80003f38:	855a                	mv	a0,s6
    80003f3a:	00000097          	auipc	ra,0x0
    80003f3e:	8a4080e7          	jalr	-1884(ra) # 800037de <bmap>
    80003f42:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003f46:	cd85                	beqz	a1,80003f7e <readi+0xce>
    bp = bread(ip->dev, addr);
    80003f48:	000b2503          	lw	a0,0(s6)
    80003f4c:	fffff097          	auipc	ra,0xfffff
    80003f50:	4a0080e7          	jalr	1184(ra) # 800033ec <bread>
    80003f54:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f56:	3ff4f713          	andi	a4,s1,1023
    80003f5a:	40ec87bb          	subw	a5,s9,a4
    80003f5e:	413a86bb          	subw	a3,s5,s3
    80003f62:	8d3e                	mv	s10,a5
    80003f64:	2781                	sext.w	a5,a5
    80003f66:	0006861b          	sext.w	a2,a3
    80003f6a:	f8f679e3          	bgeu	a2,a5,80003efc <readi+0x4c>
    80003f6e:	8d36                	mv	s10,a3
    80003f70:	b771                	j	80003efc <readi+0x4c>
      brelse(bp);
    80003f72:	854a                	mv	a0,s2
    80003f74:	fffff097          	auipc	ra,0xfffff
    80003f78:	5a8080e7          	jalr	1448(ra) # 8000351c <brelse>
      tot = -1;
    80003f7c:	59fd                	li	s3,-1
  }
  return tot;
    80003f7e:	0009851b          	sext.w	a0,s3
}
    80003f82:	70a6                	ld	ra,104(sp)
    80003f84:	7406                	ld	s0,96(sp)
    80003f86:	64e6                	ld	s1,88(sp)
    80003f88:	6946                	ld	s2,80(sp)
    80003f8a:	69a6                	ld	s3,72(sp)
    80003f8c:	6a06                	ld	s4,64(sp)
    80003f8e:	7ae2                	ld	s5,56(sp)
    80003f90:	7b42                	ld	s6,48(sp)
    80003f92:	7ba2                	ld	s7,40(sp)
    80003f94:	7c02                	ld	s8,32(sp)
    80003f96:	6ce2                	ld	s9,24(sp)
    80003f98:	6d42                	ld	s10,16(sp)
    80003f9a:	6da2                	ld	s11,8(sp)
    80003f9c:	6165                	addi	sp,sp,112
    80003f9e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003fa0:	89d6                	mv	s3,s5
    80003fa2:	bff1                	j	80003f7e <readi+0xce>
    return 0;
    80003fa4:	4501                	li	a0,0
}
    80003fa6:	8082                	ret

0000000080003fa8 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003fa8:	457c                	lw	a5,76(a0)
    80003faa:	10d7e863          	bltu	a5,a3,800040ba <writei+0x112>
{
    80003fae:	7159                	addi	sp,sp,-112
    80003fb0:	f486                	sd	ra,104(sp)
    80003fb2:	f0a2                	sd	s0,96(sp)
    80003fb4:	eca6                	sd	s1,88(sp)
    80003fb6:	e8ca                	sd	s2,80(sp)
    80003fb8:	e4ce                	sd	s3,72(sp)
    80003fba:	e0d2                	sd	s4,64(sp)
    80003fbc:	fc56                	sd	s5,56(sp)
    80003fbe:	f85a                	sd	s6,48(sp)
    80003fc0:	f45e                	sd	s7,40(sp)
    80003fc2:	f062                	sd	s8,32(sp)
    80003fc4:	ec66                	sd	s9,24(sp)
    80003fc6:	e86a                	sd	s10,16(sp)
    80003fc8:	e46e                	sd	s11,8(sp)
    80003fca:	1880                	addi	s0,sp,112
    80003fcc:	8aaa                	mv	s5,a0
    80003fce:	8bae                	mv	s7,a1
    80003fd0:	8a32                	mv	s4,a2
    80003fd2:	8936                	mv	s2,a3
    80003fd4:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003fd6:	00e687bb          	addw	a5,a3,a4
    80003fda:	0ed7e263          	bltu	a5,a3,800040be <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003fde:	00043737          	lui	a4,0x43
    80003fe2:	0ef76063          	bltu	a4,a5,800040c2 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003fe6:	0c0b0863          	beqz	s6,800040b6 <writei+0x10e>
    80003fea:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003fec:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003ff0:	5c7d                	li	s8,-1
    80003ff2:	a091                	j	80004036 <writei+0x8e>
    80003ff4:	020d1d93          	slli	s11,s10,0x20
    80003ff8:	020ddd93          	srli	s11,s11,0x20
    80003ffc:	05848513          	addi	a0,s1,88
    80004000:	86ee                	mv	a3,s11
    80004002:	8652                	mv	a2,s4
    80004004:	85de                	mv	a1,s7
    80004006:	953a                	add	a0,a0,a4
    80004008:	fffff097          	auipc	ra,0xfffff
    8000400c:	8a8080e7          	jalr	-1880(ra) # 800028b0 <either_copyin>
    80004010:	07850263          	beq	a0,s8,80004074 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004014:	8526                	mv	a0,s1
    80004016:	00000097          	auipc	ra,0x0
    8000401a:	75e080e7          	jalr	1886(ra) # 80004774 <log_write>
    brelse(bp);
    8000401e:	8526                	mv	a0,s1
    80004020:	fffff097          	auipc	ra,0xfffff
    80004024:	4fc080e7          	jalr	1276(ra) # 8000351c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004028:	013d09bb          	addw	s3,s10,s3
    8000402c:	012d093b          	addw	s2,s10,s2
    80004030:	9a6e                	add	s4,s4,s11
    80004032:	0569f663          	bgeu	s3,s6,8000407e <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80004036:	00a9559b          	srliw	a1,s2,0xa
    8000403a:	8556                	mv	a0,s5
    8000403c:	fffff097          	auipc	ra,0xfffff
    80004040:	7a2080e7          	jalr	1954(ra) # 800037de <bmap>
    80004044:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80004048:	c99d                	beqz	a1,8000407e <writei+0xd6>
    bp = bread(ip->dev, addr);
    8000404a:	000aa503          	lw	a0,0(s5)
    8000404e:	fffff097          	auipc	ra,0xfffff
    80004052:	39e080e7          	jalr	926(ra) # 800033ec <bread>
    80004056:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004058:	3ff97713          	andi	a4,s2,1023
    8000405c:	40ec87bb          	subw	a5,s9,a4
    80004060:	413b06bb          	subw	a3,s6,s3
    80004064:	8d3e                	mv	s10,a5
    80004066:	2781                	sext.w	a5,a5
    80004068:	0006861b          	sext.w	a2,a3
    8000406c:	f8f674e3          	bgeu	a2,a5,80003ff4 <writei+0x4c>
    80004070:	8d36                	mv	s10,a3
    80004072:	b749                	j	80003ff4 <writei+0x4c>
      brelse(bp);
    80004074:	8526                	mv	a0,s1
    80004076:	fffff097          	auipc	ra,0xfffff
    8000407a:	4a6080e7          	jalr	1190(ra) # 8000351c <brelse>
  }

  if(off > ip->size)
    8000407e:	04caa783          	lw	a5,76(s5)
    80004082:	0127f463          	bgeu	a5,s2,8000408a <writei+0xe2>
    ip->size = off;
    80004086:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    8000408a:	8556                	mv	a0,s5
    8000408c:	00000097          	auipc	ra,0x0
    80004090:	aa4080e7          	jalr	-1372(ra) # 80003b30 <iupdate>

  return tot;
    80004094:	0009851b          	sext.w	a0,s3
}
    80004098:	70a6                	ld	ra,104(sp)
    8000409a:	7406                	ld	s0,96(sp)
    8000409c:	64e6                	ld	s1,88(sp)
    8000409e:	6946                	ld	s2,80(sp)
    800040a0:	69a6                	ld	s3,72(sp)
    800040a2:	6a06                	ld	s4,64(sp)
    800040a4:	7ae2                	ld	s5,56(sp)
    800040a6:	7b42                	ld	s6,48(sp)
    800040a8:	7ba2                	ld	s7,40(sp)
    800040aa:	7c02                	ld	s8,32(sp)
    800040ac:	6ce2                	ld	s9,24(sp)
    800040ae:	6d42                	ld	s10,16(sp)
    800040b0:	6da2                	ld	s11,8(sp)
    800040b2:	6165                	addi	sp,sp,112
    800040b4:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800040b6:	89da                	mv	s3,s6
    800040b8:	bfc9                	j	8000408a <writei+0xe2>
    return -1;
    800040ba:	557d                	li	a0,-1
}
    800040bc:	8082                	ret
    return -1;
    800040be:	557d                	li	a0,-1
    800040c0:	bfe1                	j	80004098 <writei+0xf0>
    return -1;
    800040c2:	557d                	li	a0,-1
    800040c4:	bfd1                	j	80004098 <writei+0xf0>

00000000800040c6 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800040c6:	1141                	addi	sp,sp,-16
    800040c8:	e406                	sd	ra,8(sp)
    800040ca:	e022                	sd	s0,0(sp)
    800040cc:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800040ce:	4639                	li	a2,14
    800040d0:	ffffd097          	auipc	ra,0xffffd
    800040d4:	cce080e7          	jalr	-818(ra) # 80000d9e <strncmp>
}
    800040d8:	60a2                	ld	ra,8(sp)
    800040da:	6402                	ld	s0,0(sp)
    800040dc:	0141                	addi	sp,sp,16
    800040de:	8082                	ret

00000000800040e0 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800040e0:	7139                	addi	sp,sp,-64
    800040e2:	fc06                	sd	ra,56(sp)
    800040e4:	f822                	sd	s0,48(sp)
    800040e6:	f426                	sd	s1,40(sp)
    800040e8:	f04a                	sd	s2,32(sp)
    800040ea:	ec4e                	sd	s3,24(sp)
    800040ec:	e852                	sd	s4,16(sp)
    800040ee:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800040f0:	04451703          	lh	a4,68(a0)
    800040f4:	4785                	li	a5,1
    800040f6:	00f71a63          	bne	a4,a5,8000410a <dirlookup+0x2a>
    800040fa:	892a                	mv	s2,a0
    800040fc:	89ae                	mv	s3,a1
    800040fe:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004100:	457c                	lw	a5,76(a0)
    80004102:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004104:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004106:	e79d                	bnez	a5,80004134 <dirlookup+0x54>
    80004108:	a8a5                	j	80004180 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    8000410a:	00004517          	auipc	a0,0x4
    8000410e:	5ce50513          	addi	a0,a0,1486 # 800086d8 <syscalls+0x1b8>
    80004112:	ffffc097          	auipc	ra,0xffffc
    80004116:	42a080e7          	jalr	1066(ra) # 8000053c <panic>
      panic("dirlookup read");
    8000411a:	00004517          	auipc	a0,0x4
    8000411e:	5d650513          	addi	a0,a0,1494 # 800086f0 <syscalls+0x1d0>
    80004122:	ffffc097          	auipc	ra,0xffffc
    80004126:	41a080e7          	jalr	1050(ra) # 8000053c <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000412a:	24c1                	addiw	s1,s1,16
    8000412c:	04c92783          	lw	a5,76(s2)
    80004130:	04f4f763          	bgeu	s1,a5,8000417e <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004134:	4741                	li	a4,16
    80004136:	86a6                	mv	a3,s1
    80004138:	fc040613          	addi	a2,s0,-64
    8000413c:	4581                	li	a1,0
    8000413e:	854a                	mv	a0,s2
    80004140:	00000097          	auipc	ra,0x0
    80004144:	d70080e7          	jalr	-656(ra) # 80003eb0 <readi>
    80004148:	47c1                	li	a5,16
    8000414a:	fcf518e3          	bne	a0,a5,8000411a <dirlookup+0x3a>
    if(de.inum == 0)
    8000414e:	fc045783          	lhu	a5,-64(s0)
    80004152:	dfe1                	beqz	a5,8000412a <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004154:	fc240593          	addi	a1,s0,-62
    80004158:	854e                	mv	a0,s3
    8000415a:	00000097          	auipc	ra,0x0
    8000415e:	f6c080e7          	jalr	-148(ra) # 800040c6 <namecmp>
    80004162:	f561                	bnez	a0,8000412a <dirlookup+0x4a>
      if(poff)
    80004164:	000a0463          	beqz	s4,8000416c <dirlookup+0x8c>
        *poff = off;
    80004168:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    8000416c:	fc045583          	lhu	a1,-64(s0)
    80004170:	00092503          	lw	a0,0(s2)
    80004174:	fffff097          	auipc	ra,0xfffff
    80004178:	754080e7          	jalr	1876(ra) # 800038c8 <iget>
    8000417c:	a011                	j	80004180 <dirlookup+0xa0>
  return 0;
    8000417e:	4501                	li	a0,0
}
    80004180:	70e2                	ld	ra,56(sp)
    80004182:	7442                	ld	s0,48(sp)
    80004184:	74a2                	ld	s1,40(sp)
    80004186:	7902                	ld	s2,32(sp)
    80004188:	69e2                	ld	s3,24(sp)
    8000418a:	6a42                	ld	s4,16(sp)
    8000418c:	6121                	addi	sp,sp,64
    8000418e:	8082                	ret

0000000080004190 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004190:	711d                	addi	sp,sp,-96
    80004192:	ec86                	sd	ra,88(sp)
    80004194:	e8a2                	sd	s0,80(sp)
    80004196:	e4a6                	sd	s1,72(sp)
    80004198:	e0ca                	sd	s2,64(sp)
    8000419a:	fc4e                	sd	s3,56(sp)
    8000419c:	f852                	sd	s4,48(sp)
    8000419e:	f456                	sd	s5,40(sp)
    800041a0:	f05a                	sd	s6,32(sp)
    800041a2:	ec5e                	sd	s7,24(sp)
    800041a4:	e862                	sd	s8,16(sp)
    800041a6:	e466                	sd	s9,8(sp)
    800041a8:	1080                	addi	s0,sp,96
    800041aa:	84aa                	mv	s1,a0
    800041ac:	8b2e                	mv	s6,a1
    800041ae:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800041b0:	00054703          	lbu	a4,0(a0)
    800041b4:	02f00793          	li	a5,47
    800041b8:	02f70263          	beq	a4,a5,800041dc <namex+0x4c>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800041bc:	ffffe097          	auipc	ra,0xffffe
    800041c0:	ad8080e7          	jalr	-1320(ra) # 80001c94 <myproc>
    800041c4:	15053503          	ld	a0,336(a0)
    800041c8:	00000097          	auipc	ra,0x0
    800041cc:	9f6080e7          	jalr	-1546(ra) # 80003bbe <idup>
    800041d0:	8a2a                	mv	s4,a0
  while(*path == '/')
    800041d2:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    800041d6:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800041d8:	4b85                	li	s7,1
    800041da:	a875                	j	80004296 <namex+0x106>
    ip = iget(ROOTDEV, ROOTINO);
    800041dc:	4585                	li	a1,1
    800041de:	4505                	li	a0,1
    800041e0:	fffff097          	auipc	ra,0xfffff
    800041e4:	6e8080e7          	jalr	1768(ra) # 800038c8 <iget>
    800041e8:	8a2a                	mv	s4,a0
    800041ea:	b7e5                	j	800041d2 <namex+0x42>
      iunlockput(ip);
    800041ec:	8552                	mv	a0,s4
    800041ee:	00000097          	auipc	ra,0x0
    800041f2:	c70080e7          	jalr	-912(ra) # 80003e5e <iunlockput>
      return 0;
    800041f6:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800041f8:	8552                	mv	a0,s4
    800041fa:	60e6                	ld	ra,88(sp)
    800041fc:	6446                	ld	s0,80(sp)
    800041fe:	64a6                	ld	s1,72(sp)
    80004200:	6906                	ld	s2,64(sp)
    80004202:	79e2                	ld	s3,56(sp)
    80004204:	7a42                	ld	s4,48(sp)
    80004206:	7aa2                	ld	s5,40(sp)
    80004208:	7b02                	ld	s6,32(sp)
    8000420a:	6be2                	ld	s7,24(sp)
    8000420c:	6c42                	ld	s8,16(sp)
    8000420e:	6ca2                	ld	s9,8(sp)
    80004210:	6125                	addi	sp,sp,96
    80004212:	8082                	ret
      iunlock(ip);
    80004214:	8552                	mv	a0,s4
    80004216:	00000097          	auipc	ra,0x0
    8000421a:	aa8080e7          	jalr	-1368(ra) # 80003cbe <iunlock>
      return ip;
    8000421e:	bfe9                	j	800041f8 <namex+0x68>
      iunlockput(ip);
    80004220:	8552                	mv	a0,s4
    80004222:	00000097          	auipc	ra,0x0
    80004226:	c3c080e7          	jalr	-964(ra) # 80003e5e <iunlockput>
      return 0;
    8000422a:	8a4e                	mv	s4,s3
    8000422c:	b7f1                	j	800041f8 <namex+0x68>
  len = path - s;
    8000422e:	40998633          	sub	a2,s3,s1
    80004232:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80004236:	099c5863          	bge	s8,s9,800042c6 <namex+0x136>
    memmove(name, s, DIRSIZ);
    8000423a:	4639                	li	a2,14
    8000423c:	85a6                	mv	a1,s1
    8000423e:	8556                	mv	a0,s5
    80004240:	ffffd097          	auipc	ra,0xffffd
    80004244:	aea080e7          	jalr	-1302(ra) # 80000d2a <memmove>
    80004248:	84ce                	mv	s1,s3
  while(*path == '/')
    8000424a:	0004c783          	lbu	a5,0(s1)
    8000424e:	01279763          	bne	a5,s2,8000425c <namex+0xcc>
    path++;
    80004252:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004254:	0004c783          	lbu	a5,0(s1)
    80004258:	ff278de3          	beq	a5,s2,80004252 <namex+0xc2>
    ilock(ip);
    8000425c:	8552                	mv	a0,s4
    8000425e:	00000097          	auipc	ra,0x0
    80004262:	99e080e7          	jalr	-1634(ra) # 80003bfc <ilock>
    if(ip->type != T_DIR){
    80004266:	044a1783          	lh	a5,68(s4)
    8000426a:	f97791e3          	bne	a5,s7,800041ec <namex+0x5c>
    if(nameiparent && *path == '\0'){
    8000426e:	000b0563          	beqz	s6,80004278 <namex+0xe8>
    80004272:	0004c783          	lbu	a5,0(s1)
    80004276:	dfd9                	beqz	a5,80004214 <namex+0x84>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004278:	4601                	li	a2,0
    8000427a:	85d6                	mv	a1,s5
    8000427c:	8552                	mv	a0,s4
    8000427e:	00000097          	auipc	ra,0x0
    80004282:	e62080e7          	jalr	-414(ra) # 800040e0 <dirlookup>
    80004286:	89aa                	mv	s3,a0
    80004288:	dd41                	beqz	a0,80004220 <namex+0x90>
    iunlockput(ip);
    8000428a:	8552                	mv	a0,s4
    8000428c:	00000097          	auipc	ra,0x0
    80004290:	bd2080e7          	jalr	-1070(ra) # 80003e5e <iunlockput>
    ip = next;
    80004294:	8a4e                	mv	s4,s3
  while(*path == '/')
    80004296:	0004c783          	lbu	a5,0(s1)
    8000429a:	01279763          	bne	a5,s2,800042a8 <namex+0x118>
    path++;
    8000429e:	0485                	addi	s1,s1,1
  while(*path == '/')
    800042a0:	0004c783          	lbu	a5,0(s1)
    800042a4:	ff278de3          	beq	a5,s2,8000429e <namex+0x10e>
  if(*path == 0)
    800042a8:	cb9d                	beqz	a5,800042de <namex+0x14e>
  while(*path != '/' && *path != 0)
    800042aa:	0004c783          	lbu	a5,0(s1)
    800042ae:	89a6                	mv	s3,s1
  len = path - s;
    800042b0:	4c81                	li	s9,0
    800042b2:	4601                	li	a2,0
  while(*path != '/' && *path != 0)
    800042b4:	01278963          	beq	a5,s2,800042c6 <namex+0x136>
    800042b8:	dbbd                	beqz	a5,8000422e <namex+0x9e>
    path++;
    800042ba:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    800042bc:	0009c783          	lbu	a5,0(s3)
    800042c0:	ff279ce3          	bne	a5,s2,800042b8 <namex+0x128>
    800042c4:	b7ad                	j	8000422e <namex+0x9e>
    memmove(name, s, len);
    800042c6:	2601                	sext.w	a2,a2
    800042c8:	85a6                	mv	a1,s1
    800042ca:	8556                	mv	a0,s5
    800042cc:	ffffd097          	auipc	ra,0xffffd
    800042d0:	a5e080e7          	jalr	-1442(ra) # 80000d2a <memmove>
    name[len] = 0;
    800042d4:	9cd6                	add	s9,s9,s5
    800042d6:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    800042da:	84ce                	mv	s1,s3
    800042dc:	b7bd                	j	8000424a <namex+0xba>
  if(nameiparent){
    800042de:	f00b0de3          	beqz	s6,800041f8 <namex+0x68>
    iput(ip);
    800042e2:	8552                	mv	a0,s4
    800042e4:	00000097          	auipc	ra,0x0
    800042e8:	ad2080e7          	jalr	-1326(ra) # 80003db6 <iput>
    return 0;
    800042ec:	4a01                	li	s4,0
    800042ee:	b729                	j	800041f8 <namex+0x68>

00000000800042f0 <dirlink>:
{
    800042f0:	7139                	addi	sp,sp,-64
    800042f2:	fc06                	sd	ra,56(sp)
    800042f4:	f822                	sd	s0,48(sp)
    800042f6:	f426                	sd	s1,40(sp)
    800042f8:	f04a                	sd	s2,32(sp)
    800042fa:	ec4e                	sd	s3,24(sp)
    800042fc:	e852                	sd	s4,16(sp)
    800042fe:	0080                	addi	s0,sp,64
    80004300:	892a                	mv	s2,a0
    80004302:	8a2e                	mv	s4,a1
    80004304:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004306:	4601                	li	a2,0
    80004308:	00000097          	auipc	ra,0x0
    8000430c:	dd8080e7          	jalr	-552(ra) # 800040e0 <dirlookup>
    80004310:	e93d                	bnez	a0,80004386 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004312:	04c92483          	lw	s1,76(s2)
    80004316:	c49d                	beqz	s1,80004344 <dirlink+0x54>
    80004318:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000431a:	4741                	li	a4,16
    8000431c:	86a6                	mv	a3,s1
    8000431e:	fc040613          	addi	a2,s0,-64
    80004322:	4581                	li	a1,0
    80004324:	854a                	mv	a0,s2
    80004326:	00000097          	auipc	ra,0x0
    8000432a:	b8a080e7          	jalr	-1142(ra) # 80003eb0 <readi>
    8000432e:	47c1                	li	a5,16
    80004330:	06f51163          	bne	a0,a5,80004392 <dirlink+0xa2>
    if(de.inum == 0)
    80004334:	fc045783          	lhu	a5,-64(s0)
    80004338:	c791                	beqz	a5,80004344 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000433a:	24c1                	addiw	s1,s1,16
    8000433c:	04c92783          	lw	a5,76(s2)
    80004340:	fcf4ede3          	bltu	s1,a5,8000431a <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004344:	4639                	li	a2,14
    80004346:	85d2                	mv	a1,s4
    80004348:	fc240513          	addi	a0,s0,-62
    8000434c:	ffffd097          	auipc	ra,0xffffd
    80004350:	a8e080e7          	jalr	-1394(ra) # 80000dda <strncpy>
  de.inum = inum;
    80004354:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004358:	4741                	li	a4,16
    8000435a:	86a6                	mv	a3,s1
    8000435c:	fc040613          	addi	a2,s0,-64
    80004360:	4581                	li	a1,0
    80004362:	854a                	mv	a0,s2
    80004364:	00000097          	auipc	ra,0x0
    80004368:	c44080e7          	jalr	-956(ra) # 80003fa8 <writei>
    8000436c:	1541                	addi	a0,a0,-16
    8000436e:	00a03533          	snez	a0,a0
    80004372:	40a00533          	neg	a0,a0
}
    80004376:	70e2                	ld	ra,56(sp)
    80004378:	7442                	ld	s0,48(sp)
    8000437a:	74a2                	ld	s1,40(sp)
    8000437c:	7902                	ld	s2,32(sp)
    8000437e:	69e2                	ld	s3,24(sp)
    80004380:	6a42                	ld	s4,16(sp)
    80004382:	6121                	addi	sp,sp,64
    80004384:	8082                	ret
    iput(ip);
    80004386:	00000097          	auipc	ra,0x0
    8000438a:	a30080e7          	jalr	-1488(ra) # 80003db6 <iput>
    return -1;
    8000438e:	557d                	li	a0,-1
    80004390:	b7dd                	j	80004376 <dirlink+0x86>
      panic("dirlink read");
    80004392:	00004517          	auipc	a0,0x4
    80004396:	36e50513          	addi	a0,a0,878 # 80008700 <syscalls+0x1e0>
    8000439a:	ffffc097          	auipc	ra,0xffffc
    8000439e:	1a2080e7          	jalr	418(ra) # 8000053c <panic>

00000000800043a2 <namei>:

struct inode*
namei(char *path)
{
    800043a2:	1101                	addi	sp,sp,-32
    800043a4:	ec06                	sd	ra,24(sp)
    800043a6:	e822                	sd	s0,16(sp)
    800043a8:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800043aa:	fe040613          	addi	a2,s0,-32
    800043ae:	4581                	li	a1,0
    800043b0:	00000097          	auipc	ra,0x0
    800043b4:	de0080e7          	jalr	-544(ra) # 80004190 <namex>
}
    800043b8:	60e2                	ld	ra,24(sp)
    800043ba:	6442                	ld	s0,16(sp)
    800043bc:	6105                	addi	sp,sp,32
    800043be:	8082                	ret

00000000800043c0 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800043c0:	1141                	addi	sp,sp,-16
    800043c2:	e406                	sd	ra,8(sp)
    800043c4:	e022                	sd	s0,0(sp)
    800043c6:	0800                	addi	s0,sp,16
    800043c8:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800043ca:	4585                	li	a1,1
    800043cc:	00000097          	auipc	ra,0x0
    800043d0:	dc4080e7          	jalr	-572(ra) # 80004190 <namex>
}
    800043d4:	60a2                	ld	ra,8(sp)
    800043d6:	6402                	ld	s0,0(sp)
    800043d8:	0141                	addi	sp,sp,16
    800043da:	8082                	ret

00000000800043dc <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800043dc:	1101                	addi	sp,sp,-32
    800043de:	ec06                	sd	ra,24(sp)
    800043e0:	e822                	sd	s0,16(sp)
    800043e2:	e426                	sd	s1,8(sp)
    800043e4:	e04a                	sd	s2,0(sp)
    800043e6:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800043e8:	0001d917          	auipc	s2,0x1d
    800043ec:	85890913          	addi	s2,s2,-1960 # 80020c40 <log>
    800043f0:	01892583          	lw	a1,24(s2)
    800043f4:	02892503          	lw	a0,40(s2)
    800043f8:	fffff097          	auipc	ra,0xfffff
    800043fc:	ff4080e7          	jalr	-12(ra) # 800033ec <bread>
    80004400:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004402:	02c92603          	lw	a2,44(s2)
    80004406:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004408:	00c05f63          	blez	a2,80004426 <write_head+0x4a>
    8000440c:	0001d717          	auipc	a4,0x1d
    80004410:	86470713          	addi	a4,a4,-1948 # 80020c70 <log+0x30>
    80004414:	87aa                	mv	a5,a0
    80004416:	060a                	slli	a2,a2,0x2
    80004418:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    8000441a:	4314                	lw	a3,0(a4)
    8000441c:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    8000441e:	0711                	addi	a4,a4,4
    80004420:	0791                	addi	a5,a5,4
    80004422:	fec79ce3          	bne	a5,a2,8000441a <write_head+0x3e>
  }
  bwrite(buf);
    80004426:	8526                	mv	a0,s1
    80004428:	fffff097          	auipc	ra,0xfffff
    8000442c:	0b6080e7          	jalr	182(ra) # 800034de <bwrite>
  brelse(buf);
    80004430:	8526                	mv	a0,s1
    80004432:	fffff097          	auipc	ra,0xfffff
    80004436:	0ea080e7          	jalr	234(ra) # 8000351c <brelse>
}
    8000443a:	60e2                	ld	ra,24(sp)
    8000443c:	6442                	ld	s0,16(sp)
    8000443e:	64a2                	ld	s1,8(sp)
    80004440:	6902                	ld	s2,0(sp)
    80004442:	6105                	addi	sp,sp,32
    80004444:	8082                	ret

0000000080004446 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004446:	0001d797          	auipc	a5,0x1d
    8000444a:	8267a783          	lw	a5,-2010(a5) # 80020c6c <log+0x2c>
    8000444e:	0af05d63          	blez	a5,80004508 <install_trans+0xc2>
{
    80004452:	7139                	addi	sp,sp,-64
    80004454:	fc06                	sd	ra,56(sp)
    80004456:	f822                	sd	s0,48(sp)
    80004458:	f426                	sd	s1,40(sp)
    8000445a:	f04a                	sd	s2,32(sp)
    8000445c:	ec4e                	sd	s3,24(sp)
    8000445e:	e852                	sd	s4,16(sp)
    80004460:	e456                	sd	s5,8(sp)
    80004462:	e05a                	sd	s6,0(sp)
    80004464:	0080                	addi	s0,sp,64
    80004466:	8b2a                	mv	s6,a0
    80004468:	0001da97          	auipc	s5,0x1d
    8000446c:	808a8a93          	addi	s5,s5,-2040 # 80020c70 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004470:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004472:	0001c997          	auipc	s3,0x1c
    80004476:	7ce98993          	addi	s3,s3,1998 # 80020c40 <log>
    8000447a:	a00d                	j	8000449c <install_trans+0x56>
    brelse(lbuf);
    8000447c:	854a                	mv	a0,s2
    8000447e:	fffff097          	auipc	ra,0xfffff
    80004482:	09e080e7          	jalr	158(ra) # 8000351c <brelse>
    brelse(dbuf);
    80004486:	8526                	mv	a0,s1
    80004488:	fffff097          	auipc	ra,0xfffff
    8000448c:	094080e7          	jalr	148(ra) # 8000351c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004490:	2a05                	addiw	s4,s4,1
    80004492:	0a91                	addi	s5,s5,4
    80004494:	02c9a783          	lw	a5,44(s3)
    80004498:	04fa5e63          	bge	s4,a5,800044f4 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000449c:	0189a583          	lw	a1,24(s3)
    800044a0:	014585bb          	addw	a1,a1,s4
    800044a4:	2585                	addiw	a1,a1,1
    800044a6:	0289a503          	lw	a0,40(s3)
    800044aa:	fffff097          	auipc	ra,0xfffff
    800044ae:	f42080e7          	jalr	-190(ra) # 800033ec <bread>
    800044b2:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800044b4:	000aa583          	lw	a1,0(s5)
    800044b8:	0289a503          	lw	a0,40(s3)
    800044bc:	fffff097          	auipc	ra,0xfffff
    800044c0:	f30080e7          	jalr	-208(ra) # 800033ec <bread>
    800044c4:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800044c6:	40000613          	li	a2,1024
    800044ca:	05890593          	addi	a1,s2,88
    800044ce:	05850513          	addi	a0,a0,88
    800044d2:	ffffd097          	auipc	ra,0xffffd
    800044d6:	858080e7          	jalr	-1960(ra) # 80000d2a <memmove>
    bwrite(dbuf);  // write dst to disk
    800044da:	8526                	mv	a0,s1
    800044dc:	fffff097          	auipc	ra,0xfffff
    800044e0:	002080e7          	jalr	2(ra) # 800034de <bwrite>
    if(recovering == 0)
    800044e4:	f80b1ce3          	bnez	s6,8000447c <install_trans+0x36>
      bunpin(dbuf);
    800044e8:	8526                	mv	a0,s1
    800044ea:	fffff097          	auipc	ra,0xfffff
    800044ee:	10a080e7          	jalr	266(ra) # 800035f4 <bunpin>
    800044f2:	b769                	j	8000447c <install_trans+0x36>
}
    800044f4:	70e2                	ld	ra,56(sp)
    800044f6:	7442                	ld	s0,48(sp)
    800044f8:	74a2                	ld	s1,40(sp)
    800044fa:	7902                	ld	s2,32(sp)
    800044fc:	69e2                	ld	s3,24(sp)
    800044fe:	6a42                	ld	s4,16(sp)
    80004500:	6aa2                	ld	s5,8(sp)
    80004502:	6b02                	ld	s6,0(sp)
    80004504:	6121                	addi	sp,sp,64
    80004506:	8082                	ret
    80004508:	8082                	ret

000000008000450a <initlog>:
{
    8000450a:	7179                	addi	sp,sp,-48
    8000450c:	f406                	sd	ra,40(sp)
    8000450e:	f022                	sd	s0,32(sp)
    80004510:	ec26                	sd	s1,24(sp)
    80004512:	e84a                	sd	s2,16(sp)
    80004514:	e44e                	sd	s3,8(sp)
    80004516:	1800                	addi	s0,sp,48
    80004518:	892a                	mv	s2,a0
    8000451a:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000451c:	0001c497          	auipc	s1,0x1c
    80004520:	72448493          	addi	s1,s1,1828 # 80020c40 <log>
    80004524:	00004597          	auipc	a1,0x4
    80004528:	1ec58593          	addi	a1,a1,492 # 80008710 <syscalls+0x1f0>
    8000452c:	8526                	mv	a0,s1
    8000452e:	ffffc097          	auipc	ra,0xffffc
    80004532:	614080e7          	jalr	1556(ra) # 80000b42 <initlock>
  log.start = sb->logstart;
    80004536:	0149a583          	lw	a1,20(s3)
    8000453a:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000453c:	0109a783          	lw	a5,16(s3)
    80004540:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004542:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004546:	854a                	mv	a0,s2
    80004548:	fffff097          	auipc	ra,0xfffff
    8000454c:	ea4080e7          	jalr	-348(ra) # 800033ec <bread>
  log.lh.n = lh->n;
    80004550:	4d30                	lw	a2,88(a0)
    80004552:	d4d0                	sw	a2,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004554:	00c05f63          	blez	a2,80004572 <initlog+0x68>
    80004558:	87aa                	mv	a5,a0
    8000455a:	0001c717          	auipc	a4,0x1c
    8000455e:	71670713          	addi	a4,a4,1814 # 80020c70 <log+0x30>
    80004562:	060a                	slli	a2,a2,0x2
    80004564:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    80004566:	4ff4                	lw	a3,92(a5)
    80004568:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000456a:	0791                	addi	a5,a5,4
    8000456c:	0711                	addi	a4,a4,4
    8000456e:	fec79ce3          	bne	a5,a2,80004566 <initlog+0x5c>
  brelse(buf);
    80004572:	fffff097          	auipc	ra,0xfffff
    80004576:	faa080e7          	jalr	-86(ra) # 8000351c <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000457a:	4505                	li	a0,1
    8000457c:	00000097          	auipc	ra,0x0
    80004580:	eca080e7          	jalr	-310(ra) # 80004446 <install_trans>
  log.lh.n = 0;
    80004584:	0001c797          	auipc	a5,0x1c
    80004588:	6e07a423          	sw	zero,1768(a5) # 80020c6c <log+0x2c>
  write_head(); // clear the log
    8000458c:	00000097          	auipc	ra,0x0
    80004590:	e50080e7          	jalr	-432(ra) # 800043dc <write_head>
}
    80004594:	70a2                	ld	ra,40(sp)
    80004596:	7402                	ld	s0,32(sp)
    80004598:	64e2                	ld	s1,24(sp)
    8000459a:	6942                	ld	s2,16(sp)
    8000459c:	69a2                	ld	s3,8(sp)
    8000459e:	6145                	addi	sp,sp,48
    800045a0:	8082                	ret

00000000800045a2 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800045a2:	1101                	addi	sp,sp,-32
    800045a4:	ec06                	sd	ra,24(sp)
    800045a6:	e822                	sd	s0,16(sp)
    800045a8:	e426                	sd	s1,8(sp)
    800045aa:	e04a                	sd	s2,0(sp)
    800045ac:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800045ae:	0001c517          	auipc	a0,0x1c
    800045b2:	69250513          	addi	a0,a0,1682 # 80020c40 <log>
    800045b6:	ffffc097          	auipc	ra,0xffffc
    800045ba:	61c080e7          	jalr	1564(ra) # 80000bd2 <acquire>
  while(1){
    if(log.committing){
    800045be:	0001c497          	auipc	s1,0x1c
    800045c2:	68248493          	addi	s1,s1,1666 # 80020c40 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800045c6:	4979                	li	s2,30
    800045c8:	a039                	j	800045d6 <begin_op+0x34>
      sleep(&log, &log.lock);
    800045ca:	85a6                	mv	a1,s1
    800045cc:	8526                	mv	a0,s1
    800045ce:	ffffe097          	auipc	ra,0xffffe
    800045d2:	e84080e7          	jalr	-380(ra) # 80002452 <sleep>
    if(log.committing){
    800045d6:	50dc                	lw	a5,36(s1)
    800045d8:	fbed                	bnez	a5,800045ca <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800045da:	5098                	lw	a4,32(s1)
    800045dc:	2705                	addiw	a4,a4,1
    800045de:	0027179b          	slliw	a5,a4,0x2
    800045e2:	9fb9                	addw	a5,a5,a4
    800045e4:	0017979b          	slliw	a5,a5,0x1
    800045e8:	54d4                	lw	a3,44(s1)
    800045ea:	9fb5                	addw	a5,a5,a3
    800045ec:	00f95963          	bge	s2,a5,800045fe <begin_op+0x5c>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800045f0:	85a6                	mv	a1,s1
    800045f2:	8526                	mv	a0,s1
    800045f4:	ffffe097          	auipc	ra,0xffffe
    800045f8:	e5e080e7          	jalr	-418(ra) # 80002452 <sleep>
    800045fc:	bfe9                	j	800045d6 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800045fe:	0001c517          	auipc	a0,0x1c
    80004602:	64250513          	addi	a0,a0,1602 # 80020c40 <log>
    80004606:	d118                	sw	a4,32(a0)
      release(&log.lock);
    80004608:	ffffc097          	auipc	ra,0xffffc
    8000460c:	67e080e7          	jalr	1662(ra) # 80000c86 <release>
      break;
    }
  }
}
    80004610:	60e2                	ld	ra,24(sp)
    80004612:	6442                	ld	s0,16(sp)
    80004614:	64a2                	ld	s1,8(sp)
    80004616:	6902                	ld	s2,0(sp)
    80004618:	6105                	addi	sp,sp,32
    8000461a:	8082                	ret

000000008000461c <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000461c:	7139                	addi	sp,sp,-64
    8000461e:	fc06                	sd	ra,56(sp)
    80004620:	f822                	sd	s0,48(sp)
    80004622:	f426                	sd	s1,40(sp)
    80004624:	f04a                	sd	s2,32(sp)
    80004626:	ec4e                	sd	s3,24(sp)
    80004628:	e852                	sd	s4,16(sp)
    8000462a:	e456                	sd	s5,8(sp)
    8000462c:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000462e:	0001c497          	auipc	s1,0x1c
    80004632:	61248493          	addi	s1,s1,1554 # 80020c40 <log>
    80004636:	8526                	mv	a0,s1
    80004638:	ffffc097          	auipc	ra,0xffffc
    8000463c:	59a080e7          	jalr	1434(ra) # 80000bd2 <acquire>
  log.outstanding -= 1;
    80004640:	509c                	lw	a5,32(s1)
    80004642:	37fd                	addiw	a5,a5,-1
    80004644:	0007891b          	sext.w	s2,a5
    80004648:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000464a:	50dc                	lw	a5,36(s1)
    8000464c:	e7b9                	bnez	a5,8000469a <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000464e:	04091e63          	bnez	s2,800046aa <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004652:	0001c497          	auipc	s1,0x1c
    80004656:	5ee48493          	addi	s1,s1,1518 # 80020c40 <log>
    8000465a:	4785                	li	a5,1
    8000465c:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000465e:	8526                	mv	a0,s1
    80004660:	ffffc097          	auipc	ra,0xffffc
    80004664:	626080e7          	jalr	1574(ra) # 80000c86 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004668:	54dc                	lw	a5,44(s1)
    8000466a:	06f04763          	bgtz	a5,800046d8 <end_op+0xbc>
    acquire(&log.lock);
    8000466e:	0001c497          	auipc	s1,0x1c
    80004672:	5d248493          	addi	s1,s1,1490 # 80020c40 <log>
    80004676:	8526                	mv	a0,s1
    80004678:	ffffc097          	auipc	ra,0xffffc
    8000467c:	55a080e7          	jalr	1370(ra) # 80000bd2 <acquire>
    log.committing = 0;
    80004680:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004684:	8526                	mv	a0,s1
    80004686:	ffffe097          	auipc	ra,0xffffe
    8000468a:	e30080e7          	jalr	-464(ra) # 800024b6 <wakeup>
    release(&log.lock);
    8000468e:	8526                	mv	a0,s1
    80004690:	ffffc097          	auipc	ra,0xffffc
    80004694:	5f6080e7          	jalr	1526(ra) # 80000c86 <release>
}
    80004698:	a03d                	j	800046c6 <end_op+0xaa>
    panic("log.committing");
    8000469a:	00004517          	auipc	a0,0x4
    8000469e:	07e50513          	addi	a0,a0,126 # 80008718 <syscalls+0x1f8>
    800046a2:	ffffc097          	auipc	ra,0xffffc
    800046a6:	e9a080e7          	jalr	-358(ra) # 8000053c <panic>
    wakeup(&log);
    800046aa:	0001c497          	auipc	s1,0x1c
    800046ae:	59648493          	addi	s1,s1,1430 # 80020c40 <log>
    800046b2:	8526                	mv	a0,s1
    800046b4:	ffffe097          	auipc	ra,0xffffe
    800046b8:	e02080e7          	jalr	-510(ra) # 800024b6 <wakeup>
  release(&log.lock);
    800046bc:	8526                	mv	a0,s1
    800046be:	ffffc097          	auipc	ra,0xffffc
    800046c2:	5c8080e7          	jalr	1480(ra) # 80000c86 <release>
}
    800046c6:	70e2                	ld	ra,56(sp)
    800046c8:	7442                	ld	s0,48(sp)
    800046ca:	74a2                	ld	s1,40(sp)
    800046cc:	7902                	ld	s2,32(sp)
    800046ce:	69e2                	ld	s3,24(sp)
    800046d0:	6a42                	ld	s4,16(sp)
    800046d2:	6aa2                	ld	s5,8(sp)
    800046d4:	6121                	addi	sp,sp,64
    800046d6:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800046d8:	0001ca97          	auipc	s5,0x1c
    800046dc:	598a8a93          	addi	s5,s5,1432 # 80020c70 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800046e0:	0001ca17          	auipc	s4,0x1c
    800046e4:	560a0a13          	addi	s4,s4,1376 # 80020c40 <log>
    800046e8:	018a2583          	lw	a1,24(s4)
    800046ec:	012585bb          	addw	a1,a1,s2
    800046f0:	2585                	addiw	a1,a1,1
    800046f2:	028a2503          	lw	a0,40(s4)
    800046f6:	fffff097          	auipc	ra,0xfffff
    800046fa:	cf6080e7          	jalr	-778(ra) # 800033ec <bread>
    800046fe:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004700:	000aa583          	lw	a1,0(s5)
    80004704:	028a2503          	lw	a0,40(s4)
    80004708:	fffff097          	auipc	ra,0xfffff
    8000470c:	ce4080e7          	jalr	-796(ra) # 800033ec <bread>
    80004710:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004712:	40000613          	li	a2,1024
    80004716:	05850593          	addi	a1,a0,88
    8000471a:	05848513          	addi	a0,s1,88
    8000471e:	ffffc097          	auipc	ra,0xffffc
    80004722:	60c080e7          	jalr	1548(ra) # 80000d2a <memmove>
    bwrite(to);  // write the log
    80004726:	8526                	mv	a0,s1
    80004728:	fffff097          	auipc	ra,0xfffff
    8000472c:	db6080e7          	jalr	-586(ra) # 800034de <bwrite>
    brelse(from);
    80004730:	854e                	mv	a0,s3
    80004732:	fffff097          	auipc	ra,0xfffff
    80004736:	dea080e7          	jalr	-534(ra) # 8000351c <brelse>
    brelse(to);
    8000473a:	8526                	mv	a0,s1
    8000473c:	fffff097          	auipc	ra,0xfffff
    80004740:	de0080e7          	jalr	-544(ra) # 8000351c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004744:	2905                	addiw	s2,s2,1
    80004746:	0a91                	addi	s5,s5,4
    80004748:	02ca2783          	lw	a5,44(s4)
    8000474c:	f8f94ee3          	blt	s2,a5,800046e8 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004750:	00000097          	auipc	ra,0x0
    80004754:	c8c080e7          	jalr	-884(ra) # 800043dc <write_head>
    install_trans(0); // Now install writes to home locations
    80004758:	4501                	li	a0,0
    8000475a:	00000097          	auipc	ra,0x0
    8000475e:	cec080e7          	jalr	-788(ra) # 80004446 <install_trans>
    log.lh.n = 0;
    80004762:	0001c797          	auipc	a5,0x1c
    80004766:	5007a523          	sw	zero,1290(a5) # 80020c6c <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000476a:	00000097          	auipc	ra,0x0
    8000476e:	c72080e7          	jalr	-910(ra) # 800043dc <write_head>
    80004772:	bdf5                	j	8000466e <end_op+0x52>

0000000080004774 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004774:	1101                	addi	sp,sp,-32
    80004776:	ec06                	sd	ra,24(sp)
    80004778:	e822                	sd	s0,16(sp)
    8000477a:	e426                	sd	s1,8(sp)
    8000477c:	e04a                	sd	s2,0(sp)
    8000477e:	1000                	addi	s0,sp,32
    80004780:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004782:	0001c917          	auipc	s2,0x1c
    80004786:	4be90913          	addi	s2,s2,1214 # 80020c40 <log>
    8000478a:	854a                	mv	a0,s2
    8000478c:	ffffc097          	auipc	ra,0xffffc
    80004790:	446080e7          	jalr	1094(ra) # 80000bd2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004794:	02c92603          	lw	a2,44(s2)
    80004798:	47f5                	li	a5,29
    8000479a:	06c7c563          	blt	a5,a2,80004804 <log_write+0x90>
    8000479e:	0001c797          	auipc	a5,0x1c
    800047a2:	4be7a783          	lw	a5,1214(a5) # 80020c5c <log+0x1c>
    800047a6:	37fd                	addiw	a5,a5,-1
    800047a8:	04f65e63          	bge	a2,a5,80004804 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800047ac:	0001c797          	auipc	a5,0x1c
    800047b0:	4b47a783          	lw	a5,1204(a5) # 80020c60 <log+0x20>
    800047b4:	06f05063          	blez	a5,80004814 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800047b8:	4781                	li	a5,0
    800047ba:	06c05563          	blez	a2,80004824 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800047be:	44cc                	lw	a1,12(s1)
    800047c0:	0001c717          	auipc	a4,0x1c
    800047c4:	4b070713          	addi	a4,a4,1200 # 80020c70 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800047c8:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800047ca:	4314                	lw	a3,0(a4)
    800047cc:	04b68c63          	beq	a3,a1,80004824 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800047d0:	2785                	addiw	a5,a5,1
    800047d2:	0711                	addi	a4,a4,4
    800047d4:	fef61be3          	bne	a2,a5,800047ca <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800047d8:	0621                	addi	a2,a2,8
    800047da:	060a                	slli	a2,a2,0x2
    800047dc:	0001c797          	auipc	a5,0x1c
    800047e0:	46478793          	addi	a5,a5,1124 # 80020c40 <log>
    800047e4:	97b2                	add	a5,a5,a2
    800047e6:	44d8                	lw	a4,12(s1)
    800047e8:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800047ea:	8526                	mv	a0,s1
    800047ec:	fffff097          	auipc	ra,0xfffff
    800047f0:	dcc080e7          	jalr	-564(ra) # 800035b8 <bpin>
    log.lh.n++;
    800047f4:	0001c717          	auipc	a4,0x1c
    800047f8:	44c70713          	addi	a4,a4,1100 # 80020c40 <log>
    800047fc:	575c                	lw	a5,44(a4)
    800047fe:	2785                	addiw	a5,a5,1
    80004800:	d75c                	sw	a5,44(a4)
    80004802:	a82d                	j	8000483c <log_write+0xc8>
    panic("too big a transaction");
    80004804:	00004517          	auipc	a0,0x4
    80004808:	f2450513          	addi	a0,a0,-220 # 80008728 <syscalls+0x208>
    8000480c:	ffffc097          	auipc	ra,0xffffc
    80004810:	d30080e7          	jalr	-720(ra) # 8000053c <panic>
    panic("log_write outside of trans");
    80004814:	00004517          	auipc	a0,0x4
    80004818:	f2c50513          	addi	a0,a0,-212 # 80008740 <syscalls+0x220>
    8000481c:	ffffc097          	auipc	ra,0xffffc
    80004820:	d20080e7          	jalr	-736(ra) # 8000053c <panic>
  log.lh.block[i] = b->blockno;
    80004824:	00878693          	addi	a3,a5,8
    80004828:	068a                	slli	a3,a3,0x2
    8000482a:	0001c717          	auipc	a4,0x1c
    8000482e:	41670713          	addi	a4,a4,1046 # 80020c40 <log>
    80004832:	9736                	add	a4,a4,a3
    80004834:	44d4                	lw	a3,12(s1)
    80004836:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004838:	faf609e3          	beq	a2,a5,800047ea <log_write+0x76>
  }
  release(&log.lock);
    8000483c:	0001c517          	auipc	a0,0x1c
    80004840:	40450513          	addi	a0,a0,1028 # 80020c40 <log>
    80004844:	ffffc097          	auipc	ra,0xffffc
    80004848:	442080e7          	jalr	1090(ra) # 80000c86 <release>
}
    8000484c:	60e2                	ld	ra,24(sp)
    8000484e:	6442                	ld	s0,16(sp)
    80004850:	64a2                	ld	s1,8(sp)
    80004852:	6902                	ld	s2,0(sp)
    80004854:	6105                	addi	sp,sp,32
    80004856:	8082                	ret

0000000080004858 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004858:	1101                	addi	sp,sp,-32
    8000485a:	ec06                	sd	ra,24(sp)
    8000485c:	e822                	sd	s0,16(sp)
    8000485e:	e426                	sd	s1,8(sp)
    80004860:	e04a                	sd	s2,0(sp)
    80004862:	1000                	addi	s0,sp,32
    80004864:	84aa                	mv	s1,a0
    80004866:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004868:	00004597          	auipc	a1,0x4
    8000486c:	ef858593          	addi	a1,a1,-264 # 80008760 <syscalls+0x240>
    80004870:	0521                	addi	a0,a0,8
    80004872:	ffffc097          	auipc	ra,0xffffc
    80004876:	2d0080e7          	jalr	720(ra) # 80000b42 <initlock>
  lk->name = name;
    8000487a:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000487e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004882:	0204a423          	sw	zero,40(s1)
}
    80004886:	60e2                	ld	ra,24(sp)
    80004888:	6442                	ld	s0,16(sp)
    8000488a:	64a2                	ld	s1,8(sp)
    8000488c:	6902                	ld	s2,0(sp)
    8000488e:	6105                	addi	sp,sp,32
    80004890:	8082                	ret

0000000080004892 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004892:	1101                	addi	sp,sp,-32
    80004894:	ec06                	sd	ra,24(sp)
    80004896:	e822                	sd	s0,16(sp)
    80004898:	e426                	sd	s1,8(sp)
    8000489a:	e04a                	sd	s2,0(sp)
    8000489c:	1000                	addi	s0,sp,32
    8000489e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800048a0:	00850913          	addi	s2,a0,8
    800048a4:	854a                	mv	a0,s2
    800048a6:	ffffc097          	auipc	ra,0xffffc
    800048aa:	32c080e7          	jalr	812(ra) # 80000bd2 <acquire>
  while (lk->locked) {
    800048ae:	409c                	lw	a5,0(s1)
    800048b0:	cb89                	beqz	a5,800048c2 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800048b2:	85ca                	mv	a1,s2
    800048b4:	8526                	mv	a0,s1
    800048b6:	ffffe097          	auipc	ra,0xffffe
    800048ba:	b9c080e7          	jalr	-1124(ra) # 80002452 <sleep>
  while (lk->locked) {
    800048be:	409c                	lw	a5,0(s1)
    800048c0:	fbed                	bnez	a5,800048b2 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800048c2:	4785                	li	a5,1
    800048c4:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800048c6:	ffffd097          	auipc	ra,0xffffd
    800048ca:	3ce080e7          	jalr	974(ra) # 80001c94 <myproc>
    800048ce:	591c                	lw	a5,48(a0)
    800048d0:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800048d2:	854a                	mv	a0,s2
    800048d4:	ffffc097          	auipc	ra,0xffffc
    800048d8:	3b2080e7          	jalr	946(ra) # 80000c86 <release>
}
    800048dc:	60e2                	ld	ra,24(sp)
    800048de:	6442                	ld	s0,16(sp)
    800048e0:	64a2                	ld	s1,8(sp)
    800048e2:	6902                	ld	s2,0(sp)
    800048e4:	6105                	addi	sp,sp,32
    800048e6:	8082                	ret

00000000800048e8 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800048e8:	1101                	addi	sp,sp,-32
    800048ea:	ec06                	sd	ra,24(sp)
    800048ec:	e822                	sd	s0,16(sp)
    800048ee:	e426                	sd	s1,8(sp)
    800048f0:	e04a                	sd	s2,0(sp)
    800048f2:	1000                	addi	s0,sp,32
    800048f4:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800048f6:	00850913          	addi	s2,a0,8
    800048fa:	854a                	mv	a0,s2
    800048fc:	ffffc097          	auipc	ra,0xffffc
    80004900:	2d6080e7          	jalr	726(ra) # 80000bd2 <acquire>
  lk->locked = 0;
    80004904:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004908:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000490c:	8526                	mv	a0,s1
    8000490e:	ffffe097          	auipc	ra,0xffffe
    80004912:	ba8080e7          	jalr	-1112(ra) # 800024b6 <wakeup>
  release(&lk->lk);
    80004916:	854a                	mv	a0,s2
    80004918:	ffffc097          	auipc	ra,0xffffc
    8000491c:	36e080e7          	jalr	878(ra) # 80000c86 <release>
}
    80004920:	60e2                	ld	ra,24(sp)
    80004922:	6442                	ld	s0,16(sp)
    80004924:	64a2                	ld	s1,8(sp)
    80004926:	6902                	ld	s2,0(sp)
    80004928:	6105                	addi	sp,sp,32
    8000492a:	8082                	ret

000000008000492c <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000492c:	7179                	addi	sp,sp,-48
    8000492e:	f406                	sd	ra,40(sp)
    80004930:	f022                	sd	s0,32(sp)
    80004932:	ec26                	sd	s1,24(sp)
    80004934:	e84a                	sd	s2,16(sp)
    80004936:	e44e                	sd	s3,8(sp)
    80004938:	1800                	addi	s0,sp,48
    8000493a:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000493c:	00850913          	addi	s2,a0,8
    80004940:	854a                	mv	a0,s2
    80004942:	ffffc097          	auipc	ra,0xffffc
    80004946:	290080e7          	jalr	656(ra) # 80000bd2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000494a:	409c                	lw	a5,0(s1)
    8000494c:	ef99                	bnez	a5,8000496a <holdingsleep+0x3e>
    8000494e:	4481                	li	s1,0
  release(&lk->lk);
    80004950:	854a                	mv	a0,s2
    80004952:	ffffc097          	auipc	ra,0xffffc
    80004956:	334080e7          	jalr	820(ra) # 80000c86 <release>
  return r;
}
    8000495a:	8526                	mv	a0,s1
    8000495c:	70a2                	ld	ra,40(sp)
    8000495e:	7402                	ld	s0,32(sp)
    80004960:	64e2                	ld	s1,24(sp)
    80004962:	6942                	ld	s2,16(sp)
    80004964:	69a2                	ld	s3,8(sp)
    80004966:	6145                	addi	sp,sp,48
    80004968:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000496a:	0284a983          	lw	s3,40(s1)
    8000496e:	ffffd097          	auipc	ra,0xffffd
    80004972:	326080e7          	jalr	806(ra) # 80001c94 <myproc>
    80004976:	5904                	lw	s1,48(a0)
    80004978:	413484b3          	sub	s1,s1,s3
    8000497c:	0014b493          	seqz	s1,s1
    80004980:	bfc1                	j	80004950 <holdingsleep+0x24>

0000000080004982 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004982:	1141                	addi	sp,sp,-16
    80004984:	e406                	sd	ra,8(sp)
    80004986:	e022                	sd	s0,0(sp)
    80004988:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000498a:	00004597          	auipc	a1,0x4
    8000498e:	de658593          	addi	a1,a1,-538 # 80008770 <syscalls+0x250>
    80004992:	0001c517          	auipc	a0,0x1c
    80004996:	3f650513          	addi	a0,a0,1014 # 80020d88 <ftable>
    8000499a:	ffffc097          	auipc	ra,0xffffc
    8000499e:	1a8080e7          	jalr	424(ra) # 80000b42 <initlock>
}
    800049a2:	60a2                	ld	ra,8(sp)
    800049a4:	6402                	ld	s0,0(sp)
    800049a6:	0141                	addi	sp,sp,16
    800049a8:	8082                	ret

00000000800049aa <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800049aa:	1101                	addi	sp,sp,-32
    800049ac:	ec06                	sd	ra,24(sp)
    800049ae:	e822                	sd	s0,16(sp)
    800049b0:	e426                	sd	s1,8(sp)
    800049b2:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800049b4:	0001c517          	auipc	a0,0x1c
    800049b8:	3d450513          	addi	a0,a0,980 # 80020d88 <ftable>
    800049bc:	ffffc097          	auipc	ra,0xffffc
    800049c0:	216080e7          	jalr	534(ra) # 80000bd2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800049c4:	0001c497          	auipc	s1,0x1c
    800049c8:	3dc48493          	addi	s1,s1,988 # 80020da0 <ftable+0x18>
    800049cc:	0001d717          	auipc	a4,0x1d
    800049d0:	37470713          	addi	a4,a4,884 # 80021d40 <disk>
    if(f->ref == 0){
    800049d4:	40dc                	lw	a5,4(s1)
    800049d6:	cf99                	beqz	a5,800049f4 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800049d8:	02848493          	addi	s1,s1,40
    800049dc:	fee49ce3          	bne	s1,a4,800049d4 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800049e0:	0001c517          	auipc	a0,0x1c
    800049e4:	3a850513          	addi	a0,a0,936 # 80020d88 <ftable>
    800049e8:	ffffc097          	auipc	ra,0xffffc
    800049ec:	29e080e7          	jalr	670(ra) # 80000c86 <release>
  return 0;
    800049f0:	4481                	li	s1,0
    800049f2:	a819                	j	80004a08 <filealloc+0x5e>
      f->ref = 1;
    800049f4:	4785                	li	a5,1
    800049f6:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800049f8:	0001c517          	auipc	a0,0x1c
    800049fc:	39050513          	addi	a0,a0,912 # 80020d88 <ftable>
    80004a00:	ffffc097          	auipc	ra,0xffffc
    80004a04:	286080e7          	jalr	646(ra) # 80000c86 <release>
}
    80004a08:	8526                	mv	a0,s1
    80004a0a:	60e2                	ld	ra,24(sp)
    80004a0c:	6442                	ld	s0,16(sp)
    80004a0e:	64a2                	ld	s1,8(sp)
    80004a10:	6105                	addi	sp,sp,32
    80004a12:	8082                	ret

0000000080004a14 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004a14:	1101                	addi	sp,sp,-32
    80004a16:	ec06                	sd	ra,24(sp)
    80004a18:	e822                	sd	s0,16(sp)
    80004a1a:	e426                	sd	s1,8(sp)
    80004a1c:	1000                	addi	s0,sp,32
    80004a1e:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004a20:	0001c517          	auipc	a0,0x1c
    80004a24:	36850513          	addi	a0,a0,872 # 80020d88 <ftable>
    80004a28:	ffffc097          	auipc	ra,0xffffc
    80004a2c:	1aa080e7          	jalr	426(ra) # 80000bd2 <acquire>
  if(f->ref < 1)
    80004a30:	40dc                	lw	a5,4(s1)
    80004a32:	02f05263          	blez	a5,80004a56 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004a36:	2785                	addiw	a5,a5,1
    80004a38:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004a3a:	0001c517          	auipc	a0,0x1c
    80004a3e:	34e50513          	addi	a0,a0,846 # 80020d88 <ftable>
    80004a42:	ffffc097          	auipc	ra,0xffffc
    80004a46:	244080e7          	jalr	580(ra) # 80000c86 <release>
  return f;
}
    80004a4a:	8526                	mv	a0,s1
    80004a4c:	60e2                	ld	ra,24(sp)
    80004a4e:	6442                	ld	s0,16(sp)
    80004a50:	64a2                	ld	s1,8(sp)
    80004a52:	6105                	addi	sp,sp,32
    80004a54:	8082                	ret
    panic("filedup");
    80004a56:	00004517          	auipc	a0,0x4
    80004a5a:	d2250513          	addi	a0,a0,-734 # 80008778 <syscalls+0x258>
    80004a5e:	ffffc097          	auipc	ra,0xffffc
    80004a62:	ade080e7          	jalr	-1314(ra) # 8000053c <panic>

0000000080004a66 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004a66:	7139                	addi	sp,sp,-64
    80004a68:	fc06                	sd	ra,56(sp)
    80004a6a:	f822                	sd	s0,48(sp)
    80004a6c:	f426                	sd	s1,40(sp)
    80004a6e:	f04a                	sd	s2,32(sp)
    80004a70:	ec4e                	sd	s3,24(sp)
    80004a72:	e852                	sd	s4,16(sp)
    80004a74:	e456                	sd	s5,8(sp)
    80004a76:	0080                	addi	s0,sp,64
    80004a78:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004a7a:	0001c517          	auipc	a0,0x1c
    80004a7e:	30e50513          	addi	a0,a0,782 # 80020d88 <ftable>
    80004a82:	ffffc097          	auipc	ra,0xffffc
    80004a86:	150080e7          	jalr	336(ra) # 80000bd2 <acquire>
  if(f->ref < 1)
    80004a8a:	40dc                	lw	a5,4(s1)
    80004a8c:	06f05163          	blez	a5,80004aee <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004a90:	37fd                	addiw	a5,a5,-1
    80004a92:	0007871b          	sext.w	a4,a5
    80004a96:	c0dc                	sw	a5,4(s1)
    80004a98:	06e04363          	bgtz	a4,80004afe <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004a9c:	0004a903          	lw	s2,0(s1)
    80004aa0:	0094ca83          	lbu	s5,9(s1)
    80004aa4:	0104ba03          	ld	s4,16(s1)
    80004aa8:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004aac:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004ab0:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004ab4:	0001c517          	auipc	a0,0x1c
    80004ab8:	2d450513          	addi	a0,a0,724 # 80020d88 <ftable>
    80004abc:	ffffc097          	auipc	ra,0xffffc
    80004ac0:	1ca080e7          	jalr	458(ra) # 80000c86 <release>

  if(ff.type == FD_PIPE){
    80004ac4:	4785                	li	a5,1
    80004ac6:	04f90d63          	beq	s2,a5,80004b20 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004aca:	3979                	addiw	s2,s2,-2
    80004acc:	4785                	li	a5,1
    80004ace:	0527e063          	bltu	a5,s2,80004b0e <fileclose+0xa8>
    begin_op();
    80004ad2:	00000097          	auipc	ra,0x0
    80004ad6:	ad0080e7          	jalr	-1328(ra) # 800045a2 <begin_op>
    iput(ff.ip);
    80004ada:	854e                	mv	a0,s3
    80004adc:	fffff097          	auipc	ra,0xfffff
    80004ae0:	2da080e7          	jalr	730(ra) # 80003db6 <iput>
    end_op();
    80004ae4:	00000097          	auipc	ra,0x0
    80004ae8:	b38080e7          	jalr	-1224(ra) # 8000461c <end_op>
    80004aec:	a00d                	j	80004b0e <fileclose+0xa8>
    panic("fileclose");
    80004aee:	00004517          	auipc	a0,0x4
    80004af2:	c9250513          	addi	a0,a0,-878 # 80008780 <syscalls+0x260>
    80004af6:	ffffc097          	auipc	ra,0xffffc
    80004afa:	a46080e7          	jalr	-1466(ra) # 8000053c <panic>
    release(&ftable.lock);
    80004afe:	0001c517          	auipc	a0,0x1c
    80004b02:	28a50513          	addi	a0,a0,650 # 80020d88 <ftable>
    80004b06:	ffffc097          	auipc	ra,0xffffc
    80004b0a:	180080e7          	jalr	384(ra) # 80000c86 <release>
  }
}
    80004b0e:	70e2                	ld	ra,56(sp)
    80004b10:	7442                	ld	s0,48(sp)
    80004b12:	74a2                	ld	s1,40(sp)
    80004b14:	7902                	ld	s2,32(sp)
    80004b16:	69e2                	ld	s3,24(sp)
    80004b18:	6a42                	ld	s4,16(sp)
    80004b1a:	6aa2                	ld	s5,8(sp)
    80004b1c:	6121                	addi	sp,sp,64
    80004b1e:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004b20:	85d6                	mv	a1,s5
    80004b22:	8552                	mv	a0,s4
    80004b24:	00000097          	auipc	ra,0x0
    80004b28:	348080e7          	jalr	840(ra) # 80004e6c <pipeclose>
    80004b2c:	b7cd                	j	80004b0e <fileclose+0xa8>

0000000080004b2e <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004b2e:	715d                	addi	sp,sp,-80
    80004b30:	e486                	sd	ra,72(sp)
    80004b32:	e0a2                	sd	s0,64(sp)
    80004b34:	fc26                	sd	s1,56(sp)
    80004b36:	f84a                	sd	s2,48(sp)
    80004b38:	f44e                	sd	s3,40(sp)
    80004b3a:	0880                	addi	s0,sp,80
    80004b3c:	84aa                	mv	s1,a0
    80004b3e:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004b40:	ffffd097          	auipc	ra,0xffffd
    80004b44:	154080e7          	jalr	340(ra) # 80001c94 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004b48:	409c                	lw	a5,0(s1)
    80004b4a:	37f9                	addiw	a5,a5,-2
    80004b4c:	4705                	li	a4,1
    80004b4e:	04f76763          	bltu	a4,a5,80004b9c <filestat+0x6e>
    80004b52:	892a                	mv	s2,a0
    ilock(f->ip);
    80004b54:	6c88                	ld	a0,24(s1)
    80004b56:	fffff097          	auipc	ra,0xfffff
    80004b5a:	0a6080e7          	jalr	166(ra) # 80003bfc <ilock>
    stati(f->ip, &st);
    80004b5e:	fb840593          	addi	a1,s0,-72
    80004b62:	6c88                	ld	a0,24(s1)
    80004b64:	fffff097          	auipc	ra,0xfffff
    80004b68:	322080e7          	jalr	802(ra) # 80003e86 <stati>
    iunlock(f->ip);
    80004b6c:	6c88                	ld	a0,24(s1)
    80004b6e:	fffff097          	auipc	ra,0xfffff
    80004b72:	150080e7          	jalr	336(ra) # 80003cbe <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004b76:	46e1                	li	a3,24
    80004b78:	fb840613          	addi	a2,s0,-72
    80004b7c:	85ce                	mv	a1,s3
    80004b7e:	05093503          	ld	a0,80(s2)
    80004b82:	ffffd097          	auipc	ra,0xffffd
    80004b86:	ae4080e7          	jalr	-1308(ra) # 80001666 <copyout>
    80004b8a:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004b8e:	60a6                	ld	ra,72(sp)
    80004b90:	6406                	ld	s0,64(sp)
    80004b92:	74e2                	ld	s1,56(sp)
    80004b94:	7942                	ld	s2,48(sp)
    80004b96:	79a2                	ld	s3,40(sp)
    80004b98:	6161                	addi	sp,sp,80
    80004b9a:	8082                	ret
  return -1;
    80004b9c:	557d                	li	a0,-1
    80004b9e:	bfc5                	j	80004b8e <filestat+0x60>

0000000080004ba0 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004ba0:	7179                	addi	sp,sp,-48
    80004ba2:	f406                	sd	ra,40(sp)
    80004ba4:	f022                	sd	s0,32(sp)
    80004ba6:	ec26                	sd	s1,24(sp)
    80004ba8:	e84a                	sd	s2,16(sp)
    80004baa:	e44e                	sd	s3,8(sp)
    80004bac:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004bae:	00854783          	lbu	a5,8(a0)
    80004bb2:	c3d5                	beqz	a5,80004c56 <fileread+0xb6>
    80004bb4:	84aa                	mv	s1,a0
    80004bb6:	89ae                	mv	s3,a1
    80004bb8:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004bba:	411c                	lw	a5,0(a0)
    80004bbc:	4705                	li	a4,1
    80004bbe:	04e78963          	beq	a5,a4,80004c10 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004bc2:	470d                	li	a4,3
    80004bc4:	04e78d63          	beq	a5,a4,80004c1e <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004bc8:	4709                	li	a4,2
    80004bca:	06e79e63          	bne	a5,a4,80004c46 <fileread+0xa6>
    ilock(f->ip);
    80004bce:	6d08                	ld	a0,24(a0)
    80004bd0:	fffff097          	auipc	ra,0xfffff
    80004bd4:	02c080e7          	jalr	44(ra) # 80003bfc <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004bd8:	874a                	mv	a4,s2
    80004bda:	5094                	lw	a3,32(s1)
    80004bdc:	864e                	mv	a2,s3
    80004bde:	4585                	li	a1,1
    80004be0:	6c88                	ld	a0,24(s1)
    80004be2:	fffff097          	auipc	ra,0xfffff
    80004be6:	2ce080e7          	jalr	718(ra) # 80003eb0 <readi>
    80004bea:	892a                	mv	s2,a0
    80004bec:	00a05563          	blez	a0,80004bf6 <fileread+0x56>
      f->off += r;
    80004bf0:	509c                	lw	a5,32(s1)
    80004bf2:	9fa9                	addw	a5,a5,a0
    80004bf4:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004bf6:	6c88                	ld	a0,24(s1)
    80004bf8:	fffff097          	auipc	ra,0xfffff
    80004bfc:	0c6080e7          	jalr	198(ra) # 80003cbe <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004c00:	854a                	mv	a0,s2
    80004c02:	70a2                	ld	ra,40(sp)
    80004c04:	7402                	ld	s0,32(sp)
    80004c06:	64e2                	ld	s1,24(sp)
    80004c08:	6942                	ld	s2,16(sp)
    80004c0a:	69a2                	ld	s3,8(sp)
    80004c0c:	6145                	addi	sp,sp,48
    80004c0e:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004c10:	6908                	ld	a0,16(a0)
    80004c12:	00000097          	auipc	ra,0x0
    80004c16:	3c2080e7          	jalr	962(ra) # 80004fd4 <piperead>
    80004c1a:	892a                	mv	s2,a0
    80004c1c:	b7d5                	j	80004c00 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004c1e:	02451783          	lh	a5,36(a0)
    80004c22:	03079693          	slli	a3,a5,0x30
    80004c26:	92c1                	srli	a3,a3,0x30
    80004c28:	4725                	li	a4,9
    80004c2a:	02d76863          	bltu	a4,a3,80004c5a <fileread+0xba>
    80004c2e:	0792                	slli	a5,a5,0x4
    80004c30:	0001c717          	auipc	a4,0x1c
    80004c34:	0b870713          	addi	a4,a4,184 # 80020ce8 <devsw>
    80004c38:	97ba                	add	a5,a5,a4
    80004c3a:	639c                	ld	a5,0(a5)
    80004c3c:	c38d                	beqz	a5,80004c5e <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004c3e:	4505                	li	a0,1
    80004c40:	9782                	jalr	a5
    80004c42:	892a                	mv	s2,a0
    80004c44:	bf75                	j	80004c00 <fileread+0x60>
    panic("fileread");
    80004c46:	00004517          	auipc	a0,0x4
    80004c4a:	b4a50513          	addi	a0,a0,-1206 # 80008790 <syscalls+0x270>
    80004c4e:	ffffc097          	auipc	ra,0xffffc
    80004c52:	8ee080e7          	jalr	-1810(ra) # 8000053c <panic>
    return -1;
    80004c56:	597d                	li	s2,-1
    80004c58:	b765                	j	80004c00 <fileread+0x60>
      return -1;
    80004c5a:	597d                	li	s2,-1
    80004c5c:	b755                	j	80004c00 <fileread+0x60>
    80004c5e:	597d                	li	s2,-1
    80004c60:	b745                	j	80004c00 <fileread+0x60>

0000000080004c62 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004c62:	00954783          	lbu	a5,9(a0)
    80004c66:	10078e63          	beqz	a5,80004d82 <filewrite+0x120>
{
    80004c6a:	715d                	addi	sp,sp,-80
    80004c6c:	e486                	sd	ra,72(sp)
    80004c6e:	e0a2                	sd	s0,64(sp)
    80004c70:	fc26                	sd	s1,56(sp)
    80004c72:	f84a                	sd	s2,48(sp)
    80004c74:	f44e                	sd	s3,40(sp)
    80004c76:	f052                	sd	s4,32(sp)
    80004c78:	ec56                	sd	s5,24(sp)
    80004c7a:	e85a                	sd	s6,16(sp)
    80004c7c:	e45e                	sd	s7,8(sp)
    80004c7e:	e062                	sd	s8,0(sp)
    80004c80:	0880                	addi	s0,sp,80
    80004c82:	892a                	mv	s2,a0
    80004c84:	8b2e                	mv	s6,a1
    80004c86:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004c88:	411c                	lw	a5,0(a0)
    80004c8a:	4705                	li	a4,1
    80004c8c:	02e78263          	beq	a5,a4,80004cb0 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004c90:	470d                	li	a4,3
    80004c92:	02e78563          	beq	a5,a4,80004cbc <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004c96:	4709                	li	a4,2
    80004c98:	0ce79d63          	bne	a5,a4,80004d72 <filewrite+0x110>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004c9c:	0ac05b63          	blez	a2,80004d52 <filewrite+0xf0>
    int i = 0;
    80004ca0:	4981                	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    80004ca2:	6b85                	lui	s7,0x1
    80004ca4:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004ca8:	6c05                	lui	s8,0x1
    80004caa:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004cae:	a851                	j	80004d42 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004cb0:	6908                	ld	a0,16(a0)
    80004cb2:	00000097          	auipc	ra,0x0
    80004cb6:	22a080e7          	jalr	554(ra) # 80004edc <pipewrite>
    80004cba:	a045                	j	80004d5a <filewrite+0xf8>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004cbc:	02451783          	lh	a5,36(a0)
    80004cc0:	03079693          	slli	a3,a5,0x30
    80004cc4:	92c1                	srli	a3,a3,0x30
    80004cc6:	4725                	li	a4,9
    80004cc8:	0ad76f63          	bltu	a4,a3,80004d86 <filewrite+0x124>
    80004ccc:	0792                	slli	a5,a5,0x4
    80004cce:	0001c717          	auipc	a4,0x1c
    80004cd2:	01a70713          	addi	a4,a4,26 # 80020ce8 <devsw>
    80004cd6:	97ba                	add	a5,a5,a4
    80004cd8:	679c                	ld	a5,8(a5)
    80004cda:	cbc5                	beqz	a5,80004d8a <filewrite+0x128>
    ret = devsw[f->major].write(1, addr, n);
    80004cdc:	4505                	li	a0,1
    80004cde:	9782                	jalr	a5
    80004ce0:	a8ad                	j	80004d5a <filewrite+0xf8>
      if(n1 > max)
    80004ce2:	00048a9b          	sext.w	s5,s1
        n1 = max;

      begin_op();
    80004ce6:	00000097          	auipc	ra,0x0
    80004cea:	8bc080e7          	jalr	-1860(ra) # 800045a2 <begin_op>
      ilock(f->ip);
    80004cee:	01893503          	ld	a0,24(s2)
    80004cf2:	fffff097          	auipc	ra,0xfffff
    80004cf6:	f0a080e7          	jalr	-246(ra) # 80003bfc <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004cfa:	8756                	mv	a4,s5
    80004cfc:	02092683          	lw	a3,32(s2)
    80004d00:	01698633          	add	a2,s3,s6
    80004d04:	4585                	li	a1,1
    80004d06:	01893503          	ld	a0,24(s2)
    80004d0a:	fffff097          	auipc	ra,0xfffff
    80004d0e:	29e080e7          	jalr	670(ra) # 80003fa8 <writei>
    80004d12:	84aa                	mv	s1,a0
    80004d14:	00a05763          	blez	a0,80004d22 <filewrite+0xc0>
        f->off += r;
    80004d18:	02092783          	lw	a5,32(s2)
    80004d1c:	9fa9                	addw	a5,a5,a0
    80004d1e:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004d22:	01893503          	ld	a0,24(s2)
    80004d26:	fffff097          	auipc	ra,0xfffff
    80004d2a:	f98080e7          	jalr	-104(ra) # 80003cbe <iunlock>
      end_op();
    80004d2e:	00000097          	auipc	ra,0x0
    80004d32:	8ee080e7          	jalr	-1810(ra) # 8000461c <end_op>

      if(r != n1){
    80004d36:	009a9f63          	bne	s5,s1,80004d54 <filewrite+0xf2>
        // error from writei
        break;
      }
      i += r;
    80004d3a:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004d3e:	0149db63          	bge	s3,s4,80004d54 <filewrite+0xf2>
      int n1 = n - i;
    80004d42:	413a04bb          	subw	s1,s4,s3
      if(n1 > max)
    80004d46:	0004879b          	sext.w	a5,s1
    80004d4a:	f8fbdce3          	bge	s7,a5,80004ce2 <filewrite+0x80>
    80004d4e:	84e2                	mv	s1,s8
    80004d50:	bf49                	j	80004ce2 <filewrite+0x80>
    int i = 0;
    80004d52:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004d54:	033a1d63          	bne	s4,s3,80004d8e <filewrite+0x12c>
    80004d58:	8552                	mv	a0,s4
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004d5a:	60a6                	ld	ra,72(sp)
    80004d5c:	6406                	ld	s0,64(sp)
    80004d5e:	74e2                	ld	s1,56(sp)
    80004d60:	7942                	ld	s2,48(sp)
    80004d62:	79a2                	ld	s3,40(sp)
    80004d64:	7a02                	ld	s4,32(sp)
    80004d66:	6ae2                	ld	s5,24(sp)
    80004d68:	6b42                	ld	s6,16(sp)
    80004d6a:	6ba2                	ld	s7,8(sp)
    80004d6c:	6c02                	ld	s8,0(sp)
    80004d6e:	6161                	addi	sp,sp,80
    80004d70:	8082                	ret
    panic("filewrite");
    80004d72:	00004517          	auipc	a0,0x4
    80004d76:	a2e50513          	addi	a0,a0,-1490 # 800087a0 <syscalls+0x280>
    80004d7a:	ffffb097          	auipc	ra,0xffffb
    80004d7e:	7c2080e7          	jalr	1986(ra) # 8000053c <panic>
    return -1;
    80004d82:	557d                	li	a0,-1
}
    80004d84:	8082                	ret
      return -1;
    80004d86:	557d                	li	a0,-1
    80004d88:	bfc9                	j	80004d5a <filewrite+0xf8>
    80004d8a:	557d                	li	a0,-1
    80004d8c:	b7f9                	j	80004d5a <filewrite+0xf8>
    ret = (i == n ? n : -1);
    80004d8e:	557d                	li	a0,-1
    80004d90:	b7e9                	j	80004d5a <filewrite+0xf8>

0000000080004d92 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004d92:	7179                	addi	sp,sp,-48
    80004d94:	f406                	sd	ra,40(sp)
    80004d96:	f022                	sd	s0,32(sp)
    80004d98:	ec26                	sd	s1,24(sp)
    80004d9a:	e84a                	sd	s2,16(sp)
    80004d9c:	e44e                	sd	s3,8(sp)
    80004d9e:	e052                	sd	s4,0(sp)
    80004da0:	1800                	addi	s0,sp,48
    80004da2:	84aa                	mv	s1,a0
    80004da4:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004da6:	0005b023          	sd	zero,0(a1)
    80004daa:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004dae:	00000097          	auipc	ra,0x0
    80004db2:	bfc080e7          	jalr	-1028(ra) # 800049aa <filealloc>
    80004db6:	e088                	sd	a0,0(s1)
    80004db8:	c551                	beqz	a0,80004e44 <pipealloc+0xb2>
    80004dba:	00000097          	auipc	ra,0x0
    80004dbe:	bf0080e7          	jalr	-1040(ra) # 800049aa <filealloc>
    80004dc2:	00aa3023          	sd	a0,0(s4)
    80004dc6:	c92d                	beqz	a0,80004e38 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004dc8:	ffffc097          	auipc	ra,0xffffc
    80004dcc:	d1a080e7          	jalr	-742(ra) # 80000ae2 <kalloc>
    80004dd0:	892a                	mv	s2,a0
    80004dd2:	c125                	beqz	a0,80004e32 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004dd4:	4985                	li	s3,1
    80004dd6:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004dda:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004dde:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004de2:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004de6:	00004597          	auipc	a1,0x4
    80004dea:	9ca58593          	addi	a1,a1,-1590 # 800087b0 <syscalls+0x290>
    80004dee:	ffffc097          	auipc	ra,0xffffc
    80004df2:	d54080e7          	jalr	-684(ra) # 80000b42 <initlock>
  (*f0)->type = FD_PIPE;
    80004df6:	609c                	ld	a5,0(s1)
    80004df8:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004dfc:	609c                	ld	a5,0(s1)
    80004dfe:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004e02:	609c                	ld	a5,0(s1)
    80004e04:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004e08:	609c                	ld	a5,0(s1)
    80004e0a:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004e0e:	000a3783          	ld	a5,0(s4)
    80004e12:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004e16:	000a3783          	ld	a5,0(s4)
    80004e1a:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004e1e:	000a3783          	ld	a5,0(s4)
    80004e22:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004e26:	000a3783          	ld	a5,0(s4)
    80004e2a:	0127b823          	sd	s2,16(a5)
  return 0;
    80004e2e:	4501                	li	a0,0
    80004e30:	a025                	j	80004e58 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004e32:	6088                	ld	a0,0(s1)
    80004e34:	e501                	bnez	a0,80004e3c <pipealloc+0xaa>
    80004e36:	a039                	j	80004e44 <pipealloc+0xb2>
    80004e38:	6088                	ld	a0,0(s1)
    80004e3a:	c51d                	beqz	a0,80004e68 <pipealloc+0xd6>
    fileclose(*f0);
    80004e3c:	00000097          	auipc	ra,0x0
    80004e40:	c2a080e7          	jalr	-982(ra) # 80004a66 <fileclose>
  if(*f1)
    80004e44:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004e48:	557d                	li	a0,-1
  if(*f1)
    80004e4a:	c799                	beqz	a5,80004e58 <pipealloc+0xc6>
    fileclose(*f1);
    80004e4c:	853e                	mv	a0,a5
    80004e4e:	00000097          	auipc	ra,0x0
    80004e52:	c18080e7          	jalr	-1000(ra) # 80004a66 <fileclose>
  return -1;
    80004e56:	557d                	li	a0,-1
}
    80004e58:	70a2                	ld	ra,40(sp)
    80004e5a:	7402                	ld	s0,32(sp)
    80004e5c:	64e2                	ld	s1,24(sp)
    80004e5e:	6942                	ld	s2,16(sp)
    80004e60:	69a2                	ld	s3,8(sp)
    80004e62:	6a02                	ld	s4,0(sp)
    80004e64:	6145                	addi	sp,sp,48
    80004e66:	8082                	ret
  return -1;
    80004e68:	557d                	li	a0,-1
    80004e6a:	b7fd                	j	80004e58 <pipealloc+0xc6>

0000000080004e6c <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004e6c:	1101                	addi	sp,sp,-32
    80004e6e:	ec06                	sd	ra,24(sp)
    80004e70:	e822                	sd	s0,16(sp)
    80004e72:	e426                	sd	s1,8(sp)
    80004e74:	e04a                	sd	s2,0(sp)
    80004e76:	1000                	addi	s0,sp,32
    80004e78:	84aa                	mv	s1,a0
    80004e7a:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004e7c:	ffffc097          	auipc	ra,0xffffc
    80004e80:	d56080e7          	jalr	-682(ra) # 80000bd2 <acquire>
  if(writable){
    80004e84:	02090d63          	beqz	s2,80004ebe <pipeclose+0x52>
    pi->writeopen = 0;
    80004e88:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004e8c:	21848513          	addi	a0,s1,536
    80004e90:	ffffd097          	auipc	ra,0xffffd
    80004e94:	626080e7          	jalr	1574(ra) # 800024b6 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004e98:	2204b783          	ld	a5,544(s1)
    80004e9c:	eb95                	bnez	a5,80004ed0 <pipeclose+0x64>
    release(&pi->lock);
    80004e9e:	8526                	mv	a0,s1
    80004ea0:	ffffc097          	auipc	ra,0xffffc
    80004ea4:	de6080e7          	jalr	-538(ra) # 80000c86 <release>
    kfree((char*)pi);
    80004ea8:	8526                	mv	a0,s1
    80004eaa:	ffffc097          	auipc	ra,0xffffc
    80004eae:	b3a080e7          	jalr	-1222(ra) # 800009e4 <kfree>
  } else
    release(&pi->lock);
}
    80004eb2:	60e2                	ld	ra,24(sp)
    80004eb4:	6442                	ld	s0,16(sp)
    80004eb6:	64a2                	ld	s1,8(sp)
    80004eb8:	6902                	ld	s2,0(sp)
    80004eba:	6105                	addi	sp,sp,32
    80004ebc:	8082                	ret
    pi->readopen = 0;
    80004ebe:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004ec2:	21c48513          	addi	a0,s1,540
    80004ec6:	ffffd097          	auipc	ra,0xffffd
    80004eca:	5f0080e7          	jalr	1520(ra) # 800024b6 <wakeup>
    80004ece:	b7e9                	j	80004e98 <pipeclose+0x2c>
    release(&pi->lock);
    80004ed0:	8526                	mv	a0,s1
    80004ed2:	ffffc097          	auipc	ra,0xffffc
    80004ed6:	db4080e7          	jalr	-588(ra) # 80000c86 <release>
}
    80004eda:	bfe1                	j	80004eb2 <pipeclose+0x46>

0000000080004edc <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004edc:	711d                	addi	sp,sp,-96
    80004ede:	ec86                	sd	ra,88(sp)
    80004ee0:	e8a2                	sd	s0,80(sp)
    80004ee2:	e4a6                	sd	s1,72(sp)
    80004ee4:	e0ca                	sd	s2,64(sp)
    80004ee6:	fc4e                	sd	s3,56(sp)
    80004ee8:	f852                	sd	s4,48(sp)
    80004eea:	f456                	sd	s5,40(sp)
    80004eec:	f05a                	sd	s6,32(sp)
    80004eee:	ec5e                	sd	s7,24(sp)
    80004ef0:	e862                	sd	s8,16(sp)
    80004ef2:	1080                	addi	s0,sp,96
    80004ef4:	84aa                	mv	s1,a0
    80004ef6:	8aae                	mv	s5,a1
    80004ef8:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004efa:	ffffd097          	auipc	ra,0xffffd
    80004efe:	d9a080e7          	jalr	-614(ra) # 80001c94 <myproc>
    80004f02:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004f04:	8526                	mv	a0,s1
    80004f06:	ffffc097          	auipc	ra,0xffffc
    80004f0a:	ccc080e7          	jalr	-820(ra) # 80000bd2 <acquire>
  while(i < n){
    80004f0e:	0b405663          	blez	s4,80004fba <pipewrite+0xde>
  int i = 0;
    80004f12:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004f14:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004f16:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004f1a:	21c48b93          	addi	s7,s1,540
    80004f1e:	a089                	j	80004f60 <pipewrite+0x84>
      release(&pi->lock);
    80004f20:	8526                	mv	a0,s1
    80004f22:	ffffc097          	auipc	ra,0xffffc
    80004f26:	d64080e7          	jalr	-668(ra) # 80000c86 <release>
      return -1;
    80004f2a:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004f2c:	854a                	mv	a0,s2
    80004f2e:	60e6                	ld	ra,88(sp)
    80004f30:	6446                	ld	s0,80(sp)
    80004f32:	64a6                	ld	s1,72(sp)
    80004f34:	6906                	ld	s2,64(sp)
    80004f36:	79e2                	ld	s3,56(sp)
    80004f38:	7a42                	ld	s4,48(sp)
    80004f3a:	7aa2                	ld	s5,40(sp)
    80004f3c:	7b02                	ld	s6,32(sp)
    80004f3e:	6be2                	ld	s7,24(sp)
    80004f40:	6c42                	ld	s8,16(sp)
    80004f42:	6125                	addi	sp,sp,96
    80004f44:	8082                	ret
      wakeup(&pi->nread);
    80004f46:	8562                	mv	a0,s8
    80004f48:	ffffd097          	auipc	ra,0xffffd
    80004f4c:	56e080e7          	jalr	1390(ra) # 800024b6 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004f50:	85a6                	mv	a1,s1
    80004f52:	855e                	mv	a0,s7
    80004f54:	ffffd097          	auipc	ra,0xffffd
    80004f58:	4fe080e7          	jalr	1278(ra) # 80002452 <sleep>
  while(i < n){
    80004f5c:	07495063          	bge	s2,s4,80004fbc <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004f60:	2204a783          	lw	a5,544(s1)
    80004f64:	dfd5                	beqz	a5,80004f20 <pipewrite+0x44>
    80004f66:	854e                	mv	a0,s3
    80004f68:	ffffd097          	auipc	ra,0xffffd
    80004f6c:	792080e7          	jalr	1938(ra) # 800026fa <killed>
    80004f70:	f945                	bnez	a0,80004f20 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004f72:	2184a783          	lw	a5,536(s1)
    80004f76:	21c4a703          	lw	a4,540(s1)
    80004f7a:	2007879b          	addiw	a5,a5,512
    80004f7e:	fcf704e3          	beq	a4,a5,80004f46 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004f82:	4685                	li	a3,1
    80004f84:	01590633          	add	a2,s2,s5
    80004f88:	faf40593          	addi	a1,s0,-81
    80004f8c:	0509b503          	ld	a0,80(s3)
    80004f90:	ffffc097          	auipc	ra,0xffffc
    80004f94:	762080e7          	jalr	1890(ra) # 800016f2 <copyin>
    80004f98:	03650263          	beq	a0,s6,80004fbc <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004f9c:	21c4a783          	lw	a5,540(s1)
    80004fa0:	0017871b          	addiw	a4,a5,1
    80004fa4:	20e4ae23          	sw	a4,540(s1)
    80004fa8:	1ff7f793          	andi	a5,a5,511
    80004fac:	97a6                	add	a5,a5,s1
    80004fae:	faf44703          	lbu	a4,-81(s0)
    80004fb2:	00e78c23          	sb	a4,24(a5)
      i++;
    80004fb6:	2905                	addiw	s2,s2,1
    80004fb8:	b755                	j	80004f5c <pipewrite+0x80>
  int i = 0;
    80004fba:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004fbc:	21848513          	addi	a0,s1,536
    80004fc0:	ffffd097          	auipc	ra,0xffffd
    80004fc4:	4f6080e7          	jalr	1270(ra) # 800024b6 <wakeup>
  release(&pi->lock);
    80004fc8:	8526                	mv	a0,s1
    80004fca:	ffffc097          	auipc	ra,0xffffc
    80004fce:	cbc080e7          	jalr	-836(ra) # 80000c86 <release>
  return i;
    80004fd2:	bfa9                	j	80004f2c <pipewrite+0x50>

0000000080004fd4 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004fd4:	715d                	addi	sp,sp,-80
    80004fd6:	e486                	sd	ra,72(sp)
    80004fd8:	e0a2                	sd	s0,64(sp)
    80004fda:	fc26                	sd	s1,56(sp)
    80004fdc:	f84a                	sd	s2,48(sp)
    80004fde:	f44e                	sd	s3,40(sp)
    80004fe0:	f052                	sd	s4,32(sp)
    80004fe2:	ec56                	sd	s5,24(sp)
    80004fe4:	e85a                	sd	s6,16(sp)
    80004fe6:	0880                	addi	s0,sp,80
    80004fe8:	84aa                	mv	s1,a0
    80004fea:	892e                	mv	s2,a1
    80004fec:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004fee:	ffffd097          	auipc	ra,0xffffd
    80004ff2:	ca6080e7          	jalr	-858(ra) # 80001c94 <myproc>
    80004ff6:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004ff8:	8526                	mv	a0,s1
    80004ffa:	ffffc097          	auipc	ra,0xffffc
    80004ffe:	bd8080e7          	jalr	-1064(ra) # 80000bd2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005002:	2184a703          	lw	a4,536(s1)
    80005006:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000500a:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000500e:	02f71763          	bne	a4,a5,8000503c <piperead+0x68>
    80005012:	2244a783          	lw	a5,548(s1)
    80005016:	c39d                	beqz	a5,8000503c <piperead+0x68>
    if(killed(pr)){
    80005018:	8552                	mv	a0,s4
    8000501a:	ffffd097          	auipc	ra,0xffffd
    8000501e:	6e0080e7          	jalr	1760(ra) # 800026fa <killed>
    80005022:	e949                	bnez	a0,800050b4 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005024:	85a6                	mv	a1,s1
    80005026:	854e                	mv	a0,s3
    80005028:	ffffd097          	auipc	ra,0xffffd
    8000502c:	42a080e7          	jalr	1066(ra) # 80002452 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005030:	2184a703          	lw	a4,536(s1)
    80005034:	21c4a783          	lw	a5,540(s1)
    80005038:	fcf70de3          	beq	a4,a5,80005012 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000503c:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000503e:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005040:	05505463          	blez	s5,80005088 <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80005044:	2184a783          	lw	a5,536(s1)
    80005048:	21c4a703          	lw	a4,540(s1)
    8000504c:	02f70e63          	beq	a4,a5,80005088 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005050:	0017871b          	addiw	a4,a5,1
    80005054:	20e4ac23          	sw	a4,536(s1)
    80005058:	1ff7f793          	andi	a5,a5,511
    8000505c:	97a6                	add	a5,a5,s1
    8000505e:	0187c783          	lbu	a5,24(a5)
    80005062:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005066:	4685                	li	a3,1
    80005068:	fbf40613          	addi	a2,s0,-65
    8000506c:	85ca                	mv	a1,s2
    8000506e:	050a3503          	ld	a0,80(s4)
    80005072:	ffffc097          	auipc	ra,0xffffc
    80005076:	5f4080e7          	jalr	1524(ra) # 80001666 <copyout>
    8000507a:	01650763          	beq	a0,s6,80005088 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000507e:	2985                	addiw	s3,s3,1
    80005080:	0905                	addi	s2,s2,1
    80005082:	fd3a91e3          	bne	s5,s3,80005044 <piperead+0x70>
    80005086:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005088:	21c48513          	addi	a0,s1,540
    8000508c:	ffffd097          	auipc	ra,0xffffd
    80005090:	42a080e7          	jalr	1066(ra) # 800024b6 <wakeup>
  release(&pi->lock);
    80005094:	8526                	mv	a0,s1
    80005096:	ffffc097          	auipc	ra,0xffffc
    8000509a:	bf0080e7          	jalr	-1040(ra) # 80000c86 <release>
  return i;
}
    8000509e:	854e                	mv	a0,s3
    800050a0:	60a6                	ld	ra,72(sp)
    800050a2:	6406                	ld	s0,64(sp)
    800050a4:	74e2                	ld	s1,56(sp)
    800050a6:	7942                	ld	s2,48(sp)
    800050a8:	79a2                	ld	s3,40(sp)
    800050aa:	7a02                	ld	s4,32(sp)
    800050ac:	6ae2                	ld	s5,24(sp)
    800050ae:	6b42                	ld	s6,16(sp)
    800050b0:	6161                	addi	sp,sp,80
    800050b2:	8082                	ret
      release(&pi->lock);
    800050b4:	8526                	mv	a0,s1
    800050b6:	ffffc097          	auipc	ra,0xffffc
    800050ba:	bd0080e7          	jalr	-1072(ra) # 80000c86 <release>
      return -1;
    800050be:	59fd                	li	s3,-1
    800050c0:	bff9                	j	8000509e <piperead+0xca>

00000000800050c2 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    800050c2:	1141                	addi	sp,sp,-16
    800050c4:	e422                	sd	s0,8(sp)
    800050c6:	0800                	addi	s0,sp,16
    800050c8:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    800050ca:	8905                	andi	a0,a0,1
    800050cc:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    800050ce:	8b89                	andi	a5,a5,2
    800050d0:	c399                	beqz	a5,800050d6 <flags2perm+0x14>
      perm |= PTE_W;
    800050d2:	00456513          	ori	a0,a0,4
    return perm;
}
    800050d6:	6422                	ld	s0,8(sp)
    800050d8:	0141                	addi	sp,sp,16
    800050da:	8082                	ret

00000000800050dc <exec>:

int
exec(char *path, char **argv)
{
    800050dc:	df010113          	addi	sp,sp,-528
    800050e0:	20113423          	sd	ra,520(sp)
    800050e4:	20813023          	sd	s0,512(sp)
    800050e8:	ffa6                	sd	s1,504(sp)
    800050ea:	fbca                	sd	s2,496(sp)
    800050ec:	f7ce                	sd	s3,488(sp)
    800050ee:	f3d2                	sd	s4,480(sp)
    800050f0:	efd6                	sd	s5,472(sp)
    800050f2:	ebda                	sd	s6,464(sp)
    800050f4:	e7de                	sd	s7,456(sp)
    800050f6:	e3e2                	sd	s8,448(sp)
    800050f8:	ff66                	sd	s9,440(sp)
    800050fa:	fb6a                	sd	s10,432(sp)
    800050fc:	f76e                	sd	s11,424(sp)
    800050fe:	0c00                	addi	s0,sp,528
    80005100:	892a                	mv	s2,a0
    80005102:	dea43c23          	sd	a0,-520(s0)
    80005106:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    8000510a:	ffffd097          	auipc	ra,0xffffd
    8000510e:	b8a080e7          	jalr	-1142(ra) # 80001c94 <myproc>
    80005112:	84aa                	mv	s1,a0

  begin_op();
    80005114:	fffff097          	auipc	ra,0xfffff
    80005118:	48e080e7          	jalr	1166(ra) # 800045a2 <begin_op>

  if((ip = namei(path)) == 0){
    8000511c:	854a                	mv	a0,s2
    8000511e:	fffff097          	auipc	ra,0xfffff
    80005122:	284080e7          	jalr	644(ra) # 800043a2 <namei>
    80005126:	c92d                	beqz	a0,80005198 <exec+0xbc>
    80005128:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    8000512a:	fffff097          	auipc	ra,0xfffff
    8000512e:	ad2080e7          	jalr	-1326(ra) # 80003bfc <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005132:	04000713          	li	a4,64
    80005136:	4681                	li	a3,0
    80005138:	e5040613          	addi	a2,s0,-432
    8000513c:	4581                	li	a1,0
    8000513e:	8552                	mv	a0,s4
    80005140:	fffff097          	auipc	ra,0xfffff
    80005144:	d70080e7          	jalr	-656(ra) # 80003eb0 <readi>
    80005148:	04000793          	li	a5,64
    8000514c:	00f51a63          	bne	a0,a5,80005160 <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80005150:	e5042703          	lw	a4,-432(s0)
    80005154:	464c47b7          	lui	a5,0x464c4
    80005158:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    8000515c:	04f70463          	beq	a4,a5,800051a4 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005160:	8552                	mv	a0,s4
    80005162:	fffff097          	auipc	ra,0xfffff
    80005166:	cfc080e7          	jalr	-772(ra) # 80003e5e <iunlockput>
    end_op();
    8000516a:	fffff097          	auipc	ra,0xfffff
    8000516e:	4b2080e7          	jalr	1202(ra) # 8000461c <end_op>
  }
  return -1;
    80005172:	557d                	li	a0,-1
}
    80005174:	20813083          	ld	ra,520(sp)
    80005178:	20013403          	ld	s0,512(sp)
    8000517c:	74fe                	ld	s1,504(sp)
    8000517e:	795e                	ld	s2,496(sp)
    80005180:	79be                	ld	s3,488(sp)
    80005182:	7a1e                	ld	s4,480(sp)
    80005184:	6afe                	ld	s5,472(sp)
    80005186:	6b5e                	ld	s6,464(sp)
    80005188:	6bbe                	ld	s7,456(sp)
    8000518a:	6c1e                	ld	s8,448(sp)
    8000518c:	7cfa                	ld	s9,440(sp)
    8000518e:	7d5a                	ld	s10,432(sp)
    80005190:	7dba                	ld	s11,424(sp)
    80005192:	21010113          	addi	sp,sp,528
    80005196:	8082                	ret
    end_op();
    80005198:	fffff097          	auipc	ra,0xfffff
    8000519c:	484080e7          	jalr	1156(ra) # 8000461c <end_op>
    return -1;
    800051a0:	557d                	li	a0,-1
    800051a2:	bfc9                	j	80005174 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    800051a4:	8526                	mv	a0,s1
    800051a6:	ffffd097          	auipc	ra,0xffffd
    800051aa:	bb2080e7          	jalr	-1102(ra) # 80001d58 <proc_pagetable>
    800051ae:	8b2a                	mv	s6,a0
    800051b0:	d945                	beqz	a0,80005160 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800051b2:	e7042d03          	lw	s10,-400(s0)
    800051b6:	e8845783          	lhu	a5,-376(s0)
    800051ba:	10078463          	beqz	a5,800052c2 <exec+0x1e6>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800051be:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800051c0:	4d81                	li	s11,0
    if(ph.vaddr % PGSIZE != 0)
    800051c2:	6c85                	lui	s9,0x1
    800051c4:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    800051c8:	def43823          	sd	a5,-528(s0)

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    800051cc:	6a85                	lui	s5,0x1
    800051ce:	a0b5                	j	8000523a <exec+0x15e>
      panic("loadseg: address should exist");
    800051d0:	00003517          	auipc	a0,0x3
    800051d4:	5e850513          	addi	a0,a0,1512 # 800087b8 <syscalls+0x298>
    800051d8:	ffffb097          	auipc	ra,0xffffb
    800051dc:	364080e7          	jalr	868(ra) # 8000053c <panic>
    if(sz - i < PGSIZE)
    800051e0:	2481                	sext.w	s1,s1
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800051e2:	8726                	mv	a4,s1
    800051e4:	012c06bb          	addw	a3,s8,s2
    800051e8:	4581                	li	a1,0
    800051ea:	8552                	mv	a0,s4
    800051ec:	fffff097          	auipc	ra,0xfffff
    800051f0:	cc4080e7          	jalr	-828(ra) # 80003eb0 <readi>
    800051f4:	2501                	sext.w	a0,a0
    800051f6:	24a49863          	bne	s1,a0,80005446 <exec+0x36a>
  for(i = 0; i < sz; i += PGSIZE){
    800051fa:	012a893b          	addw	s2,s5,s2
    800051fe:	03397563          	bgeu	s2,s3,80005228 <exec+0x14c>
    pa = walkaddr(pagetable, va + i);
    80005202:	02091593          	slli	a1,s2,0x20
    80005206:	9181                	srli	a1,a1,0x20
    80005208:	95de                	add	a1,a1,s7
    8000520a:	855a                	mv	a0,s6
    8000520c:	ffffc097          	auipc	ra,0xffffc
    80005210:	e4a080e7          	jalr	-438(ra) # 80001056 <walkaddr>
    80005214:	862a                	mv	a2,a0
    if(pa == 0)
    80005216:	dd4d                	beqz	a0,800051d0 <exec+0xf4>
    if(sz - i < PGSIZE)
    80005218:	412984bb          	subw	s1,s3,s2
    8000521c:	0004879b          	sext.w	a5,s1
    80005220:	fcfcf0e3          	bgeu	s9,a5,800051e0 <exec+0x104>
    80005224:	84d6                	mv	s1,s5
    80005226:	bf6d                	j	800051e0 <exec+0x104>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005228:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000522c:	2d85                	addiw	s11,s11,1
    8000522e:	038d0d1b          	addiw	s10,s10,56
    80005232:	e8845783          	lhu	a5,-376(s0)
    80005236:	08fdd763          	bge	s11,a5,800052c4 <exec+0x1e8>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000523a:	2d01                	sext.w	s10,s10
    8000523c:	03800713          	li	a4,56
    80005240:	86ea                	mv	a3,s10
    80005242:	e1840613          	addi	a2,s0,-488
    80005246:	4581                	li	a1,0
    80005248:	8552                	mv	a0,s4
    8000524a:	fffff097          	auipc	ra,0xfffff
    8000524e:	c66080e7          	jalr	-922(ra) # 80003eb0 <readi>
    80005252:	03800793          	li	a5,56
    80005256:	1ef51663          	bne	a0,a5,80005442 <exec+0x366>
    if(ph.type != ELF_PROG_LOAD)
    8000525a:	e1842783          	lw	a5,-488(s0)
    8000525e:	4705                	li	a4,1
    80005260:	fce796e3          	bne	a5,a4,8000522c <exec+0x150>
    if(ph.memsz < ph.filesz)
    80005264:	e4043483          	ld	s1,-448(s0)
    80005268:	e3843783          	ld	a5,-456(s0)
    8000526c:	1ef4e863          	bltu	s1,a5,8000545c <exec+0x380>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005270:	e2843783          	ld	a5,-472(s0)
    80005274:	94be                	add	s1,s1,a5
    80005276:	1ef4e663          	bltu	s1,a5,80005462 <exec+0x386>
    if(ph.vaddr % PGSIZE != 0)
    8000527a:	df043703          	ld	a4,-528(s0)
    8000527e:	8ff9                	and	a5,a5,a4
    80005280:	1e079463          	bnez	a5,80005468 <exec+0x38c>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005284:	e1c42503          	lw	a0,-484(s0)
    80005288:	00000097          	auipc	ra,0x0
    8000528c:	e3a080e7          	jalr	-454(ra) # 800050c2 <flags2perm>
    80005290:	86aa                	mv	a3,a0
    80005292:	8626                	mv	a2,s1
    80005294:	85ca                	mv	a1,s2
    80005296:	855a                	mv	a0,s6
    80005298:	ffffc097          	auipc	ra,0xffffc
    8000529c:	172080e7          	jalr	370(ra) # 8000140a <uvmalloc>
    800052a0:	e0a43423          	sd	a0,-504(s0)
    800052a4:	1c050563          	beqz	a0,8000546e <exec+0x392>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800052a8:	e2843b83          	ld	s7,-472(s0)
    800052ac:	e2042c03          	lw	s8,-480(s0)
    800052b0:	e3842983          	lw	s3,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800052b4:	00098463          	beqz	s3,800052bc <exec+0x1e0>
    800052b8:	4901                	li	s2,0
    800052ba:	b7a1                	j	80005202 <exec+0x126>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800052bc:	e0843903          	ld	s2,-504(s0)
    800052c0:	b7b5                	j	8000522c <exec+0x150>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800052c2:	4901                	li	s2,0
  iunlockput(ip);
    800052c4:	8552                	mv	a0,s4
    800052c6:	fffff097          	auipc	ra,0xfffff
    800052ca:	b98080e7          	jalr	-1128(ra) # 80003e5e <iunlockput>
  end_op();
    800052ce:	fffff097          	auipc	ra,0xfffff
    800052d2:	34e080e7          	jalr	846(ra) # 8000461c <end_op>
  p = myproc();
    800052d6:	ffffd097          	auipc	ra,0xffffd
    800052da:	9be080e7          	jalr	-1602(ra) # 80001c94 <myproc>
    800052de:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    800052e0:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    800052e4:	6985                	lui	s3,0x1
    800052e6:	19fd                	addi	s3,s3,-1 # fff <_entry-0x7ffff001>
    800052e8:	99ca                	add	s3,s3,s2
    800052ea:	77fd                	lui	a5,0xfffff
    800052ec:	00f9f9b3          	and	s3,s3,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800052f0:	4691                	li	a3,4
    800052f2:	6609                	lui	a2,0x2
    800052f4:	964e                	add	a2,a2,s3
    800052f6:	85ce                	mv	a1,s3
    800052f8:	855a                	mv	a0,s6
    800052fa:	ffffc097          	auipc	ra,0xffffc
    800052fe:	110080e7          	jalr	272(ra) # 8000140a <uvmalloc>
    80005302:	892a                	mv	s2,a0
    80005304:	e0a43423          	sd	a0,-504(s0)
    80005308:	e509                	bnez	a0,80005312 <exec+0x236>
  if(pagetable)
    8000530a:	e1343423          	sd	s3,-504(s0)
    8000530e:	4a01                	li	s4,0
    80005310:	aa1d                	j	80005446 <exec+0x36a>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005312:	75f9                	lui	a1,0xffffe
    80005314:	95aa                	add	a1,a1,a0
    80005316:	855a                	mv	a0,s6
    80005318:	ffffc097          	auipc	ra,0xffffc
    8000531c:	31c080e7          	jalr	796(ra) # 80001634 <uvmclear>
  stackbase = sp - PGSIZE;
    80005320:	7bfd                	lui	s7,0xfffff
    80005322:	9bca                	add	s7,s7,s2
  for(argc = 0; argv[argc]; argc++) {
    80005324:	e0043783          	ld	a5,-512(s0)
    80005328:	6388                	ld	a0,0(a5)
    8000532a:	c52d                	beqz	a0,80005394 <exec+0x2b8>
    8000532c:	e9040993          	addi	s3,s0,-368
    80005330:	f9040c13          	addi	s8,s0,-112
    80005334:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005336:	ffffc097          	auipc	ra,0xffffc
    8000533a:	b12080e7          	jalr	-1262(ra) # 80000e48 <strlen>
    8000533e:	0015079b          	addiw	a5,a0,1
    80005342:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005346:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    8000534a:	13796563          	bltu	s2,s7,80005474 <exec+0x398>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000534e:	e0043d03          	ld	s10,-512(s0)
    80005352:	000d3a03          	ld	s4,0(s10)
    80005356:	8552                	mv	a0,s4
    80005358:	ffffc097          	auipc	ra,0xffffc
    8000535c:	af0080e7          	jalr	-1296(ra) # 80000e48 <strlen>
    80005360:	0015069b          	addiw	a3,a0,1
    80005364:	8652                	mv	a2,s4
    80005366:	85ca                	mv	a1,s2
    80005368:	855a                	mv	a0,s6
    8000536a:	ffffc097          	auipc	ra,0xffffc
    8000536e:	2fc080e7          	jalr	764(ra) # 80001666 <copyout>
    80005372:	10054363          	bltz	a0,80005478 <exec+0x39c>
    ustack[argc] = sp;
    80005376:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000537a:	0485                	addi	s1,s1,1
    8000537c:	008d0793          	addi	a5,s10,8
    80005380:	e0f43023          	sd	a5,-512(s0)
    80005384:	008d3503          	ld	a0,8(s10)
    80005388:	c909                	beqz	a0,8000539a <exec+0x2be>
    if(argc >= MAXARG)
    8000538a:	09a1                	addi	s3,s3,8
    8000538c:	fb8995e3          	bne	s3,s8,80005336 <exec+0x25a>
  ip = 0;
    80005390:	4a01                	li	s4,0
    80005392:	a855                	j	80005446 <exec+0x36a>
  sp = sz;
    80005394:	e0843903          	ld	s2,-504(s0)
  for(argc = 0; argv[argc]; argc++) {
    80005398:	4481                	li	s1,0
  ustack[argc] = 0;
    8000539a:	00349793          	slli	a5,s1,0x3
    8000539e:	f9078793          	addi	a5,a5,-112 # ffffffffffffef90 <end+0xffffffff7ffdd110>
    800053a2:	97a2                	add	a5,a5,s0
    800053a4:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    800053a8:	00148693          	addi	a3,s1,1
    800053ac:	068e                	slli	a3,a3,0x3
    800053ae:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800053b2:	ff097913          	andi	s2,s2,-16
  sz = sz1;
    800053b6:	e0843983          	ld	s3,-504(s0)
  if(sp < stackbase)
    800053ba:	f57968e3          	bltu	s2,s7,8000530a <exec+0x22e>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800053be:	e9040613          	addi	a2,s0,-368
    800053c2:	85ca                	mv	a1,s2
    800053c4:	855a                	mv	a0,s6
    800053c6:	ffffc097          	auipc	ra,0xffffc
    800053ca:	2a0080e7          	jalr	672(ra) # 80001666 <copyout>
    800053ce:	0a054763          	bltz	a0,8000547c <exec+0x3a0>
  p->trapframe->a1 = sp;
    800053d2:	058ab783          	ld	a5,88(s5) # 1058 <_entry-0x7fffefa8>
    800053d6:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800053da:	df843783          	ld	a5,-520(s0)
    800053de:	0007c703          	lbu	a4,0(a5)
    800053e2:	cf11                	beqz	a4,800053fe <exec+0x322>
    800053e4:	0785                	addi	a5,a5,1
    if(*s == '/')
    800053e6:	02f00693          	li	a3,47
    800053ea:	a039                	j	800053f8 <exec+0x31c>
      last = s+1;
    800053ec:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    800053f0:	0785                	addi	a5,a5,1
    800053f2:	fff7c703          	lbu	a4,-1(a5)
    800053f6:	c701                	beqz	a4,800053fe <exec+0x322>
    if(*s == '/')
    800053f8:	fed71ce3          	bne	a4,a3,800053f0 <exec+0x314>
    800053fc:	bfc5                	j	800053ec <exec+0x310>
  safestrcpy(p->name, last, sizeof(p->name));
    800053fe:	4641                	li	a2,16
    80005400:	df843583          	ld	a1,-520(s0)
    80005404:	158a8513          	addi	a0,s5,344
    80005408:	ffffc097          	auipc	ra,0xffffc
    8000540c:	a0e080e7          	jalr	-1522(ra) # 80000e16 <safestrcpy>
  oldpagetable = p->pagetable;
    80005410:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80005414:	056ab823          	sd	s6,80(s5)
  p->sz = sz;
    80005418:	e0843783          	ld	a5,-504(s0)
    8000541c:	04fab423          	sd	a5,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005420:	058ab783          	ld	a5,88(s5)
    80005424:	e6843703          	ld	a4,-408(s0)
    80005428:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000542a:	058ab783          	ld	a5,88(s5)
    8000542e:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005432:	85e6                	mv	a1,s9
    80005434:	ffffd097          	auipc	ra,0xffffd
    80005438:	9c0080e7          	jalr	-1600(ra) # 80001df4 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000543c:	0004851b          	sext.w	a0,s1
    80005440:	bb15                	j	80005174 <exec+0x98>
    80005442:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005446:	e0843583          	ld	a1,-504(s0)
    8000544a:	855a                	mv	a0,s6
    8000544c:	ffffd097          	auipc	ra,0xffffd
    80005450:	9a8080e7          	jalr	-1624(ra) # 80001df4 <proc_freepagetable>
  return -1;
    80005454:	557d                	li	a0,-1
  if(ip){
    80005456:	d00a0fe3          	beqz	s4,80005174 <exec+0x98>
    8000545a:	b319                	j	80005160 <exec+0x84>
    8000545c:	e1243423          	sd	s2,-504(s0)
    80005460:	b7dd                	j	80005446 <exec+0x36a>
    80005462:	e1243423          	sd	s2,-504(s0)
    80005466:	b7c5                	j	80005446 <exec+0x36a>
    80005468:	e1243423          	sd	s2,-504(s0)
    8000546c:	bfe9                	j	80005446 <exec+0x36a>
    8000546e:	e1243423          	sd	s2,-504(s0)
    80005472:	bfd1                	j	80005446 <exec+0x36a>
  ip = 0;
    80005474:	4a01                	li	s4,0
    80005476:	bfc1                	j	80005446 <exec+0x36a>
    80005478:	4a01                	li	s4,0
  if(pagetable)
    8000547a:	b7f1                	j	80005446 <exec+0x36a>
  sz = sz1;
    8000547c:	e0843983          	ld	s3,-504(s0)
    80005480:	b569                	j	8000530a <exec+0x22e>

0000000080005482 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005482:	7179                	addi	sp,sp,-48
    80005484:	f406                	sd	ra,40(sp)
    80005486:	f022                	sd	s0,32(sp)
    80005488:	ec26                	sd	s1,24(sp)
    8000548a:	e84a                	sd	s2,16(sp)
    8000548c:	1800                	addi	s0,sp,48
    8000548e:	892e                	mv	s2,a1
    80005490:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005492:	fdc40593          	addi	a1,s0,-36
    80005496:	ffffe097          	auipc	ra,0xffffe
    8000549a:	b74080e7          	jalr	-1164(ra) # 8000300a <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000549e:	fdc42703          	lw	a4,-36(s0)
    800054a2:	47bd                	li	a5,15
    800054a4:	02e7eb63          	bltu	a5,a4,800054da <argfd+0x58>
    800054a8:	ffffc097          	auipc	ra,0xffffc
    800054ac:	7ec080e7          	jalr	2028(ra) # 80001c94 <myproc>
    800054b0:	fdc42703          	lw	a4,-36(s0)
    800054b4:	01a70793          	addi	a5,a4,26
    800054b8:	078e                	slli	a5,a5,0x3
    800054ba:	953e                	add	a0,a0,a5
    800054bc:	611c                	ld	a5,0(a0)
    800054be:	c385                	beqz	a5,800054de <argfd+0x5c>
    return -1;
  if(pfd)
    800054c0:	00090463          	beqz	s2,800054c8 <argfd+0x46>
    *pfd = fd;
    800054c4:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800054c8:	4501                	li	a0,0
  if(pf)
    800054ca:	c091                	beqz	s1,800054ce <argfd+0x4c>
    *pf = f;
    800054cc:	e09c                	sd	a5,0(s1)
}
    800054ce:	70a2                	ld	ra,40(sp)
    800054d0:	7402                	ld	s0,32(sp)
    800054d2:	64e2                	ld	s1,24(sp)
    800054d4:	6942                	ld	s2,16(sp)
    800054d6:	6145                	addi	sp,sp,48
    800054d8:	8082                	ret
    return -1;
    800054da:	557d                	li	a0,-1
    800054dc:	bfcd                	j	800054ce <argfd+0x4c>
    800054de:	557d                	li	a0,-1
    800054e0:	b7fd                	j	800054ce <argfd+0x4c>

00000000800054e2 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800054e2:	1101                	addi	sp,sp,-32
    800054e4:	ec06                	sd	ra,24(sp)
    800054e6:	e822                	sd	s0,16(sp)
    800054e8:	e426                	sd	s1,8(sp)
    800054ea:	1000                	addi	s0,sp,32
    800054ec:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800054ee:	ffffc097          	auipc	ra,0xffffc
    800054f2:	7a6080e7          	jalr	1958(ra) # 80001c94 <myproc>
    800054f6:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800054f8:	0d050793          	addi	a5,a0,208
    800054fc:	4501                	li	a0,0
    800054fe:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005500:	6398                	ld	a4,0(a5)
    80005502:	cb19                	beqz	a4,80005518 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005504:	2505                	addiw	a0,a0,1
    80005506:	07a1                	addi	a5,a5,8
    80005508:	fed51ce3          	bne	a0,a3,80005500 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000550c:	557d                	li	a0,-1
}
    8000550e:	60e2                	ld	ra,24(sp)
    80005510:	6442                	ld	s0,16(sp)
    80005512:	64a2                	ld	s1,8(sp)
    80005514:	6105                	addi	sp,sp,32
    80005516:	8082                	ret
      p->ofile[fd] = f;
    80005518:	01a50793          	addi	a5,a0,26
    8000551c:	078e                	slli	a5,a5,0x3
    8000551e:	963e                	add	a2,a2,a5
    80005520:	e204                	sd	s1,0(a2)
      return fd;
    80005522:	b7f5                	j	8000550e <fdalloc+0x2c>

0000000080005524 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005524:	715d                	addi	sp,sp,-80
    80005526:	e486                	sd	ra,72(sp)
    80005528:	e0a2                	sd	s0,64(sp)
    8000552a:	fc26                	sd	s1,56(sp)
    8000552c:	f84a                	sd	s2,48(sp)
    8000552e:	f44e                	sd	s3,40(sp)
    80005530:	f052                	sd	s4,32(sp)
    80005532:	ec56                	sd	s5,24(sp)
    80005534:	e85a                	sd	s6,16(sp)
    80005536:	0880                	addi	s0,sp,80
    80005538:	8b2e                	mv	s6,a1
    8000553a:	89b2                	mv	s3,a2
    8000553c:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000553e:	fb040593          	addi	a1,s0,-80
    80005542:	fffff097          	auipc	ra,0xfffff
    80005546:	e7e080e7          	jalr	-386(ra) # 800043c0 <nameiparent>
    8000554a:	84aa                	mv	s1,a0
    8000554c:	14050b63          	beqz	a0,800056a2 <create+0x17e>
    return 0;

  ilock(dp);
    80005550:	ffffe097          	auipc	ra,0xffffe
    80005554:	6ac080e7          	jalr	1708(ra) # 80003bfc <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005558:	4601                	li	a2,0
    8000555a:	fb040593          	addi	a1,s0,-80
    8000555e:	8526                	mv	a0,s1
    80005560:	fffff097          	auipc	ra,0xfffff
    80005564:	b80080e7          	jalr	-1152(ra) # 800040e0 <dirlookup>
    80005568:	8aaa                	mv	s5,a0
    8000556a:	c921                	beqz	a0,800055ba <create+0x96>
    iunlockput(dp);
    8000556c:	8526                	mv	a0,s1
    8000556e:	fffff097          	auipc	ra,0xfffff
    80005572:	8f0080e7          	jalr	-1808(ra) # 80003e5e <iunlockput>
    ilock(ip);
    80005576:	8556                	mv	a0,s5
    80005578:	ffffe097          	auipc	ra,0xffffe
    8000557c:	684080e7          	jalr	1668(ra) # 80003bfc <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005580:	4789                	li	a5,2
    80005582:	02fb1563          	bne	s6,a5,800055ac <create+0x88>
    80005586:	044ad783          	lhu	a5,68(s5)
    8000558a:	37f9                	addiw	a5,a5,-2
    8000558c:	17c2                	slli	a5,a5,0x30
    8000558e:	93c1                	srli	a5,a5,0x30
    80005590:	4705                	li	a4,1
    80005592:	00f76d63          	bltu	a4,a5,800055ac <create+0x88>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005596:	8556                	mv	a0,s5
    80005598:	60a6                	ld	ra,72(sp)
    8000559a:	6406                	ld	s0,64(sp)
    8000559c:	74e2                	ld	s1,56(sp)
    8000559e:	7942                	ld	s2,48(sp)
    800055a0:	79a2                	ld	s3,40(sp)
    800055a2:	7a02                	ld	s4,32(sp)
    800055a4:	6ae2                	ld	s5,24(sp)
    800055a6:	6b42                	ld	s6,16(sp)
    800055a8:	6161                	addi	sp,sp,80
    800055aa:	8082                	ret
    iunlockput(ip);
    800055ac:	8556                	mv	a0,s5
    800055ae:	fffff097          	auipc	ra,0xfffff
    800055b2:	8b0080e7          	jalr	-1872(ra) # 80003e5e <iunlockput>
    return 0;
    800055b6:	4a81                	li	s5,0
    800055b8:	bff9                	j	80005596 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0){
    800055ba:	85da                	mv	a1,s6
    800055bc:	4088                	lw	a0,0(s1)
    800055be:	ffffe097          	auipc	ra,0xffffe
    800055c2:	4a6080e7          	jalr	1190(ra) # 80003a64 <ialloc>
    800055c6:	8a2a                	mv	s4,a0
    800055c8:	c529                	beqz	a0,80005612 <create+0xee>
  ilock(ip);
    800055ca:	ffffe097          	auipc	ra,0xffffe
    800055ce:	632080e7          	jalr	1586(ra) # 80003bfc <ilock>
  ip->major = major;
    800055d2:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800055d6:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800055da:	4905                	li	s2,1
    800055dc:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    800055e0:	8552                	mv	a0,s4
    800055e2:	ffffe097          	auipc	ra,0xffffe
    800055e6:	54e080e7          	jalr	1358(ra) # 80003b30 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800055ea:	032b0b63          	beq	s6,s2,80005620 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    800055ee:	004a2603          	lw	a2,4(s4)
    800055f2:	fb040593          	addi	a1,s0,-80
    800055f6:	8526                	mv	a0,s1
    800055f8:	fffff097          	auipc	ra,0xfffff
    800055fc:	cf8080e7          	jalr	-776(ra) # 800042f0 <dirlink>
    80005600:	06054f63          	bltz	a0,8000567e <create+0x15a>
  iunlockput(dp);
    80005604:	8526                	mv	a0,s1
    80005606:	fffff097          	auipc	ra,0xfffff
    8000560a:	858080e7          	jalr	-1960(ra) # 80003e5e <iunlockput>
  return ip;
    8000560e:	8ad2                	mv	s5,s4
    80005610:	b759                	j	80005596 <create+0x72>
    iunlockput(dp);
    80005612:	8526                	mv	a0,s1
    80005614:	fffff097          	auipc	ra,0xfffff
    80005618:	84a080e7          	jalr	-1974(ra) # 80003e5e <iunlockput>
    return 0;
    8000561c:	8ad2                	mv	s5,s4
    8000561e:	bfa5                	j	80005596 <create+0x72>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005620:	004a2603          	lw	a2,4(s4)
    80005624:	00003597          	auipc	a1,0x3
    80005628:	1b458593          	addi	a1,a1,436 # 800087d8 <syscalls+0x2b8>
    8000562c:	8552                	mv	a0,s4
    8000562e:	fffff097          	auipc	ra,0xfffff
    80005632:	cc2080e7          	jalr	-830(ra) # 800042f0 <dirlink>
    80005636:	04054463          	bltz	a0,8000567e <create+0x15a>
    8000563a:	40d0                	lw	a2,4(s1)
    8000563c:	00003597          	auipc	a1,0x3
    80005640:	1a458593          	addi	a1,a1,420 # 800087e0 <syscalls+0x2c0>
    80005644:	8552                	mv	a0,s4
    80005646:	fffff097          	auipc	ra,0xfffff
    8000564a:	caa080e7          	jalr	-854(ra) # 800042f0 <dirlink>
    8000564e:	02054863          	bltz	a0,8000567e <create+0x15a>
  if(dirlink(dp, name, ip->inum) < 0)
    80005652:	004a2603          	lw	a2,4(s4)
    80005656:	fb040593          	addi	a1,s0,-80
    8000565a:	8526                	mv	a0,s1
    8000565c:	fffff097          	auipc	ra,0xfffff
    80005660:	c94080e7          	jalr	-876(ra) # 800042f0 <dirlink>
    80005664:	00054d63          	bltz	a0,8000567e <create+0x15a>
    dp->nlink++;  // for ".."
    80005668:	04a4d783          	lhu	a5,74(s1)
    8000566c:	2785                	addiw	a5,a5,1
    8000566e:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005672:	8526                	mv	a0,s1
    80005674:	ffffe097          	auipc	ra,0xffffe
    80005678:	4bc080e7          	jalr	1212(ra) # 80003b30 <iupdate>
    8000567c:	b761                	j	80005604 <create+0xe0>
  ip->nlink = 0;
    8000567e:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005682:	8552                	mv	a0,s4
    80005684:	ffffe097          	auipc	ra,0xffffe
    80005688:	4ac080e7          	jalr	1196(ra) # 80003b30 <iupdate>
  iunlockput(ip);
    8000568c:	8552                	mv	a0,s4
    8000568e:	ffffe097          	auipc	ra,0xffffe
    80005692:	7d0080e7          	jalr	2000(ra) # 80003e5e <iunlockput>
  iunlockput(dp);
    80005696:	8526                	mv	a0,s1
    80005698:	ffffe097          	auipc	ra,0xffffe
    8000569c:	7c6080e7          	jalr	1990(ra) # 80003e5e <iunlockput>
  return 0;
    800056a0:	bddd                	j	80005596 <create+0x72>
    return 0;
    800056a2:	8aaa                	mv	s5,a0
    800056a4:	bdcd                	j	80005596 <create+0x72>

00000000800056a6 <sys_dup>:
{
    800056a6:	7179                	addi	sp,sp,-48
    800056a8:	f406                	sd	ra,40(sp)
    800056aa:	f022                	sd	s0,32(sp)
    800056ac:	ec26                	sd	s1,24(sp)
    800056ae:	e84a                	sd	s2,16(sp)
    800056b0:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800056b2:	fd840613          	addi	a2,s0,-40
    800056b6:	4581                	li	a1,0
    800056b8:	4501                	li	a0,0
    800056ba:	00000097          	auipc	ra,0x0
    800056be:	dc8080e7          	jalr	-568(ra) # 80005482 <argfd>
    return -1;
    800056c2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800056c4:	02054363          	bltz	a0,800056ea <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    800056c8:	fd843903          	ld	s2,-40(s0)
    800056cc:	854a                	mv	a0,s2
    800056ce:	00000097          	auipc	ra,0x0
    800056d2:	e14080e7          	jalr	-492(ra) # 800054e2 <fdalloc>
    800056d6:	84aa                	mv	s1,a0
    return -1;
    800056d8:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800056da:	00054863          	bltz	a0,800056ea <sys_dup+0x44>
  filedup(f);
    800056de:	854a                	mv	a0,s2
    800056e0:	fffff097          	auipc	ra,0xfffff
    800056e4:	334080e7          	jalr	820(ra) # 80004a14 <filedup>
  return fd;
    800056e8:	87a6                	mv	a5,s1
}
    800056ea:	853e                	mv	a0,a5
    800056ec:	70a2                	ld	ra,40(sp)
    800056ee:	7402                	ld	s0,32(sp)
    800056f0:	64e2                	ld	s1,24(sp)
    800056f2:	6942                	ld	s2,16(sp)
    800056f4:	6145                	addi	sp,sp,48
    800056f6:	8082                	ret

00000000800056f8 <sys_read>:
{
    800056f8:	7179                	addi	sp,sp,-48
    800056fa:	f406                	sd	ra,40(sp)
    800056fc:	f022                	sd	s0,32(sp)
    800056fe:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005700:	fd840593          	addi	a1,s0,-40
    80005704:	4505                	li	a0,1
    80005706:	ffffe097          	auipc	ra,0xffffe
    8000570a:	924080e7          	jalr	-1756(ra) # 8000302a <argaddr>
  argint(2, &n);
    8000570e:	fe440593          	addi	a1,s0,-28
    80005712:	4509                	li	a0,2
    80005714:	ffffe097          	auipc	ra,0xffffe
    80005718:	8f6080e7          	jalr	-1802(ra) # 8000300a <argint>
  if(argfd(0, 0, &f) < 0)
    8000571c:	fe840613          	addi	a2,s0,-24
    80005720:	4581                	li	a1,0
    80005722:	4501                	li	a0,0
    80005724:	00000097          	auipc	ra,0x0
    80005728:	d5e080e7          	jalr	-674(ra) # 80005482 <argfd>
    8000572c:	87aa                	mv	a5,a0
    return -1;
    8000572e:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005730:	0007cc63          	bltz	a5,80005748 <sys_read+0x50>
  return fileread(f, p, n);
    80005734:	fe442603          	lw	a2,-28(s0)
    80005738:	fd843583          	ld	a1,-40(s0)
    8000573c:	fe843503          	ld	a0,-24(s0)
    80005740:	fffff097          	auipc	ra,0xfffff
    80005744:	460080e7          	jalr	1120(ra) # 80004ba0 <fileread>
}
    80005748:	70a2                	ld	ra,40(sp)
    8000574a:	7402                	ld	s0,32(sp)
    8000574c:	6145                	addi	sp,sp,48
    8000574e:	8082                	ret

0000000080005750 <sys_write>:
{
    80005750:	7179                	addi	sp,sp,-48
    80005752:	f406                	sd	ra,40(sp)
    80005754:	f022                	sd	s0,32(sp)
    80005756:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005758:	fd840593          	addi	a1,s0,-40
    8000575c:	4505                	li	a0,1
    8000575e:	ffffe097          	auipc	ra,0xffffe
    80005762:	8cc080e7          	jalr	-1844(ra) # 8000302a <argaddr>
  argint(2, &n);
    80005766:	fe440593          	addi	a1,s0,-28
    8000576a:	4509                	li	a0,2
    8000576c:	ffffe097          	auipc	ra,0xffffe
    80005770:	89e080e7          	jalr	-1890(ra) # 8000300a <argint>
  if(argfd(0, 0, &f) < 0)
    80005774:	fe840613          	addi	a2,s0,-24
    80005778:	4581                	li	a1,0
    8000577a:	4501                	li	a0,0
    8000577c:	00000097          	auipc	ra,0x0
    80005780:	d06080e7          	jalr	-762(ra) # 80005482 <argfd>
    80005784:	87aa                	mv	a5,a0
    return -1;
    80005786:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005788:	0007cc63          	bltz	a5,800057a0 <sys_write+0x50>
  return filewrite(f, p, n);
    8000578c:	fe442603          	lw	a2,-28(s0)
    80005790:	fd843583          	ld	a1,-40(s0)
    80005794:	fe843503          	ld	a0,-24(s0)
    80005798:	fffff097          	auipc	ra,0xfffff
    8000579c:	4ca080e7          	jalr	1226(ra) # 80004c62 <filewrite>
}
    800057a0:	70a2                	ld	ra,40(sp)
    800057a2:	7402                	ld	s0,32(sp)
    800057a4:	6145                	addi	sp,sp,48
    800057a6:	8082                	ret

00000000800057a8 <sys_close>:
{
    800057a8:	1101                	addi	sp,sp,-32
    800057aa:	ec06                	sd	ra,24(sp)
    800057ac:	e822                	sd	s0,16(sp)
    800057ae:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800057b0:	fe040613          	addi	a2,s0,-32
    800057b4:	fec40593          	addi	a1,s0,-20
    800057b8:	4501                	li	a0,0
    800057ba:	00000097          	auipc	ra,0x0
    800057be:	cc8080e7          	jalr	-824(ra) # 80005482 <argfd>
    return -1;
    800057c2:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800057c4:	02054463          	bltz	a0,800057ec <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800057c8:	ffffc097          	auipc	ra,0xffffc
    800057cc:	4cc080e7          	jalr	1228(ra) # 80001c94 <myproc>
    800057d0:	fec42783          	lw	a5,-20(s0)
    800057d4:	07e9                	addi	a5,a5,26
    800057d6:	078e                	slli	a5,a5,0x3
    800057d8:	953e                	add	a0,a0,a5
    800057da:	00053023          	sd	zero,0(a0)
  fileclose(f);
    800057de:	fe043503          	ld	a0,-32(s0)
    800057e2:	fffff097          	auipc	ra,0xfffff
    800057e6:	284080e7          	jalr	644(ra) # 80004a66 <fileclose>
  return 0;
    800057ea:	4781                	li	a5,0
}
    800057ec:	853e                	mv	a0,a5
    800057ee:	60e2                	ld	ra,24(sp)
    800057f0:	6442                	ld	s0,16(sp)
    800057f2:	6105                	addi	sp,sp,32
    800057f4:	8082                	ret

00000000800057f6 <sys_fstat>:
{
    800057f6:	1101                	addi	sp,sp,-32
    800057f8:	ec06                	sd	ra,24(sp)
    800057fa:	e822                	sd	s0,16(sp)
    800057fc:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    800057fe:	fe040593          	addi	a1,s0,-32
    80005802:	4505                	li	a0,1
    80005804:	ffffe097          	auipc	ra,0xffffe
    80005808:	826080e7          	jalr	-2010(ra) # 8000302a <argaddr>
  if(argfd(0, 0, &f) < 0)
    8000580c:	fe840613          	addi	a2,s0,-24
    80005810:	4581                	li	a1,0
    80005812:	4501                	li	a0,0
    80005814:	00000097          	auipc	ra,0x0
    80005818:	c6e080e7          	jalr	-914(ra) # 80005482 <argfd>
    8000581c:	87aa                	mv	a5,a0
    return -1;
    8000581e:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005820:	0007ca63          	bltz	a5,80005834 <sys_fstat+0x3e>
  return filestat(f, st);
    80005824:	fe043583          	ld	a1,-32(s0)
    80005828:	fe843503          	ld	a0,-24(s0)
    8000582c:	fffff097          	auipc	ra,0xfffff
    80005830:	302080e7          	jalr	770(ra) # 80004b2e <filestat>
}
    80005834:	60e2                	ld	ra,24(sp)
    80005836:	6442                	ld	s0,16(sp)
    80005838:	6105                	addi	sp,sp,32
    8000583a:	8082                	ret

000000008000583c <sys_link>:
{
    8000583c:	7169                	addi	sp,sp,-304
    8000583e:	f606                	sd	ra,296(sp)
    80005840:	f222                	sd	s0,288(sp)
    80005842:	ee26                	sd	s1,280(sp)
    80005844:	ea4a                	sd	s2,272(sp)
    80005846:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005848:	08000613          	li	a2,128
    8000584c:	ed040593          	addi	a1,s0,-304
    80005850:	4501                	li	a0,0
    80005852:	ffffd097          	auipc	ra,0xffffd
    80005856:	7f8080e7          	jalr	2040(ra) # 8000304a <argstr>
    return -1;
    8000585a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000585c:	10054e63          	bltz	a0,80005978 <sys_link+0x13c>
    80005860:	08000613          	li	a2,128
    80005864:	f5040593          	addi	a1,s0,-176
    80005868:	4505                	li	a0,1
    8000586a:	ffffd097          	auipc	ra,0xffffd
    8000586e:	7e0080e7          	jalr	2016(ra) # 8000304a <argstr>
    return -1;
    80005872:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005874:	10054263          	bltz	a0,80005978 <sys_link+0x13c>
  begin_op();
    80005878:	fffff097          	auipc	ra,0xfffff
    8000587c:	d2a080e7          	jalr	-726(ra) # 800045a2 <begin_op>
  if((ip = namei(old)) == 0){
    80005880:	ed040513          	addi	a0,s0,-304
    80005884:	fffff097          	auipc	ra,0xfffff
    80005888:	b1e080e7          	jalr	-1250(ra) # 800043a2 <namei>
    8000588c:	84aa                	mv	s1,a0
    8000588e:	c551                	beqz	a0,8000591a <sys_link+0xde>
  ilock(ip);
    80005890:	ffffe097          	auipc	ra,0xffffe
    80005894:	36c080e7          	jalr	876(ra) # 80003bfc <ilock>
  if(ip->type == T_DIR){
    80005898:	04449703          	lh	a4,68(s1)
    8000589c:	4785                	li	a5,1
    8000589e:	08f70463          	beq	a4,a5,80005926 <sys_link+0xea>
  ip->nlink++;
    800058a2:	04a4d783          	lhu	a5,74(s1)
    800058a6:	2785                	addiw	a5,a5,1
    800058a8:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800058ac:	8526                	mv	a0,s1
    800058ae:	ffffe097          	auipc	ra,0xffffe
    800058b2:	282080e7          	jalr	642(ra) # 80003b30 <iupdate>
  iunlock(ip);
    800058b6:	8526                	mv	a0,s1
    800058b8:	ffffe097          	auipc	ra,0xffffe
    800058bc:	406080e7          	jalr	1030(ra) # 80003cbe <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800058c0:	fd040593          	addi	a1,s0,-48
    800058c4:	f5040513          	addi	a0,s0,-176
    800058c8:	fffff097          	auipc	ra,0xfffff
    800058cc:	af8080e7          	jalr	-1288(ra) # 800043c0 <nameiparent>
    800058d0:	892a                	mv	s2,a0
    800058d2:	c935                	beqz	a0,80005946 <sys_link+0x10a>
  ilock(dp);
    800058d4:	ffffe097          	auipc	ra,0xffffe
    800058d8:	328080e7          	jalr	808(ra) # 80003bfc <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800058dc:	00092703          	lw	a4,0(s2)
    800058e0:	409c                	lw	a5,0(s1)
    800058e2:	04f71d63          	bne	a4,a5,8000593c <sys_link+0x100>
    800058e6:	40d0                	lw	a2,4(s1)
    800058e8:	fd040593          	addi	a1,s0,-48
    800058ec:	854a                	mv	a0,s2
    800058ee:	fffff097          	auipc	ra,0xfffff
    800058f2:	a02080e7          	jalr	-1534(ra) # 800042f0 <dirlink>
    800058f6:	04054363          	bltz	a0,8000593c <sys_link+0x100>
  iunlockput(dp);
    800058fa:	854a                	mv	a0,s2
    800058fc:	ffffe097          	auipc	ra,0xffffe
    80005900:	562080e7          	jalr	1378(ra) # 80003e5e <iunlockput>
  iput(ip);
    80005904:	8526                	mv	a0,s1
    80005906:	ffffe097          	auipc	ra,0xffffe
    8000590a:	4b0080e7          	jalr	1200(ra) # 80003db6 <iput>
  end_op();
    8000590e:	fffff097          	auipc	ra,0xfffff
    80005912:	d0e080e7          	jalr	-754(ra) # 8000461c <end_op>
  return 0;
    80005916:	4781                	li	a5,0
    80005918:	a085                	j	80005978 <sys_link+0x13c>
    end_op();
    8000591a:	fffff097          	auipc	ra,0xfffff
    8000591e:	d02080e7          	jalr	-766(ra) # 8000461c <end_op>
    return -1;
    80005922:	57fd                	li	a5,-1
    80005924:	a891                	j	80005978 <sys_link+0x13c>
    iunlockput(ip);
    80005926:	8526                	mv	a0,s1
    80005928:	ffffe097          	auipc	ra,0xffffe
    8000592c:	536080e7          	jalr	1334(ra) # 80003e5e <iunlockput>
    end_op();
    80005930:	fffff097          	auipc	ra,0xfffff
    80005934:	cec080e7          	jalr	-788(ra) # 8000461c <end_op>
    return -1;
    80005938:	57fd                	li	a5,-1
    8000593a:	a83d                	j	80005978 <sys_link+0x13c>
    iunlockput(dp);
    8000593c:	854a                	mv	a0,s2
    8000593e:	ffffe097          	auipc	ra,0xffffe
    80005942:	520080e7          	jalr	1312(ra) # 80003e5e <iunlockput>
  ilock(ip);
    80005946:	8526                	mv	a0,s1
    80005948:	ffffe097          	auipc	ra,0xffffe
    8000594c:	2b4080e7          	jalr	692(ra) # 80003bfc <ilock>
  ip->nlink--;
    80005950:	04a4d783          	lhu	a5,74(s1)
    80005954:	37fd                	addiw	a5,a5,-1
    80005956:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000595a:	8526                	mv	a0,s1
    8000595c:	ffffe097          	auipc	ra,0xffffe
    80005960:	1d4080e7          	jalr	468(ra) # 80003b30 <iupdate>
  iunlockput(ip);
    80005964:	8526                	mv	a0,s1
    80005966:	ffffe097          	auipc	ra,0xffffe
    8000596a:	4f8080e7          	jalr	1272(ra) # 80003e5e <iunlockput>
  end_op();
    8000596e:	fffff097          	auipc	ra,0xfffff
    80005972:	cae080e7          	jalr	-850(ra) # 8000461c <end_op>
  return -1;
    80005976:	57fd                	li	a5,-1
}
    80005978:	853e                	mv	a0,a5
    8000597a:	70b2                	ld	ra,296(sp)
    8000597c:	7412                	ld	s0,288(sp)
    8000597e:	64f2                	ld	s1,280(sp)
    80005980:	6952                	ld	s2,272(sp)
    80005982:	6155                	addi	sp,sp,304
    80005984:	8082                	ret

0000000080005986 <sys_unlink>:
{
    80005986:	7151                	addi	sp,sp,-240
    80005988:	f586                	sd	ra,232(sp)
    8000598a:	f1a2                	sd	s0,224(sp)
    8000598c:	eda6                	sd	s1,216(sp)
    8000598e:	e9ca                	sd	s2,208(sp)
    80005990:	e5ce                	sd	s3,200(sp)
    80005992:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005994:	08000613          	li	a2,128
    80005998:	f3040593          	addi	a1,s0,-208
    8000599c:	4501                	li	a0,0
    8000599e:	ffffd097          	auipc	ra,0xffffd
    800059a2:	6ac080e7          	jalr	1708(ra) # 8000304a <argstr>
    800059a6:	18054163          	bltz	a0,80005b28 <sys_unlink+0x1a2>
  begin_op();
    800059aa:	fffff097          	auipc	ra,0xfffff
    800059ae:	bf8080e7          	jalr	-1032(ra) # 800045a2 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800059b2:	fb040593          	addi	a1,s0,-80
    800059b6:	f3040513          	addi	a0,s0,-208
    800059ba:	fffff097          	auipc	ra,0xfffff
    800059be:	a06080e7          	jalr	-1530(ra) # 800043c0 <nameiparent>
    800059c2:	84aa                	mv	s1,a0
    800059c4:	c979                	beqz	a0,80005a9a <sys_unlink+0x114>
  ilock(dp);
    800059c6:	ffffe097          	auipc	ra,0xffffe
    800059ca:	236080e7          	jalr	566(ra) # 80003bfc <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800059ce:	00003597          	auipc	a1,0x3
    800059d2:	e0a58593          	addi	a1,a1,-502 # 800087d8 <syscalls+0x2b8>
    800059d6:	fb040513          	addi	a0,s0,-80
    800059da:	ffffe097          	auipc	ra,0xffffe
    800059de:	6ec080e7          	jalr	1772(ra) # 800040c6 <namecmp>
    800059e2:	14050a63          	beqz	a0,80005b36 <sys_unlink+0x1b0>
    800059e6:	00003597          	auipc	a1,0x3
    800059ea:	dfa58593          	addi	a1,a1,-518 # 800087e0 <syscalls+0x2c0>
    800059ee:	fb040513          	addi	a0,s0,-80
    800059f2:	ffffe097          	auipc	ra,0xffffe
    800059f6:	6d4080e7          	jalr	1748(ra) # 800040c6 <namecmp>
    800059fa:	12050e63          	beqz	a0,80005b36 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800059fe:	f2c40613          	addi	a2,s0,-212
    80005a02:	fb040593          	addi	a1,s0,-80
    80005a06:	8526                	mv	a0,s1
    80005a08:	ffffe097          	auipc	ra,0xffffe
    80005a0c:	6d8080e7          	jalr	1752(ra) # 800040e0 <dirlookup>
    80005a10:	892a                	mv	s2,a0
    80005a12:	12050263          	beqz	a0,80005b36 <sys_unlink+0x1b0>
  ilock(ip);
    80005a16:	ffffe097          	auipc	ra,0xffffe
    80005a1a:	1e6080e7          	jalr	486(ra) # 80003bfc <ilock>
  if(ip->nlink < 1)
    80005a1e:	04a91783          	lh	a5,74(s2)
    80005a22:	08f05263          	blez	a5,80005aa6 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005a26:	04491703          	lh	a4,68(s2)
    80005a2a:	4785                	li	a5,1
    80005a2c:	08f70563          	beq	a4,a5,80005ab6 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005a30:	4641                	li	a2,16
    80005a32:	4581                	li	a1,0
    80005a34:	fc040513          	addi	a0,s0,-64
    80005a38:	ffffb097          	auipc	ra,0xffffb
    80005a3c:	296080e7          	jalr	662(ra) # 80000cce <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005a40:	4741                	li	a4,16
    80005a42:	f2c42683          	lw	a3,-212(s0)
    80005a46:	fc040613          	addi	a2,s0,-64
    80005a4a:	4581                	li	a1,0
    80005a4c:	8526                	mv	a0,s1
    80005a4e:	ffffe097          	auipc	ra,0xffffe
    80005a52:	55a080e7          	jalr	1370(ra) # 80003fa8 <writei>
    80005a56:	47c1                	li	a5,16
    80005a58:	0af51563          	bne	a0,a5,80005b02 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005a5c:	04491703          	lh	a4,68(s2)
    80005a60:	4785                	li	a5,1
    80005a62:	0af70863          	beq	a4,a5,80005b12 <sys_unlink+0x18c>
  iunlockput(dp);
    80005a66:	8526                	mv	a0,s1
    80005a68:	ffffe097          	auipc	ra,0xffffe
    80005a6c:	3f6080e7          	jalr	1014(ra) # 80003e5e <iunlockput>
  ip->nlink--;
    80005a70:	04a95783          	lhu	a5,74(s2)
    80005a74:	37fd                	addiw	a5,a5,-1
    80005a76:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005a7a:	854a                	mv	a0,s2
    80005a7c:	ffffe097          	auipc	ra,0xffffe
    80005a80:	0b4080e7          	jalr	180(ra) # 80003b30 <iupdate>
  iunlockput(ip);
    80005a84:	854a                	mv	a0,s2
    80005a86:	ffffe097          	auipc	ra,0xffffe
    80005a8a:	3d8080e7          	jalr	984(ra) # 80003e5e <iunlockput>
  end_op();
    80005a8e:	fffff097          	auipc	ra,0xfffff
    80005a92:	b8e080e7          	jalr	-1138(ra) # 8000461c <end_op>
  return 0;
    80005a96:	4501                	li	a0,0
    80005a98:	a84d                	j	80005b4a <sys_unlink+0x1c4>
    end_op();
    80005a9a:	fffff097          	auipc	ra,0xfffff
    80005a9e:	b82080e7          	jalr	-1150(ra) # 8000461c <end_op>
    return -1;
    80005aa2:	557d                	li	a0,-1
    80005aa4:	a05d                	j	80005b4a <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005aa6:	00003517          	auipc	a0,0x3
    80005aaa:	d4250513          	addi	a0,a0,-702 # 800087e8 <syscalls+0x2c8>
    80005aae:	ffffb097          	auipc	ra,0xffffb
    80005ab2:	a8e080e7          	jalr	-1394(ra) # 8000053c <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005ab6:	04c92703          	lw	a4,76(s2)
    80005aba:	02000793          	li	a5,32
    80005abe:	f6e7f9e3          	bgeu	a5,a4,80005a30 <sys_unlink+0xaa>
    80005ac2:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005ac6:	4741                	li	a4,16
    80005ac8:	86ce                	mv	a3,s3
    80005aca:	f1840613          	addi	a2,s0,-232
    80005ace:	4581                	li	a1,0
    80005ad0:	854a                	mv	a0,s2
    80005ad2:	ffffe097          	auipc	ra,0xffffe
    80005ad6:	3de080e7          	jalr	990(ra) # 80003eb0 <readi>
    80005ada:	47c1                	li	a5,16
    80005adc:	00f51b63          	bne	a0,a5,80005af2 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005ae0:	f1845783          	lhu	a5,-232(s0)
    80005ae4:	e7a1                	bnez	a5,80005b2c <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005ae6:	29c1                	addiw	s3,s3,16
    80005ae8:	04c92783          	lw	a5,76(s2)
    80005aec:	fcf9ede3          	bltu	s3,a5,80005ac6 <sys_unlink+0x140>
    80005af0:	b781                	j	80005a30 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005af2:	00003517          	auipc	a0,0x3
    80005af6:	d0e50513          	addi	a0,a0,-754 # 80008800 <syscalls+0x2e0>
    80005afa:	ffffb097          	auipc	ra,0xffffb
    80005afe:	a42080e7          	jalr	-1470(ra) # 8000053c <panic>
    panic("unlink: writei");
    80005b02:	00003517          	auipc	a0,0x3
    80005b06:	d1650513          	addi	a0,a0,-746 # 80008818 <syscalls+0x2f8>
    80005b0a:	ffffb097          	auipc	ra,0xffffb
    80005b0e:	a32080e7          	jalr	-1486(ra) # 8000053c <panic>
    dp->nlink--;
    80005b12:	04a4d783          	lhu	a5,74(s1)
    80005b16:	37fd                	addiw	a5,a5,-1
    80005b18:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005b1c:	8526                	mv	a0,s1
    80005b1e:	ffffe097          	auipc	ra,0xffffe
    80005b22:	012080e7          	jalr	18(ra) # 80003b30 <iupdate>
    80005b26:	b781                	j	80005a66 <sys_unlink+0xe0>
    return -1;
    80005b28:	557d                	li	a0,-1
    80005b2a:	a005                	j	80005b4a <sys_unlink+0x1c4>
    iunlockput(ip);
    80005b2c:	854a                	mv	a0,s2
    80005b2e:	ffffe097          	auipc	ra,0xffffe
    80005b32:	330080e7          	jalr	816(ra) # 80003e5e <iunlockput>
  iunlockput(dp);
    80005b36:	8526                	mv	a0,s1
    80005b38:	ffffe097          	auipc	ra,0xffffe
    80005b3c:	326080e7          	jalr	806(ra) # 80003e5e <iunlockput>
  end_op();
    80005b40:	fffff097          	auipc	ra,0xfffff
    80005b44:	adc080e7          	jalr	-1316(ra) # 8000461c <end_op>
  return -1;
    80005b48:	557d                	li	a0,-1
}
    80005b4a:	70ae                	ld	ra,232(sp)
    80005b4c:	740e                	ld	s0,224(sp)
    80005b4e:	64ee                	ld	s1,216(sp)
    80005b50:	694e                	ld	s2,208(sp)
    80005b52:	69ae                	ld	s3,200(sp)
    80005b54:	616d                	addi	sp,sp,240
    80005b56:	8082                	ret

0000000080005b58 <sys_open>:

uint64
sys_open(void)
{
    80005b58:	7131                	addi	sp,sp,-192
    80005b5a:	fd06                	sd	ra,184(sp)
    80005b5c:	f922                	sd	s0,176(sp)
    80005b5e:	f526                	sd	s1,168(sp)
    80005b60:	f14a                	sd	s2,160(sp)
    80005b62:	ed4e                	sd	s3,152(sp)
    80005b64:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005b66:	f4c40593          	addi	a1,s0,-180
    80005b6a:	4505                	li	a0,1
    80005b6c:	ffffd097          	auipc	ra,0xffffd
    80005b70:	49e080e7          	jalr	1182(ra) # 8000300a <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005b74:	08000613          	li	a2,128
    80005b78:	f5040593          	addi	a1,s0,-176
    80005b7c:	4501                	li	a0,0
    80005b7e:	ffffd097          	auipc	ra,0xffffd
    80005b82:	4cc080e7          	jalr	1228(ra) # 8000304a <argstr>
    80005b86:	87aa                	mv	a5,a0
    return -1;
    80005b88:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005b8a:	0a07c863          	bltz	a5,80005c3a <sys_open+0xe2>

  begin_op();
    80005b8e:	fffff097          	auipc	ra,0xfffff
    80005b92:	a14080e7          	jalr	-1516(ra) # 800045a2 <begin_op>

  if(omode & O_CREATE){
    80005b96:	f4c42783          	lw	a5,-180(s0)
    80005b9a:	2007f793          	andi	a5,a5,512
    80005b9e:	cbdd                	beqz	a5,80005c54 <sys_open+0xfc>
    ip = create(path, T_FILE, 0, 0);
    80005ba0:	4681                	li	a3,0
    80005ba2:	4601                	li	a2,0
    80005ba4:	4589                	li	a1,2
    80005ba6:	f5040513          	addi	a0,s0,-176
    80005baa:	00000097          	auipc	ra,0x0
    80005bae:	97a080e7          	jalr	-1670(ra) # 80005524 <create>
    80005bb2:	84aa                	mv	s1,a0
    if(ip == 0){
    80005bb4:	c951                	beqz	a0,80005c48 <sys_open+0xf0>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005bb6:	04449703          	lh	a4,68(s1)
    80005bba:	478d                	li	a5,3
    80005bbc:	00f71763          	bne	a4,a5,80005bca <sys_open+0x72>
    80005bc0:	0464d703          	lhu	a4,70(s1)
    80005bc4:	47a5                	li	a5,9
    80005bc6:	0ce7ec63          	bltu	a5,a4,80005c9e <sys_open+0x146>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005bca:	fffff097          	auipc	ra,0xfffff
    80005bce:	de0080e7          	jalr	-544(ra) # 800049aa <filealloc>
    80005bd2:	892a                	mv	s2,a0
    80005bd4:	c56d                	beqz	a0,80005cbe <sys_open+0x166>
    80005bd6:	00000097          	auipc	ra,0x0
    80005bda:	90c080e7          	jalr	-1780(ra) # 800054e2 <fdalloc>
    80005bde:	89aa                	mv	s3,a0
    80005be0:	0c054a63          	bltz	a0,80005cb4 <sys_open+0x15c>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005be4:	04449703          	lh	a4,68(s1)
    80005be8:	478d                	li	a5,3
    80005bea:	0ef70563          	beq	a4,a5,80005cd4 <sys_open+0x17c>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005bee:	4789                	li	a5,2
    80005bf0:	00f92023          	sw	a5,0(s2)
    f->off = 0;
    80005bf4:	02092023          	sw	zero,32(s2)
  }
  f->ip = ip;
    80005bf8:	00993c23          	sd	s1,24(s2)
  f->readable = !(omode & O_WRONLY);
    80005bfc:	f4c42783          	lw	a5,-180(s0)
    80005c00:	0017c713          	xori	a4,a5,1
    80005c04:	8b05                	andi	a4,a4,1
    80005c06:	00e90423          	sb	a4,8(s2)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005c0a:	0037f713          	andi	a4,a5,3
    80005c0e:	00e03733          	snez	a4,a4
    80005c12:	00e904a3          	sb	a4,9(s2)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005c16:	4007f793          	andi	a5,a5,1024
    80005c1a:	c791                	beqz	a5,80005c26 <sys_open+0xce>
    80005c1c:	04449703          	lh	a4,68(s1)
    80005c20:	4789                	li	a5,2
    80005c22:	0cf70063          	beq	a4,a5,80005ce2 <sys_open+0x18a>
    itrunc(ip);
  }

  iunlock(ip);
    80005c26:	8526                	mv	a0,s1
    80005c28:	ffffe097          	auipc	ra,0xffffe
    80005c2c:	096080e7          	jalr	150(ra) # 80003cbe <iunlock>
  end_op();
    80005c30:	fffff097          	auipc	ra,0xfffff
    80005c34:	9ec080e7          	jalr	-1556(ra) # 8000461c <end_op>

  return fd;
    80005c38:	854e                	mv	a0,s3
}
    80005c3a:	70ea                	ld	ra,184(sp)
    80005c3c:	744a                	ld	s0,176(sp)
    80005c3e:	74aa                	ld	s1,168(sp)
    80005c40:	790a                	ld	s2,160(sp)
    80005c42:	69ea                	ld	s3,152(sp)
    80005c44:	6129                	addi	sp,sp,192
    80005c46:	8082                	ret
      end_op();
    80005c48:	fffff097          	auipc	ra,0xfffff
    80005c4c:	9d4080e7          	jalr	-1580(ra) # 8000461c <end_op>
      return -1;
    80005c50:	557d                	li	a0,-1
    80005c52:	b7e5                	j	80005c3a <sys_open+0xe2>
    if((ip = namei(path)) == 0){
    80005c54:	f5040513          	addi	a0,s0,-176
    80005c58:	ffffe097          	auipc	ra,0xffffe
    80005c5c:	74a080e7          	jalr	1866(ra) # 800043a2 <namei>
    80005c60:	84aa                	mv	s1,a0
    80005c62:	c905                	beqz	a0,80005c92 <sys_open+0x13a>
    ilock(ip);
    80005c64:	ffffe097          	auipc	ra,0xffffe
    80005c68:	f98080e7          	jalr	-104(ra) # 80003bfc <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005c6c:	04449703          	lh	a4,68(s1)
    80005c70:	4785                	li	a5,1
    80005c72:	f4f712e3          	bne	a4,a5,80005bb6 <sys_open+0x5e>
    80005c76:	f4c42783          	lw	a5,-180(s0)
    80005c7a:	dba1                	beqz	a5,80005bca <sys_open+0x72>
      iunlockput(ip);
    80005c7c:	8526                	mv	a0,s1
    80005c7e:	ffffe097          	auipc	ra,0xffffe
    80005c82:	1e0080e7          	jalr	480(ra) # 80003e5e <iunlockput>
      end_op();
    80005c86:	fffff097          	auipc	ra,0xfffff
    80005c8a:	996080e7          	jalr	-1642(ra) # 8000461c <end_op>
      return -1;
    80005c8e:	557d                	li	a0,-1
    80005c90:	b76d                	j	80005c3a <sys_open+0xe2>
      end_op();
    80005c92:	fffff097          	auipc	ra,0xfffff
    80005c96:	98a080e7          	jalr	-1654(ra) # 8000461c <end_op>
      return -1;
    80005c9a:	557d                	li	a0,-1
    80005c9c:	bf79                	j	80005c3a <sys_open+0xe2>
    iunlockput(ip);
    80005c9e:	8526                	mv	a0,s1
    80005ca0:	ffffe097          	auipc	ra,0xffffe
    80005ca4:	1be080e7          	jalr	446(ra) # 80003e5e <iunlockput>
    end_op();
    80005ca8:	fffff097          	auipc	ra,0xfffff
    80005cac:	974080e7          	jalr	-1676(ra) # 8000461c <end_op>
    return -1;
    80005cb0:	557d                	li	a0,-1
    80005cb2:	b761                	j	80005c3a <sys_open+0xe2>
      fileclose(f);
    80005cb4:	854a                	mv	a0,s2
    80005cb6:	fffff097          	auipc	ra,0xfffff
    80005cba:	db0080e7          	jalr	-592(ra) # 80004a66 <fileclose>
    iunlockput(ip);
    80005cbe:	8526                	mv	a0,s1
    80005cc0:	ffffe097          	auipc	ra,0xffffe
    80005cc4:	19e080e7          	jalr	414(ra) # 80003e5e <iunlockput>
    end_op();
    80005cc8:	fffff097          	auipc	ra,0xfffff
    80005ccc:	954080e7          	jalr	-1708(ra) # 8000461c <end_op>
    return -1;
    80005cd0:	557d                	li	a0,-1
    80005cd2:	b7a5                	j	80005c3a <sys_open+0xe2>
    f->type = FD_DEVICE;
    80005cd4:	00f92023          	sw	a5,0(s2)
    f->major = ip->major;
    80005cd8:	04649783          	lh	a5,70(s1)
    80005cdc:	02f91223          	sh	a5,36(s2)
    80005ce0:	bf21                	j	80005bf8 <sys_open+0xa0>
    itrunc(ip);
    80005ce2:	8526                	mv	a0,s1
    80005ce4:	ffffe097          	auipc	ra,0xffffe
    80005ce8:	026080e7          	jalr	38(ra) # 80003d0a <itrunc>
    80005cec:	bf2d                	j	80005c26 <sys_open+0xce>

0000000080005cee <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005cee:	7175                	addi	sp,sp,-144
    80005cf0:	e506                	sd	ra,136(sp)
    80005cf2:	e122                	sd	s0,128(sp)
    80005cf4:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005cf6:	fffff097          	auipc	ra,0xfffff
    80005cfa:	8ac080e7          	jalr	-1876(ra) # 800045a2 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005cfe:	08000613          	li	a2,128
    80005d02:	f7040593          	addi	a1,s0,-144
    80005d06:	4501                	li	a0,0
    80005d08:	ffffd097          	auipc	ra,0xffffd
    80005d0c:	342080e7          	jalr	834(ra) # 8000304a <argstr>
    80005d10:	02054963          	bltz	a0,80005d42 <sys_mkdir+0x54>
    80005d14:	4681                	li	a3,0
    80005d16:	4601                	li	a2,0
    80005d18:	4585                	li	a1,1
    80005d1a:	f7040513          	addi	a0,s0,-144
    80005d1e:	00000097          	auipc	ra,0x0
    80005d22:	806080e7          	jalr	-2042(ra) # 80005524 <create>
    80005d26:	cd11                	beqz	a0,80005d42 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005d28:	ffffe097          	auipc	ra,0xffffe
    80005d2c:	136080e7          	jalr	310(ra) # 80003e5e <iunlockput>
  end_op();
    80005d30:	fffff097          	auipc	ra,0xfffff
    80005d34:	8ec080e7          	jalr	-1812(ra) # 8000461c <end_op>
  return 0;
    80005d38:	4501                	li	a0,0
}
    80005d3a:	60aa                	ld	ra,136(sp)
    80005d3c:	640a                	ld	s0,128(sp)
    80005d3e:	6149                	addi	sp,sp,144
    80005d40:	8082                	ret
    end_op();
    80005d42:	fffff097          	auipc	ra,0xfffff
    80005d46:	8da080e7          	jalr	-1830(ra) # 8000461c <end_op>
    return -1;
    80005d4a:	557d                	li	a0,-1
    80005d4c:	b7fd                	j	80005d3a <sys_mkdir+0x4c>

0000000080005d4e <sys_mknod>:

uint64
sys_mknod(void)
{
    80005d4e:	7135                	addi	sp,sp,-160
    80005d50:	ed06                	sd	ra,152(sp)
    80005d52:	e922                	sd	s0,144(sp)
    80005d54:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005d56:	fffff097          	auipc	ra,0xfffff
    80005d5a:	84c080e7          	jalr	-1972(ra) # 800045a2 <begin_op>
  argint(1, &major);
    80005d5e:	f6c40593          	addi	a1,s0,-148
    80005d62:	4505                	li	a0,1
    80005d64:	ffffd097          	auipc	ra,0xffffd
    80005d68:	2a6080e7          	jalr	678(ra) # 8000300a <argint>
  argint(2, &minor);
    80005d6c:	f6840593          	addi	a1,s0,-152
    80005d70:	4509                	li	a0,2
    80005d72:	ffffd097          	auipc	ra,0xffffd
    80005d76:	298080e7          	jalr	664(ra) # 8000300a <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005d7a:	08000613          	li	a2,128
    80005d7e:	f7040593          	addi	a1,s0,-144
    80005d82:	4501                	li	a0,0
    80005d84:	ffffd097          	auipc	ra,0xffffd
    80005d88:	2c6080e7          	jalr	710(ra) # 8000304a <argstr>
    80005d8c:	02054b63          	bltz	a0,80005dc2 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005d90:	f6841683          	lh	a3,-152(s0)
    80005d94:	f6c41603          	lh	a2,-148(s0)
    80005d98:	458d                	li	a1,3
    80005d9a:	f7040513          	addi	a0,s0,-144
    80005d9e:	fffff097          	auipc	ra,0xfffff
    80005da2:	786080e7          	jalr	1926(ra) # 80005524 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005da6:	cd11                	beqz	a0,80005dc2 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005da8:	ffffe097          	auipc	ra,0xffffe
    80005dac:	0b6080e7          	jalr	182(ra) # 80003e5e <iunlockput>
  end_op();
    80005db0:	fffff097          	auipc	ra,0xfffff
    80005db4:	86c080e7          	jalr	-1940(ra) # 8000461c <end_op>
  return 0;
    80005db8:	4501                	li	a0,0
}
    80005dba:	60ea                	ld	ra,152(sp)
    80005dbc:	644a                	ld	s0,144(sp)
    80005dbe:	610d                	addi	sp,sp,160
    80005dc0:	8082                	ret
    end_op();
    80005dc2:	fffff097          	auipc	ra,0xfffff
    80005dc6:	85a080e7          	jalr	-1958(ra) # 8000461c <end_op>
    return -1;
    80005dca:	557d                	li	a0,-1
    80005dcc:	b7fd                	j	80005dba <sys_mknod+0x6c>

0000000080005dce <sys_chdir>:

uint64
sys_chdir(void)
{
    80005dce:	7135                	addi	sp,sp,-160
    80005dd0:	ed06                	sd	ra,152(sp)
    80005dd2:	e922                	sd	s0,144(sp)
    80005dd4:	e526                	sd	s1,136(sp)
    80005dd6:	e14a                	sd	s2,128(sp)
    80005dd8:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005dda:	ffffc097          	auipc	ra,0xffffc
    80005dde:	eba080e7          	jalr	-326(ra) # 80001c94 <myproc>
    80005de2:	892a                	mv	s2,a0
  
  begin_op();
    80005de4:	ffffe097          	auipc	ra,0xffffe
    80005de8:	7be080e7          	jalr	1982(ra) # 800045a2 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005dec:	08000613          	li	a2,128
    80005df0:	f6040593          	addi	a1,s0,-160
    80005df4:	4501                	li	a0,0
    80005df6:	ffffd097          	auipc	ra,0xffffd
    80005dfa:	254080e7          	jalr	596(ra) # 8000304a <argstr>
    80005dfe:	04054b63          	bltz	a0,80005e54 <sys_chdir+0x86>
    80005e02:	f6040513          	addi	a0,s0,-160
    80005e06:	ffffe097          	auipc	ra,0xffffe
    80005e0a:	59c080e7          	jalr	1436(ra) # 800043a2 <namei>
    80005e0e:	84aa                	mv	s1,a0
    80005e10:	c131                	beqz	a0,80005e54 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005e12:	ffffe097          	auipc	ra,0xffffe
    80005e16:	dea080e7          	jalr	-534(ra) # 80003bfc <ilock>
  if(ip->type != T_DIR){
    80005e1a:	04449703          	lh	a4,68(s1)
    80005e1e:	4785                	li	a5,1
    80005e20:	04f71063          	bne	a4,a5,80005e60 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005e24:	8526                	mv	a0,s1
    80005e26:	ffffe097          	auipc	ra,0xffffe
    80005e2a:	e98080e7          	jalr	-360(ra) # 80003cbe <iunlock>
  iput(p->cwd);
    80005e2e:	15093503          	ld	a0,336(s2)
    80005e32:	ffffe097          	auipc	ra,0xffffe
    80005e36:	f84080e7          	jalr	-124(ra) # 80003db6 <iput>
  end_op();
    80005e3a:	ffffe097          	auipc	ra,0xffffe
    80005e3e:	7e2080e7          	jalr	2018(ra) # 8000461c <end_op>
  p->cwd = ip;
    80005e42:	14993823          	sd	s1,336(s2)
  return 0;
    80005e46:	4501                	li	a0,0
}
    80005e48:	60ea                	ld	ra,152(sp)
    80005e4a:	644a                	ld	s0,144(sp)
    80005e4c:	64aa                	ld	s1,136(sp)
    80005e4e:	690a                	ld	s2,128(sp)
    80005e50:	610d                	addi	sp,sp,160
    80005e52:	8082                	ret
    end_op();
    80005e54:	ffffe097          	auipc	ra,0xffffe
    80005e58:	7c8080e7          	jalr	1992(ra) # 8000461c <end_op>
    return -1;
    80005e5c:	557d                	li	a0,-1
    80005e5e:	b7ed                	j	80005e48 <sys_chdir+0x7a>
    iunlockput(ip);
    80005e60:	8526                	mv	a0,s1
    80005e62:	ffffe097          	auipc	ra,0xffffe
    80005e66:	ffc080e7          	jalr	-4(ra) # 80003e5e <iunlockput>
    end_op();
    80005e6a:	ffffe097          	auipc	ra,0xffffe
    80005e6e:	7b2080e7          	jalr	1970(ra) # 8000461c <end_op>
    return -1;
    80005e72:	557d                	li	a0,-1
    80005e74:	bfd1                	j	80005e48 <sys_chdir+0x7a>

0000000080005e76 <sys_exec>:

uint64
sys_exec(void)
{
    80005e76:	7121                	addi	sp,sp,-448
    80005e78:	ff06                	sd	ra,440(sp)
    80005e7a:	fb22                	sd	s0,432(sp)
    80005e7c:	f726                	sd	s1,424(sp)
    80005e7e:	f34a                	sd	s2,416(sp)
    80005e80:	ef4e                	sd	s3,408(sp)
    80005e82:	eb52                	sd	s4,400(sp)
    80005e84:	0380                	addi	s0,sp,448
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005e86:	e4840593          	addi	a1,s0,-440
    80005e8a:	4505                	li	a0,1
    80005e8c:	ffffd097          	auipc	ra,0xffffd
    80005e90:	19e080e7          	jalr	414(ra) # 8000302a <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005e94:	08000613          	li	a2,128
    80005e98:	f5040593          	addi	a1,s0,-176
    80005e9c:	4501                	li	a0,0
    80005e9e:	ffffd097          	auipc	ra,0xffffd
    80005ea2:	1ac080e7          	jalr	428(ra) # 8000304a <argstr>
    80005ea6:	87aa                	mv	a5,a0
    return -1;
    80005ea8:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005eaa:	0c07c263          	bltz	a5,80005f6e <sys_exec+0xf8>
  }
  memset(argv, 0, sizeof(argv));
    80005eae:	10000613          	li	a2,256
    80005eb2:	4581                	li	a1,0
    80005eb4:	e5040513          	addi	a0,s0,-432
    80005eb8:	ffffb097          	auipc	ra,0xffffb
    80005ebc:	e16080e7          	jalr	-490(ra) # 80000cce <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005ec0:	e5040493          	addi	s1,s0,-432
  memset(argv, 0, sizeof(argv));
    80005ec4:	89a6                	mv	s3,s1
    80005ec6:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005ec8:	02000a13          	li	s4,32
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005ecc:	00391513          	slli	a0,s2,0x3
    80005ed0:	e4040593          	addi	a1,s0,-448
    80005ed4:	e4843783          	ld	a5,-440(s0)
    80005ed8:	953e                	add	a0,a0,a5
    80005eda:	ffffd097          	auipc	ra,0xffffd
    80005ede:	092080e7          	jalr	146(ra) # 80002f6c <fetchaddr>
    80005ee2:	02054a63          	bltz	a0,80005f16 <sys_exec+0xa0>
      goto bad;
    }
    if(uarg == 0){
    80005ee6:	e4043783          	ld	a5,-448(s0)
    80005eea:	c3b9                	beqz	a5,80005f30 <sys_exec+0xba>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005eec:	ffffb097          	auipc	ra,0xffffb
    80005ef0:	bf6080e7          	jalr	-1034(ra) # 80000ae2 <kalloc>
    80005ef4:	85aa                	mv	a1,a0
    80005ef6:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005efa:	cd11                	beqz	a0,80005f16 <sys_exec+0xa0>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005efc:	6605                	lui	a2,0x1
    80005efe:	e4043503          	ld	a0,-448(s0)
    80005f02:	ffffd097          	auipc	ra,0xffffd
    80005f06:	0bc080e7          	jalr	188(ra) # 80002fbe <fetchstr>
    80005f0a:	00054663          	bltz	a0,80005f16 <sys_exec+0xa0>
    if(i >= NELEM(argv)){
    80005f0e:	0905                	addi	s2,s2,1
    80005f10:	09a1                	addi	s3,s3,8
    80005f12:	fb491de3          	bne	s2,s4,80005ecc <sys_exec+0x56>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f16:	f5040913          	addi	s2,s0,-176
    80005f1a:	6088                	ld	a0,0(s1)
    80005f1c:	c921                	beqz	a0,80005f6c <sys_exec+0xf6>
    kfree(argv[i]);
    80005f1e:	ffffb097          	auipc	ra,0xffffb
    80005f22:	ac6080e7          	jalr	-1338(ra) # 800009e4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f26:	04a1                	addi	s1,s1,8
    80005f28:	ff2499e3          	bne	s1,s2,80005f1a <sys_exec+0xa4>
  return -1;
    80005f2c:	557d                	li	a0,-1
    80005f2e:	a081                	j	80005f6e <sys_exec+0xf8>
      argv[i] = 0;
    80005f30:	0009079b          	sext.w	a5,s2
    80005f34:	078e                	slli	a5,a5,0x3
    80005f36:	fd078793          	addi	a5,a5,-48
    80005f3a:	97a2                	add	a5,a5,s0
    80005f3c:	e807b023          	sd	zero,-384(a5)
  int ret = exec(path, argv);
    80005f40:	e5040593          	addi	a1,s0,-432
    80005f44:	f5040513          	addi	a0,s0,-176
    80005f48:	fffff097          	auipc	ra,0xfffff
    80005f4c:	194080e7          	jalr	404(ra) # 800050dc <exec>
    80005f50:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f52:	f5040993          	addi	s3,s0,-176
    80005f56:	6088                	ld	a0,0(s1)
    80005f58:	c901                	beqz	a0,80005f68 <sys_exec+0xf2>
    kfree(argv[i]);
    80005f5a:	ffffb097          	auipc	ra,0xffffb
    80005f5e:	a8a080e7          	jalr	-1398(ra) # 800009e4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f62:	04a1                	addi	s1,s1,8
    80005f64:	ff3499e3          	bne	s1,s3,80005f56 <sys_exec+0xe0>
  return ret;
    80005f68:	854a                	mv	a0,s2
    80005f6a:	a011                	j	80005f6e <sys_exec+0xf8>
  return -1;
    80005f6c:	557d                	li	a0,-1
}
    80005f6e:	70fa                	ld	ra,440(sp)
    80005f70:	745a                	ld	s0,432(sp)
    80005f72:	74ba                	ld	s1,424(sp)
    80005f74:	791a                	ld	s2,416(sp)
    80005f76:	69fa                	ld	s3,408(sp)
    80005f78:	6a5a                	ld	s4,400(sp)
    80005f7a:	6139                	addi	sp,sp,448
    80005f7c:	8082                	ret

0000000080005f7e <sys_pipe>:

uint64
sys_pipe(void)
{
    80005f7e:	7139                	addi	sp,sp,-64
    80005f80:	fc06                	sd	ra,56(sp)
    80005f82:	f822                	sd	s0,48(sp)
    80005f84:	f426                	sd	s1,40(sp)
    80005f86:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005f88:	ffffc097          	auipc	ra,0xffffc
    80005f8c:	d0c080e7          	jalr	-756(ra) # 80001c94 <myproc>
    80005f90:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005f92:	fd840593          	addi	a1,s0,-40
    80005f96:	4501                	li	a0,0
    80005f98:	ffffd097          	auipc	ra,0xffffd
    80005f9c:	092080e7          	jalr	146(ra) # 8000302a <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005fa0:	fc840593          	addi	a1,s0,-56
    80005fa4:	fd040513          	addi	a0,s0,-48
    80005fa8:	fffff097          	auipc	ra,0xfffff
    80005fac:	dea080e7          	jalr	-534(ra) # 80004d92 <pipealloc>
    return -1;
    80005fb0:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005fb2:	0c054463          	bltz	a0,8000607a <sys_pipe+0xfc>
  fd0 = -1;
    80005fb6:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005fba:	fd043503          	ld	a0,-48(s0)
    80005fbe:	fffff097          	auipc	ra,0xfffff
    80005fc2:	524080e7          	jalr	1316(ra) # 800054e2 <fdalloc>
    80005fc6:	fca42223          	sw	a0,-60(s0)
    80005fca:	08054b63          	bltz	a0,80006060 <sys_pipe+0xe2>
    80005fce:	fc843503          	ld	a0,-56(s0)
    80005fd2:	fffff097          	auipc	ra,0xfffff
    80005fd6:	510080e7          	jalr	1296(ra) # 800054e2 <fdalloc>
    80005fda:	fca42023          	sw	a0,-64(s0)
    80005fde:	06054863          	bltz	a0,8000604e <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005fe2:	4691                	li	a3,4
    80005fe4:	fc440613          	addi	a2,s0,-60
    80005fe8:	fd843583          	ld	a1,-40(s0)
    80005fec:	68a8                	ld	a0,80(s1)
    80005fee:	ffffb097          	auipc	ra,0xffffb
    80005ff2:	678080e7          	jalr	1656(ra) # 80001666 <copyout>
    80005ff6:	02054063          	bltz	a0,80006016 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005ffa:	4691                	li	a3,4
    80005ffc:	fc040613          	addi	a2,s0,-64
    80006000:	fd843583          	ld	a1,-40(s0)
    80006004:	0591                	addi	a1,a1,4
    80006006:	68a8                	ld	a0,80(s1)
    80006008:	ffffb097          	auipc	ra,0xffffb
    8000600c:	65e080e7          	jalr	1630(ra) # 80001666 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006010:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006012:	06055463          	bgez	a0,8000607a <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80006016:	fc442783          	lw	a5,-60(s0)
    8000601a:	07e9                	addi	a5,a5,26
    8000601c:	078e                	slli	a5,a5,0x3
    8000601e:	97a6                	add	a5,a5,s1
    80006020:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006024:	fc042783          	lw	a5,-64(s0)
    80006028:	07e9                	addi	a5,a5,26
    8000602a:	078e                	slli	a5,a5,0x3
    8000602c:	94be                	add	s1,s1,a5
    8000602e:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80006032:	fd043503          	ld	a0,-48(s0)
    80006036:	fffff097          	auipc	ra,0xfffff
    8000603a:	a30080e7          	jalr	-1488(ra) # 80004a66 <fileclose>
    fileclose(wf);
    8000603e:	fc843503          	ld	a0,-56(s0)
    80006042:	fffff097          	auipc	ra,0xfffff
    80006046:	a24080e7          	jalr	-1500(ra) # 80004a66 <fileclose>
    return -1;
    8000604a:	57fd                	li	a5,-1
    8000604c:	a03d                	j	8000607a <sys_pipe+0xfc>
    if(fd0 >= 0)
    8000604e:	fc442783          	lw	a5,-60(s0)
    80006052:	0007c763          	bltz	a5,80006060 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80006056:	07e9                	addi	a5,a5,26
    80006058:	078e                	slli	a5,a5,0x3
    8000605a:	97a6                	add	a5,a5,s1
    8000605c:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80006060:	fd043503          	ld	a0,-48(s0)
    80006064:	fffff097          	auipc	ra,0xfffff
    80006068:	a02080e7          	jalr	-1534(ra) # 80004a66 <fileclose>
    fileclose(wf);
    8000606c:	fc843503          	ld	a0,-56(s0)
    80006070:	fffff097          	auipc	ra,0xfffff
    80006074:	9f6080e7          	jalr	-1546(ra) # 80004a66 <fileclose>
    return -1;
    80006078:	57fd                	li	a5,-1
}
    8000607a:	853e                	mv	a0,a5
    8000607c:	70e2                	ld	ra,56(sp)
    8000607e:	7442                	ld	s0,48(sp)
    80006080:	74a2                	ld	s1,40(sp)
    80006082:	6121                	addi	sp,sp,64
    80006084:	8082                	ret
	...

0000000080006090 <kernelvec>:
    80006090:	7111                	addi	sp,sp,-256
    80006092:	e006                	sd	ra,0(sp)
    80006094:	e40a                	sd	sp,8(sp)
    80006096:	e80e                	sd	gp,16(sp)
    80006098:	ec12                	sd	tp,24(sp)
    8000609a:	f016                	sd	t0,32(sp)
    8000609c:	f41a                	sd	t1,40(sp)
    8000609e:	f81e                	sd	t2,48(sp)
    800060a0:	fc22                	sd	s0,56(sp)
    800060a2:	e0a6                	sd	s1,64(sp)
    800060a4:	e4aa                	sd	a0,72(sp)
    800060a6:	e8ae                	sd	a1,80(sp)
    800060a8:	ecb2                	sd	a2,88(sp)
    800060aa:	f0b6                	sd	a3,96(sp)
    800060ac:	f4ba                	sd	a4,104(sp)
    800060ae:	f8be                	sd	a5,112(sp)
    800060b0:	fcc2                	sd	a6,120(sp)
    800060b2:	e146                	sd	a7,128(sp)
    800060b4:	e54a                	sd	s2,136(sp)
    800060b6:	e94e                	sd	s3,144(sp)
    800060b8:	ed52                	sd	s4,152(sp)
    800060ba:	f156                	sd	s5,160(sp)
    800060bc:	f55a                	sd	s6,168(sp)
    800060be:	f95e                	sd	s7,176(sp)
    800060c0:	fd62                	sd	s8,184(sp)
    800060c2:	e1e6                	sd	s9,192(sp)
    800060c4:	e5ea                	sd	s10,200(sp)
    800060c6:	e9ee                	sd	s11,208(sp)
    800060c8:	edf2                	sd	t3,216(sp)
    800060ca:	f1f6                	sd	t4,224(sp)
    800060cc:	f5fa                	sd	t5,232(sp)
    800060ce:	f9fe                	sd	t6,240(sp)
    800060d0:	d69fc0ef          	jal	ra,80002e38 <kerneltrap>
    800060d4:	6082                	ld	ra,0(sp)
    800060d6:	6122                	ld	sp,8(sp)
    800060d8:	61c2                	ld	gp,16(sp)
    800060da:	7282                	ld	t0,32(sp)
    800060dc:	7322                	ld	t1,40(sp)
    800060de:	73c2                	ld	t2,48(sp)
    800060e0:	7462                	ld	s0,56(sp)
    800060e2:	6486                	ld	s1,64(sp)
    800060e4:	6526                	ld	a0,72(sp)
    800060e6:	65c6                	ld	a1,80(sp)
    800060e8:	6666                	ld	a2,88(sp)
    800060ea:	7686                	ld	a3,96(sp)
    800060ec:	7726                	ld	a4,104(sp)
    800060ee:	77c6                	ld	a5,112(sp)
    800060f0:	7866                	ld	a6,120(sp)
    800060f2:	688a                	ld	a7,128(sp)
    800060f4:	692a                	ld	s2,136(sp)
    800060f6:	69ca                	ld	s3,144(sp)
    800060f8:	6a6a                	ld	s4,152(sp)
    800060fa:	7a8a                	ld	s5,160(sp)
    800060fc:	7b2a                	ld	s6,168(sp)
    800060fe:	7bca                	ld	s7,176(sp)
    80006100:	7c6a                	ld	s8,184(sp)
    80006102:	6c8e                	ld	s9,192(sp)
    80006104:	6d2e                	ld	s10,200(sp)
    80006106:	6dce                	ld	s11,208(sp)
    80006108:	6e6e                	ld	t3,216(sp)
    8000610a:	7e8e                	ld	t4,224(sp)
    8000610c:	7f2e                	ld	t5,232(sp)
    8000610e:	7fce                	ld	t6,240(sp)
    80006110:	6111                	addi	sp,sp,256
    80006112:	10200073          	sret
    80006116:	00000013          	nop
    8000611a:	00000013          	nop
    8000611e:	0001                	nop

0000000080006120 <timervec>:
    80006120:	34051573          	csrrw	a0,mscratch,a0
    80006124:	e10c                	sd	a1,0(a0)
    80006126:	e510                	sd	a2,8(a0)
    80006128:	e914                	sd	a3,16(a0)
    8000612a:	6d0c                	ld	a1,24(a0)
    8000612c:	7110                	ld	a2,32(a0)
    8000612e:	6194                	ld	a3,0(a1)
    80006130:	96b2                	add	a3,a3,a2
    80006132:	e194                	sd	a3,0(a1)
    80006134:	4589                	li	a1,2
    80006136:	14459073          	csrw	sip,a1
    8000613a:	6914                	ld	a3,16(a0)
    8000613c:	6510                	ld	a2,8(a0)
    8000613e:	610c                	ld	a1,0(a0)
    80006140:	34051573          	csrrw	a0,mscratch,a0
    80006144:	30200073          	mret
	...

000000008000614a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000614a:	1141                	addi	sp,sp,-16
    8000614c:	e422                	sd	s0,8(sp)
    8000614e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006150:	0c0007b7          	lui	a5,0xc000
    80006154:	4705                	li	a4,1
    80006156:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006158:	c3d8                	sw	a4,4(a5)
}
    8000615a:	6422                	ld	s0,8(sp)
    8000615c:	0141                	addi	sp,sp,16
    8000615e:	8082                	ret

0000000080006160 <plicinithart>:

void
plicinithart(void)
{
    80006160:	1141                	addi	sp,sp,-16
    80006162:	e406                	sd	ra,8(sp)
    80006164:	e022                	sd	s0,0(sp)
    80006166:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006168:	ffffc097          	auipc	ra,0xffffc
    8000616c:	b00080e7          	jalr	-1280(ra) # 80001c68 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006170:	0085171b          	slliw	a4,a0,0x8
    80006174:	0c0027b7          	lui	a5,0xc002
    80006178:	97ba                	add	a5,a5,a4
    8000617a:	40200713          	li	a4,1026
    8000617e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006182:	00d5151b          	slliw	a0,a0,0xd
    80006186:	0c2017b7          	lui	a5,0xc201
    8000618a:	97aa                	add	a5,a5,a0
    8000618c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80006190:	60a2                	ld	ra,8(sp)
    80006192:	6402                	ld	s0,0(sp)
    80006194:	0141                	addi	sp,sp,16
    80006196:	8082                	ret

0000000080006198 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006198:	1141                	addi	sp,sp,-16
    8000619a:	e406                	sd	ra,8(sp)
    8000619c:	e022                	sd	s0,0(sp)
    8000619e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800061a0:	ffffc097          	auipc	ra,0xffffc
    800061a4:	ac8080e7          	jalr	-1336(ra) # 80001c68 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800061a8:	00d5151b          	slliw	a0,a0,0xd
    800061ac:	0c2017b7          	lui	a5,0xc201
    800061b0:	97aa                	add	a5,a5,a0
  return irq;
}
    800061b2:	43c8                	lw	a0,4(a5)
    800061b4:	60a2                	ld	ra,8(sp)
    800061b6:	6402                	ld	s0,0(sp)
    800061b8:	0141                	addi	sp,sp,16
    800061ba:	8082                	ret

00000000800061bc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800061bc:	1101                	addi	sp,sp,-32
    800061be:	ec06                	sd	ra,24(sp)
    800061c0:	e822                	sd	s0,16(sp)
    800061c2:	e426                	sd	s1,8(sp)
    800061c4:	1000                	addi	s0,sp,32
    800061c6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800061c8:	ffffc097          	auipc	ra,0xffffc
    800061cc:	aa0080e7          	jalr	-1376(ra) # 80001c68 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800061d0:	00d5151b          	slliw	a0,a0,0xd
    800061d4:	0c2017b7          	lui	a5,0xc201
    800061d8:	97aa                	add	a5,a5,a0
    800061da:	c3c4                	sw	s1,4(a5)
}
    800061dc:	60e2                	ld	ra,24(sp)
    800061de:	6442                	ld	s0,16(sp)
    800061e0:	64a2                	ld	s1,8(sp)
    800061e2:	6105                	addi	sp,sp,32
    800061e4:	8082                	ret

00000000800061e6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800061e6:	1141                	addi	sp,sp,-16
    800061e8:	e406                	sd	ra,8(sp)
    800061ea:	e022                	sd	s0,0(sp)
    800061ec:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800061ee:	479d                	li	a5,7
    800061f0:	04a7cc63          	blt	a5,a0,80006248 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    800061f4:	0001c797          	auipc	a5,0x1c
    800061f8:	b4c78793          	addi	a5,a5,-1204 # 80021d40 <disk>
    800061fc:	97aa                	add	a5,a5,a0
    800061fe:	0187c783          	lbu	a5,24(a5)
    80006202:	ebb9                	bnez	a5,80006258 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006204:	00451693          	slli	a3,a0,0x4
    80006208:	0001c797          	auipc	a5,0x1c
    8000620c:	b3878793          	addi	a5,a5,-1224 # 80021d40 <disk>
    80006210:	6398                	ld	a4,0(a5)
    80006212:	9736                	add	a4,a4,a3
    80006214:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80006218:	6398                	ld	a4,0(a5)
    8000621a:	9736                	add	a4,a4,a3
    8000621c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006220:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006224:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006228:	97aa                	add	a5,a5,a0
    8000622a:	4705                	li	a4,1
    8000622c:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80006230:	0001c517          	auipc	a0,0x1c
    80006234:	b2850513          	addi	a0,a0,-1240 # 80021d58 <disk+0x18>
    80006238:	ffffc097          	auipc	ra,0xffffc
    8000623c:	27e080e7          	jalr	638(ra) # 800024b6 <wakeup>
}
    80006240:	60a2                	ld	ra,8(sp)
    80006242:	6402                	ld	s0,0(sp)
    80006244:	0141                	addi	sp,sp,16
    80006246:	8082                	ret
    panic("free_desc 1");
    80006248:	00002517          	auipc	a0,0x2
    8000624c:	5e050513          	addi	a0,a0,1504 # 80008828 <syscalls+0x308>
    80006250:	ffffa097          	auipc	ra,0xffffa
    80006254:	2ec080e7          	jalr	748(ra) # 8000053c <panic>
    panic("free_desc 2");
    80006258:	00002517          	auipc	a0,0x2
    8000625c:	5e050513          	addi	a0,a0,1504 # 80008838 <syscalls+0x318>
    80006260:	ffffa097          	auipc	ra,0xffffa
    80006264:	2dc080e7          	jalr	732(ra) # 8000053c <panic>

0000000080006268 <virtio_disk_init>:
{
    80006268:	1101                	addi	sp,sp,-32
    8000626a:	ec06                	sd	ra,24(sp)
    8000626c:	e822                	sd	s0,16(sp)
    8000626e:	e426                	sd	s1,8(sp)
    80006270:	e04a                	sd	s2,0(sp)
    80006272:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006274:	00002597          	auipc	a1,0x2
    80006278:	5d458593          	addi	a1,a1,1492 # 80008848 <syscalls+0x328>
    8000627c:	0001c517          	auipc	a0,0x1c
    80006280:	bec50513          	addi	a0,a0,-1044 # 80021e68 <disk+0x128>
    80006284:	ffffb097          	auipc	ra,0xffffb
    80006288:	8be080e7          	jalr	-1858(ra) # 80000b42 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000628c:	100017b7          	lui	a5,0x10001
    80006290:	4398                	lw	a4,0(a5)
    80006292:	2701                	sext.w	a4,a4
    80006294:	747277b7          	lui	a5,0x74727
    80006298:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000629c:	14f71b63          	bne	a4,a5,800063f2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800062a0:	100017b7          	lui	a5,0x10001
    800062a4:	43dc                	lw	a5,4(a5)
    800062a6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800062a8:	4709                	li	a4,2
    800062aa:	14e79463          	bne	a5,a4,800063f2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800062ae:	100017b7          	lui	a5,0x10001
    800062b2:	479c                	lw	a5,8(a5)
    800062b4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800062b6:	12e79e63          	bne	a5,a4,800063f2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800062ba:	100017b7          	lui	a5,0x10001
    800062be:	47d8                	lw	a4,12(a5)
    800062c0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800062c2:	554d47b7          	lui	a5,0x554d4
    800062c6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800062ca:	12f71463          	bne	a4,a5,800063f2 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    800062ce:	100017b7          	lui	a5,0x10001
    800062d2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    800062d6:	4705                	li	a4,1
    800062d8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800062da:	470d                	li	a4,3
    800062dc:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800062de:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800062e0:	c7ffe6b7          	lui	a3,0xc7ffe
    800062e4:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fdc8df>
    800062e8:	8f75                	and	a4,a4,a3
    800062ea:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800062ec:	472d                	li	a4,11
    800062ee:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    800062f0:	5bbc                	lw	a5,112(a5)
    800062f2:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    800062f6:	8ba1                	andi	a5,a5,8
    800062f8:	10078563          	beqz	a5,80006402 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800062fc:	100017b7          	lui	a5,0x10001
    80006300:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006304:	43fc                	lw	a5,68(a5)
    80006306:	2781                	sext.w	a5,a5
    80006308:	10079563          	bnez	a5,80006412 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000630c:	100017b7          	lui	a5,0x10001
    80006310:	5bdc                	lw	a5,52(a5)
    80006312:	2781                	sext.w	a5,a5
  if(max == 0)
    80006314:	10078763          	beqz	a5,80006422 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80006318:	471d                	li	a4,7
    8000631a:	10f77c63          	bgeu	a4,a5,80006432 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    8000631e:	ffffa097          	auipc	ra,0xffffa
    80006322:	7c4080e7          	jalr	1988(ra) # 80000ae2 <kalloc>
    80006326:	0001c497          	auipc	s1,0x1c
    8000632a:	a1a48493          	addi	s1,s1,-1510 # 80021d40 <disk>
    8000632e:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006330:	ffffa097          	auipc	ra,0xffffa
    80006334:	7b2080e7          	jalr	1970(ra) # 80000ae2 <kalloc>
    80006338:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000633a:	ffffa097          	auipc	ra,0xffffa
    8000633e:	7a8080e7          	jalr	1960(ra) # 80000ae2 <kalloc>
    80006342:	87aa                	mv	a5,a0
    80006344:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006346:	6088                	ld	a0,0(s1)
    80006348:	cd6d                	beqz	a0,80006442 <virtio_disk_init+0x1da>
    8000634a:	0001c717          	auipc	a4,0x1c
    8000634e:	9fe73703          	ld	a4,-1538(a4) # 80021d48 <disk+0x8>
    80006352:	cb65                	beqz	a4,80006442 <virtio_disk_init+0x1da>
    80006354:	c7fd                	beqz	a5,80006442 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80006356:	6605                	lui	a2,0x1
    80006358:	4581                	li	a1,0
    8000635a:	ffffb097          	auipc	ra,0xffffb
    8000635e:	974080e7          	jalr	-1676(ra) # 80000cce <memset>
  memset(disk.avail, 0, PGSIZE);
    80006362:	0001c497          	auipc	s1,0x1c
    80006366:	9de48493          	addi	s1,s1,-1570 # 80021d40 <disk>
    8000636a:	6605                	lui	a2,0x1
    8000636c:	4581                	li	a1,0
    8000636e:	6488                	ld	a0,8(s1)
    80006370:	ffffb097          	auipc	ra,0xffffb
    80006374:	95e080e7          	jalr	-1698(ra) # 80000cce <memset>
  memset(disk.used, 0, PGSIZE);
    80006378:	6605                	lui	a2,0x1
    8000637a:	4581                	li	a1,0
    8000637c:	6888                	ld	a0,16(s1)
    8000637e:	ffffb097          	auipc	ra,0xffffb
    80006382:	950080e7          	jalr	-1712(ra) # 80000cce <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006386:	100017b7          	lui	a5,0x10001
    8000638a:	4721                	li	a4,8
    8000638c:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    8000638e:	4098                	lw	a4,0(s1)
    80006390:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006394:	40d8                	lw	a4,4(s1)
    80006396:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000639a:	6498                	ld	a4,8(s1)
    8000639c:	0007069b          	sext.w	a3,a4
    800063a0:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    800063a4:	9701                	srai	a4,a4,0x20
    800063a6:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    800063aa:	6898                	ld	a4,16(s1)
    800063ac:	0007069b          	sext.w	a3,a4
    800063b0:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    800063b4:	9701                	srai	a4,a4,0x20
    800063b6:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    800063ba:	4705                	li	a4,1
    800063bc:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    800063be:	00e48c23          	sb	a4,24(s1)
    800063c2:	00e48ca3          	sb	a4,25(s1)
    800063c6:	00e48d23          	sb	a4,26(s1)
    800063ca:	00e48da3          	sb	a4,27(s1)
    800063ce:	00e48e23          	sb	a4,28(s1)
    800063d2:	00e48ea3          	sb	a4,29(s1)
    800063d6:	00e48f23          	sb	a4,30(s1)
    800063da:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    800063de:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    800063e2:	0727a823          	sw	s2,112(a5)
}
    800063e6:	60e2                	ld	ra,24(sp)
    800063e8:	6442                	ld	s0,16(sp)
    800063ea:	64a2                	ld	s1,8(sp)
    800063ec:	6902                	ld	s2,0(sp)
    800063ee:	6105                	addi	sp,sp,32
    800063f0:	8082                	ret
    panic("could not find virtio disk");
    800063f2:	00002517          	auipc	a0,0x2
    800063f6:	46650513          	addi	a0,a0,1126 # 80008858 <syscalls+0x338>
    800063fa:	ffffa097          	auipc	ra,0xffffa
    800063fe:	142080e7          	jalr	322(ra) # 8000053c <panic>
    panic("virtio disk FEATURES_OK unset");
    80006402:	00002517          	auipc	a0,0x2
    80006406:	47650513          	addi	a0,a0,1142 # 80008878 <syscalls+0x358>
    8000640a:	ffffa097          	auipc	ra,0xffffa
    8000640e:	132080e7          	jalr	306(ra) # 8000053c <panic>
    panic("virtio disk should not be ready");
    80006412:	00002517          	auipc	a0,0x2
    80006416:	48650513          	addi	a0,a0,1158 # 80008898 <syscalls+0x378>
    8000641a:	ffffa097          	auipc	ra,0xffffa
    8000641e:	122080e7          	jalr	290(ra) # 8000053c <panic>
    panic("virtio disk has no queue 0");
    80006422:	00002517          	auipc	a0,0x2
    80006426:	49650513          	addi	a0,a0,1174 # 800088b8 <syscalls+0x398>
    8000642a:	ffffa097          	auipc	ra,0xffffa
    8000642e:	112080e7          	jalr	274(ra) # 8000053c <panic>
    panic("virtio disk max queue too short");
    80006432:	00002517          	auipc	a0,0x2
    80006436:	4a650513          	addi	a0,a0,1190 # 800088d8 <syscalls+0x3b8>
    8000643a:	ffffa097          	auipc	ra,0xffffa
    8000643e:	102080e7          	jalr	258(ra) # 8000053c <panic>
    panic("virtio disk kalloc");
    80006442:	00002517          	auipc	a0,0x2
    80006446:	4b650513          	addi	a0,a0,1206 # 800088f8 <syscalls+0x3d8>
    8000644a:	ffffa097          	auipc	ra,0xffffa
    8000644e:	0f2080e7          	jalr	242(ra) # 8000053c <panic>

0000000080006452 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006452:	7159                	addi	sp,sp,-112
    80006454:	f486                	sd	ra,104(sp)
    80006456:	f0a2                	sd	s0,96(sp)
    80006458:	eca6                	sd	s1,88(sp)
    8000645a:	e8ca                	sd	s2,80(sp)
    8000645c:	e4ce                	sd	s3,72(sp)
    8000645e:	e0d2                	sd	s4,64(sp)
    80006460:	fc56                	sd	s5,56(sp)
    80006462:	f85a                	sd	s6,48(sp)
    80006464:	f45e                	sd	s7,40(sp)
    80006466:	f062                	sd	s8,32(sp)
    80006468:	ec66                	sd	s9,24(sp)
    8000646a:	e86a                	sd	s10,16(sp)
    8000646c:	1880                	addi	s0,sp,112
    8000646e:	8a2a                	mv	s4,a0
    80006470:	8bae                	mv	s7,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006472:	00c52c83          	lw	s9,12(a0)
    80006476:	001c9c9b          	slliw	s9,s9,0x1
    8000647a:	1c82                	slli	s9,s9,0x20
    8000647c:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006480:	0001c517          	auipc	a0,0x1c
    80006484:	9e850513          	addi	a0,a0,-1560 # 80021e68 <disk+0x128>
    80006488:	ffffa097          	auipc	ra,0xffffa
    8000648c:	74a080e7          	jalr	1866(ra) # 80000bd2 <acquire>
  for(int i = 0; i < 3; i++){
    80006490:	4901                	li	s2,0
  for(int i = 0; i < NUM; i++){
    80006492:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006494:	0001cb17          	auipc	s6,0x1c
    80006498:	8acb0b13          	addi	s6,s6,-1876 # 80021d40 <disk>
  for(int i = 0; i < 3; i++){
    8000649c:	4a8d                	li	s5,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000649e:	0001cc17          	auipc	s8,0x1c
    800064a2:	9cac0c13          	addi	s8,s8,-1590 # 80021e68 <disk+0x128>
    800064a6:	a095                	j	8000650a <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    800064a8:	00fb0733          	add	a4,s6,a5
    800064ac:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800064b0:	c11c                	sw	a5,0(a0)
    if(idx[i] < 0){
    800064b2:	0207c563          	bltz	a5,800064dc <virtio_disk_rw+0x8a>
  for(int i = 0; i < 3; i++){
    800064b6:	2605                	addiw	a2,a2,1 # 1001 <_entry-0x7fffefff>
    800064b8:	0591                	addi	a1,a1,4
    800064ba:	05560d63          	beq	a2,s5,80006514 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    800064be:	852e                	mv	a0,a1
  for(int i = 0; i < NUM; i++){
    800064c0:	0001c717          	auipc	a4,0x1c
    800064c4:	88070713          	addi	a4,a4,-1920 # 80021d40 <disk>
    800064c8:	87ca                	mv	a5,s2
    if(disk.free[i]){
    800064ca:	01874683          	lbu	a3,24(a4)
    800064ce:	fee9                	bnez	a3,800064a8 <virtio_disk_rw+0x56>
  for(int i = 0; i < NUM; i++){
    800064d0:	2785                	addiw	a5,a5,1
    800064d2:	0705                	addi	a4,a4,1
    800064d4:	fe979be3          	bne	a5,s1,800064ca <virtio_disk_rw+0x78>
    idx[i] = alloc_desc();
    800064d8:	57fd                	li	a5,-1
    800064da:	c11c                	sw	a5,0(a0)
      for(int j = 0; j < i; j++)
    800064dc:	00c05e63          	blez	a2,800064f8 <virtio_disk_rw+0xa6>
    800064e0:	060a                	slli	a2,a2,0x2
    800064e2:	01360d33          	add	s10,a2,s3
        free_desc(idx[j]);
    800064e6:	0009a503          	lw	a0,0(s3)
    800064ea:	00000097          	auipc	ra,0x0
    800064ee:	cfc080e7          	jalr	-772(ra) # 800061e6 <free_desc>
      for(int j = 0; j < i; j++)
    800064f2:	0991                	addi	s3,s3,4
    800064f4:	ffa999e3          	bne	s3,s10,800064e6 <virtio_disk_rw+0x94>
    sleep(&disk.free[0], &disk.vdisk_lock);
    800064f8:	85e2                	mv	a1,s8
    800064fa:	0001c517          	auipc	a0,0x1c
    800064fe:	85e50513          	addi	a0,a0,-1954 # 80021d58 <disk+0x18>
    80006502:	ffffc097          	auipc	ra,0xffffc
    80006506:	f50080e7          	jalr	-176(ra) # 80002452 <sleep>
  for(int i = 0; i < 3; i++){
    8000650a:	f9040993          	addi	s3,s0,-112
{
    8000650e:	85ce                	mv	a1,s3
  for(int i = 0; i < 3; i++){
    80006510:	864a                	mv	a2,s2
    80006512:	b775                	j	800064be <virtio_disk_rw+0x6c>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006514:	f9042503          	lw	a0,-112(s0)
    80006518:	00a50713          	addi	a4,a0,10
    8000651c:	0712                	slli	a4,a4,0x4

  if(write)
    8000651e:	0001c797          	auipc	a5,0x1c
    80006522:	82278793          	addi	a5,a5,-2014 # 80021d40 <disk>
    80006526:	00e786b3          	add	a3,a5,a4
    8000652a:	01703633          	snez	a2,s7
    8000652e:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006530:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80006534:	0196b823          	sd	s9,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006538:	f6070613          	addi	a2,a4,-160
    8000653c:	6394                	ld	a3,0(a5)
    8000653e:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006540:	00870593          	addi	a1,a4,8
    80006544:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006546:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006548:	0007b803          	ld	a6,0(a5)
    8000654c:	9642                	add	a2,a2,a6
    8000654e:	46c1                	li	a3,16
    80006550:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006552:	4585                	li	a1,1
    80006554:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    80006558:	f9442683          	lw	a3,-108(s0)
    8000655c:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006560:	0692                	slli	a3,a3,0x4
    80006562:	9836                	add	a6,a6,a3
    80006564:	058a0613          	addi	a2,s4,88
    80006568:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    8000656c:	0007b803          	ld	a6,0(a5)
    80006570:	96c2                	add	a3,a3,a6
    80006572:	40000613          	li	a2,1024
    80006576:	c690                	sw	a2,8(a3)
  if(write)
    80006578:	001bb613          	seqz	a2,s7
    8000657c:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006580:	00166613          	ori	a2,a2,1
    80006584:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006588:	f9842603          	lw	a2,-104(s0)
    8000658c:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006590:	00250693          	addi	a3,a0,2
    80006594:	0692                	slli	a3,a3,0x4
    80006596:	96be                	add	a3,a3,a5
    80006598:	58fd                	li	a7,-1
    8000659a:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000659e:	0612                	slli	a2,a2,0x4
    800065a0:	9832                	add	a6,a6,a2
    800065a2:	f9070713          	addi	a4,a4,-112
    800065a6:	973e                	add	a4,a4,a5
    800065a8:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    800065ac:	6398                	ld	a4,0(a5)
    800065ae:	9732                	add	a4,a4,a2
    800065b0:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800065b2:	4609                	li	a2,2
    800065b4:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    800065b8:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800065bc:	00ba2223          	sw	a1,4(s4)
  disk.info[idx[0]].b = b;
    800065c0:	0146b423          	sd	s4,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800065c4:	6794                	ld	a3,8(a5)
    800065c6:	0026d703          	lhu	a4,2(a3)
    800065ca:	8b1d                	andi	a4,a4,7
    800065cc:	0706                	slli	a4,a4,0x1
    800065ce:	96ba                	add	a3,a3,a4
    800065d0:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    800065d4:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800065d8:	6798                	ld	a4,8(a5)
    800065da:	00275783          	lhu	a5,2(a4)
    800065de:	2785                	addiw	a5,a5,1
    800065e0:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800065e4:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800065e8:	100017b7          	lui	a5,0x10001
    800065ec:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800065f0:	004a2783          	lw	a5,4(s4)
    sleep(b, &disk.vdisk_lock);
    800065f4:	0001c917          	auipc	s2,0x1c
    800065f8:	87490913          	addi	s2,s2,-1932 # 80021e68 <disk+0x128>
  while(b->disk == 1) {
    800065fc:	4485                	li	s1,1
    800065fe:	00b79c63          	bne	a5,a1,80006616 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006602:	85ca                	mv	a1,s2
    80006604:	8552                	mv	a0,s4
    80006606:	ffffc097          	auipc	ra,0xffffc
    8000660a:	e4c080e7          	jalr	-436(ra) # 80002452 <sleep>
  while(b->disk == 1) {
    8000660e:	004a2783          	lw	a5,4(s4)
    80006612:	fe9788e3          	beq	a5,s1,80006602 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006616:	f9042903          	lw	s2,-112(s0)
    8000661a:	00290713          	addi	a4,s2,2
    8000661e:	0712                	slli	a4,a4,0x4
    80006620:	0001b797          	auipc	a5,0x1b
    80006624:	72078793          	addi	a5,a5,1824 # 80021d40 <disk>
    80006628:	97ba                	add	a5,a5,a4
    8000662a:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000662e:	0001b997          	auipc	s3,0x1b
    80006632:	71298993          	addi	s3,s3,1810 # 80021d40 <disk>
    80006636:	00491713          	slli	a4,s2,0x4
    8000663a:	0009b783          	ld	a5,0(s3)
    8000663e:	97ba                	add	a5,a5,a4
    80006640:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006644:	854a                	mv	a0,s2
    80006646:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000664a:	00000097          	auipc	ra,0x0
    8000664e:	b9c080e7          	jalr	-1124(ra) # 800061e6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006652:	8885                	andi	s1,s1,1
    80006654:	f0ed                	bnez	s1,80006636 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006656:	0001c517          	auipc	a0,0x1c
    8000665a:	81250513          	addi	a0,a0,-2030 # 80021e68 <disk+0x128>
    8000665e:	ffffa097          	auipc	ra,0xffffa
    80006662:	628080e7          	jalr	1576(ra) # 80000c86 <release>
}
    80006666:	70a6                	ld	ra,104(sp)
    80006668:	7406                	ld	s0,96(sp)
    8000666a:	64e6                	ld	s1,88(sp)
    8000666c:	6946                	ld	s2,80(sp)
    8000666e:	69a6                	ld	s3,72(sp)
    80006670:	6a06                	ld	s4,64(sp)
    80006672:	7ae2                	ld	s5,56(sp)
    80006674:	7b42                	ld	s6,48(sp)
    80006676:	7ba2                	ld	s7,40(sp)
    80006678:	7c02                	ld	s8,32(sp)
    8000667a:	6ce2                	ld	s9,24(sp)
    8000667c:	6d42                	ld	s10,16(sp)
    8000667e:	6165                	addi	sp,sp,112
    80006680:	8082                	ret

0000000080006682 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006682:	1101                	addi	sp,sp,-32
    80006684:	ec06                	sd	ra,24(sp)
    80006686:	e822                	sd	s0,16(sp)
    80006688:	e426                	sd	s1,8(sp)
    8000668a:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000668c:	0001b497          	auipc	s1,0x1b
    80006690:	6b448493          	addi	s1,s1,1716 # 80021d40 <disk>
    80006694:	0001b517          	auipc	a0,0x1b
    80006698:	7d450513          	addi	a0,a0,2004 # 80021e68 <disk+0x128>
    8000669c:	ffffa097          	auipc	ra,0xffffa
    800066a0:	536080e7          	jalr	1334(ra) # 80000bd2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800066a4:	10001737          	lui	a4,0x10001
    800066a8:	533c                	lw	a5,96(a4)
    800066aa:	8b8d                	andi	a5,a5,3
    800066ac:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800066ae:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800066b2:	689c                	ld	a5,16(s1)
    800066b4:	0204d703          	lhu	a4,32(s1)
    800066b8:	0027d783          	lhu	a5,2(a5)
    800066bc:	04f70863          	beq	a4,a5,8000670c <virtio_disk_intr+0x8a>
    __sync_synchronize();
    800066c0:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800066c4:	6898                	ld	a4,16(s1)
    800066c6:	0204d783          	lhu	a5,32(s1)
    800066ca:	8b9d                	andi	a5,a5,7
    800066cc:	078e                	slli	a5,a5,0x3
    800066ce:	97ba                	add	a5,a5,a4
    800066d0:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800066d2:	00278713          	addi	a4,a5,2
    800066d6:	0712                	slli	a4,a4,0x4
    800066d8:	9726                	add	a4,a4,s1
    800066da:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    800066de:	e721                	bnez	a4,80006726 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800066e0:	0789                	addi	a5,a5,2
    800066e2:	0792                	slli	a5,a5,0x4
    800066e4:	97a6                	add	a5,a5,s1
    800066e6:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    800066e8:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800066ec:	ffffc097          	auipc	ra,0xffffc
    800066f0:	dca080e7          	jalr	-566(ra) # 800024b6 <wakeup>

    disk.used_idx += 1;
    800066f4:	0204d783          	lhu	a5,32(s1)
    800066f8:	2785                	addiw	a5,a5,1
    800066fa:	17c2                	slli	a5,a5,0x30
    800066fc:	93c1                	srli	a5,a5,0x30
    800066fe:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006702:	6898                	ld	a4,16(s1)
    80006704:	00275703          	lhu	a4,2(a4)
    80006708:	faf71ce3          	bne	a4,a5,800066c0 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    8000670c:	0001b517          	auipc	a0,0x1b
    80006710:	75c50513          	addi	a0,a0,1884 # 80021e68 <disk+0x128>
    80006714:	ffffa097          	auipc	ra,0xffffa
    80006718:	572080e7          	jalr	1394(ra) # 80000c86 <release>
}
    8000671c:	60e2                	ld	ra,24(sp)
    8000671e:	6442                	ld	s0,16(sp)
    80006720:	64a2                	ld	s1,8(sp)
    80006722:	6105                	addi	sp,sp,32
    80006724:	8082                	ret
      panic("virtio_disk_intr status");
    80006726:	00002517          	auipc	a0,0x2
    8000672a:	1ea50513          	addi	a0,a0,490 # 80008910 <syscalls+0x3f0>
    8000672e:	ffffa097          	auipc	ra,0xffffa
    80006732:	e0e080e7          	jalr	-498(ra) # 8000053c <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0)
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0)
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
