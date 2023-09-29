
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	bc010113          	addi	sp,sp,-1088 # 80008bc0 <stack0>
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
    80000054:	a3070713          	addi	a4,a4,-1488 # 80008a80 <timer_scratch>
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
    80000066:	0ee78793          	addi	a5,a5,238 # 80006150 <timervec>
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
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffbc90f>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	f0e78793          	addi	a5,a5,-242 # 80000fba <main>
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
    8000012e:	688080e7          	jalr	1672(ra) # 800027b2 <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
            break;
        uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	792080e7          	jalr	1938(ra) # 800008cc <uartputc>
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
    80000188:	a3c50513          	addi	a0,a0,-1476 # 80010bc0 <cons>
    8000018c:	00001097          	auipc	ra,0x1
    80000190:	b8e080e7          	jalr	-1138(ra) # 80000d1a <acquire>
    while (n > 0)
    {
        // wait until interrupt handler has put some
        // input into cons.buffer.
        while (cons.r == cons.w)
    80000194:	00011497          	auipc	s1,0x11
    80000198:	a2c48493          	addi	s1,s1,-1492 # 80010bc0 <cons>
            if (killed(myproc()))
            {
                release(&cons.lock);
                return -1;
            }
            sleep(&cons.r, &cons.lock);
    8000019c:	00011917          	auipc	s2,0x11
    800001a0:	abc90913          	addi	s2,s2,-1348 # 80010c58 <cons+0x98>
    while (n > 0)
    800001a4:	09305263          	blez	s3,80000228 <consoleread+0xc4>
        while (cons.r == cons.w)
    800001a8:	0984a783          	lw	a5,152(s1)
    800001ac:	09c4a703          	lw	a4,156(s1)
    800001b0:	02f71763          	bne	a4,a5,800001de <consoleread+0x7a>
            if (killed(myproc()))
    800001b4:	00002097          	auipc	ra,0x2
    800001b8:	a38080e7          	jalr	-1480(ra) # 80001bec <myproc>
    800001bc:	00002097          	auipc	ra,0x2
    800001c0:	440080e7          	jalr	1088(ra) # 800025fc <killed>
    800001c4:	ed2d                	bnez	a0,8000023e <consoleread+0xda>
            sleep(&cons.r, &cons.lock);
    800001c6:	85a6                	mv	a1,s1
    800001c8:	854a                	mv	a0,s2
    800001ca:	00002097          	auipc	ra,0x2
    800001ce:	18a080e7          	jalr	394(ra) # 80002354 <sleep>
        while (cons.r == cons.w)
    800001d2:	0984a783          	lw	a5,152(s1)
    800001d6:	09c4a703          	lw	a4,156(s1)
    800001da:	fcf70de3          	beq	a4,a5,800001b4 <consoleread+0x50>
        }

        c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001de:	00011717          	auipc	a4,0x11
    800001e2:	9e270713          	addi	a4,a4,-1566 # 80010bc0 <cons>
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
    80000214:	54c080e7          	jalr	1356(ra) # 8000275c <either_copyout>
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
    8000022c:	99850513          	addi	a0,a0,-1640 # 80010bc0 <cons>
    80000230:	00001097          	auipc	ra,0x1
    80000234:	b9e080e7          	jalr	-1122(ra) # 80000dce <release>

    return target - n;
    80000238:	413b053b          	subw	a0,s6,s3
    8000023c:	a811                	j	80000250 <consoleread+0xec>
                release(&cons.lock);
    8000023e:	00011517          	auipc	a0,0x11
    80000242:	98250513          	addi	a0,a0,-1662 # 80010bc0 <cons>
    80000246:	00001097          	auipc	ra,0x1
    8000024a:	b88080e7          	jalr	-1144(ra) # 80000dce <release>
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
    80000272:	9ef72523          	sw	a5,-1558(a4) # 80010c58 <cons+0x98>
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
    8000028c:	572080e7          	jalr	1394(ra) # 800007fa <uartputc_sync>
}
    80000290:	60a2                	ld	ra,8(sp)
    80000292:	6402                	ld	s0,0(sp)
    80000294:	0141                	addi	sp,sp,16
    80000296:	8082                	ret
        uartputc_sync('\b');
    80000298:	4521                	li	a0,8
    8000029a:	00000097          	auipc	ra,0x0
    8000029e:	560080e7          	jalr	1376(ra) # 800007fa <uartputc_sync>
        uartputc_sync(' ');
    800002a2:	02000513          	li	a0,32
    800002a6:	00000097          	auipc	ra,0x0
    800002aa:	554080e7          	jalr	1364(ra) # 800007fa <uartputc_sync>
        uartputc_sync('\b');
    800002ae:	4521                	li	a0,8
    800002b0:	00000097          	auipc	ra,0x0
    800002b4:	54a080e7          	jalr	1354(ra) # 800007fa <uartputc_sync>
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
    800002cc:	8f850513          	addi	a0,a0,-1800 # 80010bc0 <cons>
    800002d0:	00001097          	auipc	ra,0x1
    800002d4:	a4a080e7          	jalr	-1462(ra) # 80000d1a <acquire>

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
    800002f2:	51a080e7          	jalr	1306(ra) # 80002808 <procdump>
            }
        }
        break;
    }

    release(&cons.lock);
    800002f6:	00011517          	auipc	a0,0x11
    800002fa:	8ca50513          	addi	a0,a0,-1846 # 80010bc0 <cons>
    800002fe:	00001097          	auipc	ra,0x1
    80000302:	ad0080e7          	jalr	-1328(ra) # 80000dce <release>
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
    8000031e:	8a670713          	addi	a4,a4,-1882 # 80010bc0 <cons>
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
    80000348:	87c78793          	addi	a5,a5,-1924 # 80010bc0 <cons>
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
    80000376:	8e67a783          	lw	a5,-1818(a5) # 80010c58 <cons+0x98>
    8000037a:	9f1d                	subw	a4,a4,a5
    8000037c:	08000793          	li	a5,128
    80000380:	f6f71be3          	bne	a4,a5,800002f6 <consoleintr+0x3c>
    80000384:	a07d                	j	80000432 <consoleintr+0x178>
        while (cons.e != cons.w &&
    80000386:	00011717          	auipc	a4,0x11
    8000038a:	83a70713          	addi	a4,a4,-1990 # 80010bc0 <cons>
    8000038e:	0a072783          	lw	a5,160(a4)
    80000392:	09c72703          	lw	a4,156(a4)
               cons.buf[(cons.e - 1) % INPUT_BUF_SIZE] != '\n')
    80000396:	00011497          	auipc	s1,0x11
    8000039a:	82a48493          	addi	s1,s1,-2006 # 80010bc0 <cons>
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
    800003d6:	7ee70713          	addi	a4,a4,2030 # 80010bc0 <cons>
    800003da:	0a072783          	lw	a5,160(a4)
    800003de:	09c72703          	lw	a4,156(a4)
    800003e2:	f0f70ae3          	beq	a4,a5,800002f6 <consoleintr+0x3c>
            cons.e--;
    800003e6:	37fd                	addiw	a5,a5,-1
    800003e8:	00011717          	auipc	a4,0x11
    800003ec:	86f72c23          	sw	a5,-1928(a4) # 80010c60 <cons+0xa0>
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
    80000412:	7b278793          	addi	a5,a5,1970 # 80010bc0 <cons>
    80000416:	0a07a703          	lw	a4,160(a5)
    8000041a:	0017069b          	addiw	a3,a4,1
    8000041e:	0006861b          	sext.w	a2,a3
    80000422:	0ad7a023          	sw	a3,160(a5)
    80000426:	07f77713          	andi	a4,a4,127
    8000042a:	97ba                	add	a5,a5,a4
    8000042c:	4729                	li	a4,10
    8000042e:	00e78c23          	sb	a4,24(a5)
                cons.w = cons.e;
    80000432:	00011797          	auipc	a5,0x11
    80000436:	82c7a523          	sw	a2,-2006(a5) # 80010c5c <cons+0x9c>
                wakeup(&cons.r);
    8000043a:	00011517          	auipc	a0,0x11
    8000043e:	81e50513          	addi	a0,a0,-2018 # 80010c58 <cons+0x98>
    80000442:	00002097          	auipc	ra,0x2
    80000446:	f76080e7          	jalr	-138(ra) # 800023b8 <wakeup>
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
    80000458:	bcc58593          	addi	a1,a1,-1076 # 80008020 <__func__.1+0x18>
    8000045c:	00010517          	auipc	a0,0x10
    80000460:	76450513          	addi	a0,a0,1892 # 80010bc0 <cons>
    80000464:	00001097          	auipc	ra,0x1
    80000468:	826080e7          	jalr	-2010(ra) # 80000c8a <initlock>

    uartinit();
    8000046c:	00000097          	auipc	ra,0x0
    80000470:	33e080e7          	jalr	830(ra) # 800007aa <uartinit>

    // connect read and write system calls
    // to consoleread and consolewrite.
    devsw[CONSOLE].read = consoleread;
    80000474:	00041797          	auipc	a5,0x41
    80000478:	8e478793          	addi	a5,a5,-1820 # 80040d58 <devsw>
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

    if (sign && (sign = xx < 0))
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
    do
    {
        buf[i++] = digits[x % base];
    800004b4:	2581                	sext.w	a1,a1
    800004b6:	00008617          	auipc	a2,0x8
    800004ba:	b9a60613          	addi	a2,a2,-1126 # 80008050 <digits>
    800004be:	883a                	mv	a6,a4
    800004c0:	2705                	addiw	a4,a4,1
    800004c2:	02b577bb          	remuw	a5,a0,a1
    800004c6:	1782                	slli	a5,a5,0x20
    800004c8:	9381                	srli	a5,a5,0x20
    800004ca:	97b2                	add	a5,a5,a2
    800004cc:	0007c783          	lbu	a5,0(a5)
    800004d0:	00f68023          	sb	a5,0(a3)
    } while ((x /= base) != 0);
    800004d4:	0005079b          	sext.w	a5,a0
    800004d8:	02b5553b          	divuw	a0,a0,a1
    800004dc:	0685                	addi	a3,a3,1
    800004de:	feb7f0e3          	bgeu	a5,a1,800004be <printint+0x26>

    if (sign)
    800004e2:	00088c63          	beqz	a7,800004fa <printint+0x62>
        buf[i++] = '-';
    800004e6:	fe070793          	addi	a5,a4,-32
    800004ea:	00878733          	add	a4,a5,s0
    800004ee:	02d00793          	li	a5,45
    800004f2:	fef70823          	sb	a5,-16(a4)
    800004f6:	0028071b          	addiw	a4,a6,2

    while (--i >= 0)
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
    while (--i >= 0)
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
    if (sign && (sign = xx < 0))
    80000538:	4885                	li	a7,1
        x = -xx;
    8000053a:	bf95                	j	800004ae <printint+0x16>

000000008000053c <panic>:
    if (locking)
        release(&pr.lock);
}

void panic(char *s, ...)
{
    8000053c:	711d                	addi	sp,sp,-96
    8000053e:	ec06                	sd	ra,24(sp)
    80000540:	e822                	sd	s0,16(sp)
    80000542:	e426                	sd	s1,8(sp)
    80000544:	1000                	addi	s0,sp,32
    80000546:	84aa                	mv	s1,a0
    80000548:	e40c                	sd	a1,8(s0)
    8000054a:	e810                	sd	a2,16(s0)
    8000054c:	ec14                	sd	a3,24(s0)
    8000054e:	f018                	sd	a4,32(s0)
    80000550:	f41c                	sd	a5,40(s0)
    80000552:	03043823          	sd	a6,48(s0)
    80000556:	03143c23          	sd	a7,56(s0)
    pr.locking = 0;
    8000055a:	00010797          	auipc	a5,0x10
    8000055e:	7207a323          	sw	zero,1830(a5) # 80010c80 <pr+0x18>
    printf("panic: ");
    80000562:	00008517          	auipc	a0,0x8
    80000566:	ac650513          	addi	a0,a0,-1338 # 80008028 <__func__.1+0x20>
    8000056a:	00000097          	auipc	ra,0x0
    8000056e:	02e080e7          	jalr	46(ra) # 80000598 <printf>
    printf(s);
    80000572:	8526                	mv	a0,s1
    80000574:	00000097          	auipc	ra,0x0
    80000578:	024080e7          	jalr	36(ra) # 80000598 <printf>
    printf("\n");
    8000057c:	00008517          	auipc	a0,0x8
    80000580:	b0c50513          	addi	a0,a0,-1268 # 80008088 <digits+0x38>
    80000584:	00000097          	auipc	ra,0x0
    80000588:	014080e7          	jalr	20(ra) # 80000598 <printf>
    panicked = 1; // freeze uart output from other CPUs
    8000058c:	4785                	li	a5,1
    8000058e:	00008717          	auipc	a4,0x8
    80000592:	4af72123          	sw	a5,1186(a4) # 80008a30 <panicked>
    for (;;)
    80000596:	a001                	j	80000596 <panic+0x5a>

0000000080000598 <printf>:
{
    80000598:	7131                	addi	sp,sp,-192
    8000059a:	fc86                	sd	ra,120(sp)
    8000059c:	f8a2                	sd	s0,112(sp)
    8000059e:	f4a6                	sd	s1,104(sp)
    800005a0:	f0ca                	sd	s2,96(sp)
    800005a2:	ecce                	sd	s3,88(sp)
    800005a4:	e8d2                	sd	s4,80(sp)
    800005a6:	e4d6                	sd	s5,72(sp)
    800005a8:	e0da                	sd	s6,64(sp)
    800005aa:	fc5e                	sd	s7,56(sp)
    800005ac:	f862                	sd	s8,48(sp)
    800005ae:	f466                	sd	s9,40(sp)
    800005b0:	f06a                	sd	s10,32(sp)
    800005b2:	ec6e                	sd	s11,24(sp)
    800005b4:	0100                	addi	s0,sp,128
    800005b6:	8a2a                	mv	s4,a0
    800005b8:	e40c                	sd	a1,8(s0)
    800005ba:	e810                	sd	a2,16(s0)
    800005bc:	ec14                	sd	a3,24(s0)
    800005be:	f018                	sd	a4,32(s0)
    800005c0:	f41c                	sd	a5,40(s0)
    800005c2:	03043823          	sd	a6,48(s0)
    800005c6:	03143c23          	sd	a7,56(s0)
    locking = pr.locking;
    800005ca:	00010d97          	auipc	s11,0x10
    800005ce:	6b6dad83          	lw	s11,1718(s11) # 80010c80 <pr+0x18>
    if (locking)
    800005d2:	020d9b63          	bnez	s11,80000608 <printf+0x70>
    if (fmt == 0)
    800005d6:	040a0263          	beqz	s4,8000061a <printf+0x82>
    va_start(ap, fmt);
    800005da:	00840793          	addi	a5,s0,8
    800005de:	f8f43423          	sd	a5,-120(s0)
    for (i = 0; (c = fmt[i] & 0xff) != 0; i++)
    800005e2:	000a4503          	lbu	a0,0(s4)
    800005e6:	14050f63          	beqz	a0,80000744 <printf+0x1ac>
    800005ea:	4981                	li	s3,0
        if (c != '%')
    800005ec:	02500a93          	li	s5,37
        switch (c)
    800005f0:	07000b93          	li	s7,112
    consputc('x');
    800005f4:	4d41                	li	s10,16
        consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005f6:	00008b17          	auipc	s6,0x8
    800005fa:	a5ab0b13          	addi	s6,s6,-1446 # 80008050 <digits>
        switch (c)
    800005fe:	07300c93          	li	s9,115
    80000602:	06400c13          	li	s8,100
    80000606:	a82d                	j	80000640 <printf+0xa8>
        acquire(&pr.lock);
    80000608:	00010517          	auipc	a0,0x10
    8000060c:	66050513          	addi	a0,a0,1632 # 80010c68 <pr>
    80000610:	00000097          	auipc	ra,0x0
    80000614:	70a080e7          	jalr	1802(ra) # 80000d1a <acquire>
    80000618:	bf7d                	j	800005d6 <printf+0x3e>
        panic("null fmt");
    8000061a:	00008517          	auipc	a0,0x8
    8000061e:	a1e50513          	addi	a0,a0,-1506 # 80008038 <__func__.1+0x30>
    80000622:	00000097          	auipc	ra,0x0
    80000626:	f1a080e7          	jalr	-230(ra) # 8000053c <panic>
            consputc(c);
    8000062a:	00000097          	auipc	ra,0x0
    8000062e:	c4e080e7          	jalr	-946(ra) # 80000278 <consputc>
    for (i = 0; (c = fmt[i] & 0xff) != 0; i++)
    80000632:	2985                	addiw	s3,s3,1
    80000634:	013a07b3          	add	a5,s4,s3
    80000638:	0007c503          	lbu	a0,0(a5)
    8000063c:	10050463          	beqz	a0,80000744 <printf+0x1ac>
        if (c != '%')
    80000640:	ff5515e3          	bne	a0,s5,8000062a <printf+0x92>
        c = fmt[++i] & 0xff;
    80000644:	2985                	addiw	s3,s3,1
    80000646:	013a07b3          	add	a5,s4,s3
    8000064a:	0007c783          	lbu	a5,0(a5)
    8000064e:	0007849b          	sext.w	s1,a5
        if (c == 0)
    80000652:	cbed                	beqz	a5,80000744 <printf+0x1ac>
        switch (c)
    80000654:	05778a63          	beq	a5,s7,800006a8 <printf+0x110>
    80000658:	02fbf663          	bgeu	s7,a5,80000684 <printf+0xec>
    8000065c:	09978863          	beq	a5,s9,800006ec <printf+0x154>
    80000660:	07800713          	li	a4,120
    80000664:	0ce79563          	bne	a5,a4,8000072e <printf+0x196>
            printint(va_arg(ap, int), 16, 1);
    80000668:	f8843783          	ld	a5,-120(s0)
    8000066c:	00878713          	addi	a4,a5,8
    80000670:	f8e43423          	sd	a4,-120(s0)
    80000674:	4605                	li	a2,1
    80000676:	85ea                	mv	a1,s10
    80000678:	4388                	lw	a0,0(a5)
    8000067a:	00000097          	auipc	ra,0x0
    8000067e:	e1e080e7          	jalr	-482(ra) # 80000498 <printint>
            break;
    80000682:	bf45                	j	80000632 <printf+0x9a>
        switch (c)
    80000684:	09578f63          	beq	a5,s5,80000722 <printf+0x18a>
    80000688:	0b879363          	bne	a5,s8,8000072e <printf+0x196>
            printint(va_arg(ap, int), 10, 1);
    8000068c:	f8843783          	ld	a5,-120(s0)
    80000690:	00878713          	addi	a4,a5,8
    80000694:	f8e43423          	sd	a4,-120(s0)
    80000698:	4605                	li	a2,1
    8000069a:	45a9                	li	a1,10
    8000069c:	4388                	lw	a0,0(a5)
    8000069e:	00000097          	auipc	ra,0x0
    800006a2:	dfa080e7          	jalr	-518(ra) # 80000498 <printint>
            break;
    800006a6:	b771                	j	80000632 <printf+0x9a>
            printptr(va_arg(ap, uint64));
    800006a8:	f8843783          	ld	a5,-120(s0)
    800006ac:	00878713          	addi	a4,a5,8
    800006b0:	f8e43423          	sd	a4,-120(s0)
    800006b4:	0007b903          	ld	s2,0(a5)
    consputc('0');
    800006b8:	03000513          	li	a0,48
    800006bc:	00000097          	auipc	ra,0x0
    800006c0:	bbc080e7          	jalr	-1092(ra) # 80000278 <consputc>
    consputc('x');
    800006c4:	07800513          	li	a0,120
    800006c8:	00000097          	auipc	ra,0x0
    800006cc:	bb0080e7          	jalr	-1104(ra) # 80000278 <consputc>
    800006d0:	84ea                	mv	s1,s10
        consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006d2:	03c95793          	srli	a5,s2,0x3c
    800006d6:	97da                	add	a5,a5,s6
    800006d8:	0007c503          	lbu	a0,0(a5)
    800006dc:	00000097          	auipc	ra,0x0
    800006e0:	b9c080e7          	jalr	-1124(ra) # 80000278 <consputc>
    for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006e4:	0912                	slli	s2,s2,0x4
    800006e6:	34fd                	addiw	s1,s1,-1
    800006e8:	f4ed                	bnez	s1,800006d2 <printf+0x13a>
    800006ea:	b7a1                	j	80000632 <printf+0x9a>
            if ((s = va_arg(ap, char *)) == 0)
    800006ec:	f8843783          	ld	a5,-120(s0)
    800006f0:	00878713          	addi	a4,a5,8
    800006f4:	f8e43423          	sd	a4,-120(s0)
    800006f8:	6384                	ld	s1,0(a5)
    800006fa:	cc89                	beqz	s1,80000714 <printf+0x17c>
            for (; *s; s++)
    800006fc:	0004c503          	lbu	a0,0(s1)
    80000700:	d90d                	beqz	a0,80000632 <printf+0x9a>
                consputc(*s);
    80000702:	00000097          	auipc	ra,0x0
    80000706:	b76080e7          	jalr	-1162(ra) # 80000278 <consputc>
            for (; *s; s++)
    8000070a:	0485                	addi	s1,s1,1
    8000070c:	0004c503          	lbu	a0,0(s1)
    80000710:	f96d                	bnez	a0,80000702 <printf+0x16a>
    80000712:	b705                	j	80000632 <printf+0x9a>
                s = "(null)";
    80000714:	00008497          	auipc	s1,0x8
    80000718:	91c48493          	addi	s1,s1,-1764 # 80008030 <__func__.1+0x28>
            for (; *s; s++)
    8000071c:	02800513          	li	a0,40
    80000720:	b7cd                	j	80000702 <printf+0x16a>
            consputc('%');
    80000722:	8556                	mv	a0,s5
    80000724:	00000097          	auipc	ra,0x0
    80000728:	b54080e7          	jalr	-1196(ra) # 80000278 <consputc>
            break;
    8000072c:	b719                	j	80000632 <printf+0x9a>
            consputc('%');
    8000072e:	8556                	mv	a0,s5
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b48080e7          	jalr	-1208(ra) # 80000278 <consputc>
            consputc(c);
    80000738:	8526                	mv	a0,s1
    8000073a:	00000097          	auipc	ra,0x0
    8000073e:	b3e080e7          	jalr	-1218(ra) # 80000278 <consputc>
            break;
    80000742:	bdc5                	j	80000632 <printf+0x9a>
    if (locking)
    80000744:	020d9163          	bnez	s11,80000766 <printf+0x1ce>
}
    80000748:	70e6                	ld	ra,120(sp)
    8000074a:	7446                	ld	s0,112(sp)
    8000074c:	74a6                	ld	s1,104(sp)
    8000074e:	7906                	ld	s2,96(sp)
    80000750:	69e6                	ld	s3,88(sp)
    80000752:	6a46                	ld	s4,80(sp)
    80000754:	6aa6                	ld	s5,72(sp)
    80000756:	6b06                	ld	s6,64(sp)
    80000758:	7be2                	ld	s7,56(sp)
    8000075a:	7c42                	ld	s8,48(sp)
    8000075c:	7ca2                	ld	s9,40(sp)
    8000075e:	7d02                	ld	s10,32(sp)
    80000760:	6de2                	ld	s11,24(sp)
    80000762:	6129                	addi	sp,sp,192
    80000764:	8082                	ret
        release(&pr.lock);
    80000766:	00010517          	auipc	a0,0x10
    8000076a:	50250513          	addi	a0,a0,1282 # 80010c68 <pr>
    8000076e:	00000097          	auipc	ra,0x0
    80000772:	660080e7          	jalr	1632(ra) # 80000dce <release>
}
    80000776:	bfc9                	j	80000748 <printf+0x1b0>

0000000080000778 <printfinit>:
        ;
}

void printfinit(void)
{
    80000778:	1101                	addi	sp,sp,-32
    8000077a:	ec06                	sd	ra,24(sp)
    8000077c:	e822                	sd	s0,16(sp)
    8000077e:	e426                	sd	s1,8(sp)
    80000780:	1000                	addi	s0,sp,32
    initlock(&pr.lock, "pr");
    80000782:	00010497          	auipc	s1,0x10
    80000786:	4e648493          	addi	s1,s1,1254 # 80010c68 <pr>
    8000078a:	00008597          	auipc	a1,0x8
    8000078e:	8be58593          	addi	a1,a1,-1858 # 80008048 <__func__.1+0x40>
    80000792:	8526                	mv	a0,s1
    80000794:	00000097          	auipc	ra,0x0
    80000798:	4f6080e7          	jalr	1270(ra) # 80000c8a <initlock>
    pr.locking = 1;
    8000079c:	4785                	li	a5,1
    8000079e:	cc9c                	sw	a5,24(s1)
}
    800007a0:	60e2                	ld	ra,24(sp)
    800007a2:	6442                	ld	s0,16(sp)
    800007a4:	64a2                	ld	s1,8(sp)
    800007a6:	6105                	addi	sp,sp,32
    800007a8:	8082                	ret

00000000800007aa <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007aa:	1141                	addi	sp,sp,-16
    800007ac:	e406                	sd	ra,8(sp)
    800007ae:	e022                	sd	s0,0(sp)
    800007b0:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007b2:	100007b7          	lui	a5,0x10000
    800007b6:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ba:	f8000713          	li	a4,-128
    800007be:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007c2:	470d                	li	a4,3
    800007c4:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007c8:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007cc:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007d0:	469d                	li	a3,7
    800007d2:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007d6:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007da:	00008597          	auipc	a1,0x8
    800007de:	88e58593          	addi	a1,a1,-1906 # 80008068 <digits+0x18>
    800007e2:	00010517          	auipc	a0,0x10
    800007e6:	4a650513          	addi	a0,a0,1190 # 80010c88 <uart_tx_lock>
    800007ea:	00000097          	auipc	ra,0x0
    800007ee:	4a0080e7          	jalr	1184(ra) # 80000c8a <initlock>
}
    800007f2:	60a2                	ld	ra,8(sp)
    800007f4:	6402                	ld	s0,0(sp)
    800007f6:	0141                	addi	sp,sp,16
    800007f8:	8082                	ret

00000000800007fa <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007fa:	1101                	addi	sp,sp,-32
    800007fc:	ec06                	sd	ra,24(sp)
    800007fe:	e822                	sd	s0,16(sp)
    80000800:	e426                	sd	s1,8(sp)
    80000802:	1000                	addi	s0,sp,32
    80000804:	84aa                	mv	s1,a0
  push_off();
    80000806:	00000097          	auipc	ra,0x0
    8000080a:	4c8080e7          	jalr	1224(ra) # 80000cce <push_off>

  if(panicked){
    8000080e:	00008797          	auipc	a5,0x8
    80000812:	2227a783          	lw	a5,546(a5) # 80008a30 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000816:	10000737          	lui	a4,0x10000
  if(panicked){
    8000081a:	c391                	beqz	a5,8000081e <uartputc_sync+0x24>
    for(;;)
    8000081c:	a001                	j	8000081c <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000081e:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000822:	0207f793          	andi	a5,a5,32
    80000826:	dfe5                	beqz	a5,8000081e <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000828:	0ff4f513          	zext.b	a0,s1
    8000082c:	100007b7          	lui	a5,0x10000
    80000830:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000834:	00000097          	auipc	ra,0x0
    80000838:	53a080e7          	jalr	1338(ra) # 80000d6e <pop_off>
}
    8000083c:	60e2                	ld	ra,24(sp)
    8000083e:	6442                	ld	s0,16(sp)
    80000840:	64a2                	ld	s1,8(sp)
    80000842:	6105                	addi	sp,sp,32
    80000844:	8082                	ret

0000000080000846 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000846:	00008797          	auipc	a5,0x8
    8000084a:	1f27b783          	ld	a5,498(a5) # 80008a38 <uart_tx_r>
    8000084e:	00008717          	auipc	a4,0x8
    80000852:	1f273703          	ld	a4,498(a4) # 80008a40 <uart_tx_w>
    80000856:	06f70a63          	beq	a4,a5,800008ca <uartstart+0x84>
{
    8000085a:	7139                	addi	sp,sp,-64
    8000085c:	fc06                	sd	ra,56(sp)
    8000085e:	f822                	sd	s0,48(sp)
    80000860:	f426                	sd	s1,40(sp)
    80000862:	f04a                	sd	s2,32(sp)
    80000864:	ec4e                	sd	s3,24(sp)
    80000866:	e852                	sd	s4,16(sp)
    80000868:	e456                	sd	s5,8(sp)
    8000086a:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000086c:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000870:	00010a17          	auipc	s4,0x10
    80000874:	418a0a13          	addi	s4,s4,1048 # 80010c88 <uart_tx_lock>
    uart_tx_r += 1;
    80000878:	00008497          	auipc	s1,0x8
    8000087c:	1c048493          	addi	s1,s1,448 # 80008a38 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000880:	00008997          	auipc	s3,0x8
    80000884:	1c098993          	addi	s3,s3,448 # 80008a40 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000888:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000088c:	02077713          	andi	a4,a4,32
    80000890:	c705                	beqz	a4,800008b8 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000892:	01f7f713          	andi	a4,a5,31
    80000896:	9752                	add	a4,a4,s4
    80000898:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000089c:	0785                	addi	a5,a5,1
    8000089e:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008a0:	8526                	mv	a0,s1
    800008a2:	00002097          	auipc	ra,0x2
    800008a6:	b16080e7          	jalr	-1258(ra) # 800023b8 <wakeup>
    
    WriteReg(THR, c);
    800008aa:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ae:	609c                	ld	a5,0(s1)
    800008b0:	0009b703          	ld	a4,0(s3)
    800008b4:	fcf71ae3          	bne	a4,a5,80000888 <uartstart+0x42>
  }
}
    800008b8:	70e2                	ld	ra,56(sp)
    800008ba:	7442                	ld	s0,48(sp)
    800008bc:	74a2                	ld	s1,40(sp)
    800008be:	7902                	ld	s2,32(sp)
    800008c0:	69e2                	ld	s3,24(sp)
    800008c2:	6a42                	ld	s4,16(sp)
    800008c4:	6aa2                	ld	s5,8(sp)
    800008c6:	6121                	addi	sp,sp,64
    800008c8:	8082                	ret
    800008ca:	8082                	ret

00000000800008cc <uartputc>:
{
    800008cc:	7179                	addi	sp,sp,-48
    800008ce:	f406                	sd	ra,40(sp)
    800008d0:	f022                	sd	s0,32(sp)
    800008d2:	ec26                	sd	s1,24(sp)
    800008d4:	e84a                	sd	s2,16(sp)
    800008d6:	e44e                	sd	s3,8(sp)
    800008d8:	e052                	sd	s4,0(sp)
    800008da:	1800                	addi	s0,sp,48
    800008dc:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008de:	00010517          	auipc	a0,0x10
    800008e2:	3aa50513          	addi	a0,a0,938 # 80010c88 <uart_tx_lock>
    800008e6:	00000097          	auipc	ra,0x0
    800008ea:	434080e7          	jalr	1076(ra) # 80000d1a <acquire>
  if(panicked){
    800008ee:	00008797          	auipc	a5,0x8
    800008f2:	1427a783          	lw	a5,322(a5) # 80008a30 <panicked>
    800008f6:	e7c9                	bnez	a5,80000980 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008f8:	00008717          	auipc	a4,0x8
    800008fc:	14873703          	ld	a4,328(a4) # 80008a40 <uart_tx_w>
    80000900:	00008797          	auipc	a5,0x8
    80000904:	1387b783          	ld	a5,312(a5) # 80008a38 <uart_tx_r>
    80000908:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    8000090c:	00010997          	auipc	s3,0x10
    80000910:	37c98993          	addi	s3,s3,892 # 80010c88 <uart_tx_lock>
    80000914:	00008497          	auipc	s1,0x8
    80000918:	12448493          	addi	s1,s1,292 # 80008a38 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000091c:	00008917          	auipc	s2,0x8
    80000920:	12490913          	addi	s2,s2,292 # 80008a40 <uart_tx_w>
    80000924:	00e79f63          	bne	a5,a4,80000942 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85ce                	mv	a1,s3
    8000092a:	8526                	mv	a0,s1
    8000092c:	00002097          	auipc	ra,0x2
    80000930:	a28080e7          	jalr	-1496(ra) # 80002354 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093703          	ld	a4,0(s2)
    80000938:	609c                	ld	a5,0(s1)
    8000093a:	02078793          	addi	a5,a5,32
    8000093e:	fee785e3          	beq	a5,a4,80000928 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00010497          	auipc	s1,0x10
    80000946:	34648493          	addi	s1,s1,838 # 80010c88 <uart_tx_lock>
    8000094a:	01f77793          	andi	a5,a4,31
    8000094e:	97a6                	add	a5,a5,s1
    80000950:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000954:	0705                	addi	a4,a4,1
    80000956:	00008797          	auipc	a5,0x8
    8000095a:	0ee7b523          	sd	a4,234(a5) # 80008a40 <uart_tx_w>
  uartstart();
    8000095e:	00000097          	auipc	ra,0x0
    80000962:	ee8080e7          	jalr	-280(ra) # 80000846 <uartstart>
  release(&uart_tx_lock);
    80000966:	8526                	mv	a0,s1
    80000968:	00000097          	auipc	ra,0x0
    8000096c:	466080e7          	jalr	1126(ra) # 80000dce <release>
}
    80000970:	70a2                	ld	ra,40(sp)
    80000972:	7402                	ld	s0,32(sp)
    80000974:	64e2                	ld	s1,24(sp)
    80000976:	6942                	ld	s2,16(sp)
    80000978:	69a2                	ld	s3,8(sp)
    8000097a:	6a02                	ld	s4,0(sp)
    8000097c:	6145                	addi	sp,sp,48
    8000097e:	8082                	ret
    for(;;)
    80000980:	a001                	j	80000980 <uartputc+0xb4>

0000000080000982 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000982:	1141                	addi	sp,sp,-16
    80000984:	e422                	sd	s0,8(sp)
    80000986:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000988:	100007b7          	lui	a5,0x10000
    8000098c:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000990:	8b85                	andi	a5,a5,1
    80000992:	cb81                	beqz	a5,800009a2 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000994:	100007b7          	lui	a5,0x10000
    80000998:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    8000099c:	6422                	ld	s0,8(sp)
    8000099e:	0141                	addi	sp,sp,16
    800009a0:	8082                	ret
    return -1;
    800009a2:	557d                	li	a0,-1
    800009a4:	bfe5                	j	8000099c <uartgetc+0x1a>

00000000800009a6 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    800009a6:	1101                	addi	sp,sp,-32
    800009a8:	ec06                	sd	ra,24(sp)
    800009aa:	e822                	sd	s0,16(sp)
    800009ac:	e426                	sd	s1,8(sp)
    800009ae:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b0:	54fd                	li	s1,-1
    800009b2:	a029                	j	800009bc <uartintr+0x16>
      break;
    consoleintr(c);
    800009b4:	00000097          	auipc	ra,0x0
    800009b8:	906080e7          	jalr	-1786(ra) # 800002ba <consoleintr>
    int c = uartgetc();
    800009bc:	00000097          	auipc	ra,0x0
    800009c0:	fc6080e7          	jalr	-58(ra) # 80000982 <uartgetc>
    if(c == -1)
    800009c4:	fe9518e3          	bne	a0,s1,800009b4 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009c8:	00010497          	auipc	s1,0x10
    800009cc:	2c048493          	addi	s1,s1,704 # 80010c88 <uart_tx_lock>
    800009d0:	8526                	mv	a0,s1
    800009d2:	00000097          	auipc	ra,0x0
    800009d6:	348080e7          	jalr	840(ra) # 80000d1a <acquire>
  uartstart();
    800009da:	00000097          	auipc	ra,0x0
    800009de:	e6c080e7          	jalr	-404(ra) # 80000846 <uartstart>
  release(&uart_tx_lock);
    800009e2:	8526                	mv	a0,s1
    800009e4:	00000097          	auipc	ra,0x0
    800009e8:	3ea080e7          	jalr	1002(ra) # 80000dce <release>
}
    800009ec:	60e2                	ld	ra,24(sp)
    800009ee:	6442                	ld	s0,16(sp)
    800009f0:	64a2                	ld	s1,8(sp)
    800009f2:	6105                	addi	sp,sp,32
    800009f4:	8082                	ret

00000000800009f6 <kfree>:
// Free the page of physical memory pointed at by pa,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void kfree(void *pa)
{
    800009f6:	1101                	addi	sp,sp,-32
    800009f8:	ec06                	sd	ra,24(sp)
    800009fa:	e822                	sd	s0,16(sp)
    800009fc:	e426                	sd	s1,8(sp)
    800009fe:	e04a                	sd	s2,0(sp)
    80000a00:	1000                	addi	s0,sp,32
    80000a02:	84aa                	mv	s1,a0
    if (MAX_PAGES != 0)
    80000a04:	00008797          	auipc	a5,0x8
    80000a08:	04c7b783          	ld	a5,76(a5) # 80008a50 <MAX_PAGES>
    80000a0c:	c799                	beqz	a5,80000a1a <kfree+0x24>
        assert(FREE_PAGES < MAX_PAGES);
    80000a0e:	00008717          	auipc	a4,0x8
    80000a12:	03a73703          	ld	a4,58(a4) # 80008a48 <FREE_PAGES>
    80000a16:	06f77663          	bgeu	a4,a5,80000a82 <kfree+0x8c>
    struct run *r;

    if (((uint64)pa % PGSIZE) != 0 || (char *)pa < end || (uint64)pa >= PHYSTOP)
    80000a1a:	03449793          	slli	a5,s1,0x34
    80000a1e:	efc1                	bnez	a5,80000ab6 <kfree+0xc0>
    80000a20:	00041797          	auipc	a5,0x41
    80000a24:	4d078793          	addi	a5,a5,1232 # 80041ef0 <end>
    80000a28:	08f4e763          	bltu	s1,a5,80000ab6 <kfree+0xc0>
    80000a2c:	47c5                	li	a5,17
    80000a2e:	07ee                	slli	a5,a5,0x1b
    80000a30:	08f4f363          	bgeu	s1,a5,80000ab6 <kfree+0xc0>
        panic("kfree");

    // Fill with junk to catch dangling refs.
    memset(pa, 1, PGSIZE);
    80000a34:	6605                	lui	a2,0x1
    80000a36:	4585                	li	a1,1
    80000a38:	8526                	mv	a0,s1
    80000a3a:	00000097          	auipc	ra,0x0
    80000a3e:	3dc080e7          	jalr	988(ra) # 80000e16 <memset>

    r = (struct run *)pa;

    acquire(&kmem.lock);
    80000a42:	00010917          	auipc	s2,0x10
    80000a46:	27e90913          	addi	s2,s2,638 # 80010cc0 <kmem>
    80000a4a:	854a                	mv	a0,s2
    80000a4c:	00000097          	auipc	ra,0x0
    80000a50:	2ce080e7          	jalr	718(ra) # 80000d1a <acquire>
    r->next = kmem.freelist;
    80000a54:	01893783          	ld	a5,24(s2)
    80000a58:	e09c                	sd	a5,0(s1)
    kmem.freelist = r;
    80000a5a:	00993c23          	sd	s1,24(s2)
    FREE_PAGES++;
    80000a5e:	00008717          	auipc	a4,0x8
    80000a62:	fea70713          	addi	a4,a4,-22 # 80008a48 <FREE_PAGES>
    80000a66:	631c                	ld	a5,0(a4)
    80000a68:	0785                	addi	a5,a5,1
    80000a6a:	e31c                	sd	a5,0(a4)
    release(&kmem.lock);
    80000a6c:	854a                	mv	a0,s2
    80000a6e:	00000097          	auipc	ra,0x0
    80000a72:	360080e7          	jalr	864(ra) # 80000dce <release>
}
    80000a76:	60e2                	ld	ra,24(sp)
    80000a78:	6442                	ld	s0,16(sp)
    80000a7a:	64a2                	ld	s1,8(sp)
    80000a7c:	6902                	ld	s2,0(sp)
    80000a7e:	6105                	addi	sp,sp,32
    80000a80:	8082                	ret
        assert(FREE_PAGES < MAX_PAGES);
    80000a82:	03c00693          	li	a3,60
    80000a86:	00007617          	auipc	a2,0x7
    80000a8a:	58260613          	addi	a2,a2,1410 # 80008008 <__func__.1>
    80000a8e:	00007597          	auipc	a1,0x7
    80000a92:	5e258593          	addi	a1,a1,1506 # 80008070 <digits+0x20>
    80000a96:	00007517          	auipc	a0,0x7
    80000a9a:	5ea50513          	addi	a0,a0,1514 # 80008080 <digits+0x30>
    80000a9e:	00000097          	auipc	ra,0x0
    80000aa2:	afa080e7          	jalr	-1286(ra) # 80000598 <printf>
    80000aa6:	00007517          	auipc	a0,0x7
    80000aaa:	5ea50513          	addi	a0,a0,1514 # 80008090 <digits+0x40>
    80000aae:	00000097          	auipc	ra,0x0
    80000ab2:	a8e080e7          	jalr	-1394(ra) # 8000053c <panic>
        panic("kfree");
    80000ab6:	00007517          	auipc	a0,0x7
    80000aba:	5ea50513          	addi	a0,a0,1514 # 800080a0 <digits+0x50>
    80000abe:	00000097          	auipc	ra,0x0
    80000ac2:	a7e080e7          	jalr	-1410(ra) # 8000053c <panic>

0000000080000ac6 <freerange>:
{
    80000ac6:	7179                	addi	sp,sp,-48
    80000ac8:	f406                	sd	ra,40(sp)
    80000aca:	f022                	sd	s0,32(sp)
    80000acc:	ec26                	sd	s1,24(sp)
    80000ace:	e84a                	sd	s2,16(sp)
    80000ad0:	e44e                	sd	s3,8(sp)
    80000ad2:	e052                	sd	s4,0(sp)
    80000ad4:	1800                	addi	s0,sp,48
    p = (char *)PGROUNDUP((uint64)pa_start);
    80000ad6:	6785                	lui	a5,0x1
    80000ad8:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000adc:	00e504b3          	add	s1,a0,a4
    80000ae0:	777d                	lui	a4,0xfffff
    80000ae2:	8cf9                	and	s1,s1,a4
    for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    80000ae4:	94be                	add	s1,s1,a5
    80000ae6:	0095ee63          	bltu	a1,s1,80000b02 <freerange+0x3c>
    80000aea:	892e                	mv	s2,a1
        kfree(p);
    80000aec:	7a7d                	lui	s4,0xfffff
    for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    80000aee:	6985                	lui	s3,0x1
        kfree(p);
    80000af0:	01448533          	add	a0,s1,s4
    80000af4:	00000097          	auipc	ra,0x0
    80000af8:	f02080e7          	jalr	-254(ra) # 800009f6 <kfree>
    for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    80000afc:	94ce                	add	s1,s1,s3
    80000afe:	fe9979e3          	bgeu	s2,s1,80000af0 <freerange+0x2a>
}
    80000b02:	70a2                	ld	ra,40(sp)
    80000b04:	7402                	ld	s0,32(sp)
    80000b06:	64e2                	ld	s1,24(sp)
    80000b08:	6942                	ld	s2,16(sp)
    80000b0a:	69a2                	ld	s3,8(sp)
    80000b0c:	6a02                	ld	s4,0(sp)
    80000b0e:	6145                	addi	sp,sp,48
    80000b10:	8082                	ret

0000000080000b12 <kinit>:
{
    80000b12:	1141                	addi	sp,sp,-16
    80000b14:	e406                	sd	ra,8(sp)
    80000b16:	e022                	sd	s0,0(sp)
    80000b18:	0800                	addi	s0,sp,16
    initlock(&kmem.lock, "kmem");
    80000b1a:	00007597          	auipc	a1,0x7
    80000b1e:	58e58593          	addi	a1,a1,1422 # 800080a8 <digits+0x58>
    80000b22:	00010517          	auipc	a0,0x10
    80000b26:	19e50513          	addi	a0,a0,414 # 80010cc0 <kmem>
    80000b2a:	00000097          	auipc	ra,0x0
    80000b2e:	160080e7          	jalr	352(ra) # 80000c8a <initlock>
    freerange(end, (void *)PHYSTOP);
    80000b32:	45c5                	li	a1,17
    80000b34:	05ee                	slli	a1,a1,0x1b
    80000b36:	00041517          	auipc	a0,0x41
    80000b3a:	3ba50513          	addi	a0,a0,954 # 80041ef0 <end>
    80000b3e:	00000097          	auipc	ra,0x0
    80000b42:	f88080e7          	jalr	-120(ra) # 80000ac6 <freerange>
    MAX_PAGES = FREE_PAGES;
    80000b46:	00008797          	auipc	a5,0x8
    80000b4a:	f027b783          	ld	a5,-254(a5) # 80008a48 <FREE_PAGES>
    80000b4e:	00008717          	auipc	a4,0x8
    80000b52:	f0f73123          	sd	a5,-254(a4) # 80008a50 <MAX_PAGES>
}
    80000b56:	60a2                	ld	ra,8(sp)
    80000b58:	6402                	ld	s0,0(sp)
    80000b5a:	0141                	addi	sp,sp,16
    80000b5c:	8082                	ret

0000000080000b5e <increment_reference_counter>:
}

#define IndexHelper(x) (((void *)PHYSTOP-x)/PGSIZE)

void increment_reference_counter(void *pa)
{
    80000b5e:	1141                	addi	sp,sp,-16
    80000b60:	e422                	sd	s0,8(sp)
    80000b62:	0800                	addi	s0,sp,16
    reference_counter[IndexHelper(pa)]++;
    80000b64:	47c5                	li	a5,17
    80000b66:	07ee                	slli	a5,a5,0x1b
    80000b68:	40a78533          	sub	a0,a5,a0
    80000b6c:	43f55793          	srai	a5,a0,0x3f
    80000b70:	17d2                	slli	a5,a5,0x34
    80000b72:	93d1                	srli	a5,a5,0x34
    80000b74:	97aa                	add	a5,a5,a0
    80000b76:	87b1                	srai	a5,a5,0xc
    80000b78:	078a                	slli	a5,a5,0x2
    80000b7a:	00010717          	auipc	a4,0x10
    80000b7e:	16670713          	addi	a4,a4,358 # 80010ce0 <reference_counter>
    80000b82:	97ba                	add	a5,a5,a4
    80000b84:	4398                	lw	a4,0(a5)
    80000b86:	2705                	addiw	a4,a4,1
    80000b88:	c398                	sw	a4,0(a5)
}
    80000b8a:	6422                	ld	s0,8(sp)
    80000b8c:	0141                	addi	sp,sp,16
    80000b8e:	8082                	ret

0000000080000b90 <kalloc>:
{
    80000b90:	1101                	addi	sp,sp,-32
    80000b92:	ec06                	sd	ra,24(sp)
    80000b94:	e822                	sd	s0,16(sp)
    80000b96:	e426                	sd	s1,8(sp)
    80000b98:	1000                	addi	s0,sp,32
    assert(FREE_PAGES > 0);
    80000b9a:	00008797          	auipc	a5,0x8
    80000b9e:	eae7b783          	ld	a5,-338(a5) # 80008a48 <FREE_PAGES>
    80000ba2:	cfb9                	beqz	a5,80000c00 <kalloc+0x70>
    acquire(&kmem.lock);
    80000ba4:	00010497          	auipc	s1,0x10
    80000ba8:	11c48493          	addi	s1,s1,284 # 80010cc0 <kmem>
    80000bac:	8526                	mv	a0,s1
    80000bae:	00000097          	auipc	ra,0x0
    80000bb2:	16c080e7          	jalr	364(ra) # 80000d1a <acquire>
    r = kmem.freelist;
    80000bb6:	6c84                	ld	s1,24(s1)
    if (r)
    80000bb8:	ccb5                	beqz	s1,80000c34 <kalloc+0xa4>
        kmem.freelist = r->next;
    80000bba:	609c                	ld	a5,0(s1)
    80000bbc:	00010517          	auipc	a0,0x10
    80000bc0:	10450513          	addi	a0,a0,260 # 80010cc0 <kmem>
    80000bc4:	ed1c                	sd	a5,24(a0)
    release(&kmem.lock);
    80000bc6:	00000097          	auipc	ra,0x0
    80000bca:	208080e7          	jalr	520(ra) # 80000dce <release>
        memset((char *)r, 5, PGSIZE); // fill with junk
    80000bce:	6605                	lui	a2,0x1
    80000bd0:	4595                	li	a1,5
    80000bd2:	8526                	mv	a0,s1
    80000bd4:	00000097          	auipc	ra,0x0
    80000bd8:	242080e7          	jalr	578(ra) # 80000e16 <memset>
    increment_reference_counter(r);
    80000bdc:	8526                	mv	a0,s1
    80000bde:	00000097          	auipc	ra,0x0
    80000be2:	f80080e7          	jalr	-128(ra) # 80000b5e <increment_reference_counter>
    FREE_PAGES--;
    80000be6:	00008717          	auipc	a4,0x8
    80000bea:	e6270713          	addi	a4,a4,-414 # 80008a48 <FREE_PAGES>
    80000bee:	631c                	ld	a5,0(a4)
    80000bf0:	17fd                	addi	a5,a5,-1
    80000bf2:	e31c                	sd	a5,0(a4)
}
    80000bf4:	8526                	mv	a0,s1
    80000bf6:	60e2                	ld	ra,24(sp)
    80000bf8:	6442                	ld	s0,16(sp)
    80000bfa:	64a2                	ld	s1,8(sp)
    80000bfc:	6105                	addi	sp,sp,32
    80000bfe:	8082                	ret
    assert(FREE_PAGES > 0);
    80000c00:	05400693          	li	a3,84
    80000c04:	00007617          	auipc	a2,0x7
    80000c08:	3fc60613          	addi	a2,a2,1020 # 80008000 <etext>
    80000c0c:	00007597          	auipc	a1,0x7
    80000c10:	46458593          	addi	a1,a1,1124 # 80008070 <digits+0x20>
    80000c14:	00007517          	auipc	a0,0x7
    80000c18:	46c50513          	addi	a0,a0,1132 # 80008080 <digits+0x30>
    80000c1c:	00000097          	auipc	ra,0x0
    80000c20:	97c080e7          	jalr	-1668(ra) # 80000598 <printf>
    80000c24:	00007517          	auipc	a0,0x7
    80000c28:	46c50513          	addi	a0,a0,1132 # 80008090 <digits+0x40>
    80000c2c:	00000097          	auipc	ra,0x0
    80000c30:	910080e7          	jalr	-1776(ra) # 8000053c <panic>
    release(&kmem.lock);
    80000c34:	00010517          	auipc	a0,0x10
    80000c38:	08c50513          	addi	a0,a0,140 # 80010cc0 <kmem>
    80000c3c:	00000097          	auipc	ra,0x0
    80000c40:	192080e7          	jalr	402(ra) # 80000dce <release>
    if (r)
    80000c44:	bf61                	j	80000bdc <kalloc+0x4c>

0000000080000c46 <decrement_reference_counter>:

void decrement_reference_counter(void *pa)
{
    reference_counter[IndexHelper(pa)]--;
    80000c46:	4745                	li	a4,17
    80000c48:	076e                	slli	a4,a4,0x1b
    80000c4a:	8f09                	sub	a4,a4,a0
    80000c4c:	43f75793          	srai	a5,a4,0x3f
    80000c50:	17d2                	slli	a5,a5,0x34
    80000c52:	93d1                	srli	a5,a5,0x34
    80000c54:	97ba                	add	a5,a5,a4
    80000c56:	87b1                	srai	a5,a5,0xc
    80000c58:	078a                	slli	a5,a5,0x2
    80000c5a:	00010717          	auipc	a4,0x10
    80000c5e:	08670713          	addi	a4,a4,134 # 80010ce0 <reference_counter>
    80000c62:	97ba                	add	a5,a5,a4
    80000c64:	4398                	lw	a4,0(a5)
    80000c66:	377d                	addiw	a4,a4,-1
    80000c68:	0007069b          	sext.w	a3,a4
    80000c6c:	c398                	sw	a4,0(a5)
    if (reference_counter[IndexHelper(pa)] == 0)
    80000c6e:	c291                	beqz	a3,80000c72 <decrement_reference_counter+0x2c>
    80000c70:	8082                	ret
{
    80000c72:	1141                	addi	sp,sp,-16
    80000c74:	e406                	sd	ra,8(sp)
    80000c76:	e022                	sd	s0,0(sp)
    80000c78:	0800                	addi	s0,sp,16
    {
        kfree(pa);
    80000c7a:	00000097          	auipc	ra,0x0
    80000c7e:	d7c080e7          	jalr	-644(ra) # 800009f6 <kfree>
    }
    80000c82:	60a2                	ld	ra,8(sp)
    80000c84:	6402                	ld	s0,0(sp)
    80000c86:	0141                	addi	sp,sp,16
    80000c88:	8082                	ret

0000000080000c8a <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000c8a:	1141                	addi	sp,sp,-16
    80000c8c:	e422                	sd	s0,8(sp)
    80000c8e:	0800                	addi	s0,sp,16
  lk->name = name;
    80000c90:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000c92:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000c96:	00053823          	sd	zero,16(a0)
}
    80000c9a:	6422                	ld	s0,8(sp)
    80000c9c:	0141                	addi	sp,sp,16
    80000c9e:	8082                	ret

0000000080000ca0 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000ca0:	411c                	lw	a5,0(a0)
    80000ca2:	e399                	bnez	a5,80000ca8 <holding+0x8>
    80000ca4:	4501                	li	a0,0
  return r;
}
    80000ca6:	8082                	ret
{
    80000ca8:	1101                	addi	sp,sp,-32
    80000caa:	ec06                	sd	ra,24(sp)
    80000cac:	e822                	sd	s0,16(sp)
    80000cae:	e426                	sd	s1,8(sp)
    80000cb0:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000cb2:	6904                	ld	s1,16(a0)
    80000cb4:	00001097          	auipc	ra,0x1
    80000cb8:	f1c080e7          	jalr	-228(ra) # 80001bd0 <mycpu>
    80000cbc:	40a48533          	sub	a0,s1,a0
    80000cc0:	00153513          	seqz	a0,a0
}
    80000cc4:	60e2                	ld	ra,24(sp)
    80000cc6:	6442                	ld	s0,16(sp)
    80000cc8:	64a2                	ld	s1,8(sp)
    80000cca:	6105                	addi	sp,sp,32
    80000ccc:	8082                	ret

0000000080000cce <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000cce:	1101                	addi	sp,sp,-32
    80000cd0:	ec06                	sd	ra,24(sp)
    80000cd2:	e822                	sd	s0,16(sp)
    80000cd4:	e426                	sd	s1,8(sp)
    80000cd6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cd8:	100024f3          	csrr	s1,sstatus
    80000cdc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000ce0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000ce2:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000ce6:	00001097          	auipc	ra,0x1
    80000cea:	eea080e7          	jalr	-278(ra) # 80001bd0 <mycpu>
    80000cee:	5d3c                	lw	a5,120(a0)
    80000cf0:	cf89                	beqz	a5,80000d0a <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000cf2:	00001097          	auipc	ra,0x1
    80000cf6:	ede080e7          	jalr	-290(ra) # 80001bd0 <mycpu>
    80000cfa:	5d3c                	lw	a5,120(a0)
    80000cfc:	2785                	addiw	a5,a5,1
    80000cfe:	dd3c                	sw	a5,120(a0)
}
    80000d00:	60e2                	ld	ra,24(sp)
    80000d02:	6442                	ld	s0,16(sp)
    80000d04:	64a2                	ld	s1,8(sp)
    80000d06:	6105                	addi	sp,sp,32
    80000d08:	8082                	ret
    mycpu()->intena = old;
    80000d0a:	00001097          	auipc	ra,0x1
    80000d0e:	ec6080e7          	jalr	-314(ra) # 80001bd0 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000d12:	8085                	srli	s1,s1,0x1
    80000d14:	8885                	andi	s1,s1,1
    80000d16:	dd64                	sw	s1,124(a0)
    80000d18:	bfe9                	j	80000cf2 <push_off+0x24>

0000000080000d1a <acquire>:
{
    80000d1a:	1101                	addi	sp,sp,-32
    80000d1c:	ec06                	sd	ra,24(sp)
    80000d1e:	e822                	sd	s0,16(sp)
    80000d20:	e426                	sd	s1,8(sp)
    80000d22:	1000                	addi	s0,sp,32
    80000d24:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000d26:	00000097          	auipc	ra,0x0
    80000d2a:	fa8080e7          	jalr	-88(ra) # 80000cce <push_off>
  if(holding(lk))
    80000d2e:	8526                	mv	a0,s1
    80000d30:	00000097          	auipc	ra,0x0
    80000d34:	f70080e7          	jalr	-144(ra) # 80000ca0 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000d38:	4705                	li	a4,1
  if(holding(lk))
    80000d3a:	e115                	bnez	a0,80000d5e <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000d3c:	87ba                	mv	a5,a4
    80000d3e:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000d42:	2781                	sext.w	a5,a5
    80000d44:	ffe5                	bnez	a5,80000d3c <acquire+0x22>
  __sync_synchronize();
    80000d46:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000d4a:	00001097          	auipc	ra,0x1
    80000d4e:	e86080e7          	jalr	-378(ra) # 80001bd0 <mycpu>
    80000d52:	e888                	sd	a0,16(s1)
}
    80000d54:	60e2                	ld	ra,24(sp)
    80000d56:	6442                	ld	s0,16(sp)
    80000d58:	64a2                	ld	s1,8(sp)
    80000d5a:	6105                	addi	sp,sp,32
    80000d5c:	8082                	ret
    panic("acquire");
    80000d5e:	00007517          	auipc	a0,0x7
    80000d62:	35250513          	addi	a0,a0,850 # 800080b0 <digits+0x60>
    80000d66:	fffff097          	auipc	ra,0xfffff
    80000d6a:	7d6080e7          	jalr	2006(ra) # 8000053c <panic>

0000000080000d6e <pop_off>:

void
pop_off(void)
{
    80000d6e:	1141                	addi	sp,sp,-16
    80000d70:	e406                	sd	ra,8(sp)
    80000d72:	e022                	sd	s0,0(sp)
    80000d74:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000d76:	00001097          	auipc	ra,0x1
    80000d7a:	e5a080e7          	jalr	-422(ra) # 80001bd0 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d7e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000d82:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000d84:	e78d                	bnez	a5,80000dae <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000d86:	5d3c                	lw	a5,120(a0)
    80000d88:	02f05b63          	blez	a5,80000dbe <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000d8c:	37fd                	addiw	a5,a5,-1
    80000d8e:	0007871b          	sext.w	a4,a5
    80000d92:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000d94:	eb09                	bnez	a4,80000da6 <pop_off+0x38>
    80000d96:	5d7c                	lw	a5,124(a0)
    80000d98:	c799                	beqz	a5,80000da6 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d9a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000d9e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000da2:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000da6:	60a2                	ld	ra,8(sp)
    80000da8:	6402                	ld	s0,0(sp)
    80000daa:	0141                	addi	sp,sp,16
    80000dac:	8082                	ret
    panic("pop_off - interruptible");
    80000dae:	00007517          	auipc	a0,0x7
    80000db2:	30a50513          	addi	a0,a0,778 # 800080b8 <digits+0x68>
    80000db6:	fffff097          	auipc	ra,0xfffff
    80000dba:	786080e7          	jalr	1926(ra) # 8000053c <panic>
    panic("pop_off");
    80000dbe:	00007517          	auipc	a0,0x7
    80000dc2:	31250513          	addi	a0,a0,786 # 800080d0 <digits+0x80>
    80000dc6:	fffff097          	auipc	ra,0xfffff
    80000dca:	776080e7          	jalr	1910(ra) # 8000053c <panic>

0000000080000dce <release>:
{
    80000dce:	1101                	addi	sp,sp,-32
    80000dd0:	ec06                	sd	ra,24(sp)
    80000dd2:	e822                	sd	s0,16(sp)
    80000dd4:	e426                	sd	s1,8(sp)
    80000dd6:	1000                	addi	s0,sp,32
    80000dd8:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000dda:	00000097          	auipc	ra,0x0
    80000dde:	ec6080e7          	jalr	-314(ra) # 80000ca0 <holding>
    80000de2:	c115                	beqz	a0,80000e06 <release+0x38>
  lk->cpu = 0;
    80000de4:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000de8:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000dec:	0f50000f          	fence	iorw,ow
    80000df0:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000df4:	00000097          	auipc	ra,0x0
    80000df8:	f7a080e7          	jalr	-134(ra) # 80000d6e <pop_off>
}
    80000dfc:	60e2                	ld	ra,24(sp)
    80000dfe:	6442                	ld	s0,16(sp)
    80000e00:	64a2                	ld	s1,8(sp)
    80000e02:	6105                	addi	sp,sp,32
    80000e04:	8082                	ret
    panic("release");
    80000e06:	00007517          	auipc	a0,0x7
    80000e0a:	2d250513          	addi	a0,a0,722 # 800080d8 <digits+0x88>
    80000e0e:	fffff097          	auipc	ra,0xfffff
    80000e12:	72e080e7          	jalr	1838(ra) # 8000053c <panic>

0000000080000e16 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000e16:	1141                	addi	sp,sp,-16
    80000e18:	e422                	sd	s0,8(sp)
    80000e1a:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000e1c:	ca19                	beqz	a2,80000e32 <memset+0x1c>
    80000e1e:	87aa                	mv	a5,a0
    80000e20:	1602                	slli	a2,a2,0x20
    80000e22:	9201                	srli	a2,a2,0x20
    80000e24:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000e28:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000e2c:	0785                	addi	a5,a5,1
    80000e2e:	fee79de3          	bne	a5,a4,80000e28 <memset+0x12>
  }
  return dst;
}
    80000e32:	6422                	ld	s0,8(sp)
    80000e34:	0141                	addi	sp,sp,16
    80000e36:	8082                	ret

0000000080000e38 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000e38:	1141                	addi	sp,sp,-16
    80000e3a:	e422                	sd	s0,8(sp)
    80000e3c:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000e3e:	ca05                	beqz	a2,80000e6e <memcmp+0x36>
    80000e40:	fff6069b          	addiw	a3,a2,-1
    80000e44:	1682                	slli	a3,a3,0x20
    80000e46:	9281                	srli	a3,a3,0x20
    80000e48:	0685                	addi	a3,a3,1
    80000e4a:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000e4c:	00054783          	lbu	a5,0(a0)
    80000e50:	0005c703          	lbu	a4,0(a1)
    80000e54:	00e79863          	bne	a5,a4,80000e64 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000e58:	0505                	addi	a0,a0,1
    80000e5a:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000e5c:	fed518e3          	bne	a0,a3,80000e4c <memcmp+0x14>
  }

  return 0;
    80000e60:	4501                	li	a0,0
    80000e62:	a019                	j	80000e68 <memcmp+0x30>
      return *s1 - *s2;
    80000e64:	40e7853b          	subw	a0,a5,a4
}
    80000e68:	6422                	ld	s0,8(sp)
    80000e6a:	0141                	addi	sp,sp,16
    80000e6c:	8082                	ret
  return 0;
    80000e6e:	4501                	li	a0,0
    80000e70:	bfe5                	j	80000e68 <memcmp+0x30>

0000000080000e72 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000e72:	1141                	addi	sp,sp,-16
    80000e74:	e422                	sd	s0,8(sp)
    80000e76:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000e78:	c205                	beqz	a2,80000e98 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000e7a:	02a5e263          	bltu	a1,a0,80000e9e <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000e7e:	1602                	slli	a2,a2,0x20
    80000e80:	9201                	srli	a2,a2,0x20
    80000e82:	00c587b3          	add	a5,a1,a2
{
    80000e86:	872a                	mv	a4,a0
      *d++ = *s++;
    80000e88:	0585                	addi	a1,a1,1
    80000e8a:	0705                	addi	a4,a4,1
    80000e8c:	fff5c683          	lbu	a3,-1(a1)
    80000e90:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000e94:	fef59ae3          	bne	a1,a5,80000e88 <memmove+0x16>

  return dst;
}
    80000e98:	6422                	ld	s0,8(sp)
    80000e9a:	0141                	addi	sp,sp,16
    80000e9c:	8082                	ret
  if(s < d && s + n > d){
    80000e9e:	02061693          	slli	a3,a2,0x20
    80000ea2:	9281                	srli	a3,a3,0x20
    80000ea4:	00d58733          	add	a4,a1,a3
    80000ea8:	fce57be3          	bgeu	a0,a4,80000e7e <memmove+0xc>
    d += n;
    80000eac:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000eae:	fff6079b          	addiw	a5,a2,-1
    80000eb2:	1782                	slli	a5,a5,0x20
    80000eb4:	9381                	srli	a5,a5,0x20
    80000eb6:	fff7c793          	not	a5,a5
    80000eba:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000ebc:	177d                	addi	a4,a4,-1
    80000ebe:	16fd                	addi	a3,a3,-1
    80000ec0:	00074603          	lbu	a2,0(a4)
    80000ec4:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000ec8:	fee79ae3          	bne	a5,a4,80000ebc <memmove+0x4a>
    80000ecc:	b7f1                	j	80000e98 <memmove+0x26>

0000000080000ece <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000ece:	1141                	addi	sp,sp,-16
    80000ed0:	e406                	sd	ra,8(sp)
    80000ed2:	e022                	sd	s0,0(sp)
    80000ed4:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000ed6:	00000097          	auipc	ra,0x0
    80000eda:	f9c080e7          	jalr	-100(ra) # 80000e72 <memmove>
}
    80000ede:	60a2                	ld	ra,8(sp)
    80000ee0:	6402                	ld	s0,0(sp)
    80000ee2:	0141                	addi	sp,sp,16
    80000ee4:	8082                	ret

0000000080000ee6 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000ee6:	1141                	addi	sp,sp,-16
    80000ee8:	e422                	sd	s0,8(sp)
    80000eea:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000eec:	ce11                	beqz	a2,80000f08 <strncmp+0x22>
    80000eee:	00054783          	lbu	a5,0(a0)
    80000ef2:	cf89                	beqz	a5,80000f0c <strncmp+0x26>
    80000ef4:	0005c703          	lbu	a4,0(a1)
    80000ef8:	00f71a63          	bne	a4,a5,80000f0c <strncmp+0x26>
    n--, p++, q++;
    80000efc:	367d                	addiw	a2,a2,-1
    80000efe:	0505                	addi	a0,a0,1
    80000f00:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000f02:	f675                	bnez	a2,80000eee <strncmp+0x8>
  if(n == 0)
    return 0;
    80000f04:	4501                	li	a0,0
    80000f06:	a809                	j	80000f18 <strncmp+0x32>
    80000f08:	4501                	li	a0,0
    80000f0a:	a039                	j	80000f18 <strncmp+0x32>
  if(n == 0)
    80000f0c:	ca09                	beqz	a2,80000f1e <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000f0e:	00054503          	lbu	a0,0(a0)
    80000f12:	0005c783          	lbu	a5,0(a1)
    80000f16:	9d1d                	subw	a0,a0,a5
}
    80000f18:	6422                	ld	s0,8(sp)
    80000f1a:	0141                	addi	sp,sp,16
    80000f1c:	8082                	ret
    return 0;
    80000f1e:	4501                	li	a0,0
    80000f20:	bfe5                	j	80000f18 <strncmp+0x32>

0000000080000f22 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000f22:	1141                	addi	sp,sp,-16
    80000f24:	e422                	sd	s0,8(sp)
    80000f26:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000f28:	87aa                	mv	a5,a0
    80000f2a:	86b2                	mv	a3,a2
    80000f2c:	367d                	addiw	a2,a2,-1
    80000f2e:	00d05963          	blez	a3,80000f40 <strncpy+0x1e>
    80000f32:	0785                	addi	a5,a5,1
    80000f34:	0005c703          	lbu	a4,0(a1)
    80000f38:	fee78fa3          	sb	a4,-1(a5)
    80000f3c:	0585                	addi	a1,a1,1
    80000f3e:	f775                	bnez	a4,80000f2a <strncpy+0x8>
    ;
  while(n-- > 0)
    80000f40:	873e                	mv	a4,a5
    80000f42:	9fb5                	addw	a5,a5,a3
    80000f44:	37fd                	addiw	a5,a5,-1
    80000f46:	00c05963          	blez	a2,80000f58 <strncpy+0x36>
    *s++ = 0;
    80000f4a:	0705                	addi	a4,a4,1
    80000f4c:	fe070fa3          	sb	zero,-1(a4)
  while(n-- > 0)
    80000f50:	40e786bb          	subw	a3,a5,a4
    80000f54:	fed04be3          	bgtz	a3,80000f4a <strncpy+0x28>
  return os;
}
    80000f58:	6422                	ld	s0,8(sp)
    80000f5a:	0141                	addi	sp,sp,16
    80000f5c:	8082                	ret

0000000080000f5e <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000f5e:	1141                	addi	sp,sp,-16
    80000f60:	e422                	sd	s0,8(sp)
    80000f62:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000f64:	02c05363          	blez	a2,80000f8a <safestrcpy+0x2c>
    80000f68:	fff6069b          	addiw	a3,a2,-1
    80000f6c:	1682                	slli	a3,a3,0x20
    80000f6e:	9281                	srli	a3,a3,0x20
    80000f70:	96ae                	add	a3,a3,a1
    80000f72:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000f74:	00d58963          	beq	a1,a3,80000f86 <safestrcpy+0x28>
    80000f78:	0585                	addi	a1,a1,1
    80000f7a:	0785                	addi	a5,a5,1
    80000f7c:	fff5c703          	lbu	a4,-1(a1)
    80000f80:	fee78fa3          	sb	a4,-1(a5)
    80000f84:	fb65                	bnez	a4,80000f74 <safestrcpy+0x16>
    ;
  *s = 0;
    80000f86:	00078023          	sb	zero,0(a5)
  return os;
}
    80000f8a:	6422                	ld	s0,8(sp)
    80000f8c:	0141                	addi	sp,sp,16
    80000f8e:	8082                	ret

0000000080000f90 <strlen>:

int
strlen(const char *s)
{
    80000f90:	1141                	addi	sp,sp,-16
    80000f92:	e422                	sd	s0,8(sp)
    80000f94:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000f96:	00054783          	lbu	a5,0(a0)
    80000f9a:	cf91                	beqz	a5,80000fb6 <strlen+0x26>
    80000f9c:	0505                	addi	a0,a0,1
    80000f9e:	87aa                	mv	a5,a0
    80000fa0:	86be                	mv	a3,a5
    80000fa2:	0785                	addi	a5,a5,1
    80000fa4:	fff7c703          	lbu	a4,-1(a5)
    80000fa8:	ff65                	bnez	a4,80000fa0 <strlen+0x10>
    80000faa:	40a6853b          	subw	a0,a3,a0
    80000fae:	2505                	addiw	a0,a0,1
    ;
  return n;
}
    80000fb0:	6422                	ld	s0,8(sp)
    80000fb2:	0141                	addi	sp,sp,16
    80000fb4:	8082                	ret
  for(n = 0; s[n]; n++)
    80000fb6:	4501                	li	a0,0
    80000fb8:	bfe5                	j	80000fb0 <strlen+0x20>

0000000080000fba <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000fba:	1141                	addi	sp,sp,-16
    80000fbc:	e406                	sd	ra,8(sp)
    80000fbe:	e022                	sd	s0,0(sp)
    80000fc0:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000fc2:	00001097          	auipc	ra,0x1
    80000fc6:	bfe080e7          	jalr	-1026(ra) # 80001bc0 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000fca:	00008717          	auipc	a4,0x8
    80000fce:	a8e70713          	addi	a4,a4,-1394 # 80008a58 <started>
  if(cpuid() == 0){
    80000fd2:	c139                	beqz	a0,80001018 <main+0x5e>
    while(started == 0)
    80000fd4:	431c                	lw	a5,0(a4)
    80000fd6:	2781                	sext.w	a5,a5
    80000fd8:	dff5                	beqz	a5,80000fd4 <main+0x1a>
      ;
    __sync_synchronize();
    80000fda:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000fde:	00001097          	auipc	ra,0x1
    80000fe2:	be2080e7          	jalr	-1054(ra) # 80001bc0 <cpuid>
    80000fe6:	85aa                	mv	a1,a0
    80000fe8:	00007517          	auipc	a0,0x7
    80000fec:	11050513          	addi	a0,a0,272 # 800080f8 <digits+0xa8>
    80000ff0:	fffff097          	auipc	ra,0xfffff
    80000ff4:	5a8080e7          	jalr	1448(ra) # 80000598 <printf>
    kvminithart();    // turn on paging
    80000ff8:	00000097          	auipc	ra,0x0
    80000ffc:	0d8080e7          	jalr	216(ra) # 800010d0 <kvminithart>
    trapinithart();   // install kernel trap vector
    80001000:	00002097          	auipc	ra,0x2
    80001004:	a84080e7          	jalr	-1404(ra) # 80002a84 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80001008:	00005097          	auipc	ra,0x5
    8000100c:	188080e7          	jalr	392(ra) # 80006190 <plicinithart>
  }

  scheduler();        
    80001010:	00001097          	auipc	ra,0x1
    80001014:	222080e7          	jalr	546(ra) # 80002232 <scheduler>
    consoleinit();
    80001018:	fffff097          	auipc	ra,0xfffff
    8000101c:	434080e7          	jalr	1076(ra) # 8000044c <consoleinit>
    printfinit();
    80001020:	fffff097          	auipc	ra,0xfffff
    80001024:	758080e7          	jalr	1880(ra) # 80000778 <printfinit>
    printf("\n");
    80001028:	00007517          	auipc	a0,0x7
    8000102c:	06050513          	addi	a0,a0,96 # 80008088 <digits+0x38>
    80001030:	fffff097          	auipc	ra,0xfffff
    80001034:	568080e7          	jalr	1384(ra) # 80000598 <printf>
    printf("xv6 kernel is booting\n");
    80001038:	00007517          	auipc	a0,0x7
    8000103c:	0a850513          	addi	a0,a0,168 # 800080e0 <digits+0x90>
    80001040:	fffff097          	auipc	ra,0xfffff
    80001044:	558080e7          	jalr	1368(ra) # 80000598 <printf>
    printf("\n");
    80001048:	00007517          	auipc	a0,0x7
    8000104c:	04050513          	addi	a0,a0,64 # 80008088 <digits+0x38>
    80001050:	fffff097          	auipc	ra,0xfffff
    80001054:	548080e7          	jalr	1352(ra) # 80000598 <printf>
    kinit();         // physical page allocator
    80001058:	00000097          	auipc	ra,0x0
    8000105c:	aba080e7          	jalr	-1350(ra) # 80000b12 <kinit>
    kvminit();       // create kernel page table
    80001060:	00000097          	auipc	ra,0x0
    80001064:	326080e7          	jalr	806(ra) # 80001386 <kvminit>
    kvminithart();   // turn on paging
    80001068:	00000097          	auipc	ra,0x0
    8000106c:	068080e7          	jalr	104(ra) # 800010d0 <kvminithart>
    procinit();      // process table
    80001070:	00001097          	auipc	ra,0x1
    80001074:	a78080e7          	jalr	-1416(ra) # 80001ae8 <procinit>
    trapinit();      // trap vectors
    80001078:	00002097          	auipc	ra,0x2
    8000107c:	9e4080e7          	jalr	-1564(ra) # 80002a5c <trapinit>
    trapinithart();  // install kernel trap vector
    80001080:	00002097          	auipc	ra,0x2
    80001084:	a04080e7          	jalr	-1532(ra) # 80002a84 <trapinithart>
    plicinit();      // set up interrupt controller
    80001088:	00005097          	auipc	ra,0x5
    8000108c:	0f2080e7          	jalr	242(ra) # 8000617a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80001090:	00005097          	auipc	ra,0x5
    80001094:	100080e7          	jalr	256(ra) # 80006190 <plicinithart>
    binit();         // buffer cache
    80001098:	00002097          	auipc	ra,0x2
    8000109c:	2fe080e7          	jalr	766(ra) # 80003396 <binit>
    iinit();         // inode table
    800010a0:	00003097          	auipc	ra,0x3
    800010a4:	99c080e7          	jalr	-1636(ra) # 80003a3c <iinit>
    fileinit();      // file table
    800010a8:	00004097          	auipc	ra,0x4
    800010ac:	912080e7          	jalr	-1774(ra) # 800049ba <fileinit>
    virtio_disk_init(); // emulated hard disk
    800010b0:	00005097          	auipc	ra,0x5
    800010b4:	1e8080e7          	jalr	488(ra) # 80006298 <virtio_disk_init>
    userinit();      // first user process
    800010b8:	00001097          	auipc	ra,0x1
    800010bc:	e0c080e7          	jalr	-500(ra) # 80001ec4 <userinit>
    __sync_synchronize();
    800010c0:	0ff0000f          	fence
    started = 1;
    800010c4:	4785                	li	a5,1
    800010c6:	00008717          	auipc	a4,0x8
    800010ca:	98f72923          	sw	a5,-1646(a4) # 80008a58 <started>
    800010ce:	b789                	j	80001010 <main+0x56>

00000000800010d0 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    800010d0:	1141                	addi	sp,sp,-16
    800010d2:	e422                	sd	s0,8(sp)
    800010d4:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    800010d6:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    800010da:	00008797          	auipc	a5,0x8
    800010de:	9867b783          	ld	a5,-1658(a5) # 80008a60 <kernel_pagetable>
    800010e2:	83b1                	srli	a5,a5,0xc
    800010e4:	577d                	li	a4,-1
    800010e6:	177e                	slli	a4,a4,0x3f
    800010e8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    800010ea:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    800010ee:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    800010f2:	6422                	ld	s0,8(sp)
    800010f4:	0141                	addi	sp,sp,16
    800010f6:	8082                	ret

00000000800010f8 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    800010f8:	7139                	addi	sp,sp,-64
    800010fa:	fc06                	sd	ra,56(sp)
    800010fc:	f822                	sd	s0,48(sp)
    800010fe:	f426                	sd	s1,40(sp)
    80001100:	f04a                	sd	s2,32(sp)
    80001102:	ec4e                	sd	s3,24(sp)
    80001104:	e852                	sd	s4,16(sp)
    80001106:	e456                	sd	s5,8(sp)
    80001108:	e05a                	sd	s6,0(sp)
    8000110a:	0080                	addi	s0,sp,64
    8000110c:	84aa                	mv	s1,a0
    8000110e:	89ae                	mv	s3,a1
    80001110:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001112:	57fd                	li	a5,-1
    80001114:	83e9                	srli	a5,a5,0x1a
    80001116:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001118:	4b31                	li	s6,12
  if(va >= MAXVA)
    8000111a:	04b7f263          	bgeu	a5,a1,8000115e <walk+0x66>
    panic("walk");
    8000111e:	00007517          	auipc	a0,0x7
    80001122:	ff250513          	addi	a0,a0,-14 # 80008110 <digits+0xc0>
    80001126:	fffff097          	auipc	ra,0xfffff
    8000112a:	416080e7          	jalr	1046(ra) # 8000053c <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    8000112e:	060a8663          	beqz	s5,8000119a <walk+0xa2>
    80001132:	00000097          	auipc	ra,0x0
    80001136:	a5e080e7          	jalr	-1442(ra) # 80000b90 <kalloc>
    8000113a:	84aa                	mv	s1,a0
    8000113c:	c529                	beqz	a0,80001186 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000113e:	6605                	lui	a2,0x1
    80001140:	4581                	li	a1,0
    80001142:	00000097          	auipc	ra,0x0
    80001146:	cd4080e7          	jalr	-812(ra) # 80000e16 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000114a:	00c4d793          	srli	a5,s1,0xc
    8000114e:	07aa                	slli	a5,a5,0xa
    80001150:	0017e793          	ori	a5,a5,1
    80001154:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001158:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffbd107>
    8000115a:	036a0063          	beq	s4,s6,8000117a <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000115e:	0149d933          	srl	s2,s3,s4
    80001162:	1ff97913          	andi	s2,s2,511
    80001166:	090e                	slli	s2,s2,0x3
    80001168:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000116a:	00093483          	ld	s1,0(s2)
    8000116e:	0014f793          	andi	a5,s1,1
    80001172:	dfd5                	beqz	a5,8000112e <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001174:	80a9                	srli	s1,s1,0xa
    80001176:	04b2                	slli	s1,s1,0xc
    80001178:	b7c5                	j	80001158 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000117a:	00c9d513          	srli	a0,s3,0xc
    8000117e:	1ff57513          	andi	a0,a0,511
    80001182:	050e                	slli	a0,a0,0x3
    80001184:	9526                	add	a0,a0,s1
}
    80001186:	70e2                	ld	ra,56(sp)
    80001188:	7442                	ld	s0,48(sp)
    8000118a:	74a2                	ld	s1,40(sp)
    8000118c:	7902                	ld	s2,32(sp)
    8000118e:	69e2                	ld	s3,24(sp)
    80001190:	6a42                	ld	s4,16(sp)
    80001192:	6aa2                	ld	s5,8(sp)
    80001194:	6b02                	ld	s6,0(sp)
    80001196:	6121                	addi	sp,sp,64
    80001198:	8082                	ret
        return 0;
    8000119a:	4501                	li	a0,0
    8000119c:	b7ed                	j	80001186 <walk+0x8e>

000000008000119e <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000119e:	57fd                	li	a5,-1
    800011a0:	83e9                	srli	a5,a5,0x1a
    800011a2:	00b7f463          	bgeu	a5,a1,800011aa <walkaddr+0xc>
    return 0;
    800011a6:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800011a8:	8082                	ret
{
    800011aa:	1141                	addi	sp,sp,-16
    800011ac:	e406                	sd	ra,8(sp)
    800011ae:	e022                	sd	s0,0(sp)
    800011b0:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800011b2:	4601                	li	a2,0
    800011b4:	00000097          	auipc	ra,0x0
    800011b8:	f44080e7          	jalr	-188(ra) # 800010f8 <walk>
  if(pte == 0)
    800011bc:	c105                	beqz	a0,800011dc <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800011be:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800011c0:	0117f693          	andi	a3,a5,17
    800011c4:	4745                	li	a4,17
    return 0;
    800011c6:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800011c8:	00e68663          	beq	a3,a4,800011d4 <walkaddr+0x36>
}
    800011cc:	60a2                	ld	ra,8(sp)
    800011ce:	6402                	ld	s0,0(sp)
    800011d0:	0141                	addi	sp,sp,16
    800011d2:	8082                	ret
  pa = PTE2PA(*pte);
    800011d4:	83a9                	srli	a5,a5,0xa
    800011d6:	00c79513          	slli	a0,a5,0xc
  return pa;
    800011da:	bfcd                	j	800011cc <walkaddr+0x2e>
    return 0;
    800011dc:	4501                	li	a0,0
    800011de:	b7fd                	j	800011cc <walkaddr+0x2e>

00000000800011e0 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800011e0:	715d                	addi	sp,sp,-80
    800011e2:	e486                	sd	ra,72(sp)
    800011e4:	e0a2                	sd	s0,64(sp)
    800011e6:	fc26                	sd	s1,56(sp)
    800011e8:	f84a                	sd	s2,48(sp)
    800011ea:	f44e                	sd	s3,40(sp)
    800011ec:	f052                	sd	s4,32(sp)
    800011ee:	ec56                	sd	s5,24(sp)
    800011f0:	e85a                	sd	s6,16(sp)
    800011f2:	e45e                	sd	s7,8(sp)
    800011f4:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800011f6:	c639                	beqz	a2,80001244 <mappages+0x64>
    800011f8:	8aaa                	mv	s5,a0
    800011fa:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800011fc:	777d                	lui	a4,0xfffff
    800011fe:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    80001202:	fff58993          	addi	s3,a1,-1
    80001206:	99b2                	add	s3,s3,a2
    80001208:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    8000120c:	893e                	mv	s2,a5
    8000120e:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001212:	6b85                	lui	s7,0x1
    80001214:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001218:	4605                	li	a2,1
    8000121a:	85ca                	mv	a1,s2
    8000121c:	8556                	mv	a0,s5
    8000121e:	00000097          	auipc	ra,0x0
    80001222:	eda080e7          	jalr	-294(ra) # 800010f8 <walk>
    80001226:	cd1d                	beqz	a0,80001264 <mappages+0x84>
    if(*pte & PTE_V)
    80001228:	611c                	ld	a5,0(a0)
    8000122a:	8b85                	andi	a5,a5,1
    8000122c:	e785                	bnez	a5,80001254 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000122e:	80b1                	srli	s1,s1,0xc
    80001230:	04aa                	slli	s1,s1,0xa
    80001232:	0164e4b3          	or	s1,s1,s6
    80001236:	0014e493          	ori	s1,s1,1
    8000123a:	e104                	sd	s1,0(a0)
    if(a == last)
    8000123c:	05390063          	beq	s2,s3,8000127c <mappages+0x9c>
    a += PGSIZE;
    80001240:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001242:	bfc9                	j	80001214 <mappages+0x34>
    panic("mappages: size");
    80001244:	00007517          	auipc	a0,0x7
    80001248:	ed450513          	addi	a0,a0,-300 # 80008118 <digits+0xc8>
    8000124c:	fffff097          	auipc	ra,0xfffff
    80001250:	2f0080e7          	jalr	752(ra) # 8000053c <panic>
      panic("mappages: remap");
    80001254:	00007517          	auipc	a0,0x7
    80001258:	ed450513          	addi	a0,a0,-300 # 80008128 <digits+0xd8>
    8000125c:	fffff097          	auipc	ra,0xfffff
    80001260:	2e0080e7          	jalr	736(ra) # 8000053c <panic>
      return -1;
    80001264:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001266:	60a6                	ld	ra,72(sp)
    80001268:	6406                	ld	s0,64(sp)
    8000126a:	74e2                	ld	s1,56(sp)
    8000126c:	7942                	ld	s2,48(sp)
    8000126e:	79a2                	ld	s3,40(sp)
    80001270:	7a02                	ld	s4,32(sp)
    80001272:	6ae2                	ld	s5,24(sp)
    80001274:	6b42                	ld	s6,16(sp)
    80001276:	6ba2                	ld	s7,8(sp)
    80001278:	6161                	addi	sp,sp,80
    8000127a:	8082                	ret
  return 0;
    8000127c:	4501                	li	a0,0
    8000127e:	b7e5                	j	80001266 <mappages+0x86>

0000000080001280 <kvmmap>:
{
    80001280:	1141                	addi	sp,sp,-16
    80001282:	e406                	sd	ra,8(sp)
    80001284:	e022                	sd	s0,0(sp)
    80001286:	0800                	addi	s0,sp,16
    80001288:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000128a:	86b2                	mv	a3,a2
    8000128c:	863e                	mv	a2,a5
    8000128e:	00000097          	auipc	ra,0x0
    80001292:	f52080e7          	jalr	-174(ra) # 800011e0 <mappages>
    80001296:	e509                	bnez	a0,800012a0 <kvmmap+0x20>
}
    80001298:	60a2                	ld	ra,8(sp)
    8000129a:	6402                	ld	s0,0(sp)
    8000129c:	0141                	addi	sp,sp,16
    8000129e:	8082                	ret
    panic("kvmmap");
    800012a0:	00007517          	auipc	a0,0x7
    800012a4:	e9850513          	addi	a0,a0,-360 # 80008138 <digits+0xe8>
    800012a8:	fffff097          	auipc	ra,0xfffff
    800012ac:	294080e7          	jalr	660(ra) # 8000053c <panic>

00000000800012b0 <kvmmake>:
{
    800012b0:	1101                	addi	sp,sp,-32
    800012b2:	ec06                	sd	ra,24(sp)
    800012b4:	e822                	sd	s0,16(sp)
    800012b6:	e426                	sd	s1,8(sp)
    800012b8:	e04a                	sd	s2,0(sp)
    800012ba:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    800012bc:	00000097          	auipc	ra,0x0
    800012c0:	8d4080e7          	jalr	-1836(ra) # 80000b90 <kalloc>
    800012c4:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800012c6:	6605                	lui	a2,0x1
    800012c8:	4581                	li	a1,0
    800012ca:	00000097          	auipc	ra,0x0
    800012ce:	b4c080e7          	jalr	-1204(ra) # 80000e16 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800012d2:	4719                	li	a4,6
    800012d4:	6685                	lui	a3,0x1
    800012d6:	10000637          	lui	a2,0x10000
    800012da:	100005b7          	lui	a1,0x10000
    800012de:	8526                	mv	a0,s1
    800012e0:	00000097          	auipc	ra,0x0
    800012e4:	fa0080e7          	jalr	-96(ra) # 80001280 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800012e8:	4719                	li	a4,6
    800012ea:	6685                	lui	a3,0x1
    800012ec:	10001637          	lui	a2,0x10001
    800012f0:	100015b7          	lui	a1,0x10001
    800012f4:	8526                	mv	a0,s1
    800012f6:	00000097          	auipc	ra,0x0
    800012fa:	f8a080e7          	jalr	-118(ra) # 80001280 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800012fe:	4719                	li	a4,6
    80001300:	004006b7          	lui	a3,0x400
    80001304:	0c000637          	lui	a2,0xc000
    80001308:	0c0005b7          	lui	a1,0xc000
    8000130c:	8526                	mv	a0,s1
    8000130e:	00000097          	auipc	ra,0x0
    80001312:	f72080e7          	jalr	-142(ra) # 80001280 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001316:	00007917          	auipc	s2,0x7
    8000131a:	cea90913          	addi	s2,s2,-790 # 80008000 <etext>
    8000131e:	4729                	li	a4,10
    80001320:	80007697          	auipc	a3,0x80007
    80001324:	ce068693          	addi	a3,a3,-800 # 8000 <_entry-0x7fff8000>
    80001328:	4605                	li	a2,1
    8000132a:	067e                	slli	a2,a2,0x1f
    8000132c:	85b2                	mv	a1,a2
    8000132e:	8526                	mv	a0,s1
    80001330:	00000097          	auipc	ra,0x0
    80001334:	f50080e7          	jalr	-176(ra) # 80001280 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001338:	4719                	li	a4,6
    8000133a:	46c5                	li	a3,17
    8000133c:	06ee                	slli	a3,a3,0x1b
    8000133e:	412686b3          	sub	a3,a3,s2
    80001342:	864a                	mv	a2,s2
    80001344:	85ca                	mv	a1,s2
    80001346:	8526                	mv	a0,s1
    80001348:	00000097          	auipc	ra,0x0
    8000134c:	f38080e7          	jalr	-200(ra) # 80001280 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001350:	4729                	li	a4,10
    80001352:	6685                	lui	a3,0x1
    80001354:	00006617          	auipc	a2,0x6
    80001358:	cac60613          	addi	a2,a2,-852 # 80007000 <_trampoline>
    8000135c:	040005b7          	lui	a1,0x4000
    80001360:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001362:	05b2                	slli	a1,a1,0xc
    80001364:	8526                	mv	a0,s1
    80001366:	00000097          	auipc	ra,0x0
    8000136a:	f1a080e7          	jalr	-230(ra) # 80001280 <kvmmap>
  proc_mapstacks(kpgtbl);
    8000136e:	8526                	mv	a0,s1
    80001370:	00000097          	auipc	ra,0x0
    80001374:	6e2080e7          	jalr	1762(ra) # 80001a52 <proc_mapstacks>
}
    80001378:	8526                	mv	a0,s1
    8000137a:	60e2                	ld	ra,24(sp)
    8000137c:	6442                	ld	s0,16(sp)
    8000137e:	64a2                	ld	s1,8(sp)
    80001380:	6902                	ld	s2,0(sp)
    80001382:	6105                	addi	sp,sp,32
    80001384:	8082                	ret

0000000080001386 <kvminit>:
{
    80001386:	1141                	addi	sp,sp,-16
    80001388:	e406                	sd	ra,8(sp)
    8000138a:	e022                	sd	s0,0(sp)
    8000138c:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000138e:	00000097          	auipc	ra,0x0
    80001392:	f22080e7          	jalr	-222(ra) # 800012b0 <kvmmake>
    80001396:	00007797          	auipc	a5,0x7
    8000139a:	6ca7b523          	sd	a0,1738(a5) # 80008a60 <kernel_pagetable>
}
    8000139e:	60a2                	ld	ra,8(sp)
    800013a0:	6402                	ld	s0,0(sp)
    800013a2:	0141                	addi	sp,sp,16
    800013a4:	8082                	ret

00000000800013a6 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800013a6:	715d                	addi	sp,sp,-80
    800013a8:	e486                	sd	ra,72(sp)
    800013aa:	e0a2                	sd	s0,64(sp)
    800013ac:	fc26                	sd	s1,56(sp)
    800013ae:	f84a                	sd	s2,48(sp)
    800013b0:	f44e                	sd	s3,40(sp)
    800013b2:	f052                	sd	s4,32(sp)
    800013b4:	ec56                	sd	s5,24(sp)
    800013b6:	e85a                	sd	s6,16(sp)
    800013b8:	e45e                	sd	s7,8(sp)
    800013ba:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800013bc:	03459793          	slli	a5,a1,0x34
    800013c0:	e795                	bnez	a5,800013ec <uvmunmap+0x46>
    800013c2:	8a2a                	mv	s4,a0
    800013c4:	892e                	mv	s2,a1
    800013c6:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013c8:	0632                	slli	a2,a2,0xc
    800013ca:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800013ce:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013d0:	6b05                	lui	s6,0x1
    800013d2:	0735e263          	bltu	a1,s3,80001436 <uvmunmap+0x90>
      //kfree((void*)pa);
      decrement_reference_counter((void*)pa);
    }
    *pte = 0;
  }
}
    800013d6:	60a6                	ld	ra,72(sp)
    800013d8:	6406                	ld	s0,64(sp)
    800013da:	74e2                	ld	s1,56(sp)
    800013dc:	7942                	ld	s2,48(sp)
    800013de:	79a2                	ld	s3,40(sp)
    800013e0:	7a02                	ld	s4,32(sp)
    800013e2:	6ae2                	ld	s5,24(sp)
    800013e4:	6b42                	ld	s6,16(sp)
    800013e6:	6ba2                	ld	s7,8(sp)
    800013e8:	6161                	addi	sp,sp,80
    800013ea:	8082                	ret
    panic("uvmunmap: not aligned");
    800013ec:	00007517          	auipc	a0,0x7
    800013f0:	d5450513          	addi	a0,a0,-684 # 80008140 <digits+0xf0>
    800013f4:	fffff097          	auipc	ra,0xfffff
    800013f8:	148080e7          	jalr	328(ra) # 8000053c <panic>
      panic("uvmunmap: walk");
    800013fc:	00007517          	auipc	a0,0x7
    80001400:	d5c50513          	addi	a0,a0,-676 # 80008158 <digits+0x108>
    80001404:	fffff097          	auipc	ra,0xfffff
    80001408:	138080e7          	jalr	312(ra) # 8000053c <panic>
      panic("uvmunmap: not mapped");
    8000140c:	00007517          	auipc	a0,0x7
    80001410:	d5c50513          	addi	a0,a0,-676 # 80008168 <digits+0x118>
    80001414:	fffff097          	auipc	ra,0xfffff
    80001418:	128080e7          	jalr	296(ra) # 8000053c <panic>
      panic("uvmunmap: not a leaf");
    8000141c:	00007517          	auipc	a0,0x7
    80001420:	d6450513          	addi	a0,a0,-668 # 80008180 <digits+0x130>
    80001424:	fffff097          	auipc	ra,0xfffff
    80001428:	118080e7          	jalr	280(ra) # 8000053c <panic>
    *pte = 0;
    8000142c:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001430:	995a                	add	s2,s2,s6
    80001432:	fb3972e3          	bgeu	s2,s3,800013d6 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001436:	4601                	li	a2,0
    80001438:	85ca                	mv	a1,s2
    8000143a:	8552                	mv	a0,s4
    8000143c:	00000097          	auipc	ra,0x0
    80001440:	cbc080e7          	jalr	-836(ra) # 800010f8 <walk>
    80001444:	84aa                	mv	s1,a0
    80001446:	d95d                	beqz	a0,800013fc <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001448:	6108                	ld	a0,0(a0)
    8000144a:	00157793          	andi	a5,a0,1
    8000144e:	dfdd                	beqz	a5,8000140c <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001450:	3ff57793          	andi	a5,a0,1023
    80001454:	fd7784e3          	beq	a5,s7,8000141c <uvmunmap+0x76>
    if(do_free){
    80001458:	fc0a8ae3          	beqz	s5,8000142c <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    8000145c:	8129                	srli	a0,a0,0xa
      decrement_reference_counter((void*)pa);
    8000145e:	0532                	slli	a0,a0,0xc
    80001460:	fffff097          	auipc	ra,0xfffff
    80001464:	7e6080e7          	jalr	2022(ra) # 80000c46 <decrement_reference_counter>
    80001468:	b7d1                	j	8000142c <uvmunmap+0x86>

000000008000146a <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000146a:	1101                	addi	sp,sp,-32
    8000146c:	ec06                	sd	ra,24(sp)
    8000146e:	e822                	sd	s0,16(sp)
    80001470:	e426                	sd	s1,8(sp)
    80001472:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001474:	fffff097          	auipc	ra,0xfffff
    80001478:	71c080e7          	jalr	1820(ra) # 80000b90 <kalloc>
    8000147c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000147e:	c519                	beqz	a0,8000148c <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001480:	6605                	lui	a2,0x1
    80001482:	4581                	li	a1,0
    80001484:	00000097          	auipc	ra,0x0
    80001488:	992080e7          	jalr	-1646(ra) # 80000e16 <memset>
  return pagetable;
}
    8000148c:	8526                	mv	a0,s1
    8000148e:	60e2                	ld	ra,24(sp)
    80001490:	6442                	ld	s0,16(sp)
    80001492:	64a2                	ld	s1,8(sp)
    80001494:	6105                	addi	sp,sp,32
    80001496:	8082                	ret

0000000080001498 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001498:	7179                	addi	sp,sp,-48
    8000149a:	f406                	sd	ra,40(sp)
    8000149c:	f022                	sd	s0,32(sp)
    8000149e:	ec26                	sd	s1,24(sp)
    800014a0:	e84a                	sd	s2,16(sp)
    800014a2:	e44e                	sd	s3,8(sp)
    800014a4:	e052                	sd	s4,0(sp)
    800014a6:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800014a8:	6785                	lui	a5,0x1
    800014aa:	04f67863          	bgeu	a2,a5,800014fa <uvmfirst+0x62>
    800014ae:	8a2a                	mv	s4,a0
    800014b0:	89ae                	mv	s3,a1
    800014b2:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    800014b4:	fffff097          	auipc	ra,0xfffff
    800014b8:	6dc080e7          	jalr	1756(ra) # 80000b90 <kalloc>
    800014bc:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800014be:	6605                	lui	a2,0x1
    800014c0:	4581                	li	a1,0
    800014c2:	00000097          	auipc	ra,0x0
    800014c6:	954080e7          	jalr	-1708(ra) # 80000e16 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800014ca:	4779                	li	a4,30
    800014cc:	86ca                	mv	a3,s2
    800014ce:	6605                	lui	a2,0x1
    800014d0:	4581                	li	a1,0
    800014d2:	8552                	mv	a0,s4
    800014d4:	00000097          	auipc	ra,0x0
    800014d8:	d0c080e7          	jalr	-756(ra) # 800011e0 <mappages>
  memmove(mem, src, sz);
    800014dc:	8626                	mv	a2,s1
    800014de:	85ce                	mv	a1,s3
    800014e0:	854a                	mv	a0,s2
    800014e2:	00000097          	auipc	ra,0x0
    800014e6:	990080e7          	jalr	-1648(ra) # 80000e72 <memmove>
}
    800014ea:	70a2                	ld	ra,40(sp)
    800014ec:	7402                	ld	s0,32(sp)
    800014ee:	64e2                	ld	s1,24(sp)
    800014f0:	6942                	ld	s2,16(sp)
    800014f2:	69a2                	ld	s3,8(sp)
    800014f4:	6a02                	ld	s4,0(sp)
    800014f6:	6145                	addi	sp,sp,48
    800014f8:	8082                	ret
    panic("uvmfirst: more than a page");
    800014fa:	00007517          	auipc	a0,0x7
    800014fe:	c9e50513          	addi	a0,a0,-866 # 80008198 <digits+0x148>
    80001502:	fffff097          	auipc	ra,0xfffff
    80001506:	03a080e7          	jalr	58(ra) # 8000053c <panic>

000000008000150a <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    8000150a:	1101                	addi	sp,sp,-32
    8000150c:	ec06                	sd	ra,24(sp)
    8000150e:	e822                	sd	s0,16(sp)
    80001510:	e426                	sd	s1,8(sp)
    80001512:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001514:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001516:	00b67d63          	bgeu	a2,a1,80001530 <uvmdealloc+0x26>
    8000151a:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    8000151c:	6785                	lui	a5,0x1
    8000151e:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001520:	00f60733          	add	a4,a2,a5
    80001524:	76fd                	lui	a3,0xfffff
    80001526:	8f75                	and	a4,a4,a3
    80001528:	97ae                	add	a5,a5,a1
    8000152a:	8ff5                	and	a5,a5,a3
    8000152c:	00f76863          	bltu	a4,a5,8000153c <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001530:	8526                	mv	a0,s1
    80001532:	60e2                	ld	ra,24(sp)
    80001534:	6442                	ld	s0,16(sp)
    80001536:	64a2                	ld	s1,8(sp)
    80001538:	6105                	addi	sp,sp,32
    8000153a:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000153c:	8f99                	sub	a5,a5,a4
    8000153e:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001540:	4685                	li	a3,1
    80001542:	0007861b          	sext.w	a2,a5
    80001546:	85ba                	mv	a1,a4
    80001548:	00000097          	auipc	ra,0x0
    8000154c:	e5e080e7          	jalr	-418(ra) # 800013a6 <uvmunmap>
    80001550:	b7c5                	j	80001530 <uvmdealloc+0x26>

0000000080001552 <uvmalloc>:
  if(newsz < oldsz)
    80001552:	0ab66563          	bltu	a2,a1,800015fc <uvmalloc+0xaa>
{
    80001556:	7139                	addi	sp,sp,-64
    80001558:	fc06                	sd	ra,56(sp)
    8000155a:	f822                	sd	s0,48(sp)
    8000155c:	f426                	sd	s1,40(sp)
    8000155e:	f04a                	sd	s2,32(sp)
    80001560:	ec4e                	sd	s3,24(sp)
    80001562:	e852                	sd	s4,16(sp)
    80001564:	e456                	sd	s5,8(sp)
    80001566:	e05a                	sd	s6,0(sp)
    80001568:	0080                	addi	s0,sp,64
    8000156a:	8aaa                	mv	s5,a0
    8000156c:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000156e:	6785                	lui	a5,0x1
    80001570:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001572:	95be                	add	a1,a1,a5
    80001574:	77fd                	lui	a5,0xfffff
    80001576:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000157a:	08c9f363          	bgeu	s3,a2,80001600 <uvmalloc+0xae>
    8000157e:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001580:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    80001584:	fffff097          	auipc	ra,0xfffff
    80001588:	60c080e7          	jalr	1548(ra) # 80000b90 <kalloc>
    8000158c:	84aa                	mv	s1,a0
    if(mem == 0){
    8000158e:	c51d                	beqz	a0,800015bc <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    80001590:	6605                	lui	a2,0x1
    80001592:	4581                	li	a1,0
    80001594:	00000097          	auipc	ra,0x0
    80001598:	882080e7          	jalr	-1918(ra) # 80000e16 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000159c:	875a                	mv	a4,s6
    8000159e:	86a6                	mv	a3,s1
    800015a0:	6605                	lui	a2,0x1
    800015a2:	85ca                	mv	a1,s2
    800015a4:	8556                	mv	a0,s5
    800015a6:	00000097          	auipc	ra,0x0
    800015aa:	c3a080e7          	jalr	-966(ra) # 800011e0 <mappages>
    800015ae:	e90d                	bnez	a0,800015e0 <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800015b0:	6785                	lui	a5,0x1
    800015b2:	993e                	add	s2,s2,a5
    800015b4:	fd4968e3          	bltu	s2,s4,80001584 <uvmalloc+0x32>
  return newsz;
    800015b8:	8552                	mv	a0,s4
    800015ba:	a809                	j	800015cc <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    800015bc:	864e                	mv	a2,s3
    800015be:	85ca                	mv	a1,s2
    800015c0:	8556                	mv	a0,s5
    800015c2:	00000097          	auipc	ra,0x0
    800015c6:	f48080e7          	jalr	-184(ra) # 8000150a <uvmdealloc>
      return 0;
    800015ca:	4501                	li	a0,0
}
    800015cc:	70e2                	ld	ra,56(sp)
    800015ce:	7442                	ld	s0,48(sp)
    800015d0:	74a2                	ld	s1,40(sp)
    800015d2:	7902                	ld	s2,32(sp)
    800015d4:	69e2                	ld	s3,24(sp)
    800015d6:	6a42                	ld	s4,16(sp)
    800015d8:	6aa2                	ld	s5,8(sp)
    800015da:	6b02                	ld	s6,0(sp)
    800015dc:	6121                	addi	sp,sp,64
    800015de:	8082                	ret
      decrement_reference_counter(mem);
    800015e0:	8526                	mv	a0,s1
    800015e2:	fffff097          	auipc	ra,0xfffff
    800015e6:	664080e7          	jalr	1636(ra) # 80000c46 <decrement_reference_counter>
      uvmdealloc(pagetable, a, oldsz);
    800015ea:	864e                	mv	a2,s3
    800015ec:	85ca                	mv	a1,s2
    800015ee:	8556                	mv	a0,s5
    800015f0:	00000097          	auipc	ra,0x0
    800015f4:	f1a080e7          	jalr	-230(ra) # 8000150a <uvmdealloc>
      return 0;
    800015f8:	4501                	li	a0,0
    800015fa:	bfc9                	j	800015cc <uvmalloc+0x7a>
    return oldsz;
    800015fc:	852e                	mv	a0,a1
}
    800015fe:	8082                	ret
  return newsz;
    80001600:	8532                	mv	a0,a2
    80001602:	b7e9                	j	800015cc <uvmalloc+0x7a>

0000000080001604 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001604:	7179                	addi	sp,sp,-48
    80001606:	f406                	sd	ra,40(sp)
    80001608:	f022                	sd	s0,32(sp)
    8000160a:	ec26                	sd	s1,24(sp)
    8000160c:	e84a                	sd	s2,16(sp)
    8000160e:	e44e                	sd	s3,8(sp)
    80001610:	e052                	sd	s4,0(sp)
    80001612:	1800                	addi	s0,sp,48
    80001614:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001616:	84aa                	mv	s1,a0
    80001618:	6905                	lui	s2,0x1
    8000161a:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000161c:	4985                	li	s3,1
    8000161e:	a829                	j	80001638 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001620:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    80001622:	00c79513          	slli	a0,a5,0xc
    80001626:	00000097          	auipc	ra,0x0
    8000162a:	fde080e7          	jalr	-34(ra) # 80001604 <freewalk>
      pagetable[i] = 0;
    8000162e:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001632:	04a1                	addi	s1,s1,8
    80001634:	03248163          	beq	s1,s2,80001656 <freewalk+0x52>
    pte_t pte = pagetable[i];
    80001638:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000163a:	00f7f713          	andi	a4,a5,15
    8000163e:	ff3701e3          	beq	a4,s3,80001620 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001642:	8b85                	andi	a5,a5,1
    80001644:	d7fd                	beqz	a5,80001632 <freewalk+0x2e>
      panic("freewalk: leaf");
    80001646:	00007517          	auipc	a0,0x7
    8000164a:	b7250513          	addi	a0,a0,-1166 # 800081b8 <digits+0x168>
    8000164e:	fffff097          	auipc	ra,0xfffff
    80001652:	eee080e7          	jalr	-274(ra) # 8000053c <panic>
    }
  }
  //kfree((void*)pagetable);
  decrement_reference_counter((void*)pagetable);
    80001656:	8552                	mv	a0,s4
    80001658:	fffff097          	auipc	ra,0xfffff
    8000165c:	5ee080e7          	jalr	1518(ra) # 80000c46 <decrement_reference_counter>
}
    80001660:	70a2                	ld	ra,40(sp)
    80001662:	7402                	ld	s0,32(sp)
    80001664:	64e2                	ld	s1,24(sp)
    80001666:	6942                	ld	s2,16(sp)
    80001668:	69a2                	ld	s3,8(sp)
    8000166a:	6a02                	ld	s4,0(sp)
    8000166c:	6145                	addi	sp,sp,48
    8000166e:	8082                	ret

0000000080001670 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001670:	1101                	addi	sp,sp,-32
    80001672:	ec06                	sd	ra,24(sp)
    80001674:	e822                	sd	s0,16(sp)
    80001676:	e426                	sd	s1,8(sp)
    80001678:	1000                	addi	s0,sp,32
    8000167a:	84aa                	mv	s1,a0
  if(sz > 0)
    8000167c:	e999                	bnez	a1,80001692 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000167e:	8526                	mv	a0,s1
    80001680:	00000097          	auipc	ra,0x0
    80001684:	f84080e7          	jalr	-124(ra) # 80001604 <freewalk>
}
    80001688:	60e2                	ld	ra,24(sp)
    8000168a:	6442                	ld	s0,16(sp)
    8000168c:	64a2                	ld	s1,8(sp)
    8000168e:	6105                	addi	sp,sp,32
    80001690:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001692:	6785                	lui	a5,0x1
    80001694:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001696:	95be                	add	a1,a1,a5
    80001698:	4685                	li	a3,1
    8000169a:	00c5d613          	srli	a2,a1,0xc
    8000169e:	4581                	li	a1,0
    800016a0:	00000097          	auipc	ra,0x0
    800016a4:	d06080e7          	jalr	-762(ra) # 800013a6 <uvmunmap>
    800016a8:	bfd9                	j	8000167e <uvmfree+0xe>

00000000800016aa <uvmcopy>:
uvmcopy(pagetable_t old, pagetable_t new, uint64 sz)
{
    pte_t *pte;
    uint64 pa, i;

    for(i = 0; i < sz; i += PGSIZE){
    800016aa:	ce61                	beqz	a2,80001782 <uvmcopy+0xd8>
{
    800016ac:	7139                	addi	sp,sp,-64
    800016ae:	fc06                	sd	ra,56(sp)
    800016b0:	f822                	sd	s0,48(sp)
    800016b2:	f426                	sd	s1,40(sp)
    800016b4:	f04a                	sd	s2,32(sp)
    800016b6:	ec4e                	sd	s3,24(sp)
    800016b8:	e852                	sd	s4,16(sp)
    800016ba:	e456                	sd	s5,8(sp)
    800016bc:	e05a                	sd	s6,0(sp)
    800016be:	0080                	addi	s0,sp,64
    800016c0:	8a2a                	mv	s4,a0
    800016c2:	8aae                	mv	s5,a1
    800016c4:	8b32                	mv	s6,a2
    for(i = 0; i < sz; i += PGSIZE){
    800016c6:	4901                	li	s2,0
        if((pte = walk(old, i, 0)) == 0)
    800016c8:	4601                	li	a2,0
    800016ca:	85ca                	mv	a1,s2
    800016cc:	8552                	mv	a0,s4
    800016ce:	00000097          	auipc	ra,0x0
    800016d2:	a2a080e7          	jalr	-1494(ra) # 800010f8 <walk>
    800016d6:	c135                	beqz	a0,8000173a <uvmcopy+0x90>
            panic("uvmcopy: pte should exist");
        if((*pte & PTE_V) == 0)
    800016d8:	6118                	ld	a4,0(a0)
    800016da:	00177793          	andi	a5,a4,1
    800016de:	c7b5                	beqz	a5,8000174a <uvmcopy+0xa0>
            panic("uvmcopy: page not present");
        pa = PTE2PA(*pte);
    800016e0:	00a75993          	srli	s3,a4,0xa
    800016e4:	09b2                	slli	s3,s3,0xc
        uint flags = PTE_FLAGS(*pte);
        flags |= PTE_COW;
        flags &= ~PTE_W;
    800016e6:	3fb77713          	andi	a4,a4,1019

        if(mappages(new, i, PGSIZE, pa, flags) == 0){
    800016ea:	00876493          	ori	s1,a4,8
    800016ee:	8726                	mv	a4,s1
    800016f0:	86ce                	mv	a3,s3
    800016f2:	6605                	lui	a2,0x1
    800016f4:	85ca                	mv	a1,s2
    800016f6:	8556                	mv	a0,s5
    800016f8:	00000097          	auipc	ra,0x0
    800016fc:	ae8080e7          	jalr	-1304(ra) # 800011e0 <mappages>
    80001700:	ed29                	bnez	a0,8000175a <uvmcopy+0xb0>
          uvmunmap(old, i, 1, 0);
    80001702:	4681                	li	a3,0
    80001704:	4605                	li	a2,1
    80001706:	85ca                	mv	a1,s2
    80001708:	8552                	mv	a0,s4
    8000170a:	00000097          	auipc	ra,0x0
    8000170e:	c9c080e7          	jalr	-868(ra) # 800013a6 <uvmunmap>
          increment_reference_counter((void *)pa);
    80001712:	854e                	mv	a0,s3
    80001714:	fffff097          	auipc	ra,0xfffff
    80001718:	44a080e7          	jalr	1098(ra) # 80000b5e <increment_reference_counter>
        } else
            goto err;
        
        
        if(mappages(old, i, PGSIZE, pa, flags) != 0)
    8000171c:	8726                	mv	a4,s1
    8000171e:	86ce                	mv	a3,s3
    80001720:	6605                	lui	a2,0x1
    80001722:	85ca                	mv	a1,s2
    80001724:	8552                	mv	a0,s4
    80001726:	00000097          	auipc	ra,0x0
    8000172a:	aba080e7          	jalr	-1350(ra) # 800011e0 <mappages>
    8000172e:	e515                	bnez	a0,8000175a <uvmcopy+0xb0>
    for(i = 0; i < sz; i += PGSIZE){
    80001730:	6785                	lui	a5,0x1
    80001732:	993e                	add	s2,s2,a5
    80001734:	f9696ae3          	bltu	s2,s6,800016c8 <uvmcopy+0x1e>
    80001738:	a81d                	j	8000176e <uvmcopy+0xc4>
            panic("uvmcopy: pte should exist");
    8000173a:	00007517          	auipc	a0,0x7
    8000173e:	a8e50513          	addi	a0,a0,-1394 # 800081c8 <digits+0x178>
    80001742:	fffff097          	auipc	ra,0xfffff
    80001746:	dfa080e7          	jalr	-518(ra) # 8000053c <panic>
            panic("uvmcopy: page not present");
    8000174a:	00007517          	auipc	a0,0x7
    8000174e:	a9e50513          	addi	a0,a0,-1378 # 800081e8 <digits+0x198>
    80001752:	fffff097          	auipc	ra,0xfffff
    80001756:	dea080e7          	jalr	-534(ra) # 8000053c <panic>
            goto err;
    }
    return 0;

err:
    uvmunmap(new, 0, i / PGSIZE, 1);
    8000175a:	4685                	li	a3,1
    8000175c:	00c95613          	srli	a2,s2,0xc
    80001760:	4581                	li	a1,0
    80001762:	8556                	mv	a0,s5
    80001764:	00000097          	auipc	ra,0x0
    80001768:	c42080e7          	jalr	-958(ra) # 800013a6 <uvmunmap>
    return -1;
    8000176c:	557d                	li	a0,-1
}
    8000176e:	70e2                	ld	ra,56(sp)
    80001770:	7442                	ld	s0,48(sp)
    80001772:	74a2                	ld	s1,40(sp)
    80001774:	7902                	ld	s2,32(sp)
    80001776:	69e2                	ld	s3,24(sp)
    80001778:	6a42                	ld	s4,16(sp)
    8000177a:	6aa2                	ld	s5,8(sp)
    8000177c:	6b02                	ld	s6,0(sp)
    8000177e:	6121                	addi	sp,sp,64
    80001780:	8082                	ret
    return 0;
    80001782:	4501                	li	a0,0
}
    80001784:	8082                	ret

0000000080001786 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001786:	1141                	addi	sp,sp,-16
    80001788:	e406                	sd	ra,8(sp)
    8000178a:	e022                	sd	s0,0(sp)
    8000178c:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000178e:	4601                	li	a2,0
    80001790:	00000097          	auipc	ra,0x0
    80001794:	968080e7          	jalr	-1688(ra) # 800010f8 <walk>
  if(pte == 0)
    80001798:	c901                	beqz	a0,800017a8 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000179a:	611c                	ld	a5,0(a0)
    8000179c:	9bbd                	andi	a5,a5,-17
    8000179e:	e11c                	sd	a5,0(a0)
}
    800017a0:	60a2                	ld	ra,8(sp)
    800017a2:	6402                	ld	s0,0(sp)
    800017a4:	0141                	addi	sp,sp,16
    800017a6:	8082                	ret
    panic("uvmclear");
    800017a8:	00007517          	auipc	a0,0x7
    800017ac:	a6050513          	addi	a0,a0,-1440 # 80008208 <digits+0x1b8>
    800017b0:	fffff097          	auipc	ra,0xfffff
    800017b4:	d8c080e7          	jalr	-628(ra) # 8000053c <panic>

00000000800017b8 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800017b8:	c6bd                	beqz	a3,80001826 <copyout+0x6e>
{
    800017ba:	715d                	addi	sp,sp,-80
    800017bc:	e486                	sd	ra,72(sp)
    800017be:	e0a2                	sd	s0,64(sp)
    800017c0:	fc26                	sd	s1,56(sp)
    800017c2:	f84a                	sd	s2,48(sp)
    800017c4:	f44e                	sd	s3,40(sp)
    800017c6:	f052                	sd	s4,32(sp)
    800017c8:	ec56                	sd	s5,24(sp)
    800017ca:	e85a                	sd	s6,16(sp)
    800017cc:	e45e                	sd	s7,8(sp)
    800017ce:	e062                	sd	s8,0(sp)
    800017d0:	0880                	addi	s0,sp,80
    800017d2:	8b2a                	mv	s6,a0
    800017d4:	8c2e                	mv	s8,a1
    800017d6:	8a32                	mv	s4,a2
    800017d8:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800017da:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800017dc:	6a85                	lui	s5,0x1
    800017de:	a015                	j	80001802 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800017e0:	9562                	add	a0,a0,s8
    800017e2:	0004861b          	sext.w	a2,s1
    800017e6:	85d2                	mv	a1,s4
    800017e8:	41250533          	sub	a0,a0,s2
    800017ec:	fffff097          	auipc	ra,0xfffff
    800017f0:	686080e7          	jalr	1670(ra) # 80000e72 <memmove>

    len -= n;
    800017f4:	409989b3          	sub	s3,s3,s1
    src += n;
    800017f8:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800017fa:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800017fe:	02098263          	beqz	s3,80001822 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001802:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001806:	85ca                	mv	a1,s2
    80001808:	855a                	mv	a0,s6
    8000180a:	00000097          	auipc	ra,0x0
    8000180e:	994080e7          	jalr	-1644(ra) # 8000119e <walkaddr>
    if(pa0 == 0)
    80001812:	cd01                	beqz	a0,8000182a <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001814:	418904b3          	sub	s1,s2,s8
    80001818:	94d6                	add	s1,s1,s5
    8000181a:	fc99f3e3          	bgeu	s3,s1,800017e0 <copyout+0x28>
    8000181e:	84ce                	mv	s1,s3
    80001820:	b7c1                	j	800017e0 <copyout+0x28>
  }
  return 0;
    80001822:	4501                	li	a0,0
    80001824:	a021                	j	8000182c <copyout+0x74>
    80001826:	4501                	li	a0,0
}
    80001828:	8082                	ret
      return -1;
    8000182a:	557d                	li	a0,-1
}
    8000182c:	60a6                	ld	ra,72(sp)
    8000182e:	6406                	ld	s0,64(sp)
    80001830:	74e2                	ld	s1,56(sp)
    80001832:	7942                	ld	s2,48(sp)
    80001834:	79a2                	ld	s3,40(sp)
    80001836:	7a02                	ld	s4,32(sp)
    80001838:	6ae2                	ld	s5,24(sp)
    8000183a:	6b42                	ld	s6,16(sp)
    8000183c:	6ba2                	ld	s7,8(sp)
    8000183e:	6c02                	ld	s8,0(sp)
    80001840:	6161                	addi	sp,sp,80
    80001842:	8082                	ret

0000000080001844 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001844:	caa5                	beqz	a3,800018b4 <copyin+0x70>
{
    80001846:	715d                	addi	sp,sp,-80
    80001848:	e486                	sd	ra,72(sp)
    8000184a:	e0a2                	sd	s0,64(sp)
    8000184c:	fc26                	sd	s1,56(sp)
    8000184e:	f84a                	sd	s2,48(sp)
    80001850:	f44e                	sd	s3,40(sp)
    80001852:	f052                	sd	s4,32(sp)
    80001854:	ec56                	sd	s5,24(sp)
    80001856:	e85a                	sd	s6,16(sp)
    80001858:	e45e                	sd	s7,8(sp)
    8000185a:	e062                	sd	s8,0(sp)
    8000185c:	0880                	addi	s0,sp,80
    8000185e:	8b2a                	mv	s6,a0
    80001860:	8a2e                	mv	s4,a1
    80001862:	8c32                	mv	s8,a2
    80001864:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001866:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001868:	6a85                	lui	s5,0x1
    8000186a:	a01d                	j	80001890 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000186c:	018505b3          	add	a1,a0,s8
    80001870:	0004861b          	sext.w	a2,s1
    80001874:	412585b3          	sub	a1,a1,s2
    80001878:	8552                	mv	a0,s4
    8000187a:	fffff097          	auipc	ra,0xfffff
    8000187e:	5f8080e7          	jalr	1528(ra) # 80000e72 <memmove>

    len -= n;
    80001882:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001886:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001888:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000188c:	02098263          	beqz	s3,800018b0 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001890:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001894:	85ca                	mv	a1,s2
    80001896:	855a                	mv	a0,s6
    80001898:	00000097          	auipc	ra,0x0
    8000189c:	906080e7          	jalr	-1786(ra) # 8000119e <walkaddr>
    if(pa0 == 0)
    800018a0:	cd01                	beqz	a0,800018b8 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    800018a2:	418904b3          	sub	s1,s2,s8
    800018a6:	94d6                	add	s1,s1,s5
    800018a8:	fc99f2e3          	bgeu	s3,s1,8000186c <copyin+0x28>
    800018ac:	84ce                	mv	s1,s3
    800018ae:	bf7d                	j	8000186c <copyin+0x28>
  }
  return 0;
    800018b0:	4501                	li	a0,0
    800018b2:	a021                	j	800018ba <copyin+0x76>
    800018b4:	4501                	li	a0,0
}
    800018b6:	8082                	ret
      return -1;
    800018b8:	557d                	li	a0,-1
}
    800018ba:	60a6                	ld	ra,72(sp)
    800018bc:	6406                	ld	s0,64(sp)
    800018be:	74e2                	ld	s1,56(sp)
    800018c0:	7942                	ld	s2,48(sp)
    800018c2:	79a2                	ld	s3,40(sp)
    800018c4:	7a02                	ld	s4,32(sp)
    800018c6:	6ae2                	ld	s5,24(sp)
    800018c8:	6b42                	ld	s6,16(sp)
    800018ca:	6ba2                	ld	s7,8(sp)
    800018cc:	6c02                	ld	s8,0(sp)
    800018ce:	6161                	addi	sp,sp,80
    800018d0:	8082                	ret

00000000800018d2 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800018d2:	c2dd                	beqz	a3,80001978 <copyinstr+0xa6>
{
    800018d4:	715d                	addi	sp,sp,-80
    800018d6:	e486                	sd	ra,72(sp)
    800018d8:	e0a2                	sd	s0,64(sp)
    800018da:	fc26                	sd	s1,56(sp)
    800018dc:	f84a                	sd	s2,48(sp)
    800018de:	f44e                	sd	s3,40(sp)
    800018e0:	f052                	sd	s4,32(sp)
    800018e2:	ec56                	sd	s5,24(sp)
    800018e4:	e85a                	sd	s6,16(sp)
    800018e6:	e45e                	sd	s7,8(sp)
    800018e8:	0880                	addi	s0,sp,80
    800018ea:	8a2a                	mv	s4,a0
    800018ec:	8b2e                	mv	s6,a1
    800018ee:	8bb2                	mv	s7,a2
    800018f0:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800018f2:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800018f4:	6985                	lui	s3,0x1
    800018f6:	a02d                	j	80001920 <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800018f8:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800018fc:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800018fe:	37fd                	addiw	a5,a5,-1
    80001900:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001904:	60a6                	ld	ra,72(sp)
    80001906:	6406                	ld	s0,64(sp)
    80001908:	74e2                	ld	s1,56(sp)
    8000190a:	7942                	ld	s2,48(sp)
    8000190c:	79a2                	ld	s3,40(sp)
    8000190e:	7a02                	ld	s4,32(sp)
    80001910:	6ae2                	ld	s5,24(sp)
    80001912:	6b42                	ld	s6,16(sp)
    80001914:	6ba2                	ld	s7,8(sp)
    80001916:	6161                	addi	sp,sp,80
    80001918:	8082                	ret
    srcva = va0 + PGSIZE;
    8000191a:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    8000191e:	c8a9                	beqz	s1,80001970 <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    80001920:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001924:	85ca                	mv	a1,s2
    80001926:	8552                	mv	a0,s4
    80001928:	00000097          	auipc	ra,0x0
    8000192c:	876080e7          	jalr	-1930(ra) # 8000119e <walkaddr>
    if(pa0 == 0)
    80001930:	c131                	beqz	a0,80001974 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    80001932:	417906b3          	sub	a3,s2,s7
    80001936:	96ce                	add	a3,a3,s3
    80001938:	00d4f363          	bgeu	s1,a3,8000193e <copyinstr+0x6c>
    8000193c:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    8000193e:	955e                	add	a0,a0,s7
    80001940:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001944:	daf9                	beqz	a3,8000191a <copyinstr+0x48>
    80001946:	87da                	mv	a5,s6
    80001948:	885a                	mv	a6,s6
      if(*p == '\0'){
    8000194a:	41650633          	sub	a2,a0,s6
    while(n > 0){
    8000194e:	96da                	add	a3,a3,s6
    80001950:	85be                	mv	a1,a5
      if(*p == '\0'){
    80001952:	00f60733          	add	a4,a2,a5
    80001956:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffbd110>
    8000195a:	df59                	beqz	a4,800018f8 <copyinstr+0x26>
        *dst = *p;
    8000195c:	00e78023          	sb	a4,0(a5)
      dst++;
    80001960:	0785                	addi	a5,a5,1
    while(n > 0){
    80001962:	fed797e3          	bne	a5,a3,80001950 <copyinstr+0x7e>
    80001966:	14fd                	addi	s1,s1,-1
    80001968:	94c2                	add	s1,s1,a6
      --max;
    8000196a:	8c8d                	sub	s1,s1,a1
      dst++;
    8000196c:	8b3e                	mv	s6,a5
    8000196e:	b775                	j	8000191a <copyinstr+0x48>
    80001970:	4781                	li	a5,0
    80001972:	b771                	j	800018fe <copyinstr+0x2c>
      return -1;
    80001974:	557d                	li	a0,-1
    80001976:	b779                	j	80001904 <copyinstr+0x32>
  int got_null = 0;
    80001978:	4781                	li	a5,0
  if(got_null){
    8000197a:	37fd                	addiw	a5,a5,-1
    8000197c:	0007851b          	sext.w	a0,a5
}
    80001980:	8082                	ret

0000000080001982 <rr_scheduler>:
        (*sched_pointer)();
    }
}

void rr_scheduler(void)
{
    80001982:	715d                	addi	sp,sp,-80
    80001984:	e486                	sd	ra,72(sp)
    80001986:	e0a2                	sd	s0,64(sp)
    80001988:	fc26                	sd	s1,56(sp)
    8000198a:	f84a                	sd	s2,48(sp)
    8000198c:	f44e                	sd	s3,40(sp)
    8000198e:	f052                	sd	s4,32(sp)
    80001990:	ec56                	sd	s5,24(sp)
    80001992:	e85a                	sd	s6,16(sp)
    80001994:	e45e                	sd	s7,8(sp)
    80001996:	e062                	sd	s8,0(sp)
    80001998:	0880                	addi	s0,sp,80
  asm volatile("mv %0, tp" : "=r" (x) );
    8000199a:	8792                	mv	a5,tp
    int id = r_tp();
    8000199c:	2781                	sext.w	a5,a5
    struct proc *p;
    struct cpu *c = mycpu();

    c->proc = 0;
    8000199e:	0002fa97          	auipc	s5,0x2f
    800019a2:	342a8a93          	addi	s5,s5,834 # 80030ce0 <cpus>
    800019a6:	00779713          	slli	a4,a5,0x7
    800019aa:	00ea86b3          	add	a3,s5,a4
    800019ae:	0006b023          	sd	zero,0(a3) # fffffffffffff000 <end+0xffffffff7ffbd110>
                // Switch to chosen process.  It is the process's job
                // to release its lock and then reacquire it
                // before jumping back to us.
                p->state = RUNNING;
                c->proc = p;
                swtch(&c->context, &p->context);
    800019b2:	0721                	addi	a4,a4,8
    800019b4:	9aba                	add	s5,s5,a4
                c->proc = p;
    800019b6:	8936                	mv	s2,a3
                // check if we are still the right scheduler (or if schedset changed)
                if (sched_pointer != &rr_scheduler)
    800019b8:	00007c17          	auipc	s8,0x7
    800019bc:	000c0c13          	mv	s8,s8
    800019c0:	00000b97          	auipc	s7,0x0
    800019c4:	fc2b8b93          	addi	s7,s7,-62 # 80001982 <rr_scheduler>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800019c8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800019cc:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800019d0:	10079073          	csrw	sstatus,a5
        for (p = proc; p < &proc[NPROC]; p++)
    800019d4:	0002f497          	auipc	s1,0x2f
    800019d8:	73c48493          	addi	s1,s1,1852 # 80031110 <proc>
            if (p->state == RUNNABLE)
    800019dc:	498d                	li	s3,3
                p->state = RUNNING;
    800019de:	4b11                	li	s6,4
        for (p = proc; p < &proc[NPROC]; p++)
    800019e0:	00035a17          	auipc	s4,0x35
    800019e4:	130a0a13          	addi	s4,s4,304 # 80036b10 <tickslock>
    800019e8:	a81d                	j	80001a1e <rr_scheduler+0x9c>
                {
                    release(&p->lock);
    800019ea:	8526                	mv	a0,s1
    800019ec:	fffff097          	auipc	ra,0xfffff
    800019f0:	3e2080e7          	jalr	994(ra) # 80000dce <release>
                c->proc = 0;
            }
            release(&p->lock);
        }
    }
}
    800019f4:	60a6                	ld	ra,72(sp)
    800019f6:	6406                	ld	s0,64(sp)
    800019f8:	74e2                	ld	s1,56(sp)
    800019fa:	7942                	ld	s2,48(sp)
    800019fc:	79a2                	ld	s3,40(sp)
    800019fe:	7a02                	ld	s4,32(sp)
    80001a00:	6ae2                	ld	s5,24(sp)
    80001a02:	6b42                	ld	s6,16(sp)
    80001a04:	6ba2                	ld	s7,8(sp)
    80001a06:	6c02                	ld	s8,0(sp)
    80001a08:	6161                	addi	sp,sp,80
    80001a0a:	8082                	ret
            release(&p->lock);
    80001a0c:	8526                	mv	a0,s1
    80001a0e:	fffff097          	auipc	ra,0xfffff
    80001a12:	3c0080e7          	jalr	960(ra) # 80000dce <release>
        for (p = proc; p < &proc[NPROC]; p++)
    80001a16:	16848493          	addi	s1,s1,360
    80001a1a:	fb4487e3          	beq	s1,s4,800019c8 <rr_scheduler+0x46>
            acquire(&p->lock);
    80001a1e:	8526                	mv	a0,s1
    80001a20:	fffff097          	auipc	ra,0xfffff
    80001a24:	2fa080e7          	jalr	762(ra) # 80000d1a <acquire>
            if (p->state == RUNNABLE)
    80001a28:	4c9c                	lw	a5,24(s1)
    80001a2a:	ff3791e3          	bne	a5,s3,80001a0c <rr_scheduler+0x8a>
                p->state = RUNNING;
    80001a2e:	0164ac23          	sw	s6,24(s1)
                c->proc = p;
    80001a32:	00993023          	sd	s1,0(s2) # 1000 <_entry-0x7ffff000>
                swtch(&c->context, &p->context);
    80001a36:	06048593          	addi	a1,s1,96
    80001a3a:	8556                	mv	a0,s5
    80001a3c:	00001097          	auipc	ra,0x1
    80001a40:	fb6080e7          	jalr	-74(ra) # 800029f2 <swtch>
                if (sched_pointer != &rr_scheduler)
    80001a44:	000c3783          	ld	a5,0(s8) # 800089b8 <sched_pointer>
    80001a48:	fb7791e3          	bne	a5,s7,800019ea <rr_scheduler+0x68>
                c->proc = 0;
    80001a4c:	00093023          	sd	zero,0(s2)
    80001a50:	bf75                	j	80001a0c <rr_scheduler+0x8a>

0000000080001a52 <proc_mapstacks>:
{
    80001a52:	7139                	addi	sp,sp,-64
    80001a54:	fc06                	sd	ra,56(sp)
    80001a56:	f822                	sd	s0,48(sp)
    80001a58:	f426                	sd	s1,40(sp)
    80001a5a:	f04a                	sd	s2,32(sp)
    80001a5c:	ec4e                	sd	s3,24(sp)
    80001a5e:	e852                	sd	s4,16(sp)
    80001a60:	e456                	sd	s5,8(sp)
    80001a62:	e05a                	sd	s6,0(sp)
    80001a64:	0080                	addi	s0,sp,64
    80001a66:	89aa                	mv	s3,a0
    for (p = proc; p < &proc[NPROC]; p++)
    80001a68:	0002f497          	auipc	s1,0x2f
    80001a6c:	6a848493          	addi	s1,s1,1704 # 80031110 <proc>
        uint64 va = KSTACK((int)(p - proc));
    80001a70:	8b26                	mv	s6,s1
    80001a72:	00006a97          	auipc	s5,0x6
    80001a76:	59ea8a93          	addi	s5,s5,1438 # 80008010 <__func__.1+0x8>
    80001a7a:	04000937          	lui	s2,0x4000
    80001a7e:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001a80:	0932                	slli	s2,s2,0xc
    for (p = proc; p < &proc[NPROC]; p++)
    80001a82:	00035a17          	auipc	s4,0x35
    80001a86:	08ea0a13          	addi	s4,s4,142 # 80036b10 <tickslock>
        char *pa = kalloc();
    80001a8a:	fffff097          	auipc	ra,0xfffff
    80001a8e:	106080e7          	jalr	262(ra) # 80000b90 <kalloc>
    80001a92:	862a                	mv	a2,a0
        if (pa == 0)
    80001a94:	c131                	beqz	a0,80001ad8 <proc_mapstacks+0x86>
        uint64 va = KSTACK((int)(p - proc));
    80001a96:	416485b3          	sub	a1,s1,s6
    80001a9a:	858d                	srai	a1,a1,0x3
    80001a9c:	000ab783          	ld	a5,0(s5)
    80001aa0:	02f585b3          	mul	a1,a1,a5
    80001aa4:	2585                	addiw	a1,a1,1
    80001aa6:	00d5959b          	slliw	a1,a1,0xd
        kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001aaa:	4719                	li	a4,6
    80001aac:	6685                	lui	a3,0x1
    80001aae:	40b905b3          	sub	a1,s2,a1
    80001ab2:	854e                	mv	a0,s3
    80001ab4:	fffff097          	auipc	ra,0xfffff
    80001ab8:	7cc080e7          	jalr	1996(ra) # 80001280 <kvmmap>
    for (p = proc; p < &proc[NPROC]; p++)
    80001abc:	16848493          	addi	s1,s1,360
    80001ac0:	fd4495e3          	bne	s1,s4,80001a8a <proc_mapstacks+0x38>
}
    80001ac4:	70e2                	ld	ra,56(sp)
    80001ac6:	7442                	ld	s0,48(sp)
    80001ac8:	74a2                	ld	s1,40(sp)
    80001aca:	7902                	ld	s2,32(sp)
    80001acc:	69e2                	ld	s3,24(sp)
    80001ace:	6a42                	ld	s4,16(sp)
    80001ad0:	6aa2                	ld	s5,8(sp)
    80001ad2:	6b02                	ld	s6,0(sp)
    80001ad4:	6121                	addi	sp,sp,64
    80001ad6:	8082                	ret
            panic("kalloc");
    80001ad8:	00006517          	auipc	a0,0x6
    80001adc:	74050513          	addi	a0,a0,1856 # 80008218 <digits+0x1c8>
    80001ae0:	fffff097          	auipc	ra,0xfffff
    80001ae4:	a5c080e7          	jalr	-1444(ra) # 8000053c <panic>

0000000080001ae8 <procinit>:
{
    80001ae8:	7139                	addi	sp,sp,-64
    80001aea:	fc06                	sd	ra,56(sp)
    80001aec:	f822                	sd	s0,48(sp)
    80001aee:	f426                	sd	s1,40(sp)
    80001af0:	f04a                	sd	s2,32(sp)
    80001af2:	ec4e                	sd	s3,24(sp)
    80001af4:	e852                	sd	s4,16(sp)
    80001af6:	e456                	sd	s5,8(sp)
    80001af8:	e05a                	sd	s6,0(sp)
    80001afa:	0080                	addi	s0,sp,64
    initlock(&pid_lock, "nextpid");
    80001afc:	00006597          	auipc	a1,0x6
    80001b00:	72458593          	addi	a1,a1,1828 # 80008220 <digits+0x1d0>
    80001b04:	0002f517          	auipc	a0,0x2f
    80001b08:	5dc50513          	addi	a0,a0,1500 # 800310e0 <pid_lock>
    80001b0c:	fffff097          	auipc	ra,0xfffff
    80001b10:	17e080e7          	jalr	382(ra) # 80000c8a <initlock>
    initlock(&wait_lock, "wait_lock");
    80001b14:	00006597          	auipc	a1,0x6
    80001b18:	71458593          	addi	a1,a1,1812 # 80008228 <digits+0x1d8>
    80001b1c:	0002f517          	auipc	a0,0x2f
    80001b20:	5dc50513          	addi	a0,a0,1500 # 800310f8 <wait_lock>
    80001b24:	fffff097          	auipc	ra,0xfffff
    80001b28:	166080e7          	jalr	358(ra) # 80000c8a <initlock>
    for (p = proc; p < &proc[NPROC]; p++)
    80001b2c:	0002f497          	auipc	s1,0x2f
    80001b30:	5e448493          	addi	s1,s1,1508 # 80031110 <proc>
        initlock(&p->lock, "proc");
    80001b34:	00006b17          	auipc	s6,0x6
    80001b38:	704b0b13          	addi	s6,s6,1796 # 80008238 <digits+0x1e8>
        p->kstack = KSTACK((int)(p - proc));
    80001b3c:	8aa6                	mv	s5,s1
    80001b3e:	00006a17          	auipc	s4,0x6
    80001b42:	4d2a0a13          	addi	s4,s4,1234 # 80008010 <__func__.1+0x8>
    80001b46:	04000937          	lui	s2,0x4000
    80001b4a:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001b4c:	0932                	slli	s2,s2,0xc
    for (p = proc; p < &proc[NPROC]; p++)
    80001b4e:	00035997          	auipc	s3,0x35
    80001b52:	fc298993          	addi	s3,s3,-62 # 80036b10 <tickslock>
        initlock(&p->lock, "proc");
    80001b56:	85da                	mv	a1,s6
    80001b58:	8526                	mv	a0,s1
    80001b5a:	fffff097          	auipc	ra,0xfffff
    80001b5e:	130080e7          	jalr	304(ra) # 80000c8a <initlock>
        p->state = UNUSED;
    80001b62:	0004ac23          	sw	zero,24(s1)
        p->kstack = KSTACK((int)(p - proc));
    80001b66:	415487b3          	sub	a5,s1,s5
    80001b6a:	878d                	srai	a5,a5,0x3
    80001b6c:	000a3703          	ld	a4,0(s4)
    80001b70:	02e787b3          	mul	a5,a5,a4
    80001b74:	2785                	addiw	a5,a5,1
    80001b76:	00d7979b          	slliw	a5,a5,0xd
    80001b7a:	40f907b3          	sub	a5,s2,a5
    80001b7e:	e0bc                	sd	a5,64(s1)
    for (p = proc; p < &proc[NPROC]; p++)
    80001b80:	16848493          	addi	s1,s1,360
    80001b84:	fd3499e3          	bne	s1,s3,80001b56 <procinit+0x6e>
}
    80001b88:	70e2                	ld	ra,56(sp)
    80001b8a:	7442                	ld	s0,48(sp)
    80001b8c:	74a2                	ld	s1,40(sp)
    80001b8e:	7902                	ld	s2,32(sp)
    80001b90:	69e2                	ld	s3,24(sp)
    80001b92:	6a42                	ld	s4,16(sp)
    80001b94:	6aa2                	ld	s5,8(sp)
    80001b96:	6b02                	ld	s6,0(sp)
    80001b98:	6121                	addi	sp,sp,64
    80001b9a:	8082                	ret

0000000080001b9c <copy_array>:
{
    80001b9c:	1141                	addi	sp,sp,-16
    80001b9e:	e422                	sd	s0,8(sp)
    80001ba0:	0800                	addi	s0,sp,16
    for (int i = 0; i < len; i++)
    80001ba2:	00c05c63          	blez	a2,80001bba <copy_array+0x1e>
    80001ba6:	87aa                	mv	a5,a0
    80001ba8:	9532                	add	a0,a0,a2
        dst[i] = src[i];
    80001baa:	0007c703          	lbu	a4,0(a5)
    80001bae:	00e58023          	sb	a4,0(a1)
    for (int i = 0; i < len; i++)
    80001bb2:	0785                	addi	a5,a5,1
    80001bb4:	0585                	addi	a1,a1,1
    80001bb6:	fea79ae3          	bne	a5,a0,80001baa <copy_array+0xe>
}
    80001bba:	6422                	ld	s0,8(sp)
    80001bbc:	0141                	addi	sp,sp,16
    80001bbe:	8082                	ret

0000000080001bc0 <cpuid>:
{
    80001bc0:	1141                	addi	sp,sp,-16
    80001bc2:	e422                	sd	s0,8(sp)
    80001bc4:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001bc6:	8512                	mv	a0,tp
}
    80001bc8:	2501                	sext.w	a0,a0
    80001bca:	6422                	ld	s0,8(sp)
    80001bcc:	0141                	addi	sp,sp,16
    80001bce:	8082                	ret

0000000080001bd0 <mycpu>:
{
    80001bd0:	1141                	addi	sp,sp,-16
    80001bd2:	e422                	sd	s0,8(sp)
    80001bd4:	0800                	addi	s0,sp,16
    80001bd6:	8792                	mv	a5,tp
    struct cpu *c = &cpus[id];
    80001bd8:	2781                	sext.w	a5,a5
    80001bda:	079e                	slli	a5,a5,0x7
}
    80001bdc:	0002f517          	auipc	a0,0x2f
    80001be0:	10450513          	addi	a0,a0,260 # 80030ce0 <cpus>
    80001be4:	953e                	add	a0,a0,a5
    80001be6:	6422                	ld	s0,8(sp)
    80001be8:	0141                	addi	sp,sp,16
    80001bea:	8082                	ret

0000000080001bec <myproc>:
{
    80001bec:	1101                	addi	sp,sp,-32
    80001bee:	ec06                	sd	ra,24(sp)
    80001bf0:	e822                	sd	s0,16(sp)
    80001bf2:	e426                	sd	s1,8(sp)
    80001bf4:	1000                	addi	s0,sp,32
    push_off();
    80001bf6:	fffff097          	auipc	ra,0xfffff
    80001bfa:	0d8080e7          	jalr	216(ra) # 80000cce <push_off>
    80001bfe:	8792                	mv	a5,tp
    struct proc *p = c->proc;
    80001c00:	2781                	sext.w	a5,a5
    80001c02:	079e                	slli	a5,a5,0x7
    80001c04:	0002f717          	auipc	a4,0x2f
    80001c08:	0dc70713          	addi	a4,a4,220 # 80030ce0 <cpus>
    80001c0c:	97ba                	add	a5,a5,a4
    80001c0e:	6384                	ld	s1,0(a5)
    pop_off();
    80001c10:	fffff097          	auipc	ra,0xfffff
    80001c14:	15e080e7          	jalr	350(ra) # 80000d6e <pop_off>
}
    80001c18:	8526                	mv	a0,s1
    80001c1a:	60e2                	ld	ra,24(sp)
    80001c1c:	6442                	ld	s0,16(sp)
    80001c1e:	64a2                	ld	s1,8(sp)
    80001c20:	6105                	addi	sp,sp,32
    80001c22:	8082                	ret

0000000080001c24 <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001c24:	1141                	addi	sp,sp,-16
    80001c26:	e406                	sd	ra,8(sp)
    80001c28:	e022                	sd	s0,0(sp)
    80001c2a:	0800                	addi	s0,sp,16
    static int first = 1;

    // Still holding p->lock from scheduler.
    release(&myproc()->lock);
    80001c2c:	00000097          	auipc	ra,0x0
    80001c30:	fc0080e7          	jalr	-64(ra) # 80001bec <myproc>
    80001c34:	fffff097          	auipc	ra,0xfffff
    80001c38:	19a080e7          	jalr	410(ra) # 80000dce <release>

    if (first)
    80001c3c:	00007797          	auipc	a5,0x7
    80001c40:	d747a783          	lw	a5,-652(a5) # 800089b0 <first.1>
    80001c44:	eb89                	bnez	a5,80001c56 <forkret+0x32>
        // be run from main().
        first = 0;
        fsinit(ROOTDEV);
    }

    usertrapret();
    80001c46:	00001097          	auipc	ra,0x1
    80001c4a:	e56080e7          	jalr	-426(ra) # 80002a9c <usertrapret>
}
    80001c4e:	60a2                	ld	ra,8(sp)
    80001c50:	6402                	ld	s0,0(sp)
    80001c52:	0141                	addi	sp,sp,16
    80001c54:	8082                	ret
        first = 0;
    80001c56:	00007797          	auipc	a5,0x7
    80001c5a:	d407ad23          	sw	zero,-678(a5) # 800089b0 <first.1>
        fsinit(ROOTDEV);
    80001c5e:	4505                	li	a0,1
    80001c60:	00002097          	auipc	ra,0x2
    80001c64:	d5c080e7          	jalr	-676(ra) # 800039bc <fsinit>
    80001c68:	bff9                	j	80001c46 <forkret+0x22>

0000000080001c6a <allocpid>:
{
    80001c6a:	1101                	addi	sp,sp,-32
    80001c6c:	ec06                	sd	ra,24(sp)
    80001c6e:	e822                	sd	s0,16(sp)
    80001c70:	e426                	sd	s1,8(sp)
    80001c72:	e04a                	sd	s2,0(sp)
    80001c74:	1000                	addi	s0,sp,32
    acquire(&pid_lock);
    80001c76:	0002f917          	auipc	s2,0x2f
    80001c7a:	46a90913          	addi	s2,s2,1130 # 800310e0 <pid_lock>
    80001c7e:	854a                	mv	a0,s2
    80001c80:	fffff097          	auipc	ra,0xfffff
    80001c84:	09a080e7          	jalr	154(ra) # 80000d1a <acquire>
    pid = nextpid;
    80001c88:	00007797          	auipc	a5,0x7
    80001c8c:	d3878793          	addi	a5,a5,-712 # 800089c0 <nextpid>
    80001c90:	4384                	lw	s1,0(a5)
    nextpid = nextpid + 1;
    80001c92:	0014871b          	addiw	a4,s1,1
    80001c96:	c398                	sw	a4,0(a5)
    release(&pid_lock);
    80001c98:	854a                	mv	a0,s2
    80001c9a:	fffff097          	auipc	ra,0xfffff
    80001c9e:	134080e7          	jalr	308(ra) # 80000dce <release>
}
    80001ca2:	8526                	mv	a0,s1
    80001ca4:	60e2                	ld	ra,24(sp)
    80001ca6:	6442                	ld	s0,16(sp)
    80001ca8:	64a2                	ld	s1,8(sp)
    80001caa:	6902                	ld	s2,0(sp)
    80001cac:	6105                	addi	sp,sp,32
    80001cae:	8082                	ret

0000000080001cb0 <proc_pagetable>:
{
    80001cb0:	1101                	addi	sp,sp,-32
    80001cb2:	ec06                	sd	ra,24(sp)
    80001cb4:	e822                	sd	s0,16(sp)
    80001cb6:	e426                	sd	s1,8(sp)
    80001cb8:	e04a                	sd	s2,0(sp)
    80001cba:	1000                	addi	s0,sp,32
    80001cbc:	892a                	mv	s2,a0
    pagetable = uvmcreate();
    80001cbe:	fffff097          	auipc	ra,0xfffff
    80001cc2:	7ac080e7          	jalr	1964(ra) # 8000146a <uvmcreate>
    80001cc6:	84aa                	mv	s1,a0
    if (pagetable == 0)
    80001cc8:	c121                	beqz	a0,80001d08 <proc_pagetable+0x58>
    if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001cca:	4729                	li	a4,10
    80001ccc:	00005697          	auipc	a3,0x5
    80001cd0:	33468693          	addi	a3,a3,820 # 80007000 <_trampoline>
    80001cd4:	6605                	lui	a2,0x1
    80001cd6:	040005b7          	lui	a1,0x4000
    80001cda:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001cdc:	05b2                	slli	a1,a1,0xc
    80001cde:	fffff097          	auipc	ra,0xfffff
    80001ce2:	502080e7          	jalr	1282(ra) # 800011e0 <mappages>
    80001ce6:	02054863          	bltz	a0,80001d16 <proc_pagetable+0x66>
    if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001cea:	4719                	li	a4,6
    80001cec:	05893683          	ld	a3,88(s2)
    80001cf0:	6605                	lui	a2,0x1
    80001cf2:	020005b7          	lui	a1,0x2000
    80001cf6:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001cf8:	05b6                	slli	a1,a1,0xd
    80001cfa:	8526                	mv	a0,s1
    80001cfc:	fffff097          	auipc	ra,0xfffff
    80001d00:	4e4080e7          	jalr	1252(ra) # 800011e0 <mappages>
    80001d04:	02054163          	bltz	a0,80001d26 <proc_pagetable+0x76>
}
    80001d08:	8526                	mv	a0,s1
    80001d0a:	60e2                	ld	ra,24(sp)
    80001d0c:	6442                	ld	s0,16(sp)
    80001d0e:	64a2                	ld	s1,8(sp)
    80001d10:	6902                	ld	s2,0(sp)
    80001d12:	6105                	addi	sp,sp,32
    80001d14:	8082                	ret
        uvmfree(pagetable, 0);
    80001d16:	4581                	li	a1,0
    80001d18:	8526                	mv	a0,s1
    80001d1a:	00000097          	auipc	ra,0x0
    80001d1e:	956080e7          	jalr	-1706(ra) # 80001670 <uvmfree>
        return 0;
    80001d22:	4481                	li	s1,0
    80001d24:	b7d5                	j	80001d08 <proc_pagetable+0x58>
        uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001d26:	4681                	li	a3,0
    80001d28:	4605                	li	a2,1
    80001d2a:	040005b7          	lui	a1,0x4000
    80001d2e:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001d30:	05b2                	slli	a1,a1,0xc
    80001d32:	8526                	mv	a0,s1
    80001d34:	fffff097          	auipc	ra,0xfffff
    80001d38:	672080e7          	jalr	1650(ra) # 800013a6 <uvmunmap>
        uvmfree(pagetable, 0);
    80001d3c:	4581                	li	a1,0
    80001d3e:	8526                	mv	a0,s1
    80001d40:	00000097          	auipc	ra,0x0
    80001d44:	930080e7          	jalr	-1744(ra) # 80001670 <uvmfree>
        return 0;
    80001d48:	4481                	li	s1,0
    80001d4a:	bf7d                	j	80001d08 <proc_pagetable+0x58>

0000000080001d4c <proc_freepagetable>:
{
    80001d4c:	1101                	addi	sp,sp,-32
    80001d4e:	ec06                	sd	ra,24(sp)
    80001d50:	e822                	sd	s0,16(sp)
    80001d52:	e426                	sd	s1,8(sp)
    80001d54:	e04a                	sd	s2,0(sp)
    80001d56:	1000                	addi	s0,sp,32
    80001d58:	84aa                	mv	s1,a0
    80001d5a:	892e                	mv	s2,a1
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001d5c:	4681                	li	a3,0
    80001d5e:	4605                	li	a2,1
    80001d60:	040005b7          	lui	a1,0x4000
    80001d64:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001d66:	05b2                	slli	a1,a1,0xc
    80001d68:	fffff097          	auipc	ra,0xfffff
    80001d6c:	63e080e7          	jalr	1598(ra) # 800013a6 <uvmunmap>
    uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001d70:	4681                	li	a3,0
    80001d72:	4605                	li	a2,1
    80001d74:	020005b7          	lui	a1,0x2000
    80001d78:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001d7a:	05b6                	slli	a1,a1,0xd
    80001d7c:	8526                	mv	a0,s1
    80001d7e:	fffff097          	auipc	ra,0xfffff
    80001d82:	628080e7          	jalr	1576(ra) # 800013a6 <uvmunmap>
    uvmfree(pagetable, sz);
    80001d86:	85ca                	mv	a1,s2
    80001d88:	8526                	mv	a0,s1
    80001d8a:	00000097          	auipc	ra,0x0
    80001d8e:	8e6080e7          	jalr	-1818(ra) # 80001670 <uvmfree>
}
    80001d92:	60e2                	ld	ra,24(sp)
    80001d94:	6442                	ld	s0,16(sp)
    80001d96:	64a2                	ld	s1,8(sp)
    80001d98:	6902                	ld	s2,0(sp)
    80001d9a:	6105                	addi	sp,sp,32
    80001d9c:	8082                	ret

0000000080001d9e <freeproc>:
{
    80001d9e:	1101                	addi	sp,sp,-32
    80001da0:	ec06                	sd	ra,24(sp)
    80001da2:	e822                	sd	s0,16(sp)
    80001da4:	e426                	sd	s1,8(sp)
    80001da6:	1000                	addi	s0,sp,32
    80001da8:	84aa                	mv	s1,a0
    if (p->trapframe){
    80001daa:	6d28                	ld	a0,88(a0)
    80001dac:	c509                	beqz	a0,80001db6 <freeproc+0x18>
        decrement_reference_counter((void *)p->trapframe);
    80001dae:	fffff097          	auipc	ra,0xfffff
    80001db2:	e98080e7          	jalr	-360(ra) # 80000c46 <decrement_reference_counter>
    p->trapframe = 0;
    80001db6:	0404bc23          	sd	zero,88(s1)
    if (p->pagetable)
    80001dba:	68a8                	ld	a0,80(s1)
    80001dbc:	c511                	beqz	a0,80001dc8 <freeproc+0x2a>
        proc_freepagetable(p->pagetable, p->sz);
    80001dbe:	64ac                	ld	a1,72(s1)
    80001dc0:	00000097          	auipc	ra,0x0
    80001dc4:	f8c080e7          	jalr	-116(ra) # 80001d4c <proc_freepagetable>
    p->pagetable = 0;
    80001dc8:	0404b823          	sd	zero,80(s1)
    p->sz = 0;
    80001dcc:	0404b423          	sd	zero,72(s1)
    p->pid = 0;
    80001dd0:	0204a823          	sw	zero,48(s1)
    p->parent = 0;
    80001dd4:	0204bc23          	sd	zero,56(s1)
    p->name[0] = 0;
    80001dd8:	14048c23          	sb	zero,344(s1)
    p->chan = 0;
    80001ddc:	0204b023          	sd	zero,32(s1)
    p->killed = 0;
    80001de0:	0204a423          	sw	zero,40(s1)
    p->xstate = 0;
    80001de4:	0204a623          	sw	zero,44(s1)
    p->state = UNUSED;
    80001de8:	0004ac23          	sw	zero,24(s1)
}
    80001dec:	60e2                	ld	ra,24(sp)
    80001dee:	6442                	ld	s0,16(sp)
    80001df0:	64a2                	ld	s1,8(sp)
    80001df2:	6105                	addi	sp,sp,32
    80001df4:	8082                	ret

0000000080001df6 <allocproc>:
{
    80001df6:	1101                	addi	sp,sp,-32
    80001df8:	ec06                	sd	ra,24(sp)
    80001dfa:	e822                	sd	s0,16(sp)
    80001dfc:	e426                	sd	s1,8(sp)
    80001dfe:	e04a                	sd	s2,0(sp)
    80001e00:	1000                	addi	s0,sp,32
    for (p = proc; p < &proc[NPROC]; p++)
    80001e02:	0002f497          	auipc	s1,0x2f
    80001e06:	30e48493          	addi	s1,s1,782 # 80031110 <proc>
    80001e0a:	00035917          	auipc	s2,0x35
    80001e0e:	d0690913          	addi	s2,s2,-762 # 80036b10 <tickslock>
        acquire(&p->lock);
    80001e12:	8526                	mv	a0,s1
    80001e14:	fffff097          	auipc	ra,0xfffff
    80001e18:	f06080e7          	jalr	-250(ra) # 80000d1a <acquire>
        if (p->state == UNUSED)
    80001e1c:	4c9c                	lw	a5,24(s1)
    80001e1e:	cf81                	beqz	a5,80001e36 <allocproc+0x40>
            release(&p->lock);
    80001e20:	8526                	mv	a0,s1
    80001e22:	fffff097          	auipc	ra,0xfffff
    80001e26:	fac080e7          	jalr	-84(ra) # 80000dce <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001e2a:	16848493          	addi	s1,s1,360
    80001e2e:	ff2492e3          	bne	s1,s2,80001e12 <allocproc+0x1c>
    return 0;
    80001e32:	4481                	li	s1,0
    80001e34:	a889                	j	80001e86 <allocproc+0x90>
    p->pid = allocpid();
    80001e36:	00000097          	auipc	ra,0x0
    80001e3a:	e34080e7          	jalr	-460(ra) # 80001c6a <allocpid>
    80001e3e:	d888                	sw	a0,48(s1)
    p->state = USED;
    80001e40:	4785                	li	a5,1
    80001e42:	cc9c                	sw	a5,24(s1)
    if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001e44:	fffff097          	auipc	ra,0xfffff
    80001e48:	d4c080e7          	jalr	-692(ra) # 80000b90 <kalloc>
    80001e4c:	892a                	mv	s2,a0
    80001e4e:	eca8                	sd	a0,88(s1)
    80001e50:	c131                	beqz	a0,80001e94 <allocproc+0x9e>
    p->pagetable = proc_pagetable(p);
    80001e52:	8526                	mv	a0,s1
    80001e54:	00000097          	auipc	ra,0x0
    80001e58:	e5c080e7          	jalr	-420(ra) # 80001cb0 <proc_pagetable>
    80001e5c:	892a                	mv	s2,a0
    80001e5e:	e8a8                	sd	a0,80(s1)
    if (p->pagetable == 0)
    80001e60:	c531                	beqz	a0,80001eac <allocproc+0xb6>
    memset(&p->context, 0, sizeof(p->context));
    80001e62:	07000613          	li	a2,112
    80001e66:	4581                	li	a1,0
    80001e68:	06048513          	addi	a0,s1,96
    80001e6c:	fffff097          	auipc	ra,0xfffff
    80001e70:	faa080e7          	jalr	-86(ra) # 80000e16 <memset>
    p->context.ra = (uint64)forkret;
    80001e74:	00000797          	auipc	a5,0x0
    80001e78:	db078793          	addi	a5,a5,-592 # 80001c24 <forkret>
    80001e7c:	f0bc                	sd	a5,96(s1)
    p->context.sp = p->kstack + PGSIZE;
    80001e7e:	60bc                	ld	a5,64(s1)
    80001e80:	6705                	lui	a4,0x1
    80001e82:	97ba                	add	a5,a5,a4
    80001e84:	f4bc                	sd	a5,104(s1)
}
    80001e86:	8526                	mv	a0,s1
    80001e88:	60e2                	ld	ra,24(sp)
    80001e8a:	6442                	ld	s0,16(sp)
    80001e8c:	64a2                	ld	s1,8(sp)
    80001e8e:	6902                	ld	s2,0(sp)
    80001e90:	6105                	addi	sp,sp,32
    80001e92:	8082                	ret
        freeproc(p);
    80001e94:	8526                	mv	a0,s1
    80001e96:	00000097          	auipc	ra,0x0
    80001e9a:	f08080e7          	jalr	-248(ra) # 80001d9e <freeproc>
        release(&p->lock);
    80001e9e:	8526                	mv	a0,s1
    80001ea0:	fffff097          	auipc	ra,0xfffff
    80001ea4:	f2e080e7          	jalr	-210(ra) # 80000dce <release>
        return 0;
    80001ea8:	84ca                	mv	s1,s2
    80001eaa:	bff1                	j	80001e86 <allocproc+0x90>
        freeproc(p);
    80001eac:	8526                	mv	a0,s1
    80001eae:	00000097          	auipc	ra,0x0
    80001eb2:	ef0080e7          	jalr	-272(ra) # 80001d9e <freeproc>
        release(&p->lock);
    80001eb6:	8526                	mv	a0,s1
    80001eb8:	fffff097          	auipc	ra,0xfffff
    80001ebc:	f16080e7          	jalr	-234(ra) # 80000dce <release>
        return 0;
    80001ec0:	84ca                	mv	s1,s2
    80001ec2:	b7d1                	j	80001e86 <allocproc+0x90>

0000000080001ec4 <userinit>:
{
    80001ec4:	1101                	addi	sp,sp,-32
    80001ec6:	ec06                	sd	ra,24(sp)
    80001ec8:	e822                	sd	s0,16(sp)
    80001eca:	e426                	sd	s1,8(sp)
    80001ecc:	1000                	addi	s0,sp,32
    p = allocproc();
    80001ece:	00000097          	auipc	ra,0x0
    80001ed2:	f28080e7          	jalr	-216(ra) # 80001df6 <allocproc>
    80001ed6:	84aa                	mv	s1,a0
    initproc = p;
    80001ed8:	00007797          	auipc	a5,0x7
    80001edc:	b8a7b823          	sd	a0,-1136(a5) # 80008a68 <initproc>
    uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001ee0:	03400613          	li	a2,52
    80001ee4:	00007597          	auipc	a1,0x7
    80001ee8:	aec58593          	addi	a1,a1,-1300 # 800089d0 <initcode>
    80001eec:	6928                	ld	a0,80(a0)
    80001eee:	fffff097          	auipc	ra,0xfffff
    80001ef2:	5aa080e7          	jalr	1450(ra) # 80001498 <uvmfirst>
    p->sz = PGSIZE;
    80001ef6:	6785                	lui	a5,0x1
    80001ef8:	e4bc                	sd	a5,72(s1)
    p->trapframe->epc = 0;     // user program counter
    80001efa:	6cb8                	ld	a4,88(s1)
    80001efc:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
    p->trapframe->sp = PGSIZE; // user stack pointer
    80001f00:	6cb8                	ld	a4,88(s1)
    80001f02:	fb1c                	sd	a5,48(a4)
    safestrcpy(p->name, "initcode", sizeof(p->name));
    80001f04:	4641                	li	a2,16
    80001f06:	00006597          	auipc	a1,0x6
    80001f0a:	33a58593          	addi	a1,a1,826 # 80008240 <digits+0x1f0>
    80001f0e:	15848513          	addi	a0,s1,344
    80001f12:	fffff097          	auipc	ra,0xfffff
    80001f16:	04c080e7          	jalr	76(ra) # 80000f5e <safestrcpy>
    p->cwd = namei("/");
    80001f1a:	00006517          	auipc	a0,0x6
    80001f1e:	33650513          	addi	a0,a0,822 # 80008250 <digits+0x200>
    80001f22:	00002097          	auipc	ra,0x2
    80001f26:	4b8080e7          	jalr	1208(ra) # 800043da <namei>
    80001f2a:	14a4b823          	sd	a0,336(s1)
    p->state = RUNNABLE;
    80001f2e:	478d                	li	a5,3
    80001f30:	cc9c                	sw	a5,24(s1)
    release(&p->lock);
    80001f32:	8526                	mv	a0,s1
    80001f34:	fffff097          	auipc	ra,0xfffff
    80001f38:	e9a080e7          	jalr	-358(ra) # 80000dce <release>
}
    80001f3c:	60e2                	ld	ra,24(sp)
    80001f3e:	6442                	ld	s0,16(sp)
    80001f40:	64a2                	ld	s1,8(sp)
    80001f42:	6105                	addi	sp,sp,32
    80001f44:	8082                	ret

0000000080001f46 <growproc>:
{
    80001f46:	1101                	addi	sp,sp,-32
    80001f48:	ec06                	sd	ra,24(sp)
    80001f4a:	e822                	sd	s0,16(sp)
    80001f4c:	e426                	sd	s1,8(sp)
    80001f4e:	e04a                	sd	s2,0(sp)
    80001f50:	1000                	addi	s0,sp,32
    80001f52:	892a                	mv	s2,a0
    struct proc *p = myproc();
    80001f54:	00000097          	auipc	ra,0x0
    80001f58:	c98080e7          	jalr	-872(ra) # 80001bec <myproc>
    80001f5c:	84aa                	mv	s1,a0
    sz = p->sz;
    80001f5e:	652c                	ld	a1,72(a0)
    if (n > 0)
    80001f60:	01204c63          	bgtz	s2,80001f78 <growproc+0x32>
    else if (n < 0)
    80001f64:	02094663          	bltz	s2,80001f90 <growproc+0x4a>
    p->sz = sz;
    80001f68:	e4ac                	sd	a1,72(s1)
    return 0;
    80001f6a:	4501                	li	a0,0
}
    80001f6c:	60e2                	ld	ra,24(sp)
    80001f6e:	6442                	ld	s0,16(sp)
    80001f70:	64a2                	ld	s1,8(sp)
    80001f72:	6902                	ld	s2,0(sp)
    80001f74:	6105                	addi	sp,sp,32
    80001f76:	8082                	ret
        if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001f78:	4691                	li	a3,4
    80001f7a:	00b90633          	add	a2,s2,a1
    80001f7e:	6928                	ld	a0,80(a0)
    80001f80:	fffff097          	auipc	ra,0xfffff
    80001f84:	5d2080e7          	jalr	1490(ra) # 80001552 <uvmalloc>
    80001f88:	85aa                	mv	a1,a0
    80001f8a:	fd79                	bnez	a0,80001f68 <growproc+0x22>
            return -1;
    80001f8c:	557d                	li	a0,-1
    80001f8e:	bff9                	j	80001f6c <growproc+0x26>
        sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001f90:	00b90633          	add	a2,s2,a1
    80001f94:	6928                	ld	a0,80(a0)
    80001f96:	fffff097          	auipc	ra,0xfffff
    80001f9a:	574080e7          	jalr	1396(ra) # 8000150a <uvmdealloc>
    80001f9e:	85aa                	mv	a1,a0
    80001fa0:	b7e1                	j	80001f68 <growproc+0x22>

0000000080001fa2 <ps>:
{
    80001fa2:	715d                	addi	sp,sp,-80
    80001fa4:	e486                	sd	ra,72(sp)
    80001fa6:	e0a2                	sd	s0,64(sp)
    80001fa8:	fc26                	sd	s1,56(sp)
    80001faa:	f84a                	sd	s2,48(sp)
    80001fac:	f44e                	sd	s3,40(sp)
    80001fae:	f052                	sd	s4,32(sp)
    80001fb0:	ec56                	sd	s5,24(sp)
    80001fb2:	e85a                	sd	s6,16(sp)
    80001fb4:	e45e                	sd	s7,8(sp)
    80001fb6:	e062                	sd	s8,0(sp)
    80001fb8:	0880                	addi	s0,sp,80
    80001fba:	84aa                	mv	s1,a0
    80001fbc:	8bae                	mv	s7,a1
    void *result = (void *)myproc()->sz;
    80001fbe:	00000097          	auipc	ra,0x0
    80001fc2:	c2e080e7          	jalr	-978(ra) # 80001bec <myproc>
    if (count == 0)
    80001fc6:	120b8063          	beqz	s7,800020e6 <ps+0x144>
    void *result = (void *)myproc()->sz;
    80001fca:	04853b03          	ld	s6,72(a0)
    if (growproc(count * sizeof(struct user_proc)) < 0)
    80001fce:	003b951b          	slliw	a0,s7,0x3
    80001fd2:	0175053b          	addw	a0,a0,s7
    80001fd6:	0025151b          	slliw	a0,a0,0x2
    80001fda:	00000097          	auipc	ra,0x0
    80001fde:	f6c080e7          	jalr	-148(ra) # 80001f46 <growproc>
    80001fe2:	10054463          	bltz	a0,800020ea <ps+0x148>
    struct user_proc loc_result[count];
    80001fe6:	003b9a13          	slli	s4,s7,0x3
    80001fea:	9a5e                	add	s4,s4,s7
    80001fec:	0a0a                	slli	s4,s4,0x2
    80001fee:	00fa0793          	addi	a5,s4,15
    80001ff2:	8391                	srli	a5,a5,0x4
    80001ff4:	0792                	slli	a5,a5,0x4
    80001ff6:	40f10133          	sub	sp,sp,a5
    80001ffa:	8a8a                	mv	s5,sp
    struct proc *p = proc + (start * sizeof(proc));
    80001ffc:	007e97b7          	lui	a5,0x7e9
    80002000:	02f484b3          	mul	s1,s1,a5
    80002004:	0002f797          	auipc	a5,0x2f
    80002008:	10c78793          	addi	a5,a5,268 # 80031110 <proc>
    8000200c:	94be                	add	s1,s1,a5
    if (p >= &proc[NPROC])
    8000200e:	00035797          	auipc	a5,0x35
    80002012:	b0278793          	addi	a5,a5,-1278 # 80036b10 <tickslock>
    80002016:	0cf4fc63          	bgeu	s1,a5,800020ee <ps+0x14c>
        if (localCount == count)
    8000201a:	014a8913          	addi	s2,s5,20
    uint8 localCount = 0;
    8000201e:	4981                	li	s3,0
    for (; p < &proc[NPROC]; p++)
    80002020:	8c3e                	mv	s8,a5
    80002022:	a069                	j	800020ac <ps+0x10a>
            loc_result[localCount].state = UNUSED;
    80002024:	00399793          	slli	a5,s3,0x3
    80002028:	97ce                	add	a5,a5,s3
    8000202a:	078a                	slli	a5,a5,0x2
    8000202c:	97d6                	add	a5,a5,s5
    8000202e:	0007a023          	sw	zero,0(a5)
            release(&p->lock);
    80002032:	8526                	mv	a0,s1
    80002034:	fffff097          	auipc	ra,0xfffff
    80002038:	d9a080e7          	jalr	-614(ra) # 80000dce <release>
    if (localCount < count)
    8000203c:	0179f963          	bgeu	s3,s7,8000204e <ps+0xac>
        loc_result[localCount].state = UNUSED; // if we reach the end of processes
    80002040:	00399793          	slli	a5,s3,0x3
    80002044:	97ce                	add	a5,a5,s3
    80002046:	078a                	slli	a5,a5,0x2
    80002048:	97d6                	add	a5,a5,s5
    8000204a:	0007a023          	sw	zero,0(a5)
    void *result = (void *)myproc()->sz;
    8000204e:	84da                	mv	s1,s6
    copyout(myproc()->pagetable, (uint64)result, (void *)loc_result, count * sizeof(struct user_proc));
    80002050:	00000097          	auipc	ra,0x0
    80002054:	b9c080e7          	jalr	-1124(ra) # 80001bec <myproc>
    80002058:	86d2                	mv	a3,s4
    8000205a:	8656                	mv	a2,s5
    8000205c:	85da                	mv	a1,s6
    8000205e:	6928                	ld	a0,80(a0)
    80002060:	fffff097          	auipc	ra,0xfffff
    80002064:	758080e7          	jalr	1880(ra) # 800017b8 <copyout>
}
    80002068:	8526                	mv	a0,s1
    8000206a:	fb040113          	addi	sp,s0,-80
    8000206e:	60a6                	ld	ra,72(sp)
    80002070:	6406                	ld	s0,64(sp)
    80002072:	74e2                	ld	s1,56(sp)
    80002074:	7942                	ld	s2,48(sp)
    80002076:	79a2                	ld	s3,40(sp)
    80002078:	7a02                	ld	s4,32(sp)
    8000207a:	6ae2                	ld	s5,24(sp)
    8000207c:	6b42                	ld	s6,16(sp)
    8000207e:	6ba2                	ld	s7,8(sp)
    80002080:	6c02                	ld	s8,0(sp)
    80002082:	6161                	addi	sp,sp,80
    80002084:	8082                	ret
            loc_result[localCount].parent_id = p->parent->pid;
    80002086:	5b9c                	lw	a5,48(a5)
    80002088:	fef92e23          	sw	a5,-4(s2)
        release(&p->lock);
    8000208c:	8526                	mv	a0,s1
    8000208e:	fffff097          	auipc	ra,0xfffff
    80002092:	d40080e7          	jalr	-704(ra) # 80000dce <release>
        localCount++;
    80002096:	2985                	addiw	s3,s3,1
    80002098:	0ff9f993          	zext.b	s3,s3
    for (; p < &proc[NPROC]; p++)
    8000209c:	16848493          	addi	s1,s1,360
    800020a0:	f984fee3          	bgeu	s1,s8,8000203c <ps+0x9a>
        if (localCount == count)
    800020a4:	02490913          	addi	s2,s2,36
    800020a8:	fb3b83e3          	beq	s7,s3,8000204e <ps+0xac>
        acquire(&p->lock);
    800020ac:	8526                	mv	a0,s1
    800020ae:	fffff097          	auipc	ra,0xfffff
    800020b2:	c6c080e7          	jalr	-916(ra) # 80000d1a <acquire>
        if (p->state == UNUSED)
    800020b6:	4c9c                	lw	a5,24(s1)
    800020b8:	d7b5                	beqz	a5,80002024 <ps+0x82>
        loc_result[localCount].state = p->state;
    800020ba:	fef92623          	sw	a5,-20(s2)
        loc_result[localCount].killed = p->killed;
    800020be:	549c                	lw	a5,40(s1)
    800020c0:	fef92823          	sw	a5,-16(s2)
        loc_result[localCount].xstate = p->xstate;
    800020c4:	54dc                	lw	a5,44(s1)
    800020c6:	fef92a23          	sw	a5,-12(s2)
        loc_result[localCount].pid = p->pid;
    800020ca:	589c                	lw	a5,48(s1)
    800020cc:	fef92c23          	sw	a5,-8(s2)
        copy_array(p->name, loc_result[localCount].name, 16);
    800020d0:	4641                	li	a2,16
    800020d2:	85ca                	mv	a1,s2
    800020d4:	15848513          	addi	a0,s1,344
    800020d8:	00000097          	auipc	ra,0x0
    800020dc:	ac4080e7          	jalr	-1340(ra) # 80001b9c <copy_array>
        if (p->parent != 0) // init
    800020e0:	7c9c                	ld	a5,56(s1)
    800020e2:	f3d5                	bnez	a5,80002086 <ps+0xe4>
    800020e4:	b765                	j	8000208c <ps+0xea>
        return result;
    800020e6:	4481                	li	s1,0
    800020e8:	b741                	j	80002068 <ps+0xc6>
        return result;
    800020ea:	4481                	li	s1,0
    800020ec:	bfb5                	j	80002068 <ps+0xc6>
        return result;
    800020ee:	4481                	li	s1,0
    800020f0:	bfa5                	j	80002068 <ps+0xc6>

00000000800020f2 <fork>:
{
    800020f2:	7139                	addi	sp,sp,-64
    800020f4:	fc06                	sd	ra,56(sp)
    800020f6:	f822                	sd	s0,48(sp)
    800020f8:	f426                	sd	s1,40(sp)
    800020fa:	f04a                	sd	s2,32(sp)
    800020fc:	ec4e                	sd	s3,24(sp)
    800020fe:	e852                	sd	s4,16(sp)
    80002100:	e456                	sd	s5,8(sp)
    80002102:	0080                	addi	s0,sp,64
    struct proc *p = myproc();
    80002104:	00000097          	auipc	ra,0x0
    80002108:	ae8080e7          	jalr	-1304(ra) # 80001bec <myproc>
    8000210c:	8aaa                	mv	s5,a0
    if ((np = allocproc()) == 0)
    8000210e:	00000097          	auipc	ra,0x0
    80002112:	ce8080e7          	jalr	-792(ra) # 80001df6 <allocproc>
    80002116:	10050c63          	beqz	a0,8000222e <fork+0x13c>
    8000211a:	8a2a                	mv	s4,a0
    if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    8000211c:	048ab603          	ld	a2,72(s5)
    80002120:	692c                	ld	a1,80(a0)
    80002122:	050ab503          	ld	a0,80(s5)
    80002126:	fffff097          	auipc	ra,0xfffff
    8000212a:	584080e7          	jalr	1412(ra) # 800016aa <uvmcopy>
    8000212e:	04054863          	bltz	a0,8000217e <fork+0x8c>
    np->sz = p->sz;
    80002132:	048ab783          	ld	a5,72(s5)
    80002136:	04fa3423          	sd	a5,72(s4)
    *(np->trapframe) = *(p->trapframe);
    8000213a:	058ab683          	ld	a3,88(s5)
    8000213e:	87b6                	mv	a5,a3
    80002140:	058a3703          	ld	a4,88(s4)
    80002144:	12068693          	addi	a3,a3,288
    80002148:	0007b803          	ld	a6,0(a5)
    8000214c:	6788                	ld	a0,8(a5)
    8000214e:	6b8c                	ld	a1,16(a5)
    80002150:	6f90                	ld	a2,24(a5)
    80002152:	01073023          	sd	a6,0(a4)
    80002156:	e708                	sd	a0,8(a4)
    80002158:	eb0c                	sd	a1,16(a4)
    8000215a:	ef10                	sd	a2,24(a4)
    8000215c:	02078793          	addi	a5,a5,32
    80002160:	02070713          	addi	a4,a4,32
    80002164:	fed792e3          	bne	a5,a3,80002148 <fork+0x56>
    np->trapframe->a0 = 0;
    80002168:	058a3783          	ld	a5,88(s4)
    8000216c:	0607b823          	sd	zero,112(a5)
    for (i = 0; i < NOFILE; i++)
    80002170:	0d0a8493          	addi	s1,s5,208
    80002174:	0d0a0913          	addi	s2,s4,208
    80002178:	150a8993          	addi	s3,s5,336
    8000217c:	a00d                	j	8000219e <fork+0xac>
        freeproc(np);
    8000217e:	8552                	mv	a0,s4
    80002180:	00000097          	auipc	ra,0x0
    80002184:	c1e080e7          	jalr	-994(ra) # 80001d9e <freeproc>
        release(&np->lock);
    80002188:	8552                	mv	a0,s4
    8000218a:	fffff097          	auipc	ra,0xfffff
    8000218e:	c44080e7          	jalr	-956(ra) # 80000dce <release>
        return -1;
    80002192:	597d                	li	s2,-1
    80002194:	a059                	j	8000221a <fork+0x128>
    for (i = 0; i < NOFILE; i++)
    80002196:	04a1                	addi	s1,s1,8
    80002198:	0921                	addi	s2,s2,8
    8000219a:	01348b63          	beq	s1,s3,800021b0 <fork+0xbe>
        if (p->ofile[i])
    8000219e:	6088                	ld	a0,0(s1)
    800021a0:	d97d                	beqz	a0,80002196 <fork+0xa4>
            np->ofile[i] = filedup(p->ofile[i]);
    800021a2:	00003097          	auipc	ra,0x3
    800021a6:	8aa080e7          	jalr	-1878(ra) # 80004a4c <filedup>
    800021aa:	00a93023          	sd	a0,0(s2)
    800021ae:	b7e5                	j	80002196 <fork+0xa4>
    np->cwd = idup(p->cwd);
    800021b0:	150ab503          	ld	a0,336(s5)
    800021b4:	00002097          	auipc	ra,0x2
    800021b8:	a42080e7          	jalr	-1470(ra) # 80003bf6 <idup>
    800021bc:	14aa3823          	sd	a0,336(s4)
    safestrcpy(np->name, p->name, sizeof(p->name));
    800021c0:	4641                	li	a2,16
    800021c2:	158a8593          	addi	a1,s5,344
    800021c6:	158a0513          	addi	a0,s4,344
    800021ca:	fffff097          	auipc	ra,0xfffff
    800021ce:	d94080e7          	jalr	-620(ra) # 80000f5e <safestrcpy>
    pid = np->pid;
    800021d2:	030a2903          	lw	s2,48(s4)
    release(&np->lock);
    800021d6:	8552                	mv	a0,s4
    800021d8:	fffff097          	auipc	ra,0xfffff
    800021dc:	bf6080e7          	jalr	-1034(ra) # 80000dce <release>
    acquire(&wait_lock);
    800021e0:	0002f497          	auipc	s1,0x2f
    800021e4:	f1848493          	addi	s1,s1,-232 # 800310f8 <wait_lock>
    800021e8:	8526                	mv	a0,s1
    800021ea:	fffff097          	auipc	ra,0xfffff
    800021ee:	b30080e7          	jalr	-1232(ra) # 80000d1a <acquire>
    np->parent = p;
    800021f2:	035a3c23          	sd	s5,56(s4)
    release(&wait_lock);
    800021f6:	8526                	mv	a0,s1
    800021f8:	fffff097          	auipc	ra,0xfffff
    800021fc:	bd6080e7          	jalr	-1066(ra) # 80000dce <release>
    acquire(&np->lock);
    80002200:	8552                	mv	a0,s4
    80002202:	fffff097          	auipc	ra,0xfffff
    80002206:	b18080e7          	jalr	-1256(ra) # 80000d1a <acquire>
    np->state = RUNNABLE;
    8000220a:	478d                	li	a5,3
    8000220c:	00fa2c23          	sw	a5,24(s4)
    release(&np->lock);
    80002210:	8552                	mv	a0,s4
    80002212:	fffff097          	auipc	ra,0xfffff
    80002216:	bbc080e7          	jalr	-1092(ra) # 80000dce <release>
}
    8000221a:	854a                	mv	a0,s2
    8000221c:	70e2                	ld	ra,56(sp)
    8000221e:	7442                	ld	s0,48(sp)
    80002220:	74a2                	ld	s1,40(sp)
    80002222:	7902                	ld	s2,32(sp)
    80002224:	69e2                	ld	s3,24(sp)
    80002226:	6a42                	ld	s4,16(sp)
    80002228:	6aa2                	ld	s5,8(sp)
    8000222a:	6121                	addi	sp,sp,64
    8000222c:	8082                	ret
        return -1;
    8000222e:	597d                	li	s2,-1
    80002230:	b7ed                	j	8000221a <fork+0x128>

0000000080002232 <scheduler>:
{
    80002232:	1101                	addi	sp,sp,-32
    80002234:	ec06                	sd	ra,24(sp)
    80002236:	e822                	sd	s0,16(sp)
    80002238:	e426                	sd	s1,8(sp)
    8000223a:	1000                	addi	s0,sp,32
        (*sched_pointer)();
    8000223c:	00006497          	auipc	s1,0x6
    80002240:	77c48493          	addi	s1,s1,1916 # 800089b8 <sched_pointer>
    80002244:	609c                	ld	a5,0(s1)
    80002246:	9782                	jalr	a5
    while (1)
    80002248:	bff5                	j	80002244 <scheduler+0x12>

000000008000224a <sched>:
{
    8000224a:	7179                	addi	sp,sp,-48
    8000224c:	f406                	sd	ra,40(sp)
    8000224e:	f022                	sd	s0,32(sp)
    80002250:	ec26                	sd	s1,24(sp)
    80002252:	e84a                	sd	s2,16(sp)
    80002254:	e44e                	sd	s3,8(sp)
    80002256:	1800                	addi	s0,sp,48
    struct proc *p = myproc();
    80002258:	00000097          	auipc	ra,0x0
    8000225c:	994080e7          	jalr	-1644(ra) # 80001bec <myproc>
    80002260:	84aa                	mv	s1,a0
    if (!holding(&p->lock))
    80002262:	fffff097          	auipc	ra,0xfffff
    80002266:	a3e080e7          	jalr	-1474(ra) # 80000ca0 <holding>
    8000226a:	c53d                	beqz	a0,800022d8 <sched+0x8e>
    8000226c:	8792                	mv	a5,tp
    if (mycpu()->noff != 1)
    8000226e:	2781                	sext.w	a5,a5
    80002270:	079e                	slli	a5,a5,0x7
    80002272:	0002f717          	auipc	a4,0x2f
    80002276:	a6e70713          	addi	a4,a4,-1426 # 80030ce0 <cpus>
    8000227a:	97ba                	add	a5,a5,a4
    8000227c:	5fb8                	lw	a4,120(a5)
    8000227e:	4785                	li	a5,1
    80002280:	06f71463          	bne	a4,a5,800022e8 <sched+0x9e>
    if (p->state == RUNNING)
    80002284:	4c98                	lw	a4,24(s1)
    80002286:	4791                	li	a5,4
    80002288:	06f70863          	beq	a4,a5,800022f8 <sched+0xae>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000228c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002290:	8b89                	andi	a5,a5,2
    if (intr_get())
    80002292:	ebbd                	bnez	a5,80002308 <sched+0xbe>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002294:	8792                	mv	a5,tp
    intena = mycpu()->intena;
    80002296:	0002f917          	auipc	s2,0x2f
    8000229a:	a4a90913          	addi	s2,s2,-1462 # 80030ce0 <cpus>
    8000229e:	2781                	sext.w	a5,a5
    800022a0:	079e                	slli	a5,a5,0x7
    800022a2:	97ca                	add	a5,a5,s2
    800022a4:	07c7a983          	lw	s3,124(a5)
    800022a8:	8592                	mv	a1,tp
    swtch(&p->context, &mycpu()->context);
    800022aa:	2581                	sext.w	a1,a1
    800022ac:	059e                	slli	a1,a1,0x7
    800022ae:	05a1                	addi	a1,a1,8
    800022b0:	95ca                	add	a1,a1,s2
    800022b2:	06048513          	addi	a0,s1,96
    800022b6:	00000097          	auipc	ra,0x0
    800022ba:	73c080e7          	jalr	1852(ra) # 800029f2 <swtch>
    800022be:	8792                	mv	a5,tp
    mycpu()->intena = intena;
    800022c0:	2781                	sext.w	a5,a5
    800022c2:	079e                	slli	a5,a5,0x7
    800022c4:	993e                	add	s2,s2,a5
    800022c6:	07392e23          	sw	s3,124(s2)
}
    800022ca:	70a2                	ld	ra,40(sp)
    800022cc:	7402                	ld	s0,32(sp)
    800022ce:	64e2                	ld	s1,24(sp)
    800022d0:	6942                	ld	s2,16(sp)
    800022d2:	69a2                	ld	s3,8(sp)
    800022d4:	6145                	addi	sp,sp,48
    800022d6:	8082                	ret
        panic("sched p->lock");
    800022d8:	00006517          	auipc	a0,0x6
    800022dc:	f8050513          	addi	a0,a0,-128 # 80008258 <digits+0x208>
    800022e0:	ffffe097          	auipc	ra,0xffffe
    800022e4:	25c080e7          	jalr	604(ra) # 8000053c <panic>
        panic("sched locks");
    800022e8:	00006517          	auipc	a0,0x6
    800022ec:	f8050513          	addi	a0,a0,-128 # 80008268 <digits+0x218>
    800022f0:	ffffe097          	auipc	ra,0xffffe
    800022f4:	24c080e7          	jalr	588(ra) # 8000053c <panic>
        panic("sched running");
    800022f8:	00006517          	auipc	a0,0x6
    800022fc:	f8050513          	addi	a0,a0,-128 # 80008278 <digits+0x228>
    80002300:	ffffe097          	auipc	ra,0xffffe
    80002304:	23c080e7          	jalr	572(ra) # 8000053c <panic>
        panic("sched interruptible");
    80002308:	00006517          	auipc	a0,0x6
    8000230c:	f8050513          	addi	a0,a0,-128 # 80008288 <digits+0x238>
    80002310:	ffffe097          	auipc	ra,0xffffe
    80002314:	22c080e7          	jalr	556(ra) # 8000053c <panic>

0000000080002318 <yield>:
{
    80002318:	1101                	addi	sp,sp,-32
    8000231a:	ec06                	sd	ra,24(sp)
    8000231c:	e822                	sd	s0,16(sp)
    8000231e:	e426                	sd	s1,8(sp)
    80002320:	1000                	addi	s0,sp,32
    struct proc *p = myproc();
    80002322:	00000097          	auipc	ra,0x0
    80002326:	8ca080e7          	jalr	-1846(ra) # 80001bec <myproc>
    8000232a:	84aa                	mv	s1,a0
    acquire(&p->lock);
    8000232c:	fffff097          	auipc	ra,0xfffff
    80002330:	9ee080e7          	jalr	-1554(ra) # 80000d1a <acquire>
    p->state = RUNNABLE;
    80002334:	478d                	li	a5,3
    80002336:	cc9c                	sw	a5,24(s1)
    sched();
    80002338:	00000097          	auipc	ra,0x0
    8000233c:	f12080e7          	jalr	-238(ra) # 8000224a <sched>
    release(&p->lock);
    80002340:	8526                	mv	a0,s1
    80002342:	fffff097          	auipc	ra,0xfffff
    80002346:	a8c080e7          	jalr	-1396(ra) # 80000dce <release>
}
    8000234a:	60e2                	ld	ra,24(sp)
    8000234c:	6442                	ld	s0,16(sp)
    8000234e:	64a2                	ld	s1,8(sp)
    80002350:	6105                	addi	sp,sp,32
    80002352:	8082                	ret

0000000080002354 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    80002354:	7179                	addi	sp,sp,-48
    80002356:	f406                	sd	ra,40(sp)
    80002358:	f022                	sd	s0,32(sp)
    8000235a:	ec26                	sd	s1,24(sp)
    8000235c:	e84a                	sd	s2,16(sp)
    8000235e:	e44e                	sd	s3,8(sp)
    80002360:	1800                	addi	s0,sp,48
    80002362:	89aa                	mv	s3,a0
    80002364:	892e                	mv	s2,a1
    struct proc *p = myproc();
    80002366:	00000097          	auipc	ra,0x0
    8000236a:	886080e7          	jalr	-1914(ra) # 80001bec <myproc>
    8000236e:	84aa                	mv	s1,a0
    // Once we hold p->lock, we can be
    // guaranteed that we won't miss any wakeup
    // (wakeup locks p->lock),
    // so it's okay to release lk.

    acquire(&p->lock); // DOC: sleeplock1
    80002370:	fffff097          	auipc	ra,0xfffff
    80002374:	9aa080e7          	jalr	-1622(ra) # 80000d1a <acquire>
    release(lk);
    80002378:	854a                	mv	a0,s2
    8000237a:	fffff097          	auipc	ra,0xfffff
    8000237e:	a54080e7          	jalr	-1452(ra) # 80000dce <release>

    // Go to sleep.
    p->chan = chan;
    80002382:	0334b023          	sd	s3,32(s1)
    p->state = SLEEPING;
    80002386:	4789                	li	a5,2
    80002388:	cc9c                	sw	a5,24(s1)

    sched();
    8000238a:	00000097          	auipc	ra,0x0
    8000238e:	ec0080e7          	jalr	-320(ra) # 8000224a <sched>

    // Tidy up.
    p->chan = 0;
    80002392:	0204b023          	sd	zero,32(s1)

    // Reacquire original lock.
    release(&p->lock);
    80002396:	8526                	mv	a0,s1
    80002398:	fffff097          	auipc	ra,0xfffff
    8000239c:	a36080e7          	jalr	-1482(ra) # 80000dce <release>
    acquire(lk);
    800023a0:	854a                	mv	a0,s2
    800023a2:	fffff097          	auipc	ra,0xfffff
    800023a6:	978080e7          	jalr	-1672(ra) # 80000d1a <acquire>
}
    800023aa:	70a2                	ld	ra,40(sp)
    800023ac:	7402                	ld	s0,32(sp)
    800023ae:	64e2                	ld	s1,24(sp)
    800023b0:	6942                	ld	s2,16(sp)
    800023b2:	69a2                	ld	s3,8(sp)
    800023b4:	6145                	addi	sp,sp,48
    800023b6:	8082                	ret

00000000800023b8 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    800023b8:	7139                	addi	sp,sp,-64
    800023ba:	fc06                	sd	ra,56(sp)
    800023bc:	f822                	sd	s0,48(sp)
    800023be:	f426                	sd	s1,40(sp)
    800023c0:	f04a                	sd	s2,32(sp)
    800023c2:	ec4e                	sd	s3,24(sp)
    800023c4:	e852                	sd	s4,16(sp)
    800023c6:	e456                	sd	s5,8(sp)
    800023c8:	0080                	addi	s0,sp,64
    800023ca:	8a2a                	mv	s4,a0
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++)
    800023cc:	0002f497          	auipc	s1,0x2f
    800023d0:	d4448493          	addi	s1,s1,-700 # 80031110 <proc>
    {
        if (p != myproc())
        {
            acquire(&p->lock);
            if (p->state == SLEEPING && p->chan == chan)
    800023d4:	4989                	li	s3,2
            {
                p->state = RUNNABLE;
    800023d6:	4a8d                	li	s5,3
    for (p = proc; p < &proc[NPROC]; p++)
    800023d8:	00034917          	auipc	s2,0x34
    800023dc:	73890913          	addi	s2,s2,1848 # 80036b10 <tickslock>
    800023e0:	a811                	j	800023f4 <wakeup+0x3c>
            }
            release(&p->lock);
    800023e2:	8526                	mv	a0,s1
    800023e4:	fffff097          	auipc	ra,0xfffff
    800023e8:	9ea080e7          	jalr	-1558(ra) # 80000dce <release>
    for (p = proc; p < &proc[NPROC]; p++)
    800023ec:	16848493          	addi	s1,s1,360
    800023f0:	03248663          	beq	s1,s2,8000241c <wakeup+0x64>
        if (p != myproc())
    800023f4:	fffff097          	auipc	ra,0xfffff
    800023f8:	7f8080e7          	jalr	2040(ra) # 80001bec <myproc>
    800023fc:	fea488e3          	beq	s1,a0,800023ec <wakeup+0x34>
            acquire(&p->lock);
    80002400:	8526                	mv	a0,s1
    80002402:	fffff097          	auipc	ra,0xfffff
    80002406:	918080e7          	jalr	-1768(ra) # 80000d1a <acquire>
            if (p->state == SLEEPING && p->chan == chan)
    8000240a:	4c9c                	lw	a5,24(s1)
    8000240c:	fd379be3          	bne	a5,s3,800023e2 <wakeup+0x2a>
    80002410:	709c                	ld	a5,32(s1)
    80002412:	fd4798e3          	bne	a5,s4,800023e2 <wakeup+0x2a>
                p->state = RUNNABLE;
    80002416:	0154ac23          	sw	s5,24(s1)
    8000241a:	b7e1                	j	800023e2 <wakeup+0x2a>
        }
    }
}
    8000241c:	70e2                	ld	ra,56(sp)
    8000241e:	7442                	ld	s0,48(sp)
    80002420:	74a2                	ld	s1,40(sp)
    80002422:	7902                	ld	s2,32(sp)
    80002424:	69e2                	ld	s3,24(sp)
    80002426:	6a42                	ld	s4,16(sp)
    80002428:	6aa2                	ld	s5,8(sp)
    8000242a:	6121                	addi	sp,sp,64
    8000242c:	8082                	ret

000000008000242e <reparent>:
{
    8000242e:	7179                	addi	sp,sp,-48
    80002430:	f406                	sd	ra,40(sp)
    80002432:	f022                	sd	s0,32(sp)
    80002434:	ec26                	sd	s1,24(sp)
    80002436:	e84a                	sd	s2,16(sp)
    80002438:	e44e                	sd	s3,8(sp)
    8000243a:	e052                	sd	s4,0(sp)
    8000243c:	1800                	addi	s0,sp,48
    8000243e:	892a                	mv	s2,a0
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002440:	0002f497          	auipc	s1,0x2f
    80002444:	cd048493          	addi	s1,s1,-816 # 80031110 <proc>
            pp->parent = initproc;
    80002448:	00006a17          	auipc	s4,0x6
    8000244c:	620a0a13          	addi	s4,s4,1568 # 80008a68 <initproc>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002450:	00034997          	auipc	s3,0x34
    80002454:	6c098993          	addi	s3,s3,1728 # 80036b10 <tickslock>
    80002458:	a029                	j	80002462 <reparent+0x34>
    8000245a:	16848493          	addi	s1,s1,360
    8000245e:	01348d63          	beq	s1,s3,80002478 <reparent+0x4a>
        if (pp->parent == p)
    80002462:	7c9c                	ld	a5,56(s1)
    80002464:	ff279be3          	bne	a5,s2,8000245a <reparent+0x2c>
            pp->parent = initproc;
    80002468:	000a3503          	ld	a0,0(s4)
    8000246c:	fc88                	sd	a0,56(s1)
            wakeup(initproc);
    8000246e:	00000097          	auipc	ra,0x0
    80002472:	f4a080e7          	jalr	-182(ra) # 800023b8 <wakeup>
    80002476:	b7d5                	j	8000245a <reparent+0x2c>
}
    80002478:	70a2                	ld	ra,40(sp)
    8000247a:	7402                	ld	s0,32(sp)
    8000247c:	64e2                	ld	s1,24(sp)
    8000247e:	6942                	ld	s2,16(sp)
    80002480:	69a2                	ld	s3,8(sp)
    80002482:	6a02                	ld	s4,0(sp)
    80002484:	6145                	addi	sp,sp,48
    80002486:	8082                	ret

0000000080002488 <exit>:
{
    80002488:	7179                	addi	sp,sp,-48
    8000248a:	f406                	sd	ra,40(sp)
    8000248c:	f022                	sd	s0,32(sp)
    8000248e:	ec26                	sd	s1,24(sp)
    80002490:	e84a                	sd	s2,16(sp)
    80002492:	e44e                	sd	s3,8(sp)
    80002494:	e052                	sd	s4,0(sp)
    80002496:	1800                	addi	s0,sp,48
    80002498:	8a2a                	mv	s4,a0
    struct proc *p = myproc();
    8000249a:	fffff097          	auipc	ra,0xfffff
    8000249e:	752080e7          	jalr	1874(ra) # 80001bec <myproc>
    800024a2:	89aa                	mv	s3,a0
    if (p == initproc)
    800024a4:	00006797          	auipc	a5,0x6
    800024a8:	5c47b783          	ld	a5,1476(a5) # 80008a68 <initproc>
    800024ac:	0d050493          	addi	s1,a0,208
    800024b0:	15050913          	addi	s2,a0,336
    800024b4:	02a79363          	bne	a5,a0,800024da <exit+0x52>
        panic("init exiting");
    800024b8:	00006517          	auipc	a0,0x6
    800024bc:	de850513          	addi	a0,a0,-536 # 800082a0 <digits+0x250>
    800024c0:	ffffe097          	auipc	ra,0xffffe
    800024c4:	07c080e7          	jalr	124(ra) # 8000053c <panic>
            fileclose(f);
    800024c8:	00002097          	auipc	ra,0x2
    800024cc:	5d6080e7          	jalr	1494(ra) # 80004a9e <fileclose>
            p->ofile[fd] = 0;
    800024d0:	0004b023          	sd	zero,0(s1)
    for (int fd = 0; fd < NOFILE; fd++)
    800024d4:	04a1                	addi	s1,s1,8
    800024d6:	01248563          	beq	s1,s2,800024e0 <exit+0x58>
        if (p->ofile[fd])
    800024da:	6088                	ld	a0,0(s1)
    800024dc:	f575                	bnez	a0,800024c8 <exit+0x40>
    800024de:	bfdd                	j	800024d4 <exit+0x4c>
    begin_op();
    800024e0:	00002097          	auipc	ra,0x2
    800024e4:	0fa080e7          	jalr	250(ra) # 800045da <begin_op>
    iput(p->cwd);
    800024e8:	1509b503          	ld	a0,336(s3)
    800024ec:	00002097          	auipc	ra,0x2
    800024f0:	902080e7          	jalr	-1790(ra) # 80003dee <iput>
    end_op();
    800024f4:	00002097          	auipc	ra,0x2
    800024f8:	160080e7          	jalr	352(ra) # 80004654 <end_op>
    p->cwd = 0;
    800024fc:	1409b823          	sd	zero,336(s3)
    acquire(&wait_lock);
    80002500:	0002f497          	auipc	s1,0x2f
    80002504:	bf848493          	addi	s1,s1,-1032 # 800310f8 <wait_lock>
    80002508:	8526                	mv	a0,s1
    8000250a:	fffff097          	auipc	ra,0xfffff
    8000250e:	810080e7          	jalr	-2032(ra) # 80000d1a <acquire>
    reparent(p);
    80002512:	854e                	mv	a0,s3
    80002514:	00000097          	auipc	ra,0x0
    80002518:	f1a080e7          	jalr	-230(ra) # 8000242e <reparent>
    wakeup(p->parent);
    8000251c:	0389b503          	ld	a0,56(s3)
    80002520:	00000097          	auipc	ra,0x0
    80002524:	e98080e7          	jalr	-360(ra) # 800023b8 <wakeup>
    acquire(&p->lock);
    80002528:	854e                	mv	a0,s3
    8000252a:	ffffe097          	auipc	ra,0xffffe
    8000252e:	7f0080e7          	jalr	2032(ra) # 80000d1a <acquire>
    p->xstate = status;
    80002532:	0349a623          	sw	s4,44(s3)
    p->state = ZOMBIE;
    80002536:	4795                	li	a5,5
    80002538:	00f9ac23          	sw	a5,24(s3)
    release(&wait_lock);
    8000253c:	8526                	mv	a0,s1
    8000253e:	fffff097          	auipc	ra,0xfffff
    80002542:	890080e7          	jalr	-1904(ra) # 80000dce <release>
    sched();
    80002546:	00000097          	auipc	ra,0x0
    8000254a:	d04080e7          	jalr	-764(ra) # 8000224a <sched>
    panic("zombie exit");
    8000254e:	00006517          	auipc	a0,0x6
    80002552:	d6250513          	addi	a0,a0,-670 # 800082b0 <digits+0x260>
    80002556:	ffffe097          	auipc	ra,0xffffe
    8000255a:	fe6080e7          	jalr	-26(ra) # 8000053c <panic>

000000008000255e <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    8000255e:	7179                	addi	sp,sp,-48
    80002560:	f406                	sd	ra,40(sp)
    80002562:	f022                	sd	s0,32(sp)
    80002564:	ec26                	sd	s1,24(sp)
    80002566:	e84a                	sd	s2,16(sp)
    80002568:	e44e                	sd	s3,8(sp)
    8000256a:	1800                	addi	s0,sp,48
    8000256c:	892a                	mv	s2,a0
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++)
    8000256e:	0002f497          	auipc	s1,0x2f
    80002572:	ba248493          	addi	s1,s1,-1118 # 80031110 <proc>
    80002576:	00034997          	auipc	s3,0x34
    8000257a:	59a98993          	addi	s3,s3,1434 # 80036b10 <tickslock>
    {
        acquire(&p->lock);
    8000257e:	8526                	mv	a0,s1
    80002580:	ffffe097          	auipc	ra,0xffffe
    80002584:	79a080e7          	jalr	1946(ra) # 80000d1a <acquire>
        if (p->pid == pid)
    80002588:	589c                	lw	a5,48(s1)
    8000258a:	01278d63          	beq	a5,s2,800025a4 <kill+0x46>
                p->state = RUNNABLE;
            }
            release(&p->lock);
            return 0;
        }
        release(&p->lock);
    8000258e:	8526                	mv	a0,s1
    80002590:	fffff097          	auipc	ra,0xfffff
    80002594:	83e080e7          	jalr	-1986(ra) # 80000dce <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80002598:	16848493          	addi	s1,s1,360
    8000259c:	ff3491e3          	bne	s1,s3,8000257e <kill+0x20>
    }
    return -1;
    800025a0:	557d                	li	a0,-1
    800025a2:	a829                	j	800025bc <kill+0x5e>
            p->killed = 1;
    800025a4:	4785                	li	a5,1
    800025a6:	d49c                	sw	a5,40(s1)
            if (p->state == SLEEPING)
    800025a8:	4c98                	lw	a4,24(s1)
    800025aa:	4789                	li	a5,2
    800025ac:	00f70f63          	beq	a4,a5,800025ca <kill+0x6c>
            release(&p->lock);
    800025b0:	8526                	mv	a0,s1
    800025b2:	fffff097          	auipc	ra,0xfffff
    800025b6:	81c080e7          	jalr	-2020(ra) # 80000dce <release>
            return 0;
    800025ba:	4501                	li	a0,0
}
    800025bc:	70a2                	ld	ra,40(sp)
    800025be:	7402                	ld	s0,32(sp)
    800025c0:	64e2                	ld	s1,24(sp)
    800025c2:	6942                	ld	s2,16(sp)
    800025c4:	69a2                	ld	s3,8(sp)
    800025c6:	6145                	addi	sp,sp,48
    800025c8:	8082                	ret
                p->state = RUNNABLE;
    800025ca:	478d                	li	a5,3
    800025cc:	cc9c                	sw	a5,24(s1)
    800025ce:	b7cd                	j	800025b0 <kill+0x52>

00000000800025d0 <setkilled>:

void setkilled(struct proc *p)
{
    800025d0:	1101                	addi	sp,sp,-32
    800025d2:	ec06                	sd	ra,24(sp)
    800025d4:	e822                	sd	s0,16(sp)
    800025d6:	e426                	sd	s1,8(sp)
    800025d8:	1000                	addi	s0,sp,32
    800025da:	84aa                	mv	s1,a0
    acquire(&p->lock);
    800025dc:	ffffe097          	auipc	ra,0xffffe
    800025e0:	73e080e7          	jalr	1854(ra) # 80000d1a <acquire>
    p->killed = 1;
    800025e4:	4785                	li	a5,1
    800025e6:	d49c                	sw	a5,40(s1)
    release(&p->lock);
    800025e8:	8526                	mv	a0,s1
    800025ea:	ffffe097          	auipc	ra,0xffffe
    800025ee:	7e4080e7          	jalr	2020(ra) # 80000dce <release>
}
    800025f2:	60e2                	ld	ra,24(sp)
    800025f4:	6442                	ld	s0,16(sp)
    800025f6:	64a2                	ld	s1,8(sp)
    800025f8:	6105                	addi	sp,sp,32
    800025fa:	8082                	ret

00000000800025fc <killed>:

int killed(struct proc *p)
{
    800025fc:	1101                	addi	sp,sp,-32
    800025fe:	ec06                	sd	ra,24(sp)
    80002600:	e822                	sd	s0,16(sp)
    80002602:	e426                	sd	s1,8(sp)
    80002604:	e04a                	sd	s2,0(sp)
    80002606:	1000                	addi	s0,sp,32
    80002608:	84aa                	mv	s1,a0
    int k;

    acquire(&p->lock);
    8000260a:	ffffe097          	auipc	ra,0xffffe
    8000260e:	710080e7          	jalr	1808(ra) # 80000d1a <acquire>
    k = p->killed;
    80002612:	0284a903          	lw	s2,40(s1)
    release(&p->lock);
    80002616:	8526                	mv	a0,s1
    80002618:	ffffe097          	auipc	ra,0xffffe
    8000261c:	7b6080e7          	jalr	1974(ra) # 80000dce <release>
    return k;
}
    80002620:	854a                	mv	a0,s2
    80002622:	60e2                	ld	ra,24(sp)
    80002624:	6442                	ld	s0,16(sp)
    80002626:	64a2                	ld	s1,8(sp)
    80002628:	6902                	ld	s2,0(sp)
    8000262a:	6105                	addi	sp,sp,32
    8000262c:	8082                	ret

000000008000262e <wait>:
{
    8000262e:	715d                	addi	sp,sp,-80
    80002630:	e486                	sd	ra,72(sp)
    80002632:	e0a2                	sd	s0,64(sp)
    80002634:	fc26                	sd	s1,56(sp)
    80002636:	f84a                	sd	s2,48(sp)
    80002638:	f44e                	sd	s3,40(sp)
    8000263a:	f052                	sd	s4,32(sp)
    8000263c:	ec56                	sd	s5,24(sp)
    8000263e:	e85a                	sd	s6,16(sp)
    80002640:	e45e                	sd	s7,8(sp)
    80002642:	e062                	sd	s8,0(sp)
    80002644:	0880                	addi	s0,sp,80
    80002646:	8b2a                	mv	s6,a0
    struct proc *p = myproc();
    80002648:	fffff097          	auipc	ra,0xfffff
    8000264c:	5a4080e7          	jalr	1444(ra) # 80001bec <myproc>
    80002650:	892a                	mv	s2,a0
    acquire(&wait_lock);
    80002652:	0002f517          	auipc	a0,0x2f
    80002656:	aa650513          	addi	a0,a0,-1370 # 800310f8 <wait_lock>
    8000265a:	ffffe097          	auipc	ra,0xffffe
    8000265e:	6c0080e7          	jalr	1728(ra) # 80000d1a <acquire>
        havekids = 0;
    80002662:	4b81                	li	s7,0
                if (pp->state == ZOMBIE)
    80002664:	4a15                	li	s4,5
                havekids = 1;
    80002666:	4a85                	li	s5,1
        for (pp = proc; pp < &proc[NPROC]; pp++)
    80002668:	00034997          	auipc	s3,0x34
    8000266c:	4a898993          	addi	s3,s3,1192 # 80036b10 <tickslock>
        sleep(p, &wait_lock); // DOC: wait-sleep
    80002670:	0002fc17          	auipc	s8,0x2f
    80002674:	a88c0c13          	addi	s8,s8,-1400 # 800310f8 <wait_lock>
    80002678:	a0d1                	j	8000273c <wait+0x10e>
                    pid = pp->pid;
    8000267a:	0304a983          	lw	s3,48(s1)
                    if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    8000267e:	000b0e63          	beqz	s6,8000269a <wait+0x6c>
    80002682:	4691                	li	a3,4
    80002684:	02c48613          	addi	a2,s1,44
    80002688:	85da                	mv	a1,s6
    8000268a:	05093503          	ld	a0,80(s2)
    8000268e:	fffff097          	auipc	ra,0xfffff
    80002692:	12a080e7          	jalr	298(ra) # 800017b8 <copyout>
    80002696:	04054163          	bltz	a0,800026d8 <wait+0xaa>
                    freeproc(pp);
    8000269a:	8526                	mv	a0,s1
    8000269c:	fffff097          	auipc	ra,0xfffff
    800026a0:	702080e7          	jalr	1794(ra) # 80001d9e <freeproc>
                    release(&pp->lock);
    800026a4:	8526                	mv	a0,s1
    800026a6:	ffffe097          	auipc	ra,0xffffe
    800026aa:	728080e7          	jalr	1832(ra) # 80000dce <release>
                    release(&wait_lock);
    800026ae:	0002f517          	auipc	a0,0x2f
    800026b2:	a4a50513          	addi	a0,a0,-1462 # 800310f8 <wait_lock>
    800026b6:	ffffe097          	auipc	ra,0xffffe
    800026ba:	718080e7          	jalr	1816(ra) # 80000dce <release>
}
    800026be:	854e                	mv	a0,s3
    800026c0:	60a6                	ld	ra,72(sp)
    800026c2:	6406                	ld	s0,64(sp)
    800026c4:	74e2                	ld	s1,56(sp)
    800026c6:	7942                	ld	s2,48(sp)
    800026c8:	79a2                	ld	s3,40(sp)
    800026ca:	7a02                	ld	s4,32(sp)
    800026cc:	6ae2                	ld	s5,24(sp)
    800026ce:	6b42                	ld	s6,16(sp)
    800026d0:	6ba2                	ld	s7,8(sp)
    800026d2:	6c02                	ld	s8,0(sp)
    800026d4:	6161                	addi	sp,sp,80
    800026d6:	8082                	ret
                        release(&pp->lock);
    800026d8:	8526                	mv	a0,s1
    800026da:	ffffe097          	auipc	ra,0xffffe
    800026de:	6f4080e7          	jalr	1780(ra) # 80000dce <release>
                        release(&wait_lock);
    800026e2:	0002f517          	auipc	a0,0x2f
    800026e6:	a1650513          	addi	a0,a0,-1514 # 800310f8 <wait_lock>
    800026ea:	ffffe097          	auipc	ra,0xffffe
    800026ee:	6e4080e7          	jalr	1764(ra) # 80000dce <release>
                        return -1;
    800026f2:	59fd                	li	s3,-1
    800026f4:	b7e9                	j	800026be <wait+0x90>
        for (pp = proc; pp < &proc[NPROC]; pp++)
    800026f6:	16848493          	addi	s1,s1,360
    800026fa:	03348463          	beq	s1,s3,80002722 <wait+0xf4>
            if (pp->parent == p)
    800026fe:	7c9c                	ld	a5,56(s1)
    80002700:	ff279be3          	bne	a5,s2,800026f6 <wait+0xc8>
                acquire(&pp->lock);
    80002704:	8526                	mv	a0,s1
    80002706:	ffffe097          	auipc	ra,0xffffe
    8000270a:	614080e7          	jalr	1556(ra) # 80000d1a <acquire>
                if (pp->state == ZOMBIE)
    8000270e:	4c9c                	lw	a5,24(s1)
    80002710:	f74785e3          	beq	a5,s4,8000267a <wait+0x4c>
                release(&pp->lock);
    80002714:	8526                	mv	a0,s1
    80002716:	ffffe097          	auipc	ra,0xffffe
    8000271a:	6b8080e7          	jalr	1720(ra) # 80000dce <release>
                havekids = 1;
    8000271e:	8756                	mv	a4,s5
    80002720:	bfd9                	j	800026f6 <wait+0xc8>
        if (!havekids || killed(p))
    80002722:	c31d                	beqz	a4,80002748 <wait+0x11a>
    80002724:	854a                	mv	a0,s2
    80002726:	00000097          	auipc	ra,0x0
    8000272a:	ed6080e7          	jalr	-298(ra) # 800025fc <killed>
    8000272e:	ed09                	bnez	a0,80002748 <wait+0x11a>
        sleep(p, &wait_lock); // DOC: wait-sleep
    80002730:	85e2                	mv	a1,s8
    80002732:	854a                	mv	a0,s2
    80002734:	00000097          	auipc	ra,0x0
    80002738:	c20080e7          	jalr	-992(ra) # 80002354 <sleep>
        havekids = 0;
    8000273c:	875e                	mv	a4,s7
        for (pp = proc; pp < &proc[NPROC]; pp++)
    8000273e:	0002f497          	auipc	s1,0x2f
    80002742:	9d248493          	addi	s1,s1,-1582 # 80031110 <proc>
    80002746:	bf65                	j	800026fe <wait+0xd0>
            release(&wait_lock);
    80002748:	0002f517          	auipc	a0,0x2f
    8000274c:	9b050513          	addi	a0,a0,-1616 # 800310f8 <wait_lock>
    80002750:	ffffe097          	auipc	ra,0xffffe
    80002754:	67e080e7          	jalr	1662(ra) # 80000dce <release>
            return -1;
    80002758:	59fd                	li	s3,-1
    8000275a:	b795                	j	800026be <wait+0x90>

000000008000275c <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000275c:	7179                	addi	sp,sp,-48
    8000275e:	f406                	sd	ra,40(sp)
    80002760:	f022                	sd	s0,32(sp)
    80002762:	ec26                	sd	s1,24(sp)
    80002764:	e84a                	sd	s2,16(sp)
    80002766:	e44e                	sd	s3,8(sp)
    80002768:	e052                	sd	s4,0(sp)
    8000276a:	1800                	addi	s0,sp,48
    8000276c:	84aa                	mv	s1,a0
    8000276e:	892e                	mv	s2,a1
    80002770:	89b2                	mv	s3,a2
    80002772:	8a36                	mv	s4,a3
    struct proc *p = myproc();
    80002774:	fffff097          	auipc	ra,0xfffff
    80002778:	478080e7          	jalr	1144(ra) # 80001bec <myproc>
    if (user_dst)
    8000277c:	c08d                	beqz	s1,8000279e <either_copyout+0x42>
    {
        return copyout(p->pagetable, dst, src, len);
    8000277e:	86d2                	mv	a3,s4
    80002780:	864e                	mv	a2,s3
    80002782:	85ca                	mv	a1,s2
    80002784:	6928                	ld	a0,80(a0)
    80002786:	fffff097          	auipc	ra,0xfffff
    8000278a:	032080e7          	jalr	50(ra) # 800017b8 <copyout>
    else
    {
        memmove((char *)dst, src, len);
        return 0;
    }
}
    8000278e:	70a2                	ld	ra,40(sp)
    80002790:	7402                	ld	s0,32(sp)
    80002792:	64e2                	ld	s1,24(sp)
    80002794:	6942                	ld	s2,16(sp)
    80002796:	69a2                	ld	s3,8(sp)
    80002798:	6a02                	ld	s4,0(sp)
    8000279a:	6145                	addi	sp,sp,48
    8000279c:	8082                	ret
        memmove((char *)dst, src, len);
    8000279e:	000a061b          	sext.w	a2,s4
    800027a2:	85ce                	mv	a1,s3
    800027a4:	854a                	mv	a0,s2
    800027a6:	ffffe097          	auipc	ra,0xffffe
    800027aa:	6cc080e7          	jalr	1740(ra) # 80000e72 <memmove>
        return 0;
    800027ae:	8526                	mv	a0,s1
    800027b0:	bff9                	j	8000278e <either_copyout+0x32>

00000000800027b2 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800027b2:	7179                	addi	sp,sp,-48
    800027b4:	f406                	sd	ra,40(sp)
    800027b6:	f022                	sd	s0,32(sp)
    800027b8:	ec26                	sd	s1,24(sp)
    800027ba:	e84a                	sd	s2,16(sp)
    800027bc:	e44e                	sd	s3,8(sp)
    800027be:	e052                	sd	s4,0(sp)
    800027c0:	1800                	addi	s0,sp,48
    800027c2:	892a                	mv	s2,a0
    800027c4:	84ae                	mv	s1,a1
    800027c6:	89b2                	mv	s3,a2
    800027c8:	8a36                	mv	s4,a3
    struct proc *p = myproc();
    800027ca:	fffff097          	auipc	ra,0xfffff
    800027ce:	422080e7          	jalr	1058(ra) # 80001bec <myproc>
    if (user_src)
    800027d2:	c08d                	beqz	s1,800027f4 <either_copyin+0x42>
    {
        return copyin(p->pagetable, dst, src, len);
    800027d4:	86d2                	mv	a3,s4
    800027d6:	864e                	mv	a2,s3
    800027d8:	85ca                	mv	a1,s2
    800027da:	6928                	ld	a0,80(a0)
    800027dc:	fffff097          	auipc	ra,0xfffff
    800027e0:	068080e7          	jalr	104(ra) # 80001844 <copyin>
    else
    {
        memmove(dst, (char *)src, len);
        return 0;
    }
}
    800027e4:	70a2                	ld	ra,40(sp)
    800027e6:	7402                	ld	s0,32(sp)
    800027e8:	64e2                	ld	s1,24(sp)
    800027ea:	6942                	ld	s2,16(sp)
    800027ec:	69a2                	ld	s3,8(sp)
    800027ee:	6a02                	ld	s4,0(sp)
    800027f0:	6145                	addi	sp,sp,48
    800027f2:	8082                	ret
        memmove(dst, (char *)src, len);
    800027f4:	000a061b          	sext.w	a2,s4
    800027f8:	85ce                	mv	a1,s3
    800027fa:	854a                	mv	a0,s2
    800027fc:	ffffe097          	auipc	ra,0xffffe
    80002800:	676080e7          	jalr	1654(ra) # 80000e72 <memmove>
        return 0;
    80002804:	8526                	mv	a0,s1
    80002806:	bff9                	j	800027e4 <either_copyin+0x32>

0000000080002808 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002808:	715d                	addi	sp,sp,-80
    8000280a:	e486                	sd	ra,72(sp)
    8000280c:	e0a2                	sd	s0,64(sp)
    8000280e:	fc26                	sd	s1,56(sp)
    80002810:	f84a                	sd	s2,48(sp)
    80002812:	f44e                	sd	s3,40(sp)
    80002814:	f052                	sd	s4,32(sp)
    80002816:	ec56                	sd	s5,24(sp)
    80002818:	e85a                	sd	s6,16(sp)
    8000281a:	e45e                	sd	s7,8(sp)
    8000281c:	0880                	addi	s0,sp,80
        [RUNNING] "run   ",
        [ZOMBIE] "zombie"};
    struct proc *p;
    char *state;

    printf("\n");
    8000281e:	00006517          	auipc	a0,0x6
    80002822:	86a50513          	addi	a0,a0,-1942 # 80008088 <digits+0x38>
    80002826:	ffffe097          	auipc	ra,0xffffe
    8000282a:	d72080e7          	jalr	-654(ra) # 80000598 <printf>
    for (p = proc; p < &proc[NPROC]; p++)
    8000282e:	0002f497          	auipc	s1,0x2f
    80002832:	a3a48493          	addi	s1,s1,-1478 # 80031268 <proc+0x158>
    80002836:	00034917          	auipc	s2,0x34
    8000283a:	43290913          	addi	s2,s2,1074 # 80036c68 <bcache+0x140>
    {
        if (p->state == UNUSED)
            continue;
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000283e:	4b15                	li	s6,5
            state = states[p->state];
        else
            state = "???";
    80002840:	00006997          	auipc	s3,0x6
    80002844:	a8098993          	addi	s3,s3,-1408 # 800082c0 <digits+0x270>
        printf("%d <%s %s", p->pid, state, p->name);
    80002848:	00006a97          	auipc	s5,0x6
    8000284c:	a80a8a93          	addi	s5,s5,-1408 # 800082c8 <digits+0x278>
        printf("\n");
    80002850:	00006a17          	auipc	s4,0x6
    80002854:	838a0a13          	addi	s4,s4,-1992 # 80008088 <digits+0x38>
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002858:	00006b97          	auipc	s7,0x6
    8000285c:	b80b8b93          	addi	s7,s7,-1152 # 800083d8 <states.0>
    80002860:	a00d                	j	80002882 <procdump+0x7a>
        printf("%d <%s %s", p->pid, state, p->name);
    80002862:	ed86a583          	lw	a1,-296(a3)
    80002866:	8556                	mv	a0,s5
    80002868:	ffffe097          	auipc	ra,0xffffe
    8000286c:	d30080e7          	jalr	-720(ra) # 80000598 <printf>
        printf("\n");
    80002870:	8552                	mv	a0,s4
    80002872:	ffffe097          	auipc	ra,0xffffe
    80002876:	d26080e7          	jalr	-730(ra) # 80000598 <printf>
    for (p = proc; p < &proc[NPROC]; p++)
    8000287a:	16848493          	addi	s1,s1,360
    8000287e:	03248263          	beq	s1,s2,800028a2 <procdump+0x9a>
        if (p->state == UNUSED)
    80002882:	86a6                	mv	a3,s1
    80002884:	ec04a783          	lw	a5,-320(s1)
    80002888:	dbed                	beqz	a5,8000287a <procdump+0x72>
            state = "???";
    8000288a:	864e                	mv	a2,s3
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000288c:	fcfb6be3          	bltu	s6,a5,80002862 <procdump+0x5a>
    80002890:	02079713          	slli	a4,a5,0x20
    80002894:	01d75793          	srli	a5,a4,0x1d
    80002898:	97de                	add	a5,a5,s7
    8000289a:	6390                	ld	a2,0(a5)
    8000289c:	f279                	bnez	a2,80002862 <procdump+0x5a>
            state = "???";
    8000289e:	864e                	mv	a2,s3
    800028a0:	b7c9                	j	80002862 <procdump+0x5a>
    }
}
    800028a2:	60a6                	ld	ra,72(sp)
    800028a4:	6406                	ld	s0,64(sp)
    800028a6:	74e2                	ld	s1,56(sp)
    800028a8:	7942                	ld	s2,48(sp)
    800028aa:	79a2                	ld	s3,40(sp)
    800028ac:	7a02                	ld	s4,32(sp)
    800028ae:	6ae2                	ld	s5,24(sp)
    800028b0:	6b42                	ld	s6,16(sp)
    800028b2:	6ba2                	ld	s7,8(sp)
    800028b4:	6161                	addi	sp,sp,80
    800028b6:	8082                	ret

00000000800028b8 <schedls>:

void schedls()
{
    800028b8:	1141                	addi	sp,sp,-16
    800028ba:	e406                	sd	ra,8(sp)
    800028bc:	e022                	sd	s0,0(sp)
    800028be:	0800                	addi	s0,sp,16
    printf("[ ]\tScheduler Name\tScheduler ID\n");
    800028c0:	00006517          	auipc	a0,0x6
    800028c4:	a1850513          	addi	a0,a0,-1512 # 800082d8 <digits+0x288>
    800028c8:	ffffe097          	auipc	ra,0xffffe
    800028cc:	cd0080e7          	jalr	-816(ra) # 80000598 <printf>
    printf("====================================\n");
    800028d0:	00006517          	auipc	a0,0x6
    800028d4:	a3050513          	addi	a0,a0,-1488 # 80008300 <digits+0x2b0>
    800028d8:	ffffe097          	auipc	ra,0xffffe
    800028dc:	cc0080e7          	jalr	-832(ra) # 80000598 <printf>
    for (int i = 0; i < SCHEDC; i++)
    {
        if (available_schedulers[i].impl == sched_pointer)
    800028e0:	00006717          	auipc	a4,0x6
    800028e4:	13873703          	ld	a4,312(a4) # 80008a18 <available_schedulers+0x10>
    800028e8:	00006797          	auipc	a5,0x6
    800028ec:	0d07b783          	ld	a5,208(a5) # 800089b8 <sched_pointer>
    800028f0:	04f70663          	beq	a4,a5,8000293c <schedls+0x84>
        {
            printf("[*]\t");
        }
        else
        {
            printf("   \t");
    800028f4:	00006517          	auipc	a0,0x6
    800028f8:	a3c50513          	addi	a0,a0,-1476 # 80008330 <digits+0x2e0>
    800028fc:	ffffe097          	auipc	ra,0xffffe
    80002900:	c9c080e7          	jalr	-868(ra) # 80000598 <printf>
        }
        printf("%s\t%d\n", available_schedulers[i].name, available_schedulers[i].id);
    80002904:	00006617          	auipc	a2,0x6
    80002908:	11c62603          	lw	a2,284(a2) # 80008a20 <available_schedulers+0x18>
    8000290c:	00006597          	auipc	a1,0x6
    80002910:	0fc58593          	addi	a1,a1,252 # 80008a08 <available_schedulers>
    80002914:	00006517          	auipc	a0,0x6
    80002918:	a2450513          	addi	a0,a0,-1500 # 80008338 <digits+0x2e8>
    8000291c:	ffffe097          	auipc	ra,0xffffe
    80002920:	c7c080e7          	jalr	-900(ra) # 80000598 <printf>
    }
    printf("\n*: current scheduler\n\n");
    80002924:	00006517          	auipc	a0,0x6
    80002928:	a1c50513          	addi	a0,a0,-1508 # 80008340 <digits+0x2f0>
    8000292c:	ffffe097          	auipc	ra,0xffffe
    80002930:	c6c080e7          	jalr	-916(ra) # 80000598 <printf>
}
    80002934:	60a2                	ld	ra,8(sp)
    80002936:	6402                	ld	s0,0(sp)
    80002938:	0141                	addi	sp,sp,16
    8000293a:	8082                	ret
            printf("[*]\t");
    8000293c:	00006517          	auipc	a0,0x6
    80002940:	9ec50513          	addi	a0,a0,-1556 # 80008328 <digits+0x2d8>
    80002944:	ffffe097          	auipc	ra,0xffffe
    80002948:	c54080e7          	jalr	-940(ra) # 80000598 <printf>
    8000294c:	bf65                	j	80002904 <schedls+0x4c>

000000008000294e <schedset>:

void schedset(int id)
{
    8000294e:	1141                	addi	sp,sp,-16
    80002950:	e406                	sd	ra,8(sp)
    80002952:	e022                	sd	s0,0(sp)
    80002954:	0800                	addi	s0,sp,16
    if (id < 0 || SCHEDC <= id)
    80002956:	e90d                	bnez	a0,80002988 <schedset+0x3a>
    {
        printf("Scheduler unchanged: ID out of range\n");
        return;
    }
    sched_pointer = available_schedulers[id].impl;
    80002958:	00006797          	auipc	a5,0x6
    8000295c:	0c07b783          	ld	a5,192(a5) # 80008a18 <available_schedulers+0x10>
    80002960:	00006717          	auipc	a4,0x6
    80002964:	04f73c23          	sd	a5,88(a4) # 800089b8 <sched_pointer>
    printf("Scheduler successfully changed to %s\n", available_schedulers[id].name);
    80002968:	00006597          	auipc	a1,0x6
    8000296c:	0a058593          	addi	a1,a1,160 # 80008a08 <available_schedulers>
    80002970:	00006517          	auipc	a0,0x6
    80002974:	a1050513          	addi	a0,a0,-1520 # 80008380 <digits+0x330>
    80002978:	ffffe097          	auipc	ra,0xffffe
    8000297c:	c20080e7          	jalr	-992(ra) # 80000598 <printf>
}
    80002980:	60a2                	ld	ra,8(sp)
    80002982:	6402                	ld	s0,0(sp)
    80002984:	0141                	addi	sp,sp,16
    80002986:	8082                	ret
        printf("Scheduler unchanged: ID out of range\n");
    80002988:	00006517          	auipc	a0,0x6
    8000298c:	9d050513          	addi	a0,a0,-1584 # 80008358 <digits+0x308>
    80002990:	ffffe097          	auipc	ra,0xffffe
    80002994:	c08080e7          	jalr	-1016(ra) # 80000598 <printf>
        return;
    80002998:	b7e5                	j	80002980 <schedset+0x32>

000000008000299a <va2pa>:

uint64 va2pa(uint64 va, int pid) 
{
    8000299a:	1101                	addi	sp,sp,-32
    8000299c:	ec06                	sd	ra,24(sp)
    8000299e:	e822                	sd	s0,16(sp)
    800029a0:	e426                	sd	s1,8(sp)
    800029a2:	e04a                	sd	s2,0(sp)
    800029a4:	1000                	addi	s0,sp,32
    800029a6:	892a                	mv	s2,a0
    800029a8:	84ae                	mv	s1,a1
    // printf("%d", pid);
    struct proc *p = 0;
    pagetable_t pt = myproc()->pagetable;
    800029aa:	fffff097          	auipc	ra,0xfffff
    800029ae:	242080e7          	jalr	578(ra) # 80001bec <myproc>
    800029b2:	6928                	ld	a0,80(a0)
    int found = 0;

    if (pid > 0) {
    800029b4:	02905463          	blez	s1,800029dc <va2pa+0x42>
        for (p = proc; p < &proc[NPROC]; p++) {
    800029b8:	0002e797          	auipc	a5,0x2e
    800029bc:	75878793          	addi	a5,a5,1880 # 80031110 <proc>
    800029c0:	00034697          	auipc	a3,0x34
    800029c4:	15068693          	addi	a3,a3,336 # 80036b10 <tickslock>
            if (p->pid == pid) {
    800029c8:	5b98                	lw	a4,48(a5)
    800029ca:	00970863          	beq	a4,s1,800029da <va2pa+0x40>
        for (p = proc; p < &proc[NPROC]; p++) {
    800029ce:	16878793          	addi	a5,a5,360
    800029d2:	fed79be3          	bne	a5,a3,800029c8 <va2pa+0x2e>
                pt=p->pagetable;
                break;
            }
        }
        if (found == 0) {
            return 0;
    800029d6:	4501                	li	a0,0
    800029d8:	a039                	j	800029e6 <va2pa+0x4c>
                pt=p->pagetable;
    800029da:	6ba8                	ld	a0,80(a5)
        }
    }
    uint64 pa = walkaddr(pt, va);
    800029dc:	85ca                	mv	a1,s2
    800029de:	ffffe097          	auipc	ra,0xffffe
    800029e2:	7c0080e7          	jalr	1984(ra) # 8000119e <walkaddr>
    return pa; 
    800029e6:	60e2                	ld	ra,24(sp)
    800029e8:	6442                	ld	s0,16(sp)
    800029ea:	64a2                	ld	s1,8(sp)
    800029ec:	6902                	ld	s2,0(sp)
    800029ee:	6105                	addi	sp,sp,32
    800029f0:	8082                	ret

00000000800029f2 <swtch>:
    800029f2:	00153023          	sd	ra,0(a0)
    800029f6:	00253423          	sd	sp,8(a0)
    800029fa:	e900                	sd	s0,16(a0)
    800029fc:	ed04                	sd	s1,24(a0)
    800029fe:	03253023          	sd	s2,32(a0)
    80002a02:	03353423          	sd	s3,40(a0)
    80002a06:	03453823          	sd	s4,48(a0)
    80002a0a:	03553c23          	sd	s5,56(a0)
    80002a0e:	05653023          	sd	s6,64(a0)
    80002a12:	05753423          	sd	s7,72(a0)
    80002a16:	05853823          	sd	s8,80(a0)
    80002a1a:	05953c23          	sd	s9,88(a0)
    80002a1e:	07a53023          	sd	s10,96(a0)
    80002a22:	07b53423          	sd	s11,104(a0)
    80002a26:	0005b083          	ld	ra,0(a1)
    80002a2a:	0085b103          	ld	sp,8(a1)
    80002a2e:	6980                	ld	s0,16(a1)
    80002a30:	6d84                	ld	s1,24(a1)
    80002a32:	0205b903          	ld	s2,32(a1)
    80002a36:	0285b983          	ld	s3,40(a1)
    80002a3a:	0305ba03          	ld	s4,48(a1)
    80002a3e:	0385ba83          	ld	s5,56(a1)
    80002a42:	0405bb03          	ld	s6,64(a1)
    80002a46:	0485bb83          	ld	s7,72(a1)
    80002a4a:	0505bc03          	ld	s8,80(a1)
    80002a4e:	0585bc83          	ld	s9,88(a1)
    80002a52:	0605bd03          	ld	s10,96(a1)
    80002a56:	0685bd83          	ld	s11,104(a1)
    80002a5a:	8082                	ret

0000000080002a5c <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002a5c:	1141                	addi	sp,sp,-16
    80002a5e:	e406                	sd	ra,8(sp)
    80002a60:	e022                	sd	s0,0(sp)
    80002a62:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002a64:	00006597          	auipc	a1,0x6
    80002a68:	9a458593          	addi	a1,a1,-1628 # 80008408 <states.0+0x30>
    80002a6c:	00034517          	auipc	a0,0x34
    80002a70:	0a450513          	addi	a0,a0,164 # 80036b10 <tickslock>
    80002a74:	ffffe097          	auipc	ra,0xffffe
    80002a78:	216080e7          	jalr	534(ra) # 80000c8a <initlock>
}
    80002a7c:	60a2                	ld	ra,8(sp)
    80002a7e:	6402                	ld	s0,0(sp)
    80002a80:	0141                	addi	sp,sp,16
    80002a82:	8082                	ret

0000000080002a84 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002a84:	1141                	addi	sp,sp,-16
    80002a86:	e422                	sd	s0,8(sp)
    80002a88:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a8a:	00003797          	auipc	a5,0x3
    80002a8e:	63678793          	addi	a5,a5,1590 # 800060c0 <kernelvec>
    80002a92:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002a96:	6422                	ld	s0,8(sp)
    80002a98:	0141                	addi	sp,sp,16
    80002a9a:	8082                	ret

0000000080002a9c <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002a9c:	1141                	addi	sp,sp,-16
    80002a9e:	e406                	sd	ra,8(sp)
    80002aa0:	e022                	sd	s0,0(sp)
    80002aa2:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002aa4:	fffff097          	auipc	ra,0xfffff
    80002aa8:	148080e7          	jalr	328(ra) # 80001bec <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002aac:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002ab0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ab2:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002ab6:	00004697          	auipc	a3,0x4
    80002aba:	54a68693          	addi	a3,a3,1354 # 80007000 <_trampoline>
    80002abe:	00004717          	auipc	a4,0x4
    80002ac2:	54270713          	addi	a4,a4,1346 # 80007000 <_trampoline>
    80002ac6:	8f15                	sub	a4,a4,a3
    80002ac8:	040007b7          	lui	a5,0x4000
    80002acc:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002ace:	07b2                	slli	a5,a5,0xc
    80002ad0:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002ad2:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002ad6:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002ad8:	18002673          	csrr	a2,satp
    80002adc:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002ade:	6d30                	ld	a2,88(a0)
    80002ae0:	6138                	ld	a4,64(a0)
    80002ae2:	6585                	lui	a1,0x1
    80002ae4:	972e                	add	a4,a4,a1
    80002ae6:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002ae8:	6d38                	ld	a4,88(a0)
    80002aea:	00000617          	auipc	a2,0x0
    80002aee:	13460613          	addi	a2,a2,308 # 80002c1e <usertrap>
    80002af2:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002af4:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002af6:	8612                	mv	a2,tp
    80002af8:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002afa:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002afe:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002b02:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b06:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002b0a:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002b0c:	6f18                	ld	a4,24(a4)
    80002b0e:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002b12:	6928                	ld	a0,80(a0)
    80002b14:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002b16:	00004717          	auipc	a4,0x4
    80002b1a:	58670713          	addi	a4,a4,1414 # 8000709c <userret>
    80002b1e:	8f15                	sub	a4,a4,a3
    80002b20:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002b22:	577d                	li	a4,-1
    80002b24:	177e                	slli	a4,a4,0x3f
    80002b26:	8d59                	or	a0,a0,a4
    80002b28:	9782                	jalr	a5
}
    80002b2a:	60a2                	ld	ra,8(sp)
    80002b2c:	6402                	ld	s0,0(sp)
    80002b2e:	0141                	addi	sp,sp,16
    80002b30:	8082                	ret

0000000080002b32 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002b32:	1101                	addi	sp,sp,-32
    80002b34:	ec06                	sd	ra,24(sp)
    80002b36:	e822                	sd	s0,16(sp)
    80002b38:	e426                	sd	s1,8(sp)
    80002b3a:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002b3c:	00034497          	auipc	s1,0x34
    80002b40:	fd448493          	addi	s1,s1,-44 # 80036b10 <tickslock>
    80002b44:	8526                	mv	a0,s1
    80002b46:	ffffe097          	auipc	ra,0xffffe
    80002b4a:	1d4080e7          	jalr	468(ra) # 80000d1a <acquire>
  ticks++;
    80002b4e:	00006517          	auipc	a0,0x6
    80002b52:	f2250513          	addi	a0,a0,-222 # 80008a70 <ticks>
    80002b56:	411c                	lw	a5,0(a0)
    80002b58:	2785                	addiw	a5,a5,1
    80002b5a:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002b5c:	00000097          	auipc	ra,0x0
    80002b60:	85c080e7          	jalr	-1956(ra) # 800023b8 <wakeup>
  release(&tickslock);
    80002b64:	8526                	mv	a0,s1
    80002b66:	ffffe097          	auipc	ra,0xffffe
    80002b6a:	268080e7          	jalr	616(ra) # 80000dce <release>
}
    80002b6e:	60e2                	ld	ra,24(sp)
    80002b70:	6442                	ld	s0,16(sp)
    80002b72:	64a2                	ld	s1,8(sp)
    80002b74:	6105                	addi	sp,sp,32
    80002b76:	8082                	ret

0000000080002b78 <devintr>:
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b78:	142027f3          	csrr	a5,scause
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002b7c:	4501                	li	a0,0
  if((scause & 0x8000000000000000L) &&
    80002b7e:	0807df63          	bgez	a5,80002c1c <devintr+0xa4>
{
    80002b82:	1101                	addi	sp,sp,-32
    80002b84:	ec06                	sd	ra,24(sp)
    80002b86:	e822                	sd	s0,16(sp)
    80002b88:	e426                	sd	s1,8(sp)
    80002b8a:	1000                	addi	s0,sp,32
     (scause & 0xff) == 9){
    80002b8c:	0ff7f713          	zext.b	a4,a5
  if((scause & 0x8000000000000000L) &&
    80002b90:	46a5                	li	a3,9
    80002b92:	00d70d63          	beq	a4,a3,80002bac <devintr+0x34>
  } else if(scause == 0x8000000000000001L){
    80002b96:	577d                	li	a4,-1
    80002b98:	177e                	slli	a4,a4,0x3f
    80002b9a:	0705                	addi	a4,a4,1
    return 0;
    80002b9c:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002b9e:	04e78e63          	beq	a5,a4,80002bfa <devintr+0x82>
  }
}
    80002ba2:	60e2                	ld	ra,24(sp)
    80002ba4:	6442                	ld	s0,16(sp)
    80002ba6:	64a2                	ld	s1,8(sp)
    80002ba8:	6105                	addi	sp,sp,32
    80002baa:	8082                	ret
    int irq = plic_claim();
    80002bac:	00003097          	auipc	ra,0x3
    80002bb0:	61c080e7          	jalr	1564(ra) # 800061c8 <plic_claim>
    80002bb4:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002bb6:	47a9                	li	a5,10
    80002bb8:	02f50763          	beq	a0,a5,80002be6 <devintr+0x6e>
    } else if(irq == VIRTIO0_IRQ){
    80002bbc:	4785                	li	a5,1
    80002bbe:	02f50963          	beq	a0,a5,80002bf0 <devintr+0x78>
    return 1;
    80002bc2:	4505                	li	a0,1
    } else if(irq){
    80002bc4:	dcf9                	beqz	s1,80002ba2 <devintr+0x2a>
      printf("unexpected interrupt irq=%d\n", irq);
    80002bc6:	85a6                	mv	a1,s1
    80002bc8:	00006517          	auipc	a0,0x6
    80002bcc:	84850513          	addi	a0,a0,-1976 # 80008410 <states.0+0x38>
    80002bd0:	ffffe097          	auipc	ra,0xffffe
    80002bd4:	9c8080e7          	jalr	-1592(ra) # 80000598 <printf>
      plic_complete(irq);
    80002bd8:	8526                	mv	a0,s1
    80002bda:	00003097          	auipc	ra,0x3
    80002bde:	612080e7          	jalr	1554(ra) # 800061ec <plic_complete>
    return 1;
    80002be2:	4505                	li	a0,1
    80002be4:	bf7d                	j	80002ba2 <devintr+0x2a>
      uartintr();
    80002be6:	ffffe097          	auipc	ra,0xffffe
    80002bea:	dc0080e7          	jalr	-576(ra) # 800009a6 <uartintr>
    if(irq)
    80002bee:	b7ed                	j	80002bd8 <devintr+0x60>
      virtio_disk_intr();
    80002bf0:	00004097          	auipc	ra,0x4
    80002bf4:	ac2080e7          	jalr	-1342(ra) # 800066b2 <virtio_disk_intr>
    if(irq)
    80002bf8:	b7c5                	j	80002bd8 <devintr+0x60>
    if(cpuid() == 0){
    80002bfa:	fffff097          	auipc	ra,0xfffff
    80002bfe:	fc6080e7          	jalr	-58(ra) # 80001bc0 <cpuid>
    80002c02:	c901                	beqz	a0,80002c12 <devintr+0x9a>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002c04:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002c08:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002c0a:	14479073          	csrw	sip,a5
    return 2;
    80002c0e:	4509                	li	a0,2
    80002c10:	bf49                	j	80002ba2 <devintr+0x2a>
      clockintr();
    80002c12:	00000097          	auipc	ra,0x0
    80002c16:	f20080e7          	jalr	-224(ra) # 80002b32 <clockintr>
    80002c1a:	b7ed                	j	80002c04 <devintr+0x8c>
}
    80002c1c:	8082                	ret

0000000080002c1e <usertrap>:
{
    80002c1e:	7139                	addi	sp,sp,-64
    80002c20:	fc06                	sd	ra,56(sp)
    80002c22:	f822                	sd	s0,48(sp)
    80002c24:	f426                	sd	s1,40(sp)
    80002c26:	f04a                	sd	s2,32(sp)
    80002c28:	ec4e                	sd	s3,24(sp)
    80002c2a:	e852                	sd	s4,16(sp)
    80002c2c:	e456                	sd	s5,8(sp)
    80002c2e:	0080                	addi	s0,sp,64
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c30:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002c34:	1007f793          	andi	a5,a5,256
    80002c38:	eba9                	bnez	a5,80002c8a <usertrap+0x6c>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c3a:	00003797          	auipc	a5,0x3
    80002c3e:	48678793          	addi	a5,a5,1158 # 800060c0 <kernelvec>
    80002c42:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002c46:	fffff097          	auipc	ra,0xfffff
    80002c4a:	fa6080e7          	jalr	-90(ra) # 80001bec <myproc>
    80002c4e:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002c50:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c52:	14102773          	csrr	a4,sepc
    80002c56:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c58:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002c5c:	47a1                	li	a5,8
    80002c5e:	02f70e63          	beq	a4,a5,80002c9a <usertrap+0x7c>
    80002c62:	14202773          	csrr	a4,scause
  } else if(r_scause() == 15){
    80002c66:	47bd                	li	a5,15
    80002c68:	06f70363          	beq	a4,a5,80002cce <usertrap+0xb0>
    } else if((which_dev = devintr()) != 0){
    80002c6c:	00000097          	auipc	ra,0x0
    80002c70:	f0c080e7          	jalr	-244(ra) # 80002b78 <devintr>
    80002c74:	892a                	mv	s2,a0
    80002c76:	12050b63          	beqz	a0,80002dac <usertrap+0x18e>
  if(killed(p))
    80002c7a:	8526                	mv	a0,s1
    80002c7c:	00000097          	auipc	ra,0x0
    80002c80:	980080e7          	jalr	-1664(ra) # 800025fc <killed>
    80002c84:	16050763          	beqz	a0,80002df2 <usertrap+0x1d4>
    80002c88:	a285                	j	80002de8 <usertrap+0x1ca>
    panic("usertrap: not from user mode");
    80002c8a:	00005517          	auipc	a0,0x5
    80002c8e:	7a650513          	addi	a0,a0,1958 # 80008430 <states.0+0x58>
    80002c92:	ffffe097          	auipc	ra,0xffffe
    80002c96:	8aa080e7          	jalr	-1878(ra) # 8000053c <panic>
    if(killed(p))
    80002c9a:	00000097          	auipc	ra,0x0
    80002c9e:	962080e7          	jalr	-1694(ra) # 800025fc <killed>
    80002ca2:	e105                	bnez	a0,80002cc2 <usertrap+0xa4>
    p->trapframe->epc += 4;
    80002ca4:	6cb8                	ld	a4,88(s1)
    80002ca6:	6f1c                	ld	a5,24(a4)
    80002ca8:	0791                	addi	a5,a5,4
    80002caa:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002cac:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002cb0:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002cb4:	10079073          	csrw	sstatus,a5
    syscall();
    80002cb8:	00000097          	auipc	ra,0x0
    80002cbc:	394080e7          	jalr	916(ra) # 8000304c <syscall>
    80002cc0:	a069                	j	80002d4a <usertrap+0x12c>
      exit(-1);
    80002cc2:	557d                	li	a0,-1
    80002cc4:	fffff097          	auipc	ra,0xfffff
    80002cc8:	7c4080e7          	jalr	1988(ra) # 80002488 <exit>
    80002ccc:	bfe1                	j	80002ca4 <usertrap+0x86>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002cce:	143029f3          	csrr	s3,stval
        uint64 faultingAddress = PGROUNDDOWN(r_stval()); // Get the faulting address (saved in the stval register). Tip from piazza to use PGROUNDDOWN in able to use the value.
    80002cd2:	77fd                	lui	a5,0xfffff
    80002cd4:	00f9f9b3          	and	s3,s3,a5
        pte = walk(p->pagetable, faultingAddress, 0); // Get the page table entry.
    80002cd8:	4601                	li	a2,0
    80002cda:	85ce                	mv	a1,s3
    80002cdc:	6928                	ld	a0,80(a0)
    80002cde:	ffffe097          	auipc	ra,0xffffe
    80002ce2:	41a080e7          	jalr	1050(ra) # 800010f8 <walk>
    80002ce6:	892a                	mv	s2,a0
        if (pte == 0){
    80002ce8:	c541                	beqz	a0,80002d70 <usertrap+0x152>
        if (*pte & PTE_COW){
    80002cea:	00053a03          	ld	s4,0(a0)
    80002cee:	008a7793          	andi	a5,s4,8
    80002cf2:	c3dd                	beqz	a5,80002d98 <usertrap+0x17a>
            void *mem = kalloc(); // Allocate a new page.
    80002cf4:	ffffe097          	auipc	ra,0xffffe
    80002cf8:	e9c080e7          	jalr	-356(ra) # 80000b90 <kalloc>
    80002cfc:	8aaa                	mv	s5,a0
            void *pa = (void *)PTE2PA(*pte);
    80002cfe:	00093903          	ld	s2,0(s2)
    80002d02:	00a95913          	srli	s2,s2,0xa
    80002d06:	0932                	slli	s2,s2,0xc
            uvmunmap(p->pagetable, faultingAddress, 1, 0); // Unmap the COW page.
    80002d08:	4681                	li	a3,0
    80002d0a:	4605                	li	a2,1
    80002d0c:	85ce                	mv	a1,s3
    80002d0e:	68a8                	ld	a0,80(s1)
    80002d10:	ffffe097          	auipc	ra,0xffffe
    80002d14:	696080e7          	jalr	1686(ra) # 800013a6 <uvmunmap>
            memmove(mem, pa, PGSIZE); // Copy the data from the COW page to the new page.
    80002d18:	6605                	lui	a2,0x1
    80002d1a:	85ca                	mv	a1,s2
    80002d1c:	8556                	mv	a0,s5
    80002d1e:	ffffe097          	auipc	ra,0xffffe
    80002d22:	154080e7          	jalr	340(ra) # 80000e72 <memmove>
            decrement_reference_counter(pa);
    80002d26:	854a                	mv	a0,s2
    80002d28:	ffffe097          	auipc	ra,0xffffe
    80002d2c:	f1e080e7          	jalr	-226(ra) # 80000c46 <decrement_reference_counter>
            flags &= ~PTE_COW; // Not a COW
    80002d30:	3f7a7713          	andi	a4,s4,1015
            if (mappages(p->pagetable, faultingAddress, PGSIZE, (uint64)mem, flags) != 0)
    80002d34:	00476713          	ori	a4,a4,4
    80002d38:	86d6                	mv	a3,s5
    80002d3a:	6605                	lui	a2,0x1
    80002d3c:	85ce                	mv	a1,s3
    80002d3e:	68a8                	ld	a0,80(s1)
    80002d40:	ffffe097          	auipc	ra,0xffffe
    80002d44:	4a0080e7          	jalr	1184(ra) # 800011e0 <mappages>
    80002d48:	ed15                	bnez	a0,80002d84 <usertrap+0x166>
  if(killed(p))
    80002d4a:	8526                	mv	a0,s1
    80002d4c:	00000097          	auipc	ra,0x0
    80002d50:	8b0080e7          	jalr	-1872(ra) # 800025fc <killed>
    80002d54:	e949                	bnez	a0,80002de6 <usertrap+0x1c8>
  usertrapret();
    80002d56:	00000097          	auipc	ra,0x0
    80002d5a:	d46080e7          	jalr	-698(ra) # 80002a9c <usertrapret>
}
    80002d5e:	70e2                	ld	ra,56(sp)
    80002d60:	7442                	ld	s0,48(sp)
    80002d62:	74a2                	ld	s1,40(sp)
    80002d64:	7902                	ld	s2,32(sp)
    80002d66:	69e2                	ld	s3,24(sp)
    80002d68:	6a42                	ld	s4,16(sp)
    80002d6a:	6aa2                	ld	s5,8(sp)
    80002d6c:	6121                	addi	sp,sp,64
    80002d6e:	8082                	ret
            p->killed = 1;
    80002d70:	4785                	li	a5,1
    80002d72:	d49c                	sw	a5,40(s1)
            panic("Something went wrong.");
    80002d74:	00005517          	auipc	a0,0x5
    80002d78:	6dc50513          	addi	a0,a0,1756 # 80008450 <states.0+0x78>
    80002d7c:	ffffd097          	auipc	ra,0xffffd
    80002d80:	7c0080e7          	jalr	1984(ra) # 8000053c <panic>
                p->killed = 1;
    80002d84:	4785                	li	a5,1
    80002d86:	d49c                	sw	a5,40(s1)
                panic("Something went wrong.");
    80002d88:	00005517          	auipc	a0,0x5
    80002d8c:	6c850513          	addi	a0,a0,1736 # 80008450 <states.0+0x78>
    80002d90:	ffffd097          	auipc	ra,0xffffd
    80002d94:	7ac080e7          	jalr	1964(ra) # 8000053c <panic>
            p->killed = 1;
    80002d98:	4785                	li	a5,1
    80002d9a:	d49c                	sw	a5,40(s1)
            panic("Something went wrong. ");
    80002d9c:	00005517          	auipc	a0,0x5
    80002da0:	6cc50513          	addi	a0,a0,1740 # 80008468 <states.0+0x90>
    80002da4:	ffffd097          	auipc	ra,0xffffd
    80002da8:	798080e7          	jalr	1944(ra) # 8000053c <panic>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002dac:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002db0:	5890                	lw	a2,48(s1)
    80002db2:	00005517          	auipc	a0,0x5
    80002db6:	6ce50513          	addi	a0,a0,1742 # 80008480 <states.0+0xa8>
    80002dba:	ffffd097          	auipc	ra,0xffffd
    80002dbe:	7de080e7          	jalr	2014(ra) # 80000598 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002dc2:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002dc6:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002dca:	00005517          	auipc	a0,0x5
    80002dce:	6e650513          	addi	a0,a0,1766 # 800084b0 <states.0+0xd8>
    80002dd2:	ffffd097          	auipc	ra,0xffffd
    80002dd6:	7c6080e7          	jalr	1990(ra) # 80000598 <printf>
    setkilled(p);
    80002dda:	8526                	mv	a0,s1
    80002ddc:	fffff097          	auipc	ra,0xfffff
    80002de0:	7f4080e7          	jalr	2036(ra) # 800025d0 <setkilled>
    80002de4:	b79d                	j	80002d4a <usertrap+0x12c>
  if(killed(p))
    80002de6:	4901                	li	s2,0
    exit(-1);
    80002de8:	557d                	li	a0,-1
    80002dea:	fffff097          	auipc	ra,0xfffff
    80002dee:	69e080e7          	jalr	1694(ra) # 80002488 <exit>
  if(which_dev == 2)
    80002df2:	4789                	li	a5,2
    80002df4:	f6f911e3          	bne	s2,a5,80002d56 <usertrap+0x138>
    yield();
    80002df8:	fffff097          	auipc	ra,0xfffff
    80002dfc:	520080e7          	jalr	1312(ra) # 80002318 <yield>
    80002e00:	bf99                	j	80002d56 <usertrap+0x138>

0000000080002e02 <kerneltrap>:
{
    80002e02:	7179                	addi	sp,sp,-48
    80002e04:	f406                	sd	ra,40(sp)
    80002e06:	f022                	sd	s0,32(sp)
    80002e08:	ec26                	sd	s1,24(sp)
    80002e0a:	e84a                	sd	s2,16(sp)
    80002e0c:	e44e                	sd	s3,8(sp)
    80002e0e:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e10:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e14:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e18:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002e1c:	1004f793          	andi	a5,s1,256
    80002e20:	cb85                	beqz	a5,80002e50 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e22:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002e26:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002e28:	ef85                	bnez	a5,80002e60 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002e2a:	00000097          	auipc	ra,0x0
    80002e2e:	d4e080e7          	jalr	-690(ra) # 80002b78 <devintr>
    80002e32:	cd1d                	beqz	a0,80002e70 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002e34:	4789                	li	a5,2
    80002e36:	06f50a63          	beq	a0,a5,80002eaa <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002e3a:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e3e:	10049073          	csrw	sstatus,s1
}
    80002e42:	70a2                	ld	ra,40(sp)
    80002e44:	7402                	ld	s0,32(sp)
    80002e46:	64e2                	ld	s1,24(sp)
    80002e48:	6942                	ld	s2,16(sp)
    80002e4a:	69a2                	ld	s3,8(sp)
    80002e4c:	6145                	addi	sp,sp,48
    80002e4e:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002e50:	00005517          	auipc	a0,0x5
    80002e54:	68050513          	addi	a0,a0,1664 # 800084d0 <states.0+0xf8>
    80002e58:	ffffd097          	auipc	ra,0xffffd
    80002e5c:	6e4080e7          	jalr	1764(ra) # 8000053c <panic>
    panic("kerneltrap: interrupts enabled");
    80002e60:	00005517          	auipc	a0,0x5
    80002e64:	69850513          	addi	a0,a0,1688 # 800084f8 <states.0+0x120>
    80002e68:	ffffd097          	auipc	ra,0xffffd
    80002e6c:	6d4080e7          	jalr	1748(ra) # 8000053c <panic>
    printf("scause %p\n", scause);
    80002e70:	85ce                	mv	a1,s3
    80002e72:	00005517          	auipc	a0,0x5
    80002e76:	6a650513          	addi	a0,a0,1702 # 80008518 <states.0+0x140>
    80002e7a:	ffffd097          	auipc	ra,0xffffd
    80002e7e:	71e080e7          	jalr	1822(ra) # 80000598 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e82:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002e86:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002e8a:	00005517          	auipc	a0,0x5
    80002e8e:	69e50513          	addi	a0,a0,1694 # 80008528 <states.0+0x150>
    80002e92:	ffffd097          	auipc	ra,0xffffd
    80002e96:	706080e7          	jalr	1798(ra) # 80000598 <printf>
    panic("kerneltrap");
    80002e9a:	00005517          	auipc	a0,0x5
    80002e9e:	6a650513          	addi	a0,a0,1702 # 80008540 <states.0+0x168>
    80002ea2:	ffffd097          	auipc	ra,0xffffd
    80002ea6:	69a080e7          	jalr	1690(ra) # 8000053c <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002eaa:	fffff097          	auipc	ra,0xfffff
    80002eae:	d42080e7          	jalr	-702(ra) # 80001bec <myproc>
    80002eb2:	d541                	beqz	a0,80002e3a <kerneltrap+0x38>
    80002eb4:	fffff097          	auipc	ra,0xfffff
    80002eb8:	d38080e7          	jalr	-712(ra) # 80001bec <myproc>
    80002ebc:	4d18                	lw	a4,24(a0)
    80002ebe:	4791                	li	a5,4
    80002ec0:	f6f71de3          	bne	a4,a5,80002e3a <kerneltrap+0x38>
    yield();
    80002ec4:	fffff097          	auipc	ra,0xfffff
    80002ec8:	454080e7          	jalr	1108(ra) # 80002318 <yield>
    80002ecc:	b7bd                	j	80002e3a <kerneltrap+0x38>

0000000080002ece <argraw>:
    return strlen(buf);
}

static uint64
argraw(int n)
{
    80002ece:	1101                	addi	sp,sp,-32
    80002ed0:	ec06                	sd	ra,24(sp)
    80002ed2:	e822                	sd	s0,16(sp)
    80002ed4:	e426                	sd	s1,8(sp)
    80002ed6:	1000                	addi	s0,sp,32
    80002ed8:	84aa                	mv	s1,a0
    struct proc *p = myproc();
    80002eda:	fffff097          	auipc	ra,0xfffff
    80002ede:	d12080e7          	jalr	-750(ra) # 80001bec <myproc>
    switch (n)
    80002ee2:	4795                	li	a5,5
    80002ee4:	0497e163          	bltu	a5,s1,80002f26 <argraw+0x58>
    80002ee8:	048a                	slli	s1,s1,0x2
    80002eea:	00005717          	auipc	a4,0x5
    80002eee:	68e70713          	addi	a4,a4,1678 # 80008578 <states.0+0x1a0>
    80002ef2:	94ba                	add	s1,s1,a4
    80002ef4:	409c                	lw	a5,0(s1)
    80002ef6:	97ba                	add	a5,a5,a4
    80002ef8:	8782                	jr	a5
    {
    case 0:
        return p->trapframe->a0;
    80002efa:	6d3c                	ld	a5,88(a0)
    80002efc:	7ba8                	ld	a0,112(a5)
    case 5:
        return p->trapframe->a5;
    }
    panic("argraw");
    return -1;
}
    80002efe:	60e2                	ld	ra,24(sp)
    80002f00:	6442                	ld	s0,16(sp)
    80002f02:	64a2                	ld	s1,8(sp)
    80002f04:	6105                	addi	sp,sp,32
    80002f06:	8082                	ret
        return p->trapframe->a1;
    80002f08:	6d3c                	ld	a5,88(a0)
    80002f0a:	7fa8                	ld	a0,120(a5)
    80002f0c:	bfcd                	j	80002efe <argraw+0x30>
        return p->trapframe->a2;
    80002f0e:	6d3c                	ld	a5,88(a0)
    80002f10:	63c8                	ld	a0,128(a5)
    80002f12:	b7f5                	j	80002efe <argraw+0x30>
        return p->trapframe->a3;
    80002f14:	6d3c                	ld	a5,88(a0)
    80002f16:	67c8                	ld	a0,136(a5)
    80002f18:	b7dd                	j	80002efe <argraw+0x30>
        return p->trapframe->a4;
    80002f1a:	6d3c                	ld	a5,88(a0)
    80002f1c:	6bc8                	ld	a0,144(a5)
    80002f1e:	b7c5                	j	80002efe <argraw+0x30>
        return p->trapframe->a5;
    80002f20:	6d3c                	ld	a5,88(a0)
    80002f22:	6fc8                	ld	a0,152(a5)
    80002f24:	bfe9                	j	80002efe <argraw+0x30>
    panic("argraw");
    80002f26:	00005517          	auipc	a0,0x5
    80002f2a:	62a50513          	addi	a0,a0,1578 # 80008550 <states.0+0x178>
    80002f2e:	ffffd097          	auipc	ra,0xffffd
    80002f32:	60e080e7          	jalr	1550(ra) # 8000053c <panic>

0000000080002f36 <fetchaddr>:
{
    80002f36:	1101                	addi	sp,sp,-32
    80002f38:	ec06                	sd	ra,24(sp)
    80002f3a:	e822                	sd	s0,16(sp)
    80002f3c:	e426                	sd	s1,8(sp)
    80002f3e:	e04a                	sd	s2,0(sp)
    80002f40:	1000                	addi	s0,sp,32
    80002f42:	84aa                	mv	s1,a0
    80002f44:	892e                	mv	s2,a1
    struct proc *p = myproc();
    80002f46:	fffff097          	auipc	ra,0xfffff
    80002f4a:	ca6080e7          	jalr	-858(ra) # 80001bec <myproc>
    if (addr >= p->sz || addr + sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002f4e:	653c                	ld	a5,72(a0)
    80002f50:	02f4f863          	bgeu	s1,a5,80002f80 <fetchaddr+0x4a>
    80002f54:	00848713          	addi	a4,s1,8
    80002f58:	02e7e663          	bltu	a5,a4,80002f84 <fetchaddr+0x4e>
    if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002f5c:	46a1                	li	a3,8
    80002f5e:	8626                	mv	a2,s1
    80002f60:	85ca                	mv	a1,s2
    80002f62:	6928                	ld	a0,80(a0)
    80002f64:	fffff097          	auipc	ra,0xfffff
    80002f68:	8e0080e7          	jalr	-1824(ra) # 80001844 <copyin>
    80002f6c:	00a03533          	snez	a0,a0
    80002f70:	40a00533          	neg	a0,a0
}
    80002f74:	60e2                	ld	ra,24(sp)
    80002f76:	6442                	ld	s0,16(sp)
    80002f78:	64a2                	ld	s1,8(sp)
    80002f7a:	6902                	ld	s2,0(sp)
    80002f7c:	6105                	addi	sp,sp,32
    80002f7e:	8082                	ret
        return -1;
    80002f80:	557d                	li	a0,-1
    80002f82:	bfcd                	j	80002f74 <fetchaddr+0x3e>
    80002f84:	557d                	li	a0,-1
    80002f86:	b7fd                	j	80002f74 <fetchaddr+0x3e>

0000000080002f88 <fetchstr>:
{
    80002f88:	7179                	addi	sp,sp,-48
    80002f8a:	f406                	sd	ra,40(sp)
    80002f8c:	f022                	sd	s0,32(sp)
    80002f8e:	ec26                	sd	s1,24(sp)
    80002f90:	e84a                	sd	s2,16(sp)
    80002f92:	e44e                	sd	s3,8(sp)
    80002f94:	1800                	addi	s0,sp,48
    80002f96:	892a                	mv	s2,a0
    80002f98:	84ae                	mv	s1,a1
    80002f9a:	89b2                	mv	s3,a2
    struct proc *p = myproc();
    80002f9c:	fffff097          	auipc	ra,0xfffff
    80002fa0:	c50080e7          	jalr	-944(ra) # 80001bec <myproc>
    if (copyinstr(p->pagetable, buf, addr, max) < 0)
    80002fa4:	86ce                	mv	a3,s3
    80002fa6:	864a                	mv	a2,s2
    80002fa8:	85a6                	mv	a1,s1
    80002faa:	6928                	ld	a0,80(a0)
    80002fac:	fffff097          	auipc	ra,0xfffff
    80002fb0:	926080e7          	jalr	-1754(ra) # 800018d2 <copyinstr>
    80002fb4:	00054e63          	bltz	a0,80002fd0 <fetchstr+0x48>
    return strlen(buf);
    80002fb8:	8526                	mv	a0,s1
    80002fba:	ffffe097          	auipc	ra,0xffffe
    80002fbe:	fd6080e7          	jalr	-42(ra) # 80000f90 <strlen>
}
    80002fc2:	70a2                	ld	ra,40(sp)
    80002fc4:	7402                	ld	s0,32(sp)
    80002fc6:	64e2                	ld	s1,24(sp)
    80002fc8:	6942                	ld	s2,16(sp)
    80002fca:	69a2                	ld	s3,8(sp)
    80002fcc:	6145                	addi	sp,sp,48
    80002fce:	8082                	ret
        return -1;
    80002fd0:	557d                	li	a0,-1
    80002fd2:	bfc5                	j	80002fc2 <fetchstr+0x3a>

0000000080002fd4 <argint>:

// Fetch the nth 32-bit system call argument.
void argint(int n, int *ip)
{
    80002fd4:	1101                	addi	sp,sp,-32
    80002fd6:	ec06                	sd	ra,24(sp)
    80002fd8:	e822                	sd	s0,16(sp)
    80002fda:	e426                	sd	s1,8(sp)
    80002fdc:	1000                	addi	s0,sp,32
    80002fde:	84ae                	mv	s1,a1
    *ip = argraw(n);
    80002fe0:	00000097          	auipc	ra,0x0
    80002fe4:	eee080e7          	jalr	-274(ra) # 80002ece <argraw>
    80002fe8:	c088                	sw	a0,0(s1)
}
    80002fea:	60e2                	ld	ra,24(sp)
    80002fec:	6442                	ld	s0,16(sp)
    80002fee:	64a2                	ld	s1,8(sp)
    80002ff0:	6105                	addi	sp,sp,32
    80002ff2:	8082                	ret

0000000080002ff4 <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void argaddr(int n, uint64 *ip)
{
    80002ff4:	1101                	addi	sp,sp,-32
    80002ff6:	ec06                	sd	ra,24(sp)
    80002ff8:	e822                	sd	s0,16(sp)
    80002ffa:	e426                	sd	s1,8(sp)
    80002ffc:	1000                	addi	s0,sp,32
    80002ffe:	84ae                	mv	s1,a1
    *ip = argraw(n);
    80003000:	00000097          	auipc	ra,0x0
    80003004:	ece080e7          	jalr	-306(ra) # 80002ece <argraw>
    80003008:	e088                	sd	a0,0(s1)
}
    8000300a:	60e2                	ld	ra,24(sp)
    8000300c:	6442                	ld	s0,16(sp)
    8000300e:	64a2                	ld	s1,8(sp)
    80003010:	6105                	addi	sp,sp,32
    80003012:	8082                	ret

0000000080003014 <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    80003014:	7179                	addi	sp,sp,-48
    80003016:	f406                	sd	ra,40(sp)
    80003018:	f022                	sd	s0,32(sp)
    8000301a:	ec26                	sd	s1,24(sp)
    8000301c:	e84a                	sd	s2,16(sp)
    8000301e:	1800                	addi	s0,sp,48
    80003020:	84ae                	mv	s1,a1
    80003022:	8932                	mv	s2,a2
    uint64 addr;
    argaddr(n, &addr);
    80003024:	fd840593          	addi	a1,s0,-40
    80003028:	00000097          	auipc	ra,0x0
    8000302c:	fcc080e7          	jalr	-52(ra) # 80002ff4 <argaddr>
    return fetchstr(addr, buf, max);
    80003030:	864a                	mv	a2,s2
    80003032:	85a6                	mv	a1,s1
    80003034:	fd843503          	ld	a0,-40(s0)
    80003038:	00000097          	auipc	ra,0x0
    8000303c:	f50080e7          	jalr	-176(ra) # 80002f88 <fetchstr>
}
    80003040:	70a2                	ld	ra,40(sp)
    80003042:	7402                	ld	s0,32(sp)
    80003044:	64e2                	ld	s1,24(sp)
    80003046:	6942                	ld	s2,16(sp)
    80003048:	6145                	addi	sp,sp,48
    8000304a:	8082                	ret

000000008000304c <syscall>:
    [SYS_pfreepages] sys_pfreepages,
    [SYS_va2pa] sys_va2pa,
};

void syscall(void)
{
    8000304c:	1101                	addi	sp,sp,-32
    8000304e:	ec06                	sd	ra,24(sp)
    80003050:	e822                	sd	s0,16(sp)
    80003052:	e426                	sd	s1,8(sp)
    80003054:	e04a                	sd	s2,0(sp)
    80003056:	1000                	addi	s0,sp,32
    int num;
    struct proc *p = myproc();
    80003058:	fffff097          	auipc	ra,0xfffff
    8000305c:	b94080e7          	jalr	-1132(ra) # 80001bec <myproc>
    80003060:	84aa                	mv	s1,a0

    num = p->trapframe->a7;
    80003062:	05853903          	ld	s2,88(a0)
    80003066:	0a893783          	ld	a5,168(s2)
    8000306a:	0007869b          	sext.w	a3,a5
    if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    8000306e:	37fd                	addiw	a5,a5,-1 # ffffffffffffefff <end+0xffffffff7ffbd10f>
    80003070:	4765                	li	a4,25
    80003072:	00f76f63          	bltu	a4,a5,80003090 <syscall+0x44>
    80003076:	00369713          	slli	a4,a3,0x3
    8000307a:	00005797          	auipc	a5,0x5
    8000307e:	51678793          	addi	a5,a5,1302 # 80008590 <syscalls>
    80003082:	97ba                	add	a5,a5,a4
    80003084:	639c                	ld	a5,0(a5)
    80003086:	c789                	beqz	a5,80003090 <syscall+0x44>
    {
        // Use num to lookup the system call function for num, call it,
        // and store its return value in p->trapframe->a0
        p->trapframe->a0 = syscalls[num]();
    80003088:	9782                	jalr	a5
    8000308a:	06a93823          	sd	a0,112(s2)
    8000308e:	a839                	j	800030ac <syscall+0x60>
    }
    else
    {
        printf("%d %s: unknown sys call %d\n",
    80003090:	15848613          	addi	a2,s1,344
    80003094:	588c                	lw	a1,48(s1)
    80003096:	00005517          	auipc	a0,0x5
    8000309a:	4c250513          	addi	a0,a0,1218 # 80008558 <states.0+0x180>
    8000309e:	ffffd097          	auipc	ra,0xffffd
    800030a2:	4fa080e7          	jalr	1274(ra) # 80000598 <printf>
               p->pid, p->name, num);
        p->trapframe->a0 = -1;
    800030a6:	6cbc                	ld	a5,88(s1)
    800030a8:	577d                	li	a4,-1
    800030aa:	fbb8                	sd	a4,112(a5)
    }
}
    800030ac:	60e2                	ld	ra,24(sp)
    800030ae:	6442                	ld	s0,16(sp)
    800030b0:	64a2                	ld	s1,8(sp)
    800030b2:	6902                	ld	s2,0(sp)
    800030b4:	6105                	addi	sp,sp,32
    800030b6:	8082                	ret

00000000800030b8 <sys_exit>:

extern uint64 FREE_PAGES; // kalloc.c keeps track of those

uint64
sys_exit(void)
{
    800030b8:	1101                	addi	sp,sp,-32
    800030ba:	ec06                	sd	ra,24(sp)
    800030bc:	e822                	sd	s0,16(sp)
    800030be:	1000                	addi	s0,sp,32
    int n;
    argint(0, &n);
    800030c0:	fec40593          	addi	a1,s0,-20
    800030c4:	4501                	li	a0,0
    800030c6:	00000097          	auipc	ra,0x0
    800030ca:	f0e080e7          	jalr	-242(ra) # 80002fd4 <argint>
    exit(n);
    800030ce:	fec42503          	lw	a0,-20(s0)
    800030d2:	fffff097          	auipc	ra,0xfffff
    800030d6:	3b6080e7          	jalr	950(ra) # 80002488 <exit>
    return 0; // not reached
}
    800030da:	4501                	li	a0,0
    800030dc:	60e2                	ld	ra,24(sp)
    800030de:	6442                	ld	s0,16(sp)
    800030e0:	6105                	addi	sp,sp,32
    800030e2:	8082                	ret

00000000800030e4 <sys_getpid>:

uint64
sys_getpid(void)
{
    800030e4:	1141                	addi	sp,sp,-16
    800030e6:	e406                	sd	ra,8(sp)
    800030e8:	e022                	sd	s0,0(sp)
    800030ea:	0800                	addi	s0,sp,16
    return myproc()->pid;
    800030ec:	fffff097          	auipc	ra,0xfffff
    800030f0:	b00080e7          	jalr	-1280(ra) # 80001bec <myproc>
}
    800030f4:	5908                	lw	a0,48(a0)
    800030f6:	60a2                	ld	ra,8(sp)
    800030f8:	6402                	ld	s0,0(sp)
    800030fa:	0141                	addi	sp,sp,16
    800030fc:	8082                	ret

00000000800030fe <sys_fork>:

uint64
sys_fork(void)
{
    800030fe:	1141                	addi	sp,sp,-16
    80003100:	e406                	sd	ra,8(sp)
    80003102:	e022                	sd	s0,0(sp)
    80003104:	0800                	addi	s0,sp,16
    return fork();
    80003106:	fffff097          	auipc	ra,0xfffff
    8000310a:	fec080e7          	jalr	-20(ra) # 800020f2 <fork>
}
    8000310e:	60a2                	ld	ra,8(sp)
    80003110:	6402                	ld	s0,0(sp)
    80003112:	0141                	addi	sp,sp,16
    80003114:	8082                	ret

0000000080003116 <sys_wait>:

uint64
sys_wait(void)
{
    80003116:	1101                	addi	sp,sp,-32
    80003118:	ec06                	sd	ra,24(sp)
    8000311a:	e822                	sd	s0,16(sp)
    8000311c:	1000                	addi	s0,sp,32
    uint64 p;
    argaddr(0, &p);
    8000311e:	fe840593          	addi	a1,s0,-24
    80003122:	4501                	li	a0,0
    80003124:	00000097          	auipc	ra,0x0
    80003128:	ed0080e7          	jalr	-304(ra) # 80002ff4 <argaddr>
    return wait(p);
    8000312c:	fe843503          	ld	a0,-24(s0)
    80003130:	fffff097          	auipc	ra,0xfffff
    80003134:	4fe080e7          	jalr	1278(ra) # 8000262e <wait>
}
    80003138:	60e2                	ld	ra,24(sp)
    8000313a:	6442                	ld	s0,16(sp)
    8000313c:	6105                	addi	sp,sp,32
    8000313e:	8082                	ret

0000000080003140 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003140:	7179                	addi	sp,sp,-48
    80003142:	f406                	sd	ra,40(sp)
    80003144:	f022                	sd	s0,32(sp)
    80003146:	ec26                	sd	s1,24(sp)
    80003148:	1800                	addi	s0,sp,48
    uint64 addr;
    int n;

    argint(0, &n);
    8000314a:	fdc40593          	addi	a1,s0,-36
    8000314e:	4501                	li	a0,0
    80003150:	00000097          	auipc	ra,0x0
    80003154:	e84080e7          	jalr	-380(ra) # 80002fd4 <argint>
    addr = myproc()->sz;
    80003158:	fffff097          	auipc	ra,0xfffff
    8000315c:	a94080e7          	jalr	-1388(ra) # 80001bec <myproc>
    80003160:	6524                	ld	s1,72(a0)
    if (growproc(n) < 0)
    80003162:	fdc42503          	lw	a0,-36(s0)
    80003166:	fffff097          	auipc	ra,0xfffff
    8000316a:	de0080e7          	jalr	-544(ra) # 80001f46 <growproc>
    8000316e:	00054863          	bltz	a0,8000317e <sys_sbrk+0x3e>
        return -1;
    return addr;
}
    80003172:	8526                	mv	a0,s1
    80003174:	70a2                	ld	ra,40(sp)
    80003176:	7402                	ld	s0,32(sp)
    80003178:	64e2                	ld	s1,24(sp)
    8000317a:	6145                	addi	sp,sp,48
    8000317c:	8082                	ret
        return -1;
    8000317e:	54fd                	li	s1,-1
    80003180:	bfcd                	j	80003172 <sys_sbrk+0x32>

0000000080003182 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003182:	7139                	addi	sp,sp,-64
    80003184:	fc06                	sd	ra,56(sp)
    80003186:	f822                	sd	s0,48(sp)
    80003188:	f426                	sd	s1,40(sp)
    8000318a:	f04a                	sd	s2,32(sp)
    8000318c:	ec4e                	sd	s3,24(sp)
    8000318e:	0080                	addi	s0,sp,64
    int n;
    uint ticks0;

    argint(0, &n);
    80003190:	fcc40593          	addi	a1,s0,-52
    80003194:	4501                	li	a0,0
    80003196:	00000097          	auipc	ra,0x0
    8000319a:	e3e080e7          	jalr	-450(ra) # 80002fd4 <argint>
    acquire(&tickslock);
    8000319e:	00034517          	auipc	a0,0x34
    800031a2:	97250513          	addi	a0,a0,-1678 # 80036b10 <tickslock>
    800031a6:	ffffe097          	auipc	ra,0xffffe
    800031aa:	b74080e7          	jalr	-1164(ra) # 80000d1a <acquire>
    ticks0 = ticks;
    800031ae:	00006917          	auipc	s2,0x6
    800031b2:	8c292903          	lw	s2,-1854(s2) # 80008a70 <ticks>
    while (ticks - ticks0 < n)
    800031b6:	fcc42783          	lw	a5,-52(s0)
    800031ba:	cf9d                	beqz	a5,800031f8 <sys_sleep+0x76>
        if (killed(myproc()))
        {
            release(&tickslock);
            return -1;
        }
        sleep(&ticks, &tickslock);
    800031bc:	00034997          	auipc	s3,0x34
    800031c0:	95498993          	addi	s3,s3,-1708 # 80036b10 <tickslock>
    800031c4:	00006497          	auipc	s1,0x6
    800031c8:	8ac48493          	addi	s1,s1,-1876 # 80008a70 <ticks>
        if (killed(myproc()))
    800031cc:	fffff097          	auipc	ra,0xfffff
    800031d0:	a20080e7          	jalr	-1504(ra) # 80001bec <myproc>
    800031d4:	fffff097          	auipc	ra,0xfffff
    800031d8:	428080e7          	jalr	1064(ra) # 800025fc <killed>
    800031dc:	ed15                	bnez	a0,80003218 <sys_sleep+0x96>
        sleep(&ticks, &tickslock);
    800031de:	85ce                	mv	a1,s3
    800031e0:	8526                	mv	a0,s1
    800031e2:	fffff097          	auipc	ra,0xfffff
    800031e6:	172080e7          	jalr	370(ra) # 80002354 <sleep>
    while (ticks - ticks0 < n)
    800031ea:	409c                	lw	a5,0(s1)
    800031ec:	412787bb          	subw	a5,a5,s2
    800031f0:	fcc42703          	lw	a4,-52(s0)
    800031f4:	fce7ece3          	bltu	a5,a4,800031cc <sys_sleep+0x4a>
    }
    release(&tickslock);
    800031f8:	00034517          	auipc	a0,0x34
    800031fc:	91850513          	addi	a0,a0,-1768 # 80036b10 <tickslock>
    80003200:	ffffe097          	auipc	ra,0xffffe
    80003204:	bce080e7          	jalr	-1074(ra) # 80000dce <release>
    return 0;
    80003208:	4501                	li	a0,0
}
    8000320a:	70e2                	ld	ra,56(sp)
    8000320c:	7442                	ld	s0,48(sp)
    8000320e:	74a2                	ld	s1,40(sp)
    80003210:	7902                	ld	s2,32(sp)
    80003212:	69e2                	ld	s3,24(sp)
    80003214:	6121                	addi	sp,sp,64
    80003216:	8082                	ret
            release(&tickslock);
    80003218:	00034517          	auipc	a0,0x34
    8000321c:	8f850513          	addi	a0,a0,-1800 # 80036b10 <tickslock>
    80003220:	ffffe097          	auipc	ra,0xffffe
    80003224:	bae080e7          	jalr	-1106(ra) # 80000dce <release>
            return -1;
    80003228:	557d                	li	a0,-1
    8000322a:	b7c5                	j	8000320a <sys_sleep+0x88>

000000008000322c <sys_kill>:

uint64
sys_kill(void)
{
    8000322c:	1101                	addi	sp,sp,-32
    8000322e:	ec06                	sd	ra,24(sp)
    80003230:	e822                	sd	s0,16(sp)
    80003232:	1000                	addi	s0,sp,32
    int pid;

    argint(0, &pid);
    80003234:	fec40593          	addi	a1,s0,-20
    80003238:	4501                	li	a0,0
    8000323a:	00000097          	auipc	ra,0x0
    8000323e:	d9a080e7          	jalr	-614(ra) # 80002fd4 <argint>
    return kill(pid);
    80003242:	fec42503          	lw	a0,-20(s0)
    80003246:	fffff097          	auipc	ra,0xfffff
    8000324a:	318080e7          	jalr	792(ra) # 8000255e <kill>
}
    8000324e:	60e2                	ld	ra,24(sp)
    80003250:	6442                	ld	s0,16(sp)
    80003252:	6105                	addi	sp,sp,32
    80003254:	8082                	ret

0000000080003256 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003256:	1101                	addi	sp,sp,-32
    80003258:	ec06                	sd	ra,24(sp)
    8000325a:	e822                	sd	s0,16(sp)
    8000325c:	e426                	sd	s1,8(sp)
    8000325e:	1000                	addi	s0,sp,32
    uint xticks;

    acquire(&tickslock);
    80003260:	00034517          	auipc	a0,0x34
    80003264:	8b050513          	addi	a0,a0,-1872 # 80036b10 <tickslock>
    80003268:	ffffe097          	auipc	ra,0xffffe
    8000326c:	ab2080e7          	jalr	-1358(ra) # 80000d1a <acquire>
    xticks = ticks;
    80003270:	00006497          	auipc	s1,0x6
    80003274:	8004a483          	lw	s1,-2048(s1) # 80008a70 <ticks>
    release(&tickslock);
    80003278:	00034517          	auipc	a0,0x34
    8000327c:	89850513          	addi	a0,a0,-1896 # 80036b10 <tickslock>
    80003280:	ffffe097          	auipc	ra,0xffffe
    80003284:	b4e080e7          	jalr	-1202(ra) # 80000dce <release>
    return xticks;
}
    80003288:	02049513          	slli	a0,s1,0x20
    8000328c:	9101                	srli	a0,a0,0x20
    8000328e:	60e2                	ld	ra,24(sp)
    80003290:	6442                	ld	s0,16(sp)
    80003292:	64a2                	ld	s1,8(sp)
    80003294:	6105                	addi	sp,sp,32
    80003296:	8082                	ret

0000000080003298 <sys_ps>:

void *
sys_ps(void)
{
    80003298:	1101                	addi	sp,sp,-32
    8000329a:	ec06                	sd	ra,24(sp)
    8000329c:	e822                	sd	s0,16(sp)
    8000329e:	1000                	addi	s0,sp,32
    int start = 0, count = 0;
    800032a0:	fe042623          	sw	zero,-20(s0)
    800032a4:	fe042423          	sw	zero,-24(s0)
    argint(0, &start);
    800032a8:	fec40593          	addi	a1,s0,-20
    800032ac:	4501                	li	a0,0
    800032ae:	00000097          	auipc	ra,0x0
    800032b2:	d26080e7          	jalr	-730(ra) # 80002fd4 <argint>
    argint(1, &count);
    800032b6:	fe840593          	addi	a1,s0,-24
    800032ba:	4505                	li	a0,1
    800032bc:	00000097          	auipc	ra,0x0
    800032c0:	d18080e7          	jalr	-744(ra) # 80002fd4 <argint>
    return ps((uint8)start, (uint8)count);
    800032c4:	fe844583          	lbu	a1,-24(s0)
    800032c8:	fec44503          	lbu	a0,-20(s0)
    800032cc:	fffff097          	auipc	ra,0xfffff
    800032d0:	cd6080e7          	jalr	-810(ra) # 80001fa2 <ps>
}
    800032d4:	60e2                	ld	ra,24(sp)
    800032d6:	6442                	ld	s0,16(sp)
    800032d8:	6105                	addi	sp,sp,32
    800032da:	8082                	ret

00000000800032dc <sys_schedls>:

uint64 sys_schedls(void)
{
    800032dc:	1141                	addi	sp,sp,-16
    800032de:	e406                	sd	ra,8(sp)
    800032e0:	e022                	sd	s0,0(sp)
    800032e2:	0800                	addi	s0,sp,16
    schedls();
    800032e4:	fffff097          	auipc	ra,0xfffff
    800032e8:	5d4080e7          	jalr	1492(ra) # 800028b8 <schedls>
    return 0;
}
    800032ec:	4501                	li	a0,0
    800032ee:	60a2                	ld	ra,8(sp)
    800032f0:	6402                	ld	s0,0(sp)
    800032f2:	0141                	addi	sp,sp,16
    800032f4:	8082                	ret

00000000800032f6 <sys_schedset>:

uint64 sys_schedset(void)
{
    800032f6:	1101                	addi	sp,sp,-32
    800032f8:	ec06                	sd	ra,24(sp)
    800032fa:	e822                	sd	s0,16(sp)
    800032fc:	1000                	addi	s0,sp,32
    int id = 0;
    800032fe:	fe042623          	sw	zero,-20(s0)
    argint(0, &id);
    80003302:	fec40593          	addi	a1,s0,-20
    80003306:	4501                	li	a0,0
    80003308:	00000097          	auipc	ra,0x0
    8000330c:	ccc080e7          	jalr	-820(ra) # 80002fd4 <argint>
    schedset(id - 1);
    80003310:	fec42503          	lw	a0,-20(s0)
    80003314:	357d                	addiw	a0,a0,-1
    80003316:	fffff097          	auipc	ra,0xfffff
    8000331a:	638080e7          	jalr	1592(ra) # 8000294e <schedset>
    return 0;
}
    8000331e:	4501                	li	a0,0
    80003320:	60e2                	ld	ra,24(sp)
    80003322:	6442                	ld	s0,16(sp)
    80003324:	6105                	addi	sp,sp,32
    80003326:	8082                	ret

0000000080003328 <sys_va2pa>:

uint64 sys_va2pa(void)
{
    80003328:	1101                	addi	sp,sp,-32
    8000332a:	ec06                	sd	ra,24(sp)
    8000332c:	e822                	sd	s0,16(sp)
    8000332e:	1000                	addi	s0,sp,32
    uint64 va = 0;
    80003330:	fe043423          	sd	zero,-24(s0)
    argaddr(0, &va);
    80003334:	fe840593          	addi	a1,s0,-24
    80003338:	4501                	li	a0,0
    8000333a:	00000097          	auipc	ra,0x0
    8000333e:	cba080e7          	jalr	-838(ra) # 80002ff4 <argaddr>
    int pid = 0;
    80003342:	fe042223          	sw	zero,-28(s0)
    argint(1, &pid);
    80003346:	fe440593          	addi	a1,s0,-28
    8000334a:	4505                	li	a0,1
    8000334c:	00000097          	auipc	ra,0x0
    80003350:	c88080e7          	jalr	-888(ra) # 80002fd4 <argint>

    uint64 physicalAddress = va2pa(va, pid);
    80003354:	fe442583          	lw	a1,-28(s0)
    80003358:	fe843503          	ld	a0,-24(s0)
    8000335c:	fffff097          	auipc	ra,0xfffff
    80003360:	63e080e7          	jalr	1598(ra) # 8000299a <va2pa>
    return physicalAddress;
}
    80003364:	60e2                	ld	ra,24(sp)
    80003366:	6442                	ld	s0,16(sp)
    80003368:	6105                	addi	sp,sp,32
    8000336a:	8082                	ret

000000008000336c <sys_pfreepages>:

uint64 sys_pfreepages(void)
{
    8000336c:	1141                	addi	sp,sp,-16
    8000336e:	e406                	sd	ra,8(sp)
    80003370:	e022                	sd	s0,0(sp)
    80003372:	0800                	addi	s0,sp,16
    printf("%d\n", FREE_PAGES);
    80003374:	00005597          	auipc	a1,0x5
    80003378:	6d45b583          	ld	a1,1748(a1) # 80008a48 <FREE_PAGES>
    8000337c:	00005517          	auipc	a0,0x5
    80003380:	1f450513          	addi	a0,a0,500 # 80008570 <states.0+0x198>
    80003384:	ffffd097          	auipc	ra,0xffffd
    80003388:	214080e7          	jalr	532(ra) # 80000598 <printf>
    return 0;
    8000338c:	4501                	li	a0,0
    8000338e:	60a2                	ld	ra,8(sp)
    80003390:	6402                	ld	s0,0(sp)
    80003392:	0141                	addi	sp,sp,16
    80003394:	8082                	ret

0000000080003396 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003396:	7179                	addi	sp,sp,-48
    80003398:	f406                	sd	ra,40(sp)
    8000339a:	f022                	sd	s0,32(sp)
    8000339c:	ec26                	sd	s1,24(sp)
    8000339e:	e84a                	sd	s2,16(sp)
    800033a0:	e44e                	sd	s3,8(sp)
    800033a2:	e052                	sd	s4,0(sp)
    800033a4:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800033a6:	00005597          	auipc	a1,0x5
    800033aa:	2c258593          	addi	a1,a1,706 # 80008668 <syscalls+0xd8>
    800033ae:	00033517          	auipc	a0,0x33
    800033b2:	77a50513          	addi	a0,a0,1914 # 80036b28 <bcache>
    800033b6:	ffffe097          	auipc	ra,0xffffe
    800033ba:	8d4080e7          	jalr	-1836(ra) # 80000c8a <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800033be:	0003b797          	auipc	a5,0x3b
    800033c2:	76a78793          	addi	a5,a5,1898 # 8003eb28 <bcache+0x8000>
    800033c6:	0003c717          	auipc	a4,0x3c
    800033ca:	9ca70713          	addi	a4,a4,-1590 # 8003ed90 <bcache+0x8268>
    800033ce:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800033d2:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800033d6:	00033497          	auipc	s1,0x33
    800033da:	76a48493          	addi	s1,s1,1898 # 80036b40 <bcache+0x18>
    b->next = bcache.head.next;
    800033de:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800033e0:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800033e2:	00005a17          	auipc	s4,0x5
    800033e6:	28ea0a13          	addi	s4,s4,654 # 80008670 <syscalls+0xe0>
    b->next = bcache.head.next;
    800033ea:	2b893783          	ld	a5,696(s2)
    800033ee:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800033f0:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800033f4:	85d2                	mv	a1,s4
    800033f6:	01048513          	addi	a0,s1,16
    800033fa:	00001097          	auipc	ra,0x1
    800033fe:	496080e7          	jalr	1174(ra) # 80004890 <initsleeplock>
    bcache.head.next->prev = b;
    80003402:	2b893783          	ld	a5,696(s2)
    80003406:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003408:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000340c:	45848493          	addi	s1,s1,1112
    80003410:	fd349de3          	bne	s1,s3,800033ea <binit+0x54>
  }
}
    80003414:	70a2                	ld	ra,40(sp)
    80003416:	7402                	ld	s0,32(sp)
    80003418:	64e2                	ld	s1,24(sp)
    8000341a:	6942                	ld	s2,16(sp)
    8000341c:	69a2                	ld	s3,8(sp)
    8000341e:	6a02                	ld	s4,0(sp)
    80003420:	6145                	addi	sp,sp,48
    80003422:	8082                	ret

0000000080003424 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003424:	7179                	addi	sp,sp,-48
    80003426:	f406                	sd	ra,40(sp)
    80003428:	f022                	sd	s0,32(sp)
    8000342a:	ec26                	sd	s1,24(sp)
    8000342c:	e84a                	sd	s2,16(sp)
    8000342e:	e44e                	sd	s3,8(sp)
    80003430:	1800                	addi	s0,sp,48
    80003432:	892a                	mv	s2,a0
    80003434:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003436:	00033517          	auipc	a0,0x33
    8000343a:	6f250513          	addi	a0,a0,1778 # 80036b28 <bcache>
    8000343e:	ffffe097          	auipc	ra,0xffffe
    80003442:	8dc080e7          	jalr	-1828(ra) # 80000d1a <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003446:	0003c497          	auipc	s1,0x3c
    8000344a:	99a4b483          	ld	s1,-1638(s1) # 8003ede0 <bcache+0x82b8>
    8000344e:	0003c797          	auipc	a5,0x3c
    80003452:	94278793          	addi	a5,a5,-1726 # 8003ed90 <bcache+0x8268>
    80003456:	02f48f63          	beq	s1,a5,80003494 <bread+0x70>
    8000345a:	873e                	mv	a4,a5
    8000345c:	a021                	j	80003464 <bread+0x40>
    8000345e:	68a4                	ld	s1,80(s1)
    80003460:	02e48a63          	beq	s1,a4,80003494 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003464:	449c                	lw	a5,8(s1)
    80003466:	ff279ce3          	bne	a5,s2,8000345e <bread+0x3a>
    8000346a:	44dc                	lw	a5,12(s1)
    8000346c:	ff3799e3          	bne	a5,s3,8000345e <bread+0x3a>
      b->refcnt++;
    80003470:	40bc                	lw	a5,64(s1)
    80003472:	2785                	addiw	a5,a5,1
    80003474:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003476:	00033517          	auipc	a0,0x33
    8000347a:	6b250513          	addi	a0,a0,1714 # 80036b28 <bcache>
    8000347e:	ffffe097          	auipc	ra,0xffffe
    80003482:	950080e7          	jalr	-1712(ra) # 80000dce <release>
      acquiresleep(&b->lock);
    80003486:	01048513          	addi	a0,s1,16
    8000348a:	00001097          	auipc	ra,0x1
    8000348e:	440080e7          	jalr	1088(ra) # 800048ca <acquiresleep>
      return b;
    80003492:	a8b9                	j	800034f0 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003494:	0003c497          	auipc	s1,0x3c
    80003498:	9444b483          	ld	s1,-1724(s1) # 8003edd8 <bcache+0x82b0>
    8000349c:	0003c797          	auipc	a5,0x3c
    800034a0:	8f478793          	addi	a5,a5,-1804 # 8003ed90 <bcache+0x8268>
    800034a4:	00f48863          	beq	s1,a5,800034b4 <bread+0x90>
    800034a8:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800034aa:	40bc                	lw	a5,64(s1)
    800034ac:	cf81                	beqz	a5,800034c4 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800034ae:	64a4                	ld	s1,72(s1)
    800034b0:	fee49de3          	bne	s1,a4,800034aa <bread+0x86>
  panic("bget: no buffers");
    800034b4:	00005517          	auipc	a0,0x5
    800034b8:	1c450513          	addi	a0,a0,452 # 80008678 <syscalls+0xe8>
    800034bc:	ffffd097          	auipc	ra,0xffffd
    800034c0:	080080e7          	jalr	128(ra) # 8000053c <panic>
      b->dev = dev;
    800034c4:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800034c8:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800034cc:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800034d0:	4785                	li	a5,1
    800034d2:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800034d4:	00033517          	auipc	a0,0x33
    800034d8:	65450513          	addi	a0,a0,1620 # 80036b28 <bcache>
    800034dc:	ffffe097          	auipc	ra,0xffffe
    800034e0:	8f2080e7          	jalr	-1806(ra) # 80000dce <release>
      acquiresleep(&b->lock);
    800034e4:	01048513          	addi	a0,s1,16
    800034e8:	00001097          	auipc	ra,0x1
    800034ec:	3e2080e7          	jalr	994(ra) # 800048ca <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800034f0:	409c                	lw	a5,0(s1)
    800034f2:	cb89                	beqz	a5,80003504 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800034f4:	8526                	mv	a0,s1
    800034f6:	70a2                	ld	ra,40(sp)
    800034f8:	7402                	ld	s0,32(sp)
    800034fa:	64e2                	ld	s1,24(sp)
    800034fc:	6942                	ld	s2,16(sp)
    800034fe:	69a2                	ld	s3,8(sp)
    80003500:	6145                	addi	sp,sp,48
    80003502:	8082                	ret
    virtio_disk_rw(b, 0);
    80003504:	4581                	li	a1,0
    80003506:	8526                	mv	a0,s1
    80003508:	00003097          	auipc	ra,0x3
    8000350c:	f7a080e7          	jalr	-134(ra) # 80006482 <virtio_disk_rw>
    b->valid = 1;
    80003510:	4785                	li	a5,1
    80003512:	c09c                	sw	a5,0(s1)
  return b;
    80003514:	b7c5                	j	800034f4 <bread+0xd0>

0000000080003516 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003516:	1101                	addi	sp,sp,-32
    80003518:	ec06                	sd	ra,24(sp)
    8000351a:	e822                	sd	s0,16(sp)
    8000351c:	e426                	sd	s1,8(sp)
    8000351e:	1000                	addi	s0,sp,32
    80003520:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003522:	0541                	addi	a0,a0,16
    80003524:	00001097          	auipc	ra,0x1
    80003528:	440080e7          	jalr	1088(ra) # 80004964 <holdingsleep>
    8000352c:	cd01                	beqz	a0,80003544 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000352e:	4585                	li	a1,1
    80003530:	8526                	mv	a0,s1
    80003532:	00003097          	auipc	ra,0x3
    80003536:	f50080e7          	jalr	-176(ra) # 80006482 <virtio_disk_rw>
}
    8000353a:	60e2                	ld	ra,24(sp)
    8000353c:	6442                	ld	s0,16(sp)
    8000353e:	64a2                	ld	s1,8(sp)
    80003540:	6105                	addi	sp,sp,32
    80003542:	8082                	ret
    panic("bwrite");
    80003544:	00005517          	auipc	a0,0x5
    80003548:	14c50513          	addi	a0,a0,332 # 80008690 <syscalls+0x100>
    8000354c:	ffffd097          	auipc	ra,0xffffd
    80003550:	ff0080e7          	jalr	-16(ra) # 8000053c <panic>

0000000080003554 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003554:	1101                	addi	sp,sp,-32
    80003556:	ec06                	sd	ra,24(sp)
    80003558:	e822                	sd	s0,16(sp)
    8000355a:	e426                	sd	s1,8(sp)
    8000355c:	e04a                	sd	s2,0(sp)
    8000355e:	1000                	addi	s0,sp,32
    80003560:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003562:	01050913          	addi	s2,a0,16
    80003566:	854a                	mv	a0,s2
    80003568:	00001097          	auipc	ra,0x1
    8000356c:	3fc080e7          	jalr	1020(ra) # 80004964 <holdingsleep>
    80003570:	c925                	beqz	a0,800035e0 <brelse+0x8c>
    panic("brelse");

  releasesleep(&b->lock);
    80003572:	854a                	mv	a0,s2
    80003574:	00001097          	auipc	ra,0x1
    80003578:	3ac080e7          	jalr	940(ra) # 80004920 <releasesleep>

  acquire(&bcache.lock);
    8000357c:	00033517          	auipc	a0,0x33
    80003580:	5ac50513          	addi	a0,a0,1452 # 80036b28 <bcache>
    80003584:	ffffd097          	auipc	ra,0xffffd
    80003588:	796080e7          	jalr	1942(ra) # 80000d1a <acquire>
  b->refcnt--;
    8000358c:	40bc                	lw	a5,64(s1)
    8000358e:	37fd                	addiw	a5,a5,-1
    80003590:	0007871b          	sext.w	a4,a5
    80003594:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003596:	e71d                	bnez	a4,800035c4 <brelse+0x70>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003598:	68b8                	ld	a4,80(s1)
    8000359a:	64bc                	ld	a5,72(s1)
    8000359c:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    8000359e:	68b8                	ld	a4,80(s1)
    800035a0:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800035a2:	0003b797          	auipc	a5,0x3b
    800035a6:	58678793          	addi	a5,a5,1414 # 8003eb28 <bcache+0x8000>
    800035aa:	2b87b703          	ld	a4,696(a5)
    800035ae:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800035b0:	0003b717          	auipc	a4,0x3b
    800035b4:	7e070713          	addi	a4,a4,2016 # 8003ed90 <bcache+0x8268>
    800035b8:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800035ba:	2b87b703          	ld	a4,696(a5)
    800035be:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800035c0:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800035c4:	00033517          	auipc	a0,0x33
    800035c8:	56450513          	addi	a0,a0,1380 # 80036b28 <bcache>
    800035cc:	ffffe097          	auipc	ra,0xffffe
    800035d0:	802080e7          	jalr	-2046(ra) # 80000dce <release>
}
    800035d4:	60e2                	ld	ra,24(sp)
    800035d6:	6442                	ld	s0,16(sp)
    800035d8:	64a2                	ld	s1,8(sp)
    800035da:	6902                	ld	s2,0(sp)
    800035dc:	6105                	addi	sp,sp,32
    800035de:	8082                	ret
    panic("brelse");
    800035e0:	00005517          	auipc	a0,0x5
    800035e4:	0b850513          	addi	a0,a0,184 # 80008698 <syscalls+0x108>
    800035e8:	ffffd097          	auipc	ra,0xffffd
    800035ec:	f54080e7          	jalr	-172(ra) # 8000053c <panic>

00000000800035f0 <bpin>:

void
bpin(struct buf *b) {
    800035f0:	1101                	addi	sp,sp,-32
    800035f2:	ec06                	sd	ra,24(sp)
    800035f4:	e822                	sd	s0,16(sp)
    800035f6:	e426                	sd	s1,8(sp)
    800035f8:	1000                	addi	s0,sp,32
    800035fa:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800035fc:	00033517          	auipc	a0,0x33
    80003600:	52c50513          	addi	a0,a0,1324 # 80036b28 <bcache>
    80003604:	ffffd097          	auipc	ra,0xffffd
    80003608:	716080e7          	jalr	1814(ra) # 80000d1a <acquire>
  b->refcnt++;
    8000360c:	40bc                	lw	a5,64(s1)
    8000360e:	2785                	addiw	a5,a5,1
    80003610:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003612:	00033517          	auipc	a0,0x33
    80003616:	51650513          	addi	a0,a0,1302 # 80036b28 <bcache>
    8000361a:	ffffd097          	auipc	ra,0xffffd
    8000361e:	7b4080e7          	jalr	1972(ra) # 80000dce <release>
}
    80003622:	60e2                	ld	ra,24(sp)
    80003624:	6442                	ld	s0,16(sp)
    80003626:	64a2                	ld	s1,8(sp)
    80003628:	6105                	addi	sp,sp,32
    8000362a:	8082                	ret

000000008000362c <bunpin>:

void
bunpin(struct buf *b) {
    8000362c:	1101                	addi	sp,sp,-32
    8000362e:	ec06                	sd	ra,24(sp)
    80003630:	e822                	sd	s0,16(sp)
    80003632:	e426                	sd	s1,8(sp)
    80003634:	1000                	addi	s0,sp,32
    80003636:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003638:	00033517          	auipc	a0,0x33
    8000363c:	4f050513          	addi	a0,a0,1264 # 80036b28 <bcache>
    80003640:	ffffd097          	auipc	ra,0xffffd
    80003644:	6da080e7          	jalr	1754(ra) # 80000d1a <acquire>
  b->refcnt--;
    80003648:	40bc                	lw	a5,64(s1)
    8000364a:	37fd                	addiw	a5,a5,-1
    8000364c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000364e:	00033517          	auipc	a0,0x33
    80003652:	4da50513          	addi	a0,a0,1242 # 80036b28 <bcache>
    80003656:	ffffd097          	auipc	ra,0xffffd
    8000365a:	778080e7          	jalr	1912(ra) # 80000dce <release>
}
    8000365e:	60e2                	ld	ra,24(sp)
    80003660:	6442                	ld	s0,16(sp)
    80003662:	64a2                	ld	s1,8(sp)
    80003664:	6105                	addi	sp,sp,32
    80003666:	8082                	ret

0000000080003668 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003668:	1101                	addi	sp,sp,-32
    8000366a:	ec06                	sd	ra,24(sp)
    8000366c:	e822                	sd	s0,16(sp)
    8000366e:	e426                	sd	s1,8(sp)
    80003670:	e04a                	sd	s2,0(sp)
    80003672:	1000                	addi	s0,sp,32
    80003674:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003676:	00d5d59b          	srliw	a1,a1,0xd
    8000367a:	0003c797          	auipc	a5,0x3c
    8000367e:	b8a7a783          	lw	a5,-1142(a5) # 8003f204 <sb+0x1c>
    80003682:	9dbd                	addw	a1,a1,a5
    80003684:	00000097          	auipc	ra,0x0
    80003688:	da0080e7          	jalr	-608(ra) # 80003424 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000368c:	0074f713          	andi	a4,s1,7
    80003690:	4785                	li	a5,1
    80003692:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003696:	14ce                	slli	s1,s1,0x33
    80003698:	90d9                	srli	s1,s1,0x36
    8000369a:	00950733          	add	a4,a0,s1
    8000369e:	05874703          	lbu	a4,88(a4)
    800036a2:	00e7f6b3          	and	a3,a5,a4
    800036a6:	c69d                	beqz	a3,800036d4 <bfree+0x6c>
    800036a8:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800036aa:	94aa                	add	s1,s1,a0
    800036ac:	fff7c793          	not	a5,a5
    800036b0:	8f7d                	and	a4,a4,a5
    800036b2:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    800036b6:	00001097          	auipc	ra,0x1
    800036ba:	0f6080e7          	jalr	246(ra) # 800047ac <log_write>
  brelse(bp);
    800036be:	854a                	mv	a0,s2
    800036c0:	00000097          	auipc	ra,0x0
    800036c4:	e94080e7          	jalr	-364(ra) # 80003554 <brelse>
}
    800036c8:	60e2                	ld	ra,24(sp)
    800036ca:	6442                	ld	s0,16(sp)
    800036cc:	64a2                	ld	s1,8(sp)
    800036ce:	6902                	ld	s2,0(sp)
    800036d0:	6105                	addi	sp,sp,32
    800036d2:	8082                	ret
    panic("freeing free block");
    800036d4:	00005517          	auipc	a0,0x5
    800036d8:	fcc50513          	addi	a0,a0,-52 # 800086a0 <syscalls+0x110>
    800036dc:	ffffd097          	auipc	ra,0xffffd
    800036e0:	e60080e7          	jalr	-416(ra) # 8000053c <panic>

00000000800036e4 <balloc>:
{
    800036e4:	711d                	addi	sp,sp,-96
    800036e6:	ec86                	sd	ra,88(sp)
    800036e8:	e8a2                	sd	s0,80(sp)
    800036ea:	e4a6                	sd	s1,72(sp)
    800036ec:	e0ca                	sd	s2,64(sp)
    800036ee:	fc4e                	sd	s3,56(sp)
    800036f0:	f852                	sd	s4,48(sp)
    800036f2:	f456                	sd	s5,40(sp)
    800036f4:	f05a                	sd	s6,32(sp)
    800036f6:	ec5e                	sd	s7,24(sp)
    800036f8:	e862                	sd	s8,16(sp)
    800036fa:	e466                	sd	s9,8(sp)
    800036fc:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800036fe:	0003c797          	auipc	a5,0x3c
    80003702:	aee7a783          	lw	a5,-1298(a5) # 8003f1ec <sb+0x4>
    80003706:	cff5                	beqz	a5,80003802 <balloc+0x11e>
    80003708:	8baa                	mv	s7,a0
    8000370a:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000370c:	0003cb17          	auipc	s6,0x3c
    80003710:	adcb0b13          	addi	s6,s6,-1316 # 8003f1e8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003714:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003716:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003718:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000371a:	6c89                	lui	s9,0x2
    8000371c:	a061                	j	800037a4 <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000371e:	97ca                	add	a5,a5,s2
    80003720:	8e55                	or	a2,a2,a3
    80003722:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003726:	854a                	mv	a0,s2
    80003728:	00001097          	auipc	ra,0x1
    8000372c:	084080e7          	jalr	132(ra) # 800047ac <log_write>
        brelse(bp);
    80003730:	854a                	mv	a0,s2
    80003732:	00000097          	auipc	ra,0x0
    80003736:	e22080e7          	jalr	-478(ra) # 80003554 <brelse>
  bp = bread(dev, bno);
    8000373a:	85a6                	mv	a1,s1
    8000373c:	855e                	mv	a0,s7
    8000373e:	00000097          	auipc	ra,0x0
    80003742:	ce6080e7          	jalr	-794(ra) # 80003424 <bread>
    80003746:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003748:	40000613          	li	a2,1024
    8000374c:	4581                	li	a1,0
    8000374e:	05850513          	addi	a0,a0,88
    80003752:	ffffd097          	auipc	ra,0xffffd
    80003756:	6c4080e7          	jalr	1732(ra) # 80000e16 <memset>
  log_write(bp);
    8000375a:	854a                	mv	a0,s2
    8000375c:	00001097          	auipc	ra,0x1
    80003760:	050080e7          	jalr	80(ra) # 800047ac <log_write>
  brelse(bp);
    80003764:	854a                	mv	a0,s2
    80003766:	00000097          	auipc	ra,0x0
    8000376a:	dee080e7          	jalr	-530(ra) # 80003554 <brelse>
}
    8000376e:	8526                	mv	a0,s1
    80003770:	60e6                	ld	ra,88(sp)
    80003772:	6446                	ld	s0,80(sp)
    80003774:	64a6                	ld	s1,72(sp)
    80003776:	6906                	ld	s2,64(sp)
    80003778:	79e2                	ld	s3,56(sp)
    8000377a:	7a42                	ld	s4,48(sp)
    8000377c:	7aa2                	ld	s5,40(sp)
    8000377e:	7b02                	ld	s6,32(sp)
    80003780:	6be2                	ld	s7,24(sp)
    80003782:	6c42                	ld	s8,16(sp)
    80003784:	6ca2                	ld	s9,8(sp)
    80003786:	6125                	addi	sp,sp,96
    80003788:	8082                	ret
    brelse(bp);
    8000378a:	854a                	mv	a0,s2
    8000378c:	00000097          	auipc	ra,0x0
    80003790:	dc8080e7          	jalr	-568(ra) # 80003554 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003794:	015c87bb          	addw	a5,s9,s5
    80003798:	00078a9b          	sext.w	s5,a5
    8000379c:	004b2703          	lw	a4,4(s6)
    800037a0:	06eaf163          	bgeu	s5,a4,80003802 <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    800037a4:	41fad79b          	sraiw	a5,s5,0x1f
    800037a8:	0137d79b          	srliw	a5,a5,0x13
    800037ac:	015787bb          	addw	a5,a5,s5
    800037b0:	40d7d79b          	sraiw	a5,a5,0xd
    800037b4:	01cb2583          	lw	a1,28(s6)
    800037b8:	9dbd                	addw	a1,a1,a5
    800037ba:	855e                	mv	a0,s7
    800037bc:	00000097          	auipc	ra,0x0
    800037c0:	c68080e7          	jalr	-920(ra) # 80003424 <bread>
    800037c4:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800037c6:	004b2503          	lw	a0,4(s6)
    800037ca:	000a849b          	sext.w	s1,s5
    800037ce:	8762                	mv	a4,s8
    800037d0:	faa4fde3          	bgeu	s1,a0,8000378a <balloc+0xa6>
      m = 1 << (bi % 8);
    800037d4:	00777693          	andi	a3,a4,7
    800037d8:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800037dc:	41f7579b          	sraiw	a5,a4,0x1f
    800037e0:	01d7d79b          	srliw	a5,a5,0x1d
    800037e4:	9fb9                	addw	a5,a5,a4
    800037e6:	4037d79b          	sraiw	a5,a5,0x3
    800037ea:	00f90633          	add	a2,s2,a5
    800037ee:	05864603          	lbu	a2,88(a2) # 1058 <_entry-0x7fffefa8>
    800037f2:	00c6f5b3          	and	a1,a3,a2
    800037f6:	d585                	beqz	a1,8000371e <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800037f8:	2705                	addiw	a4,a4,1
    800037fa:	2485                	addiw	s1,s1,1
    800037fc:	fd471ae3          	bne	a4,s4,800037d0 <balloc+0xec>
    80003800:	b769                	j	8000378a <balloc+0xa6>
  printf("balloc: out of blocks\n");
    80003802:	00005517          	auipc	a0,0x5
    80003806:	eb650513          	addi	a0,a0,-330 # 800086b8 <syscalls+0x128>
    8000380a:	ffffd097          	auipc	ra,0xffffd
    8000380e:	d8e080e7          	jalr	-626(ra) # 80000598 <printf>
  return 0;
    80003812:	4481                	li	s1,0
    80003814:	bfa9                	j	8000376e <balloc+0x8a>

0000000080003816 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003816:	7179                	addi	sp,sp,-48
    80003818:	f406                	sd	ra,40(sp)
    8000381a:	f022                	sd	s0,32(sp)
    8000381c:	ec26                	sd	s1,24(sp)
    8000381e:	e84a                	sd	s2,16(sp)
    80003820:	e44e                	sd	s3,8(sp)
    80003822:	e052                	sd	s4,0(sp)
    80003824:	1800                	addi	s0,sp,48
    80003826:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003828:	47ad                	li	a5,11
    8000382a:	02b7e863          	bltu	a5,a1,8000385a <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    8000382e:	02059793          	slli	a5,a1,0x20
    80003832:	01e7d593          	srli	a1,a5,0x1e
    80003836:	00b504b3          	add	s1,a0,a1
    8000383a:	0504a903          	lw	s2,80(s1)
    8000383e:	06091e63          	bnez	s2,800038ba <bmap+0xa4>
      addr = balloc(ip->dev);
    80003842:	4108                	lw	a0,0(a0)
    80003844:	00000097          	auipc	ra,0x0
    80003848:	ea0080e7          	jalr	-352(ra) # 800036e4 <balloc>
    8000384c:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003850:	06090563          	beqz	s2,800038ba <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    80003854:	0524a823          	sw	s2,80(s1)
    80003858:	a08d                	j	800038ba <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    8000385a:	ff45849b          	addiw	s1,a1,-12
    8000385e:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003862:	0ff00793          	li	a5,255
    80003866:	08e7e563          	bltu	a5,a4,800038f0 <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    8000386a:	08052903          	lw	s2,128(a0)
    8000386e:	00091d63          	bnez	s2,80003888 <bmap+0x72>
      addr = balloc(ip->dev);
    80003872:	4108                	lw	a0,0(a0)
    80003874:	00000097          	auipc	ra,0x0
    80003878:	e70080e7          	jalr	-400(ra) # 800036e4 <balloc>
    8000387c:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003880:	02090d63          	beqz	s2,800038ba <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003884:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003888:	85ca                	mv	a1,s2
    8000388a:	0009a503          	lw	a0,0(s3)
    8000388e:	00000097          	auipc	ra,0x0
    80003892:	b96080e7          	jalr	-1130(ra) # 80003424 <bread>
    80003896:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003898:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000389c:	02049713          	slli	a4,s1,0x20
    800038a0:	01e75593          	srli	a1,a4,0x1e
    800038a4:	00b784b3          	add	s1,a5,a1
    800038a8:	0004a903          	lw	s2,0(s1)
    800038ac:	02090063          	beqz	s2,800038cc <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800038b0:	8552                	mv	a0,s4
    800038b2:	00000097          	auipc	ra,0x0
    800038b6:	ca2080e7          	jalr	-862(ra) # 80003554 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800038ba:	854a                	mv	a0,s2
    800038bc:	70a2                	ld	ra,40(sp)
    800038be:	7402                	ld	s0,32(sp)
    800038c0:	64e2                	ld	s1,24(sp)
    800038c2:	6942                	ld	s2,16(sp)
    800038c4:	69a2                	ld	s3,8(sp)
    800038c6:	6a02                	ld	s4,0(sp)
    800038c8:	6145                	addi	sp,sp,48
    800038ca:	8082                	ret
      addr = balloc(ip->dev);
    800038cc:	0009a503          	lw	a0,0(s3)
    800038d0:	00000097          	auipc	ra,0x0
    800038d4:	e14080e7          	jalr	-492(ra) # 800036e4 <balloc>
    800038d8:	0005091b          	sext.w	s2,a0
      if(addr){
    800038dc:	fc090ae3          	beqz	s2,800038b0 <bmap+0x9a>
        a[bn] = addr;
    800038e0:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    800038e4:	8552                	mv	a0,s4
    800038e6:	00001097          	auipc	ra,0x1
    800038ea:	ec6080e7          	jalr	-314(ra) # 800047ac <log_write>
    800038ee:	b7c9                	j	800038b0 <bmap+0x9a>
  panic("bmap: out of range");
    800038f0:	00005517          	auipc	a0,0x5
    800038f4:	de050513          	addi	a0,a0,-544 # 800086d0 <syscalls+0x140>
    800038f8:	ffffd097          	auipc	ra,0xffffd
    800038fc:	c44080e7          	jalr	-956(ra) # 8000053c <panic>

0000000080003900 <iget>:
{
    80003900:	7179                	addi	sp,sp,-48
    80003902:	f406                	sd	ra,40(sp)
    80003904:	f022                	sd	s0,32(sp)
    80003906:	ec26                	sd	s1,24(sp)
    80003908:	e84a                	sd	s2,16(sp)
    8000390a:	e44e                	sd	s3,8(sp)
    8000390c:	e052                	sd	s4,0(sp)
    8000390e:	1800                	addi	s0,sp,48
    80003910:	89aa                	mv	s3,a0
    80003912:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003914:	0003c517          	auipc	a0,0x3c
    80003918:	8f450513          	addi	a0,a0,-1804 # 8003f208 <itable>
    8000391c:	ffffd097          	auipc	ra,0xffffd
    80003920:	3fe080e7          	jalr	1022(ra) # 80000d1a <acquire>
  empty = 0;
    80003924:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003926:	0003c497          	auipc	s1,0x3c
    8000392a:	8fa48493          	addi	s1,s1,-1798 # 8003f220 <itable+0x18>
    8000392e:	0003d697          	auipc	a3,0x3d
    80003932:	38268693          	addi	a3,a3,898 # 80040cb0 <log>
    80003936:	a039                	j	80003944 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003938:	02090b63          	beqz	s2,8000396e <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000393c:	08848493          	addi	s1,s1,136
    80003940:	02d48a63          	beq	s1,a3,80003974 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003944:	449c                	lw	a5,8(s1)
    80003946:	fef059e3          	blez	a5,80003938 <iget+0x38>
    8000394a:	4098                	lw	a4,0(s1)
    8000394c:	ff3716e3          	bne	a4,s3,80003938 <iget+0x38>
    80003950:	40d8                	lw	a4,4(s1)
    80003952:	ff4713e3          	bne	a4,s4,80003938 <iget+0x38>
      ip->ref++;
    80003956:	2785                	addiw	a5,a5,1
    80003958:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000395a:	0003c517          	auipc	a0,0x3c
    8000395e:	8ae50513          	addi	a0,a0,-1874 # 8003f208 <itable>
    80003962:	ffffd097          	auipc	ra,0xffffd
    80003966:	46c080e7          	jalr	1132(ra) # 80000dce <release>
      return ip;
    8000396a:	8926                	mv	s2,s1
    8000396c:	a03d                	j	8000399a <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000396e:	f7f9                	bnez	a5,8000393c <iget+0x3c>
    80003970:	8926                	mv	s2,s1
    80003972:	b7e9                	j	8000393c <iget+0x3c>
  if(empty == 0)
    80003974:	02090c63          	beqz	s2,800039ac <iget+0xac>
  ip->dev = dev;
    80003978:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000397c:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003980:	4785                	li	a5,1
    80003982:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003986:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000398a:	0003c517          	auipc	a0,0x3c
    8000398e:	87e50513          	addi	a0,a0,-1922 # 8003f208 <itable>
    80003992:	ffffd097          	auipc	ra,0xffffd
    80003996:	43c080e7          	jalr	1084(ra) # 80000dce <release>
}
    8000399a:	854a                	mv	a0,s2
    8000399c:	70a2                	ld	ra,40(sp)
    8000399e:	7402                	ld	s0,32(sp)
    800039a0:	64e2                	ld	s1,24(sp)
    800039a2:	6942                	ld	s2,16(sp)
    800039a4:	69a2                	ld	s3,8(sp)
    800039a6:	6a02                	ld	s4,0(sp)
    800039a8:	6145                	addi	sp,sp,48
    800039aa:	8082                	ret
    panic("iget: no inodes");
    800039ac:	00005517          	auipc	a0,0x5
    800039b0:	d3c50513          	addi	a0,a0,-708 # 800086e8 <syscalls+0x158>
    800039b4:	ffffd097          	auipc	ra,0xffffd
    800039b8:	b88080e7          	jalr	-1144(ra) # 8000053c <panic>

00000000800039bc <fsinit>:
fsinit(int dev) {
    800039bc:	7179                	addi	sp,sp,-48
    800039be:	f406                	sd	ra,40(sp)
    800039c0:	f022                	sd	s0,32(sp)
    800039c2:	ec26                	sd	s1,24(sp)
    800039c4:	e84a                	sd	s2,16(sp)
    800039c6:	e44e                	sd	s3,8(sp)
    800039c8:	1800                	addi	s0,sp,48
    800039ca:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800039cc:	4585                	li	a1,1
    800039ce:	00000097          	auipc	ra,0x0
    800039d2:	a56080e7          	jalr	-1450(ra) # 80003424 <bread>
    800039d6:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800039d8:	0003c997          	auipc	s3,0x3c
    800039dc:	81098993          	addi	s3,s3,-2032 # 8003f1e8 <sb>
    800039e0:	02000613          	li	a2,32
    800039e4:	05850593          	addi	a1,a0,88
    800039e8:	854e                	mv	a0,s3
    800039ea:	ffffd097          	auipc	ra,0xffffd
    800039ee:	488080e7          	jalr	1160(ra) # 80000e72 <memmove>
  brelse(bp);
    800039f2:	8526                	mv	a0,s1
    800039f4:	00000097          	auipc	ra,0x0
    800039f8:	b60080e7          	jalr	-1184(ra) # 80003554 <brelse>
  if(sb.magic != FSMAGIC)
    800039fc:	0009a703          	lw	a4,0(s3)
    80003a00:	102037b7          	lui	a5,0x10203
    80003a04:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003a08:	02f71263          	bne	a4,a5,80003a2c <fsinit+0x70>
  initlog(dev, &sb);
    80003a0c:	0003b597          	auipc	a1,0x3b
    80003a10:	7dc58593          	addi	a1,a1,2012 # 8003f1e8 <sb>
    80003a14:	854a                	mv	a0,s2
    80003a16:	00001097          	auipc	ra,0x1
    80003a1a:	b2c080e7          	jalr	-1236(ra) # 80004542 <initlog>
}
    80003a1e:	70a2                	ld	ra,40(sp)
    80003a20:	7402                	ld	s0,32(sp)
    80003a22:	64e2                	ld	s1,24(sp)
    80003a24:	6942                	ld	s2,16(sp)
    80003a26:	69a2                	ld	s3,8(sp)
    80003a28:	6145                	addi	sp,sp,48
    80003a2a:	8082                	ret
    panic("invalid file system");
    80003a2c:	00005517          	auipc	a0,0x5
    80003a30:	ccc50513          	addi	a0,a0,-820 # 800086f8 <syscalls+0x168>
    80003a34:	ffffd097          	auipc	ra,0xffffd
    80003a38:	b08080e7          	jalr	-1272(ra) # 8000053c <panic>

0000000080003a3c <iinit>:
{
    80003a3c:	7179                	addi	sp,sp,-48
    80003a3e:	f406                	sd	ra,40(sp)
    80003a40:	f022                	sd	s0,32(sp)
    80003a42:	ec26                	sd	s1,24(sp)
    80003a44:	e84a                	sd	s2,16(sp)
    80003a46:	e44e                	sd	s3,8(sp)
    80003a48:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003a4a:	00005597          	auipc	a1,0x5
    80003a4e:	cc658593          	addi	a1,a1,-826 # 80008710 <syscalls+0x180>
    80003a52:	0003b517          	auipc	a0,0x3b
    80003a56:	7b650513          	addi	a0,a0,1974 # 8003f208 <itable>
    80003a5a:	ffffd097          	auipc	ra,0xffffd
    80003a5e:	230080e7          	jalr	560(ra) # 80000c8a <initlock>
  for(i = 0; i < NINODE; i++) {
    80003a62:	0003b497          	auipc	s1,0x3b
    80003a66:	7ce48493          	addi	s1,s1,1998 # 8003f230 <itable+0x28>
    80003a6a:	0003d997          	auipc	s3,0x3d
    80003a6e:	25698993          	addi	s3,s3,598 # 80040cc0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003a72:	00005917          	auipc	s2,0x5
    80003a76:	ca690913          	addi	s2,s2,-858 # 80008718 <syscalls+0x188>
    80003a7a:	85ca                	mv	a1,s2
    80003a7c:	8526                	mv	a0,s1
    80003a7e:	00001097          	auipc	ra,0x1
    80003a82:	e12080e7          	jalr	-494(ra) # 80004890 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003a86:	08848493          	addi	s1,s1,136
    80003a8a:	ff3498e3          	bne	s1,s3,80003a7a <iinit+0x3e>
}
    80003a8e:	70a2                	ld	ra,40(sp)
    80003a90:	7402                	ld	s0,32(sp)
    80003a92:	64e2                	ld	s1,24(sp)
    80003a94:	6942                	ld	s2,16(sp)
    80003a96:	69a2                	ld	s3,8(sp)
    80003a98:	6145                	addi	sp,sp,48
    80003a9a:	8082                	ret

0000000080003a9c <ialloc>:
{
    80003a9c:	7139                	addi	sp,sp,-64
    80003a9e:	fc06                	sd	ra,56(sp)
    80003aa0:	f822                	sd	s0,48(sp)
    80003aa2:	f426                	sd	s1,40(sp)
    80003aa4:	f04a                	sd	s2,32(sp)
    80003aa6:	ec4e                	sd	s3,24(sp)
    80003aa8:	e852                	sd	s4,16(sp)
    80003aaa:	e456                	sd	s5,8(sp)
    80003aac:	e05a                	sd	s6,0(sp)
    80003aae:	0080                	addi	s0,sp,64
  for(inum = 1; inum < sb.ninodes; inum++){
    80003ab0:	0003b717          	auipc	a4,0x3b
    80003ab4:	74472703          	lw	a4,1860(a4) # 8003f1f4 <sb+0xc>
    80003ab8:	4785                	li	a5,1
    80003aba:	04e7f863          	bgeu	a5,a4,80003b0a <ialloc+0x6e>
    80003abe:	8aaa                	mv	s5,a0
    80003ac0:	8b2e                	mv	s6,a1
    80003ac2:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003ac4:	0003ba17          	auipc	s4,0x3b
    80003ac8:	724a0a13          	addi	s4,s4,1828 # 8003f1e8 <sb>
    80003acc:	00495593          	srli	a1,s2,0x4
    80003ad0:	018a2783          	lw	a5,24(s4)
    80003ad4:	9dbd                	addw	a1,a1,a5
    80003ad6:	8556                	mv	a0,s5
    80003ad8:	00000097          	auipc	ra,0x0
    80003adc:	94c080e7          	jalr	-1716(ra) # 80003424 <bread>
    80003ae0:	84aa                	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003ae2:	05850993          	addi	s3,a0,88
    80003ae6:	00f97793          	andi	a5,s2,15
    80003aea:	079a                	slli	a5,a5,0x6
    80003aec:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003aee:	00099783          	lh	a5,0(s3)
    80003af2:	cf9d                	beqz	a5,80003b30 <ialloc+0x94>
    brelse(bp);
    80003af4:	00000097          	auipc	ra,0x0
    80003af8:	a60080e7          	jalr	-1440(ra) # 80003554 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003afc:	0905                	addi	s2,s2,1
    80003afe:	00ca2703          	lw	a4,12(s4)
    80003b02:	0009079b          	sext.w	a5,s2
    80003b06:	fce7e3e3          	bltu	a5,a4,80003acc <ialloc+0x30>
  printf("ialloc: no inodes\n");
    80003b0a:	00005517          	auipc	a0,0x5
    80003b0e:	c1650513          	addi	a0,a0,-1002 # 80008720 <syscalls+0x190>
    80003b12:	ffffd097          	auipc	ra,0xffffd
    80003b16:	a86080e7          	jalr	-1402(ra) # 80000598 <printf>
  return 0;
    80003b1a:	4501                	li	a0,0
}
    80003b1c:	70e2                	ld	ra,56(sp)
    80003b1e:	7442                	ld	s0,48(sp)
    80003b20:	74a2                	ld	s1,40(sp)
    80003b22:	7902                	ld	s2,32(sp)
    80003b24:	69e2                	ld	s3,24(sp)
    80003b26:	6a42                	ld	s4,16(sp)
    80003b28:	6aa2                	ld	s5,8(sp)
    80003b2a:	6b02                	ld	s6,0(sp)
    80003b2c:	6121                	addi	sp,sp,64
    80003b2e:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003b30:	04000613          	li	a2,64
    80003b34:	4581                	li	a1,0
    80003b36:	854e                	mv	a0,s3
    80003b38:	ffffd097          	auipc	ra,0xffffd
    80003b3c:	2de080e7          	jalr	734(ra) # 80000e16 <memset>
      dip->type = type;
    80003b40:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003b44:	8526                	mv	a0,s1
    80003b46:	00001097          	auipc	ra,0x1
    80003b4a:	c66080e7          	jalr	-922(ra) # 800047ac <log_write>
      brelse(bp);
    80003b4e:	8526                	mv	a0,s1
    80003b50:	00000097          	auipc	ra,0x0
    80003b54:	a04080e7          	jalr	-1532(ra) # 80003554 <brelse>
      return iget(dev, inum);
    80003b58:	0009059b          	sext.w	a1,s2
    80003b5c:	8556                	mv	a0,s5
    80003b5e:	00000097          	auipc	ra,0x0
    80003b62:	da2080e7          	jalr	-606(ra) # 80003900 <iget>
    80003b66:	bf5d                	j	80003b1c <ialloc+0x80>

0000000080003b68 <iupdate>:
{
    80003b68:	1101                	addi	sp,sp,-32
    80003b6a:	ec06                	sd	ra,24(sp)
    80003b6c:	e822                	sd	s0,16(sp)
    80003b6e:	e426                	sd	s1,8(sp)
    80003b70:	e04a                	sd	s2,0(sp)
    80003b72:	1000                	addi	s0,sp,32
    80003b74:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003b76:	415c                	lw	a5,4(a0)
    80003b78:	0047d79b          	srliw	a5,a5,0x4
    80003b7c:	0003b597          	auipc	a1,0x3b
    80003b80:	6845a583          	lw	a1,1668(a1) # 8003f200 <sb+0x18>
    80003b84:	9dbd                	addw	a1,a1,a5
    80003b86:	4108                	lw	a0,0(a0)
    80003b88:	00000097          	auipc	ra,0x0
    80003b8c:	89c080e7          	jalr	-1892(ra) # 80003424 <bread>
    80003b90:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003b92:	05850793          	addi	a5,a0,88
    80003b96:	40d8                	lw	a4,4(s1)
    80003b98:	8b3d                	andi	a4,a4,15
    80003b9a:	071a                	slli	a4,a4,0x6
    80003b9c:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003b9e:	04449703          	lh	a4,68(s1)
    80003ba2:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003ba6:	04649703          	lh	a4,70(s1)
    80003baa:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003bae:	04849703          	lh	a4,72(s1)
    80003bb2:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003bb6:	04a49703          	lh	a4,74(s1)
    80003bba:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003bbe:	44f8                	lw	a4,76(s1)
    80003bc0:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003bc2:	03400613          	li	a2,52
    80003bc6:	05048593          	addi	a1,s1,80
    80003bca:	00c78513          	addi	a0,a5,12
    80003bce:	ffffd097          	auipc	ra,0xffffd
    80003bd2:	2a4080e7          	jalr	676(ra) # 80000e72 <memmove>
  log_write(bp);
    80003bd6:	854a                	mv	a0,s2
    80003bd8:	00001097          	auipc	ra,0x1
    80003bdc:	bd4080e7          	jalr	-1068(ra) # 800047ac <log_write>
  brelse(bp);
    80003be0:	854a                	mv	a0,s2
    80003be2:	00000097          	auipc	ra,0x0
    80003be6:	972080e7          	jalr	-1678(ra) # 80003554 <brelse>
}
    80003bea:	60e2                	ld	ra,24(sp)
    80003bec:	6442                	ld	s0,16(sp)
    80003bee:	64a2                	ld	s1,8(sp)
    80003bf0:	6902                	ld	s2,0(sp)
    80003bf2:	6105                	addi	sp,sp,32
    80003bf4:	8082                	ret

0000000080003bf6 <idup>:
{
    80003bf6:	1101                	addi	sp,sp,-32
    80003bf8:	ec06                	sd	ra,24(sp)
    80003bfa:	e822                	sd	s0,16(sp)
    80003bfc:	e426                	sd	s1,8(sp)
    80003bfe:	1000                	addi	s0,sp,32
    80003c00:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003c02:	0003b517          	auipc	a0,0x3b
    80003c06:	60650513          	addi	a0,a0,1542 # 8003f208 <itable>
    80003c0a:	ffffd097          	auipc	ra,0xffffd
    80003c0e:	110080e7          	jalr	272(ra) # 80000d1a <acquire>
  ip->ref++;
    80003c12:	449c                	lw	a5,8(s1)
    80003c14:	2785                	addiw	a5,a5,1
    80003c16:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003c18:	0003b517          	auipc	a0,0x3b
    80003c1c:	5f050513          	addi	a0,a0,1520 # 8003f208 <itable>
    80003c20:	ffffd097          	auipc	ra,0xffffd
    80003c24:	1ae080e7          	jalr	430(ra) # 80000dce <release>
}
    80003c28:	8526                	mv	a0,s1
    80003c2a:	60e2                	ld	ra,24(sp)
    80003c2c:	6442                	ld	s0,16(sp)
    80003c2e:	64a2                	ld	s1,8(sp)
    80003c30:	6105                	addi	sp,sp,32
    80003c32:	8082                	ret

0000000080003c34 <ilock>:
{
    80003c34:	1101                	addi	sp,sp,-32
    80003c36:	ec06                	sd	ra,24(sp)
    80003c38:	e822                	sd	s0,16(sp)
    80003c3a:	e426                	sd	s1,8(sp)
    80003c3c:	e04a                	sd	s2,0(sp)
    80003c3e:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003c40:	c115                	beqz	a0,80003c64 <ilock+0x30>
    80003c42:	84aa                	mv	s1,a0
    80003c44:	451c                	lw	a5,8(a0)
    80003c46:	00f05f63          	blez	a5,80003c64 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003c4a:	0541                	addi	a0,a0,16
    80003c4c:	00001097          	auipc	ra,0x1
    80003c50:	c7e080e7          	jalr	-898(ra) # 800048ca <acquiresleep>
  if(ip->valid == 0){
    80003c54:	40bc                	lw	a5,64(s1)
    80003c56:	cf99                	beqz	a5,80003c74 <ilock+0x40>
}
    80003c58:	60e2                	ld	ra,24(sp)
    80003c5a:	6442                	ld	s0,16(sp)
    80003c5c:	64a2                	ld	s1,8(sp)
    80003c5e:	6902                	ld	s2,0(sp)
    80003c60:	6105                	addi	sp,sp,32
    80003c62:	8082                	ret
    panic("ilock");
    80003c64:	00005517          	auipc	a0,0x5
    80003c68:	ad450513          	addi	a0,a0,-1324 # 80008738 <syscalls+0x1a8>
    80003c6c:	ffffd097          	auipc	ra,0xffffd
    80003c70:	8d0080e7          	jalr	-1840(ra) # 8000053c <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003c74:	40dc                	lw	a5,4(s1)
    80003c76:	0047d79b          	srliw	a5,a5,0x4
    80003c7a:	0003b597          	auipc	a1,0x3b
    80003c7e:	5865a583          	lw	a1,1414(a1) # 8003f200 <sb+0x18>
    80003c82:	9dbd                	addw	a1,a1,a5
    80003c84:	4088                	lw	a0,0(s1)
    80003c86:	fffff097          	auipc	ra,0xfffff
    80003c8a:	79e080e7          	jalr	1950(ra) # 80003424 <bread>
    80003c8e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003c90:	05850593          	addi	a1,a0,88
    80003c94:	40dc                	lw	a5,4(s1)
    80003c96:	8bbd                	andi	a5,a5,15
    80003c98:	079a                	slli	a5,a5,0x6
    80003c9a:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003c9c:	00059783          	lh	a5,0(a1)
    80003ca0:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003ca4:	00259783          	lh	a5,2(a1)
    80003ca8:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003cac:	00459783          	lh	a5,4(a1)
    80003cb0:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003cb4:	00659783          	lh	a5,6(a1)
    80003cb8:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003cbc:	459c                	lw	a5,8(a1)
    80003cbe:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003cc0:	03400613          	li	a2,52
    80003cc4:	05b1                	addi	a1,a1,12
    80003cc6:	05048513          	addi	a0,s1,80
    80003cca:	ffffd097          	auipc	ra,0xffffd
    80003cce:	1a8080e7          	jalr	424(ra) # 80000e72 <memmove>
    brelse(bp);
    80003cd2:	854a                	mv	a0,s2
    80003cd4:	00000097          	auipc	ra,0x0
    80003cd8:	880080e7          	jalr	-1920(ra) # 80003554 <brelse>
    ip->valid = 1;
    80003cdc:	4785                	li	a5,1
    80003cde:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003ce0:	04449783          	lh	a5,68(s1)
    80003ce4:	fbb5                	bnez	a5,80003c58 <ilock+0x24>
      panic("ilock: no type");
    80003ce6:	00005517          	auipc	a0,0x5
    80003cea:	a5a50513          	addi	a0,a0,-1446 # 80008740 <syscalls+0x1b0>
    80003cee:	ffffd097          	auipc	ra,0xffffd
    80003cf2:	84e080e7          	jalr	-1970(ra) # 8000053c <panic>

0000000080003cf6 <iunlock>:
{
    80003cf6:	1101                	addi	sp,sp,-32
    80003cf8:	ec06                	sd	ra,24(sp)
    80003cfa:	e822                	sd	s0,16(sp)
    80003cfc:	e426                	sd	s1,8(sp)
    80003cfe:	e04a                	sd	s2,0(sp)
    80003d00:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003d02:	c905                	beqz	a0,80003d32 <iunlock+0x3c>
    80003d04:	84aa                	mv	s1,a0
    80003d06:	01050913          	addi	s2,a0,16
    80003d0a:	854a                	mv	a0,s2
    80003d0c:	00001097          	auipc	ra,0x1
    80003d10:	c58080e7          	jalr	-936(ra) # 80004964 <holdingsleep>
    80003d14:	cd19                	beqz	a0,80003d32 <iunlock+0x3c>
    80003d16:	449c                	lw	a5,8(s1)
    80003d18:	00f05d63          	blez	a5,80003d32 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003d1c:	854a                	mv	a0,s2
    80003d1e:	00001097          	auipc	ra,0x1
    80003d22:	c02080e7          	jalr	-1022(ra) # 80004920 <releasesleep>
}
    80003d26:	60e2                	ld	ra,24(sp)
    80003d28:	6442                	ld	s0,16(sp)
    80003d2a:	64a2                	ld	s1,8(sp)
    80003d2c:	6902                	ld	s2,0(sp)
    80003d2e:	6105                	addi	sp,sp,32
    80003d30:	8082                	ret
    panic("iunlock");
    80003d32:	00005517          	auipc	a0,0x5
    80003d36:	a1e50513          	addi	a0,a0,-1506 # 80008750 <syscalls+0x1c0>
    80003d3a:	ffffd097          	auipc	ra,0xffffd
    80003d3e:	802080e7          	jalr	-2046(ra) # 8000053c <panic>

0000000080003d42 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003d42:	7179                	addi	sp,sp,-48
    80003d44:	f406                	sd	ra,40(sp)
    80003d46:	f022                	sd	s0,32(sp)
    80003d48:	ec26                	sd	s1,24(sp)
    80003d4a:	e84a                	sd	s2,16(sp)
    80003d4c:	e44e                	sd	s3,8(sp)
    80003d4e:	e052                	sd	s4,0(sp)
    80003d50:	1800                	addi	s0,sp,48
    80003d52:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003d54:	05050493          	addi	s1,a0,80
    80003d58:	08050913          	addi	s2,a0,128
    80003d5c:	a021                	j	80003d64 <itrunc+0x22>
    80003d5e:	0491                	addi	s1,s1,4
    80003d60:	01248d63          	beq	s1,s2,80003d7a <itrunc+0x38>
    if(ip->addrs[i]){
    80003d64:	408c                	lw	a1,0(s1)
    80003d66:	dde5                	beqz	a1,80003d5e <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003d68:	0009a503          	lw	a0,0(s3)
    80003d6c:	00000097          	auipc	ra,0x0
    80003d70:	8fc080e7          	jalr	-1796(ra) # 80003668 <bfree>
      ip->addrs[i] = 0;
    80003d74:	0004a023          	sw	zero,0(s1)
    80003d78:	b7dd                	j	80003d5e <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003d7a:	0809a583          	lw	a1,128(s3)
    80003d7e:	e185                	bnez	a1,80003d9e <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003d80:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003d84:	854e                	mv	a0,s3
    80003d86:	00000097          	auipc	ra,0x0
    80003d8a:	de2080e7          	jalr	-542(ra) # 80003b68 <iupdate>
}
    80003d8e:	70a2                	ld	ra,40(sp)
    80003d90:	7402                	ld	s0,32(sp)
    80003d92:	64e2                	ld	s1,24(sp)
    80003d94:	6942                	ld	s2,16(sp)
    80003d96:	69a2                	ld	s3,8(sp)
    80003d98:	6a02                	ld	s4,0(sp)
    80003d9a:	6145                	addi	sp,sp,48
    80003d9c:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003d9e:	0009a503          	lw	a0,0(s3)
    80003da2:	fffff097          	auipc	ra,0xfffff
    80003da6:	682080e7          	jalr	1666(ra) # 80003424 <bread>
    80003daa:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003dac:	05850493          	addi	s1,a0,88
    80003db0:	45850913          	addi	s2,a0,1112
    80003db4:	a021                	j	80003dbc <itrunc+0x7a>
    80003db6:	0491                	addi	s1,s1,4
    80003db8:	01248b63          	beq	s1,s2,80003dce <itrunc+0x8c>
      if(a[j])
    80003dbc:	408c                	lw	a1,0(s1)
    80003dbe:	dde5                	beqz	a1,80003db6 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003dc0:	0009a503          	lw	a0,0(s3)
    80003dc4:	00000097          	auipc	ra,0x0
    80003dc8:	8a4080e7          	jalr	-1884(ra) # 80003668 <bfree>
    80003dcc:	b7ed                	j	80003db6 <itrunc+0x74>
    brelse(bp);
    80003dce:	8552                	mv	a0,s4
    80003dd0:	fffff097          	auipc	ra,0xfffff
    80003dd4:	784080e7          	jalr	1924(ra) # 80003554 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003dd8:	0809a583          	lw	a1,128(s3)
    80003ddc:	0009a503          	lw	a0,0(s3)
    80003de0:	00000097          	auipc	ra,0x0
    80003de4:	888080e7          	jalr	-1912(ra) # 80003668 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003de8:	0809a023          	sw	zero,128(s3)
    80003dec:	bf51                	j	80003d80 <itrunc+0x3e>

0000000080003dee <iput>:
{
    80003dee:	1101                	addi	sp,sp,-32
    80003df0:	ec06                	sd	ra,24(sp)
    80003df2:	e822                	sd	s0,16(sp)
    80003df4:	e426                	sd	s1,8(sp)
    80003df6:	e04a                	sd	s2,0(sp)
    80003df8:	1000                	addi	s0,sp,32
    80003dfa:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003dfc:	0003b517          	auipc	a0,0x3b
    80003e00:	40c50513          	addi	a0,a0,1036 # 8003f208 <itable>
    80003e04:	ffffd097          	auipc	ra,0xffffd
    80003e08:	f16080e7          	jalr	-234(ra) # 80000d1a <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003e0c:	4498                	lw	a4,8(s1)
    80003e0e:	4785                	li	a5,1
    80003e10:	02f70363          	beq	a4,a5,80003e36 <iput+0x48>
  ip->ref--;
    80003e14:	449c                	lw	a5,8(s1)
    80003e16:	37fd                	addiw	a5,a5,-1
    80003e18:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003e1a:	0003b517          	auipc	a0,0x3b
    80003e1e:	3ee50513          	addi	a0,a0,1006 # 8003f208 <itable>
    80003e22:	ffffd097          	auipc	ra,0xffffd
    80003e26:	fac080e7          	jalr	-84(ra) # 80000dce <release>
}
    80003e2a:	60e2                	ld	ra,24(sp)
    80003e2c:	6442                	ld	s0,16(sp)
    80003e2e:	64a2                	ld	s1,8(sp)
    80003e30:	6902                	ld	s2,0(sp)
    80003e32:	6105                	addi	sp,sp,32
    80003e34:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003e36:	40bc                	lw	a5,64(s1)
    80003e38:	dff1                	beqz	a5,80003e14 <iput+0x26>
    80003e3a:	04a49783          	lh	a5,74(s1)
    80003e3e:	fbf9                	bnez	a5,80003e14 <iput+0x26>
    acquiresleep(&ip->lock);
    80003e40:	01048913          	addi	s2,s1,16
    80003e44:	854a                	mv	a0,s2
    80003e46:	00001097          	auipc	ra,0x1
    80003e4a:	a84080e7          	jalr	-1404(ra) # 800048ca <acquiresleep>
    release(&itable.lock);
    80003e4e:	0003b517          	auipc	a0,0x3b
    80003e52:	3ba50513          	addi	a0,a0,954 # 8003f208 <itable>
    80003e56:	ffffd097          	auipc	ra,0xffffd
    80003e5a:	f78080e7          	jalr	-136(ra) # 80000dce <release>
    itrunc(ip);
    80003e5e:	8526                	mv	a0,s1
    80003e60:	00000097          	auipc	ra,0x0
    80003e64:	ee2080e7          	jalr	-286(ra) # 80003d42 <itrunc>
    ip->type = 0;
    80003e68:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003e6c:	8526                	mv	a0,s1
    80003e6e:	00000097          	auipc	ra,0x0
    80003e72:	cfa080e7          	jalr	-774(ra) # 80003b68 <iupdate>
    ip->valid = 0;
    80003e76:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003e7a:	854a                	mv	a0,s2
    80003e7c:	00001097          	auipc	ra,0x1
    80003e80:	aa4080e7          	jalr	-1372(ra) # 80004920 <releasesleep>
    acquire(&itable.lock);
    80003e84:	0003b517          	auipc	a0,0x3b
    80003e88:	38450513          	addi	a0,a0,900 # 8003f208 <itable>
    80003e8c:	ffffd097          	auipc	ra,0xffffd
    80003e90:	e8e080e7          	jalr	-370(ra) # 80000d1a <acquire>
    80003e94:	b741                	j	80003e14 <iput+0x26>

0000000080003e96 <iunlockput>:
{
    80003e96:	1101                	addi	sp,sp,-32
    80003e98:	ec06                	sd	ra,24(sp)
    80003e9a:	e822                	sd	s0,16(sp)
    80003e9c:	e426                	sd	s1,8(sp)
    80003e9e:	1000                	addi	s0,sp,32
    80003ea0:	84aa                	mv	s1,a0
  iunlock(ip);
    80003ea2:	00000097          	auipc	ra,0x0
    80003ea6:	e54080e7          	jalr	-428(ra) # 80003cf6 <iunlock>
  iput(ip);
    80003eaa:	8526                	mv	a0,s1
    80003eac:	00000097          	auipc	ra,0x0
    80003eb0:	f42080e7          	jalr	-190(ra) # 80003dee <iput>
}
    80003eb4:	60e2                	ld	ra,24(sp)
    80003eb6:	6442                	ld	s0,16(sp)
    80003eb8:	64a2                	ld	s1,8(sp)
    80003eba:	6105                	addi	sp,sp,32
    80003ebc:	8082                	ret

0000000080003ebe <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003ebe:	1141                	addi	sp,sp,-16
    80003ec0:	e422                	sd	s0,8(sp)
    80003ec2:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003ec4:	411c                	lw	a5,0(a0)
    80003ec6:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003ec8:	415c                	lw	a5,4(a0)
    80003eca:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003ecc:	04451783          	lh	a5,68(a0)
    80003ed0:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003ed4:	04a51783          	lh	a5,74(a0)
    80003ed8:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003edc:	04c56783          	lwu	a5,76(a0)
    80003ee0:	e99c                	sd	a5,16(a1)
}
    80003ee2:	6422                	ld	s0,8(sp)
    80003ee4:	0141                	addi	sp,sp,16
    80003ee6:	8082                	ret

0000000080003ee8 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003ee8:	457c                	lw	a5,76(a0)
    80003eea:	0ed7e963          	bltu	a5,a3,80003fdc <readi+0xf4>
{
    80003eee:	7159                	addi	sp,sp,-112
    80003ef0:	f486                	sd	ra,104(sp)
    80003ef2:	f0a2                	sd	s0,96(sp)
    80003ef4:	eca6                	sd	s1,88(sp)
    80003ef6:	e8ca                	sd	s2,80(sp)
    80003ef8:	e4ce                	sd	s3,72(sp)
    80003efa:	e0d2                	sd	s4,64(sp)
    80003efc:	fc56                	sd	s5,56(sp)
    80003efe:	f85a                	sd	s6,48(sp)
    80003f00:	f45e                	sd	s7,40(sp)
    80003f02:	f062                	sd	s8,32(sp)
    80003f04:	ec66                	sd	s9,24(sp)
    80003f06:	e86a                	sd	s10,16(sp)
    80003f08:	e46e                	sd	s11,8(sp)
    80003f0a:	1880                	addi	s0,sp,112
    80003f0c:	8b2a                	mv	s6,a0
    80003f0e:	8bae                	mv	s7,a1
    80003f10:	8a32                	mv	s4,a2
    80003f12:	84b6                	mv	s1,a3
    80003f14:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003f16:	9f35                	addw	a4,a4,a3
    return 0;
    80003f18:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003f1a:	0ad76063          	bltu	a4,a3,80003fba <readi+0xd2>
  if(off + n > ip->size)
    80003f1e:	00e7f463          	bgeu	a5,a4,80003f26 <readi+0x3e>
    n = ip->size - off;
    80003f22:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f26:	0a0a8963          	beqz	s5,80003fd8 <readi+0xf0>
    80003f2a:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f2c:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003f30:	5c7d                	li	s8,-1
    80003f32:	a82d                	j	80003f6c <readi+0x84>
    80003f34:	020d1d93          	slli	s11,s10,0x20
    80003f38:	020ddd93          	srli	s11,s11,0x20
    80003f3c:	05890613          	addi	a2,s2,88
    80003f40:	86ee                	mv	a3,s11
    80003f42:	963a                	add	a2,a2,a4
    80003f44:	85d2                	mv	a1,s4
    80003f46:	855e                	mv	a0,s7
    80003f48:	fffff097          	auipc	ra,0xfffff
    80003f4c:	814080e7          	jalr	-2028(ra) # 8000275c <either_copyout>
    80003f50:	05850d63          	beq	a0,s8,80003faa <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003f54:	854a                	mv	a0,s2
    80003f56:	fffff097          	auipc	ra,0xfffff
    80003f5a:	5fe080e7          	jalr	1534(ra) # 80003554 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f5e:	013d09bb          	addw	s3,s10,s3
    80003f62:	009d04bb          	addw	s1,s10,s1
    80003f66:	9a6e                	add	s4,s4,s11
    80003f68:	0559f763          	bgeu	s3,s5,80003fb6 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003f6c:	00a4d59b          	srliw	a1,s1,0xa
    80003f70:	855a                	mv	a0,s6
    80003f72:	00000097          	auipc	ra,0x0
    80003f76:	8a4080e7          	jalr	-1884(ra) # 80003816 <bmap>
    80003f7a:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003f7e:	cd85                	beqz	a1,80003fb6 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003f80:	000b2503          	lw	a0,0(s6)
    80003f84:	fffff097          	auipc	ra,0xfffff
    80003f88:	4a0080e7          	jalr	1184(ra) # 80003424 <bread>
    80003f8c:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f8e:	3ff4f713          	andi	a4,s1,1023
    80003f92:	40ec87bb          	subw	a5,s9,a4
    80003f96:	413a86bb          	subw	a3,s5,s3
    80003f9a:	8d3e                	mv	s10,a5
    80003f9c:	2781                	sext.w	a5,a5
    80003f9e:	0006861b          	sext.w	a2,a3
    80003fa2:	f8f679e3          	bgeu	a2,a5,80003f34 <readi+0x4c>
    80003fa6:	8d36                	mv	s10,a3
    80003fa8:	b771                	j	80003f34 <readi+0x4c>
      brelse(bp);
    80003faa:	854a                	mv	a0,s2
    80003fac:	fffff097          	auipc	ra,0xfffff
    80003fb0:	5a8080e7          	jalr	1448(ra) # 80003554 <brelse>
      tot = -1;
    80003fb4:	59fd                	li	s3,-1
  }
  return tot;
    80003fb6:	0009851b          	sext.w	a0,s3
}
    80003fba:	70a6                	ld	ra,104(sp)
    80003fbc:	7406                	ld	s0,96(sp)
    80003fbe:	64e6                	ld	s1,88(sp)
    80003fc0:	6946                	ld	s2,80(sp)
    80003fc2:	69a6                	ld	s3,72(sp)
    80003fc4:	6a06                	ld	s4,64(sp)
    80003fc6:	7ae2                	ld	s5,56(sp)
    80003fc8:	7b42                	ld	s6,48(sp)
    80003fca:	7ba2                	ld	s7,40(sp)
    80003fcc:	7c02                	ld	s8,32(sp)
    80003fce:	6ce2                	ld	s9,24(sp)
    80003fd0:	6d42                	ld	s10,16(sp)
    80003fd2:	6da2                	ld	s11,8(sp)
    80003fd4:	6165                	addi	sp,sp,112
    80003fd6:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003fd8:	89d6                	mv	s3,s5
    80003fda:	bff1                	j	80003fb6 <readi+0xce>
    return 0;
    80003fdc:	4501                	li	a0,0
}
    80003fde:	8082                	ret

0000000080003fe0 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003fe0:	457c                	lw	a5,76(a0)
    80003fe2:	10d7e863          	bltu	a5,a3,800040f2 <writei+0x112>
{
    80003fe6:	7159                	addi	sp,sp,-112
    80003fe8:	f486                	sd	ra,104(sp)
    80003fea:	f0a2                	sd	s0,96(sp)
    80003fec:	eca6                	sd	s1,88(sp)
    80003fee:	e8ca                	sd	s2,80(sp)
    80003ff0:	e4ce                	sd	s3,72(sp)
    80003ff2:	e0d2                	sd	s4,64(sp)
    80003ff4:	fc56                	sd	s5,56(sp)
    80003ff6:	f85a                	sd	s6,48(sp)
    80003ff8:	f45e                	sd	s7,40(sp)
    80003ffa:	f062                	sd	s8,32(sp)
    80003ffc:	ec66                	sd	s9,24(sp)
    80003ffe:	e86a                	sd	s10,16(sp)
    80004000:	e46e                	sd	s11,8(sp)
    80004002:	1880                	addi	s0,sp,112
    80004004:	8aaa                	mv	s5,a0
    80004006:	8bae                	mv	s7,a1
    80004008:	8a32                	mv	s4,a2
    8000400a:	8936                	mv	s2,a3
    8000400c:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    8000400e:	00e687bb          	addw	a5,a3,a4
    80004012:	0ed7e263          	bltu	a5,a3,800040f6 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004016:	00043737          	lui	a4,0x43
    8000401a:	0ef76063          	bltu	a4,a5,800040fa <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000401e:	0c0b0863          	beqz	s6,800040ee <writei+0x10e>
    80004022:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80004024:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80004028:	5c7d                	li	s8,-1
    8000402a:	a091                	j	8000406e <writei+0x8e>
    8000402c:	020d1d93          	slli	s11,s10,0x20
    80004030:	020ddd93          	srli	s11,s11,0x20
    80004034:	05848513          	addi	a0,s1,88
    80004038:	86ee                	mv	a3,s11
    8000403a:	8652                	mv	a2,s4
    8000403c:	85de                	mv	a1,s7
    8000403e:	953a                	add	a0,a0,a4
    80004040:	ffffe097          	auipc	ra,0xffffe
    80004044:	772080e7          	jalr	1906(ra) # 800027b2 <either_copyin>
    80004048:	07850263          	beq	a0,s8,800040ac <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    8000404c:	8526                	mv	a0,s1
    8000404e:	00000097          	auipc	ra,0x0
    80004052:	75e080e7          	jalr	1886(ra) # 800047ac <log_write>
    brelse(bp);
    80004056:	8526                	mv	a0,s1
    80004058:	fffff097          	auipc	ra,0xfffff
    8000405c:	4fc080e7          	jalr	1276(ra) # 80003554 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004060:	013d09bb          	addw	s3,s10,s3
    80004064:	012d093b          	addw	s2,s10,s2
    80004068:	9a6e                	add	s4,s4,s11
    8000406a:	0569f663          	bgeu	s3,s6,800040b6 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    8000406e:	00a9559b          	srliw	a1,s2,0xa
    80004072:	8556                	mv	a0,s5
    80004074:	fffff097          	auipc	ra,0xfffff
    80004078:	7a2080e7          	jalr	1954(ra) # 80003816 <bmap>
    8000407c:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80004080:	c99d                	beqz	a1,800040b6 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80004082:	000aa503          	lw	a0,0(s5)
    80004086:	fffff097          	auipc	ra,0xfffff
    8000408a:	39e080e7          	jalr	926(ra) # 80003424 <bread>
    8000408e:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004090:	3ff97713          	andi	a4,s2,1023
    80004094:	40ec87bb          	subw	a5,s9,a4
    80004098:	413b06bb          	subw	a3,s6,s3
    8000409c:	8d3e                	mv	s10,a5
    8000409e:	2781                	sext.w	a5,a5
    800040a0:	0006861b          	sext.w	a2,a3
    800040a4:	f8f674e3          	bgeu	a2,a5,8000402c <writei+0x4c>
    800040a8:	8d36                	mv	s10,a3
    800040aa:	b749                	j	8000402c <writei+0x4c>
      brelse(bp);
    800040ac:	8526                	mv	a0,s1
    800040ae:	fffff097          	auipc	ra,0xfffff
    800040b2:	4a6080e7          	jalr	1190(ra) # 80003554 <brelse>
  }

  if(off > ip->size)
    800040b6:	04caa783          	lw	a5,76(s5)
    800040ba:	0127f463          	bgeu	a5,s2,800040c2 <writei+0xe2>
    ip->size = off;
    800040be:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800040c2:	8556                	mv	a0,s5
    800040c4:	00000097          	auipc	ra,0x0
    800040c8:	aa4080e7          	jalr	-1372(ra) # 80003b68 <iupdate>

  return tot;
    800040cc:	0009851b          	sext.w	a0,s3
}
    800040d0:	70a6                	ld	ra,104(sp)
    800040d2:	7406                	ld	s0,96(sp)
    800040d4:	64e6                	ld	s1,88(sp)
    800040d6:	6946                	ld	s2,80(sp)
    800040d8:	69a6                	ld	s3,72(sp)
    800040da:	6a06                	ld	s4,64(sp)
    800040dc:	7ae2                	ld	s5,56(sp)
    800040de:	7b42                	ld	s6,48(sp)
    800040e0:	7ba2                	ld	s7,40(sp)
    800040e2:	7c02                	ld	s8,32(sp)
    800040e4:	6ce2                	ld	s9,24(sp)
    800040e6:	6d42                	ld	s10,16(sp)
    800040e8:	6da2                	ld	s11,8(sp)
    800040ea:	6165                	addi	sp,sp,112
    800040ec:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800040ee:	89da                	mv	s3,s6
    800040f0:	bfc9                	j	800040c2 <writei+0xe2>
    return -1;
    800040f2:	557d                	li	a0,-1
}
    800040f4:	8082                	ret
    return -1;
    800040f6:	557d                	li	a0,-1
    800040f8:	bfe1                	j	800040d0 <writei+0xf0>
    return -1;
    800040fa:	557d                	li	a0,-1
    800040fc:	bfd1                	j	800040d0 <writei+0xf0>

00000000800040fe <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800040fe:	1141                	addi	sp,sp,-16
    80004100:	e406                	sd	ra,8(sp)
    80004102:	e022                	sd	s0,0(sp)
    80004104:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004106:	4639                	li	a2,14
    80004108:	ffffd097          	auipc	ra,0xffffd
    8000410c:	dde080e7          	jalr	-546(ra) # 80000ee6 <strncmp>
}
    80004110:	60a2                	ld	ra,8(sp)
    80004112:	6402                	ld	s0,0(sp)
    80004114:	0141                	addi	sp,sp,16
    80004116:	8082                	ret

0000000080004118 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004118:	7139                	addi	sp,sp,-64
    8000411a:	fc06                	sd	ra,56(sp)
    8000411c:	f822                	sd	s0,48(sp)
    8000411e:	f426                	sd	s1,40(sp)
    80004120:	f04a                	sd	s2,32(sp)
    80004122:	ec4e                	sd	s3,24(sp)
    80004124:	e852                	sd	s4,16(sp)
    80004126:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004128:	04451703          	lh	a4,68(a0)
    8000412c:	4785                	li	a5,1
    8000412e:	00f71a63          	bne	a4,a5,80004142 <dirlookup+0x2a>
    80004132:	892a                	mv	s2,a0
    80004134:	89ae                	mv	s3,a1
    80004136:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004138:	457c                	lw	a5,76(a0)
    8000413a:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    8000413c:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000413e:	e79d                	bnez	a5,8000416c <dirlookup+0x54>
    80004140:	a8a5                	j	800041b8 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004142:	00004517          	auipc	a0,0x4
    80004146:	61650513          	addi	a0,a0,1558 # 80008758 <syscalls+0x1c8>
    8000414a:	ffffc097          	auipc	ra,0xffffc
    8000414e:	3f2080e7          	jalr	1010(ra) # 8000053c <panic>
      panic("dirlookup read");
    80004152:	00004517          	auipc	a0,0x4
    80004156:	61e50513          	addi	a0,a0,1566 # 80008770 <syscalls+0x1e0>
    8000415a:	ffffc097          	auipc	ra,0xffffc
    8000415e:	3e2080e7          	jalr	994(ra) # 8000053c <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004162:	24c1                	addiw	s1,s1,16
    80004164:	04c92783          	lw	a5,76(s2)
    80004168:	04f4f763          	bgeu	s1,a5,800041b6 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000416c:	4741                	li	a4,16
    8000416e:	86a6                	mv	a3,s1
    80004170:	fc040613          	addi	a2,s0,-64
    80004174:	4581                	li	a1,0
    80004176:	854a                	mv	a0,s2
    80004178:	00000097          	auipc	ra,0x0
    8000417c:	d70080e7          	jalr	-656(ra) # 80003ee8 <readi>
    80004180:	47c1                	li	a5,16
    80004182:	fcf518e3          	bne	a0,a5,80004152 <dirlookup+0x3a>
    if(de.inum == 0)
    80004186:	fc045783          	lhu	a5,-64(s0)
    8000418a:	dfe1                	beqz	a5,80004162 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    8000418c:	fc240593          	addi	a1,s0,-62
    80004190:	854e                	mv	a0,s3
    80004192:	00000097          	auipc	ra,0x0
    80004196:	f6c080e7          	jalr	-148(ra) # 800040fe <namecmp>
    8000419a:	f561                	bnez	a0,80004162 <dirlookup+0x4a>
      if(poff)
    8000419c:	000a0463          	beqz	s4,800041a4 <dirlookup+0x8c>
        *poff = off;
    800041a0:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800041a4:	fc045583          	lhu	a1,-64(s0)
    800041a8:	00092503          	lw	a0,0(s2)
    800041ac:	fffff097          	auipc	ra,0xfffff
    800041b0:	754080e7          	jalr	1876(ra) # 80003900 <iget>
    800041b4:	a011                	j	800041b8 <dirlookup+0xa0>
  return 0;
    800041b6:	4501                	li	a0,0
}
    800041b8:	70e2                	ld	ra,56(sp)
    800041ba:	7442                	ld	s0,48(sp)
    800041bc:	74a2                	ld	s1,40(sp)
    800041be:	7902                	ld	s2,32(sp)
    800041c0:	69e2                	ld	s3,24(sp)
    800041c2:	6a42                	ld	s4,16(sp)
    800041c4:	6121                	addi	sp,sp,64
    800041c6:	8082                	ret

00000000800041c8 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800041c8:	711d                	addi	sp,sp,-96
    800041ca:	ec86                	sd	ra,88(sp)
    800041cc:	e8a2                	sd	s0,80(sp)
    800041ce:	e4a6                	sd	s1,72(sp)
    800041d0:	e0ca                	sd	s2,64(sp)
    800041d2:	fc4e                	sd	s3,56(sp)
    800041d4:	f852                	sd	s4,48(sp)
    800041d6:	f456                	sd	s5,40(sp)
    800041d8:	f05a                	sd	s6,32(sp)
    800041da:	ec5e                	sd	s7,24(sp)
    800041dc:	e862                	sd	s8,16(sp)
    800041de:	e466                	sd	s9,8(sp)
    800041e0:	1080                	addi	s0,sp,96
    800041e2:	84aa                	mv	s1,a0
    800041e4:	8b2e                	mv	s6,a1
    800041e6:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800041e8:	00054703          	lbu	a4,0(a0)
    800041ec:	02f00793          	li	a5,47
    800041f0:	02f70263          	beq	a4,a5,80004214 <namex+0x4c>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800041f4:	ffffe097          	auipc	ra,0xffffe
    800041f8:	9f8080e7          	jalr	-1544(ra) # 80001bec <myproc>
    800041fc:	15053503          	ld	a0,336(a0)
    80004200:	00000097          	auipc	ra,0x0
    80004204:	9f6080e7          	jalr	-1546(ra) # 80003bf6 <idup>
    80004208:	8a2a                	mv	s4,a0
  while(*path == '/')
    8000420a:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    8000420e:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004210:	4b85                	li	s7,1
    80004212:	a875                	j	800042ce <namex+0x106>
    ip = iget(ROOTDEV, ROOTINO);
    80004214:	4585                	li	a1,1
    80004216:	4505                	li	a0,1
    80004218:	fffff097          	auipc	ra,0xfffff
    8000421c:	6e8080e7          	jalr	1768(ra) # 80003900 <iget>
    80004220:	8a2a                	mv	s4,a0
    80004222:	b7e5                	j	8000420a <namex+0x42>
      iunlockput(ip);
    80004224:	8552                	mv	a0,s4
    80004226:	00000097          	auipc	ra,0x0
    8000422a:	c70080e7          	jalr	-912(ra) # 80003e96 <iunlockput>
      return 0;
    8000422e:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004230:	8552                	mv	a0,s4
    80004232:	60e6                	ld	ra,88(sp)
    80004234:	6446                	ld	s0,80(sp)
    80004236:	64a6                	ld	s1,72(sp)
    80004238:	6906                	ld	s2,64(sp)
    8000423a:	79e2                	ld	s3,56(sp)
    8000423c:	7a42                	ld	s4,48(sp)
    8000423e:	7aa2                	ld	s5,40(sp)
    80004240:	7b02                	ld	s6,32(sp)
    80004242:	6be2                	ld	s7,24(sp)
    80004244:	6c42                	ld	s8,16(sp)
    80004246:	6ca2                	ld	s9,8(sp)
    80004248:	6125                	addi	sp,sp,96
    8000424a:	8082                	ret
      iunlock(ip);
    8000424c:	8552                	mv	a0,s4
    8000424e:	00000097          	auipc	ra,0x0
    80004252:	aa8080e7          	jalr	-1368(ra) # 80003cf6 <iunlock>
      return ip;
    80004256:	bfe9                	j	80004230 <namex+0x68>
      iunlockput(ip);
    80004258:	8552                	mv	a0,s4
    8000425a:	00000097          	auipc	ra,0x0
    8000425e:	c3c080e7          	jalr	-964(ra) # 80003e96 <iunlockput>
      return 0;
    80004262:	8a4e                	mv	s4,s3
    80004264:	b7f1                	j	80004230 <namex+0x68>
  len = path - s;
    80004266:	40998633          	sub	a2,s3,s1
    8000426a:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    8000426e:	099c5863          	bge	s8,s9,800042fe <namex+0x136>
    memmove(name, s, DIRSIZ);
    80004272:	4639                	li	a2,14
    80004274:	85a6                	mv	a1,s1
    80004276:	8556                	mv	a0,s5
    80004278:	ffffd097          	auipc	ra,0xffffd
    8000427c:	bfa080e7          	jalr	-1030(ra) # 80000e72 <memmove>
    80004280:	84ce                	mv	s1,s3
  while(*path == '/')
    80004282:	0004c783          	lbu	a5,0(s1)
    80004286:	01279763          	bne	a5,s2,80004294 <namex+0xcc>
    path++;
    8000428a:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000428c:	0004c783          	lbu	a5,0(s1)
    80004290:	ff278de3          	beq	a5,s2,8000428a <namex+0xc2>
    ilock(ip);
    80004294:	8552                	mv	a0,s4
    80004296:	00000097          	auipc	ra,0x0
    8000429a:	99e080e7          	jalr	-1634(ra) # 80003c34 <ilock>
    if(ip->type != T_DIR){
    8000429e:	044a1783          	lh	a5,68(s4)
    800042a2:	f97791e3          	bne	a5,s7,80004224 <namex+0x5c>
    if(nameiparent && *path == '\0'){
    800042a6:	000b0563          	beqz	s6,800042b0 <namex+0xe8>
    800042aa:	0004c783          	lbu	a5,0(s1)
    800042ae:	dfd9                	beqz	a5,8000424c <namex+0x84>
    if((next = dirlookup(ip, name, 0)) == 0){
    800042b0:	4601                	li	a2,0
    800042b2:	85d6                	mv	a1,s5
    800042b4:	8552                	mv	a0,s4
    800042b6:	00000097          	auipc	ra,0x0
    800042ba:	e62080e7          	jalr	-414(ra) # 80004118 <dirlookup>
    800042be:	89aa                	mv	s3,a0
    800042c0:	dd41                	beqz	a0,80004258 <namex+0x90>
    iunlockput(ip);
    800042c2:	8552                	mv	a0,s4
    800042c4:	00000097          	auipc	ra,0x0
    800042c8:	bd2080e7          	jalr	-1070(ra) # 80003e96 <iunlockput>
    ip = next;
    800042cc:	8a4e                	mv	s4,s3
  while(*path == '/')
    800042ce:	0004c783          	lbu	a5,0(s1)
    800042d2:	01279763          	bne	a5,s2,800042e0 <namex+0x118>
    path++;
    800042d6:	0485                	addi	s1,s1,1
  while(*path == '/')
    800042d8:	0004c783          	lbu	a5,0(s1)
    800042dc:	ff278de3          	beq	a5,s2,800042d6 <namex+0x10e>
  if(*path == 0)
    800042e0:	cb9d                	beqz	a5,80004316 <namex+0x14e>
  while(*path != '/' && *path != 0)
    800042e2:	0004c783          	lbu	a5,0(s1)
    800042e6:	89a6                	mv	s3,s1
  len = path - s;
    800042e8:	4c81                	li	s9,0
    800042ea:	4601                	li	a2,0
  while(*path != '/' && *path != 0)
    800042ec:	01278963          	beq	a5,s2,800042fe <namex+0x136>
    800042f0:	dbbd                	beqz	a5,80004266 <namex+0x9e>
    path++;
    800042f2:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    800042f4:	0009c783          	lbu	a5,0(s3)
    800042f8:	ff279ce3          	bne	a5,s2,800042f0 <namex+0x128>
    800042fc:	b7ad                	j	80004266 <namex+0x9e>
    memmove(name, s, len);
    800042fe:	2601                	sext.w	a2,a2
    80004300:	85a6                	mv	a1,s1
    80004302:	8556                	mv	a0,s5
    80004304:	ffffd097          	auipc	ra,0xffffd
    80004308:	b6e080e7          	jalr	-1170(ra) # 80000e72 <memmove>
    name[len] = 0;
    8000430c:	9cd6                	add	s9,s9,s5
    8000430e:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80004312:	84ce                	mv	s1,s3
    80004314:	b7bd                	j	80004282 <namex+0xba>
  if(nameiparent){
    80004316:	f00b0de3          	beqz	s6,80004230 <namex+0x68>
    iput(ip);
    8000431a:	8552                	mv	a0,s4
    8000431c:	00000097          	auipc	ra,0x0
    80004320:	ad2080e7          	jalr	-1326(ra) # 80003dee <iput>
    return 0;
    80004324:	4a01                	li	s4,0
    80004326:	b729                	j	80004230 <namex+0x68>

0000000080004328 <dirlink>:
{
    80004328:	7139                	addi	sp,sp,-64
    8000432a:	fc06                	sd	ra,56(sp)
    8000432c:	f822                	sd	s0,48(sp)
    8000432e:	f426                	sd	s1,40(sp)
    80004330:	f04a                	sd	s2,32(sp)
    80004332:	ec4e                	sd	s3,24(sp)
    80004334:	e852                	sd	s4,16(sp)
    80004336:	0080                	addi	s0,sp,64
    80004338:	892a                	mv	s2,a0
    8000433a:	8a2e                	mv	s4,a1
    8000433c:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000433e:	4601                	li	a2,0
    80004340:	00000097          	auipc	ra,0x0
    80004344:	dd8080e7          	jalr	-552(ra) # 80004118 <dirlookup>
    80004348:	e93d                	bnez	a0,800043be <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000434a:	04c92483          	lw	s1,76(s2)
    8000434e:	c49d                	beqz	s1,8000437c <dirlink+0x54>
    80004350:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004352:	4741                	li	a4,16
    80004354:	86a6                	mv	a3,s1
    80004356:	fc040613          	addi	a2,s0,-64
    8000435a:	4581                	li	a1,0
    8000435c:	854a                	mv	a0,s2
    8000435e:	00000097          	auipc	ra,0x0
    80004362:	b8a080e7          	jalr	-1142(ra) # 80003ee8 <readi>
    80004366:	47c1                	li	a5,16
    80004368:	06f51163          	bne	a0,a5,800043ca <dirlink+0xa2>
    if(de.inum == 0)
    8000436c:	fc045783          	lhu	a5,-64(s0)
    80004370:	c791                	beqz	a5,8000437c <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004372:	24c1                	addiw	s1,s1,16
    80004374:	04c92783          	lw	a5,76(s2)
    80004378:	fcf4ede3          	bltu	s1,a5,80004352 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000437c:	4639                	li	a2,14
    8000437e:	85d2                	mv	a1,s4
    80004380:	fc240513          	addi	a0,s0,-62
    80004384:	ffffd097          	auipc	ra,0xffffd
    80004388:	b9e080e7          	jalr	-1122(ra) # 80000f22 <strncpy>
  de.inum = inum;
    8000438c:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004390:	4741                	li	a4,16
    80004392:	86a6                	mv	a3,s1
    80004394:	fc040613          	addi	a2,s0,-64
    80004398:	4581                	li	a1,0
    8000439a:	854a                	mv	a0,s2
    8000439c:	00000097          	auipc	ra,0x0
    800043a0:	c44080e7          	jalr	-956(ra) # 80003fe0 <writei>
    800043a4:	1541                	addi	a0,a0,-16
    800043a6:	00a03533          	snez	a0,a0
    800043aa:	40a00533          	neg	a0,a0
}
    800043ae:	70e2                	ld	ra,56(sp)
    800043b0:	7442                	ld	s0,48(sp)
    800043b2:	74a2                	ld	s1,40(sp)
    800043b4:	7902                	ld	s2,32(sp)
    800043b6:	69e2                	ld	s3,24(sp)
    800043b8:	6a42                	ld	s4,16(sp)
    800043ba:	6121                	addi	sp,sp,64
    800043bc:	8082                	ret
    iput(ip);
    800043be:	00000097          	auipc	ra,0x0
    800043c2:	a30080e7          	jalr	-1488(ra) # 80003dee <iput>
    return -1;
    800043c6:	557d                	li	a0,-1
    800043c8:	b7dd                	j	800043ae <dirlink+0x86>
      panic("dirlink read");
    800043ca:	00004517          	auipc	a0,0x4
    800043ce:	3b650513          	addi	a0,a0,950 # 80008780 <syscalls+0x1f0>
    800043d2:	ffffc097          	auipc	ra,0xffffc
    800043d6:	16a080e7          	jalr	362(ra) # 8000053c <panic>

00000000800043da <namei>:

struct inode*
namei(char *path)
{
    800043da:	1101                	addi	sp,sp,-32
    800043dc:	ec06                	sd	ra,24(sp)
    800043de:	e822                	sd	s0,16(sp)
    800043e0:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800043e2:	fe040613          	addi	a2,s0,-32
    800043e6:	4581                	li	a1,0
    800043e8:	00000097          	auipc	ra,0x0
    800043ec:	de0080e7          	jalr	-544(ra) # 800041c8 <namex>
}
    800043f0:	60e2                	ld	ra,24(sp)
    800043f2:	6442                	ld	s0,16(sp)
    800043f4:	6105                	addi	sp,sp,32
    800043f6:	8082                	ret

00000000800043f8 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800043f8:	1141                	addi	sp,sp,-16
    800043fa:	e406                	sd	ra,8(sp)
    800043fc:	e022                	sd	s0,0(sp)
    800043fe:	0800                	addi	s0,sp,16
    80004400:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004402:	4585                	li	a1,1
    80004404:	00000097          	auipc	ra,0x0
    80004408:	dc4080e7          	jalr	-572(ra) # 800041c8 <namex>
}
    8000440c:	60a2                	ld	ra,8(sp)
    8000440e:	6402                	ld	s0,0(sp)
    80004410:	0141                	addi	sp,sp,16
    80004412:	8082                	ret

0000000080004414 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004414:	1101                	addi	sp,sp,-32
    80004416:	ec06                	sd	ra,24(sp)
    80004418:	e822                	sd	s0,16(sp)
    8000441a:	e426                	sd	s1,8(sp)
    8000441c:	e04a                	sd	s2,0(sp)
    8000441e:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004420:	0003d917          	auipc	s2,0x3d
    80004424:	89090913          	addi	s2,s2,-1904 # 80040cb0 <log>
    80004428:	01892583          	lw	a1,24(s2)
    8000442c:	02892503          	lw	a0,40(s2)
    80004430:	fffff097          	auipc	ra,0xfffff
    80004434:	ff4080e7          	jalr	-12(ra) # 80003424 <bread>
    80004438:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000443a:	02c92603          	lw	a2,44(s2)
    8000443e:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004440:	00c05f63          	blez	a2,8000445e <write_head+0x4a>
    80004444:	0003d717          	auipc	a4,0x3d
    80004448:	89c70713          	addi	a4,a4,-1892 # 80040ce0 <log+0x30>
    8000444c:	87aa                	mv	a5,a0
    8000444e:	060a                	slli	a2,a2,0x2
    80004450:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    80004452:	4314                	lw	a3,0(a4)
    80004454:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    80004456:	0711                	addi	a4,a4,4
    80004458:	0791                	addi	a5,a5,4
    8000445a:	fec79ce3          	bne	a5,a2,80004452 <write_head+0x3e>
  }
  bwrite(buf);
    8000445e:	8526                	mv	a0,s1
    80004460:	fffff097          	auipc	ra,0xfffff
    80004464:	0b6080e7          	jalr	182(ra) # 80003516 <bwrite>
  brelse(buf);
    80004468:	8526                	mv	a0,s1
    8000446a:	fffff097          	auipc	ra,0xfffff
    8000446e:	0ea080e7          	jalr	234(ra) # 80003554 <brelse>
}
    80004472:	60e2                	ld	ra,24(sp)
    80004474:	6442                	ld	s0,16(sp)
    80004476:	64a2                	ld	s1,8(sp)
    80004478:	6902                	ld	s2,0(sp)
    8000447a:	6105                	addi	sp,sp,32
    8000447c:	8082                	ret

000000008000447e <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000447e:	0003d797          	auipc	a5,0x3d
    80004482:	85e7a783          	lw	a5,-1954(a5) # 80040cdc <log+0x2c>
    80004486:	0af05d63          	blez	a5,80004540 <install_trans+0xc2>
{
    8000448a:	7139                	addi	sp,sp,-64
    8000448c:	fc06                	sd	ra,56(sp)
    8000448e:	f822                	sd	s0,48(sp)
    80004490:	f426                	sd	s1,40(sp)
    80004492:	f04a                	sd	s2,32(sp)
    80004494:	ec4e                	sd	s3,24(sp)
    80004496:	e852                	sd	s4,16(sp)
    80004498:	e456                	sd	s5,8(sp)
    8000449a:	e05a                	sd	s6,0(sp)
    8000449c:	0080                	addi	s0,sp,64
    8000449e:	8b2a                	mv	s6,a0
    800044a0:	0003da97          	auipc	s5,0x3d
    800044a4:	840a8a93          	addi	s5,s5,-1984 # 80040ce0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044a8:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800044aa:	0003d997          	auipc	s3,0x3d
    800044ae:	80698993          	addi	s3,s3,-2042 # 80040cb0 <log>
    800044b2:	a00d                	j	800044d4 <install_trans+0x56>
    brelse(lbuf);
    800044b4:	854a                	mv	a0,s2
    800044b6:	fffff097          	auipc	ra,0xfffff
    800044ba:	09e080e7          	jalr	158(ra) # 80003554 <brelse>
    brelse(dbuf);
    800044be:	8526                	mv	a0,s1
    800044c0:	fffff097          	auipc	ra,0xfffff
    800044c4:	094080e7          	jalr	148(ra) # 80003554 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044c8:	2a05                	addiw	s4,s4,1
    800044ca:	0a91                	addi	s5,s5,4
    800044cc:	02c9a783          	lw	a5,44(s3)
    800044d0:	04fa5e63          	bge	s4,a5,8000452c <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800044d4:	0189a583          	lw	a1,24(s3)
    800044d8:	014585bb          	addw	a1,a1,s4
    800044dc:	2585                	addiw	a1,a1,1
    800044de:	0289a503          	lw	a0,40(s3)
    800044e2:	fffff097          	auipc	ra,0xfffff
    800044e6:	f42080e7          	jalr	-190(ra) # 80003424 <bread>
    800044ea:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800044ec:	000aa583          	lw	a1,0(s5)
    800044f0:	0289a503          	lw	a0,40(s3)
    800044f4:	fffff097          	auipc	ra,0xfffff
    800044f8:	f30080e7          	jalr	-208(ra) # 80003424 <bread>
    800044fc:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800044fe:	40000613          	li	a2,1024
    80004502:	05890593          	addi	a1,s2,88
    80004506:	05850513          	addi	a0,a0,88
    8000450a:	ffffd097          	auipc	ra,0xffffd
    8000450e:	968080e7          	jalr	-1688(ra) # 80000e72 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004512:	8526                	mv	a0,s1
    80004514:	fffff097          	auipc	ra,0xfffff
    80004518:	002080e7          	jalr	2(ra) # 80003516 <bwrite>
    if(recovering == 0)
    8000451c:	f80b1ce3          	bnez	s6,800044b4 <install_trans+0x36>
      bunpin(dbuf);
    80004520:	8526                	mv	a0,s1
    80004522:	fffff097          	auipc	ra,0xfffff
    80004526:	10a080e7          	jalr	266(ra) # 8000362c <bunpin>
    8000452a:	b769                	j	800044b4 <install_trans+0x36>
}
    8000452c:	70e2                	ld	ra,56(sp)
    8000452e:	7442                	ld	s0,48(sp)
    80004530:	74a2                	ld	s1,40(sp)
    80004532:	7902                	ld	s2,32(sp)
    80004534:	69e2                	ld	s3,24(sp)
    80004536:	6a42                	ld	s4,16(sp)
    80004538:	6aa2                	ld	s5,8(sp)
    8000453a:	6b02                	ld	s6,0(sp)
    8000453c:	6121                	addi	sp,sp,64
    8000453e:	8082                	ret
    80004540:	8082                	ret

0000000080004542 <initlog>:
{
    80004542:	7179                	addi	sp,sp,-48
    80004544:	f406                	sd	ra,40(sp)
    80004546:	f022                	sd	s0,32(sp)
    80004548:	ec26                	sd	s1,24(sp)
    8000454a:	e84a                	sd	s2,16(sp)
    8000454c:	e44e                	sd	s3,8(sp)
    8000454e:	1800                	addi	s0,sp,48
    80004550:	892a                	mv	s2,a0
    80004552:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004554:	0003c497          	auipc	s1,0x3c
    80004558:	75c48493          	addi	s1,s1,1884 # 80040cb0 <log>
    8000455c:	00004597          	auipc	a1,0x4
    80004560:	23458593          	addi	a1,a1,564 # 80008790 <syscalls+0x200>
    80004564:	8526                	mv	a0,s1
    80004566:	ffffc097          	auipc	ra,0xffffc
    8000456a:	724080e7          	jalr	1828(ra) # 80000c8a <initlock>
  log.start = sb->logstart;
    8000456e:	0149a583          	lw	a1,20(s3)
    80004572:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004574:	0109a783          	lw	a5,16(s3)
    80004578:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000457a:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000457e:	854a                	mv	a0,s2
    80004580:	fffff097          	auipc	ra,0xfffff
    80004584:	ea4080e7          	jalr	-348(ra) # 80003424 <bread>
  log.lh.n = lh->n;
    80004588:	4d30                	lw	a2,88(a0)
    8000458a:	d4d0                	sw	a2,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000458c:	00c05f63          	blez	a2,800045aa <initlog+0x68>
    80004590:	87aa                	mv	a5,a0
    80004592:	0003c717          	auipc	a4,0x3c
    80004596:	74e70713          	addi	a4,a4,1870 # 80040ce0 <log+0x30>
    8000459a:	060a                	slli	a2,a2,0x2
    8000459c:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    8000459e:	4ff4                	lw	a3,92(a5)
    800045a0:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800045a2:	0791                	addi	a5,a5,4
    800045a4:	0711                	addi	a4,a4,4
    800045a6:	fec79ce3          	bne	a5,a2,8000459e <initlog+0x5c>
  brelse(buf);
    800045aa:	fffff097          	auipc	ra,0xfffff
    800045ae:	faa080e7          	jalr	-86(ra) # 80003554 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800045b2:	4505                	li	a0,1
    800045b4:	00000097          	auipc	ra,0x0
    800045b8:	eca080e7          	jalr	-310(ra) # 8000447e <install_trans>
  log.lh.n = 0;
    800045bc:	0003c797          	auipc	a5,0x3c
    800045c0:	7207a023          	sw	zero,1824(a5) # 80040cdc <log+0x2c>
  write_head(); // clear the log
    800045c4:	00000097          	auipc	ra,0x0
    800045c8:	e50080e7          	jalr	-432(ra) # 80004414 <write_head>
}
    800045cc:	70a2                	ld	ra,40(sp)
    800045ce:	7402                	ld	s0,32(sp)
    800045d0:	64e2                	ld	s1,24(sp)
    800045d2:	6942                	ld	s2,16(sp)
    800045d4:	69a2                	ld	s3,8(sp)
    800045d6:	6145                	addi	sp,sp,48
    800045d8:	8082                	ret

00000000800045da <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800045da:	1101                	addi	sp,sp,-32
    800045dc:	ec06                	sd	ra,24(sp)
    800045de:	e822                	sd	s0,16(sp)
    800045e0:	e426                	sd	s1,8(sp)
    800045e2:	e04a                	sd	s2,0(sp)
    800045e4:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800045e6:	0003c517          	auipc	a0,0x3c
    800045ea:	6ca50513          	addi	a0,a0,1738 # 80040cb0 <log>
    800045ee:	ffffc097          	auipc	ra,0xffffc
    800045f2:	72c080e7          	jalr	1836(ra) # 80000d1a <acquire>
  while(1){
    if(log.committing){
    800045f6:	0003c497          	auipc	s1,0x3c
    800045fa:	6ba48493          	addi	s1,s1,1722 # 80040cb0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800045fe:	4979                	li	s2,30
    80004600:	a039                	j	8000460e <begin_op+0x34>
      sleep(&log, &log.lock);
    80004602:	85a6                	mv	a1,s1
    80004604:	8526                	mv	a0,s1
    80004606:	ffffe097          	auipc	ra,0xffffe
    8000460a:	d4e080e7          	jalr	-690(ra) # 80002354 <sleep>
    if(log.committing){
    8000460e:	50dc                	lw	a5,36(s1)
    80004610:	fbed                	bnez	a5,80004602 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004612:	5098                	lw	a4,32(s1)
    80004614:	2705                	addiw	a4,a4,1
    80004616:	0027179b          	slliw	a5,a4,0x2
    8000461a:	9fb9                	addw	a5,a5,a4
    8000461c:	0017979b          	slliw	a5,a5,0x1
    80004620:	54d4                	lw	a3,44(s1)
    80004622:	9fb5                	addw	a5,a5,a3
    80004624:	00f95963          	bge	s2,a5,80004636 <begin_op+0x5c>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004628:	85a6                	mv	a1,s1
    8000462a:	8526                	mv	a0,s1
    8000462c:	ffffe097          	auipc	ra,0xffffe
    80004630:	d28080e7          	jalr	-728(ra) # 80002354 <sleep>
    80004634:	bfe9                	j	8000460e <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004636:	0003c517          	auipc	a0,0x3c
    8000463a:	67a50513          	addi	a0,a0,1658 # 80040cb0 <log>
    8000463e:	d118                	sw	a4,32(a0)
      release(&log.lock);
    80004640:	ffffc097          	auipc	ra,0xffffc
    80004644:	78e080e7          	jalr	1934(ra) # 80000dce <release>
      break;
    }
  }
}
    80004648:	60e2                	ld	ra,24(sp)
    8000464a:	6442                	ld	s0,16(sp)
    8000464c:	64a2                	ld	s1,8(sp)
    8000464e:	6902                	ld	s2,0(sp)
    80004650:	6105                	addi	sp,sp,32
    80004652:	8082                	ret

0000000080004654 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004654:	7139                	addi	sp,sp,-64
    80004656:	fc06                	sd	ra,56(sp)
    80004658:	f822                	sd	s0,48(sp)
    8000465a:	f426                	sd	s1,40(sp)
    8000465c:	f04a                	sd	s2,32(sp)
    8000465e:	ec4e                	sd	s3,24(sp)
    80004660:	e852                	sd	s4,16(sp)
    80004662:	e456                	sd	s5,8(sp)
    80004664:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004666:	0003c497          	auipc	s1,0x3c
    8000466a:	64a48493          	addi	s1,s1,1610 # 80040cb0 <log>
    8000466e:	8526                	mv	a0,s1
    80004670:	ffffc097          	auipc	ra,0xffffc
    80004674:	6aa080e7          	jalr	1706(ra) # 80000d1a <acquire>
  log.outstanding -= 1;
    80004678:	509c                	lw	a5,32(s1)
    8000467a:	37fd                	addiw	a5,a5,-1
    8000467c:	0007891b          	sext.w	s2,a5
    80004680:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004682:	50dc                	lw	a5,36(s1)
    80004684:	e7b9                	bnez	a5,800046d2 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004686:	04091e63          	bnez	s2,800046e2 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    8000468a:	0003c497          	auipc	s1,0x3c
    8000468e:	62648493          	addi	s1,s1,1574 # 80040cb0 <log>
    80004692:	4785                	li	a5,1
    80004694:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004696:	8526                	mv	a0,s1
    80004698:	ffffc097          	auipc	ra,0xffffc
    8000469c:	736080e7          	jalr	1846(ra) # 80000dce <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800046a0:	54dc                	lw	a5,44(s1)
    800046a2:	06f04763          	bgtz	a5,80004710 <end_op+0xbc>
    acquire(&log.lock);
    800046a6:	0003c497          	auipc	s1,0x3c
    800046aa:	60a48493          	addi	s1,s1,1546 # 80040cb0 <log>
    800046ae:	8526                	mv	a0,s1
    800046b0:	ffffc097          	auipc	ra,0xffffc
    800046b4:	66a080e7          	jalr	1642(ra) # 80000d1a <acquire>
    log.committing = 0;
    800046b8:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800046bc:	8526                	mv	a0,s1
    800046be:	ffffe097          	auipc	ra,0xffffe
    800046c2:	cfa080e7          	jalr	-774(ra) # 800023b8 <wakeup>
    release(&log.lock);
    800046c6:	8526                	mv	a0,s1
    800046c8:	ffffc097          	auipc	ra,0xffffc
    800046cc:	706080e7          	jalr	1798(ra) # 80000dce <release>
}
    800046d0:	a03d                	j	800046fe <end_op+0xaa>
    panic("log.committing");
    800046d2:	00004517          	auipc	a0,0x4
    800046d6:	0c650513          	addi	a0,a0,198 # 80008798 <syscalls+0x208>
    800046da:	ffffc097          	auipc	ra,0xffffc
    800046de:	e62080e7          	jalr	-414(ra) # 8000053c <panic>
    wakeup(&log);
    800046e2:	0003c497          	auipc	s1,0x3c
    800046e6:	5ce48493          	addi	s1,s1,1486 # 80040cb0 <log>
    800046ea:	8526                	mv	a0,s1
    800046ec:	ffffe097          	auipc	ra,0xffffe
    800046f0:	ccc080e7          	jalr	-820(ra) # 800023b8 <wakeup>
  release(&log.lock);
    800046f4:	8526                	mv	a0,s1
    800046f6:	ffffc097          	auipc	ra,0xffffc
    800046fa:	6d8080e7          	jalr	1752(ra) # 80000dce <release>
}
    800046fe:	70e2                	ld	ra,56(sp)
    80004700:	7442                	ld	s0,48(sp)
    80004702:	74a2                	ld	s1,40(sp)
    80004704:	7902                	ld	s2,32(sp)
    80004706:	69e2                	ld	s3,24(sp)
    80004708:	6a42                	ld	s4,16(sp)
    8000470a:	6aa2                	ld	s5,8(sp)
    8000470c:	6121                	addi	sp,sp,64
    8000470e:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004710:	0003ca97          	auipc	s5,0x3c
    80004714:	5d0a8a93          	addi	s5,s5,1488 # 80040ce0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004718:	0003ca17          	auipc	s4,0x3c
    8000471c:	598a0a13          	addi	s4,s4,1432 # 80040cb0 <log>
    80004720:	018a2583          	lw	a1,24(s4)
    80004724:	012585bb          	addw	a1,a1,s2
    80004728:	2585                	addiw	a1,a1,1
    8000472a:	028a2503          	lw	a0,40(s4)
    8000472e:	fffff097          	auipc	ra,0xfffff
    80004732:	cf6080e7          	jalr	-778(ra) # 80003424 <bread>
    80004736:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004738:	000aa583          	lw	a1,0(s5)
    8000473c:	028a2503          	lw	a0,40(s4)
    80004740:	fffff097          	auipc	ra,0xfffff
    80004744:	ce4080e7          	jalr	-796(ra) # 80003424 <bread>
    80004748:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000474a:	40000613          	li	a2,1024
    8000474e:	05850593          	addi	a1,a0,88
    80004752:	05848513          	addi	a0,s1,88
    80004756:	ffffc097          	auipc	ra,0xffffc
    8000475a:	71c080e7          	jalr	1820(ra) # 80000e72 <memmove>
    bwrite(to);  // write the log
    8000475e:	8526                	mv	a0,s1
    80004760:	fffff097          	auipc	ra,0xfffff
    80004764:	db6080e7          	jalr	-586(ra) # 80003516 <bwrite>
    brelse(from);
    80004768:	854e                	mv	a0,s3
    8000476a:	fffff097          	auipc	ra,0xfffff
    8000476e:	dea080e7          	jalr	-534(ra) # 80003554 <brelse>
    brelse(to);
    80004772:	8526                	mv	a0,s1
    80004774:	fffff097          	auipc	ra,0xfffff
    80004778:	de0080e7          	jalr	-544(ra) # 80003554 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000477c:	2905                	addiw	s2,s2,1
    8000477e:	0a91                	addi	s5,s5,4
    80004780:	02ca2783          	lw	a5,44(s4)
    80004784:	f8f94ee3          	blt	s2,a5,80004720 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004788:	00000097          	auipc	ra,0x0
    8000478c:	c8c080e7          	jalr	-884(ra) # 80004414 <write_head>
    install_trans(0); // Now install writes to home locations
    80004790:	4501                	li	a0,0
    80004792:	00000097          	auipc	ra,0x0
    80004796:	cec080e7          	jalr	-788(ra) # 8000447e <install_trans>
    log.lh.n = 0;
    8000479a:	0003c797          	auipc	a5,0x3c
    8000479e:	5407a123          	sw	zero,1346(a5) # 80040cdc <log+0x2c>
    write_head();    // Erase the transaction from the log
    800047a2:	00000097          	auipc	ra,0x0
    800047a6:	c72080e7          	jalr	-910(ra) # 80004414 <write_head>
    800047aa:	bdf5                	j	800046a6 <end_op+0x52>

00000000800047ac <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800047ac:	1101                	addi	sp,sp,-32
    800047ae:	ec06                	sd	ra,24(sp)
    800047b0:	e822                	sd	s0,16(sp)
    800047b2:	e426                	sd	s1,8(sp)
    800047b4:	e04a                	sd	s2,0(sp)
    800047b6:	1000                	addi	s0,sp,32
    800047b8:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800047ba:	0003c917          	auipc	s2,0x3c
    800047be:	4f690913          	addi	s2,s2,1270 # 80040cb0 <log>
    800047c2:	854a                	mv	a0,s2
    800047c4:	ffffc097          	auipc	ra,0xffffc
    800047c8:	556080e7          	jalr	1366(ra) # 80000d1a <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800047cc:	02c92603          	lw	a2,44(s2)
    800047d0:	47f5                	li	a5,29
    800047d2:	06c7c563          	blt	a5,a2,8000483c <log_write+0x90>
    800047d6:	0003c797          	auipc	a5,0x3c
    800047da:	4f67a783          	lw	a5,1270(a5) # 80040ccc <log+0x1c>
    800047de:	37fd                	addiw	a5,a5,-1
    800047e0:	04f65e63          	bge	a2,a5,8000483c <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800047e4:	0003c797          	auipc	a5,0x3c
    800047e8:	4ec7a783          	lw	a5,1260(a5) # 80040cd0 <log+0x20>
    800047ec:	06f05063          	blez	a5,8000484c <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800047f0:	4781                	li	a5,0
    800047f2:	06c05563          	blez	a2,8000485c <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800047f6:	44cc                	lw	a1,12(s1)
    800047f8:	0003c717          	auipc	a4,0x3c
    800047fc:	4e870713          	addi	a4,a4,1256 # 80040ce0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004800:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004802:	4314                	lw	a3,0(a4)
    80004804:	04b68c63          	beq	a3,a1,8000485c <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004808:	2785                	addiw	a5,a5,1
    8000480a:	0711                	addi	a4,a4,4
    8000480c:	fef61be3          	bne	a2,a5,80004802 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004810:	0621                	addi	a2,a2,8
    80004812:	060a                	slli	a2,a2,0x2
    80004814:	0003c797          	auipc	a5,0x3c
    80004818:	49c78793          	addi	a5,a5,1180 # 80040cb0 <log>
    8000481c:	97b2                	add	a5,a5,a2
    8000481e:	44d8                	lw	a4,12(s1)
    80004820:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004822:	8526                	mv	a0,s1
    80004824:	fffff097          	auipc	ra,0xfffff
    80004828:	dcc080e7          	jalr	-564(ra) # 800035f0 <bpin>
    log.lh.n++;
    8000482c:	0003c717          	auipc	a4,0x3c
    80004830:	48470713          	addi	a4,a4,1156 # 80040cb0 <log>
    80004834:	575c                	lw	a5,44(a4)
    80004836:	2785                	addiw	a5,a5,1
    80004838:	d75c                	sw	a5,44(a4)
    8000483a:	a82d                	j	80004874 <log_write+0xc8>
    panic("too big a transaction");
    8000483c:	00004517          	auipc	a0,0x4
    80004840:	f6c50513          	addi	a0,a0,-148 # 800087a8 <syscalls+0x218>
    80004844:	ffffc097          	auipc	ra,0xffffc
    80004848:	cf8080e7          	jalr	-776(ra) # 8000053c <panic>
    panic("log_write outside of trans");
    8000484c:	00004517          	auipc	a0,0x4
    80004850:	f7450513          	addi	a0,a0,-140 # 800087c0 <syscalls+0x230>
    80004854:	ffffc097          	auipc	ra,0xffffc
    80004858:	ce8080e7          	jalr	-792(ra) # 8000053c <panic>
  log.lh.block[i] = b->blockno;
    8000485c:	00878693          	addi	a3,a5,8
    80004860:	068a                	slli	a3,a3,0x2
    80004862:	0003c717          	auipc	a4,0x3c
    80004866:	44e70713          	addi	a4,a4,1102 # 80040cb0 <log>
    8000486a:	9736                	add	a4,a4,a3
    8000486c:	44d4                	lw	a3,12(s1)
    8000486e:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004870:	faf609e3          	beq	a2,a5,80004822 <log_write+0x76>
  }
  release(&log.lock);
    80004874:	0003c517          	auipc	a0,0x3c
    80004878:	43c50513          	addi	a0,a0,1084 # 80040cb0 <log>
    8000487c:	ffffc097          	auipc	ra,0xffffc
    80004880:	552080e7          	jalr	1362(ra) # 80000dce <release>
}
    80004884:	60e2                	ld	ra,24(sp)
    80004886:	6442                	ld	s0,16(sp)
    80004888:	64a2                	ld	s1,8(sp)
    8000488a:	6902                	ld	s2,0(sp)
    8000488c:	6105                	addi	sp,sp,32
    8000488e:	8082                	ret

0000000080004890 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004890:	1101                	addi	sp,sp,-32
    80004892:	ec06                	sd	ra,24(sp)
    80004894:	e822                	sd	s0,16(sp)
    80004896:	e426                	sd	s1,8(sp)
    80004898:	e04a                	sd	s2,0(sp)
    8000489a:	1000                	addi	s0,sp,32
    8000489c:	84aa                	mv	s1,a0
    8000489e:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800048a0:	00004597          	auipc	a1,0x4
    800048a4:	f4058593          	addi	a1,a1,-192 # 800087e0 <syscalls+0x250>
    800048a8:	0521                	addi	a0,a0,8
    800048aa:	ffffc097          	auipc	ra,0xffffc
    800048ae:	3e0080e7          	jalr	992(ra) # 80000c8a <initlock>
  lk->name = name;
    800048b2:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800048b6:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800048ba:	0204a423          	sw	zero,40(s1)
}
    800048be:	60e2                	ld	ra,24(sp)
    800048c0:	6442                	ld	s0,16(sp)
    800048c2:	64a2                	ld	s1,8(sp)
    800048c4:	6902                	ld	s2,0(sp)
    800048c6:	6105                	addi	sp,sp,32
    800048c8:	8082                	ret

00000000800048ca <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800048ca:	1101                	addi	sp,sp,-32
    800048cc:	ec06                	sd	ra,24(sp)
    800048ce:	e822                	sd	s0,16(sp)
    800048d0:	e426                	sd	s1,8(sp)
    800048d2:	e04a                	sd	s2,0(sp)
    800048d4:	1000                	addi	s0,sp,32
    800048d6:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800048d8:	00850913          	addi	s2,a0,8
    800048dc:	854a                	mv	a0,s2
    800048de:	ffffc097          	auipc	ra,0xffffc
    800048e2:	43c080e7          	jalr	1084(ra) # 80000d1a <acquire>
  while (lk->locked) {
    800048e6:	409c                	lw	a5,0(s1)
    800048e8:	cb89                	beqz	a5,800048fa <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800048ea:	85ca                	mv	a1,s2
    800048ec:	8526                	mv	a0,s1
    800048ee:	ffffe097          	auipc	ra,0xffffe
    800048f2:	a66080e7          	jalr	-1434(ra) # 80002354 <sleep>
  while (lk->locked) {
    800048f6:	409c                	lw	a5,0(s1)
    800048f8:	fbed                	bnez	a5,800048ea <acquiresleep+0x20>
  }
  lk->locked = 1;
    800048fa:	4785                	li	a5,1
    800048fc:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800048fe:	ffffd097          	auipc	ra,0xffffd
    80004902:	2ee080e7          	jalr	750(ra) # 80001bec <myproc>
    80004906:	591c                	lw	a5,48(a0)
    80004908:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000490a:	854a                	mv	a0,s2
    8000490c:	ffffc097          	auipc	ra,0xffffc
    80004910:	4c2080e7          	jalr	1218(ra) # 80000dce <release>
}
    80004914:	60e2                	ld	ra,24(sp)
    80004916:	6442                	ld	s0,16(sp)
    80004918:	64a2                	ld	s1,8(sp)
    8000491a:	6902                	ld	s2,0(sp)
    8000491c:	6105                	addi	sp,sp,32
    8000491e:	8082                	ret

0000000080004920 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004920:	1101                	addi	sp,sp,-32
    80004922:	ec06                	sd	ra,24(sp)
    80004924:	e822                	sd	s0,16(sp)
    80004926:	e426                	sd	s1,8(sp)
    80004928:	e04a                	sd	s2,0(sp)
    8000492a:	1000                	addi	s0,sp,32
    8000492c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000492e:	00850913          	addi	s2,a0,8
    80004932:	854a                	mv	a0,s2
    80004934:	ffffc097          	auipc	ra,0xffffc
    80004938:	3e6080e7          	jalr	998(ra) # 80000d1a <acquire>
  lk->locked = 0;
    8000493c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004940:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004944:	8526                	mv	a0,s1
    80004946:	ffffe097          	auipc	ra,0xffffe
    8000494a:	a72080e7          	jalr	-1422(ra) # 800023b8 <wakeup>
  release(&lk->lk);
    8000494e:	854a                	mv	a0,s2
    80004950:	ffffc097          	auipc	ra,0xffffc
    80004954:	47e080e7          	jalr	1150(ra) # 80000dce <release>
}
    80004958:	60e2                	ld	ra,24(sp)
    8000495a:	6442                	ld	s0,16(sp)
    8000495c:	64a2                	ld	s1,8(sp)
    8000495e:	6902                	ld	s2,0(sp)
    80004960:	6105                	addi	sp,sp,32
    80004962:	8082                	ret

0000000080004964 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004964:	7179                	addi	sp,sp,-48
    80004966:	f406                	sd	ra,40(sp)
    80004968:	f022                	sd	s0,32(sp)
    8000496a:	ec26                	sd	s1,24(sp)
    8000496c:	e84a                	sd	s2,16(sp)
    8000496e:	e44e                	sd	s3,8(sp)
    80004970:	1800                	addi	s0,sp,48
    80004972:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004974:	00850913          	addi	s2,a0,8
    80004978:	854a                	mv	a0,s2
    8000497a:	ffffc097          	auipc	ra,0xffffc
    8000497e:	3a0080e7          	jalr	928(ra) # 80000d1a <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004982:	409c                	lw	a5,0(s1)
    80004984:	ef99                	bnez	a5,800049a2 <holdingsleep+0x3e>
    80004986:	4481                	li	s1,0
  release(&lk->lk);
    80004988:	854a                	mv	a0,s2
    8000498a:	ffffc097          	auipc	ra,0xffffc
    8000498e:	444080e7          	jalr	1092(ra) # 80000dce <release>
  return r;
}
    80004992:	8526                	mv	a0,s1
    80004994:	70a2                	ld	ra,40(sp)
    80004996:	7402                	ld	s0,32(sp)
    80004998:	64e2                	ld	s1,24(sp)
    8000499a:	6942                	ld	s2,16(sp)
    8000499c:	69a2                	ld	s3,8(sp)
    8000499e:	6145                	addi	sp,sp,48
    800049a0:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800049a2:	0284a983          	lw	s3,40(s1)
    800049a6:	ffffd097          	auipc	ra,0xffffd
    800049aa:	246080e7          	jalr	582(ra) # 80001bec <myproc>
    800049ae:	5904                	lw	s1,48(a0)
    800049b0:	413484b3          	sub	s1,s1,s3
    800049b4:	0014b493          	seqz	s1,s1
    800049b8:	bfc1                	j	80004988 <holdingsleep+0x24>

00000000800049ba <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800049ba:	1141                	addi	sp,sp,-16
    800049bc:	e406                	sd	ra,8(sp)
    800049be:	e022                	sd	s0,0(sp)
    800049c0:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800049c2:	00004597          	auipc	a1,0x4
    800049c6:	e2e58593          	addi	a1,a1,-466 # 800087f0 <syscalls+0x260>
    800049ca:	0003c517          	auipc	a0,0x3c
    800049ce:	42e50513          	addi	a0,a0,1070 # 80040df8 <ftable>
    800049d2:	ffffc097          	auipc	ra,0xffffc
    800049d6:	2b8080e7          	jalr	696(ra) # 80000c8a <initlock>
}
    800049da:	60a2                	ld	ra,8(sp)
    800049dc:	6402                	ld	s0,0(sp)
    800049de:	0141                	addi	sp,sp,16
    800049e0:	8082                	ret

00000000800049e2 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800049e2:	1101                	addi	sp,sp,-32
    800049e4:	ec06                	sd	ra,24(sp)
    800049e6:	e822                	sd	s0,16(sp)
    800049e8:	e426                	sd	s1,8(sp)
    800049ea:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800049ec:	0003c517          	auipc	a0,0x3c
    800049f0:	40c50513          	addi	a0,a0,1036 # 80040df8 <ftable>
    800049f4:	ffffc097          	auipc	ra,0xffffc
    800049f8:	326080e7          	jalr	806(ra) # 80000d1a <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800049fc:	0003c497          	auipc	s1,0x3c
    80004a00:	41448493          	addi	s1,s1,1044 # 80040e10 <ftable+0x18>
    80004a04:	0003d717          	auipc	a4,0x3d
    80004a08:	3ac70713          	addi	a4,a4,940 # 80041db0 <disk>
    if(f->ref == 0){
    80004a0c:	40dc                	lw	a5,4(s1)
    80004a0e:	cf99                	beqz	a5,80004a2c <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004a10:	02848493          	addi	s1,s1,40
    80004a14:	fee49ce3          	bne	s1,a4,80004a0c <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004a18:	0003c517          	auipc	a0,0x3c
    80004a1c:	3e050513          	addi	a0,a0,992 # 80040df8 <ftable>
    80004a20:	ffffc097          	auipc	ra,0xffffc
    80004a24:	3ae080e7          	jalr	942(ra) # 80000dce <release>
  return 0;
    80004a28:	4481                	li	s1,0
    80004a2a:	a819                	j	80004a40 <filealloc+0x5e>
      f->ref = 1;
    80004a2c:	4785                	li	a5,1
    80004a2e:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004a30:	0003c517          	auipc	a0,0x3c
    80004a34:	3c850513          	addi	a0,a0,968 # 80040df8 <ftable>
    80004a38:	ffffc097          	auipc	ra,0xffffc
    80004a3c:	396080e7          	jalr	918(ra) # 80000dce <release>
}
    80004a40:	8526                	mv	a0,s1
    80004a42:	60e2                	ld	ra,24(sp)
    80004a44:	6442                	ld	s0,16(sp)
    80004a46:	64a2                	ld	s1,8(sp)
    80004a48:	6105                	addi	sp,sp,32
    80004a4a:	8082                	ret

0000000080004a4c <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004a4c:	1101                	addi	sp,sp,-32
    80004a4e:	ec06                	sd	ra,24(sp)
    80004a50:	e822                	sd	s0,16(sp)
    80004a52:	e426                	sd	s1,8(sp)
    80004a54:	1000                	addi	s0,sp,32
    80004a56:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004a58:	0003c517          	auipc	a0,0x3c
    80004a5c:	3a050513          	addi	a0,a0,928 # 80040df8 <ftable>
    80004a60:	ffffc097          	auipc	ra,0xffffc
    80004a64:	2ba080e7          	jalr	698(ra) # 80000d1a <acquire>
  if(f->ref < 1)
    80004a68:	40dc                	lw	a5,4(s1)
    80004a6a:	02f05263          	blez	a5,80004a8e <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004a6e:	2785                	addiw	a5,a5,1
    80004a70:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004a72:	0003c517          	auipc	a0,0x3c
    80004a76:	38650513          	addi	a0,a0,902 # 80040df8 <ftable>
    80004a7a:	ffffc097          	auipc	ra,0xffffc
    80004a7e:	354080e7          	jalr	852(ra) # 80000dce <release>
  return f;
}
    80004a82:	8526                	mv	a0,s1
    80004a84:	60e2                	ld	ra,24(sp)
    80004a86:	6442                	ld	s0,16(sp)
    80004a88:	64a2                	ld	s1,8(sp)
    80004a8a:	6105                	addi	sp,sp,32
    80004a8c:	8082                	ret
    panic("filedup");
    80004a8e:	00004517          	auipc	a0,0x4
    80004a92:	d6a50513          	addi	a0,a0,-662 # 800087f8 <syscalls+0x268>
    80004a96:	ffffc097          	auipc	ra,0xffffc
    80004a9a:	aa6080e7          	jalr	-1370(ra) # 8000053c <panic>

0000000080004a9e <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004a9e:	7139                	addi	sp,sp,-64
    80004aa0:	fc06                	sd	ra,56(sp)
    80004aa2:	f822                	sd	s0,48(sp)
    80004aa4:	f426                	sd	s1,40(sp)
    80004aa6:	f04a                	sd	s2,32(sp)
    80004aa8:	ec4e                	sd	s3,24(sp)
    80004aaa:	e852                	sd	s4,16(sp)
    80004aac:	e456                	sd	s5,8(sp)
    80004aae:	0080                	addi	s0,sp,64
    80004ab0:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004ab2:	0003c517          	auipc	a0,0x3c
    80004ab6:	34650513          	addi	a0,a0,838 # 80040df8 <ftable>
    80004aba:	ffffc097          	auipc	ra,0xffffc
    80004abe:	260080e7          	jalr	608(ra) # 80000d1a <acquire>
  if(f->ref < 1)
    80004ac2:	40dc                	lw	a5,4(s1)
    80004ac4:	06f05163          	blez	a5,80004b26 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004ac8:	37fd                	addiw	a5,a5,-1
    80004aca:	0007871b          	sext.w	a4,a5
    80004ace:	c0dc                	sw	a5,4(s1)
    80004ad0:	06e04363          	bgtz	a4,80004b36 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004ad4:	0004a903          	lw	s2,0(s1)
    80004ad8:	0094ca83          	lbu	s5,9(s1)
    80004adc:	0104ba03          	ld	s4,16(s1)
    80004ae0:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004ae4:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004ae8:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004aec:	0003c517          	auipc	a0,0x3c
    80004af0:	30c50513          	addi	a0,a0,780 # 80040df8 <ftable>
    80004af4:	ffffc097          	auipc	ra,0xffffc
    80004af8:	2da080e7          	jalr	730(ra) # 80000dce <release>

  if(ff.type == FD_PIPE){
    80004afc:	4785                	li	a5,1
    80004afe:	04f90d63          	beq	s2,a5,80004b58 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004b02:	3979                	addiw	s2,s2,-2
    80004b04:	4785                	li	a5,1
    80004b06:	0527e063          	bltu	a5,s2,80004b46 <fileclose+0xa8>
    begin_op();
    80004b0a:	00000097          	auipc	ra,0x0
    80004b0e:	ad0080e7          	jalr	-1328(ra) # 800045da <begin_op>
    iput(ff.ip);
    80004b12:	854e                	mv	a0,s3
    80004b14:	fffff097          	auipc	ra,0xfffff
    80004b18:	2da080e7          	jalr	730(ra) # 80003dee <iput>
    end_op();
    80004b1c:	00000097          	auipc	ra,0x0
    80004b20:	b38080e7          	jalr	-1224(ra) # 80004654 <end_op>
    80004b24:	a00d                	j	80004b46 <fileclose+0xa8>
    panic("fileclose");
    80004b26:	00004517          	auipc	a0,0x4
    80004b2a:	cda50513          	addi	a0,a0,-806 # 80008800 <syscalls+0x270>
    80004b2e:	ffffc097          	auipc	ra,0xffffc
    80004b32:	a0e080e7          	jalr	-1522(ra) # 8000053c <panic>
    release(&ftable.lock);
    80004b36:	0003c517          	auipc	a0,0x3c
    80004b3a:	2c250513          	addi	a0,a0,706 # 80040df8 <ftable>
    80004b3e:	ffffc097          	auipc	ra,0xffffc
    80004b42:	290080e7          	jalr	656(ra) # 80000dce <release>
  }
}
    80004b46:	70e2                	ld	ra,56(sp)
    80004b48:	7442                	ld	s0,48(sp)
    80004b4a:	74a2                	ld	s1,40(sp)
    80004b4c:	7902                	ld	s2,32(sp)
    80004b4e:	69e2                	ld	s3,24(sp)
    80004b50:	6a42                	ld	s4,16(sp)
    80004b52:	6aa2                	ld	s5,8(sp)
    80004b54:	6121                	addi	sp,sp,64
    80004b56:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004b58:	85d6                	mv	a1,s5
    80004b5a:	8552                	mv	a0,s4
    80004b5c:	00000097          	auipc	ra,0x0
    80004b60:	348080e7          	jalr	840(ra) # 80004ea4 <pipeclose>
    80004b64:	b7cd                	j	80004b46 <fileclose+0xa8>

0000000080004b66 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004b66:	715d                	addi	sp,sp,-80
    80004b68:	e486                	sd	ra,72(sp)
    80004b6a:	e0a2                	sd	s0,64(sp)
    80004b6c:	fc26                	sd	s1,56(sp)
    80004b6e:	f84a                	sd	s2,48(sp)
    80004b70:	f44e                	sd	s3,40(sp)
    80004b72:	0880                	addi	s0,sp,80
    80004b74:	84aa                	mv	s1,a0
    80004b76:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004b78:	ffffd097          	auipc	ra,0xffffd
    80004b7c:	074080e7          	jalr	116(ra) # 80001bec <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004b80:	409c                	lw	a5,0(s1)
    80004b82:	37f9                	addiw	a5,a5,-2
    80004b84:	4705                	li	a4,1
    80004b86:	04f76763          	bltu	a4,a5,80004bd4 <filestat+0x6e>
    80004b8a:	892a                	mv	s2,a0
    ilock(f->ip);
    80004b8c:	6c88                	ld	a0,24(s1)
    80004b8e:	fffff097          	auipc	ra,0xfffff
    80004b92:	0a6080e7          	jalr	166(ra) # 80003c34 <ilock>
    stati(f->ip, &st);
    80004b96:	fb840593          	addi	a1,s0,-72
    80004b9a:	6c88                	ld	a0,24(s1)
    80004b9c:	fffff097          	auipc	ra,0xfffff
    80004ba0:	322080e7          	jalr	802(ra) # 80003ebe <stati>
    iunlock(f->ip);
    80004ba4:	6c88                	ld	a0,24(s1)
    80004ba6:	fffff097          	auipc	ra,0xfffff
    80004baa:	150080e7          	jalr	336(ra) # 80003cf6 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004bae:	46e1                	li	a3,24
    80004bb0:	fb840613          	addi	a2,s0,-72
    80004bb4:	85ce                	mv	a1,s3
    80004bb6:	05093503          	ld	a0,80(s2)
    80004bba:	ffffd097          	auipc	ra,0xffffd
    80004bbe:	bfe080e7          	jalr	-1026(ra) # 800017b8 <copyout>
    80004bc2:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004bc6:	60a6                	ld	ra,72(sp)
    80004bc8:	6406                	ld	s0,64(sp)
    80004bca:	74e2                	ld	s1,56(sp)
    80004bcc:	7942                	ld	s2,48(sp)
    80004bce:	79a2                	ld	s3,40(sp)
    80004bd0:	6161                	addi	sp,sp,80
    80004bd2:	8082                	ret
  return -1;
    80004bd4:	557d                	li	a0,-1
    80004bd6:	bfc5                	j	80004bc6 <filestat+0x60>

0000000080004bd8 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004bd8:	7179                	addi	sp,sp,-48
    80004bda:	f406                	sd	ra,40(sp)
    80004bdc:	f022                	sd	s0,32(sp)
    80004bde:	ec26                	sd	s1,24(sp)
    80004be0:	e84a                	sd	s2,16(sp)
    80004be2:	e44e                	sd	s3,8(sp)
    80004be4:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004be6:	00854783          	lbu	a5,8(a0)
    80004bea:	c3d5                	beqz	a5,80004c8e <fileread+0xb6>
    80004bec:	84aa                	mv	s1,a0
    80004bee:	89ae                	mv	s3,a1
    80004bf0:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004bf2:	411c                	lw	a5,0(a0)
    80004bf4:	4705                	li	a4,1
    80004bf6:	04e78963          	beq	a5,a4,80004c48 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004bfa:	470d                	li	a4,3
    80004bfc:	04e78d63          	beq	a5,a4,80004c56 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004c00:	4709                	li	a4,2
    80004c02:	06e79e63          	bne	a5,a4,80004c7e <fileread+0xa6>
    ilock(f->ip);
    80004c06:	6d08                	ld	a0,24(a0)
    80004c08:	fffff097          	auipc	ra,0xfffff
    80004c0c:	02c080e7          	jalr	44(ra) # 80003c34 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004c10:	874a                	mv	a4,s2
    80004c12:	5094                	lw	a3,32(s1)
    80004c14:	864e                	mv	a2,s3
    80004c16:	4585                	li	a1,1
    80004c18:	6c88                	ld	a0,24(s1)
    80004c1a:	fffff097          	auipc	ra,0xfffff
    80004c1e:	2ce080e7          	jalr	718(ra) # 80003ee8 <readi>
    80004c22:	892a                	mv	s2,a0
    80004c24:	00a05563          	blez	a0,80004c2e <fileread+0x56>
      f->off += r;
    80004c28:	509c                	lw	a5,32(s1)
    80004c2a:	9fa9                	addw	a5,a5,a0
    80004c2c:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004c2e:	6c88                	ld	a0,24(s1)
    80004c30:	fffff097          	auipc	ra,0xfffff
    80004c34:	0c6080e7          	jalr	198(ra) # 80003cf6 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004c38:	854a                	mv	a0,s2
    80004c3a:	70a2                	ld	ra,40(sp)
    80004c3c:	7402                	ld	s0,32(sp)
    80004c3e:	64e2                	ld	s1,24(sp)
    80004c40:	6942                	ld	s2,16(sp)
    80004c42:	69a2                	ld	s3,8(sp)
    80004c44:	6145                	addi	sp,sp,48
    80004c46:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004c48:	6908                	ld	a0,16(a0)
    80004c4a:	00000097          	auipc	ra,0x0
    80004c4e:	3c2080e7          	jalr	962(ra) # 8000500c <piperead>
    80004c52:	892a                	mv	s2,a0
    80004c54:	b7d5                	j	80004c38 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004c56:	02451783          	lh	a5,36(a0)
    80004c5a:	03079693          	slli	a3,a5,0x30
    80004c5e:	92c1                	srli	a3,a3,0x30
    80004c60:	4725                	li	a4,9
    80004c62:	02d76863          	bltu	a4,a3,80004c92 <fileread+0xba>
    80004c66:	0792                	slli	a5,a5,0x4
    80004c68:	0003c717          	auipc	a4,0x3c
    80004c6c:	0f070713          	addi	a4,a4,240 # 80040d58 <devsw>
    80004c70:	97ba                	add	a5,a5,a4
    80004c72:	639c                	ld	a5,0(a5)
    80004c74:	c38d                	beqz	a5,80004c96 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004c76:	4505                	li	a0,1
    80004c78:	9782                	jalr	a5
    80004c7a:	892a                	mv	s2,a0
    80004c7c:	bf75                	j	80004c38 <fileread+0x60>
    panic("fileread");
    80004c7e:	00004517          	auipc	a0,0x4
    80004c82:	b9250513          	addi	a0,a0,-1134 # 80008810 <syscalls+0x280>
    80004c86:	ffffc097          	auipc	ra,0xffffc
    80004c8a:	8b6080e7          	jalr	-1866(ra) # 8000053c <panic>
    return -1;
    80004c8e:	597d                	li	s2,-1
    80004c90:	b765                	j	80004c38 <fileread+0x60>
      return -1;
    80004c92:	597d                	li	s2,-1
    80004c94:	b755                	j	80004c38 <fileread+0x60>
    80004c96:	597d                	li	s2,-1
    80004c98:	b745                	j	80004c38 <fileread+0x60>

0000000080004c9a <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004c9a:	00954783          	lbu	a5,9(a0)
    80004c9e:	10078e63          	beqz	a5,80004dba <filewrite+0x120>
{
    80004ca2:	715d                	addi	sp,sp,-80
    80004ca4:	e486                	sd	ra,72(sp)
    80004ca6:	e0a2                	sd	s0,64(sp)
    80004ca8:	fc26                	sd	s1,56(sp)
    80004caa:	f84a                	sd	s2,48(sp)
    80004cac:	f44e                	sd	s3,40(sp)
    80004cae:	f052                	sd	s4,32(sp)
    80004cb0:	ec56                	sd	s5,24(sp)
    80004cb2:	e85a                	sd	s6,16(sp)
    80004cb4:	e45e                	sd	s7,8(sp)
    80004cb6:	e062                	sd	s8,0(sp)
    80004cb8:	0880                	addi	s0,sp,80
    80004cba:	892a                	mv	s2,a0
    80004cbc:	8b2e                	mv	s6,a1
    80004cbe:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004cc0:	411c                	lw	a5,0(a0)
    80004cc2:	4705                	li	a4,1
    80004cc4:	02e78263          	beq	a5,a4,80004ce8 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004cc8:	470d                	li	a4,3
    80004cca:	02e78563          	beq	a5,a4,80004cf4 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004cce:	4709                	li	a4,2
    80004cd0:	0ce79d63          	bne	a5,a4,80004daa <filewrite+0x110>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004cd4:	0ac05b63          	blez	a2,80004d8a <filewrite+0xf0>
    int i = 0;
    80004cd8:	4981                	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    80004cda:	6b85                	lui	s7,0x1
    80004cdc:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004ce0:	6c05                	lui	s8,0x1
    80004ce2:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004ce6:	a851                	j	80004d7a <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004ce8:	6908                	ld	a0,16(a0)
    80004cea:	00000097          	auipc	ra,0x0
    80004cee:	22a080e7          	jalr	554(ra) # 80004f14 <pipewrite>
    80004cf2:	a045                	j	80004d92 <filewrite+0xf8>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004cf4:	02451783          	lh	a5,36(a0)
    80004cf8:	03079693          	slli	a3,a5,0x30
    80004cfc:	92c1                	srli	a3,a3,0x30
    80004cfe:	4725                	li	a4,9
    80004d00:	0ad76f63          	bltu	a4,a3,80004dbe <filewrite+0x124>
    80004d04:	0792                	slli	a5,a5,0x4
    80004d06:	0003c717          	auipc	a4,0x3c
    80004d0a:	05270713          	addi	a4,a4,82 # 80040d58 <devsw>
    80004d0e:	97ba                	add	a5,a5,a4
    80004d10:	679c                	ld	a5,8(a5)
    80004d12:	cbc5                	beqz	a5,80004dc2 <filewrite+0x128>
    ret = devsw[f->major].write(1, addr, n);
    80004d14:	4505                	li	a0,1
    80004d16:	9782                	jalr	a5
    80004d18:	a8ad                	j	80004d92 <filewrite+0xf8>
      if(n1 > max)
    80004d1a:	00048a9b          	sext.w	s5,s1
        n1 = max;

      begin_op();
    80004d1e:	00000097          	auipc	ra,0x0
    80004d22:	8bc080e7          	jalr	-1860(ra) # 800045da <begin_op>
      ilock(f->ip);
    80004d26:	01893503          	ld	a0,24(s2)
    80004d2a:	fffff097          	auipc	ra,0xfffff
    80004d2e:	f0a080e7          	jalr	-246(ra) # 80003c34 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004d32:	8756                	mv	a4,s5
    80004d34:	02092683          	lw	a3,32(s2)
    80004d38:	01698633          	add	a2,s3,s6
    80004d3c:	4585                	li	a1,1
    80004d3e:	01893503          	ld	a0,24(s2)
    80004d42:	fffff097          	auipc	ra,0xfffff
    80004d46:	29e080e7          	jalr	670(ra) # 80003fe0 <writei>
    80004d4a:	84aa                	mv	s1,a0
    80004d4c:	00a05763          	blez	a0,80004d5a <filewrite+0xc0>
        f->off += r;
    80004d50:	02092783          	lw	a5,32(s2)
    80004d54:	9fa9                	addw	a5,a5,a0
    80004d56:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004d5a:	01893503          	ld	a0,24(s2)
    80004d5e:	fffff097          	auipc	ra,0xfffff
    80004d62:	f98080e7          	jalr	-104(ra) # 80003cf6 <iunlock>
      end_op();
    80004d66:	00000097          	auipc	ra,0x0
    80004d6a:	8ee080e7          	jalr	-1810(ra) # 80004654 <end_op>

      if(r != n1){
    80004d6e:	009a9f63          	bne	s5,s1,80004d8c <filewrite+0xf2>
        // error from writei
        break;
      }
      i += r;
    80004d72:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004d76:	0149db63          	bge	s3,s4,80004d8c <filewrite+0xf2>
      int n1 = n - i;
    80004d7a:	413a04bb          	subw	s1,s4,s3
      if(n1 > max)
    80004d7e:	0004879b          	sext.w	a5,s1
    80004d82:	f8fbdce3          	bge	s7,a5,80004d1a <filewrite+0x80>
    80004d86:	84e2                	mv	s1,s8
    80004d88:	bf49                	j	80004d1a <filewrite+0x80>
    int i = 0;
    80004d8a:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004d8c:	033a1d63          	bne	s4,s3,80004dc6 <filewrite+0x12c>
    80004d90:	8552                	mv	a0,s4
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004d92:	60a6                	ld	ra,72(sp)
    80004d94:	6406                	ld	s0,64(sp)
    80004d96:	74e2                	ld	s1,56(sp)
    80004d98:	7942                	ld	s2,48(sp)
    80004d9a:	79a2                	ld	s3,40(sp)
    80004d9c:	7a02                	ld	s4,32(sp)
    80004d9e:	6ae2                	ld	s5,24(sp)
    80004da0:	6b42                	ld	s6,16(sp)
    80004da2:	6ba2                	ld	s7,8(sp)
    80004da4:	6c02                	ld	s8,0(sp)
    80004da6:	6161                	addi	sp,sp,80
    80004da8:	8082                	ret
    panic("filewrite");
    80004daa:	00004517          	auipc	a0,0x4
    80004dae:	a7650513          	addi	a0,a0,-1418 # 80008820 <syscalls+0x290>
    80004db2:	ffffb097          	auipc	ra,0xffffb
    80004db6:	78a080e7          	jalr	1930(ra) # 8000053c <panic>
    return -1;
    80004dba:	557d                	li	a0,-1
}
    80004dbc:	8082                	ret
      return -1;
    80004dbe:	557d                	li	a0,-1
    80004dc0:	bfc9                	j	80004d92 <filewrite+0xf8>
    80004dc2:	557d                	li	a0,-1
    80004dc4:	b7f9                	j	80004d92 <filewrite+0xf8>
    ret = (i == n ? n : -1);
    80004dc6:	557d                	li	a0,-1
    80004dc8:	b7e9                	j	80004d92 <filewrite+0xf8>

0000000080004dca <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004dca:	7179                	addi	sp,sp,-48
    80004dcc:	f406                	sd	ra,40(sp)
    80004dce:	f022                	sd	s0,32(sp)
    80004dd0:	ec26                	sd	s1,24(sp)
    80004dd2:	e84a                	sd	s2,16(sp)
    80004dd4:	e44e                	sd	s3,8(sp)
    80004dd6:	e052                	sd	s4,0(sp)
    80004dd8:	1800                	addi	s0,sp,48
    80004dda:	84aa                	mv	s1,a0
    80004ddc:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004dde:	0005b023          	sd	zero,0(a1)
    80004de2:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004de6:	00000097          	auipc	ra,0x0
    80004dea:	bfc080e7          	jalr	-1028(ra) # 800049e2 <filealloc>
    80004dee:	e088                	sd	a0,0(s1)
    80004df0:	c551                	beqz	a0,80004e7c <pipealloc+0xb2>
    80004df2:	00000097          	auipc	ra,0x0
    80004df6:	bf0080e7          	jalr	-1040(ra) # 800049e2 <filealloc>
    80004dfa:	00aa3023          	sd	a0,0(s4)
    80004dfe:	c92d                	beqz	a0,80004e70 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004e00:	ffffc097          	auipc	ra,0xffffc
    80004e04:	d90080e7          	jalr	-624(ra) # 80000b90 <kalloc>
    80004e08:	892a                	mv	s2,a0
    80004e0a:	c125                	beqz	a0,80004e6a <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004e0c:	4985                	li	s3,1
    80004e0e:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004e12:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004e16:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004e1a:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004e1e:	00004597          	auipc	a1,0x4
    80004e22:	a1258593          	addi	a1,a1,-1518 # 80008830 <syscalls+0x2a0>
    80004e26:	ffffc097          	auipc	ra,0xffffc
    80004e2a:	e64080e7          	jalr	-412(ra) # 80000c8a <initlock>
  (*f0)->type = FD_PIPE;
    80004e2e:	609c                	ld	a5,0(s1)
    80004e30:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004e34:	609c                	ld	a5,0(s1)
    80004e36:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004e3a:	609c                	ld	a5,0(s1)
    80004e3c:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004e40:	609c                	ld	a5,0(s1)
    80004e42:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004e46:	000a3783          	ld	a5,0(s4)
    80004e4a:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004e4e:	000a3783          	ld	a5,0(s4)
    80004e52:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004e56:	000a3783          	ld	a5,0(s4)
    80004e5a:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004e5e:	000a3783          	ld	a5,0(s4)
    80004e62:	0127b823          	sd	s2,16(a5)
  return 0;
    80004e66:	4501                	li	a0,0
    80004e68:	a025                	j	80004e90 <pipealloc+0xc6>
 bad:
  if(pi){
    //kfree((char*)pi);
    decrement_reference_counter((char*)pi);
  }
  if(*f0)
    80004e6a:	6088                	ld	a0,0(s1)
    80004e6c:	e501                	bnez	a0,80004e74 <pipealloc+0xaa>
    80004e6e:	a039                	j	80004e7c <pipealloc+0xb2>
    80004e70:	6088                	ld	a0,0(s1)
    80004e72:	c51d                	beqz	a0,80004ea0 <pipealloc+0xd6>
    fileclose(*f0);
    80004e74:	00000097          	auipc	ra,0x0
    80004e78:	c2a080e7          	jalr	-982(ra) # 80004a9e <fileclose>
  if(*f1)
    80004e7c:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004e80:	557d                	li	a0,-1
  if(*f1)
    80004e82:	c799                	beqz	a5,80004e90 <pipealloc+0xc6>
    fileclose(*f1);
    80004e84:	853e                	mv	a0,a5
    80004e86:	00000097          	auipc	ra,0x0
    80004e8a:	c18080e7          	jalr	-1000(ra) # 80004a9e <fileclose>
  return -1;
    80004e8e:	557d                	li	a0,-1
}
    80004e90:	70a2                	ld	ra,40(sp)
    80004e92:	7402                	ld	s0,32(sp)
    80004e94:	64e2                	ld	s1,24(sp)
    80004e96:	6942                	ld	s2,16(sp)
    80004e98:	69a2                	ld	s3,8(sp)
    80004e9a:	6a02                	ld	s4,0(sp)
    80004e9c:	6145                	addi	sp,sp,48
    80004e9e:	8082                	ret
  return -1;
    80004ea0:	557d                	li	a0,-1
    80004ea2:	b7fd                	j	80004e90 <pipealloc+0xc6>

0000000080004ea4 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004ea4:	1101                	addi	sp,sp,-32
    80004ea6:	ec06                	sd	ra,24(sp)
    80004ea8:	e822                	sd	s0,16(sp)
    80004eaa:	e426                	sd	s1,8(sp)
    80004eac:	e04a                	sd	s2,0(sp)
    80004eae:	1000                	addi	s0,sp,32
    80004eb0:	84aa                	mv	s1,a0
    80004eb2:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004eb4:	ffffc097          	auipc	ra,0xffffc
    80004eb8:	e66080e7          	jalr	-410(ra) # 80000d1a <acquire>
  if(writable){
    80004ebc:	02090d63          	beqz	s2,80004ef6 <pipeclose+0x52>
    pi->writeopen = 0;
    80004ec0:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004ec4:	21848513          	addi	a0,s1,536
    80004ec8:	ffffd097          	auipc	ra,0xffffd
    80004ecc:	4f0080e7          	jalr	1264(ra) # 800023b8 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004ed0:	2204b783          	ld	a5,544(s1)
    80004ed4:	eb95                	bnez	a5,80004f08 <pipeclose+0x64>
    release(&pi->lock);
    80004ed6:	8526                	mv	a0,s1
    80004ed8:	ffffc097          	auipc	ra,0xffffc
    80004edc:	ef6080e7          	jalr	-266(ra) # 80000dce <release>
    //kfree((char*)pi);
    decrement_reference_counter((char*)pi);
    80004ee0:	8526                	mv	a0,s1
    80004ee2:	ffffc097          	auipc	ra,0xffffc
    80004ee6:	d64080e7          	jalr	-668(ra) # 80000c46 <decrement_reference_counter>
  } else
    release(&pi->lock);
}
    80004eea:	60e2                	ld	ra,24(sp)
    80004eec:	6442                	ld	s0,16(sp)
    80004eee:	64a2                	ld	s1,8(sp)
    80004ef0:	6902                	ld	s2,0(sp)
    80004ef2:	6105                	addi	sp,sp,32
    80004ef4:	8082                	ret
    pi->readopen = 0;
    80004ef6:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004efa:	21c48513          	addi	a0,s1,540
    80004efe:	ffffd097          	auipc	ra,0xffffd
    80004f02:	4ba080e7          	jalr	1210(ra) # 800023b8 <wakeup>
    80004f06:	b7e9                	j	80004ed0 <pipeclose+0x2c>
    release(&pi->lock);
    80004f08:	8526                	mv	a0,s1
    80004f0a:	ffffc097          	auipc	ra,0xffffc
    80004f0e:	ec4080e7          	jalr	-316(ra) # 80000dce <release>
}
    80004f12:	bfe1                	j	80004eea <pipeclose+0x46>

0000000080004f14 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004f14:	711d                	addi	sp,sp,-96
    80004f16:	ec86                	sd	ra,88(sp)
    80004f18:	e8a2                	sd	s0,80(sp)
    80004f1a:	e4a6                	sd	s1,72(sp)
    80004f1c:	e0ca                	sd	s2,64(sp)
    80004f1e:	fc4e                	sd	s3,56(sp)
    80004f20:	f852                	sd	s4,48(sp)
    80004f22:	f456                	sd	s5,40(sp)
    80004f24:	f05a                	sd	s6,32(sp)
    80004f26:	ec5e                	sd	s7,24(sp)
    80004f28:	e862                	sd	s8,16(sp)
    80004f2a:	1080                	addi	s0,sp,96
    80004f2c:	84aa                	mv	s1,a0
    80004f2e:	8aae                	mv	s5,a1
    80004f30:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004f32:	ffffd097          	auipc	ra,0xffffd
    80004f36:	cba080e7          	jalr	-838(ra) # 80001bec <myproc>
    80004f3a:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004f3c:	8526                	mv	a0,s1
    80004f3e:	ffffc097          	auipc	ra,0xffffc
    80004f42:	ddc080e7          	jalr	-548(ra) # 80000d1a <acquire>
  while(i < n){
    80004f46:	0b405663          	blez	s4,80004ff2 <pipewrite+0xde>
  int i = 0;
    80004f4a:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004f4c:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004f4e:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004f52:	21c48b93          	addi	s7,s1,540
    80004f56:	a089                	j	80004f98 <pipewrite+0x84>
      release(&pi->lock);
    80004f58:	8526                	mv	a0,s1
    80004f5a:	ffffc097          	auipc	ra,0xffffc
    80004f5e:	e74080e7          	jalr	-396(ra) # 80000dce <release>
      return -1;
    80004f62:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004f64:	854a                	mv	a0,s2
    80004f66:	60e6                	ld	ra,88(sp)
    80004f68:	6446                	ld	s0,80(sp)
    80004f6a:	64a6                	ld	s1,72(sp)
    80004f6c:	6906                	ld	s2,64(sp)
    80004f6e:	79e2                	ld	s3,56(sp)
    80004f70:	7a42                	ld	s4,48(sp)
    80004f72:	7aa2                	ld	s5,40(sp)
    80004f74:	7b02                	ld	s6,32(sp)
    80004f76:	6be2                	ld	s7,24(sp)
    80004f78:	6c42                	ld	s8,16(sp)
    80004f7a:	6125                	addi	sp,sp,96
    80004f7c:	8082                	ret
      wakeup(&pi->nread);
    80004f7e:	8562                	mv	a0,s8
    80004f80:	ffffd097          	auipc	ra,0xffffd
    80004f84:	438080e7          	jalr	1080(ra) # 800023b8 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004f88:	85a6                	mv	a1,s1
    80004f8a:	855e                	mv	a0,s7
    80004f8c:	ffffd097          	auipc	ra,0xffffd
    80004f90:	3c8080e7          	jalr	968(ra) # 80002354 <sleep>
  while(i < n){
    80004f94:	07495063          	bge	s2,s4,80004ff4 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004f98:	2204a783          	lw	a5,544(s1)
    80004f9c:	dfd5                	beqz	a5,80004f58 <pipewrite+0x44>
    80004f9e:	854e                	mv	a0,s3
    80004fa0:	ffffd097          	auipc	ra,0xffffd
    80004fa4:	65c080e7          	jalr	1628(ra) # 800025fc <killed>
    80004fa8:	f945                	bnez	a0,80004f58 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004faa:	2184a783          	lw	a5,536(s1)
    80004fae:	21c4a703          	lw	a4,540(s1)
    80004fb2:	2007879b          	addiw	a5,a5,512
    80004fb6:	fcf704e3          	beq	a4,a5,80004f7e <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004fba:	4685                	li	a3,1
    80004fbc:	01590633          	add	a2,s2,s5
    80004fc0:	faf40593          	addi	a1,s0,-81
    80004fc4:	0509b503          	ld	a0,80(s3)
    80004fc8:	ffffd097          	auipc	ra,0xffffd
    80004fcc:	87c080e7          	jalr	-1924(ra) # 80001844 <copyin>
    80004fd0:	03650263          	beq	a0,s6,80004ff4 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004fd4:	21c4a783          	lw	a5,540(s1)
    80004fd8:	0017871b          	addiw	a4,a5,1
    80004fdc:	20e4ae23          	sw	a4,540(s1)
    80004fe0:	1ff7f793          	andi	a5,a5,511
    80004fe4:	97a6                	add	a5,a5,s1
    80004fe6:	faf44703          	lbu	a4,-81(s0)
    80004fea:	00e78c23          	sb	a4,24(a5)
      i++;
    80004fee:	2905                	addiw	s2,s2,1
    80004ff0:	b755                	j	80004f94 <pipewrite+0x80>
  int i = 0;
    80004ff2:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004ff4:	21848513          	addi	a0,s1,536
    80004ff8:	ffffd097          	auipc	ra,0xffffd
    80004ffc:	3c0080e7          	jalr	960(ra) # 800023b8 <wakeup>
  release(&pi->lock);
    80005000:	8526                	mv	a0,s1
    80005002:	ffffc097          	auipc	ra,0xffffc
    80005006:	dcc080e7          	jalr	-564(ra) # 80000dce <release>
  return i;
    8000500a:	bfa9                	j	80004f64 <pipewrite+0x50>

000000008000500c <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    8000500c:	715d                	addi	sp,sp,-80
    8000500e:	e486                	sd	ra,72(sp)
    80005010:	e0a2                	sd	s0,64(sp)
    80005012:	fc26                	sd	s1,56(sp)
    80005014:	f84a                	sd	s2,48(sp)
    80005016:	f44e                	sd	s3,40(sp)
    80005018:	f052                	sd	s4,32(sp)
    8000501a:	ec56                	sd	s5,24(sp)
    8000501c:	e85a                	sd	s6,16(sp)
    8000501e:	0880                	addi	s0,sp,80
    80005020:	84aa                	mv	s1,a0
    80005022:	892e                	mv	s2,a1
    80005024:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005026:	ffffd097          	auipc	ra,0xffffd
    8000502a:	bc6080e7          	jalr	-1082(ra) # 80001bec <myproc>
    8000502e:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005030:	8526                	mv	a0,s1
    80005032:	ffffc097          	auipc	ra,0xffffc
    80005036:	ce8080e7          	jalr	-792(ra) # 80000d1a <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000503a:	2184a703          	lw	a4,536(s1)
    8000503e:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005042:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005046:	02f71763          	bne	a4,a5,80005074 <piperead+0x68>
    8000504a:	2244a783          	lw	a5,548(s1)
    8000504e:	c39d                	beqz	a5,80005074 <piperead+0x68>
    if(killed(pr)){
    80005050:	8552                	mv	a0,s4
    80005052:	ffffd097          	auipc	ra,0xffffd
    80005056:	5aa080e7          	jalr	1450(ra) # 800025fc <killed>
    8000505a:	e949                	bnez	a0,800050ec <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000505c:	85a6                	mv	a1,s1
    8000505e:	854e                	mv	a0,s3
    80005060:	ffffd097          	auipc	ra,0xffffd
    80005064:	2f4080e7          	jalr	756(ra) # 80002354 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005068:	2184a703          	lw	a4,536(s1)
    8000506c:	21c4a783          	lw	a5,540(s1)
    80005070:	fcf70de3          	beq	a4,a5,8000504a <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005074:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005076:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005078:	05505463          	blez	s5,800050c0 <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    8000507c:	2184a783          	lw	a5,536(s1)
    80005080:	21c4a703          	lw	a4,540(s1)
    80005084:	02f70e63          	beq	a4,a5,800050c0 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005088:	0017871b          	addiw	a4,a5,1
    8000508c:	20e4ac23          	sw	a4,536(s1)
    80005090:	1ff7f793          	andi	a5,a5,511
    80005094:	97a6                	add	a5,a5,s1
    80005096:	0187c783          	lbu	a5,24(a5)
    8000509a:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000509e:	4685                	li	a3,1
    800050a0:	fbf40613          	addi	a2,s0,-65
    800050a4:	85ca                	mv	a1,s2
    800050a6:	050a3503          	ld	a0,80(s4)
    800050aa:	ffffc097          	auipc	ra,0xffffc
    800050ae:	70e080e7          	jalr	1806(ra) # 800017b8 <copyout>
    800050b2:	01650763          	beq	a0,s6,800050c0 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800050b6:	2985                	addiw	s3,s3,1
    800050b8:	0905                	addi	s2,s2,1
    800050ba:	fd3a91e3          	bne	s5,s3,8000507c <piperead+0x70>
    800050be:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800050c0:	21c48513          	addi	a0,s1,540
    800050c4:	ffffd097          	auipc	ra,0xffffd
    800050c8:	2f4080e7          	jalr	756(ra) # 800023b8 <wakeup>
  release(&pi->lock);
    800050cc:	8526                	mv	a0,s1
    800050ce:	ffffc097          	auipc	ra,0xffffc
    800050d2:	d00080e7          	jalr	-768(ra) # 80000dce <release>
  return i;
}
    800050d6:	854e                	mv	a0,s3
    800050d8:	60a6                	ld	ra,72(sp)
    800050da:	6406                	ld	s0,64(sp)
    800050dc:	74e2                	ld	s1,56(sp)
    800050de:	7942                	ld	s2,48(sp)
    800050e0:	79a2                	ld	s3,40(sp)
    800050e2:	7a02                	ld	s4,32(sp)
    800050e4:	6ae2                	ld	s5,24(sp)
    800050e6:	6b42                	ld	s6,16(sp)
    800050e8:	6161                	addi	sp,sp,80
    800050ea:	8082                	ret
      release(&pi->lock);
    800050ec:	8526                	mv	a0,s1
    800050ee:	ffffc097          	auipc	ra,0xffffc
    800050f2:	ce0080e7          	jalr	-800(ra) # 80000dce <release>
      return -1;
    800050f6:	59fd                	li	s3,-1
    800050f8:	bff9                	j	800050d6 <piperead+0xca>

00000000800050fa <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    800050fa:	1141                	addi	sp,sp,-16
    800050fc:	e422                	sd	s0,8(sp)
    800050fe:	0800                	addi	s0,sp,16
    80005100:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80005102:	8905                	andi	a0,a0,1
    80005104:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80005106:	8b89                	andi	a5,a5,2
    80005108:	c399                	beqz	a5,8000510e <flags2perm+0x14>
      perm |= PTE_W;
    8000510a:	00456513          	ori	a0,a0,4
    return perm;
}
    8000510e:	6422                	ld	s0,8(sp)
    80005110:	0141                	addi	sp,sp,16
    80005112:	8082                	ret

0000000080005114 <exec>:

int
exec(char *path, char **argv)
{
    80005114:	df010113          	addi	sp,sp,-528
    80005118:	20113423          	sd	ra,520(sp)
    8000511c:	20813023          	sd	s0,512(sp)
    80005120:	ffa6                	sd	s1,504(sp)
    80005122:	fbca                	sd	s2,496(sp)
    80005124:	f7ce                	sd	s3,488(sp)
    80005126:	f3d2                	sd	s4,480(sp)
    80005128:	efd6                	sd	s5,472(sp)
    8000512a:	ebda                	sd	s6,464(sp)
    8000512c:	e7de                	sd	s7,456(sp)
    8000512e:	e3e2                	sd	s8,448(sp)
    80005130:	ff66                	sd	s9,440(sp)
    80005132:	fb6a                	sd	s10,432(sp)
    80005134:	f76e                	sd	s11,424(sp)
    80005136:	0c00                	addi	s0,sp,528
    80005138:	892a                	mv	s2,a0
    8000513a:	dea43c23          	sd	a0,-520(s0)
    8000513e:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005142:	ffffd097          	auipc	ra,0xffffd
    80005146:	aaa080e7          	jalr	-1366(ra) # 80001bec <myproc>
    8000514a:	84aa                	mv	s1,a0

  begin_op();
    8000514c:	fffff097          	auipc	ra,0xfffff
    80005150:	48e080e7          	jalr	1166(ra) # 800045da <begin_op>

  if((ip = namei(path)) == 0){
    80005154:	854a                	mv	a0,s2
    80005156:	fffff097          	auipc	ra,0xfffff
    8000515a:	284080e7          	jalr	644(ra) # 800043da <namei>
    8000515e:	c92d                	beqz	a0,800051d0 <exec+0xbc>
    80005160:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005162:	fffff097          	auipc	ra,0xfffff
    80005166:	ad2080e7          	jalr	-1326(ra) # 80003c34 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    8000516a:	04000713          	li	a4,64
    8000516e:	4681                	li	a3,0
    80005170:	e5040613          	addi	a2,s0,-432
    80005174:	4581                	li	a1,0
    80005176:	8552                	mv	a0,s4
    80005178:	fffff097          	auipc	ra,0xfffff
    8000517c:	d70080e7          	jalr	-656(ra) # 80003ee8 <readi>
    80005180:	04000793          	li	a5,64
    80005184:	00f51a63          	bne	a0,a5,80005198 <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80005188:	e5042703          	lw	a4,-432(s0)
    8000518c:	464c47b7          	lui	a5,0x464c4
    80005190:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005194:	04f70463          	beq	a4,a5,800051dc <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005198:	8552                	mv	a0,s4
    8000519a:	fffff097          	auipc	ra,0xfffff
    8000519e:	cfc080e7          	jalr	-772(ra) # 80003e96 <iunlockput>
    end_op();
    800051a2:	fffff097          	auipc	ra,0xfffff
    800051a6:	4b2080e7          	jalr	1202(ra) # 80004654 <end_op>
  }
  return -1;
    800051aa:	557d                	li	a0,-1
}
    800051ac:	20813083          	ld	ra,520(sp)
    800051b0:	20013403          	ld	s0,512(sp)
    800051b4:	74fe                	ld	s1,504(sp)
    800051b6:	795e                	ld	s2,496(sp)
    800051b8:	79be                	ld	s3,488(sp)
    800051ba:	7a1e                	ld	s4,480(sp)
    800051bc:	6afe                	ld	s5,472(sp)
    800051be:	6b5e                	ld	s6,464(sp)
    800051c0:	6bbe                	ld	s7,456(sp)
    800051c2:	6c1e                	ld	s8,448(sp)
    800051c4:	7cfa                	ld	s9,440(sp)
    800051c6:	7d5a                	ld	s10,432(sp)
    800051c8:	7dba                	ld	s11,424(sp)
    800051ca:	21010113          	addi	sp,sp,528
    800051ce:	8082                	ret
    end_op();
    800051d0:	fffff097          	auipc	ra,0xfffff
    800051d4:	484080e7          	jalr	1156(ra) # 80004654 <end_op>
    return -1;
    800051d8:	557d                	li	a0,-1
    800051da:	bfc9                	j	800051ac <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    800051dc:	8526                	mv	a0,s1
    800051de:	ffffd097          	auipc	ra,0xffffd
    800051e2:	ad2080e7          	jalr	-1326(ra) # 80001cb0 <proc_pagetable>
    800051e6:	8b2a                	mv	s6,a0
    800051e8:	d945                	beqz	a0,80005198 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800051ea:	e7042d03          	lw	s10,-400(s0)
    800051ee:	e8845783          	lhu	a5,-376(s0)
    800051f2:	10078463          	beqz	a5,800052fa <exec+0x1e6>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800051f6:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800051f8:	4d81                	li	s11,0
    if(ph.vaddr % PGSIZE != 0)
    800051fa:	6c85                	lui	s9,0x1
    800051fc:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80005200:	def43823          	sd	a5,-528(s0)

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    80005204:	6a85                	lui	s5,0x1
    80005206:	a0b5                	j	80005272 <exec+0x15e>
      panic("loadseg: address should exist");
    80005208:	00003517          	auipc	a0,0x3
    8000520c:	63050513          	addi	a0,a0,1584 # 80008838 <syscalls+0x2a8>
    80005210:	ffffb097          	auipc	ra,0xffffb
    80005214:	32c080e7          	jalr	812(ra) # 8000053c <panic>
    if(sz - i < PGSIZE)
    80005218:	2481                	sext.w	s1,s1
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    8000521a:	8726                	mv	a4,s1
    8000521c:	012c06bb          	addw	a3,s8,s2
    80005220:	4581                	li	a1,0
    80005222:	8552                	mv	a0,s4
    80005224:	fffff097          	auipc	ra,0xfffff
    80005228:	cc4080e7          	jalr	-828(ra) # 80003ee8 <readi>
    8000522c:	2501                	sext.w	a0,a0
    8000522e:	24a49863          	bne	s1,a0,8000547e <exec+0x36a>
  for(i = 0; i < sz; i += PGSIZE){
    80005232:	012a893b          	addw	s2,s5,s2
    80005236:	03397563          	bgeu	s2,s3,80005260 <exec+0x14c>
    pa = walkaddr(pagetable, va + i);
    8000523a:	02091593          	slli	a1,s2,0x20
    8000523e:	9181                	srli	a1,a1,0x20
    80005240:	95de                	add	a1,a1,s7
    80005242:	855a                	mv	a0,s6
    80005244:	ffffc097          	auipc	ra,0xffffc
    80005248:	f5a080e7          	jalr	-166(ra) # 8000119e <walkaddr>
    8000524c:	862a                	mv	a2,a0
    if(pa == 0)
    8000524e:	dd4d                	beqz	a0,80005208 <exec+0xf4>
    if(sz - i < PGSIZE)
    80005250:	412984bb          	subw	s1,s3,s2
    80005254:	0004879b          	sext.w	a5,s1
    80005258:	fcfcf0e3          	bgeu	s9,a5,80005218 <exec+0x104>
    8000525c:	84d6                	mv	s1,s5
    8000525e:	bf6d                	j	80005218 <exec+0x104>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005260:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005264:	2d85                	addiw	s11,s11,1
    80005266:	038d0d1b          	addiw	s10,s10,56
    8000526a:	e8845783          	lhu	a5,-376(s0)
    8000526e:	08fdd763          	bge	s11,a5,800052fc <exec+0x1e8>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005272:	2d01                	sext.w	s10,s10
    80005274:	03800713          	li	a4,56
    80005278:	86ea                	mv	a3,s10
    8000527a:	e1840613          	addi	a2,s0,-488
    8000527e:	4581                	li	a1,0
    80005280:	8552                	mv	a0,s4
    80005282:	fffff097          	auipc	ra,0xfffff
    80005286:	c66080e7          	jalr	-922(ra) # 80003ee8 <readi>
    8000528a:	03800793          	li	a5,56
    8000528e:	1ef51663          	bne	a0,a5,8000547a <exec+0x366>
    if(ph.type != ELF_PROG_LOAD)
    80005292:	e1842783          	lw	a5,-488(s0)
    80005296:	4705                	li	a4,1
    80005298:	fce796e3          	bne	a5,a4,80005264 <exec+0x150>
    if(ph.memsz < ph.filesz)
    8000529c:	e4043483          	ld	s1,-448(s0)
    800052a0:	e3843783          	ld	a5,-456(s0)
    800052a4:	1ef4e863          	bltu	s1,a5,80005494 <exec+0x380>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800052a8:	e2843783          	ld	a5,-472(s0)
    800052ac:	94be                	add	s1,s1,a5
    800052ae:	1ef4e663          	bltu	s1,a5,8000549a <exec+0x386>
    if(ph.vaddr % PGSIZE != 0)
    800052b2:	df043703          	ld	a4,-528(s0)
    800052b6:	8ff9                	and	a5,a5,a4
    800052b8:	1e079463          	bnez	a5,800054a0 <exec+0x38c>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800052bc:	e1c42503          	lw	a0,-484(s0)
    800052c0:	00000097          	auipc	ra,0x0
    800052c4:	e3a080e7          	jalr	-454(ra) # 800050fa <flags2perm>
    800052c8:	86aa                	mv	a3,a0
    800052ca:	8626                	mv	a2,s1
    800052cc:	85ca                	mv	a1,s2
    800052ce:	855a                	mv	a0,s6
    800052d0:	ffffc097          	auipc	ra,0xffffc
    800052d4:	282080e7          	jalr	642(ra) # 80001552 <uvmalloc>
    800052d8:	e0a43423          	sd	a0,-504(s0)
    800052dc:	1c050563          	beqz	a0,800054a6 <exec+0x392>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800052e0:	e2843b83          	ld	s7,-472(s0)
    800052e4:	e2042c03          	lw	s8,-480(s0)
    800052e8:	e3842983          	lw	s3,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800052ec:	00098463          	beqz	s3,800052f4 <exec+0x1e0>
    800052f0:	4901                	li	s2,0
    800052f2:	b7a1                	j	8000523a <exec+0x126>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800052f4:	e0843903          	ld	s2,-504(s0)
    800052f8:	b7b5                	j	80005264 <exec+0x150>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800052fa:	4901                	li	s2,0
  iunlockput(ip);
    800052fc:	8552                	mv	a0,s4
    800052fe:	fffff097          	auipc	ra,0xfffff
    80005302:	b98080e7          	jalr	-1128(ra) # 80003e96 <iunlockput>
  end_op();
    80005306:	fffff097          	auipc	ra,0xfffff
    8000530a:	34e080e7          	jalr	846(ra) # 80004654 <end_op>
  p = myproc();
    8000530e:	ffffd097          	auipc	ra,0xffffd
    80005312:	8de080e7          	jalr	-1826(ra) # 80001bec <myproc>
    80005316:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005318:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    8000531c:	6985                	lui	s3,0x1
    8000531e:	19fd                	addi	s3,s3,-1 # fff <_entry-0x7ffff001>
    80005320:	99ca                	add	s3,s3,s2
    80005322:	77fd                	lui	a5,0xfffff
    80005324:	00f9f9b3          	and	s3,s3,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005328:	4691                	li	a3,4
    8000532a:	6609                	lui	a2,0x2
    8000532c:	964e                	add	a2,a2,s3
    8000532e:	85ce                	mv	a1,s3
    80005330:	855a                	mv	a0,s6
    80005332:	ffffc097          	auipc	ra,0xffffc
    80005336:	220080e7          	jalr	544(ra) # 80001552 <uvmalloc>
    8000533a:	892a                	mv	s2,a0
    8000533c:	e0a43423          	sd	a0,-504(s0)
    80005340:	e509                	bnez	a0,8000534a <exec+0x236>
  if(pagetable)
    80005342:	e1343423          	sd	s3,-504(s0)
    80005346:	4a01                	li	s4,0
    80005348:	aa1d                	j	8000547e <exec+0x36a>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000534a:	75f9                	lui	a1,0xffffe
    8000534c:	95aa                	add	a1,a1,a0
    8000534e:	855a                	mv	a0,s6
    80005350:	ffffc097          	auipc	ra,0xffffc
    80005354:	436080e7          	jalr	1078(ra) # 80001786 <uvmclear>
  stackbase = sp - PGSIZE;
    80005358:	7bfd                	lui	s7,0xfffff
    8000535a:	9bca                	add	s7,s7,s2
  for(argc = 0; argv[argc]; argc++) {
    8000535c:	e0043783          	ld	a5,-512(s0)
    80005360:	6388                	ld	a0,0(a5)
    80005362:	c52d                	beqz	a0,800053cc <exec+0x2b8>
    80005364:	e9040993          	addi	s3,s0,-368
    80005368:	f9040c13          	addi	s8,s0,-112
    8000536c:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    8000536e:	ffffc097          	auipc	ra,0xffffc
    80005372:	c22080e7          	jalr	-990(ra) # 80000f90 <strlen>
    80005376:	0015079b          	addiw	a5,a0,1
    8000537a:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000537e:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80005382:	13796563          	bltu	s2,s7,800054ac <exec+0x398>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005386:	e0043d03          	ld	s10,-512(s0)
    8000538a:	000d3a03          	ld	s4,0(s10)
    8000538e:	8552                	mv	a0,s4
    80005390:	ffffc097          	auipc	ra,0xffffc
    80005394:	c00080e7          	jalr	-1024(ra) # 80000f90 <strlen>
    80005398:	0015069b          	addiw	a3,a0,1
    8000539c:	8652                	mv	a2,s4
    8000539e:	85ca                	mv	a1,s2
    800053a0:	855a                	mv	a0,s6
    800053a2:	ffffc097          	auipc	ra,0xffffc
    800053a6:	416080e7          	jalr	1046(ra) # 800017b8 <copyout>
    800053aa:	10054363          	bltz	a0,800054b0 <exec+0x39c>
    ustack[argc] = sp;
    800053ae:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800053b2:	0485                	addi	s1,s1,1
    800053b4:	008d0793          	addi	a5,s10,8
    800053b8:	e0f43023          	sd	a5,-512(s0)
    800053bc:	008d3503          	ld	a0,8(s10)
    800053c0:	c909                	beqz	a0,800053d2 <exec+0x2be>
    if(argc >= MAXARG)
    800053c2:	09a1                	addi	s3,s3,8
    800053c4:	fb8995e3          	bne	s3,s8,8000536e <exec+0x25a>
  ip = 0;
    800053c8:	4a01                	li	s4,0
    800053ca:	a855                	j	8000547e <exec+0x36a>
  sp = sz;
    800053cc:	e0843903          	ld	s2,-504(s0)
  for(argc = 0; argv[argc]; argc++) {
    800053d0:	4481                	li	s1,0
  ustack[argc] = 0;
    800053d2:	00349793          	slli	a5,s1,0x3
    800053d6:	f9078793          	addi	a5,a5,-112 # ffffffffffffef90 <end+0xffffffff7ffbd0a0>
    800053da:	97a2                	add	a5,a5,s0
    800053dc:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    800053e0:	00148693          	addi	a3,s1,1
    800053e4:	068e                	slli	a3,a3,0x3
    800053e6:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800053ea:	ff097913          	andi	s2,s2,-16
  sz = sz1;
    800053ee:	e0843983          	ld	s3,-504(s0)
  if(sp < stackbase)
    800053f2:	f57968e3          	bltu	s2,s7,80005342 <exec+0x22e>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800053f6:	e9040613          	addi	a2,s0,-368
    800053fa:	85ca                	mv	a1,s2
    800053fc:	855a                	mv	a0,s6
    800053fe:	ffffc097          	auipc	ra,0xffffc
    80005402:	3ba080e7          	jalr	954(ra) # 800017b8 <copyout>
    80005406:	0a054763          	bltz	a0,800054b4 <exec+0x3a0>
  p->trapframe->a1 = sp;
    8000540a:	058ab783          	ld	a5,88(s5) # 1058 <_entry-0x7fffefa8>
    8000540e:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005412:	df843783          	ld	a5,-520(s0)
    80005416:	0007c703          	lbu	a4,0(a5)
    8000541a:	cf11                	beqz	a4,80005436 <exec+0x322>
    8000541c:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000541e:	02f00693          	li	a3,47
    80005422:	a039                	j	80005430 <exec+0x31c>
      last = s+1;
    80005424:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005428:	0785                	addi	a5,a5,1
    8000542a:	fff7c703          	lbu	a4,-1(a5)
    8000542e:	c701                	beqz	a4,80005436 <exec+0x322>
    if(*s == '/')
    80005430:	fed71ce3          	bne	a4,a3,80005428 <exec+0x314>
    80005434:	bfc5                	j	80005424 <exec+0x310>
  safestrcpy(p->name, last, sizeof(p->name));
    80005436:	4641                	li	a2,16
    80005438:	df843583          	ld	a1,-520(s0)
    8000543c:	158a8513          	addi	a0,s5,344
    80005440:	ffffc097          	auipc	ra,0xffffc
    80005444:	b1e080e7          	jalr	-1250(ra) # 80000f5e <safestrcpy>
  oldpagetable = p->pagetable;
    80005448:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    8000544c:	056ab823          	sd	s6,80(s5)
  p->sz = sz;
    80005450:	e0843783          	ld	a5,-504(s0)
    80005454:	04fab423          	sd	a5,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005458:	058ab783          	ld	a5,88(s5)
    8000545c:	e6843703          	ld	a4,-408(s0)
    80005460:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005462:	058ab783          	ld	a5,88(s5)
    80005466:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000546a:	85e6                	mv	a1,s9
    8000546c:	ffffd097          	auipc	ra,0xffffd
    80005470:	8e0080e7          	jalr	-1824(ra) # 80001d4c <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005474:	0004851b          	sext.w	a0,s1
    80005478:	bb15                	j	800051ac <exec+0x98>
    8000547a:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    8000547e:	e0843583          	ld	a1,-504(s0)
    80005482:	855a                	mv	a0,s6
    80005484:	ffffd097          	auipc	ra,0xffffd
    80005488:	8c8080e7          	jalr	-1848(ra) # 80001d4c <proc_freepagetable>
  return -1;
    8000548c:	557d                	li	a0,-1
  if(ip){
    8000548e:	d00a0fe3          	beqz	s4,800051ac <exec+0x98>
    80005492:	b319                	j	80005198 <exec+0x84>
    80005494:	e1243423          	sd	s2,-504(s0)
    80005498:	b7dd                	j	8000547e <exec+0x36a>
    8000549a:	e1243423          	sd	s2,-504(s0)
    8000549e:	b7c5                	j	8000547e <exec+0x36a>
    800054a0:	e1243423          	sd	s2,-504(s0)
    800054a4:	bfe9                	j	8000547e <exec+0x36a>
    800054a6:	e1243423          	sd	s2,-504(s0)
    800054aa:	bfd1                	j	8000547e <exec+0x36a>
  ip = 0;
    800054ac:	4a01                	li	s4,0
    800054ae:	bfc1                	j	8000547e <exec+0x36a>
    800054b0:	4a01                	li	s4,0
  if(pagetable)
    800054b2:	b7f1                	j	8000547e <exec+0x36a>
  sz = sz1;
    800054b4:	e0843983          	ld	s3,-504(s0)
    800054b8:	b569                	j	80005342 <exec+0x22e>

00000000800054ba <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800054ba:	7179                	addi	sp,sp,-48
    800054bc:	f406                	sd	ra,40(sp)
    800054be:	f022                	sd	s0,32(sp)
    800054c0:	ec26                	sd	s1,24(sp)
    800054c2:	e84a                	sd	s2,16(sp)
    800054c4:	1800                	addi	s0,sp,48
    800054c6:	892e                	mv	s2,a1
    800054c8:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    800054ca:	fdc40593          	addi	a1,s0,-36
    800054ce:	ffffe097          	auipc	ra,0xffffe
    800054d2:	b06080e7          	jalr	-1274(ra) # 80002fd4 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800054d6:	fdc42703          	lw	a4,-36(s0)
    800054da:	47bd                	li	a5,15
    800054dc:	02e7eb63          	bltu	a5,a4,80005512 <argfd+0x58>
    800054e0:	ffffc097          	auipc	ra,0xffffc
    800054e4:	70c080e7          	jalr	1804(ra) # 80001bec <myproc>
    800054e8:	fdc42703          	lw	a4,-36(s0)
    800054ec:	01a70793          	addi	a5,a4,26
    800054f0:	078e                	slli	a5,a5,0x3
    800054f2:	953e                	add	a0,a0,a5
    800054f4:	611c                	ld	a5,0(a0)
    800054f6:	c385                	beqz	a5,80005516 <argfd+0x5c>
    return -1;
  if(pfd)
    800054f8:	00090463          	beqz	s2,80005500 <argfd+0x46>
    *pfd = fd;
    800054fc:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005500:	4501                	li	a0,0
  if(pf)
    80005502:	c091                	beqz	s1,80005506 <argfd+0x4c>
    *pf = f;
    80005504:	e09c                	sd	a5,0(s1)
}
    80005506:	70a2                	ld	ra,40(sp)
    80005508:	7402                	ld	s0,32(sp)
    8000550a:	64e2                	ld	s1,24(sp)
    8000550c:	6942                	ld	s2,16(sp)
    8000550e:	6145                	addi	sp,sp,48
    80005510:	8082                	ret
    return -1;
    80005512:	557d                	li	a0,-1
    80005514:	bfcd                	j	80005506 <argfd+0x4c>
    80005516:	557d                	li	a0,-1
    80005518:	b7fd                	j	80005506 <argfd+0x4c>

000000008000551a <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000551a:	1101                	addi	sp,sp,-32
    8000551c:	ec06                	sd	ra,24(sp)
    8000551e:	e822                	sd	s0,16(sp)
    80005520:	e426                	sd	s1,8(sp)
    80005522:	1000                	addi	s0,sp,32
    80005524:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005526:	ffffc097          	auipc	ra,0xffffc
    8000552a:	6c6080e7          	jalr	1734(ra) # 80001bec <myproc>
    8000552e:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005530:	0d050793          	addi	a5,a0,208
    80005534:	4501                	li	a0,0
    80005536:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005538:	6398                	ld	a4,0(a5)
    8000553a:	cb19                	beqz	a4,80005550 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000553c:	2505                	addiw	a0,a0,1
    8000553e:	07a1                	addi	a5,a5,8
    80005540:	fed51ce3          	bne	a0,a3,80005538 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005544:	557d                	li	a0,-1
}
    80005546:	60e2                	ld	ra,24(sp)
    80005548:	6442                	ld	s0,16(sp)
    8000554a:	64a2                	ld	s1,8(sp)
    8000554c:	6105                	addi	sp,sp,32
    8000554e:	8082                	ret
      p->ofile[fd] = f;
    80005550:	01a50793          	addi	a5,a0,26
    80005554:	078e                	slli	a5,a5,0x3
    80005556:	963e                	add	a2,a2,a5
    80005558:	e204                	sd	s1,0(a2)
      return fd;
    8000555a:	b7f5                	j	80005546 <fdalloc+0x2c>

000000008000555c <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000555c:	715d                	addi	sp,sp,-80
    8000555e:	e486                	sd	ra,72(sp)
    80005560:	e0a2                	sd	s0,64(sp)
    80005562:	fc26                	sd	s1,56(sp)
    80005564:	f84a                	sd	s2,48(sp)
    80005566:	f44e                	sd	s3,40(sp)
    80005568:	f052                	sd	s4,32(sp)
    8000556a:	ec56                	sd	s5,24(sp)
    8000556c:	e85a                	sd	s6,16(sp)
    8000556e:	0880                	addi	s0,sp,80
    80005570:	8b2e                	mv	s6,a1
    80005572:	89b2                	mv	s3,a2
    80005574:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005576:	fb040593          	addi	a1,s0,-80
    8000557a:	fffff097          	auipc	ra,0xfffff
    8000557e:	e7e080e7          	jalr	-386(ra) # 800043f8 <nameiparent>
    80005582:	84aa                	mv	s1,a0
    80005584:	14050b63          	beqz	a0,800056da <create+0x17e>
    return 0;

  ilock(dp);
    80005588:	ffffe097          	auipc	ra,0xffffe
    8000558c:	6ac080e7          	jalr	1708(ra) # 80003c34 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005590:	4601                	li	a2,0
    80005592:	fb040593          	addi	a1,s0,-80
    80005596:	8526                	mv	a0,s1
    80005598:	fffff097          	auipc	ra,0xfffff
    8000559c:	b80080e7          	jalr	-1152(ra) # 80004118 <dirlookup>
    800055a0:	8aaa                	mv	s5,a0
    800055a2:	c921                	beqz	a0,800055f2 <create+0x96>
    iunlockput(dp);
    800055a4:	8526                	mv	a0,s1
    800055a6:	fffff097          	auipc	ra,0xfffff
    800055aa:	8f0080e7          	jalr	-1808(ra) # 80003e96 <iunlockput>
    ilock(ip);
    800055ae:	8556                	mv	a0,s5
    800055b0:	ffffe097          	auipc	ra,0xffffe
    800055b4:	684080e7          	jalr	1668(ra) # 80003c34 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800055b8:	4789                	li	a5,2
    800055ba:	02fb1563          	bne	s6,a5,800055e4 <create+0x88>
    800055be:	044ad783          	lhu	a5,68(s5)
    800055c2:	37f9                	addiw	a5,a5,-2
    800055c4:	17c2                	slli	a5,a5,0x30
    800055c6:	93c1                	srli	a5,a5,0x30
    800055c8:	4705                	li	a4,1
    800055ca:	00f76d63          	bltu	a4,a5,800055e4 <create+0x88>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    800055ce:	8556                	mv	a0,s5
    800055d0:	60a6                	ld	ra,72(sp)
    800055d2:	6406                	ld	s0,64(sp)
    800055d4:	74e2                	ld	s1,56(sp)
    800055d6:	7942                	ld	s2,48(sp)
    800055d8:	79a2                	ld	s3,40(sp)
    800055da:	7a02                	ld	s4,32(sp)
    800055dc:	6ae2                	ld	s5,24(sp)
    800055de:	6b42                	ld	s6,16(sp)
    800055e0:	6161                	addi	sp,sp,80
    800055e2:	8082                	ret
    iunlockput(ip);
    800055e4:	8556                	mv	a0,s5
    800055e6:	fffff097          	auipc	ra,0xfffff
    800055ea:	8b0080e7          	jalr	-1872(ra) # 80003e96 <iunlockput>
    return 0;
    800055ee:	4a81                	li	s5,0
    800055f0:	bff9                	j	800055ce <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0){
    800055f2:	85da                	mv	a1,s6
    800055f4:	4088                	lw	a0,0(s1)
    800055f6:	ffffe097          	auipc	ra,0xffffe
    800055fa:	4a6080e7          	jalr	1190(ra) # 80003a9c <ialloc>
    800055fe:	8a2a                	mv	s4,a0
    80005600:	c529                	beqz	a0,8000564a <create+0xee>
  ilock(ip);
    80005602:	ffffe097          	auipc	ra,0xffffe
    80005606:	632080e7          	jalr	1586(ra) # 80003c34 <ilock>
  ip->major = major;
    8000560a:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    8000560e:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005612:	4905                	li	s2,1
    80005614:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005618:	8552                	mv	a0,s4
    8000561a:	ffffe097          	auipc	ra,0xffffe
    8000561e:	54e080e7          	jalr	1358(ra) # 80003b68 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005622:	032b0b63          	beq	s6,s2,80005658 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80005626:	004a2603          	lw	a2,4(s4)
    8000562a:	fb040593          	addi	a1,s0,-80
    8000562e:	8526                	mv	a0,s1
    80005630:	fffff097          	auipc	ra,0xfffff
    80005634:	cf8080e7          	jalr	-776(ra) # 80004328 <dirlink>
    80005638:	06054f63          	bltz	a0,800056b6 <create+0x15a>
  iunlockput(dp);
    8000563c:	8526                	mv	a0,s1
    8000563e:	fffff097          	auipc	ra,0xfffff
    80005642:	858080e7          	jalr	-1960(ra) # 80003e96 <iunlockput>
  return ip;
    80005646:	8ad2                	mv	s5,s4
    80005648:	b759                	j	800055ce <create+0x72>
    iunlockput(dp);
    8000564a:	8526                	mv	a0,s1
    8000564c:	fffff097          	auipc	ra,0xfffff
    80005650:	84a080e7          	jalr	-1974(ra) # 80003e96 <iunlockput>
    return 0;
    80005654:	8ad2                	mv	s5,s4
    80005656:	bfa5                	j	800055ce <create+0x72>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005658:	004a2603          	lw	a2,4(s4)
    8000565c:	00003597          	auipc	a1,0x3
    80005660:	1fc58593          	addi	a1,a1,508 # 80008858 <syscalls+0x2c8>
    80005664:	8552                	mv	a0,s4
    80005666:	fffff097          	auipc	ra,0xfffff
    8000566a:	cc2080e7          	jalr	-830(ra) # 80004328 <dirlink>
    8000566e:	04054463          	bltz	a0,800056b6 <create+0x15a>
    80005672:	40d0                	lw	a2,4(s1)
    80005674:	00003597          	auipc	a1,0x3
    80005678:	1ec58593          	addi	a1,a1,492 # 80008860 <syscalls+0x2d0>
    8000567c:	8552                	mv	a0,s4
    8000567e:	fffff097          	auipc	ra,0xfffff
    80005682:	caa080e7          	jalr	-854(ra) # 80004328 <dirlink>
    80005686:	02054863          	bltz	a0,800056b6 <create+0x15a>
  if(dirlink(dp, name, ip->inum) < 0)
    8000568a:	004a2603          	lw	a2,4(s4)
    8000568e:	fb040593          	addi	a1,s0,-80
    80005692:	8526                	mv	a0,s1
    80005694:	fffff097          	auipc	ra,0xfffff
    80005698:	c94080e7          	jalr	-876(ra) # 80004328 <dirlink>
    8000569c:	00054d63          	bltz	a0,800056b6 <create+0x15a>
    dp->nlink++;  // for ".."
    800056a0:	04a4d783          	lhu	a5,74(s1)
    800056a4:	2785                	addiw	a5,a5,1
    800056a6:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800056aa:	8526                	mv	a0,s1
    800056ac:	ffffe097          	auipc	ra,0xffffe
    800056b0:	4bc080e7          	jalr	1212(ra) # 80003b68 <iupdate>
    800056b4:	b761                	j	8000563c <create+0xe0>
  ip->nlink = 0;
    800056b6:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800056ba:	8552                	mv	a0,s4
    800056bc:	ffffe097          	auipc	ra,0xffffe
    800056c0:	4ac080e7          	jalr	1196(ra) # 80003b68 <iupdate>
  iunlockput(ip);
    800056c4:	8552                	mv	a0,s4
    800056c6:	ffffe097          	auipc	ra,0xffffe
    800056ca:	7d0080e7          	jalr	2000(ra) # 80003e96 <iunlockput>
  iunlockput(dp);
    800056ce:	8526                	mv	a0,s1
    800056d0:	ffffe097          	auipc	ra,0xffffe
    800056d4:	7c6080e7          	jalr	1990(ra) # 80003e96 <iunlockput>
  return 0;
    800056d8:	bddd                	j	800055ce <create+0x72>
    return 0;
    800056da:	8aaa                	mv	s5,a0
    800056dc:	bdcd                	j	800055ce <create+0x72>

00000000800056de <sys_dup>:
{
    800056de:	7179                	addi	sp,sp,-48
    800056e0:	f406                	sd	ra,40(sp)
    800056e2:	f022                	sd	s0,32(sp)
    800056e4:	ec26                	sd	s1,24(sp)
    800056e6:	e84a                	sd	s2,16(sp)
    800056e8:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800056ea:	fd840613          	addi	a2,s0,-40
    800056ee:	4581                	li	a1,0
    800056f0:	4501                	li	a0,0
    800056f2:	00000097          	auipc	ra,0x0
    800056f6:	dc8080e7          	jalr	-568(ra) # 800054ba <argfd>
    return -1;
    800056fa:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800056fc:	02054363          	bltz	a0,80005722 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    80005700:	fd843903          	ld	s2,-40(s0)
    80005704:	854a                	mv	a0,s2
    80005706:	00000097          	auipc	ra,0x0
    8000570a:	e14080e7          	jalr	-492(ra) # 8000551a <fdalloc>
    8000570e:	84aa                	mv	s1,a0
    return -1;
    80005710:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005712:	00054863          	bltz	a0,80005722 <sys_dup+0x44>
  filedup(f);
    80005716:	854a                	mv	a0,s2
    80005718:	fffff097          	auipc	ra,0xfffff
    8000571c:	334080e7          	jalr	820(ra) # 80004a4c <filedup>
  return fd;
    80005720:	87a6                	mv	a5,s1
}
    80005722:	853e                	mv	a0,a5
    80005724:	70a2                	ld	ra,40(sp)
    80005726:	7402                	ld	s0,32(sp)
    80005728:	64e2                	ld	s1,24(sp)
    8000572a:	6942                	ld	s2,16(sp)
    8000572c:	6145                	addi	sp,sp,48
    8000572e:	8082                	ret

0000000080005730 <sys_read>:
{
    80005730:	7179                	addi	sp,sp,-48
    80005732:	f406                	sd	ra,40(sp)
    80005734:	f022                	sd	s0,32(sp)
    80005736:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005738:	fd840593          	addi	a1,s0,-40
    8000573c:	4505                	li	a0,1
    8000573e:	ffffe097          	auipc	ra,0xffffe
    80005742:	8b6080e7          	jalr	-1866(ra) # 80002ff4 <argaddr>
  argint(2, &n);
    80005746:	fe440593          	addi	a1,s0,-28
    8000574a:	4509                	li	a0,2
    8000574c:	ffffe097          	auipc	ra,0xffffe
    80005750:	888080e7          	jalr	-1912(ra) # 80002fd4 <argint>
  if(argfd(0, 0, &f) < 0)
    80005754:	fe840613          	addi	a2,s0,-24
    80005758:	4581                	li	a1,0
    8000575a:	4501                	li	a0,0
    8000575c:	00000097          	auipc	ra,0x0
    80005760:	d5e080e7          	jalr	-674(ra) # 800054ba <argfd>
    80005764:	87aa                	mv	a5,a0
    return -1;
    80005766:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005768:	0007cc63          	bltz	a5,80005780 <sys_read+0x50>
  return fileread(f, p, n);
    8000576c:	fe442603          	lw	a2,-28(s0)
    80005770:	fd843583          	ld	a1,-40(s0)
    80005774:	fe843503          	ld	a0,-24(s0)
    80005778:	fffff097          	auipc	ra,0xfffff
    8000577c:	460080e7          	jalr	1120(ra) # 80004bd8 <fileread>
}
    80005780:	70a2                	ld	ra,40(sp)
    80005782:	7402                	ld	s0,32(sp)
    80005784:	6145                	addi	sp,sp,48
    80005786:	8082                	ret

0000000080005788 <sys_write>:
{
    80005788:	7179                	addi	sp,sp,-48
    8000578a:	f406                	sd	ra,40(sp)
    8000578c:	f022                	sd	s0,32(sp)
    8000578e:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005790:	fd840593          	addi	a1,s0,-40
    80005794:	4505                	li	a0,1
    80005796:	ffffe097          	auipc	ra,0xffffe
    8000579a:	85e080e7          	jalr	-1954(ra) # 80002ff4 <argaddr>
  argint(2, &n);
    8000579e:	fe440593          	addi	a1,s0,-28
    800057a2:	4509                	li	a0,2
    800057a4:	ffffe097          	auipc	ra,0xffffe
    800057a8:	830080e7          	jalr	-2000(ra) # 80002fd4 <argint>
  if(argfd(0, 0, &f) < 0)
    800057ac:	fe840613          	addi	a2,s0,-24
    800057b0:	4581                	li	a1,0
    800057b2:	4501                	li	a0,0
    800057b4:	00000097          	auipc	ra,0x0
    800057b8:	d06080e7          	jalr	-762(ra) # 800054ba <argfd>
    800057bc:	87aa                	mv	a5,a0
    return -1;
    800057be:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800057c0:	0007cc63          	bltz	a5,800057d8 <sys_write+0x50>
  return filewrite(f, p, n);
    800057c4:	fe442603          	lw	a2,-28(s0)
    800057c8:	fd843583          	ld	a1,-40(s0)
    800057cc:	fe843503          	ld	a0,-24(s0)
    800057d0:	fffff097          	auipc	ra,0xfffff
    800057d4:	4ca080e7          	jalr	1226(ra) # 80004c9a <filewrite>
}
    800057d8:	70a2                	ld	ra,40(sp)
    800057da:	7402                	ld	s0,32(sp)
    800057dc:	6145                	addi	sp,sp,48
    800057de:	8082                	ret

00000000800057e0 <sys_close>:
{
    800057e0:	1101                	addi	sp,sp,-32
    800057e2:	ec06                	sd	ra,24(sp)
    800057e4:	e822                	sd	s0,16(sp)
    800057e6:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800057e8:	fe040613          	addi	a2,s0,-32
    800057ec:	fec40593          	addi	a1,s0,-20
    800057f0:	4501                	li	a0,0
    800057f2:	00000097          	auipc	ra,0x0
    800057f6:	cc8080e7          	jalr	-824(ra) # 800054ba <argfd>
    return -1;
    800057fa:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800057fc:	02054463          	bltz	a0,80005824 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005800:	ffffc097          	auipc	ra,0xffffc
    80005804:	3ec080e7          	jalr	1004(ra) # 80001bec <myproc>
    80005808:	fec42783          	lw	a5,-20(s0)
    8000580c:	07e9                	addi	a5,a5,26
    8000580e:	078e                	slli	a5,a5,0x3
    80005810:	953e                	add	a0,a0,a5
    80005812:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80005816:	fe043503          	ld	a0,-32(s0)
    8000581a:	fffff097          	auipc	ra,0xfffff
    8000581e:	284080e7          	jalr	644(ra) # 80004a9e <fileclose>
  return 0;
    80005822:	4781                	li	a5,0
}
    80005824:	853e                	mv	a0,a5
    80005826:	60e2                	ld	ra,24(sp)
    80005828:	6442                	ld	s0,16(sp)
    8000582a:	6105                	addi	sp,sp,32
    8000582c:	8082                	ret

000000008000582e <sys_fstat>:
{
    8000582e:	1101                	addi	sp,sp,-32
    80005830:	ec06                	sd	ra,24(sp)
    80005832:	e822                	sd	s0,16(sp)
    80005834:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005836:	fe040593          	addi	a1,s0,-32
    8000583a:	4505                	li	a0,1
    8000583c:	ffffd097          	auipc	ra,0xffffd
    80005840:	7b8080e7          	jalr	1976(ra) # 80002ff4 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005844:	fe840613          	addi	a2,s0,-24
    80005848:	4581                	li	a1,0
    8000584a:	4501                	li	a0,0
    8000584c:	00000097          	auipc	ra,0x0
    80005850:	c6e080e7          	jalr	-914(ra) # 800054ba <argfd>
    80005854:	87aa                	mv	a5,a0
    return -1;
    80005856:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005858:	0007ca63          	bltz	a5,8000586c <sys_fstat+0x3e>
  return filestat(f, st);
    8000585c:	fe043583          	ld	a1,-32(s0)
    80005860:	fe843503          	ld	a0,-24(s0)
    80005864:	fffff097          	auipc	ra,0xfffff
    80005868:	302080e7          	jalr	770(ra) # 80004b66 <filestat>
}
    8000586c:	60e2                	ld	ra,24(sp)
    8000586e:	6442                	ld	s0,16(sp)
    80005870:	6105                	addi	sp,sp,32
    80005872:	8082                	ret

0000000080005874 <sys_link>:
{
    80005874:	7169                	addi	sp,sp,-304
    80005876:	f606                	sd	ra,296(sp)
    80005878:	f222                	sd	s0,288(sp)
    8000587a:	ee26                	sd	s1,280(sp)
    8000587c:	ea4a                	sd	s2,272(sp)
    8000587e:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005880:	08000613          	li	a2,128
    80005884:	ed040593          	addi	a1,s0,-304
    80005888:	4501                	li	a0,0
    8000588a:	ffffd097          	auipc	ra,0xffffd
    8000588e:	78a080e7          	jalr	1930(ra) # 80003014 <argstr>
    return -1;
    80005892:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005894:	10054e63          	bltz	a0,800059b0 <sys_link+0x13c>
    80005898:	08000613          	li	a2,128
    8000589c:	f5040593          	addi	a1,s0,-176
    800058a0:	4505                	li	a0,1
    800058a2:	ffffd097          	auipc	ra,0xffffd
    800058a6:	772080e7          	jalr	1906(ra) # 80003014 <argstr>
    return -1;
    800058aa:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800058ac:	10054263          	bltz	a0,800059b0 <sys_link+0x13c>
  begin_op();
    800058b0:	fffff097          	auipc	ra,0xfffff
    800058b4:	d2a080e7          	jalr	-726(ra) # 800045da <begin_op>
  if((ip = namei(old)) == 0){
    800058b8:	ed040513          	addi	a0,s0,-304
    800058bc:	fffff097          	auipc	ra,0xfffff
    800058c0:	b1e080e7          	jalr	-1250(ra) # 800043da <namei>
    800058c4:	84aa                	mv	s1,a0
    800058c6:	c551                	beqz	a0,80005952 <sys_link+0xde>
  ilock(ip);
    800058c8:	ffffe097          	auipc	ra,0xffffe
    800058cc:	36c080e7          	jalr	876(ra) # 80003c34 <ilock>
  if(ip->type == T_DIR){
    800058d0:	04449703          	lh	a4,68(s1)
    800058d4:	4785                	li	a5,1
    800058d6:	08f70463          	beq	a4,a5,8000595e <sys_link+0xea>
  ip->nlink++;
    800058da:	04a4d783          	lhu	a5,74(s1)
    800058de:	2785                	addiw	a5,a5,1
    800058e0:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800058e4:	8526                	mv	a0,s1
    800058e6:	ffffe097          	auipc	ra,0xffffe
    800058ea:	282080e7          	jalr	642(ra) # 80003b68 <iupdate>
  iunlock(ip);
    800058ee:	8526                	mv	a0,s1
    800058f0:	ffffe097          	auipc	ra,0xffffe
    800058f4:	406080e7          	jalr	1030(ra) # 80003cf6 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800058f8:	fd040593          	addi	a1,s0,-48
    800058fc:	f5040513          	addi	a0,s0,-176
    80005900:	fffff097          	auipc	ra,0xfffff
    80005904:	af8080e7          	jalr	-1288(ra) # 800043f8 <nameiparent>
    80005908:	892a                	mv	s2,a0
    8000590a:	c935                	beqz	a0,8000597e <sys_link+0x10a>
  ilock(dp);
    8000590c:	ffffe097          	auipc	ra,0xffffe
    80005910:	328080e7          	jalr	808(ra) # 80003c34 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005914:	00092703          	lw	a4,0(s2)
    80005918:	409c                	lw	a5,0(s1)
    8000591a:	04f71d63          	bne	a4,a5,80005974 <sys_link+0x100>
    8000591e:	40d0                	lw	a2,4(s1)
    80005920:	fd040593          	addi	a1,s0,-48
    80005924:	854a                	mv	a0,s2
    80005926:	fffff097          	auipc	ra,0xfffff
    8000592a:	a02080e7          	jalr	-1534(ra) # 80004328 <dirlink>
    8000592e:	04054363          	bltz	a0,80005974 <sys_link+0x100>
  iunlockput(dp);
    80005932:	854a                	mv	a0,s2
    80005934:	ffffe097          	auipc	ra,0xffffe
    80005938:	562080e7          	jalr	1378(ra) # 80003e96 <iunlockput>
  iput(ip);
    8000593c:	8526                	mv	a0,s1
    8000593e:	ffffe097          	auipc	ra,0xffffe
    80005942:	4b0080e7          	jalr	1200(ra) # 80003dee <iput>
  end_op();
    80005946:	fffff097          	auipc	ra,0xfffff
    8000594a:	d0e080e7          	jalr	-754(ra) # 80004654 <end_op>
  return 0;
    8000594e:	4781                	li	a5,0
    80005950:	a085                	j	800059b0 <sys_link+0x13c>
    end_op();
    80005952:	fffff097          	auipc	ra,0xfffff
    80005956:	d02080e7          	jalr	-766(ra) # 80004654 <end_op>
    return -1;
    8000595a:	57fd                	li	a5,-1
    8000595c:	a891                	j	800059b0 <sys_link+0x13c>
    iunlockput(ip);
    8000595e:	8526                	mv	a0,s1
    80005960:	ffffe097          	auipc	ra,0xffffe
    80005964:	536080e7          	jalr	1334(ra) # 80003e96 <iunlockput>
    end_op();
    80005968:	fffff097          	auipc	ra,0xfffff
    8000596c:	cec080e7          	jalr	-788(ra) # 80004654 <end_op>
    return -1;
    80005970:	57fd                	li	a5,-1
    80005972:	a83d                	j	800059b0 <sys_link+0x13c>
    iunlockput(dp);
    80005974:	854a                	mv	a0,s2
    80005976:	ffffe097          	auipc	ra,0xffffe
    8000597a:	520080e7          	jalr	1312(ra) # 80003e96 <iunlockput>
  ilock(ip);
    8000597e:	8526                	mv	a0,s1
    80005980:	ffffe097          	auipc	ra,0xffffe
    80005984:	2b4080e7          	jalr	692(ra) # 80003c34 <ilock>
  ip->nlink--;
    80005988:	04a4d783          	lhu	a5,74(s1)
    8000598c:	37fd                	addiw	a5,a5,-1
    8000598e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005992:	8526                	mv	a0,s1
    80005994:	ffffe097          	auipc	ra,0xffffe
    80005998:	1d4080e7          	jalr	468(ra) # 80003b68 <iupdate>
  iunlockput(ip);
    8000599c:	8526                	mv	a0,s1
    8000599e:	ffffe097          	auipc	ra,0xffffe
    800059a2:	4f8080e7          	jalr	1272(ra) # 80003e96 <iunlockput>
  end_op();
    800059a6:	fffff097          	auipc	ra,0xfffff
    800059aa:	cae080e7          	jalr	-850(ra) # 80004654 <end_op>
  return -1;
    800059ae:	57fd                	li	a5,-1
}
    800059b0:	853e                	mv	a0,a5
    800059b2:	70b2                	ld	ra,296(sp)
    800059b4:	7412                	ld	s0,288(sp)
    800059b6:	64f2                	ld	s1,280(sp)
    800059b8:	6952                	ld	s2,272(sp)
    800059ba:	6155                	addi	sp,sp,304
    800059bc:	8082                	ret

00000000800059be <sys_unlink>:
{
    800059be:	7151                	addi	sp,sp,-240
    800059c0:	f586                	sd	ra,232(sp)
    800059c2:	f1a2                	sd	s0,224(sp)
    800059c4:	eda6                	sd	s1,216(sp)
    800059c6:	e9ca                	sd	s2,208(sp)
    800059c8:	e5ce                	sd	s3,200(sp)
    800059ca:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800059cc:	08000613          	li	a2,128
    800059d0:	f3040593          	addi	a1,s0,-208
    800059d4:	4501                	li	a0,0
    800059d6:	ffffd097          	auipc	ra,0xffffd
    800059da:	63e080e7          	jalr	1598(ra) # 80003014 <argstr>
    800059de:	18054163          	bltz	a0,80005b60 <sys_unlink+0x1a2>
  begin_op();
    800059e2:	fffff097          	auipc	ra,0xfffff
    800059e6:	bf8080e7          	jalr	-1032(ra) # 800045da <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800059ea:	fb040593          	addi	a1,s0,-80
    800059ee:	f3040513          	addi	a0,s0,-208
    800059f2:	fffff097          	auipc	ra,0xfffff
    800059f6:	a06080e7          	jalr	-1530(ra) # 800043f8 <nameiparent>
    800059fa:	84aa                	mv	s1,a0
    800059fc:	c979                	beqz	a0,80005ad2 <sys_unlink+0x114>
  ilock(dp);
    800059fe:	ffffe097          	auipc	ra,0xffffe
    80005a02:	236080e7          	jalr	566(ra) # 80003c34 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005a06:	00003597          	auipc	a1,0x3
    80005a0a:	e5258593          	addi	a1,a1,-430 # 80008858 <syscalls+0x2c8>
    80005a0e:	fb040513          	addi	a0,s0,-80
    80005a12:	ffffe097          	auipc	ra,0xffffe
    80005a16:	6ec080e7          	jalr	1772(ra) # 800040fe <namecmp>
    80005a1a:	14050a63          	beqz	a0,80005b6e <sys_unlink+0x1b0>
    80005a1e:	00003597          	auipc	a1,0x3
    80005a22:	e4258593          	addi	a1,a1,-446 # 80008860 <syscalls+0x2d0>
    80005a26:	fb040513          	addi	a0,s0,-80
    80005a2a:	ffffe097          	auipc	ra,0xffffe
    80005a2e:	6d4080e7          	jalr	1748(ra) # 800040fe <namecmp>
    80005a32:	12050e63          	beqz	a0,80005b6e <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005a36:	f2c40613          	addi	a2,s0,-212
    80005a3a:	fb040593          	addi	a1,s0,-80
    80005a3e:	8526                	mv	a0,s1
    80005a40:	ffffe097          	auipc	ra,0xffffe
    80005a44:	6d8080e7          	jalr	1752(ra) # 80004118 <dirlookup>
    80005a48:	892a                	mv	s2,a0
    80005a4a:	12050263          	beqz	a0,80005b6e <sys_unlink+0x1b0>
  ilock(ip);
    80005a4e:	ffffe097          	auipc	ra,0xffffe
    80005a52:	1e6080e7          	jalr	486(ra) # 80003c34 <ilock>
  if(ip->nlink < 1)
    80005a56:	04a91783          	lh	a5,74(s2)
    80005a5a:	08f05263          	blez	a5,80005ade <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005a5e:	04491703          	lh	a4,68(s2)
    80005a62:	4785                	li	a5,1
    80005a64:	08f70563          	beq	a4,a5,80005aee <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005a68:	4641                	li	a2,16
    80005a6a:	4581                	li	a1,0
    80005a6c:	fc040513          	addi	a0,s0,-64
    80005a70:	ffffb097          	auipc	ra,0xffffb
    80005a74:	3a6080e7          	jalr	934(ra) # 80000e16 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005a78:	4741                	li	a4,16
    80005a7a:	f2c42683          	lw	a3,-212(s0)
    80005a7e:	fc040613          	addi	a2,s0,-64
    80005a82:	4581                	li	a1,0
    80005a84:	8526                	mv	a0,s1
    80005a86:	ffffe097          	auipc	ra,0xffffe
    80005a8a:	55a080e7          	jalr	1370(ra) # 80003fe0 <writei>
    80005a8e:	47c1                	li	a5,16
    80005a90:	0af51563          	bne	a0,a5,80005b3a <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005a94:	04491703          	lh	a4,68(s2)
    80005a98:	4785                	li	a5,1
    80005a9a:	0af70863          	beq	a4,a5,80005b4a <sys_unlink+0x18c>
  iunlockput(dp);
    80005a9e:	8526                	mv	a0,s1
    80005aa0:	ffffe097          	auipc	ra,0xffffe
    80005aa4:	3f6080e7          	jalr	1014(ra) # 80003e96 <iunlockput>
  ip->nlink--;
    80005aa8:	04a95783          	lhu	a5,74(s2)
    80005aac:	37fd                	addiw	a5,a5,-1
    80005aae:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005ab2:	854a                	mv	a0,s2
    80005ab4:	ffffe097          	auipc	ra,0xffffe
    80005ab8:	0b4080e7          	jalr	180(ra) # 80003b68 <iupdate>
  iunlockput(ip);
    80005abc:	854a                	mv	a0,s2
    80005abe:	ffffe097          	auipc	ra,0xffffe
    80005ac2:	3d8080e7          	jalr	984(ra) # 80003e96 <iunlockput>
  end_op();
    80005ac6:	fffff097          	auipc	ra,0xfffff
    80005aca:	b8e080e7          	jalr	-1138(ra) # 80004654 <end_op>
  return 0;
    80005ace:	4501                	li	a0,0
    80005ad0:	a84d                	j	80005b82 <sys_unlink+0x1c4>
    end_op();
    80005ad2:	fffff097          	auipc	ra,0xfffff
    80005ad6:	b82080e7          	jalr	-1150(ra) # 80004654 <end_op>
    return -1;
    80005ada:	557d                	li	a0,-1
    80005adc:	a05d                	j	80005b82 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005ade:	00003517          	auipc	a0,0x3
    80005ae2:	d8a50513          	addi	a0,a0,-630 # 80008868 <syscalls+0x2d8>
    80005ae6:	ffffb097          	auipc	ra,0xffffb
    80005aea:	a56080e7          	jalr	-1450(ra) # 8000053c <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005aee:	04c92703          	lw	a4,76(s2)
    80005af2:	02000793          	li	a5,32
    80005af6:	f6e7f9e3          	bgeu	a5,a4,80005a68 <sys_unlink+0xaa>
    80005afa:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005afe:	4741                	li	a4,16
    80005b00:	86ce                	mv	a3,s3
    80005b02:	f1840613          	addi	a2,s0,-232
    80005b06:	4581                	li	a1,0
    80005b08:	854a                	mv	a0,s2
    80005b0a:	ffffe097          	auipc	ra,0xffffe
    80005b0e:	3de080e7          	jalr	990(ra) # 80003ee8 <readi>
    80005b12:	47c1                	li	a5,16
    80005b14:	00f51b63          	bne	a0,a5,80005b2a <sys_unlink+0x16c>
    if(de.inum != 0)
    80005b18:	f1845783          	lhu	a5,-232(s0)
    80005b1c:	e7a1                	bnez	a5,80005b64 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005b1e:	29c1                	addiw	s3,s3,16
    80005b20:	04c92783          	lw	a5,76(s2)
    80005b24:	fcf9ede3          	bltu	s3,a5,80005afe <sys_unlink+0x140>
    80005b28:	b781                	j	80005a68 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005b2a:	00003517          	auipc	a0,0x3
    80005b2e:	d5650513          	addi	a0,a0,-682 # 80008880 <syscalls+0x2f0>
    80005b32:	ffffb097          	auipc	ra,0xffffb
    80005b36:	a0a080e7          	jalr	-1526(ra) # 8000053c <panic>
    panic("unlink: writei");
    80005b3a:	00003517          	auipc	a0,0x3
    80005b3e:	d5e50513          	addi	a0,a0,-674 # 80008898 <syscalls+0x308>
    80005b42:	ffffb097          	auipc	ra,0xffffb
    80005b46:	9fa080e7          	jalr	-1542(ra) # 8000053c <panic>
    dp->nlink--;
    80005b4a:	04a4d783          	lhu	a5,74(s1)
    80005b4e:	37fd                	addiw	a5,a5,-1
    80005b50:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005b54:	8526                	mv	a0,s1
    80005b56:	ffffe097          	auipc	ra,0xffffe
    80005b5a:	012080e7          	jalr	18(ra) # 80003b68 <iupdate>
    80005b5e:	b781                	j	80005a9e <sys_unlink+0xe0>
    return -1;
    80005b60:	557d                	li	a0,-1
    80005b62:	a005                	j	80005b82 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005b64:	854a                	mv	a0,s2
    80005b66:	ffffe097          	auipc	ra,0xffffe
    80005b6a:	330080e7          	jalr	816(ra) # 80003e96 <iunlockput>
  iunlockput(dp);
    80005b6e:	8526                	mv	a0,s1
    80005b70:	ffffe097          	auipc	ra,0xffffe
    80005b74:	326080e7          	jalr	806(ra) # 80003e96 <iunlockput>
  end_op();
    80005b78:	fffff097          	auipc	ra,0xfffff
    80005b7c:	adc080e7          	jalr	-1316(ra) # 80004654 <end_op>
  return -1;
    80005b80:	557d                	li	a0,-1
}
    80005b82:	70ae                	ld	ra,232(sp)
    80005b84:	740e                	ld	s0,224(sp)
    80005b86:	64ee                	ld	s1,216(sp)
    80005b88:	694e                	ld	s2,208(sp)
    80005b8a:	69ae                	ld	s3,200(sp)
    80005b8c:	616d                	addi	sp,sp,240
    80005b8e:	8082                	ret

0000000080005b90 <sys_open>:

uint64
sys_open(void)
{
    80005b90:	7131                	addi	sp,sp,-192
    80005b92:	fd06                	sd	ra,184(sp)
    80005b94:	f922                	sd	s0,176(sp)
    80005b96:	f526                	sd	s1,168(sp)
    80005b98:	f14a                	sd	s2,160(sp)
    80005b9a:	ed4e                	sd	s3,152(sp)
    80005b9c:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005b9e:	f4c40593          	addi	a1,s0,-180
    80005ba2:	4505                	li	a0,1
    80005ba4:	ffffd097          	auipc	ra,0xffffd
    80005ba8:	430080e7          	jalr	1072(ra) # 80002fd4 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005bac:	08000613          	li	a2,128
    80005bb0:	f5040593          	addi	a1,s0,-176
    80005bb4:	4501                	li	a0,0
    80005bb6:	ffffd097          	auipc	ra,0xffffd
    80005bba:	45e080e7          	jalr	1118(ra) # 80003014 <argstr>
    80005bbe:	87aa                	mv	a5,a0
    return -1;
    80005bc0:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005bc2:	0a07c863          	bltz	a5,80005c72 <sys_open+0xe2>

  begin_op();
    80005bc6:	fffff097          	auipc	ra,0xfffff
    80005bca:	a14080e7          	jalr	-1516(ra) # 800045da <begin_op>

  if(omode & O_CREATE){
    80005bce:	f4c42783          	lw	a5,-180(s0)
    80005bd2:	2007f793          	andi	a5,a5,512
    80005bd6:	cbdd                	beqz	a5,80005c8c <sys_open+0xfc>
    ip = create(path, T_FILE, 0, 0);
    80005bd8:	4681                	li	a3,0
    80005bda:	4601                	li	a2,0
    80005bdc:	4589                	li	a1,2
    80005bde:	f5040513          	addi	a0,s0,-176
    80005be2:	00000097          	auipc	ra,0x0
    80005be6:	97a080e7          	jalr	-1670(ra) # 8000555c <create>
    80005bea:	84aa                	mv	s1,a0
    if(ip == 0){
    80005bec:	c951                	beqz	a0,80005c80 <sys_open+0xf0>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005bee:	04449703          	lh	a4,68(s1)
    80005bf2:	478d                	li	a5,3
    80005bf4:	00f71763          	bne	a4,a5,80005c02 <sys_open+0x72>
    80005bf8:	0464d703          	lhu	a4,70(s1)
    80005bfc:	47a5                	li	a5,9
    80005bfe:	0ce7ec63          	bltu	a5,a4,80005cd6 <sys_open+0x146>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005c02:	fffff097          	auipc	ra,0xfffff
    80005c06:	de0080e7          	jalr	-544(ra) # 800049e2 <filealloc>
    80005c0a:	892a                	mv	s2,a0
    80005c0c:	c56d                	beqz	a0,80005cf6 <sys_open+0x166>
    80005c0e:	00000097          	auipc	ra,0x0
    80005c12:	90c080e7          	jalr	-1780(ra) # 8000551a <fdalloc>
    80005c16:	89aa                	mv	s3,a0
    80005c18:	0c054a63          	bltz	a0,80005cec <sys_open+0x15c>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005c1c:	04449703          	lh	a4,68(s1)
    80005c20:	478d                	li	a5,3
    80005c22:	0ef70563          	beq	a4,a5,80005d0c <sys_open+0x17c>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005c26:	4789                	li	a5,2
    80005c28:	00f92023          	sw	a5,0(s2)
    f->off = 0;
    80005c2c:	02092023          	sw	zero,32(s2)
  }
  f->ip = ip;
    80005c30:	00993c23          	sd	s1,24(s2)
  f->readable = !(omode & O_WRONLY);
    80005c34:	f4c42783          	lw	a5,-180(s0)
    80005c38:	0017c713          	xori	a4,a5,1
    80005c3c:	8b05                	andi	a4,a4,1
    80005c3e:	00e90423          	sb	a4,8(s2)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005c42:	0037f713          	andi	a4,a5,3
    80005c46:	00e03733          	snez	a4,a4
    80005c4a:	00e904a3          	sb	a4,9(s2)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005c4e:	4007f793          	andi	a5,a5,1024
    80005c52:	c791                	beqz	a5,80005c5e <sys_open+0xce>
    80005c54:	04449703          	lh	a4,68(s1)
    80005c58:	4789                	li	a5,2
    80005c5a:	0cf70063          	beq	a4,a5,80005d1a <sys_open+0x18a>
    itrunc(ip);
  }

  iunlock(ip);
    80005c5e:	8526                	mv	a0,s1
    80005c60:	ffffe097          	auipc	ra,0xffffe
    80005c64:	096080e7          	jalr	150(ra) # 80003cf6 <iunlock>
  end_op();
    80005c68:	fffff097          	auipc	ra,0xfffff
    80005c6c:	9ec080e7          	jalr	-1556(ra) # 80004654 <end_op>

  return fd;
    80005c70:	854e                	mv	a0,s3
}
    80005c72:	70ea                	ld	ra,184(sp)
    80005c74:	744a                	ld	s0,176(sp)
    80005c76:	74aa                	ld	s1,168(sp)
    80005c78:	790a                	ld	s2,160(sp)
    80005c7a:	69ea                	ld	s3,152(sp)
    80005c7c:	6129                	addi	sp,sp,192
    80005c7e:	8082                	ret
      end_op();
    80005c80:	fffff097          	auipc	ra,0xfffff
    80005c84:	9d4080e7          	jalr	-1580(ra) # 80004654 <end_op>
      return -1;
    80005c88:	557d                	li	a0,-1
    80005c8a:	b7e5                	j	80005c72 <sys_open+0xe2>
    if((ip = namei(path)) == 0){
    80005c8c:	f5040513          	addi	a0,s0,-176
    80005c90:	ffffe097          	auipc	ra,0xffffe
    80005c94:	74a080e7          	jalr	1866(ra) # 800043da <namei>
    80005c98:	84aa                	mv	s1,a0
    80005c9a:	c905                	beqz	a0,80005cca <sys_open+0x13a>
    ilock(ip);
    80005c9c:	ffffe097          	auipc	ra,0xffffe
    80005ca0:	f98080e7          	jalr	-104(ra) # 80003c34 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005ca4:	04449703          	lh	a4,68(s1)
    80005ca8:	4785                	li	a5,1
    80005caa:	f4f712e3          	bne	a4,a5,80005bee <sys_open+0x5e>
    80005cae:	f4c42783          	lw	a5,-180(s0)
    80005cb2:	dba1                	beqz	a5,80005c02 <sys_open+0x72>
      iunlockput(ip);
    80005cb4:	8526                	mv	a0,s1
    80005cb6:	ffffe097          	auipc	ra,0xffffe
    80005cba:	1e0080e7          	jalr	480(ra) # 80003e96 <iunlockput>
      end_op();
    80005cbe:	fffff097          	auipc	ra,0xfffff
    80005cc2:	996080e7          	jalr	-1642(ra) # 80004654 <end_op>
      return -1;
    80005cc6:	557d                	li	a0,-1
    80005cc8:	b76d                	j	80005c72 <sys_open+0xe2>
      end_op();
    80005cca:	fffff097          	auipc	ra,0xfffff
    80005cce:	98a080e7          	jalr	-1654(ra) # 80004654 <end_op>
      return -1;
    80005cd2:	557d                	li	a0,-1
    80005cd4:	bf79                	j	80005c72 <sys_open+0xe2>
    iunlockput(ip);
    80005cd6:	8526                	mv	a0,s1
    80005cd8:	ffffe097          	auipc	ra,0xffffe
    80005cdc:	1be080e7          	jalr	446(ra) # 80003e96 <iunlockput>
    end_op();
    80005ce0:	fffff097          	auipc	ra,0xfffff
    80005ce4:	974080e7          	jalr	-1676(ra) # 80004654 <end_op>
    return -1;
    80005ce8:	557d                	li	a0,-1
    80005cea:	b761                	j	80005c72 <sys_open+0xe2>
      fileclose(f);
    80005cec:	854a                	mv	a0,s2
    80005cee:	fffff097          	auipc	ra,0xfffff
    80005cf2:	db0080e7          	jalr	-592(ra) # 80004a9e <fileclose>
    iunlockput(ip);
    80005cf6:	8526                	mv	a0,s1
    80005cf8:	ffffe097          	auipc	ra,0xffffe
    80005cfc:	19e080e7          	jalr	414(ra) # 80003e96 <iunlockput>
    end_op();
    80005d00:	fffff097          	auipc	ra,0xfffff
    80005d04:	954080e7          	jalr	-1708(ra) # 80004654 <end_op>
    return -1;
    80005d08:	557d                	li	a0,-1
    80005d0a:	b7a5                	j	80005c72 <sys_open+0xe2>
    f->type = FD_DEVICE;
    80005d0c:	00f92023          	sw	a5,0(s2)
    f->major = ip->major;
    80005d10:	04649783          	lh	a5,70(s1)
    80005d14:	02f91223          	sh	a5,36(s2)
    80005d18:	bf21                	j	80005c30 <sys_open+0xa0>
    itrunc(ip);
    80005d1a:	8526                	mv	a0,s1
    80005d1c:	ffffe097          	auipc	ra,0xffffe
    80005d20:	026080e7          	jalr	38(ra) # 80003d42 <itrunc>
    80005d24:	bf2d                	j	80005c5e <sys_open+0xce>

0000000080005d26 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005d26:	7175                	addi	sp,sp,-144
    80005d28:	e506                	sd	ra,136(sp)
    80005d2a:	e122                	sd	s0,128(sp)
    80005d2c:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005d2e:	fffff097          	auipc	ra,0xfffff
    80005d32:	8ac080e7          	jalr	-1876(ra) # 800045da <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005d36:	08000613          	li	a2,128
    80005d3a:	f7040593          	addi	a1,s0,-144
    80005d3e:	4501                	li	a0,0
    80005d40:	ffffd097          	auipc	ra,0xffffd
    80005d44:	2d4080e7          	jalr	724(ra) # 80003014 <argstr>
    80005d48:	02054963          	bltz	a0,80005d7a <sys_mkdir+0x54>
    80005d4c:	4681                	li	a3,0
    80005d4e:	4601                	li	a2,0
    80005d50:	4585                	li	a1,1
    80005d52:	f7040513          	addi	a0,s0,-144
    80005d56:	00000097          	auipc	ra,0x0
    80005d5a:	806080e7          	jalr	-2042(ra) # 8000555c <create>
    80005d5e:	cd11                	beqz	a0,80005d7a <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005d60:	ffffe097          	auipc	ra,0xffffe
    80005d64:	136080e7          	jalr	310(ra) # 80003e96 <iunlockput>
  end_op();
    80005d68:	fffff097          	auipc	ra,0xfffff
    80005d6c:	8ec080e7          	jalr	-1812(ra) # 80004654 <end_op>
  return 0;
    80005d70:	4501                	li	a0,0
}
    80005d72:	60aa                	ld	ra,136(sp)
    80005d74:	640a                	ld	s0,128(sp)
    80005d76:	6149                	addi	sp,sp,144
    80005d78:	8082                	ret
    end_op();
    80005d7a:	fffff097          	auipc	ra,0xfffff
    80005d7e:	8da080e7          	jalr	-1830(ra) # 80004654 <end_op>
    return -1;
    80005d82:	557d                	li	a0,-1
    80005d84:	b7fd                	j	80005d72 <sys_mkdir+0x4c>

0000000080005d86 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005d86:	7135                	addi	sp,sp,-160
    80005d88:	ed06                	sd	ra,152(sp)
    80005d8a:	e922                	sd	s0,144(sp)
    80005d8c:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005d8e:	fffff097          	auipc	ra,0xfffff
    80005d92:	84c080e7          	jalr	-1972(ra) # 800045da <begin_op>
  argint(1, &major);
    80005d96:	f6c40593          	addi	a1,s0,-148
    80005d9a:	4505                	li	a0,1
    80005d9c:	ffffd097          	auipc	ra,0xffffd
    80005da0:	238080e7          	jalr	568(ra) # 80002fd4 <argint>
  argint(2, &minor);
    80005da4:	f6840593          	addi	a1,s0,-152
    80005da8:	4509                	li	a0,2
    80005daa:	ffffd097          	auipc	ra,0xffffd
    80005dae:	22a080e7          	jalr	554(ra) # 80002fd4 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005db2:	08000613          	li	a2,128
    80005db6:	f7040593          	addi	a1,s0,-144
    80005dba:	4501                	li	a0,0
    80005dbc:	ffffd097          	auipc	ra,0xffffd
    80005dc0:	258080e7          	jalr	600(ra) # 80003014 <argstr>
    80005dc4:	02054b63          	bltz	a0,80005dfa <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005dc8:	f6841683          	lh	a3,-152(s0)
    80005dcc:	f6c41603          	lh	a2,-148(s0)
    80005dd0:	458d                	li	a1,3
    80005dd2:	f7040513          	addi	a0,s0,-144
    80005dd6:	fffff097          	auipc	ra,0xfffff
    80005dda:	786080e7          	jalr	1926(ra) # 8000555c <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005dde:	cd11                	beqz	a0,80005dfa <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005de0:	ffffe097          	auipc	ra,0xffffe
    80005de4:	0b6080e7          	jalr	182(ra) # 80003e96 <iunlockput>
  end_op();
    80005de8:	fffff097          	auipc	ra,0xfffff
    80005dec:	86c080e7          	jalr	-1940(ra) # 80004654 <end_op>
  return 0;
    80005df0:	4501                	li	a0,0
}
    80005df2:	60ea                	ld	ra,152(sp)
    80005df4:	644a                	ld	s0,144(sp)
    80005df6:	610d                	addi	sp,sp,160
    80005df8:	8082                	ret
    end_op();
    80005dfa:	fffff097          	auipc	ra,0xfffff
    80005dfe:	85a080e7          	jalr	-1958(ra) # 80004654 <end_op>
    return -1;
    80005e02:	557d                	li	a0,-1
    80005e04:	b7fd                	j	80005df2 <sys_mknod+0x6c>

0000000080005e06 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005e06:	7135                	addi	sp,sp,-160
    80005e08:	ed06                	sd	ra,152(sp)
    80005e0a:	e922                	sd	s0,144(sp)
    80005e0c:	e526                	sd	s1,136(sp)
    80005e0e:	e14a                	sd	s2,128(sp)
    80005e10:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005e12:	ffffc097          	auipc	ra,0xffffc
    80005e16:	dda080e7          	jalr	-550(ra) # 80001bec <myproc>
    80005e1a:	892a                	mv	s2,a0
  
  begin_op();
    80005e1c:	ffffe097          	auipc	ra,0xffffe
    80005e20:	7be080e7          	jalr	1982(ra) # 800045da <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005e24:	08000613          	li	a2,128
    80005e28:	f6040593          	addi	a1,s0,-160
    80005e2c:	4501                	li	a0,0
    80005e2e:	ffffd097          	auipc	ra,0xffffd
    80005e32:	1e6080e7          	jalr	486(ra) # 80003014 <argstr>
    80005e36:	04054b63          	bltz	a0,80005e8c <sys_chdir+0x86>
    80005e3a:	f6040513          	addi	a0,s0,-160
    80005e3e:	ffffe097          	auipc	ra,0xffffe
    80005e42:	59c080e7          	jalr	1436(ra) # 800043da <namei>
    80005e46:	84aa                	mv	s1,a0
    80005e48:	c131                	beqz	a0,80005e8c <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005e4a:	ffffe097          	auipc	ra,0xffffe
    80005e4e:	dea080e7          	jalr	-534(ra) # 80003c34 <ilock>
  if(ip->type != T_DIR){
    80005e52:	04449703          	lh	a4,68(s1)
    80005e56:	4785                	li	a5,1
    80005e58:	04f71063          	bne	a4,a5,80005e98 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005e5c:	8526                	mv	a0,s1
    80005e5e:	ffffe097          	auipc	ra,0xffffe
    80005e62:	e98080e7          	jalr	-360(ra) # 80003cf6 <iunlock>
  iput(p->cwd);
    80005e66:	15093503          	ld	a0,336(s2)
    80005e6a:	ffffe097          	auipc	ra,0xffffe
    80005e6e:	f84080e7          	jalr	-124(ra) # 80003dee <iput>
  end_op();
    80005e72:	ffffe097          	auipc	ra,0xffffe
    80005e76:	7e2080e7          	jalr	2018(ra) # 80004654 <end_op>
  p->cwd = ip;
    80005e7a:	14993823          	sd	s1,336(s2)
  return 0;
    80005e7e:	4501                	li	a0,0
}
    80005e80:	60ea                	ld	ra,152(sp)
    80005e82:	644a                	ld	s0,144(sp)
    80005e84:	64aa                	ld	s1,136(sp)
    80005e86:	690a                	ld	s2,128(sp)
    80005e88:	610d                	addi	sp,sp,160
    80005e8a:	8082                	ret
    end_op();
    80005e8c:	ffffe097          	auipc	ra,0xffffe
    80005e90:	7c8080e7          	jalr	1992(ra) # 80004654 <end_op>
    return -1;
    80005e94:	557d                	li	a0,-1
    80005e96:	b7ed                	j	80005e80 <sys_chdir+0x7a>
    iunlockput(ip);
    80005e98:	8526                	mv	a0,s1
    80005e9a:	ffffe097          	auipc	ra,0xffffe
    80005e9e:	ffc080e7          	jalr	-4(ra) # 80003e96 <iunlockput>
    end_op();
    80005ea2:	ffffe097          	auipc	ra,0xffffe
    80005ea6:	7b2080e7          	jalr	1970(ra) # 80004654 <end_op>
    return -1;
    80005eaa:	557d                	li	a0,-1
    80005eac:	bfd1                	j	80005e80 <sys_chdir+0x7a>

0000000080005eae <sys_exec>:

uint64
sys_exec(void)
{
    80005eae:	7121                	addi	sp,sp,-448
    80005eb0:	ff06                	sd	ra,440(sp)
    80005eb2:	fb22                	sd	s0,432(sp)
    80005eb4:	f726                	sd	s1,424(sp)
    80005eb6:	f34a                	sd	s2,416(sp)
    80005eb8:	ef4e                	sd	s3,408(sp)
    80005eba:	eb52                	sd	s4,400(sp)
    80005ebc:	0380                	addi	s0,sp,448
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005ebe:	e4840593          	addi	a1,s0,-440
    80005ec2:	4505                	li	a0,1
    80005ec4:	ffffd097          	auipc	ra,0xffffd
    80005ec8:	130080e7          	jalr	304(ra) # 80002ff4 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005ecc:	08000613          	li	a2,128
    80005ed0:	f5040593          	addi	a1,s0,-176
    80005ed4:	4501                	li	a0,0
    80005ed6:	ffffd097          	auipc	ra,0xffffd
    80005eda:	13e080e7          	jalr	318(ra) # 80003014 <argstr>
    80005ede:	87aa                	mv	a5,a0
    return -1;
    80005ee0:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005ee2:	0c07c263          	bltz	a5,80005fa6 <sys_exec+0xf8>
  }
  memset(argv, 0, sizeof(argv));
    80005ee6:	10000613          	li	a2,256
    80005eea:	4581                	li	a1,0
    80005eec:	e5040513          	addi	a0,s0,-432
    80005ef0:	ffffb097          	auipc	ra,0xffffb
    80005ef4:	f26080e7          	jalr	-218(ra) # 80000e16 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005ef8:	e5040493          	addi	s1,s0,-432
  memset(argv, 0, sizeof(argv));
    80005efc:	89a6                	mv	s3,s1
    80005efe:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005f00:	02000a13          	li	s4,32
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005f04:	00391513          	slli	a0,s2,0x3
    80005f08:	e4040593          	addi	a1,s0,-448
    80005f0c:	e4843783          	ld	a5,-440(s0)
    80005f10:	953e                	add	a0,a0,a5
    80005f12:	ffffd097          	auipc	ra,0xffffd
    80005f16:	024080e7          	jalr	36(ra) # 80002f36 <fetchaddr>
    80005f1a:	02054a63          	bltz	a0,80005f4e <sys_exec+0xa0>
      goto bad;
    }
    if(uarg == 0){
    80005f1e:	e4043783          	ld	a5,-448(s0)
    80005f22:	c3b9                	beqz	a5,80005f68 <sys_exec+0xba>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005f24:	ffffb097          	auipc	ra,0xffffb
    80005f28:	c6c080e7          	jalr	-916(ra) # 80000b90 <kalloc>
    80005f2c:	85aa                	mv	a1,a0
    80005f2e:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005f32:	cd11                	beqz	a0,80005f4e <sys_exec+0xa0>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005f34:	6605                	lui	a2,0x1
    80005f36:	e4043503          	ld	a0,-448(s0)
    80005f3a:	ffffd097          	auipc	ra,0xffffd
    80005f3e:	04e080e7          	jalr	78(ra) # 80002f88 <fetchstr>
    80005f42:	00054663          	bltz	a0,80005f4e <sys_exec+0xa0>
    if(i >= NELEM(argv)){
    80005f46:	0905                	addi	s2,s2,1
    80005f48:	09a1                	addi	s3,s3,8
    80005f4a:	fb491de3          	bne	s2,s4,80005f04 <sys_exec+0x56>
  }

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++){
    80005f4e:	f5040913          	addi	s2,s0,-176
    80005f52:	6088                	ld	a0,0(s1)
    80005f54:	c921                	beqz	a0,80005fa4 <sys_exec+0xf6>
    //kfree(argv[i]);
    decrement_reference_counter(argv[i]);
    80005f56:	ffffb097          	auipc	ra,0xffffb
    80005f5a:	cf0080e7          	jalr	-784(ra) # 80000c46 <decrement_reference_counter>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++){
    80005f5e:	04a1                	addi	s1,s1,8
    80005f60:	ff2499e3          	bne	s1,s2,80005f52 <sys_exec+0xa4>
  }

  return -1;
    80005f64:	557d                	li	a0,-1
    80005f66:	a081                	j	80005fa6 <sys_exec+0xf8>
      argv[i] = 0;
    80005f68:	0009079b          	sext.w	a5,s2
    80005f6c:	078e                	slli	a5,a5,0x3
    80005f6e:	fd078793          	addi	a5,a5,-48
    80005f72:	97a2                	add	a5,a5,s0
    80005f74:	e807b023          	sd	zero,-384(a5)
  int ret = exec(path, argv);
    80005f78:	e5040593          	addi	a1,s0,-432
    80005f7c:	f5040513          	addi	a0,s0,-176
    80005f80:	fffff097          	auipc	ra,0xfffff
    80005f84:	194080e7          	jalr	404(ra) # 80005114 <exec>
    80005f88:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++){
    80005f8a:	f5040993          	addi	s3,s0,-176
    80005f8e:	6088                	ld	a0,0(s1)
    80005f90:	c901                	beqz	a0,80005fa0 <sys_exec+0xf2>
    decrement_reference_counter(argv[i]);
    80005f92:	ffffb097          	auipc	ra,0xffffb
    80005f96:	cb4080e7          	jalr	-844(ra) # 80000c46 <decrement_reference_counter>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++){
    80005f9a:	04a1                	addi	s1,s1,8
    80005f9c:	ff3499e3          	bne	s1,s3,80005f8e <sys_exec+0xe0>
  return ret;
    80005fa0:	854a                	mv	a0,s2
    80005fa2:	a011                	j	80005fa6 <sys_exec+0xf8>
  return -1;
    80005fa4:	557d                	li	a0,-1
}
    80005fa6:	70fa                	ld	ra,440(sp)
    80005fa8:	745a                	ld	s0,432(sp)
    80005faa:	74ba                	ld	s1,424(sp)
    80005fac:	791a                	ld	s2,416(sp)
    80005fae:	69fa                	ld	s3,408(sp)
    80005fb0:	6a5a                	ld	s4,400(sp)
    80005fb2:	6139                	addi	sp,sp,448
    80005fb4:	8082                	ret

0000000080005fb6 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005fb6:	7139                	addi	sp,sp,-64
    80005fb8:	fc06                	sd	ra,56(sp)
    80005fba:	f822                	sd	s0,48(sp)
    80005fbc:	f426                	sd	s1,40(sp)
    80005fbe:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005fc0:	ffffc097          	auipc	ra,0xffffc
    80005fc4:	c2c080e7          	jalr	-980(ra) # 80001bec <myproc>
    80005fc8:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005fca:	fd840593          	addi	a1,s0,-40
    80005fce:	4501                	li	a0,0
    80005fd0:	ffffd097          	auipc	ra,0xffffd
    80005fd4:	024080e7          	jalr	36(ra) # 80002ff4 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005fd8:	fc840593          	addi	a1,s0,-56
    80005fdc:	fd040513          	addi	a0,s0,-48
    80005fe0:	fffff097          	auipc	ra,0xfffff
    80005fe4:	dea080e7          	jalr	-534(ra) # 80004dca <pipealloc>
    return -1;
    80005fe8:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005fea:	0c054463          	bltz	a0,800060b2 <sys_pipe+0xfc>
  fd0 = -1;
    80005fee:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005ff2:	fd043503          	ld	a0,-48(s0)
    80005ff6:	fffff097          	auipc	ra,0xfffff
    80005ffa:	524080e7          	jalr	1316(ra) # 8000551a <fdalloc>
    80005ffe:	fca42223          	sw	a0,-60(s0)
    80006002:	08054b63          	bltz	a0,80006098 <sys_pipe+0xe2>
    80006006:	fc843503          	ld	a0,-56(s0)
    8000600a:	fffff097          	auipc	ra,0xfffff
    8000600e:	510080e7          	jalr	1296(ra) # 8000551a <fdalloc>
    80006012:	fca42023          	sw	a0,-64(s0)
    80006016:	06054863          	bltz	a0,80006086 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000601a:	4691                	li	a3,4
    8000601c:	fc440613          	addi	a2,s0,-60
    80006020:	fd843583          	ld	a1,-40(s0)
    80006024:	68a8                	ld	a0,80(s1)
    80006026:	ffffb097          	auipc	ra,0xffffb
    8000602a:	792080e7          	jalr	1938(ra) # 800017b8 <copyout>
    8000602e:	02054063          	bltz	a0,8000604e <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006032:	4691                	li	a3,4
    80006034:	fc040613          	addi	a2,s0,-64
    80006038:	fd843583          	ld	a1,-40(s0)
    8000603c:	0591                	addi	a1,a1,4
    8000603e:	68a8                	ld	a0,80(s1)
    80006040:	ffffb097          	auipc	ra,0xffffb
    80006044:	778080e7          	jalr	1912(ra) # 800017b8 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006048:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000604a:	06055463          	bgez	a0,800060b2 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    8000604e:	fc442783          	lw	a5,-60(s0)
    80006052:	07e9                	addi	a5,a5,26
    80006054:	078e                	slli	a5,a5,0x3
    80006056:	97a6                	add	a5,a5,s1
    80006058:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    8000605c:	fc042783          	lw	a5,-64(s0)
    80006060:	07e9                	addi	a5,a5,26
    80006062:	078e                	slli	a5,a5,0x3
    80006064:	94be                	add	s1,s1,a5
    80006066:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    8000606a:	fd043503          	ld	a0,-48(s0)
    8000606e:	fffff097          	auipc	ra,0xfffff
    80006072:	a30080e7          	jalr	-1488(ra) # 80004a9e <fileclose>
    fileclose(wf);
    80006076:	fc843503          	ld	a0,-56(s0)
    8000607a:	fffff097          	auipc	ra,0xfffff
    8000607e:	a24080e7          	jalr	-1500(ra) # 80004a9e <fileclose>
    return -1;
    80006082:	57fd                	li	a5,-1
    80006084:	a03d                	j	800060b2 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80006086:	fc442783          	lw	a5,-60(s0)
    8000608a:	0007c763          	bltz	a5,80006098 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    8000608e:	07e9                	addi	a5,a5,26
    80006090:	078e                	slli	a5,a5,0x3
    80006092:	97a6                	add	a5,a5,s1
    80006094:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80006098:	fd043503          	ld	a0,-48(s0)
    8000609c:	fffff097          	auipc	ra,0xfffff
    800060a0:	a02080e7          	jalr	-1534(ra) # 80004a9e <fileclose>
    fileclose(wf);
    800060a4:	fc843503          	ld	a0,-56(s0)
    800060a8:	fffff097          	auipc	ra,0xfffff
    800060ac:	9f6080e7          	jalr	-1546(ra) # 80004a9e <fileclose>
    return -1;
    800060b0:	57fd                	li	a5,-1
}
    800060b2:	853e                	mv	a0,a5
    800060b4:	70e2                	ld	ra,56(sp)
    800060b6:	7442                	ld	s0,48(sp)
    800060b8:	74a2                	ld	s1,40(sp)
    800060ba:	6121                	addi	sp,sp,64
    800060bc:	8082                	ret
	...

00000000800060c0 <kernelvec>:
    800060c0:	7111                	addi	sp,sp,-256
    800060c2:	e006                	sd	ra,0(sp)
    800060c4:	e40a                	sd	sp,8(sp)
    800060c6:	e80e                	sd	gp,16(sp)
    800060c8:	ec12                	sd	tp,24(sp)
    800060ca:	f016                	sd	t0,32(sp)
    800060cc:	f41a                	sd	t1,40(sp)
    800060ce:	f81e                	sd	t2,48(sp)
    800060d0:	fc22                	sd	s0,56(sp)
    800060d2:	e0a6                	sd	s1,64(sp)
    800060d4:	e4aa                	sd	a0,72(sp)
    800060d6:	e8ae                	sd	a1,80(sp)
    800060d8:	ecb2                	sd	a2,88(sp)
    800060da:	f0b6                	sd	a3,96(sp)
    800060dc:	f4ba                	sd	a4,104(sp)
    800060de:	f8be                	sd	a5,112(sp)
    800060e0:	fcc2                	sd	a6,120(sp)
    800060e2:	e146                	sd	a7,128(sp)
    800060e4:	e54a                	sd	s2,136(sp)
    800060e6:	e94e                	sd	s3,144(sp)
    800060e8:	ed52                	sd	s4,152(sp)
    800060ea:	f156                	sd	s5,160(sp)
    800060ec:	f55a                	sd	s6,168(sp)
    800060ee:	f95e                	sd	s7,176(sp)
    800060f0:	fd62                	sd	s8,184(sp)
    800060f2:	e1e6                	sd	s9,192(sp)
    800060f4:	e5ea                	sd	s10,200(sp)
    800060f6:	e9ee                	sd	s11,208(sp)
    800060f8:	edf2                	sd	t3,216(sp)
    800060fa:	f1f6                	sd	t4,224(sp)
    800060fc:	f5fa                	sd	t5,232(sp)
    800060fe:	f9fe                	sd	t6,240(sp)
    80006100:	d03fc0ef          	jal	ra,80002e02 <kerneltrap>
    80006104:	6082                	ld	ra,0(sp)
    80006106:	6122                	ld	sp,8(sp)
    80006108:	61c2                	ld	gp,16(sp)
    8000610a:	7282                	ld	t0,32(sp)
    8000610c:	7322                	ld	t1,40(sp)
    8000610e:	73c2                	ld	t2,48(sp)
    80006110:	7462                	ld	s0,56(sp)
    80006112:	6486                	ld	s1,64(sp)
    80006114:	6526                	ld	a0,72(sp)
    80006116:	65c6                	ld	a1,80(sp)
    80006118:	6666                	ld	a2,88(sp)
    8000611a:	7686                	ld	a3,96(sp)
    8000611c:	7726                	ld	a4,104(sp)
    8000611e:	77c6                	ld	a5,112(sp)
    80006120:	7866                	ld	a6,120(sp)
    80006122:	688a                	ld	a7,128(sp)
    80006124:	692a                	ld	s2,136(sp)
    80006126:	69ca                	ld	s3,144(sp)
    80006128:	6a6a                	ld	s4,152(sp)
    8000612a:	7a8a                	ld	s5,160(sp)
    8000612c:	7b2a                	ld	s6,168(sp)
    8000612e:	7bca                	ld	s7,176(sp)
    80006130:	7c6a                	ld	s8,184(sp)
    80006132:	6c8e                	ld	s9,192(sp)
    80006134:	6d2e                	ld	s10,200(sp)
    80006136:	6dce                	ld	s11,208(sp)
    80006138:	6e6e                	ld	t3,216(sp)
    8000613a:	7e8e                	ld	t4,224(sp)
    8000613c:	7f2e                	ld	t5,232(sp)
    8000613e:	7fce                	ld	t6,240(sp)
    80006140:	6111                	addi	sp,sp,256
    80006142:	10200073          	sret
    80006146:	00000013          	nop
    8000614a:	00000013          	nop
    8000614e:	0001                	nop

0000000080006150 <timervec>:
    80006150:	34051573          	csrrw	a0,mscratch,a0
    80006154:	e10c                	sd	a1,0(a0)
    80006156:	e510                	sd	a2,8(a0)
    80006158:	e914                	sd	a3,16(a0)
    8000615a:	6d0c                	ld	a1,24(a0)
    8000615c:	7110                	ld	a2,32(a0)
    8000615e:	6194                	ld	a3,0(a1)
    80006160:	96b2                	add	a3,a3,a2
    80006162:	e194                	sd	a3,0(a1)
    80006164:	4589                	li	a1,2
    80006166:	14459073          	csrw	sip,a1
    8000616a:	6914                	ld	a3,16(a0)
    8000616c:	6510                	ld	a2,8(a0)
    8000616e:	610c                	ld	a1,0(a0)
    80006170:	34051573          	csrrw	a0,mscratch,a0
    80006174:	30200073          	mret
	...

000000008000617a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000617a:	1141                	addi	sp,sp,-16
    8000617c:	e422                	sd	s0,8(sp)
    8000617e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006180:	0c0007b7          	lui	a5,0xc000
    80006184:	4705                	li	a4,1
    80006186:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006188:	c3d8                	sw	a4,4(a5)
}
    8000618a:	6422                	ld	s0,8(sp)
    8000618c:	0141                	addi	sp,sp,16
    8000618e:	8082                	ret

0000000080006190 <plicinithart>:

void
plicinithart(void)
{
    80006190:	1141                	addi	sp,sp,-16
    80006192:	e406                	sd	ra,8(sp)
    80006194:	e022                	sd	s0,0(sp)
    80006196:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006198:	ffffc097          	auipc	ra,0xffffc
    8000619c:	a28080e7          	jalr	-1496(ra) # 80001bc0 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800061a0:	0085171b          	slliw	a4,a0,0x8
    800061a4:	0c0027b7          	lui	a5,0xc002
    800061a8:	97ba                	add	a5,a5,a4
    800061aa:	40200713          	li	a4,1026
    800061ae:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800061b2:	00d5151b          	slliw	a0,a0,0xd
    800061b6:	0c2017b7          	lui	a5,0xc201
    800061ba:	97aa                	add	a5,a5,a0
    800061bc:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    800061c0:	60a2                	ld	ra,8(sp)
    800061c2:	6402                	ld	s0,0(sp)
    800061c4:	0141                	addi	sp,sp,16
    800061c6:	8082                	ret

00000000800061c8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800061c8:	1141                	addi	sp,sp,-16
    800061ca:	e406                	sd	ra,8(sp)
    800061cc:	e022                	sd	s0,0(sp)
    800061ce:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800061d0:	ffffc097          	auipc	ra,0xffffc
    800061d4:	9f0080e7          	jalr	-1552(ra) # 80001bc0 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800061d8:	00d5151b          	slliw	a0,a0,0xd
    800061dc:	0c2017b7          	lui	a5,0xc201
    800061e0:	97aa                	add	a5,a5,a0
  return irq;
}
    800061e2:	43c8                	lw	a0,4(a5)
    800061e4:	60a2                	ld	ra,8(sp)
    800061e6:	6402                	ld	s0,0(sp)
    800061e8:	0141                	addi	sp,sp,16
    800061ea:	8082                	ret

00000000800061ec <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800061ec:	1101                	addi	sp,sp,-32
    800061ee:	ec06                	sd	ra,24(sp)
    800061f0:	e822                	sd	s0,16(sp)
    800061f2:	e426                	sd	s1,8(sp)
    800061f4:	1000                	addi	s0,sp,32
    800061f6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800061f8:	ffffc097          	auipc	ra,0xffffc
    800061fc:	9c8080e7          	jalr	-1592(ra) # 80001bc0 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006200:	00d5151b          	slliw	a0,a0,0xd
    80006204:	0c2017b7          	lui	a5,0xc201
    80006208:	97aa                	add	a5,a5,a0
    8000620a:	c3c4                	sw	s1,4(a5)
}
    8000620c:	60e2                	ld	ra,24(sp)
    8000620e:	6442                	ld	s0,16(sp)
    80006210:	64a2                	ld	s1,8(sp)
    80006212:	6105                	addi	sp,sp,32
    80006214:	8082                	ret

0000000080006216 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006216:	1141                	addi	sp,sp,-16
    80006218:	e406                	sd	ra,8(sp)
    8000621a:	e022                	sd	s0,0(sp)
    8000621c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000621e:	479d                	li	a5,7
    80006220:	04a7cc63          	blt	a5,a0,80006278 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006224:	0003c797          	auipc	a5,0x3c
    80006228:	b8c78793          	addi	a5,a5,-1140 # 80041db0 <disk>
    8000622c:	97aa                	add	a5,a5,a0
    8000622e:	0187c783          	lbu	a5,24(a5)
    80006232:	ebb9                	bnez	a5,80006288 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006234:	00451693          	slli	a3,a0,0x4
    80006238:	0003c797          	auipc	a5,0x3c
    8000623c:	b7878793          	addi	a5,a5,-1160 # 80041db0 <disk>
    80006240:	6398                	ld	a4,0(a5)
    80006242:	9736                	add	a4,a4,a3
    80006244:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80006248:	6398                	ld	a4,0(a5)
    8000624a:	9736                	add	a4,a4,a3
    8000624c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006250:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006254:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006258:	97aa                	add	a5,a5,a0
    8000625a:	4705                	li	a4,1
    8000625c:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80006260:	0003c517          	auipc	a0,0x3c
    80006264:	b6850513          	addi	a0,a0,-1176 # 80041dc8 <disk+0x18>
    80006268:	ffffc097          	auipc	ra,0xffffc
    8000626c:	150080e7          	jalr	336(ra) # 800023b8 <wakeup>
}
    80006270:	60a2                	ld	ra,8(sp)
    80006272:	6402                	ld	s0,0(sp)
    80006274:	0141                	addi	sp,sp,16
    80006276:	8082                	ret
    panic("free_desc 1");
    80006278:	00002517          	auipc	a0,0x2
    8000627c:	63050513          	addi	a0,a0,1584 # 800088a8 <syscalls+0x318>
    80006280:	ffffa097          	auipc	ra,0xffffa
    80006284:	2bc080e7          	jalr	700(ra) # 8000053c <panic>
    panic("free_desc 2");
    80006288:	00002517          	auipc	a0,0x2
    8000628c:	63050513          	addi	a0,a0,1584 # 800088b8 <syscalls+0x328>
    80006290:	ffffa097          	auipc	ra,0xffffa
    80006294:	2ac080e7          	jalr	684(ra) # 8000053c <panic>

0000000080006298 <virtio_disk_init>:
{
    80006298:	1101                	addi	sp,sp,-32
    8000629a:	ec06                	sd	ra,24(sp)
    8000629c:	e822                	sd	s0,16(sp)
    8000629e:	e426                	sd	s1,8(sp)
    800062a0:	e04a                	sd	s2,0(sp)
    800062a2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800062a4:	00002597          	auipc	a1,0x2
    800062a8:	62458593          	addi	a1,a1,1572 # 800088c8 <syscalls+0x338>
    800062ac:	0003c517          	auipc	a0,0x3c
    800062b0:	c2c50513          	addi	a0,a0,-980 # 80041ed8 <disk+0x128>
    800062b4:	ffffb097          	auipc	ra,0xffffb
    800062b8:	9d6080e7          	jalr	-1578(ra) # 80000c8a <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800062bc:	100017b7          	lui	a5,0x10001
    800062c0:	4398                	lw	a4,0(a5)
    800062c2:	2701                	sext.w	a4,a4
    800062c4:	747277b7          	lui	a5,0x74727
    800062c8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800062cc:	14f71b63          	bne	a4,a5,80006422 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800062d0:	100017b7          	lui	a5,0x10001
    800062d4:	43dc                	lw	a5,4(a5)
    800062d6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800062d8:	4709                	li	a4,2
    800062da:	14e79463          	bne	a5,a4,80006422 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800062de:	100017b7          	lui	a5,0x10001
    800062e2:	479c                	lw	a5,8(a5)
    800062e4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800062e6:	12e79e63          	bne	a5,a4,80006422 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800062ea:	100017b7          	lui	a5,0x10001
    800062ee:	47d8                	lw	a4,12(a5)
    800062f0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800062f2:	554d47b7          	lui	a5,0x554d4
    800062f6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800062fa:	12f71463          	bne	a4,a5,80006422 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    800062fe:	100017b7          	lui	a5,0x10001
    80006302:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006306:	4705                	li	a4,1
    80006308:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000630a:	470d                	li	a4,3
    8000630c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000630e:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006310:	c7ffe6b7          	lui	a3,0xc7ffe
    80006314:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fbc86f>
    80006318:	8f75                	and	a4,a4,a3
    8000631a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000631c:	472d                	li	a4,11
    8000631e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006320:	5bbc                	lw	a5,112(a5)
    80006322:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006326:	8ba1                	andi	a5,a5,8
    80006328:	10078563          	beqz	a5,80006432 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000632c:	100017b7          	lui	a5,0x10001
    80006330:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006334:	43fc                	lw	a5,68(a5)
    80006336:	2781                	sext.w	a5,a5
    80006338:	10079563          	bnez	a5,80006442 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000633c:	100017b7          	lui	a5,0x10001
    80006340:	5bdc                	lw	a5,52(a5)
    80006342:	2781                	sext.w	a5,a5
  if(max == 0)
    80006344:	10078763          	beqz	a5,80006452 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80006348:	471d                	li	a4,7
    8000634a:	10f77c63          	bgeu	a4,a5,80006462 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    8000634e:	ffffb097          	auipc	ra,0xffffb
    80006352:	842080e7          	jalr	-1982(ra) # 80000b90 <kalloc>
    80006356:	0003c497          	auipc	s1,0x3c
    8000635a:	a5a48493          	addi	s1,s1,-1446 # 80041db0 <disk>
    8000635e:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006360:	ffffb097          	auipc	ra,0xffffb
    80006364:	830080e7          	jalr	-2000(ra) # 80000b90 <kalloc>
    80006368:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000636a:	ffffb097          	auipc	ra,0xffffb
    8000636e:	826080e7          	jalr	-2010(ra) # 80000b90 <kalloc>
    80006372:	87aa                	mv	a5,a0
    80006374:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006376:	6088                	ld	a0,0(s1)
    80006378:	cd6d                	beqz	a0,80006472 <virtio_disk_init+0x1da>
    8000637a:	0003c717          	auipc	a4,0x3c
    8000637e:	a3e73703          	ld	a4,-1474(a4) # 80041db8 <disk+0x8>
    80006382:	cb65                	beqz	a4,80006472 <virtio_disk_init+0x1da>
    80006384:	c7fd                	beqz	a5,80006472 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80006386:	6605                	lui	a2,0x1
    80006388:	4581                	li	a1,0
    8000638a:	ffffb097          	auipc	ra,0xffffb
    8000638e:	a8c080e7          	jalr	-1396(ra) # 80000e16 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006392:	0003c497          	auipc	s1,0x3c
    80006396:	a1e48493          	addi	s1,s1,-1506 # 80041db0 <disk>
    8000639a:	6605                	lui	a2,0x1
    8000639c:	4581                	li	a1,0
    8000639e:	6488                	ld	a0,8(s1)
    800063a0:	ffffb097          	auipc	ra,0xffffb
    800063a4:	a76080e7          	jalr	-1418(ra) # 80000e16 <memset>
  memset(disk.used, 0, PGSIZE);
    800063a8:	6605                	lui	a2,0x1
    800063aa:	4581                	li	a1,0
    800063ac:	6888                	ld	a0,16(s1)
    800063ae:	ffffb097          	auipc	ra,0xffffb
    800063b2:	a68080e7          	jalr	-1432(ra) # 80000e16 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800063b6:	100017b7          	lui	a5,0x10001
    800063ba:	4721                	li	a4,8
    800063bc:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800063be:	4098                	lw	a4,0(s1)
    800063c0:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    800063c4:	40d8                	lw	a4,4(s1)
    800063c6:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    800063ca:	6498                	ld	a4,8(s1)
    800063cc:	0007069b          	sext.w	a3,a4
    800063d0:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    800063d4:	9701                	srai	a4,a4,0x20
    800063d6:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    800063da:	6898                	ld	a4,16(s1)
    800063dc:	0007069b          	sext.w	a3,a4
    800063e0:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    800063e4:	9701                	srai	a4,a4,0x20
    800063e6:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    800063ea:	4705                	li	a4,1
    800063ec:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    800063ee:	00e48c23          	sb	a4,24(s1)
    800063f2:	00e48ca3          	sb	a4,25(s1)
    800063f6:	00e48d23          	sb	a4,26(s1)
    800063fa:	00e48da3          	sb	a4,27(s1)
    800063fe:	00e48e23          	sb	a4,28(s1)
    80006402:	00e48ea3          	sb	a4,29(s1)
    80006406:	00e48f23          	sb	a4,30(s1)
    8000640a:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    8000640e:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006412:	0727a823          	sw	s2,112(a5)
}
    80006416:	60e2                	ld	ra,24(sp)
    80006418:	6442                	ld	s0,16(sp)
    8000641a:	64a2                	ld	s1,8(sp)
    8000641c:	6902                	ld	s2,0(sp)
    8000641e:	6105                	addi	sp,sp,32
    80006420:	8082                	ret
    panic("could not find virtio disk");
    80006422:	00002517          	auipc	a0,0x2
    80006426:	4b650513          	addi	a0,a0,1206 # 800088d8 <syscalls+0x348>
    8000642a:	ffffa097          	auipc	ra,0xffffa
    8000642e:	112080e7          	jalr	274(ra) # 8000053c <panic>
    panic("virtio disk FEATURES_OK unset");
    80006432:	00002517          	auipc	a0,0x2
    80006436:	4c650513          	addi	a0,a0,1222 # 800088f8 <syscalls+0x368>
    8000643a:	ffffa097          	auipc	ra,0xffffa
    8000643e:	102080e7          	jalr	258(ra) # 8000053c <panic>
    panic("virtio disk should not be ready");
    80006442:	00002517          	auipc	a0,0x2
    80006446:	4d650513          	addi	a0,a0,1238 # 80008918 <syscalls+0x388>
    8000644a:	ffffa097          	auipc	ra,0xffffa
    8000644e:	0f2080e7          	jalr	242(ra) # 8000053c <panic>
    panic("virtio disk has no queue 0");
    80006452:	00002517          	auipc	a0,0x2
    80006456:	4e650513          	addi	a0,a0,1254 # 80008938 <syscalls+0x3a8>
    8000645a:	ffffa097          	auipc	ra,0xffffa
    8000645e:	0e2080e7          	jalr	226(ra) # 8000053c <panic>
    panic("virtio disk max queue too short");
    80006462:	00002517          	auipc	a0,0x2
    80006466:	4f650513          	addi	a0,a0,1270 # 80008958 <syscalls+0x3c8>
    8000646a:	ffffa097          	auipc	ra,0xffffa
    8000646e:	0d2080e7          	jalr	210(ra) # 8000053c <panic>
    panic("virtio disk kalloc");
    80006472:	00002517          	auipc	a0,0x2
    80006476:	50650513          	addi	a0,a0,1286 # 80008978 <syscalls+0x3e8>
    8000647a:	ffffa097          	auipc	ra,0xffffa
    8000647e:	0c2080e7          	jalr	194(ra) # 8000053c <panic>

0000000080006482 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006482:	7159                	addi	sp,sp,-112
    80006484:	f486                	sd	ra,104(sp)
    80006486:	f0a2                	sd	s0,96(sp)
    80006488:	eca6                	sd	s1,88(sp)
    8000648a:	e8ca                	sd	s2,80(sp)
    8000648c:	e4ce                	sd	s3,72(sp)
    8000648e:	e0d2                	sd	s4,64(sp)
    80006490:	fc56                	sd	s5,56(sp)
    80006492:	f85a                	sd	s6,48(sp)
    80006494:	f45e                	sd	s7,40(sp)
    80006496:	f062                	sd	s8,32(sp)
    80006498:	ec66                	sd	s9,24(sp)
    8000649a:	e86a                	sd	s10,16(sp)
    8000649c:	1880                	addi	s0,sp,112
    8000649e:	8a2a                	mv	s4,a0
    800064a0:	8bae                	mv	s7,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800064a2:	00c52c83          	lw	s9,12(a0)
    800064a6:	001c9c9b          	slliw	s9,s9,0x1
    800064aa:	1c82                	slli	s9,s9,0x20
    800064ac:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800064b0:	0003c517          	auipc	a0,0x3c
    800064b4:	a2850513          	addi	a0,a0,-1496 # 80041ed8 <disk+0x128>
    800064b8:	ffffb097          	auipc	ra,0xffffb
    800064bc:	862080e7          	jalr	-1950(ra) # 80000d1a <acquire>
  for(int i = 0; i < 3; i++){
    800064c0:	4901                	li	s2,0
  for(int i = 0; i < NUM; i++){
    800064c2:	44a1                	li	s1,8
      disk.free[i] = 0;
    800064c4:	0003cb17          	auipc	s6,0x3c
    800064c8:	8ecb0b13          	addi	s6,s6,-1812 # 80041db0 <disk>
  for(int i = 0; i < 3; i++){
    800064cc:	4a8d                	li	s5,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800064ce:	0003cc17          	auipc	s8,0x3c
    800064d2:	a0ac0c13          	addi	s8,s8,-1526 # 80041ed8 <disk+0x128>
    800064d6:	a095                	j	8000653a <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    800064d8:	00fb0733          	add	a4,s6,a5
    800064dc:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800064e0:	c11c                	sw	a5,0(a0)
    if(idx[i] < 0){
    800064e2:	0207c563          	bltz	a5,8000650c <virtio_disk_rw+0x8a>
  for(int i = 0; i < 3; i++){
    800064e6:	2605                	addiw	a2,a2,1 # 1001 <_entry-0x7fffefff>
    800064e8:	0591                	addi	a1,a1,4
    800064ea:	05560d63          	beq	a2,s5,80006544 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    800064ee:	852e                	mv	a0,a1
  for(int i = 0; i < NUM; i++){
    800064f0:	0003c717          	auipc	a4,0x3c
    800064f4:	8c070713          	addi	a4,a4,-1856 # 80041db0 <disk>
    800064f8:	87ca                	mv	a5,s2
    if(disk.free[i]){
    800064fa:	01874683          	lbu	a3,24(a4)
    800064fe:	fee9                	bnez	a3,800064d8 <virtio_disk_rw+0x56>
  for(int i = 0; i < NUM; i++){
    80006500:	2785                	addiw	a5,a5,1
    80006502:	0705                	addi	a4,a4,1
    80006504:	fe979be3          	bne	a5,s1,800064fa <virtio_disk_rw+0x78>
    idx[i] = alloc_desc();
    80006508:	57fd                	li	a5,-1
    8000650a:	c11c                	sw	a5,0(a0)
      for(int j = 0; j < i; j++)
    8000650c:	00c05e63          	blez	a2,80006528 <virtio_disk_rw+0xa6>
    80006510:	060a                	slli	a2,a2,0x2
    80006512:	01360d33          	add	s10,a2,s3
        free_desc(idx[j]);
    80006516:	0009a503          	lw	a0,0(s3)
    8000651a:	00000097          	auipc	ra,0x0
    8000651e:	cfc080e7          	jalr	-772(ra) # 80006216 <free_desc>
      for(int j = 0; j < i; j++)
    80006522:	0991                	addi	s3,s3,4
    80006524:	ffa999e3          	bne	s3,s10,80006516 <virtio_disk_rw+0x94>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006528:	85e2                	mv	a1,s8
    8000652a:	0003c517          	auipc	a0,0x3c
    8000652e:	89e50513          	addi	a0,a0,-1890 # 80041dc8 <disk+0x18>
    80006532:	ffffc097          	auipc	ra,0xffffc
    80006536:	e22080e7          	jalr	-478(ra) # 80002354 <sleep>
  for(int i = 0; i < 3; i++){
    8000653a:	f9040993          	addi	s3,s0,-112
{
    8000653e:	85ce                	mv	a1,s3
  for(int i = 0; i < 3; i++){
    80006540:	864a                	mv	a2,s2
    80006542:	b775                	j	800064ee <virtio_disk_rw+0x6c>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006544:	f9042503          	lw	a0,-112(s0)
    80006548:	00a50713          	addi	a4,a0,10
    8000654c:	0712                	slli	a4,a4,0x4

  if(write)
    8000654e:	0003c797          	auipc	a5,0x3c
    80006552:	86278793          	addi	a5,a5,-1950 # 80041db0 <disk>
    80006556:	00e786b3          	add	a3,a5,a4
    8000655a:	01703633          	snez	a2,s7
    8000655e:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006560:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80006564:	0196b823          	sd	s9,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006568:	f6070613          	addi	a2,a4,-160
    8000656c:	6394                	ld	a3,0(a5)
    8000656e:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006570:	00870593          	addi	a1,a4,8
    80006574:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006576:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006578:	0007b803          	ld	a6,0(a5)
    8000657c:	9642                	add	a2,a2,a6
    8000657e:	46c1                	li	a3,16
    80006580:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006582:	4585                	li	a1,1
    80006584:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    80006588:	f9442683          	lw	a3,-108(s0)
    8000658c:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006590:	0692                	slli	a3,a3,0x4
    80006592:	9836                	add	a6,a6,a3
    80006594:	058a0613          	addi	a2,s4,88
    80006598:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    8000659c:	0007b803          	ld	a6,0(a5)
    800065a0:	96c2                	add	a3,a3,a6
    800065a2:	40000613          	li	a2,1024
    800065a6:	c690                	sw	a2,8(a3)
  if(write)
    800065a8:	001bb613          	seqz	a2,s7
    800065ac:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800065b0:	00166613          	ori	a2,a2,1
    800065b4:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800065b8:	f9842603          	lw	a2,-104(s0)
    800065bc:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800065c0:	00250693          	addi	a3,a0,2
    800065c4:	0692                	slli	a3,a3,0x4
    800065c6:	96be                	add	a3,a3,a5
    800065c8:	58fd                	li	a7,-1
    800065ca:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800065ce:	0612                	slli	a2,a2,0x4
    800065d0:	9832                	add	a6,a6,a2
    800065d2:	f9070713          	addi	a4,a4,-112
    800065d6:	973e                	add	a4,a4,a5
    800065d8:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    800065dc:	6398                	ld	a4,0(a5)
    800065de:	9732                	add	a4,a4,a2
    800065e0:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800065e2:	4609                	li	a2,2
    800065e4:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    800065e8:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800065ec:	00ba2223          	sw	a1,4(s4)
  disk.info[idx[0]].b = b;
    800065f0:	0146b423          	sd	s4,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800065f4:	6794                	ld	a3,8(a5)
    800065f6:	0026d703          	lhu	a4,2(a3)
    800065fa:	8b1d                	andi	a4,a4,7
    800065fc:	0706                	slli	a4,a4,0x1
    800065fe:	96ba                	add	a3,a3,a4
    80006600:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006604:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006608:	6798                	ld	a4,8(a5)
    8000660a:	00275783          	lhu	a5,2(a4)
    8000660e:	2785                	addiw	a5,a5,1
    80006610:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006614:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006618:	100017b7          	lui	a5,0x10001
    8000661c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006620:	004a2783          	lw	a5,4(s4)
    sleep(b, &disk.vdisk_lock);
    80006624:	0003c917          	auipc	s2,0x3c
    80006628:	8b490913          	addi	s2,s2,-1868 # 80041ed8 <disk+0x128>
  while(b->disk == 1) {
    8000662c:	4485                	li	s1,1
    8000662e:	00b79c63          	bne	a5,a1,80006646 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006632:	85ca                	mv	a1,s2
    80006634:	8552                	mv	a0,s4
    80006636:	ffffc097          	auipc	ra,0xffffc
    8000663a:	d1e080e7          	jalr	-738(ra) # 80002354 <sleep>
  while(b->disk == 1) {
    8000663e:	004a2783          	lw	a5,4(s4)
    80006642:	fe9788e3          	beq	a5,s1,80006632 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006646:	f9042903          	lw	s2,-112(s0)
    8000664a:	00290713          	addi	a4,s2,2
    8000664e:	0712                	slli	a4,a4,0x4
    80006650:	0003b797          	auipc	a5,0x3b
    80006654:	76078793          	addi	a5,a5,1888 # 80041db0 <disk>
    80006658:	97ba                	add	a5,a5,a4
    8000665a:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000665e:	0003b997          	auipc	s3,0x3b
    80006662:	75298993          	addi	s3,s3,1874 # 80041db0 <disk>
    80006666:	00491713          	slli	a4,s2,0x4
    8000666a:	0009b783          	ld	a5,0(s3)
    8000666e:	97ba                	add	a5,a5,a4
    80006670:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006674:	854a                	mv	a0,s2
    80006676:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000667a:	00000097          	auipc	ra,0x0
    8000667e:	b9c080e7          	jalr	-1124(ra) # 80006216 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006682:	8885                	andi	s1,s1,1
    80006684:	f0ed                	bnez	s1,80006666 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006686:	0003c517          	auipc	a0,0x3c
    8000668a:	85250513          	addi	a0,a0,-1966 # 80041ed8 <disk+0x128>
    8000668e:	ffffa097          	auipc	ra,0xffffa
    80006692:	740080e7          	jalr	1856(ra) # 80000dce <release>
}
    80006696:	70a6                	ld	ra,104(sp)
    80006698:	7406                	ld	s0,96(sp)
    8000669a:	64e6                	ld	s1,88(sp)
    8000669c:	6946                	ld	s2,80(sp)
    8000669e:	69a6                	ld	s3,72(sp)
    800066a0:	6a06                	ld	s4,64(sp)
    800066a2:	7ae2                	ld	s5,56(sp)
    800066a4:	7b42                	ld	s6,48(sp)
    800066a6:	7ba2                	ld	s7,40(sp)
    800066a8:	7c02                	ld	s8,32(sp)
    800066aa:	6ce2                	ld	s9,24(sp)
    800066ac:	6d42                	ld	s10,16(sp)
    800066ae:	6165                	addi	sp,sp,112
    800066b0:	8082                	ret

00000000800066b2 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800066b2:	1101                	addi	sp,sp,-32
    800066b4:	ec06                	sd	ra,24(sp)
    800066b6:	e822                	sd	s0,16(sp)
    800066b8:	e426                	sd	s1,8(sp)
    800066ba:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800066bc:	0003b497          	auipc	s1,0x3b
    800066c0:	6f448493          	addi	s1,s1,1780 # 80041db0 <disk>
    800066c4:	0003c517          	auipc	a0,0x3c
    800066c8:	81450513          	addi	a0,a0,-2028 # 80041ed8 <disk+0x128>
    800066cc:	ffffa097          	auipc	ra,0xffffa
    800066d0:	64e080e7          	jalr	1614(ra) # 80000d1a <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800066d4:	10001737          	lui	a4,0x10001
    800066d8:	533c                	lw	a5,96(a4)
    800066da:	8b8d                	andi	a5,a5,3
    800066dc:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800066de:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800066e2:	689c                	ld	a5,16(s1)
    800066e4:	0204d703          	lhu	a4,32(s1)
    800066e8:	0027d783          	lhu	a5,2(a5)
    800066ec:	04f70863          	beq	a4,a5,8000673c <virtio_disk_intr+0x8a>
    __sync_synchronize();
    800066f0:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800066f4:	6898                	ld	a4,16(s1)
    800066f6:	0204d783          	lhu	a5,32(s1)
    800066fa:	8b9d                	andi	a5,a5,7
    800066fc:	078e                	slli	a5,a5,0x3
    800066fe:	97ba                	add	a5,a5,a4
    80006700:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006702:	00278713          	addi	a4,a5,2
    80006706:	0712                	slli	a4,a4,0x4
    80006708:	9726                	add	a4,a4,s1
    8000670a:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    8000670e:	e721                	bnez	a4,80006756 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006710:	0789                	addi	a5,a5,2
    80006712:	0792                	slli	a5,a5,0x4
    80006714:	97a6                	add	a5,a5,s1
    80006716:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80006718:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000671c:	ffffc097          	auipc	ra,0xffffc
    80006720:	c9c080e7          	jalr	-868(ra) # 800023b8 <wakeup>

    disk.used_idx += 1;
    80006724:	0204d783          	lhu	a5,32(s1)
    80006728:	2785                	addiw	a5,a5,1
    8000672a:	17c2                	slli	a5,a5,0x30
    8000672c:	93c1                	srli	a5,a5,0x30
    8000672e:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006732:	6898                	ld	a4,16(s1)
    80006734:	00275703          	lhu	a4,2(a4)
    80006738:	faf71ce3          	bne	a4,a5,800066f0 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    8000673c:	0003b517          	auipc	a0,0x3b
    80006740:	79c50513          	addi	a0,a0,1948 # 80041ed8 <disk+0x128>
    80006744:	ffffa097          	auipc	ra,0xffffa
    80006748:	68a080e7          	jalr	1674(ra) # 80000dce <release>
}
    8000674c:	60e2                	ld	ra,24(sp)
    8000674e:	6442                	ld	s0,16(sp)
    80006750:	64a2                	ld	s1,8(sp)
    80006752:	6105                	addi	sp,sp,32
    80006754:	8082                	ret
      panic("virtio_disk_intr status");
    80006756:	00002517          	auipc	a0,0x2
    8000675a:	23a50513          	addi	a0,a0,570 # 80008990 <syscalls+0x400>
    8000675e:	ffffa097          	auipc	ra,0xffffa
    80006762:	dde080e7          	jalr	-546(ra) # 8000053c <panic>
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
