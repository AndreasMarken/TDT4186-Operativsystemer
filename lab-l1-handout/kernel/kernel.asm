
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	91013103          	ld	sp,-1776(sp) # 80008910 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000054:	92070713          	addi	a4,a4,-1760 # 80008970 <timer_scratch>
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
    80000066:	bfe78793          	addi	a5,a5,-1026 # 80005c60 <timervec>
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
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdca1f>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	dcc78793          	addi	a5,a5,-564 # 80000e78 <main>
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
int
consolewrite(int user_src, uint64 src, int n)
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

  for(i = 0; i < n; i++){
    80000112:	04c05763          	blez	a2,80000160 <consolewrite+0x60>
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	addi	a0,s0,-65
    8000012a:	00002097          	auipc	ra,0x2
    8000012e:	388080e7          	jalr	904(ra) # 800024b2 <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
      break;
    uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	784080e7          	jalr	1924(ra) # 800008be <uartputc>
  for(i = 0; i < n; i++){
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
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4c>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	92650513          	addi	a0,a0,-1754 # 80010ab0 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a44080e7          	jalr	-1468(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	91648493          	addi	s1,s1,-1770 # 80010ab0 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	9a690913          	addi	s2,s2,-1626 # 80010b48 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
      if(killed(myproc())){
    800001c0:	00001097          	auipc	ra,0x1
    800001c4:	7ec080e7          	jalr	2028(ra) # 800019ac <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	134080e7          	jalr	308(ra) # 800022fc <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	e7e080e7          	jalr	-386(ra) # 80002054 <sleep>
    while(cons.r == cons.w){
    800001de:	0984a783          	lw	a5,152(s1)
    800001e2:	09c4a703          	lw	a4,156(s1)
    800001e6:	fcf70de3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ea:	0017871b          	addiw	a4,a5,1
    800001ee:	08e4ac23          	sw	a4,152(s1)
    800001f2:	07f7f713          	andi	a4,a5,127
    800001f6:	9726                	add	a4,a4,s1
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
    cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00002097          	auipc	ra,0x2
    80000216:	24a080e7          	jalr	586(ra) # 8000245c <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
    dst++;
    8000021e:	0a05                	addi	s4,s4,1
    --n;
    80000220:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	88a50513          	addi	a0,a0,-1910 # 80010ab0 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a5c080e7          	jalr	-1444(ra) # 80000c8a <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	87450513          	addi	a0,a0,-1932 # 80010ab0 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	a46080e7          	jalr	-1466(ra) # 80000c8a <release>
        return -1;
    8000024c:	557d                	li	a0,-1
}
    8000024e:	70a6                	ld	ra,104(sp)
    80000250:	7406                	ld	s0,96(sp)
    80000252:	64e6                	ld	s1,88(sp)
    80000254:	6946                	ld	s2,80(sp)
    80000256:	69a6                	ld	s3,72(sp)
    80000258:	6a06                	ld	s4,64(sp)
    8000025a:	7ae2                	ld	s5,56(sp)
    8000025c:	7b42                	ld	s6,48(sp)
    8000025e:	7ba2                	ld	s7,40(sp)
    80000260:	7c02                	ld	s8,32(sp)
    80000262:	6ce2                	ld	s9,24(sp)
    80000264:	6d42                	ld	s10,16(sp)
    80000266:	6165                	addi	sp,sp,112
    80000268:	8082                	ret
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	8cf72b23          	sw	a5,-1834(a4) # 80010b48 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	560080e7          	jalr	1376(ra) # 800007ec <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	54e080e7          	jalr	1358(ra) # 800007ec <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	542080e7          	jalr	1346(ra) # 800007ec <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	538080e7          	jalr	1336(ra) # 800007ec <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00010517          	auipc	a0,0x10
    800002d0:	7e450513          	addi	a0,a0,2020 # 80010ab0 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	902080e7          	jalr	-1790(ra) # 80000bd6 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	216080e7          	jalr	534(ra) # 80002508 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00010517          	auipc	a0,0x10
    800002fe:	7b650513          	addi	a0,a0,1974 # 80010ab0 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	988080e7          	jalr	-1656(ra) # 80000c8a <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031e:	00010717          	auipc	a4,0x10
    80000322:	79270713          	addi	a4,a4,1938 # 80010ab0 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00010797          	auipc	a5,0x10
    8000034c:	76878793          	addi	a5,a5,1896 # 80010ab0 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00010797          	auipc	a5,0x10
    8000037a:	7d27a783          	lw	a5,2002(a5) # 80010b48 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00010717          	auipc	a4,0x10
    8000038e:	72670713          	addi	a4,a4,1830 # 80010ab0 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00010497          	auipc	s1,0x10
    8000039e:	71648493          	addi	s1,s1,1814 # 80010ab0 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00010717          	auipc	a4,0x10
    800003da:	6da70713          	addi	a4,a4,1754 # 80010ab0 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00010717          	auipc	a4,0x10
    800003f0:	76f72223          	sw	a5,1892(a4) # 80010b50 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00010797          	auipc	a5,0x10
    80000416:	69e78793          	addi	a5,a5,1694 # 80010ab0 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00010797          	auipc	a5,0x10
    8000043a:	70c7ab23          	sw	a2,1814(a5) # 80010b4c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00010517          	auipc	a0,0x10
    80000442:	70a50513          	addi	a0,a0,1802 # 80010b48 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	c72080e7          	jalr	-910(ra) # 800020b8 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00010517          	auipc	a0,0x10
    80000464:	65050513          	addi	a0,a0,1616 # 80010ab0 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6de080e7          	jalr	1758(ra) # 80000b46 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32c080e7          	jalr	812(ra) # 8000079c <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00020797          	auipc	a5,0x20
    8000047c:	7d078793          	addi	a5,a5,2000 # 80020c48 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7670713          	addi	a4,a4,-906 # 80000100 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054763          	bltz	a0,80000538 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088c63          	beqz	a7,800004fe <printint+0x62>
    buf[i++] = '-';
    800004ea:	fe070793          	addi	a5,a4,-32
    800004ee:	00878733          	add	a4,a5,s0
    800004f2:	02d00793          	li	a5,45
    800004f6:	fef70823          	sb	a5,-16(a4)
    800004fa:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fe:	02e05763          	blez	a4,8000052c <printint+0x90>
    80000502:	fd040793          	addi	a5,s0,-48
    80000506:	00e784b3          	add	s1,a5,a4
    8000050a:	fff78913          	addi	s2,a5,-1
    8000050e:	993a                	add	s2,s2,a4
    80000510:	377d                	addiw	a4,a4,-1
    80000512:	1702                	slli	a4,a4,0x20
    80000514:	9301                	srli	a4,a4,0x20
    80000516:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051a:	fff4c503          	lbu	a0,-1(s1)
    8000051e:	00000097          	auipc	ra,0x0
    80000522:	d5e080e7          	jalr	-674(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000526:	14fd                	addi	s1,s1,-1
    80000528:	ff2499e3          	bne	s1,s2,8000051a <printint+0x7e>
}
    8000052c:	70a2                	ld	ra,40(sp)
    8000052e:	7402                	ld	s0,32(sp)
    80000530:	64e2                	ld	s1,24(sp)
    80000532:	6942                	ld	s2,16(sp)
    80000534:	6145                	addi	sp,sp,48
    80000536:	8082                	ret
    x = -xx;
    80000538:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053c:	4885                	li	a7,1
    x = -xx;
    8000053e:	bf95                	j	800004b2 <printint+0x16>

0000000080000540 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000540:	1101                	addi	sp,sp,-32
    80000542:	ec06                	sd	ra,24(sp)
    80000544:	e822                	sd	s0,16(sp)
    80000546:	e426                	sd	s1,8(sp)
    80000548:	1000                	addi	s0,sp,32
    8000054a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054c:	00010797          	auipc	a5,0x10
    80000550:	6207a223          	sw	zero,1572(a5) # 80010b70 <pr+0x18>
  printf("panic: ");
    80000554:	00008517          	auipc	a0,0x8
    80000558:	ac450513          	addi	a0,a0,-1340 # 80008018 <etext+0x18>
    8000055c:	00000097          	auipc	ra,0x0
    80000560:	02e080e7          	jalr	46(ra) # 8000058a <printf>
  printf(s);
    80000564:	8526                	mv	a0,s1
    80000566:	00000097          	auipc	ra,0x0
    8000056a:	024080e7          	jalr	36(ra) # 8000058a <printf>
  printf("\n");
    8000056e:	00008517          	auipc	a0,0x8
    80000572:	b5a50513          	addi	a0,a0,-1190 # 800080c8 <digits+0x88>
    80000576:	00000097          	auipc	ra,0x0
    8000057a:	014080e7          	jalr	20(ra) # 8000058a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057e:	4785                	li	a5,1
    80000580:	00008717          	auipc	a4,0x8
    80000584:	3af72823          	sw	a5,944(a4) # 80008930 <panicked>
  for(;;)
    80000588:	a001                	j	80000588 <panic+0x48>

000000008000058a <printf>:
{
    8000058a:	7131                	addi	sp,sp,-192
    8000058c:	fc86                	sd	ra,120(sp)
    8000058e:	f8a2                	sd	s0,112(sp)
    80000590:	f4a6                	sd	s1,104(sp)
    80000592:	f0ca                	sd	s2,96(sp)
    80000594:	ecce                	sd	s3,88(sp)
    80000596:	e8d2                	sd	s4,80(sp)
    80000598:	e4d6                	sd	s5,72(sp)
    8000059a:	e0da                	sd	s6,64(sp)
    8000059c:	fc5e                	sd	s7,56(sp)
    8000059e:	f862                	sd	s8,48(sp)
    800005a0:	f466                	sd	s9,40(sp)
    800005a2:	f06a                	sd	s10,32(sp)
    800005a4:	ec6e                	sd	s11,24(sp)
    800005a6:	0100                	addi	s0,sp,128
    800005a8:	8a2a                	mv	s4,a0
    800005aa:	e40c                	sd	a1,8(s0)
    800005ac:	e810                	sd	a2,16(s0)
    800005ae:	ec14                	sd	a3,24(s0)
    800005b0:	f018                	sd	a4,32(s0)
    800005b2:	f41c                	sd	a5,40(s0)
    800005b4:	03043823          	sd	a6,48(s0)
    800005b8:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005bc:	00010d97          	auipc	s11,0x10
    800005c0:	5b4dad83          	lw	s11,1460(s11) # 80010b70 <pr+0x18>
  if(locking)
    800005c4:	020d9b63          	bnez	s11,800005fa <printf+0x70>
  if (fmt == 0)
    800005c8:	040a0263          	beqz	s4,8000060c <printf+0x82>
  va_start(ap, fmt);
    800005cc:	00840793          	addi	a5,s0,8
    800005d0:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d4:	000a4503          	lbu	a0,0(s4)
    800005d8:	14050f63          	beqz	a0,80000736 <printf+0x1ac>
    800005dc:	4981                	li	s3,0
    if(c != '%'){
    800005de:	02500a93          	li	s5,37
    switch(c){
    800005e2:	07000b93          	li	s7,112
  consputc('x');
    800005e6:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e8:	00008b17          	auipc	s6,0x8
    800005ec:	a58b0b13          	addi	s6,s6,-1448 # 80008040 <digits>
    switch(c){
    800005f0:	07300c93          	li	s9,115
    800005f4:	06400c13          	li	s8,100
    800005f8:	a82d                	j	80000632 <printf+0xa8>
    acquire(&pr.lock);
    800005fa:	00010517          	auipc	a0,0x10
    800005fe:	55e50513          	addi	a0,a0,1374 # 80010b58 <pr>
    80000602:	00000097          	auipc	ra,0x0
    80000606:	5d4080e7          	jalr	1492(ra) # 80000bd6 <acquire>
    8000060a:	bf7d                	j	800005c8 <printf+0x3e>
    panic("null fmt");
    8000060c:	00008517          	auipc	a0,0x8
    80000610:	a1c50513          	addi	a0,a0,-1508 # 80008028 <etext+0x28>
    80000614:	00000097          	auipc	ra,0x0
    80000618:	f2c080e7          	jalr	-212(ra) # 80000540 <panic>
      consputc(c);
    8000061c:	00000097          	auipc	ra,0x0
    80000620:	c60080e7          	jalr	-928(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000624:	2985                	addiw	s3,s3,1
    80000626:	013a07b3          	add	a5,s4,s3
    8000062a:	0007c503          	lbu	a0,0(a5)
    8000062e:	10050463          	beqz	a0,80000736 <printf+0x1ac>
    if(c != '%'){
    80000632:	ff5515e3          	bne	a0,s5,8000061c <printf+0x92>
    c = fmt[++i] & 0xff;
    80000636:	2985                	addiw	s3,s3,1
    80000638:	013a07b3          	add	a5,s4,s3
    8000063c:	0007c783          	lbu	a5,0(a5)
    80000640:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000644:	cbed                	beqz	a5,80000736 <printf+0x1ac>
    switch(c){
    80000646:	05778a63          	beq	a5,s7,8000069a <printf+0x110>
    8000064a:	02fbf663          	bgeu	s7,a5,80000676 <printf+0xec>
    8000064e:	09978863          	beq	a5,s9,800006de <printf+0x154>
    80000652:	07800713          	li	a4,120
    80000656:	0ce79563          	bne	a5,a4,80000720 <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    8000065a:	f8843783          	ld	a5,-120(s0)
    8000065e:	00878713          	addi	a4,a5,8
    80000662:	f8e43423          	sd	a4,-120(s0)
    80000666:	4605                	li	a2,1
    80000668:	85ea                	mv	a1,s10
    8000066a:	4388                	lw	a0,0(a5)
    8000066c:	00000097          	auipc	ra,0x0
    80000670:	e30080e7          	jalr	-464(ra) # 8000049c <printint>
      break;
    80000674:	bf45                	j	80000624 <printf+0x9a>
    switch(c){
    80000676:	09578f63          	beq	a5,s5,80000714 <printf+0x18a>
    8000067a:	0b879363          	bne	a5,s8,80000720 <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067e:	f8843783          	ld	a5,-120(s0)
    80000682:	00878713          	addi	a4,a5,8
    80000686:	f8e43423          	sd	a4,-120(s0)
    8000068a:	4605                	li	a2,1
    8000068c:	45a9                	li	a1,10
    8000068e:	4388                	lw	a0,0(a5)
    80000690:	00000097          	auipc	ra,0x0
    80000694:	e0c080e7          	jalr	-500(ra) # 8000049c <printint>
      break;
    80000698:	b771                	j	80000624 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069a:	f8843783          	ld	a5,-120(s0)
    8000069e:	00878713          	addi	a4,a5,8
    800006a2:	f8e43423          	sd	a4,-120(s0)
    800006a6:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006aa:	03000513          	li	a0,48
    800006ae:	00000097          	auipc	ra,0x0
    800006b2:	bce080e7          	jalr	-1074(ra) # 8000027c <consputc>
  consputc('x');
    800006b6:	07800513          	li	a0,120
    800006ba:	00000097          	auipc	ra,0x0
    800006be:	bc2080e7          	jalr	-1086(ra) # 8000027c <consputc>
    800006c2:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c4:	03c95793          	srli	a5,s2,0x3c
    800006c8:	97da                	add	a5,a5,s6
    800006ca:	0007c503          	lbu	a0,0(a5)
    800006ce:	00000097          	auipc	ra,0x0
    800006d2:	bae080e7          	jalr	-1106(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d6:	0912                	slli	s2,s2,0x4
    800006d8:	34fd                	addiw	s1,s1,-1
    800006da:	f4ed                	bnez	s1,800006c4 <printf+0x13a>
    800006dc:	b7a1                	j	80000624 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	6384                	ld	s1,0(a5)
    800006ec:	cc89                	beqz	s1,80000706 <printf+0x17c>
      for(; *s; s++)
    800006ee:	0004c503          	lbu	a0,0(s1)
    800006f2:	d90d                	beqz	a0,80000624 <printf+0x9a>
        consputc(*s);
    800006f4:	00000097          	auipc	ra,0x0
    800006f8:	b88080e7          	jalr	-1144(ra) # 8000027c <consputc>
      for(; *s; s++)
    800006fc:	0485                	addi	s1,s1,1
    800006fe:	0004c503          	lbu	a0,0(s1)
    80000702:	f96d                	bnez	a0,800006f4 <printf+0x16a>
    80000704:	b705                	j	80000624 <printf+0x9a>
        s = "(null)";
    80000706:	00008497          	auipc	s1,0x8
    8000070a:	91a48493          	addi	s1,s1,-1766 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070e:	02800513          	li	a0,40
    80000712:	b7cd                	j	800006f4 <printf+0x16a>
      consputc('%');
    80000714:	8556                	mv	a0,s5
    80000716:	00000097          	auipc	ra,0x0
    8000071a:	b66080e7          	jalr	-1178(ra) # 8000027c <consputc>
      break;
    8000071e:	b719                	j	80000624 <printf+0x9a>
      consputc('%');
    80000720:	8556                	mv	a0,s5
    80000722:	00000097          	auipc	ra,0x0
    80000726:	b5a080e7          	jalr	-1190(ra) # 8000027c <consputc>
      consputc(c);
    8000072a:	8526                	mv	a0,s1
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b50080e7          	jalr	-1200(ra) # 8000027c <consputc>
      break;
    80000734:	bdc5                	j	80000624 <printf+0x9a>
  if(locking)
    80000736:	020d9163          	bnez	s11,80000758 <printf+0x1ce>
}
    8000073a:	70e6                	ld	ra,120(sp)
    8000073c:	7446                	ld	s0,112(sp)
    8000073e:	74a6                	ld	s1,104(sp)
    80000740:	7906                	ld	s2,96(sp)
    80000742:	69e6                	ld	s3,88(sp)
    80000744:	6a46                	ld	s4,80(sp)
    80000746:	6aa6                	ld	s5,72(sp)
    80000748:	6b06                	ld	s6,64(sp)
    8000074a:	7be2                	ld	s7,56(sp)
    8000074c:	7c42                	ld	s8,48(sp)
    8000074e:	7ca2                	ld	s9,40(sp)
    80000750:	7d02                	ld	s10,32(sp)
    80000752:	6de2                	ld	s11,24(sp)
    80000754:	6129                	addi	sp,sp,192
    80000756:	8082                	ret
    release(&pr.lock);
    80000758:	00010517          	auipc	a0,0x10
    8000075c:	40050513          	addi	a0,a0,1024 # 80010b58 <pr>
    80000760:	00000097          	auipc	ra,0x0
    80000764:	52a080e7          	jalr	1322(ra) # 80000c8a <release>
}
    80000768:	bfc9                	j	8000073a <printf+0x1b0>

000000008000076a <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076a:	1101                	addi	sp,sp,-32
    8000076c:	ec06                	sd	ra,24(sp)
    8000076e:	e822                	sd	s0,16(sp)
    80000770:	e426                	sd	s1,8(sp)
    80000772:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000774:	00010497          	auipc	s1,0x10
    80000778:	3e448493          	addi	s1,s1,996 # 80010b58 <pr>
    8000077c:	00008597          	auipc	a1,0x8
    80000780:	8bc58593          	addi	a1,a1,-1860 # 80008038 <etext+0x38>
    80000784:	8526                	mv	a0,s1
    80000786:	00000097          	auipc	ra,0x0
    8000078a:	3c0080e7          	jalr	960(ra) # 80000b46 <initlock>
  pr.locking = 1;
    8000078e:	4785                	li	a5,1
    80000790:	cc9c                	sw	a5,24(s1)
}
    80000792:	60e2                	ld	ra,24(sp)
    80000794:	6442                	ld	s0,16(sp)
    80000796:	64a2                	ld	s1,8(sp)
    80000798:	6105                	addi	sp,sp,32
    8000079a:	8082                	ret

000000008000079c <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079c:	1141                	addi	sp,sp,-16
    8000079e:	e406                	sd	ra,8(sp)
    800007a0:	e022                	sd	s0,0(sp)
    800007a2:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a4:	100007b7          	lui	a5,0x10000
    800007a8:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ac:	f8000713          	li	a4,-128
    800007b0:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b4:	470d                	li	a4,3
    800007b6:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007ba:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007be:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c2:	469d                	li	a3,7
    800007c4:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c8:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007cc:	00008597          	auipc	a1,0x8
    800007d0:	88c58593          	addi	a1,a1,-1908 # 80008058 <digits+0x18>
    800007d4:	00010517          	auipc	a0,0x10
    800007d8:	3a450513          	addi	a0,a0,932 # 80010b78 <uart_tx_lock>
    800007dc:	00000097          	auipc	ra,0x0
    800007e0:	36a080e7          	jalr	874(ra) # 80000b46 <initlock>
}
    800007e4:	60a2                	ld	ra,8(sp)
    800007e6:	6402                	ld	s0,0(sp)
    800007e8:	0141                	addi	sp,sp,16
    800007ea:	8082                	ret

00000000800007ec <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ec:	1101                	addi	sp,sp,-32
    800007ee:	ec06                	sd	ra,24(sp)
    800007f0:	e822                	sd	s0,16(sp)
    800007f2:	e426                	sd	s1,8(sp)
    800007f4:	1000                	addi	s0,sp,32
    800007f6:	84aa                	mv	s1,a0
  push_off();
    800007f8:	00000097          	auipc	ra,0x0
    800007fc:	392080e7          	jalr	914(ra) # 80000b8a <push_off>

  if(panicked){
    80000800:	00008797          	auipc	a5,0x8
    80000804:	1307a783          	lw	a5,304(a5) # 80008930 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000808:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080c:	c391                	beqz	a5,80000810 <uartputc_sync+0x24>
    for(;;)
    8000080e:	a001                	j	8000080e <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000810:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000814:	0207f793          	andi	a5,a5,32
    80000818:	dfe5                	beqz	a5,80000810 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000081a:	0ff4f513          	zext.b	a0,s1
    8000081e:	100007b7          	lui	a5,0x10000
    80000822:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000826:	00000097          	auipc	ra,0x0
    8000082a:	404080e7          	jalr	1028(ra) # 80000c2a <pop_off>
}
    8000082e:	60e2                	ld	ra,24(sp)
    80000830:	6442                	ld	s0,16(sp)
    80000832:	64a2                	ld	s1,8(sp)
    80000834:	6105                	addi	sp,sp,32
    80000836:	8082                	ret

0000000080000838 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000838:	00008797          	auipc	a5,0x8
    8000083c:	1007b783          	ld	a5,256(a5) # 80008938 <uart_tx_r>
    80000840:	00008717          	auipc	a4,0x8
    80000844:	10073703          	ld	a4,256(a4) # 80008940 <uart_tx_w>
    80000848:	06f70a63          	beq	a4,a5,800008bc <uartstart+0x84>
{
    8000084c:	7139                	addi	sp,sp,-64
    8000084e:	fc06                	sd	ra,56(sp)
    80000850:	f822                	sd	s0,48(sp)
    80000852:	f426                	sd	s1,40(sp)
    80000854:	f04a                	sd	s2,32(sp)
    80000856:	ec4e                	sd	s3,24(sp)
    80000858:	e852                	sd	s4,16(sp)
    8000085a:	e456                	sd	s5,8(sp)
    8000085c:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085e:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000862:	00010a17          	auipc	s4,0x10
    80000866:	316a0a13          	addi	s4,s4,790 # 80010b78 <uart_tx_lock>
    uart_tx_r += 1;
    8000086a:	00008497          	auipc	s1,0x8
    8000086e:	0ce48493          	addi	s1,s1,206 # 80008938 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000872:	00008997          	auipc	s3,0x8
    80000876:	0ce98993          	addi	s3,s3,206 # 80008940 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000087a:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087e:	02077713          	andi	a4,a4,32
    80000882:	c705                	beqz	a4,800008aa <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000884:	01f7f713          	andi	a4,a5,31
    80000888:	9752                	add	a4,a4,s4
    8000088a:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088e:	0785                	addi	a5,a5,1
    80000890:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000892:	8526                	mv	a0,s1
    80000894:	00002097          	auipc	ra,0x2
    80000898:	824080e7          	jalr	-2012(ra) # 800020b8 <wakeup>
    
    WriteReg(THR, c);
    8000089c:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008a0:	609c                	ld	a5,0(s1)
    800008a2:	0009b703          	ld	a4,0(s3)
    800008a6:	fcf71ae3          	bne	a4,a5,8000087a <uartstart+0x42>
  }
}
    800008aa:	70e2                	ld	ra,56(sp)
    800008ac:	7442                	ld	s0,48(sp)
    800008ae:	74a2                	ld	s1,40(sp)
    800008b0:	7902                	ld	s2,32(sp)
    800008b2:	69e2                	ld	s3,24(sp)
    800008b4:	6a42                	ld	s4,16(sp)
    800008b6:	6aa2                	ld	s5,8(sp)
    800008b8:	6121                	addi	sp,sp,64
    800008ba:	8082                	ret
    800008bc:	8082                	ret

00000000800008be <uartputc>:
{
    800008be:	7179                	addi	sp,sp,-48
    800008c0:	f406                	sd	ra,40(sp)
    800008c2:	f022                	sd	s0,32(sp)
    800008c4:	ec26                	sd	s1,24(sp)
    800008c6:	e84a                	sd	s2,16(sp)
    800008c8:	e44e                	sd	s3,8(sp)
    800008ca:	e052                	sd	s4,0(sp)
    800008cc:	1800                	addi	s0,sp,48
    800008ce:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008d0:	00010517          	auipc	a0,0x10
    800008d4:	2a850513          	addi	a0,a0,680 # 80010b78 <uart_tx_lock>
    800008d8:	00000097          	auipc	ra,0x0
    800008dc:	2fe080e7          	jalr	766(ra) # 80000bd6 <acquire>
  if(panicked){
    800008e0:	00008797          	auipc	a5,0x8
    800008e4:	0507a783          	lw	a5,80(a5) # 80008930 <panicked>
    800008e8:	e7c9                	bnez	a5,80000972 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008ea:	00008717          	auipc	a4,0x8
    800008ee:	05673703          	ld	a4,86(a4) # 80008940 <uart_tx_w>
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	0467b783          	ld	a5,70(a5) # 80008938 <uart_tx_r>
    800008fa:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fe:	00010997          	auipc	s3,0x10
    80000902:	27a98993          	addi	s3,s3,634 # 80010b78 <uart_tx_lock>
    80000906:	00008497          	auipc	s1,0x8
    8000090a:	03248493          	addi	s1,s1,50 # 80008938 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090e:	00008917          	auipc	s2,0x8
    80000912:	03290913          	addi	s2,s2,50 # 80008940 <uart_tx_w>
    80000916:	00e79f63          	bne	a5,a4,80000934 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000091a:	85ce                	mv	a1,s3
    8000091c:	8526                	mv	a0,s1
    8000091e:	00001097          	auipc	ra,0x1
    80000922:	736080e7          	jalr	1846(ra) # 80002054 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000926:	00093703          	ld	a4,0(s2)
    8000092a:	609c                	ld	a5,0(s1)
    8000092c:	02078793          	addi	a5,a5,32
    80000930:	fee785e3          	beq	a5,a4,8000091a <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000934:	00010497          	auipc	s1,0x10
    80000938:	24448493          	addi	s1,s1,580 # 80010b78 <uart_tx_lock>
    8000093c:	01f77793          	andi	a5,a4,31
    80000940:	97a6                	add	a5,a5,s1
    80000942:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000946:	0705                	addi	a4,a4,1
    80000948:	00008797          	auipc	a5,0x8
    8000094c:	fee7bc23          	sd	a4,-8(a5) # 80008940 <uart_tx_w>
  uartstart();
    80000950:	00000097          	auipc	ra,0x0
    80000954:	ee8080e7          	jalr	-280(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    80000958:	8526                	mv	a0,s1
    8000095a:	00000097          	auipc	ra,0x0
    8000095e:	330080e7          	jalr	816(ra) # 80000c8a <release>
}
    80000962:	70a2                	ld	ra,40(sp)
    80000964:	7402                	ld	s0,32(sp)
    80000966:	64e2                	ld	s1,24(sp)
    80000968:	6942                	ld	s2,16(sp)
    8000096a:	69a2                	ld	s3,8(sp)
    8000096c:	6a02                	ld	s4,0(sp)
    8000096e:	6145                	addi	sp,sp,48
    80000970:	8082                	ret
    for(;;)
    80000972:	a001                	j	80000972 <uartputc+0xb4>

0000000080000974 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000974:	1141                	addi	sp,sp,-16
    80000976:	e422                	sd	s0,8(sp)
    80000978:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000097a:	100007b7          	lui	a5,0x10000
    8000097e:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000982:	8b85                	andi	a5,a5,1
    80000984:	cb81                	beqz	a5,80000994 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    8000098e:	6422                	ld	s0,8(sp)
    80000990:	0141                	addi	sp,sp,16
    80000992:	8082                	ret
    return -1;
    80000994:	557d                	li	a0,-1
    80000996:	bfe5                	j	8000098e <uartgetc+0x1a>

0000000080000998 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    80000998:	1101                	addi	sp,sp,-32
    8000099a:	ec06                	sd	ra,24(sp)
    8000099c:	e822                	sd	s0,16(sp)
    8000099e:	e426                	sd	s1,8(sp)
    800009a0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a2:	54fd                	li	s1,-1
    800009a4:	a029                	j	800009ae <uartintr+0x16>
      break;
    consoleintr(c);
    800009a6:	00000097          	auipc	ra,0x0
    800009aa:	918080e7          	jalr	-1768(ra) # 800002be <consoleintr>
    int c = uartgetc();
    800009ae:	00000097          	auipc	ra,0x0
    800009b2:	fc6080e7          	jalr	-58(ra) # 80000974 <uartgetc>
    if(c == -1)
    800009b6:	fe9518e3          	bne	a0,s1,800009a6 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ba:	00010497          	auipc	s1,0x10
    800009be:	1be48493          	addi	s1,s1,446 # 80010b78 <uart_tx_lock>
    800009c2:	8526                	mv	a0,s1
    800009c4:	00000097          	auipc	ra,0x0
    800009c8:	212080e7          	jalr	530(ra) # 80000bd6 <acquire>
  uartstart();
    800009cc:	00000097          	auipc	ra,0x0
    800009d0:	e6c080e7          	jalr	-404(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    800009d4:	8526                	mv	a0,s1
    800009d6:	00000097          	auipc	ra,0x0
    800009da:	2b4080e7          	jalr	692(ra) # 80000c8a <release>
}
    800009de:	60e2                	ld	ra,24(sp)
    800009e0:	6442                	ld	s0,16(sp)
    800009e2:	64a2                	ld	s1,8(sp)
    800009e4:	6105                	addi	sp,sp,32
    800009e6:	8082                	ret

00000000800009e8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009e8:	1101                	addi	sp,sp,-32
    800009ea:	ec06                	sd	ra,24(sp)
    800009ec:	e822                	sd	s0,16(sp)
    800009ee:	e426                	sd	s1,8(sp)
    800009f0:	e04a                	sd	s2,0(sp)
    800009f2:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f4:	03451793          	slli	a5,a0,0x34
    800009f8:	ebb9                	bnez	a5,80000a4e <kfree+0x66>
    800009fa:	84aa                	mv	s1,a0
    800009fc:	00021797          	auipc	a5,0x21
    80000a00:	3e478793          	addi	a5,a5,996 # 80021de0 <end>
    80000a04:	04f56563          	bltu	a0,a5,80000a4e <kfree+0x66>
    80000a08:	47c5                	li	a5,17
    80000a0a:	07ee                	slli	a5,a5,0x1b
    80000a0c:	04f57163          	bgeu	a0,a5,80000a4e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a10:	6605                	lui	a2,0x1
    80000a12:	4585                	li	a1,1
    80000a14:	00000097          	auipc	ra,0x0
    80000a18:	2be080e7          	jalr	702(ra) # 80000cd2 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a1c:	00010917          	auipc	s2,0x10
    80000a20:	19490913          	addi	s2,s2,404 # 80010bb0 <kmem>
    80000a24:	854a                	mv	a0,s2
    80000a26:	00000097          	auipc	ra,0x0
    80000a2a:	1b0080e7          	jalr	432(ra) # 80000bd6 <acquire>
  r->next = kmem.freelist;
    80000a2e:	01893783          	ld	a5,24(s2)
    80000a32:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a34:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a38:	854a                	mv	a0,s2
    80000a3a:	00000097          	auipc	ra,0x0
    80000a3e:	250080e7          	jalr	592(ra) # 80000c8a <release>
}
    80000a42:	60e2                	ld	ra,24(sp)
    80000a44:	6442                	ld	s0,16(sp)
    80000a46:	64a2                	ld	s1,8(sp)
    80000a48:	6902                	ld	s2,0(sp)
    80000a4a:	6105                	addi	sp,sp,32
    80000a4c:	8082                	ret
    panic("kfree");
    80000a4e:	00007517          	auipc	a0,0x7
    80000a52:	61250513          	addi	a0,a0,1554 # 80008060 <digits+0x20>
    80000a56:	00000097          	auipc	ra,0x0
    80000a5a:	aea080e7          	jalr	-1302(ra) # 80000540 <panic>

0000000080000a5e <freerange>:
{
    80000a5e:	7179                	addi	sp,sp,-48
    80000a60:	f406                	sd	ra,40(sp)
    80000a62:	f022                	sd	s0,32(sp)
    80000a64:	ec26                	sd	s1,24(sp)
    80000a66:	e84a                	sd	s2,16(sp)
    80000a68:	e44e                	sd	s3,8(sp)
    80000a6a:	e052                	sd	s4,0(sp)
    80000a6c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a6e:	6785                	lui	a5,0x1
    80000a70:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000a74:	00e504b3          	add	s1,a0,a4
    80000a78:	777d                	lui	a4,0xfffff
    80000a7a:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a7c:	94be                	add	s1,s1,a5
    80000a7e:	0095ee63          	bltu	a1,s1,80000a9a <freerange+0x3c>
    80000a82:	892e                	mv	s2,a1
    kfree(p);
    80000a84:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a86:	6985                	lui	s3,0x1
    kfree(p);
    80000a88:	01448533          	add	a0,s1,s4
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	f5c080e7          	jalr	-164(ra) # 800009e8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	94ce                	add	s1,s1,s3
    80000a96:	fe9979e3          	bgeu	s2,s1,80000a88 <freerange+0x2a>
}
    80000a9a:	70a2                	ld	ra,40(sp)
    80000a9c:	7402                	ld	s0,32(sp)
    80000a9e:	64e2                	ld	s1,24(sp)
    80000aa0:	6942                	ld	s2,16(sp)
    80000aa2:	69a2                	ld	s3,8(sp)
    80000aa4:	6a02                	ld	s4,0(sp)
    80000aa6:	6145                	addi	sp,sp,48
    80000aa8:	8082                	ret

0000000080000aaa <kinit>:
{
    80000aaa:	1141                	addi	sp,sp,-16
    80000aac:	e406                	sd	ra,8(sp)
    80000aae:	e022                	sd	s0,0(sp)
    80000ab0:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ab2:	00007597          	auipc	a1,0x7
    80000ab6:	5b658593          	addi	a1,a1,1462 # 80008068 <digits+0x28>
    80000aba:	00010517          	auipc	a0,0x10
    80000abe:	0f650513          	addi	a0,a0,246 # 80010bb0 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00021517          	auipc	a0,0x21
    80000ad2:	31250513          	addi	a0,a0,786 # 80021de0 <end>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	f88080e7          	jalr	-120(ra) # 80000a5e <freerange>
}
    80000ade:	60a2                	ld	ra,8(sp)
    80000ae0:	6402                	ld	s0,0(sp)
    80000ae2:	0141                	addi	sp,sp,16
    80000ae4:	8082                	ret

0000000080000ae6 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae6:	1101                	addi	sp,sp,-32
    80000ae8:	ec06                	sd	ra,24(sp)
    80000aea:	e822                	sd	s0,16(sp)
    80000aec:	e426                	sd	s1,8(sp)
    80000aee:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000af0:	00010497          	auipc	s1,0x10
    80000af4:	0c048493          	addi	s1,s1,192 # 80010bb0 <kmem>
    80000af8:	8526                	mv	a0,s1
    80000afa:	00000097          	auipc	ra,0x0
    80000afe:	0dc080e7          	jalr	220(ra) # 80000bd6 <acquire>
  r = kmem.freelist;
    80000b02:	6c84                	ld	s1,24(s1)
  if(r)
    80000b04:	c885                	beqz	s1,80000b34 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b06:	609c                	ld	a5,0(s1)
    80000b08:	00010517          	auipc	a0,0x10
    80000b0c:	0a850513          	addi	a0,a0,168 # 80010bb0 <kmem>
    80000b10:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b12:	00000097          	auipc	ra,0x0
    80000b16:	178080e7          	jalr	376(ra) # 80000c8a <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b1a:	6605                	lui	a2,0x1
    80000b1c:	4595                	li	a1,5
    80000b1e:	8526                	mv	a0,s1
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	1b2080e7          	jalr	434(ra) # 80000cd2 <memset>
  return (void*)r;
}
    80000b28:	8526                	mv	a0,s1
    80000b2a:	60e2                	ld	ra,24(sp)
    80000b2c:	6442                	ld	s0,16(sp)
    80000b2e:	64a2                	ld	s1,8(sp)
    80000b30:	6105                	addi	sp,sp,32
    80000b32:	8082                	ret
  release(&kmem.lock);
    80000b34:	00010517          	auipc	a0,0x10
    80000b38:	07c50513          	addi	a0,a0,124 # 80010bb0 <kmem>
    80000b3c:	00000097          	auipc	ra,0x0
    80000b40:	14e080e7          	jalr	334(ra) # 80000c8a <release>
  if(r)
    80000b44:	b7d5                	j	80000b28 <kalloc+0x42>

0000000080000b46 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b46:	1141                	addi	sp,sp,-16
    80000b48:	e422                	sd	s0,8(sp)
    80000b4a:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b4c:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b4e:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b52:	00053823          	sd	zero,16(a0)
}
    80000b56:	6422                	ld	s0,8(sp)
    80000b58:	0141                	addi	sp,sp,16
    80000b5a:	8082                	ret

0000000080000b5c <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b5c:	411c                	lw	a5,0(a0)
    80000b5e:	e399                	bnez	a5,80000b64 <holding+0x8>
    80000b60:	4501                	li	a0,0
  return r;
}
    80000b62:	8082                	ret
{
    80000b64:	1101                	addi	sp,sp,-32
    80000b66:	ec06                	sd	ra,24(sp)
    80000b68:	e822                	sd	s0,16(sp)
    80000b6a:	e426                	sd	s1,8(sp)
    80000b6c:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b6e:	6904                	ld	s1,16(a0)
    80000b70:	00001097          	auipc	ra,0x1
    80000b74:	e20080e7          	jalr	-480(ra) # 80001990 <mycpu>
    80000b78:	40a48533          	sub	a0,s1,a0
    80000b7c:	00153513          	seqz	a0,a0
}
    80000b80:	60e2                	ld	ra,24(sp)
    80000b82:	6442                	ld	s0,16(sp)
    80000b84:	64a2                	ld	s1,8(sp)
    80000b86:	6105                	addi	sp,sp,32
    80000b88:	8082                	ret

0000000080000b8a <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b8a:	1101                	addi	sp,sp,-32
    80000b8c:	ec06                	sd	ra,24(sp)
    80000b8e:	e822                	sd	s0,16(sp)
    80000b90:	e426                	sd	s1,8(sp)
    80000b92:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b94:	100024f3          	csrr	s1,sstatus
    80000b98:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b9c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b9e:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000ba2:	00001097          	auipc	ra,0x1
    80000ba6:	dee080e7          	jalr	-530(ra) # 80001990 <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	de2080e7          	jalr	-542(ra) # 80001990 <mycpu>
    80000bb6:	5d3c                	lw	a5,120(a0)
    80000bb8:	2785                	addiw	a5,a5,1
    80000bba:	dd3c                	sw	a5,120(a0)
}
    80000bbc:	60e2                	ld	ra,24(sp)
    80000bbe:	6442                	ld	s0,16(sp)
    80000bc0:	64a2                	ld	s1,8(sp)
    80000bc2:	6105                	addi	sp,sp,32
    80000bc4:	8082                	ret
    mycpu()->intena = old;
    80000bc6:	00001097          	auipc	ra,0x1
    80000bca:	dca080e7          	jalr	-566(ra) # 80001990 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bce:	8085                	srli	s1,s1,0x1
    80000bd0:	8885                	andi	s1,s1,1
    80000bd2:	dd64                	sw	s1,124(a0)
    80000bd4:	bfe9                	j	80000bae <push_off+0x24>

0000000080000bd6 <acquire>:
{
    80000bd6:	1101                	addi	sp,sp,-32
    80000bd8:	ec06                	sd	ra,24(sp)
    80000bda:	e822                	sd	s0,16(sp)
    80000bdc:	e426                	sd	s1,8(sp)
    80000bde:	1000                	addi	s0,sp,32
    80000be0:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000be2:	00000097          	auipc	ra,0x0
    80000be6:	fa8080e7          	jalr	-88(ra) # 80000b8a <push_off>
  if(holding(lk))
    80000bea:	8526                	mv	a0,s1
    80000bec:	00000097          	auipc	ra,0x0
    80000bf0:	f70080e7          	jalr	-144(ra) # 80000b5c <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf4:	4705                	li	a4,1
  if(holding(lk))
    80000bf6:	e115                	bnez	a0,80000c1a <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf8:	87ba                	mv	a5,a4
    80000bfa:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bfe:	2781                	sext.w	a5,a5
    80000c00:	ffe5                	bnez	a5,80000bf8 <acquire+0x22>
  __sync_synchronize();
    80000c02:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c06:	00001097          	auipc	ra,0x1
    80000c0a:	d8a080e7          	jalr	-630(ra) # 80001990 <mycpu>
    80000c0e:	e888                	sd	a0,16(s1)
}
    80000c10:	60e2                	ld	ra,24(sp)
    80000c12:	6442                	ld	s0,16(sp)
    80000c14:	64a2                	ld	s1,8(sp)
    80000c16:	6105                	addi	sp,sp,32
    80000c18:	8082                	ret
    panic("acquire");
    80000c1a:	00007517          	auipc	a0,0x7
    80000c1e:	45650513          	addi	a0,a0,1110 # 80008070 <digits+0x30>
    80000c22:	00000097          	auipc	ra,0x0
    80000c26:	91e080e7          	jalr	-1762(ra) # 80000540 <panic>

0000000080000c2a <pop_off>:

void
pop_off(void)
{
    80000c2a:	1141                	addi	sp,sp,-16
    80000c2c:	e406                	sd	ra,8(sp)
    80000c2e:	e022                	sd	s0,0(sp)
    80000c30:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c32:	00001097          	auipc	ra,0x1
    80000c36:	d5e080e7          	jalr	-674(ra) # 80001990 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c3a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c3e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c40:	e78d                	bnez	a5,80000c6a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c42:	5d3c                	lw	a5,120(a0)
    80000c44:	02f05b63          	blez	a5,80000c7a <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c48:	37fd                	addiw	a5,a5,-1
    80000c4a:	0007871b          	sext.w	a4,a5
    80000c4e:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c50:	eb09                	bnez	a4,80000c62 <pop_off+0x38>
    80000c52:	5d7c                	lw	a5,124(a0)
    80000c54:	c799                	beqz	a5,80000c62 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c56:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c5a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c5e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c62:	60a2                	ld	ra,8(sp)
    80000c64:	6402                	ld	s0,0(sp)
    80000c66:	0141                	addi	sp,sp,16
    80000c68:	8082                	ret
    panic("pop_off - interruptible");
    80000c6a:	00007517          	auipc	a0,0x7
    80000c6e:	40e50513          	addi	a0,a0,1038 # 80008078 <digits+0x38>
    80000c72:	00000097          	auipc	ra,0x0
    80000c76:	8ce080e7          	jalr	-1842(ra) # 80000540 <panic>
    panic("pop_off");
    80000c7a:	00007517          	auipc	a0,0x7
    80000c7e:	41650513          	addi	a0,a0,1046 # 80008090 <digits+0x50>
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	8be080e7          	jalr	-1858(ra) # 80000540 <panic>

0000000080000c8a <release>:
{
    80000c8a:	1101                	addi	sp,sp,-32
    80000c8c:	ec06                	sd	ra,24(sp)
    80000c8e:	e822                	sd	s0,16(sp)
    80000c90:	e426                	sd	s1,8(sp)
    80000c92:	1000                	addi	s0,sp,32
    80000c94:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	ec6080e7          	jalr	-314(ra) # 80000b5c <holding>
    80000c9e:	c115                	beqz	a0,80000cc2 <release+0x38>
  lk->cpu = 0;
    80000ca0:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ca4:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca8:	0f50000f          	fence	iorw,ow
    80000cac:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cb0:	00000097          	auipc	ra,0x0
    80000cb4:	f7a080e7          	jalr	-134(ra) # 80000c2a <pop_off>
}
    80000cb8:	60e2                	ld	ra,24(sp)
    80000cba:	6442                	ld	s0,16(sp)
    80000cbc:	64a2                	ld	s1,8(sp)
    80000cbe:	6105                	addi	sp,sp,32
    80000cc0:	8082                	ret
    panic("release");
    80000cc2:	00007517          	auipc	a0,0x7
    80000cc6:	3d650513          	addi	a0,a0,982 # 80008098 <digits+0x58>
    80000cca:	00000097          	auipc	ra,0x0
    80000cce:	876080e7          	jalr	-1930(ra) # 80000540 <panic>

0000000080000cd2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cd2:	1141                	addi	sp,sp,-16
    80000cd4:	e422                	sd	s0,8(sp)
    80000cd6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd8:	ca19                	beqz	a2,80000cee <memset+0x1c>
    80000cda:	87aa                	mv	a5,a0
    80000cdc:	1602                	slli	a2,a2,0x20
    80000cde:	9201                	srli	a2,a2,0x20
    80000ce0:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000ce4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce8:	0785                	addi	a5,a5,1
    80000cea:	fee79de3          	bne	a5,a4,80000ce4 <memset+0x12>
  }
  return dst;
}
    80000cee:	6422                	ld	s0,8(sp)
    80000cf0:	0141                	addi	sp,sp,16
    80000cf2:	8082                	ret

0000000080000cf4 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cf4:	1141                	addi	sp,sp,-16
    80000cf6:	e422                	sd	s0,8(sp)
    80000cf8:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cfa:	ca05                	beqz	a2,80000d2a <memcmp+0x36>
    80000cfc:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000d00:	1682                	slli	a3,a3,0x20
    80000d02:	9281                	srli	a3,a3,0x20
    80000d04:	0685                	addi	a3,a3,1
    80000d06:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d08:	00054783          	lbu	a5,0(a0)
    80000d0c:	0005c703          	lbu	a4,0(a1)
    80000d10:	00e79863          	bne	a5,a4,80000d20 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d14:	0505                	addi	a0,a0,1
    80000d16:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d18:	fed518e3          	bne	a0,a3,80000d08 <memcmp+0x14>
  }

  return 0;
    80000d1c:	4501                	li	a0,0
    80000d1e:	a019                	j	80000d24 <memcmp+0x30>
      return *s1 - *s2;
    80000d20:	40e7853b          	subw	a0,a5,a4
}
    80000d24:	6422                	ld	s0,8(sp)
    80000d26:	0141                	addi	sp,sp,16
    80000d28:	8082                	ret
  return 0;
    80000d2a:	4501                	li	a0,0
    80000d2c:	bfe5                	j	80000d24 <memcmp+0x30>

0000000080000d2e <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d2e:	1141                	addi	sp,sp,-16
    80000d30:	e422                	sd	s0,8(sp)
    80000d32:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d34:	c205                	beqz	a2,80000d54 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d36:	02a5e263          	bltu	a1,a0,80000d5a <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d3a:	1602                	slli	a2,a2,0x20
    80000d3c:	9201                	srli	a2,a2,0x20
    80000d3e:	00c587b3          	add	a5,a1,a2
{
    80000d42:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d44:	0585                	addi	a1,a1,1
    80000d46:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffdd221>
    80000d48:	fff5c683          	lbu	a3,-1(a1)
    80000d4c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d50:	fef59ae3          	bne	a1,a5,80000d44 <memmove+0x16>

  return dst;
}
    80000d54:	6422                	ld	s0,8(sp)
    80000d56:	0141                	addi	sp,sp,16
    80000d58:	8082                	ret
  if(s < d && s + n > d){
    80000d5a:	02061693          	slli	a3,a2,0x20
    80000d5e:	9281                	srli	a3,a3,0x20
    80000d60:	00d58733          	add	a4,a1,a3
    80000d64:	fce57be3          	bgeu	a0,a4,80000d3a <memmove+0xc>
    d += n;
    80000d68:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d6a:	fff6079b          	addiw	a5,a2,-1
    80000d6e:	1782                	slli	a5,a5,0x20
    80000d70:	9381                	srli	a5,a5,0x20
    80000d72:	fff7c793          	not	a5,a5
    80000d76:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d78:	177d                	addi	a4,a4,-1
    80000d7a:	16fd                	addi	a3,a3,-1
    80000d7c:	00074603          	lbu	a2,0(a4)
    80000d80:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d84:	fee79ae3          	bne	a5,a4,80000d78 <memmove+0x4a>
    80000d88:	b7f1                	j	80000d54 <memmove+0x26>

0000000080000d8a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d8a:	1141                	addi	sp,sp,-16
    80000d8c:	e406                	sd	ra,8(sp)
    80000d8e:	e022                	sd	s0,0(sp)
    80000d90:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d92:	00000097          	auipc	ra,0x0
    80000d96:	f9c080e7          	jalr	-100(ra) # 80000d2e <memmove>
}
    80000d9a:	60a2                	ld	ra,8(sp)
    80000d9c:	6402                	ld	s0,0(sp)
    80000d9e:	0141                	addi	sp,sp,16
    80000da0:	8082                	ret

0000000080000da2 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000da2:	1141                	addi	sp,sp,-16
    80000da4:	e422                	sd	s0,8(sp)
    80000da6:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da8:	ce11                	beqz	a2,80000dc4 <strncmp+0x22>
    80000daa:	00054783          	lbu	a5,0(a0)
    80000dae:	cf89                	beqz	a5,80000dc8 <strncmp+0x26>
    80000db0:	0005c703          	lbu	a4,0(a1)
    80000db4:	00f71a63          	bne	a4,a5,80000dc8 <strncmp+0x26>
    n--, p++, q++;
    80000db8:	367d                	addiw	a2,a2,-1
    80000dba:	0505                	addi	a0,a0,1
    80000dbc:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dbe:	f675                	bnez	a2,80000daa <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dc0:	4501                	li	a0,0
    80000dc2:	a809                	j	80000dd4 <strncmp+0x32>
    80000dc4:	4501                	li	a0,0
    80000dc6:	a039                	j	80000dd4 <strncmp+0x32>
  if(n == 0)
    80000dc8:	ca09                	beqz	a2,80000dda <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dca:	00054503          	lbu	a0,0(a0)
    80000dce:	0005c783          	lbu	a5,0(a1)
    80000dd2:	9d1d                	subw	a0,a0,a5
}
    80000dd4:	6422                	ld	s0,8(sp)
    80000dd6:	0141                	addi	sp,sp,16
    80000dd8:	8082                	ret
    return 0;
    80000dda:	4501                	li	a0,0
    80000ddc:	bfe5                	j	80000dd4 <strncmp+0x32>

0000000080000dde <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dde:	1141                	addi	sp,sp,-16
    80000de0:	e422                	sd	s0,8(sp)
    80000de2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000de4:	872a                	mv	a4,a0
    80000de6:	8832                	mv	a6,a2
    80000de8:	367d                	addiw	a2,a2,-1
    80000dea:	01005963          	blez	a6,80000dfc <strncpy+0x1e>
    80000dee:	0705                	addi	a4,a4,1
    80000df0:	0005c783          	lbu	a5,0(a1)
    80000df4:	fef70fa3          	sb	a5,-1(a4)
    80000df8:	0585                	addi	a1,a1,1
    80000dfa:	f7f5                	bnez	a5,80000de6 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000dfc:	86ba                	mv	a3,a4
    80000dfe:	00c05c63          	blez	a2,80000e16 <strncpy+0x38>
    *s++ = 0;
    80000e02:	0685                	addi	a3,a3,1
    80000e04:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e08:	40d707bb          	subw	a5,a4,a3
    80000e0c:	37fd                	addiw	a5,a5,-1
    80000e0e:	010787bb          	addw	a5,a5,a6
    80000e12:	fef048e3          	bgtz	a5,80000e02 <strncpy+0x24>
  return os;
}
    80000e16:	6422                	ld	s0,8(sp)
    80000e18:	0141                	addi	sp,sp,16
    80000e1a:	8082                	ret

0000000080000e1c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e1c:	1141                	addi	sp,sp,-16
    80000e1e:	e422                	sd	s0,8(sp)
    80000e20:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e22:	02c05363          	blez	a2,80000e48 <safestrcpy+0x2c>
    80000e26:	fff6069b          	addiw	a3,a2,-1
    80000e2a:	1682                	slli	a3,a3,0x20
    80000e2c:	9281                	srli	a3,a3,0x20
    80000e2e:	96ae                	add	a3,a3,a1
    80000e30:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e32:	00d58963          	beq	a1,a3,80000e44 <safestrcpy+0x28>
    80000e36:	0585                	addi	a1,a1,1
    80000e38:	0785                	addi	a5,a5,1
    80000e3a:	fff5c703          	lbu	a4,-1(a1)
    80000e3e:	fee78fa3          	sb	a4,-1(a5)
    80000e42:	fb65                	bnez	a4,80000e32 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e44:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e48:	6422                	ld	s0,8(sp)
    80000e4a:	0141                	addi	sp,sp,16
    80000e4c:	8082                	ret

0000000080000e4e <strlen>:

int
strlen(const char *s)
{
    80000e4e:	1141                	addi	sp,sp,-16
    80000e50:	e422                	sd	s0,8(sp)
    80000e52:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e54:	00054783          	lbu	a5,0(a0)
    80000e58:	cf91                	beqz	a5,80000e74 <strlen+0x26>
    80000e5a:	0505                	addi	a0,a0,1
    80000e5c:	87aa                	mv	a5,a0
    80000e5e:	4685                	li	a3,1
    80000e60:	9e89                	subw	a3,a3,a0
    80000e62:	00f6853b          	addw	a0,a3,a5
    80000e66:	0785                	addi	a5,a5,1
    80000e68:	fff7c703          	lbu	a4,-1(a5)
    80000e6c:	fb7d                	bnez	a4,80000e62 <strlen+0x14>
    ;
  return n;
}
    80000e6e:	6422                	ld	s0,8(sp)
    80000e70:	0141                	addi	sp,sp,16
    80000e72:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e74:	4501                	li	a0,0
    80000e76:	bfe5                	j	80000e6e <strlen+0x20>

0000000080000e78 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e78:	1141                	addi	sp,sp,-16
    80000e7a:	e406                	sd	ra,8(sp)
    80000e7c:	e022                	sd	s0,0(sp)
    80000e7e:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e80:	00001097          	auipc	ra,0x1
    80000e84:	b00080e7          	jalr	-1280(ra) # 80001980 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e88:	00008717          	auipc	a4,0x8
    80000e8c:	ac070713          	addi	a4,a4,-1344 # 80008948 <started>
  if(cpuid() == 0){
    80000e90:	c139                	beqz	a0,80000ed6 <main+0x5e>
    while(started == 0)
    80000e92:	431c                	lw	a5,0(a4)
    80000e94:	2781                	sext.w	a5,a5
    80000e96:	dff5                	beqz	a5,80000e92 <main+0x1a>
      ;
    __sync_synchronize();
    80000e98:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e9c:	00001097          	auipc	ra,0x1
    80000ea0:	ae4080e7          	jalr	-1308(ra) # 80001980 <cpuid>
    80000ea4:	85aa                	mv	a1,a0
    80000ea6:	00007517          	auipc	a0,0x7
    80000eaa:	21250513          	addi	a0,a0,530 # 800080b8 <digits+0x78>
    80000eae:	fffff097          	auipc	ra,0xfffff
    80000eb2:	6dc080e7          	jalr	1756(ra) # 8000058a <printf>
    kvminithart();    // turn on paging
    80000eb6:	00000097          	auipc	ra,0x0
    80000eba:	0d8080e7          	jalr	216(ra) # 80000f8e <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ebe:	00002097          	auipc	ra,0x2
    80000ec2:	82c080e7          	jalr	-2004(ra) # 800026ea <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec6:	00005097          	auipc	ra,0x5
    80000eca:	dda080e7          	jalr	-550(ra) # 80005ca0 <plicinithart>
  }

  scheduler();        
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	fd4080e7          	jalr	-44(ra) # 80001ea2 <scheduler>
    consoleinit();
    80000ed6:	fffff097          	auipc	ra,0xfffff
    80000eda:	57a080e7          	jalr	1402(ra) # 80000450 <consoleinit>
    printfinit();
    80000ede:	00000097          	auipc	ra,0x0
    80000ee2:	88c080e7          	jalr	-1908(ra) # 8000076a <printfinit>
    printf("\n");
    80000ee6:	00007517          	auipc	a0,0x7
    80000eea:	1e250513          	addi	a0,a0,482 # 800080c8 <digits+0x88>
    80000eee:	fffff097          	auipc	ra,0xfffff
    80000ef2:	69c080e7          	jalr	1692(ra) # 8000058a <printf>
    printf("xv6 kernel is booting\n");
    80000ef6:	00007517          	auipc	a0,0x7
    80000efa:	1aa50513          	addi	a0,a0,426 # 800080a0 <digits+0x60>
    80000efe:	fffff097          	auipc	ra,0xfffff
    80000f02:	68c080e7          	jalr	1676(ra) # 8000058a <printf>
    printf("\n");
    80000f06:	00007517          	auipc	a0,0x7
    80000f0a:	1c250513          	addi	a0,a0,450 # 800080c8 <digits+0x88>
    80000f0e:	fffff097          	auipc	ra,0xfffff
    80000f12:	67c080e7          	jalr	1660(ra) # 8000058a <printf>
    kinit();         // physical page allocator
    80000f16:	00000097          	auipc	ra,0x0
    80000f1a:	b94080e7          	jalr	-1132(ra) # 80000aaa <kinit>
    kvminit();       // create kernel page table
    80000f1e:	00000097          	auipc	ra,0x0
    80000f22:	326080e7          	jalr	806(ra) # 80001244 <kvminit>
    kvminithart();   // turn on paging
    80000f26:	00000097          	auipc	ra,0x0
    80000f2a:	068080e7          	jalr	104(ra) # 80000f8e <kvminithart>
    procinit();      // process table
    80000f2e:	00001097          	auipc	ra,0x1
    80000f32:	99e080e7          	jalr	-1634(ra) # 800018cc <procinit>
    trapinit();      // trap vectors
    80000f36:	00001097          	auipc	ra,0x1
    80000f3a:	78c080e7          	jalr	1932(ra) # 800026c2 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f3e:	00001097          	auipc	ra,0x1
    80000f42:	7ac080e7          	jalr	1964(ra) # 800026ea <trapinithart>
    plicinit();      // set up interrupt controller
    80000f46:	00005097          	auipc	ra,0x5
    80000f4a:	d44080e7          	jalr	-700(ra) # 80005c8a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f4e:	00005097          	auipc	ra,0x5
    80000f52:	d52080e7          	jalr	-686(ra) # 80005ca0 <plicinithart>
    binit();         // buffer cache
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	eea080e7          	jalr	-278(ra) # 80002e40 <binit>
    iinit();         // inode table
    80000f5e:	00002097          	auipc	ra,0x2
    80000f62:	58a080e7          	jalr	1418(ra) # 800034e8 <iinit>
    fileinit();      // file table
    80000f66:	00003097          	auipc	ra,0x3
    80000f6a:	530080e7          	jalr	1328(ra) # 80004496 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	e3a080e7          	jalr	-454(ra) # 80005da8 <virtio_disk_init>
    userinit();      // first user process
    80000f76:	00001097          	auipc	ra,0x1
    80000f7a:	d0e080e7          	jalr	-754(ra) # 80001c84 <userinit>
    __sync_synchronize();
    80000f7e:	0ff0000f          	fence
    started = 1;
    80000f82:	4785                	li	a5,1
    80000f84:	00008717          	auipc	a4,0x8
    80000f88:	9cf72223          	sw	a5,-1596(a4) # 80008948 <started>
    80000f8c:	b789                	j	80000ece <main+0x56>

0000000080000f8e <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f8e:	1141                	addi	sp,sp,-16
    80000f90:	e422                	sd	s0,8(sp)
    80000f92:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f94:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000f98:	00008797          	auipc	a5,0x8
    80000f9c:	9b87b783          	ld	a5,-1608(a5) # 80008950 <kernel_pagetable>
    80000fa0:	83b1                	srli	a5,a5,0xc
    80000fa2:	577d                	li	a4,-1
    80000fa4:	177e                	slli	a4,a4,0x3f
    80000fa6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fa8:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fac:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000fb0:	6422                	ld	s0,8(sp)
    80000fb2:	0141                	addi	sp,sp,16
    80000fb4:	8082                	ret

0000000080000fb6 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fb6:	7139                	addi	sp,sp,-64
    80000fb8:	fc06                	sd	ra,56(sp)
    80000fba:	f822                	sd	s0,48(sp)
    80000fbc:	f426                	sd	s1,40(sp)
    80000fbe:	f04a                	sd	s2,32(sp)
    80000fc0:	ec4e                	sd	s3,24(sp)
    80000fc2:	e852                	sd	s4,16(sp)
    80000fc4:	e456                	sd	s5,8(sp)
    80000fc6:	e05a                	sd	s6,0(sp)
    80000fc8:	0080                	addi	s0,sp,64
    80000fca:	84aa                	mv	s1,a0
    80000fcc:	89ae                	mv	s3,a1
    80000fce:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fd0:	57fd                	li	a5,-1
    80000fd2:	83e9                	srli	a5,a5,0x1a
    80000fd4:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fd6:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fd8:	04b7f263          	bgeu	a5,a1,8000101c <walk+0x66>
    panic("walk");
    80000fdc:	00007517          	auipc	a0,0x7
    80000fe0:	0f450513          	addi	a0,a0,244 # 800080d0 <digits+0x90>
    80000fe4:	fffff097          	auipc	ra,0xfffff
    80000fe8:	55c080e7          	jalr	1372(ra) # 80000540 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fec:	060a8663          	beqz	s5,80001058 <walk+0xa2>
    80000ff0:	00000097          	auipc	ra,0x0
    80000ff4:	af6080e7          	jalr	-1290(ra) # 80000ae6 <kalloc>
    80000ff8:	84aa                	mv	s1,a0
    80000ffa:	c529                	beqz	a0,80001044 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000ffc:	6605                	lui	a2,0x1
    80000ffe:	4581                	li	a1,0
    80001000:	00000097          	auipc	ra,0x0
    80001004:	cd2080e7          	jalr	-814(ra) # 80000cd2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001008:	00c4d793          	srli	a5,s1,0xc
    8000100c:	07aa                	slli	a5,a5,0xa
    8000100e:	0017e793          	ori	a5,a5,1
    80001012:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001016:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffdd217>
    80001018:	036a0063          	beq	s4,s6,80001038 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000101c:	0149d933          	srl	s2,s3,s4
    80001020:	1ff97913          	andi	s2,s2,511
    80001024:	090e                	slli	s2,s2,0x3
    80001026:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001028:	00093483          	ld	s1,0(s2)
    8000102c:	0014f793          	andi	a5,s1,1
    80001030:	dfd5                	beqz	a5,80000fec <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001032:	80a9                	srli	s1,s1,0xa
    80001034:	04b2                	slli	s1,s1,0xc
    80001036:	b7c5                	j	80001016 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001038:	00c9d513          	srli	a0,s3,0xc
    8000103c:	1ff57513          	andi	a0,a0,511
    80001040:	050e                	slli	a0,a0,0x3
    80001042:	9526                	add	a0,a0,s1
}
    80001044:	70e2                	ld	ra,56(sp)
    80001046:	7442                	ld	s0,48(sp)
    80001048:	74a2                	ld	s1,40(sp)
    8000104a:	7902                	ld	s2,32(sp)
    8000104c:	69e2                	ld	s3,24(sp)
    8000104e:	6a42                	ld	s4,16(sp)
    80001050:	6aa2                	ld	s5,8(sp)
    80001052:	6b02                	ld	s6,0(sp)
    80001054:	6121                	addi	sp,sp,64
    80001056:	8082                	ret
        return 0;
    80001058:	4501                	li	a0,0
    8000105a:	b7ed                	j	80001044 <walk+0x8e>

000000008000105c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000105c:	57fd                	li	a5,-1
    8000105e:	83e9                	srli	a5,a5,0x1a
    80001060:	00b7f463          	bgeu	a5,a1,80001068 <walkaddr+0xc>
    return 0;
    80001064:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001066:	8082                	ret
{
    80001068:	1141                	addi	sp,sp,-16
    8000106a:	e406                	sd	ra,8(sp)
    8000106c:	e022                	sd	s0,0(sp)
    8000106e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001070:	4601                	li	a2,0
    80001072:	00000097          	auipc	ra,0x0
    80001076:	f44080e7          	jalr	-188(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000107a:	c105                	beqz	a0,8000109a <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000107c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000107e:	0117f693          	andi	a3,a5,17
    80001082:	4745                	li	a4,17
    return 0;
    80001084:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001086:	00e68663          	beq	a3,a4,80001092 <walkaddr+0x36>
}
    8000108a:	60a2                	ld	ra,8(sp)
    8000108c:	6402                	ld	s0,0(sp)
    8000108e:	0141                	addi	sp,sp,16
    80001090:	8082                	ret
  pa = PTE2PA(*pte);
    80001092:	83a9                	srli	a5,a5,0xa
    80001094:	00c79513          	slli	a0,a5,0xc
  return pa;
    80001098:	bfcd                	j	8000108a <walkaddr+0x2e>
    return 0;
    8000109a:	4501                	li	a0,0
    8000109c:	b7fd                	j	8000108a <walkaddr+0x2e>

000000008000109e <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000109e:	715d                	addi	sp,sp,-80
    800010a0:	e486                	sd	ra,72(sp)
    800010a2:	e0a2                	sd	s0,64(sp)
    800010a4:	fc26                	sd	s1,56(sp)
    800010a6:	f84a                	sd	s2,48(sp)
    800010a8:	f44e                	sd	s3,40(sp)
    800010aa:	f052                	sd	s4,32(sp)
    800010ac:	ec56                	sd	s5,24(sp)
    800010ae:	e85a                	sd	s6,16(sp)
    800010b0:	e45e                	sd	s7,8(sp)
    800010b2:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010b4:	c639                	beqz	a2,80001102 <mappages+0x64>
    800010b6:	8aaa                	mv	s5,a0
    800010b8:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010ba:	777d                	lui	a4,0xfffff
    800010bc:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010c0:	fff58993          	addi	s3,a1,-1
    800010c4:	99b2                	add	s3,s3,a2
    800010c6:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010ca:	893e                	mv	s2,a5
    800010cc:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010d0:	6b85                	lui	s7,0x1
    800010d2:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010d6:	4605                	li	a2,1
    800010d8:	85ca                	mv	a1,s2
    800010da:	8556                	mv	a0,s5
    800010dc:	00000097          	auipc	ra,0x0
    800010e0:	eda080e7          	jalr	-294(ra) # 80000fb6 <walk>
    800010e4:	cd1d                	beqz	a0,80001122 <mappages+0x84>
    if(*pte & PTE_V)
    800010e6:	611c                	ld	a5,0(a0)
    800010e8:	8b85                	andi	a5,a5,1
    800010ea:	e785                	bnez	a5,80001112 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010ec:	80b1                	srli	s1,s1,0xc
    800010ee:	04aa                	slli	s1,s1,0xa
    800010f0:	0164e4b3          	or	s1,s1,s6
    800010f4:	0014e493          	ori	s1,s1,1
    800010f8:	e104                	sd	s1,0(a0)
    if(a == last)
    800010fa:	05390063          	beq	s2,s3,8000113a <mappages+0x9c>
    a += PGSIZE;
    800010fe:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001100:	bfc9                	j	800010d2 <mappages+0x34>
    panic("mappages: size");
    80001102:	00007517          	auipc	a0,0x7
    80001106:	fd650513          	addi	a0,a0,-42 # 800080d8 <digits+0x98>
    8000110a:	fffff097          	auipc	ra,0xfffff
    8000110e:	436080e7          	jalr	1078(ra) # 80000540 <panic>
      panic("mappages: remap");
    80001112:	00007517          	auipc	a0,0x7
    80001116:	fd650513          	addi	a0,a0,-42 # 800080e8 <digits+0xa8>
    8000111a:	fffff097          	auipc	ra,0xfffff
    8000111e:	426080e7          	jalr	1062(ra) # 80000540 <panic>
      return -1;
    80001122:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001124:	60a6                	ld	ra,72(sp)
    80001126:	6406                	ld	s0,64(sp)
    80001128:	74e2                	ld	s1,56(sp)
    8000112a:	7942                	ld	s2,48(sp)
    8000112c:	79a2                	ld	s3,40(sp)
    8000112e:	7a02                	ld	s4,32(sp)
    80001130:	6ae2                	ld	s5,24(sp)
    80001132:	6b42                	ld	s6,16(sp)
    80001134:	6ba2                	ld	s7,8(sp)
    80001136:	6161                	addi	sp,sp,80
    80001138:	8082                	ret
  return 0;
    8000113a:	4501                	li	a0,0
    8000113c:	b7e5                	j	80001124 <mappages+0x86>

000000008000113e <kvmmap>:
{
    8000113e:	1141                	addi	sp,sp,-16
    80001140:	e406                	sd	ra,8(sp)
    80001142:	e022                	sd	s0,0(sp)
    80001144:	0800                	addi	s0,sp,16
    80001146:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001148:	86b2                	mv	a3,a2
    8000114a:	863e                	mv	a2,a5
    8000114c:	00000097          	auipc	ra,0x0
    80001150:	f52080e7          	jalr	-174(ra) # 8000109e <mappages>
    80001154:	e509                	bnez	a0,8000115e <kvmmap+0x20>
}
    80001156:	60a2                	ld	ra,8(sp)
    80001158:	6402                	ld	s0,0(sp)
    8000115a:	0141                	addi	sp,sp,16
    8000115c:	8082                	ret
    panic("kvmmap");
    8000115e:	00007517          	auipc	a0,0x7
    80001162:	f9a50513          	addi	a0,a0,-102 # 800080f8 <digits+0xb8>
    80001166:	fffff097          	auipc	ra,0xfffff
    8000116a:	3da080e7          	jalr	986(ra) # 80000540 <panic>

000000008000116e <kvmmake>:
{
    8000116e:	1101                	addi	sp,sp,-32
    80001170:	ec06                	sd	ra,24(sp)
    80001172:	e822                	sd	s0,16(sp)
    80001174:	e426                	sd	s1,8(sp)
    80001176:	e04a                	sd	s2,0(sp)
    80001178:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000117a:	00000097          	auipc	ra,0x0
    8000117e:	96c080e7          	jalr	-1684(ra) # 80000ae6 <kalloc>
    80001182:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001184:	6605                	lui	a2,0x1
    80001186:	4581                	li	a1,0
    80001188:	00000097          	auipc	ra,0x0
    8000118c:	b4a080e7          	jalr	-1206(ra) # 80000cd2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001190:	4719                	li	a4,6
    80001192:	6685                	lui	a3,0x1
    80001194:	10000637          	lui	a2,0x10000
    80001198:	100005b7          	lui	a1,0x10000
    8000119c:	8526                	mv	a0,s1
    8000119e:	00000097          	auipc	ra,0x0
    800011a2:	fa0080e7          	jalr	-96(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011a6:	4719                	li	a4,6
    800011a8:	6685                	lui	a3,0x1
    800011aa:	10001637          	lui	a2,0x10001
    800011ae:	100015b7          	lui	a1,0x10001
    800011b2:	8526                	mv	a0,s1
    800011b4:	00000097          	auipc	ra,0x0
    800011b8:	f8a080e7          	jalr	-118(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011bc:	4719                	li	a4,6
    800011be:	004006b7          	lui	a3,0x400
    800011c2:	0c000637          	lui	a2,0xc000
    800011c6:	0c0005b7          	lui	a1,0xc000
    800011ca:	8526                	mv	a0,s1
    800011cc:	00000097          	auipc	ra,0x0
    800011d0:	f72080e7          	jalr	-142(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011d4:	00007917          	auipc	s2,0x7
    800011d8:	e2c90913          	addi	s2,s2,-468 # 80008000 <etext>
    800011dc:	4729                	li	a4,10
    800011de:	80007697          	auipc	a3,0x80007
    800011e2:	e2268693          	addi	a3,a3,-478 # 8000 <_entry-0x7fff8000>
    800011e6:	4605                	li	a2,1
    800011e8:	067e                	slli	a2,a2,0x1f
    800011ea:	85b2                	mv	a1,a2
    800011ec:	8526                	mv	a0,s1
    800011ee:	00000097          	auipc	ra,0x0
    800011f2:	f50080e7          	jalr	-176(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011f6:	4719                	li	a4,6
    800011f8:	46c5                	li	a3,17
    800011fa:	06ee                	slli	a3,a3,0x1b
    800011fc:	412686b3          	sub	a3,a3,s2
    80001200:	864a                	mv	a2,s2
    80001202:	85ca                	mv	a1,s2
    80001204:	8526                	mv	a0,s1
    80001206:	00000097          	auipc	ra,0x0
    8000120a:	f38080e7          	jalr	-200(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000120e:	4729                	li	a4,10
    80001210:	6685                	lui	a3,0x1
    80001212:	00006617          	auipc	a2,0x6
    80001216:	dee60613          	addi	a2,a2,-530 # 80007000 <_trampoline>
    8000121a:	040005b7          	lui	a1,0x4000
    8000121e:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001220:	05b2                	slli	a1,a1,0xc
    80001222:	8526                	mv	a0,s1
    80001224:	00000097          	auipc	ra,0x0
    80001228:	f1a080e7          	jalr	-230(ra) # 8000113e <kvmmap>
  proc_mapstacks(kpgtbl);
    8000122c:	8526                	mv	a0,s1
    8000122e:	00000097          	auipc	ra,0x0
    80001232:	608080e7          	jalr	1544(ra) # 80001836 <proc_mapstacks>
}
    80001236:	8526                	mv	a0,s1
    80001238:	60e2                	ld	ra,24(sp)
    8000123a:	6442                	ld	s0,16(sp)
    8000123c:	64a2                	ld	s1,8(sp)
    8000123e:	6902                	ld	s2,0(sp)
    80001240:	6105                	addi	sp,sp,32
    80001242:	8082                	ret

0000000080001244 <kvminit>:
{
    80001244:	1141                	addi	sp,sp,-16
    80001246:	e406                	sd	ra,8(sp)
    80001248:	e022                	sd	s0,0(sp)
    8000124a:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000124c:	00000097          	auipc	ra,0x0
    80001250:	f22080e7          	jalr	-222(ra) # 8000116e <kvmmake>
    80001254:	00007797          	auipc	a5,0x7
    80001258:	6ea7be23          	sd	a0,1788(a5) # 80008950 <kernel_pagetable>
}
    8000125c:	60a2                	ld	ra,8(sp)
    8000125e:	6402                	ld	s0,0(sp)
    80001260:	0141                	addi	sp,sp,16
    80001262:	8082                	ret

0000000080001264 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001264:	715d                	addi	sp,sp,-80
    80001266:	e486                	sd	ra,72(sp)
    80001268:	e0a2                	sd	s0,64(sp)
    8000126a:	fc26                	sd	s1,56(sp)
    8000126c:	f84a                	sd	s2,48(sp)
    8000126e:	f44e                	sd	s3,40(sp)
    80001270:	f052                	sd	s4,32(sp)
    80001272:	ec56                	sd	s5,24(sp)
    80001274:	e85a                	sd	s6,16(sp)
    80001276:	e45e                	sd	s7,8(sp)
    80001278:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000127a:	03459793          	slli	a5,a1,0x34
    8000127e:	e795                	bnez	a5,800012aa <uvmunmap+0x46>
    80001280:	8a2a                	mv	s4,a0
    80001282:	892e                	mv	s2,a1
    80001284:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001286:	0632                	slli	a2,a2,0xc
    80001288:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000128c:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000128e:	6b05                	lui	s6,0x1
    80001290:	0735e263          	bltu	a1,s3,800012f4 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001294:	60a6                	ld	ra,72(sp)
    80001296:	6406                	ld	s0,64(sp)
    80001298:	74e2                	ld	s1,56(sp)
    8000129a:	7942                	ld	s2,48(sp)
    8000129c:	79a2                	ld	s3,40(sp)
    8000129e:	7a02                	ld	s4,32(sp)
    800012a0:	6ae2                	ld	s5,24(sp)
    800012a2:	6b42                	ld	s6,16(sp)
    800012a4:	6ba2                	ld	s7,8(sp)
    800012a6:	6161                	addi	sp,sp,80
    800012a8:	8082                	ret
    panic("uvmunmap: not aligned");
    800012aa:	00007517          	auipc	a0,0x7
    800012ae:	e5650513          	addi	a0,a0,-426 # 80008100 <digits+0xc0>
    800012b2:	fffff097          	auipc	ra,0xfffff
    800012b6:	28e080e7          	jalr	654(ra) # 80000540 <panic>
      panic("uvmunmap: walk");
    800012ba:	00007517          	auipc	a0,0x7
    800012be:	e5e50513          	addi	a0,a0,-418 # 80008118 <digits+0xd8>
    800012c2:	fffff097          	auipc	ra,0xfffff
    800012c6:	27e080e7          	jalr	638(ra) # 80000540 <panic>
      panic("uvmunmap: not mapped");
    800012ca:	00007517          	auipc	a0,0x7
    800012ce:	e5e50513          	addi	a0,a0,-418 # 80008128 <digits+0xe8>
    800012d2:	fffff097          	auipc	ra,0xfffff
    800012d6:	26e080e7          	jalr	622(ra) # 80000540 <panic>
      panic("uvmunmap: not a leaf");
    800012da:	00007517          	auipc	a0,0x7
    800012de:	e6650513          	addi	a0,a0,-410 # 80008140 <digits+0x100>
    800012e2:	fffff097          	auipc	ra,0xfffff
    800012e6:	25e080e7          	jalr	606(ra) # 80000540 <panic>
    *pte = 0;
    800012ea:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012ee:	995a                	add	s2,s2,s6
    800012f0:	fb3972e3          	bgeu	s2,s3,80001294 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012f4:	4601                	li	a2,0
    800012f6:	85ca                	mv	a1,s2
    800012f8:	8552                	mv	a0,s4
    800012fa:	00000097          	auipc	ra,0x0
    800012fe:	cbc080e7          	jalr	-836(ra) # 80000fb6 <walk>
    80001302:	84aa                	mv	s1,a0
    80001304:	d95d                	beqz	a0,800012ba <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001306:	6108                	ld	a0,0(a0)
    80001308:	00157793          	andi	a5,a0,1
    8000130c:	dfdd                	beqz	a5,800012ca <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000130e:	3ff57793          	andi	a5,a0,1023
    80001312:	fd7784e3          	beq	a5,s7,800012da <uvmunmap+0x76>
    if(do_free){
    80001316:	fc0a8ae3          	beqz	s5,800012ea <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    8000131a:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000131c:	0532                	slli	a0,a0,0xc
    8000131e:	fffff097          	auipc	ra,0xfffff
    80001322:	6ca080e7          	jalr	1738(ra) # 800009e8 <kfree>
    80001326:	b7d1                	j	800012ea <uvmunmap+0x86>

0000000080001328 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001328:	1101                	addi	sp,sp,-32
    8000132a:	ec06                	sd	ra,24(sp)
    8000132c:	e822                	sd	s0,16(sp)
    8000132e:	e426                	sd	s1,8(sp)
    80001330:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001332:	fffff097          	auipc	ra,0xfffff
    80001336:	7b4080e7          	jalr	1972(ra) # 80000ae6 <kalloc>
    8000133a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000133c:	c519                	beqz	a0,8000134a <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000133e:	6605                	lui	a2,0x1
    80001340:	4581                	li	a1,0
    80001342:	00000097          	auipc	ra,0x0
    80001346:	990080e7          	jalr	-1648(ra) # 80000cd2 <memset>
  return pagetable;
}
    8000134a:	8526                	mv	a0,s1
    8000134c:	60e2                	ld	ra,24(sp)
    8000134e:	6442                	ld	s0,16(sp)
    80001350:	64a2                	ld	s1,8(sp)
    80001352:	6105                	addi	sp,sp,32
    80001354:	8082                	ret

0000000080001356 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001356:	7179                	addi	sp,sp,-48
    80001358:	f406                	sd	ra,40(sp)
    8000135a:	f022                	sd	s0,32(sp)
    8000135c:	ec26                	sd	s1,24(sp)
    8000135e:	e84a                	sd	s2,16(sp)
    80001360:	e44e                	sd	s3,8(sp)
    80001362:	e052                	sd	s4,0(sp)
    80001364:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001366:	6785                	lui	a5,0x1
    80001368:	04f67863          	bgeu	a2,a5,800013b8 <uvmfirst+0x62>
    8000136c:	8a2a                	mv	s4,a0
    8000136e:	89ae                	mv	s3,a1
    80001370:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    80001372:	fffff097          	auipc	ra,0xfffff
    80001376:	774080e7          	jalr	1908(ra) # 80000ae6 <kalloc>
    8000137a:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000137c:	6605                	lui	a2,0x1
    8000137e:	4581                	li	a1,0
    80001380:	00000097          	auipc	ra,0x0
    80001384:	952080e7          	jalr	-1710(ra) # 80000cd2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001388:	4779                	li	a4,30
    8000138a:	86ca                	mv	a3,s2
    8000138c:	6605                	lui	a2,0x1
    8000138e:	4581                	li	a1,0
    80001390:	8552                	mv	a0,s4
    80001392:	00000097          	auipc	ra,0x0
    80001396:	d0c080e7          	jalr	-756(ra) # 8000109e <mappages>
  memmove(mem, src, sz);
    8000139a:	8626                	mv	a2,s1
    8000139c:	85ce                	mv	a1,s3
    8000139e:	854a                	mv	a0,s2
    800013a0:	00000097          	auipc	ra,0x0
    800013a4:	98e080e7          	jalr	-1650(ra) # 80000d2e <memmove>
}
    800013a8:	70a2                	ld	ra,40(sp)
    800013aa:	7402                	ld	s0,32(sp)
    800013ac:	64e2                	ld	s1,24(sp)
    800013ae:	6942                	ld	s2,16(sp)
    800013b0:	69a2                	ld	s3,8(sp)
    800013b2:	6a02                	ld	s4,0(sp)
    800013b4:	6145                	addi	sp,sp,48
    800013b6:	8082                	ret
    panic("uvmfirst: more than a page");
    800013b8:	00007517          	auipc	a0,0x7
    800013bc:	da050513          	addi	a0,a0,-608 # 80008158 <digits+0x118>
    800013c0:	fffff097          	auipc	ra,0xfffff
    800013c4:	180080e7          	jalr	384(ra) # 80000540 <panic>

00000000800013c8 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013c8:	1101                	addi	sp,sp,-32
    800013ca:	ec06                	sd	ra,24(sp)
    800013cc:	e822                	sd	s0,16(sp)
    800013ce:	e426                	sd	s1,8(sp)
    800013d0:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013d2:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013d4:	00b67d63          	bgeu	a2,a1,800013ee <uvmdealloc+0x26>
    800013d8:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013da:	6785                	lui	a5,0x1
    800013dc:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800013de:	00f60733          	add	a4,a2,a5
    800013e2:	76fd                	lui	a3,0xfffff
    800013e4:	8f75                	and	a4,a4,a3
    800013e6:	97ae                	add	a5,a5,a1
    800013e8:	8ff5                	and	a5,a5,a3
    800013ea:	00f76863          	bltu	a4,a5,800013fa <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013ee:	8526                	mv	a0,s1
    800013f0:	60e2                	ld	ra,24(sp)
    800013f2:	6442                	ld	s0,16(sp)
    800013f4:	64a2                	ld	s1,8(sp)
    800013f6:	6105                	addi	sp,sp,32
    800013f8:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013fa:	8f99                	sub	a5,a5,a4
    800013fc:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013fe:	4685                	li	a3,1
    80001400:	0007861b          	sext.w	a2,a5
    80001404:	85ba                	mv	a1,a4
    80001406:	00000097          	auipc	ra,0x0
    8000140a:	e5e080e7          	jalr	-418(ra) # 80001264 <uvmunmap>
    8000140e:	b7c5                	j	800013ee <uvmdealloc+0x26>

0000000080001410 <uvmalloc>:
  if(newsz < oldsz)
    80001410:	0ab66563          	bltu	a2,a1,800014ba <uvmalloc+0xaa>
{
    80001414:	7139                	addi	sp,sp,-64
    80001416:	fc06                	sd	ra,56(sp)
    80001418:	f822                	sd	s0,48(sp)
    8000141a:	f426                	sd	s1,40(sp)
    8000141c:	f04a                	sd	s2,32(sp)
    8000141e:	ec4e                	sd	s3,24(sp)
    80001420:	e852                	sd	s4,16(sp)
    80001422:	e456                	sd	s5,8(sp)
    80001424:	e05a                	sd	s6,0(sp)
    80001426:	0080                	addi	s0,sp,64
    80001428:	8aaa                	mv	s5,a0
    8000142a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000142c:	6785                	lui	a5,0x1
    8000142e:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001430:	95be                	add	a1,a1,a5
    80001432:	77fd                	lui	a5,0xfffff
    80001434:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001438:	08c9f363          	bgeu	s3,a2,800014be <uvmalloc+0xae>
    8000143c:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000143e:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    80001442:	fffff097          	auipc	ra,0xfffff
    80001446:	6a4080e7          	jalr	1700(ra) # 80000ae6 <kalloc>
    8000144a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000144c:	c51d                	beqz	a0,8000147a <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    8000144e:	6605                	lui	a2,0x1
    80001450:	4581                	li	a1,0
    80001452:	00000097          	auipc	ra,0x0
    80001456:	880080e7          	jalr	-1920(ra) # 80000cd2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000145a:	875a                	mv	a4,s6
    8000145c:	86a6                	mv	a3,s1
    8000145e:	6605                	lui	a2,0x1
    80001460:	85ca                	mv	a1,s2
    80001462:	8556                	mv	a0,s5
    80001464:	00000097          	auipc	ra,0x0
    80001468:	c3a080e7          	jalr	-966(ra) # 8000109e <mappages>
    8000146c:	e90d                	bnez	a0,8000149e <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000146e:	6785                	lui	a5,0x1
    80001470:	993e                	add	s2,s2,a5
    80001472:	fd4968e3          	bltu	s2,s4,80001442 <uvmalloc+0x32>
  return newsz;
    80001476:	8552                	mv	a0,s4
    80001478:	a809                	j	8000148a <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    8000147a:	864e                	mv	a2,s3
    8000147c:	85ca                	mv	a1,s2
    8000147e:	8556                	mv	a0,s5
    80001480:	00000097          	auipc	ra,0x0
    80001484:	f48080e7          	jalr	-184(ra) # 800013c8 <uvmdealloc>
      return 0;
    80001488:	4501                	li	a0,0
}
    8000148a:	70e2                	ld	ra,56(sp)
    8000148c:	7442                	ld	s0,48(sp)
    8000148e:	74a2                	ld	s1,40(sp)
    80001490:	7902                	ld	s2,32(sp)
    80001492:	69e2                	ld	s3,24(sp)
    80001494:	6a42                	ld	s4,16(sp)
    80001496:	6aa2                	ld	s5,8(sp)
    80001498:	6b02                	ld	s6,0(sp)
    8000149a:	6121                	addi	sp,sp,64
    8000149c:	8082                	ret
      kfree(mem);
    8000149e:	8526                	mv	a0,s1
    800014a0:	fffff097          	auipc	ra,0xfffff
    800014a4:	548080e7          	jalr	1352(ra) # 800009e8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014a8:	864e                	mv	a2,s3
    800014aa:	85ca                	mv	a1,s2
    800014ac:	8556                	mv	a0,s5
    800014ae:	00000097          	auipc	ra,0x0
    800014b2:	f1a080e7          	jalr	-230(ra) # 800013c8 <uvmdealloc>
      return 0;
    800014b6:	4501                	li	a0,0
    800014b8:	bfc9                	j	8000148a <uvmalloc+0x7a>
    return oldsz;
    800014ba:	852e                	mv	a0,a1
}
    800014bc:	8082                	ret
  return newsz;
    800014be:	8532                	mv	a0,a2
    800014c0:	b7e9                	j	8000148a <uvmalloc+0x7a>

00000000800014c2 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014c2:	7179                	addi	sp,sp,-48
    800014c4:	f406                	sd	ra,40(sp)
    800014c6:	f022                	sd	s0,32(sp)
    800014c8:	ec26                	sd	s1,24(sp)
    800014ca:	e84a                	sd	s2,16(sp)
    800014cc:	e44e                	sd	s3,8(sp)
    800014ce:	e052                	sd	s4,0(sp)
    800014d0:	1800                	addi	s0,sp,48
    800014d2:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014d4:	84aa                	mv	s1,a0
    800014d6:	6905                	lui	s2,0x1
    800014d8:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014da:	4985                	li	s3,1
    800014dc:	a829                	j	800014f6 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014de:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    800014e0:	00c79513          	slli	a0,a5,0xc
    800014e4:	00000097          	auipc	ra,0x0
    800014e8:	fde080e7          	jalr	-34(ra) # 800014c2 <freewalk>
      pagetable[i] = 0;
    800014ec:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f0:	04a1                	addi	s1,s1,8
    800014f2:	03248163          	beq	s1,s2,80001514 <freewalk+0x52>
    pte_t pte = pagetable[i];
    800014f6:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f8:	00f7f713          	andi	a4,a5,15
    800014fc:	ff3701e3          	beq	a4,s3,800014de <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001500:	8b85                	andi	a5,a5,1
    80001502:	d7fd                	beqz	a5,800014f0 <freewalk+0x2e>
      panic("freewalk: leaf");
    80001504:	00007517          	auipc	a0,0x7
    80001508:	c7450513          	addi	a0,a0,-908 # 80008178 <digits+0x138>
    8000150c:	fffff097          	auipc	ra,0xfffff
    80001510:	034080e7          	jalr	52(ra) # 80000540 <panic>
    }
  }
  kfree((void*)pagetable);
    80001514:	8552                	mv	a0,s4
    80001516:	fffff097          	auipc	ra,0xfffff
    8000151a:	4d2080e7          	jalr	1234(ra) # 800009e8 <kfree>
}
    8000151e:	70a2                	ld	ra,40(sp)
    80001520:	7402                	ld	s0,32(sp)
    80001522:	64e2                	ld	s1,24(sp)
    80001524:	6942                	ld	s2,16(sp)
    80001526:	69a2                	ld	s3,8(sp)
    80001528:	6a02                	ld	s4,0(sp)
    8000152a:	6145                	addi	sp,sp,48
    8000152c:	8082                	ret

000000008000152e <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000152e:	1101                	addi	sp,sp,-32
    80001530:	ec06                	sd	ra,24(sp)
    80001532:	e822                	sd	s0,16(sp)
    80001534:	e426                	sd	s1,8(sp)
    80001536:	1000                	addi	s0,sp,32
    80001538:	84aa                	mv	s1,a0
  if(sz > 0)
    8000153a:	e999                	bnez	a1,80001550 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000153c:	8526                	mv	a0,s1
    8000153e:	00000097          	auipc	ra,0x0
    80001542:	f84080e7          	jalr	-124(ra) # 800014c2 <freewalk>
}
    80001546:	60e2                	ld	ra,24(sp)
    80001548:	6442                	ld	s0,16(sp)
    8000154a:	64a2                	ld	s1,8(sp)
    8000154c:	6105                	addi	sp,sp,32
    8000154e:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001550:	6785                	lui	a5,0x1
    80001552:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001554:	95be                	add	a1,a1,a5
    80001556:	4685                	li	a3,1
    80001558:	00c5d613          	srli	a2,a1,0xc
    8000155c:	4581                	li	a1,0
    8000155e:	00000097          	auipc	ra,0x0
    80001562:	d06080e7          	jalr	-762(ra) # 80001264 <uvmunmap>
    80001566:	bfd9                	j	8000153c <uvmfree+0xe>

0000000080001568 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001568:	c679                	beqz	a2,80001636 <uvmcopy+0xce>
{
    8000156a:	715d                	addi	sp,sp,-80
    8000156c:	e486                	sd	ra,72(sp)
    8000156e:	e0a2                	sd	s0,64(sp)
    80001570:	fc26                	sd	s1,56(sp)
    80001572:	f84a                	sd	s2,48(sp)
    80001574:	f44e                	sd	s3,40(sp)
    80001576:	f052                	sd	s4,32(sp)
    80001578:	ec56                	sd	s5,24(sp)
    8000157a:	e85a                	sd	s6,16(sp)
    8000157c:	e45e                	sd	s7,8(sp)
    8000157e:	0880                	addi	s0,sp,80
    80001580:	8b2a                	mv	s6,a0
    80001582:	8aae                	mv	s5,a1
    80001584:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001586:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001588:	4601                	li	a2,0
    8000158a:	85ce                	mv	a1,s3
    8000158c:	855a                	mv	a0,s6
    8000158e:	00000097          	auipc	ra,0x0
    80001592:	a28080e7          	jalr	-1496(ra) # 80000fb6 <walk>
    80001596:	c531                	beqz	a0,800015e2 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001598:	6118                	ld	a4,0(a0)
    8000159a:	00177793          	andi	a5,a4,1
    8000159e:	cbb1                	beqz	a5,800015f2 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a0:	00a75593          	srli	a1,a4,0xa
    800015a4:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015a8:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015ac:	fffff097          	auipc	ra,0xfffff
    800015b0:	53a080e7          	jalr	1338(ra) # 80000ae6 <kalloc>
    800015b4:	892a                	mv	s2,a0
    800015b6:	c939                	beqz	a0,8000160c <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015b8:	6605                	lui	a2,0x1
    800015ba:	85de                	mv	a1,s7
    800015bc:	fffff097          	auipc	ra,0xfffff
    800015c0:	772080e7          	jalr	1906(ra) # 80000d2e <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015c4:	8726                	mv	a4,s1
    800015c6:	86ca                	mv	a3,s2
    800015c8:	6605                	lui	a2,0x1
    800015ca:	85ce                	mv	a1,s3
    800015cc:	8556                	mv	a0,s5
    800015ce:	00000097          	auipc	ra,0x0
    800015d2:	ad0080e7          	jalr	-1328(ra) # 8000109e <mappages>
    800015d6:	e515                	bnez	a0,80001602 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015d8:	6785                	lui	a5,0x1
    800015da:	99be                	add	s3,s3,a5
    800015dc:	fb49e6e3          	bltu	s3,s4,80001588 <uvmcopy+0x20>
    800015e0:	a081                	j	80001620 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e2:	00007517          	auipc	a0,0x7
    800015e6:	ba650513          	addi	a0,a0,-1114 # 80008188 <digits+0x148>
    800015ea:	fffff097          	auipc	ra,0xfffff
    800015ee:	f56080e7          	jalr	-170(ra) # 80000540 <panic>
      panic("uvmcopy: page not present");
    800015f2:	00007517          	auipc	a0,0x7
    800015f6:	bb650513          	addi	a0,a0,-1098 # 800081a8 <digits+0x168>
    800015fa:	fffff097          	auipc	ra,0xfffff
    800015fe:	f46080e7          	jalr	-186(ra) # 80000540 <panic>
      kfree(mem);
    80001602:	854a                	mv	a0,s2
    80001604:	fffff097          	auipc	ra,0xfffff
    80001608:	3e4080e7          	jalr	996(ra) # 800009e8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000160c:	4685                	li	a3,1
    8000160e:	00c9d613          	srli	a2,s3,0xc
    80001612:	4581                	li	a1,0
    80001614:	8556                	mv	a0,s5
    80001616:	00000097          	auipc	ra,0x0
    8000161a:	c4e080e7          	jalr	-946(ra) # 80001264 <uvmunmap>
  return -1;
    8000161e:	557d                	li	a0,-1
}
    80001620:	60a6                	ld	ra,72(sp)
    80001622:	6406                	ld	s0,64(sp)
    80001624:	74e2                	ld	s1,56(sp)
    80001626:	7942                	ld	s2,48(sp)
    80001628:	79a2                	ld	s3,40(sp)
    8000162a:	7a02                	ld	s4,32(sp)
    8000162c:	6ae2                	ld	s5,24(sp)
    8000162e:	6b42                	ld	s6,16(sp)
    80001630:	6ba2                	ld	s7,8(sp)
    80001632:	6161                	addi	sp,sp,80
    80001634:	8082                	ret
  return 0;
    80001636:	4501                	li	a0,0
}
    80001638:	8082                	ret

000000008000163a <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000163a:	1141                	addi	sp,sp,-16
    8000163c:	e406                	sd	ra,8(sp)
    8000163e:	e022                	sd	s0,0(sp)
    80001640:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001642:	4601                	li	a2,0
    80001644:	00000097          	auipc	ra,0x0
    80001648:	972080e7          	jalr	-1678(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000164c:	c901                	beqz	a0,8000165c <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000164e:	611c                	ld	a5,0(a0)
    80001650:	9bbd                	andi	a5,a5,-17
    80001652:	e11c                	sd	a5,0(a0)
}
    80001654:	60a2                	ld	ra,8(sp)
    80001656:	6402                	ld	s0,0(sp)
    80001658:	0141                	addi	sp,sp,16
    8000165a:	8082                	ret
    panic("uvmclear");
    8000165c:	00007517          	auipc	a0,0x7
    80001660:	b6c50513          	addi	a0,a0,-1172 # 800081c8 <digits+0x188>
    80001664:	fffff097          	auipc	ra,0xfffff
    80001668:	edc080e7          	jalr	-292(ra) # 80000540 <panic>

000000008000166c <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000166c:	c6bd                	beqz	a3,800016da <copyout+0x6e>
{
    8000166e:	715d                	addi	sp,sp,-80
    80001670:	e486                	sd	ra,72(sp)
    80001672:	e0a2                	sd	s0,64(sp)
    80001674:	fc26                	sd	s1,56(sp)
    80001676:	f84a                	sd	s2,48(sp)
    80001678:	f44e                	sd	s3,40(sp)
    8000167a:	f052                	sd	s4,32(sp)
    8000167c:	ec56                	sd	s5,24(sp)
    8000167e:	e85a                	sd	s6,16(sp)
    80001680:	e45e                	sd	s7,8(sp)
    80001682:	e062                	sd	s8,0(sp)
    80001684:	0880                	addi	s0,sp,80
    80001686:	8b2a                	mv	s6,a0
    80001688:	8c2e                	mv	s8,a1
    8000168a:	8a32                	mv	s4,a2
    8000168c:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000168e:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001690:	6a85                	lui	s5,0x1
    80001692:	a015                	j	800016b6 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001694:	9562                	add	a0,a0,s8
    80001696:	0004861b          	sext.w	a2,s1
    8000169a:	85d2                	mv	a1,s4
    8000169c:	41250533          	sub	a0,a0,s2
    800016a0:	fffff097          	auipc	ra,0xfffff
    800016a4:	68e080e7          	jalr	1678(ra) # 80000d2e <memmove>

    len -= n;
    800016a8:	409989b3          	sub	s3,s3,s1
    src += n;
    800016ac:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016ae:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b2:	02098263          	beqz	s3,800016d6 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016b6:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016ba:	85ca                	mv	a1,s2
    800016bc:	855a                	mv	a0,s6
    800016be:	00000097          	auipc	ra,0x0
    800016c2:	99e080e7          	jalr	-1634(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800016c6:	cd01                	beqz	a0,800016de <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016c8:	418904b3          	sub	s1,s2,s8
    800016cc:	94d6                	add	s1,s1,s5
    800016ce:	fc99f3e3          	bgeu	s3,s1,80001694 <copyout+0x28>
    800016d2:	84ce                	mv	s1,s3
    800016d4:	b7c1                	j	80001694 <copyout+0x28>
  }
  return 0;
    800016d6:	4501                	li	a0,0
    800016d8:	a021                	j	800016e0 <copyout+0x74>
    800016da:	4501                	li	a0,0
}
    800016dc:	8082                	ret
      return -1;
    800016de:	557d                	li	a0,-1
}
    800016e0:	60a6                	ld	ra,72(sp)
    800016e2:	6406                	ld	s0,64(sp)
    800016e4:	74e2                	ld	s1,56(sp)
    800016e6:	7942                	ld	s2,48(sp)
    800016e8:	79a2                	ld	s3,40(sp)
    800016ea:	7a02                	ld	s4,32(sp)
    800016ec:	6ae2                	ld	s5,24(sp)
    800016ee:	6b42                	ld	s6,16(sp)
    800016f0:	6ba2                	ld	s7,8(sp)
    800016f2:	6c02                	ld	s8,0(sp)
    800016f4:	6161                	addi	sp,sp,80
    800016f6:	8082                	ret

00000000800016f8 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016f8:	caa5                	beqz	a3,80001768 <copyin+0x70>
{
    800016fa:	715d                	addi	sp,sp,-80
    800016fc:	e486                	sd	ra,72(sp)
    800016fe:	e0a2                	sd	s0,64(sp)
    80001700:	fc26                	sd	s1,56(sp)
    80001702:	f84a                	sd	s2,48(sp)
    80001704:	f44e                	sd	s3,40(sp)
    80001706:	f052                	sd	s4,32(sp)
    80001708:	ec56                	sd	s5,24(sp)
    8000170a:	e85a                	sd	s6,16(sp)
    8000170c:	e45e                	sd	s7,8(sp)
    8000170e:	e062                	sd	s8,0(sp)
    80001710:	0880                	addi	s0,sp,80
    80001712:	8b2a                	mv	s6,a0
    80001714:	8a2e                	mv	s4,a1
    80001716:	8c32                	mv	s8,a2
    80001718:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    8000171a:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000171c:	6a85                	lui	s5,0x1
    8000171e:	a01d                	j	80001744 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001720:	018505b3          	add	a1,a0,s8
    80001724:	0004861b          	sext.w	a2,s1
    80001728:	412585b3          	sub	a1,a1,s2
    8000172c:	8552                	mv	a0,s4
    8000172e:	fffff097          	auipc	ra,0xfffff
    80001732:	600080e7          	jalr	1536(ra) # 80000d2e <memmove>

    len -= n;
    80001736:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173a:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000173c:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001740:	02098263          	beqz	s3,80001764 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001744:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001748:	85ca                	mv	a1,s2
    8000174a:	855a                	mv	a0,s6
    8000174c:	00000097          	auipc	ra,0x0
    80001750:	910080e7          	jalr	-1776(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    80001754:	cd01                	beqz	a0,8000176c <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001756:	418904b3          	sub	s1,s2,s8
    8000175a:	94d6                	add	s1,s1,s5
    8000175c:	fc99f2e3          	bgeu	s3,s1,80001720 <copyin+0x28>
    80001760:	84ce                	mv	s1,s3
    80001762:	bf7d                	j	80001720 <copyin+0x28>
  }
  return 0;
    80001764:	4501                	li	a0,0
    80001766:	a021                	j	8000176e <copyin+0x76>
    80001768:	4501                	li	a0,0
}
    8000176a:	8082                	ret
      return -1;
    8000176c:	557d                	li	a0,-1
}
    8000176e:	60a6                	ld	ra,72(sp)
    80001770:	6406                	ld	s0,64(sp)
    80001772:	74e2                	ld	s1,56(sp)
    80001774:	7942                	ld	s2,48(sp)
    80001776:	79a2                	ld	s3,40(sp)
    80001778:	7a02                	ld	s4,32(sp)
    8000177a:	6ae2                	ld	s5,24(sp)
    8000177c:	6b42                	ld	s6,16(sp)
    8000177e:	6ba2                	ld	s7,8(sp)
    80001780:	6c02                	ld	s8,0(sp)
    80001782:	6161                	addi	sp,sp,80
    80001784:	8082                	ret

0000000080001786 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001786:	c2dd                	beqz	a3,8000182c <copyinstr+0xa6>
{
    80001788:	715d                	addi	sp,sp,-80
    8000178a:	e486                	sd	ra,72(sp)
    8000178c:	e0a2                	sd	s0,64(sp)
    8000178e:	fc26                	sd	s1,56(sp)
    80001790:	f84a                	sd	s2,48(sp)
    80001792:	f44e                	sd	s3,40(sp)
    80001794:	f052                	sd	s4,32(sp)
    80001796:	ec56                	sd	s5,24(sp)
    80001798:	e85a                	sd	s6,16(sp)
    8000179a:	e45e                	sd	s7,8(sp)
    8000179c:	0880                	addi	s0,sp,80
    8000179e:	8a2a                	mv	s4,a0
    800017a0:	8b2e                	mv	s6,a1
    800017a2:	8bb2                	mv	s7,a2
    800017a4:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017a6:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017a8:	6985                	lui	s3,0x1
    800017aa:	a02d                	j	800017d4 <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017ac:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b0:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b2:	37fd                	addiw	a5,a5,-1
    800017b4:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017b8:	60a6                	ld	ra,72(sp)
    800017ba:	6406                	ld	s0,64(sp)
    800017bc:	74e2                	ld	s1,56(sp)
    800017be:	7942                	ld	s2,48(sp)
    800017c0:	79a2                	ld	s3,40(sp)
    800017c2:	7a02                	ld	s4,32(sp)
    800017c4:	6ae2                	ld	s5,24(sp)
    800017c6:	6b42                	ld	s6,16(sp)
    800017c8:	6ba2                	ld	s7,8(sp)
    800017ca:	6161                	addi	sp,sp,80
    800017cc:	8082                	ret
    srcva = va0 + PGSIZE;
    800017ce:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d2:	c8a9                	beqz	s1,80001824 <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    800017d4:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017d8:	85ca                	mv	a1,s2
    800017da:	8552                	mv	a0,s4
    800017dc:	00000097          	auipc	ra,0x0
    800017e0:	880080e7          	jalr	-1920(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800017e4:	c131                	beqz	a0,80001828 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    800017e6:	417906b3          	sub	a3,s2,s7
    800017ea:	96ce                	add	a3,a3,s3
    800017ec:	00d4f363          	bgeu	s1,a3,800017f2 <copyinstr+0x6c>
    800017f0:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f2:	955e                	add	a0,a0,s7
    800017f4:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017f8:	daf9                	beqz	a3,800017ce <copyinstr+0x48>
    800017fa:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017fc:	41650633          	sub	a2,a0,s6
    80001800:	fff48593          	addi	a1,s1,-1
    80001804:	95da                	add	a1,a1,s6
    while(n > 0){
    80001806:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    80001808:	00f60733          	add	a4,a2,a5
    8000180c:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffdd220>
    80001810:	df51                	beqz	a4,800017ac <copyinstr+0x26>
        *dst = *p;
    80001812:	00e78023          	sb	a4,0(a5)
      --max;
    80001816:	40f584b3          	sub	s1,a1,a5
      dst++;
    8000181a:	0785                	addi	a5,a5,1
    while(n > 0){
    8000181c:	fed796e3          	bne	a5,a3,80001808 <copyinstr+0x82>
      dst++;
    80001820:	8b3e                	mv	s6,a5
    80001822:	b775                	j	800017ce <copyinstr+0x48>
    80001824:	4781                	li	a5,0
    80001826:	b771                	j	800017b2 <copyinstr+0x2c>
      return -1;
    80001828:	557d                	li	a0,-1
    8000182a:	b779                	j	800017b8 <copyinstr+0x32>
  int got_null = 0;
    8000182c:	4781                	li	a5,0
  if(got_null){
    8000182e:	37fd                	addiw	a5,a5,-1
    80001830:	0007851b          	sext.w	a0,a5
}
    80001834:	8082                	ret

0000000080001836 <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    80001836:	7139                	addi	sp,sp,-64
    80001838:	fc06                	sd	ra,56(sp)
    8000183a:	f822                	sd	s0,48(sp)
    8000183c:	f426                	sd	s1,40(sp)
    8000183e:	f04a                	sd	s2,32(sp)
    80001840:	ec4e                	sd	s3,24(sp)
    80001842:	e852                	sd	s4,16(sp)
    80001844:	e456                	sd	s5,8(sp)
    80001846:	e05a                	sd	s6,0(sp)
    80001848:	0080                	addi	s0,sp,64
    8000184a:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    8000184c:	0000f497          	auipc	s1,0xf
    80001850:	7b448493          	addi	s1,s1,1972 # 80011000 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001854:	8b26                	mv	s6,s1
    80001856:	00006a97          	auipc	s5,0x6
    8000185a:	7aaa8a93          	addi	s5,s5,1962 # 80008000 <etext>
    8000185e:	04000937          	lui	s2,0x4000
    80001862:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001864:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001866:	00015a17          	auipc	s4,0x15
    8000186a:	19aa0a13          	addi	s4,s4,410 # 80016a00 <tickslock>
    char *pa = kalloc();
    8000186e:	fffff097          	auipc	ra,0xfffff
    80001872:	278080e7          	jalr	632(ra) # 80000ae6 <kalloc>
    80001876:	862a                	mv	a2,a0
    if(pa == 0)
    80001878:	c131                	beqz	a0,800018bc <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    8000187a:	416485b3          	sub	a1,s1,s6
    8000187e:	858d                	srai	a1,a1,0x3
    80001880:	000ab783          	ld	a5,0(s5)
    80001884:	02f585b3          	mul	a1,a1,a5
    80001888:	2585                	addiw	a1,a1,1
    8000188a:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000188e:	4719                	li	a4,6
    80001890:	6685                	lui	a3,0x1
    80001892:	40b905b3          	sub	a1,s2,a1
    80001896:	854e                	mv	a0,s3
    80001898:	00000097          	auipc	ra,0x0
    8000189c:	8a6080e7          	jalr	-1882(ra) # 8000113e <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018a0:	16848493          	addi	s1,s1,360
    800018a4:	fd4495e3          	bne	s1,s4,8000186e <proc_mapstacks+0x38>
  }
}
    800018a8:	70e2                	ld	ra,56(sp)
    800018aa:	7442                	ld	s0,48(sp)
    800018ac:	74a2                	ld	s1,40(sp)
    800018ae:	7902                	ld	s2,32(sp)
    800018b0:	69e2                	ld	s3,24(sp)
    800018b2:	6a42                	ld	s4,16(sp)
    800018b4:	6aa2                	ld	s5,8(sp)
    800018b6:	6b02                	ld	s6,0(sp)
    800018b8:	6121                	addi	sp,sp,64
    800018ba:	8082                	ret
      panic("kalloc");
    800018bc:	00007517          	auipc	a0,0x7
    800018c0:	91c50513          	addi	a0,a0,-1764 # 800081d8 <digits+0x198>
    800018c4:	fffff097          	auipc	ra,0xfffff
    800018c8:	c7c080e7          	jalr	-900(ra) # 80000540 <panic>

00000000800018cc <procinit>:

// initialize the proc table.
void
procinit(void)
{
    800018cc:	7139                	addi	sp,sp,-64
    800018ce:	fc06                	sd	ra,56(sp)
    800018d0:	f822                	sd	s0,48(sp)
    800018d2:	f426                	sd	s1,40(sp)
    800018d4:	f04a                	sd	s2,32(sp)
    800018d6:	ec4e                	sd	s3,24(sp)
    800018d8:	e852                	sd	s4,16(sp)
    800018da:	e456                	sd	s5,8(sp)
    800018dc:	e05a                	sd	s6,0(sp)
    800018de:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018e0:	00007597          	auipc	a1,0x7
    800018e4:	90058593          	addi	a1,a1,-1792 # 800081e0 <digits+0x1a0>
    800018e8:	0000f517          	auipc	a0,0xf
    800018ec:	2e850513          	addi	a0,a0,744 # 80010bd0 <pid_lock>
    800018f0:	fffff097          	auipc	ra,0xfffff
    800018f4:	256080e7          	jalr	598(ra) # 80000b46 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018f8:	00007597          	auipc	a1,0x7
    800018fc:	8f058593          	addi	a1,a1,-1808 # 800081e8 <digits+0x1a8>
    80001900:	0000f517          	auipc	a0,0xf
    80001904:	2e850513          	addi	a0,a0,744 # 80010be8 <wait_lock>
    80001908:	fffff097          	auipc	ra,0xfffff
    8000190c:	23e080e7          	jalr	574(ra) # 80000b46 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001910:	0000f497          	auipc	s1,0xf
    80001914:	6f048493          	addi	s1,s1,1776 # 80011000 <proc>
      initlock(&p->lock, "proc");
    80001918:	00007b17          	auipc	s6,0x7
    8000191c:	8e0b0b13          	addi	s6,s6,-1824 # 800081f8 <digits+0x1b8>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    80001920:	8aa6                	mv	s5,s1
    80001922:	00006a17          	auipc	s4,0x6
    80001926:	6dea0a13          	addi	s4,s4,1758 # 80008000 <etext>
    8000192a:	04000937          	lui	s2,0x4000
    8000192e:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001930:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001932:	00015997          	auipc	s3,0x15
    80001936:	0ce98993          	addi	s3,s3,206 # 80016a00 <tickslock>
      initlock(&p->lock, "proc");
    8000193a:	85da                	mv	a1,s6
    8000193c:	8526                	mv	a0,s1
    8000193e:	fffff097          	auipc	ra,0xfffff
    80001942:	208080e7          	jalr	520(ra) # 80000b46 <initlock>
      p->state = UNUSED;
    80001946:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    8000194a:	415487b3          	sub	a5,s1,s5
    8000194e:	878d                	srai	a5,a5,0x3
    80001950:	000a3703          	ld	a4,0(s4)
    80001954:	02e787b3          	mul	a5,a5,a4
    80001958:	2785                	addiw	a5,a5,1
    8000195a:	00d7979b          	slliw	a5,a5,0xd
    8000195e:	40f907b3          	sub	a5,s2,a5
    80001962:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001964:	16848493          	addi	s1,s1,360
    80001968:	fd3499e3          	bne	s1,s3,8000193a <procinit+0x6e>
  }
}
    8000196c:	70e2                	ld	ra,56(sp)
    8000196e:	7442                	ld	s0,48(sp)
    80001970:	74a2                	ld	s1,40(sp)
    80001972:	7902                	ld	s2,32(sp)
    80001974:	69e2                	ld	s3,24(sp)
    80001976:	6a42                	ld	s4,16(sp)
    80001978:	6aa2                	ld	s5,8(sp)
    8000197a:	6b02                	ld	s6,0(sp)
    8000197c:	6121                	addi	sp,sp,64
    8000197e:	8082                	ret

0000000080001980 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001980:	1141                	addi	sp,sp,-16
    80001982:	e422                	sd	s0,8(sp)
    80001984:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001986:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001988:	2501                	sext.w	a0,a0
    8000198a:	6422                	ld	s0,8(sp)
    8000198c:	0141                	addi	sp,sp,16
    8000198e:	8082                	ret

0000000080001990 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    80001990:	1141                	addi	sp,sp,-16
    80001992:	e422                	sd	s0,8(sp)
    80001994:	0800                	addi	s0,sp,16
    80001996:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001998:	2781                	sext.w	a5,a5
    8000199a:	079e                	slli	a5,a5,0x7
  return c;
}
    8000199c:	0000f517          	auipc	a0,0xf
    800019a0:	26450513          	addi	a0,a0,612 # 80010c00 <cpus>
    800019a4:	953e                	add	a0,a0,a5
    800019a6:	6422                	ld	s0,8(sp)
    800019a8:	0141                	addi	sp,sp,16
    800019aa:	8082                	ret

00000000800019ac <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    800019ac:	1101                	addi	sp,sp,-32
    800019ae:	ec06                	sd	ra,24(sp)
    800019b0:	e822                	sd	s0,16(sp)
    800019b2:	e426                	sd	s1,8(sp)
    800019b4:	1000                	addi	s0,sp,32
  push_off();
    800019b6:	fffff097          	auipc	ra,0xfffff
    800019ba:	1d4080e7          	jalr	468(ra) # 80000b8a <push_off>
    800019be:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019c0:	2781                	sext.w	a5,a5
    800019c2:	079e                	slli	a5,a5,0x7
    800019c4:	0000f717          	auipc	a4,0xf
    800019c8:	20c70713          	addi	a4,a4,524 # 80010bd0 <pid_lock>
    800019cc:	97ba                	add	a5,a5,a4
    800019ce:	7b84                	ld	s1,48(a5)
  pop_off();
    800019d0:	fffff097          	auipc	ra,0xfffff
    800019d4:	25a080e7          	jalr	602(ra) # 80000c2a <pop_off>
  return p;
}
    800019d8:	8526                	mv	a0,s1
    800019da:	60e2                	ld	ra,24(sp)
    800019dc:	6442                	ld	s0,16(sp)
    800019de:	64a2                	ld	s1,8(sp)
    800019e0:	6105                	addi	sp,sp,32
    800019e2:	8082                	ret

00000000800019e4 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019e4:	1141                	addi	sp,sp,-16
    800019e6:	e406                	sd	ra,8(sp)
    800019e8:	e022                	sd	s0,0(sp)
    800019ea:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019ec:	00000097          	auipc	ra,0x0
    800019f0:	fc0080e7          	jalr	-64(ra) # 800019ac <myproc>
    800019f4:	fffff097          	auipc	ra,0xfffff
    800019f8:	296080e7          	jalr	662(ra) # 80000c8a <release>

  if (first) {
    800019fc:	00007797          	auipc	a5,0x7
    80001a00:	ec47a783          	lw	a5,-316(a5) # 800088c0 <first.2>
    80001a04:	eb89                	bnez	a5,80001a16 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a06:	00001097          	auipc	ra,0x1
    80001a0a:	cfc080e7          	jalr	-772(ra) # 80002702 <usertrapret>
}
    80001a0e:	60a2                	ld	ra,8(sp)
    80001a10:	6402                	ld	s0,0(sp)
    80001a12:	0141                	addi	sp,sp,16
    80001a14:	8082                	ret
    first = 0;
    80001a16:	00007797          	auipc	a5,0x7
    80001a1a:	ea07a523          	sw	zero,-342(a5) # 800088c0 <first.2>
    fsinit(ROOTDEV);
    80001a1e:	4505                	li	a0,1
    80001a20:	00002097          	auipc	ra,0x2
    80001a24:	a48080e7          	jalr	-1464(ra) # 80003468 <fsinit>
    80001a28:	bff9                	j	80001a06 <forkret+0x22>

0000000080001a2a <allocpid>:
{
    80001a2a:	1101                	addi	sp,sp,-32
    80001a2c:	ec06                	sd	ra,24(sp)
    80001a2e:	e822                	sd	s0,16(sp)
    80001a30:	e426                	sd	s1,8(sp)
    80001a32:	e04a                	sd	s2,0(sp)
    80001a34:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a36:	0000f917          	auipc	s2,0xf
    80001a3a:	19a90913          	addi	s2,s2,410 # 80010bd0 <pid_lock>
    80001a3e:	854a                	mv	a0,s2
    80001a40:	fffff097          	auipc	ra,0xfffff
    80001a44:	196080e7          	jalr	406(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001a48:	00007797          	auipc	a5,0x7
    80001a4c:	e7c78793          	addi	a5,a5,-388 # 800088c4 <nextpid>
    80001a50:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a52:	0014871b          	addiw	a4,s1,1
    80001a56:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a58:	854a                	mv	a0,s2
    80001a5a:	fffff097          	auipc	ra,0xfffff
    80001a5e:	230080e7          	jalr	560(ra) # 80000c8a <release>
}
    80001a62:	8526                	mv	a0,s1
    80001a64:	60e2                	ld	ra,24(sp)
    80001a66:	6442                	ld	s0,16(sp)
    80001a68:	64a2                	ld	s1,8(sp)
    80001a6a:	6902                	ld	s2,0(sp)
    80001a6c:	6105                	addi	sp,sp,32
    80001a6e:	8082                	ret

0000000080001a70 <proc_pagetable>:
{
    80001a70:	1101                	addi	sp,sp,-32
    80001a72:	ec06                	sd	ra,24(sp)
    80001a74:	e822                	sd	s0,16(sp)
    80001a76:	e426                	sd	s1,8(sp)
    80001a78:	e04a                	sd	s2,0(sp)
    80001a7a:	1000                	addi	s0,sp,32
    80001a7c:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a7e:	00000097          	auipc	ra,0x0
    80001a82:	8aa080e7          	jalr	-1878(ra) # 80001328 <uvmcreate>
    80001a86:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a88:	c121                	beqz	a0,80001ac8 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a8a:	4729                	li	a4,10
    80001a8c:	00005697          	auipc	a3,0x5
    80001a90:	57468693          	addi	a3,a3,1396 # 80007000 <_trampoline>
    80001a94:	6605                	lui	a2,0x1
    80001a96:	040005b7          	lui	a1,0x4000
    80001a9a:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001a9c:	05b2                	slli	a1,a1,0xc
    80001a9e:	fffff097          	auipc	ra,0xfffff
    80001aa2:	600080e7          	jalr	1536(ra) # 8000109e <mappages>
    80001aa6:	02054863          	bltz	a0,80001ad6 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001aaa:	4719                	li	a4,6
    80001aac:	05893683          	ld	a3,88(s2)
    80001ab0:	6605                	lui	a2,0x1
    80001ab2:	020005b7          	lui	a1,0x2000
    80001ab6:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001ab8:	05b6                	slli	a1,a1,0xd
    80001aba:	8526                	mv	a0,s1
    80001abc:	fffff097          	auipc	ra,0xfffff
    80001ac0:	5e2080e7          	jalr	1506(ra) # 8000109e <mappages>
    80001ac4:	02054163          	bltz	a0,80001ae6 <proc_pagetable+0x76>
}
    80001ac8:	8526                	mv	a0,s1
    80001aca:	60e2                	ld	ra,24(sp)
    80001acc:	6442                	ld	s0,16(sp)
    80001ace:	64a2                	ld	s1,8(sp)
    80001ad0:	6902                	ld	s2,0(sp)
    80001ad2:	6105                	addi	sp,sp,32
    80001ad4:	8082                	ret
    uvmfree(pagetable, 0);
    80001ad6:	4581                	li	a1,0
    80001ad8:	8526                	mv	a0,s1
    80001ada:	00000097          	auipc	ra,0x0
    80001ade:	a54080e7          	jalr	-1452(ra) # 8000152e <uvmfree>
    return 0;
    80001ae2:	4481                	li	s1,0
    80001ae4:	b7d5                	j	80001ac8 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ae6:	4681                	li	a3,0
    80001ae8:	4605                	li	a2,1
    80001aea:	040005b7          	lui	a1,0x4000
    80001aee:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001af0:	05b2                	slli	a1,a1,0xc
    80001af2:	8526                	mv	a0,s1
    80001af4:	fffff097          	auipc	ra,0xfffff
    80001af8:	770080e7          	jalr	1904(ra) # 80001264 <uvmunmap>
    uvmfree(pagetable, 0);
    80001afc:	4581                	li	a1,0
    80001afe:	8526                	mv	a0,s1
    80001b00:	00000097          	auipc	ra,0x0
    80001b04:	a2e080e7          	jalr	-1490(ra) # 8000152e <uvmfree>
    return 0;
    80001b08:	4481                	li	s1,0
    80001b0a:	bf7d                	j	80001ac8 <proc_pagetable+0x58>

0000000080001b0c <proc_freepagetable>:
{
    80001b0c:	1101                	addi	sp,sp,-32
    80001b0e:	ec06                	sd	ra,24(sp)
    80001b10:	e822                	sd	s0,16(sp)
    80001b12:	e426                	sd	s1,8(sp)
    80001b14:	e04a                	sd	s2,0(sp)
    80001b16:	1000                	addi	s0,sp,32
    80001b18:	84aa                	mv	s1,a0
    80001b1a:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b1c:	4681                	li	a3,0
    80001b1e:	4605                	li	a2,1
    80001b20:	040005b7          	lui	a1,0x4000
    80001b24:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b26:	05b2                	slli	a1,a1,0xc
    80001b28:	fffff097          	auipc	ra,0xfffff
    80001b2c:	73c080e7          	jalr	1852(ra) # 80001264 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b30:	4681                	li	a3,0
    80001b32:	4605                	li	a2,1
    80001b34:	020005b7          	lui	a1,0x2000
    80001b38:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b3a:	05b6                	slli	a1,a1,0xd
    80001b3c:	8526                	mv	a0,s1
    80001b3e:	fffff097          	auipc	ra,0xfffff
    80001b42:	726080e7          	jalr	1830(ra) # 80001264 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b46:	85ca                	mv	a1,s2
    80001b48:	8526                	mv	a0,s1
    80001b4a:	00000097          	auipc	ra,0x0
    80001b4e:	9e4080e7          	jalr	-1564(ra) # 8000152e <uvmfree>
}
    80001b52:	60e2                	ld	ra,24(sp)
    80001b54:	6442                	ld	s0,16(sp)
    80001b56:	64a2                	ld	s1,8(sp)
    80001b58:	6902                	ld	s2,0(sp)
    80001b5a:	6105                	addi	sp,sp,32
    80001b5c:	8082                	ret

0000000080001b5e <freeproc>:
{
    80001b5e:	1101                	addi	sp,sp,-32
    80001b60:	ec06                	sd	ra,24(sp)
    80001b62:	e822                	sd	s0,16(sp)
    80001b64:	e426                	sd	s1,8(sp)
    80001b66:	1000                	addi	s0,sp,32
    80001b68:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b6a:	6d28                	ld	a0,88(a0)
    80001b6c:	c509                	beqz	a0,80001b76 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b6e:	fffff097          	auipc	ra,0xfffff
    80001b72:	e7a080e7          	jalr	-390(ra) # 800009e8 <kfree>
  p->trapframe = 0;
    80001b76:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b7a:	68a8                	ld	a0,80(s1)
    80001b7c:	c511                	beqz	a0,80001b88 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b7e:	64ac                	ld	a1,72(s1)
    80001b80:	00000097          	auipc	ra,0x0
    80001b84:	f8c080e7          	jalr	-116(ra) # 80001b0c <proc_freepagetable>
  p->pagetable = 0;
    80001b88:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b8c:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b90:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b94:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b98:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001b9c:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001ba0:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001ba4:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001ba8:	0004ac23          	sw	zero,24(s1)
}
    80001bac:	60e2                	ld	ra,24(sp)
    80001bae:	6442                	ld	s0,16(sp)
    80001bb0:	64a2                	ld	s1,8(sp)
    80001bb2:	6105                	addi	sp,sp,32
    80001bb4:	8082                	ret

0000000080001bb6 <allocproc>:
{
    80001bb6:	1101                	addi	sp,sp,-32
    80001bb8:	ec06                	sd	ra,24(sp)
    80001bba:	e822                	sd	s0,16(sp)
    80001bbc:	e426                	sd	s1,8(sp)
    80001bbe:	e04a                	sd	s2,0(sp)
    80001bc0:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bc2:	0000f497          	auipc	s1,0xf
    80001bc6:	43e48493          	addi	s1,s1,1086 # 80011000 <proc>
    80001bca:	00015917          	auipc	s2,0x15
    80001bce:	e3690913          	addi	s2,s2,-458 # 80016a00 <tickslock>
    acquire(&p->lock);
    80001bd2:	8526                	mv	a0,s1
    80001bd4:	fffff097          	auipc	ra,0xfffff
    80001bd8:	002080e7          	jalr	2(ra) # 80000bd6 <acquire>
    if(p->state == UNUSED) {
    80001bdc:	4c9c                	lw	a5,24(s1)
    80001bde:	cf81                	beqz	a5,80001bf6 <allocproc+0x40>
      release(&p->lock);
    80001be0:	8526                	mv	a0,s1
    80001be2:	fffff097          	auipc	ra,0xfffff
    80001be6:	0a8080e7          	jalr	168(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bea:	16848493          	addi	s1,s1,360
    80001bee:	ff2492e3          	bne	s1,s2,80001bd2 <allocproc+0x1c>
  return 0;
    80001bf2:	4481                	li	s1,0
    80001bf4:	a889                	j	80001c46 <allocproc+0x90>
  p->pid = allocpid();
    80001bf6:	00000097          	auipc	ra,0x0
    80001bfa:	e34080e7          	jalr	-460(ra) # 80001a2a <allocpid>
    80001bfe:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c00:	4785                	li	a5,1
    80001c02:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c04:	fffff097          	auipc	ra,0xfffff
    80001c08:	ee2080e7          	jalr	-286(ra) # 80000ae6 <kalloc>
    80001c0c:	892a                	mv	s2,a0
    80001c0e:	eca8                	sd	a0,88(s1)
    80001c10:	c131                	beqz	a0,80001c54 <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001c12:	8526                	mv	a0,s1
    80001c14:	00000097          	auipc	ra,0x0
    80001c18:	e5c080e7          	jalr	-420(ra) # 80001a70 <proc_pagetable>
    80001c1c:	892a                	mv	s2,a0
    80001c1e:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c20:	c531                	beqz	a0,80001c6c <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001c22:	07000613          	li	a2,112
    80001c26:	4581                	li	a1,0
    80001c28:	06048513          	addi	a0,s1,96
    80001c2c:	fffff097          	auipc	ra,0xfffff
    80001c30:	0a6080e7          	jalr	166(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001c34:	00000797          	auipc	a5,0x0
    80001c38:	db078793          	addi	a5,a5,-592 # 800019e4 <forkret>
    80001c3c:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c3e:	60bc                	ld	a5,64(s1)
    80001c40:	6705                	lui	a4,0x1
    80001c42:	97ba                	add	a5,a5,a4
    80001c44:	f4bc                	sd	a5,104(s1)
}
    80001c46:	8526                	mv	a0,s1
    80001c48:	60e2                	ld	ra,24(sp)
    80001c4a:	6442                	ld	s0,16(sp)
    80001c4c:	64a2                	ld	s1,8(sp)
    80001c4e:	6902                	ld	s2,0(sp)
    80001c50:	6105                	addi	sp,sp,32
    80001c52:	8082                	ret
    freeproc(p);
    80001c54:	8526                	mv	a0,s1
    80001c56:	00000097          	auipc	ra,0x0
    80001c5a:	f08080e7          	jalr	-248(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001c5e:	8526                	mv	a0,s1
    80001c60:	fffff097          	auipc	ra,0xfffff
    80001c64:	02a080e7          	jalr	42(ra) # 80000c8a <release>
    return 0;
    80001c68:	84ca                	mv	s1,s2
    80001c6a:	bff1                	j	80001c46 <allocproc+0x90>
    freeproc(p);
    80001c6c:	8526                	mv	a0,s1
    80001c6e:	00000097          	auipc	ra,0x0
    80001c72:	ef0080e7          	jalr	-272(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001c76:	8526                	mv	a0,s1
    80001c78:	fffff097          	auipc	ra,0xfffff
    80001c7c:	012080e7          	jalr	18(ra) # 80000c8a <release>
    return 0;
    80001c80:	84ca                	mv	s1,s2
    80001c82:	b7d1                	j	80001c46 <allocproc+0x90>

0000000080001c84 <userinit>:
{
    80001c84:	1101                	addi	sp,sp,-32
    80001c86:	ec06                	sd	ra,24(sp)
    80001c88:	e822                	sd	s0,16(sp)
    80001c8a:	e426                	sd	s1,8(sp)
    80001c8c:	1000                	addi	s0,sp,32
  p = allocproc();
    80001c8e:	00000097          	auipc	ra,0x0
    80001c92:	f28080e7          	jalr	-216(ra) # 80001bb6 <allocproc>
    80001c96:	84aa                	mv	s1,a0
  initproc = p;
    80001c98:	00007797          	auipc	a5,0x7
    80001c9c:	cca7b023          	sd	a0,-832(a5) # 80008958 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001ca0:	03400613          	li	a2,52
    80001ca4:	00007597          	auipc	a1,0x7
    80001ca8:	c2c58593          	addi	a1,a1,-980 # 800088d0 <initcode>
    80001cac:	6928                	ld	a0,80(a0)
    80001cae:	fffff097          	auipc	ra,0xfffff
    80001cb2:	6a8080e7          	jalr	1704(ra) # 80001356 <uvmfirst>
  p->sz = PGSIZE;
    80001cb6:	6785                	lui	a5,0x1
    80001cb8:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cba:	6cb8                	ld	a4,88(s1)
    80001cbc:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cc0:	6cb8                	ld	a4,88(s1)
    80001cc2:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cc4:	4641                	li	a2,16
    80001cc6:	00006597          	auipc	a1,0x6
    80001cca:	53a58593          	addi	a1,a1,1338 # 80008200 <digits+0x1c0>
    80001cce:	15848513          	addi	a0,s1,344
    80001cd2:	fffff097          	auipc	ra,0xfffff
    80001cd6:	14a080e7          	jalr	330(ra) # 80000e1c <safestrcpy>
  p->cwd = namei("/");
    80001cda:	00006517          	auipc	a0,0x6
    80001cde:	53650513          	addi	a0,a0,1334 # 80008210 <digits+0x1d0>
    80001ce2:	00002097          	auipc	ra,0x2
    80001ce6:	1b0080e7          	jalr	432(ra) # 80003e92 <namei>
    80001cea:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001cee:	478d                	li	a5,3
    80001cf0:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001cf2:	8526                	mv	a0,s1
    80001cf4:	fffff097          	auipc	ra,0xfffff
    80001cf8:	f96080e7          	jalr	-106(ra) # 80000c8a <release>
}
    80001cfc:	60e2                	ld	ra,24(sp)
    80001cfe:	6442                	ld	s0,16(sp)
    80001d00:	64a2                	ld	s1,8(sp)
    80001d02:	6105                	addi	sp,sp,32
    80001d04:	8082                	ret

0000000080001d06 <growproc>:
{
    80001d06:	1101                	addi	sp,sp,-32
    80001d08:	ec06                	sd	ra,24(sp)
    80001d0a:	e822                	sd	s0,16(sp)
    80001d0c:	e426                	sd	s1,8(sp)
    80001d0e:	e04a                	sd	s2,0(sp)
    80001d10:	1000                	addi	s0,sp,32
    80001d12:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d14:	00000097          	auipc	ra,0x0
    80001d18:	c98080e7          	jalr	-872(ra) # 800019ac <myproc>
    80001d1c:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d1e:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001d20:	01204c63          	bgtz	s2,80001d38 <growproc+0x32>
  } else if(n < 0){
    80001d24:	02094663          	bltz	s2,80001d50 <growproc+0x4a>
  p->sz = sz;
    80001d28:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d2a:	4501                	li	a0,0
}
    80001d2c:	60e2                	ld	ra,24(sp)
    80001d2e:	6442                	ld	s0,16(sp)
    80001d30:	64a2                	ld	s1,8(sp)
    80001d32:	6902                	ld	s2,0(sp)
    80001d34:	6105                	addi	sp,sp,32
    80001d36:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001d38:	4691                	li	a3,4
    80001d3a:	00b90633          	add	a2,s2,a1
    80001d3e:	6928                	ld	a0,80(a0)
    80001d40:	fffff097          	auipc	ra,0xfffff
    80001d44:	6d0080e7          	jalr	1744(ra) # 80001410 <uvmalloc>
    80001d48:	85aa                	mv	a1,a0
    80001d4a:	fd79                	bnez	a0,80001d28 <growproc+0x22>
      return -1;
    80001d4c:	557d                	li	a0,-1
    80001d4e:	bff9                	j	80001d2c <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d50:	00b90633          	add	a2,s2,a1
    80001d54:	6928                	ld	a0,80(a0)
    80001d56:	fffff097          	auipc	ra,0xfffff
    80001d5a:	672080e7          	jalr	1650(ra) # 800013c8 <uvmdealloc>
    80001d5e:	85aa                	mv	a1,a0
    80001d60:	b7e1                	j	80001d28 <growproc+0x22>

0000000080001d62 <fork>:
{
    80001d62:	7139                	addi	sp,sp,-64
    80001d64:	fc06                	sd	ra,56(sp)
    80001d66:	f822                	sd	s0,48(sp)
    80001d68:	f426                	sd	s1,40(sp)
    80001d6a:	f04a                	sd	s2,32(sp)
    80001d6c:	ec4e                	sd	s3,24(sp)
    80001d6e:	e852                	sd	s4,16(sp)
    80001d70:	e456                	sd	s5,8(sp)
    80001d72:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001d74:	00000097          	auipc	ra,0x0
    80001d78:	c38080e7          	jalr	-968(ra) # 800019ac <myproc>
    80001d7c:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001d7e:	00000097          	auipc	ra,0x0
    80001d82:	e38080e7          	jalr	-456(ra) # 80001bb6 <allocproc>
    80001d86:	10050c63          	beqz	a0,80001e9e <fork+0x13c>
    80001d8a:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001d8c:	048ab603          	ld	a2,72(s5)
    80001d90:	692c                	ld	a1,80(a0)
    80001d92:	050ab503          	ld	a0,80(s5)
    80001d96:	fffff097          	auipc	ra,0xfffff
    80001d9a:	7d2080e7          	jalr	2002(ra) # 80001568 <uvmcopy>
    80001d9e:	04054863          	bltz	a0,80001dee <fork+0x8c>
  np->sz = p->sz;
    80001da2:	048ab783          	ld	a5,72(s5)
    80001da6:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001daa:	058ab683          	ld	a3,88(s5)
    80001dae:	87b6                	mv	a5,a3
    80001db0:	058a3703          	ld	a4,88(s4)
    80001db4:	12068693          	addi	a3,a3,288
    80001db8:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dbc:	6788                	ld	a0,8(a5)
    80001dbe:	6b8c                	ld	a1,16(a5)
    80001dc0:	6f90                	ld	a2,24(a5)
    80001dc2:	01073023          	sd	a6,0(a4)
    80001dc6:	e708                	sd	a0,8(a4)
    80001dc8:	eb0c                	sd	a1,16(a4)
    80001dca:	ef10                	sd	a2,24(a4)
    80001dcc:	02078793          	addi	a5,a5,32
    80001dd0:	02070713          	addi	a4,a4,32
    80001dd4:	fed792e3          	bne	a5,a3,80001db8 <fork+0x56>
  np->trapframe->a0 = 0;
    80001dd8:	058a3783          	ld	a5,88(s4)
    80001ddc:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001de0:	0d0a8493          	addi	s1,s5,208
    80001de4:	0d0a0913          	addi	s2,s4,208
    80001de8:	150a8993          	addi	s3,s5,336
    80001dec:	a00d                	j	80001e0e <fork+0xac>
    freeproc(np);
    80001dee:	8552                	mv	a0,s4
    80001df0:	00000097          	auipc	ra,0x0
    80001df4:	d6e080e7          	jalr	-658(ra) # 80001b5e <freeproc>
    release(&np->lock);
    80001df8:	8552                	mv	a0,s4
    80001dfa:	fffff097          	auipc	ra,0xfffff
    80001dfe:	e90080e7          	jalr	-368(ra) # 80000c8a <release>
    return -1;
    80001e02:	597d                	li	s2,-1
    80001e04:	a059                	j	80001e8a <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    80001e06:	04a1                	addi	s1,s1,8
    80001e08:	0921                	addi	s2,s2,8
    80001e0a:	01348b63          	beq	s1,s3,80001e20 <fork+0xbe>
    if(p->ofile[i])
    80001e0e:	6088                	ld	a0,0(s1)
    80001e10:	d97d                	beqz	a0,80001e06 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e12:	00002097          	auipc	ra,0x2
    80001e16:	716080e7          	jalr	1814(ra) # 80004528 <filedup>
    80001e1a:	00a93023          	sd	a0,0(s2)
    80001e1e:	b7e5                	j	80001e06 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e20:	150ab503          	ld	a0,336(s5)
    80001e24:	00002097          	auipc	ra,0x2
    80001e28:	884080e7          	jalr	-1916(ra) # 800036a8 <idup>
    80001e2c:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e30:	4641                	li	a2,16
    80001e32:	158a8593          	addi	a1,s5,344
    80001e36:	158a0513          	addi	a0,s4,344
    80001e3a:	fffff097          	auipc	ra,0xfffff
    80001e3e:	fe2080e7          	jalr	-30(ra) # 80000e1c <safestrcpy>
  pid = np->pid;
    80001e42:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001e46:	8552                	mv	a0,s4
    80001e48:	fffff097          	auipc	ra,0xfffff
    80001e4c:	e42080e7          	jalr	-446(ra) # 80000c8a <release>
  acquire(&wait_lock);
    80001e50:	0000f497          	auipc	s1,0xf
    80001e54:	d9848493          	addi	s1,s1,-616 # 80010be8 <wait_lock>
    80001e58:	8526                	mv	a0,s1
    80001e5a:	fffff097          	auipc	ra,0xfffff
    80001e5e:	d7c080e7          	jalr	-644(ra) # 80000bd6 <acquire>
  np->parent = p;
    80001e62:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001e66:	8526                	mv	a0,s1
    80001e68:	fffff097          	auipc	ra,0xfffff
    80001e6c:	e22080e7          	jalr	-478(ra) # 80000c8a <release>
  acquire(&np->lock);
    80001e70:	8552                	mv	a0,s4
    80001e72:	fffff097          	auipc	ra,0xfffff
    80001e76:	d64080e7          	jalr	-668(ra) # 80000bd6 <acquire>
  np->state = RUNNABLE;
    80001e7a:	478d                	li	a5,3
    80001e7c:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001e80:	8552                	mv	a0,s4
    80001e82:	fffff097          	auipc	ra,0xfffff
    80001e86:	e08080e7          	jalr	-504(ra) # 80000c8a <release>
}
    80001e8a:	854a                	mv	a0,s2
    80001e8c:	70e2                	ld	ra,56(sp)
    80001e8e:	7442                	ld	s0,48(sp)
    80001e90:	74a2                	ld	s1,40(sp)
    80001e92:	7902                	ld	s2,32(sp)
    80001e94:	69e2                	ld	s3,24(sp)
    80001e96:	6a42                	ld	s4,16(sp)
    80001e98:	6aa2                	ld	s5,8(sp)
    80001e9a:	6121                	addi	sp,sp,64
    80001e9c:	8082                	ret
    return -1;
    80001e9e:	597d                	li	s2,-1
    80001ea0:	b7ed                	j	80001e8a <fork+0x128>

0000000080001ea2 <scheduler>:
{
    80001ea2:	7139                	addi	sp,sp,-64
    80001ea4:	fc06                	sd	ra,56(sp)
    80001ea6:	f822                	sd	s0,48(sp)
    80001ea8:	f426                	sd	s1,40(sp)
    80001eaa:	f04a                	sd	s2,32(sp)
    80001eac:	ec4e                	sd	s3,24(sp)
    80001eae:	e852                	sd	s4,16(sp)
    80001eb0:	e456                	sd	s5,8(sp)
    80001eb2:	e05a                	sd	s6,0(sp)
    80001eb4:	0080                	addi	s0,sp,64
    80001eb6:	8792                	mv	a5,tp
  int id = r_tp();
    80001eb8:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001eba:	00779a93          	slli	s5,a5,0x7
    80001ebe:	0000f717          	auipc	a4,0xf
    80001ec2:	d1270713          	addi	a4,a4,-750 # 80010bd0 <pid_lock>
    80001ec6:	9756                	add	a4,a4,s5
    80001ec8:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001ecc:	0000f717          	auipc	a4,0xf
    80001ed0:	d3c70713          	addi	a4,a4,-708 # 80010c08 <cpus+0x8>
    80001ed4:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001ed6:	498d                	li	s3,3
        p->state = RUNNING;
    80001ed8:	4b11                	li	s6,4
        c->proc = p;
    80001eda:	079e                	slli	a5,a5,0x7
    80001edc:	0000fa17          	auipc	s4,0xf
    80001ee0:	cf4a0a13          	addi	s4,s4,-780 # 80010bd0 <pid_lock>
    80001ee4:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001ee6:	00015917          	auipc	s2,0x15
    80001eea:	b1a90913          	addi	s2,s2,-1254 # 80016a00 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001eee:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001ef2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001ef6:	10079073          	csrw	sstatus,a5
    80001efa:	0000f497          	auipc	s1,0xf
    80001efe:	10648493          	addi	s1,s1,262 # 80011000 <proc>
    80001f02:	a811                	j	80001f16 <scheduler+0x74>
      release(&p->lock);
    80001f04:	8526                	mv	a0,s1
    80001f06:	fffff097          	auipc	ra,0xfffff
    80001f0a:	d84080e7          	jalr	-636(ra) # 80000c8a <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f0e:	16848493          	addi	s1,s1,360
    80001f12:	fd248ee3          	beq	s1,s2,80001eee <scheduler+0x4c>
      acquire(&p->lock);
    80001f16:	8526                	mv	a0,s1
    80001f18:	fffff097          	auipc	ra,0xfffff
    80001f1c:	cbe080e7          	jalr	-834(ra) # 80000bd6 <acquire>
      if(p->state == RUNNABLE) {
    80001f20:	4c9c                	lw	a5,24(s1)
    80001f22:	ff3791e3          	bne	a5,s3,80001f04 <scheduler+0x62>
        p->state = RUNNING;
    80001f26:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f2a:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f2e:	06048593          	addi	a1,s1,96
    80001f32:	8556                	mv	a0,s5
    80001f34:	00000097          	auipc	ra,0x0
    80001f38:	724080e7          	jalr	1828(ra) # 80002658 <swtch>
        c->proc = 0;
    80001f3c:	020a3823          	sd	zero,48(s4)
    80001f40:	b7d1                	j	80001f04 <scheduler+0x62>

0000000080001f42 <sched>:
{
    80001f42:	7179                	addi	sp,sp,-48
    80001f44:	f406                	sd	ra,40(sp)
    80001f46:	f022                	sd	s0,32(sp)
    80001f48:	ec26                	sd	s1,24(sp)
    80001f4a:	e84a                	sd	s2,16(sp)
    80001f4c:	e44e                	sd	s3,8(sp)
    80001f4e:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f50:	00000097          	auipc	ra,0x0
    80001f54:	a5c080e7          	jalr	-1444(ra) # 800019ac <myproc>
    80001f58:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001f5a:	fffff097          	auipc	ra,0xfffff
    80001f5e:	c02080e7          	jalr	-1022(ra) # 80000b5c <holding>
    80001f62:	c93d                	beqz	a0,80001fd8 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f64:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001f66:	2781                	sext.w	a5,a5
    80001f68:	079e                	slli	a5,a5,0x7
    80001f6a:	0000f717          	auipc	a4,0xf
    80001f6e:	c6670713          	addi	a4,a4,-922 # 80010bd0 <pid_lock>
    80001f72:	97ba                	add	a5,a5,a4
    80001f74:	0a87a703          	lw	a4,168(a5)
    80001f78:	4785                	li	a5,1
    80001f7a:	06f71763          	bne	a4,a5,80001fe8 <sched+0xa6>
  if(p->state == RUNNING)
    80001f7e:	4c98                	lw	a4,24(s1)
    80001f80:	4791                	li	a5,4
    80001f82:	06f70b63          	beq	a4,a5,80001ff8 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f86:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001f8a:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001f8c:	efb5                	bnez	a5,80002008 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f8e:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001f90:	0000f917          	auipc	s2,0xf
    80001f94:	c4090913          	addi	s2,s2,-960 # 80010bd0 <pid_lock>
    80001f98:	2781                	sext.w	a5,a5
    80001f9a:	079e                	slli	a5,a5,0x7
    80001f9c:	97ca                	add	a5,a5,s2
    80001f9e:	0ac7a983          	lw	s3,172(a5)
    80001fa2:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001fa4:	2781                	sext.w	a5,a5
    80001fa6:	079e                	slli	a5,a5,0x7
    80001fa8:	0000f597          	auipc	a1,0xf
    80001fac:	c6058593          	addi	a1,a1,-928 # 80010c08 <cpus+0x8>
    80001fb0:	95be                	add	a1,a1,a5
    80001fb2:	06048513          	addi	a0,s1,96
    80001fb6:	00000097          	auipc	ra,0x0
    80001fba:	6a2080e7          	jalr	1698(ra) # 80002658 <swtch>
    80001fbe:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001fc0:	2781                	sext.w	a5,a5
    80001fc2:	079e                	slli	a5,a5,0x7
    80001fc4:	993e                	add	s2,s2,a5
    80001fc6:	0b392623          	sw	s3,172(s2)
}
    80001fca:	70a2                	ld	ra,40(sp)
    80001fcc:	7402                	ld	s0,32(sp)
    80001fce:	64e2                	ld	s1,24(sp)
    80001fd0:	6942                	ld	s2,16(sp)
    80001fd2:	69a2                	ld	s3,8(sp)
    80001fd4:	6145                	addi	sp,sp,48
    80001fd6:	8082                	ret
    panic("sched p->lock");
    80001fd8:	00006517          	auipc	a0,0x6
    80001fdc:	24050513          	addi	a0,a0,576 # 80008218 <digits+0x1d8>
    80001fe0:	ffffe097          	auipc	ra,0xffffe
    80001fe4:	560080e7          	jalr	1376(ra) # 80000540 <panic>
    panic("sched locks");
    80001fe8:	00006517          	auipc	a0,0x6
    80001fec:	24050513          	addi	a0,a0,576 # 80008228 <digits+0x1e8>
    80001ff0:	ffffe097          	auipc	ra,0xffffe
    80001ff4:	550080e7          	jalr	1360(ra) # 80000540 <panic>
    panic("sched running");
    80001ff8:	00006517          	auipc	a0,0x6
    80001ffc:	24050513          	addi	a0,a0,576 # 80008238 <digits+0x1f8>
    80002000:	ffffe097          	auipc	ra,0xffffe
    80002004:	540080e7          	jalr	1344(ra) # 80000540 <panic>
    panic("sched interruptible");
    80002008:	00006517          	auipc	a0,0x6
    8000200c:	24050513          	addi	a0,a0,576 # 80008248 <digits+0x208>
    80002010:	ffffe097          	auipc	ra,0xffffe
    80002014:	530080e7          	jalr	1328(ra) # 80000540 <panic>

0000000080002018 <yield>:
{
    80002018:	1101                	addi	sp,sp,-32
    8000201a:	ec06                	sd	ra,24(sp)
    8000201c:	e822                	sd	s0,16(sp)
    8000201e:	e426                	sd	s1,8(sp)
    80002020:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002022:	00000097          	auipc	ra,0x0
    80002026:	98a080e7          	jalr	-1654(ra) # 800019ac <myproc>
    8000202a:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000202c:	fffff097          	auipc	ra,0xfffff
    80002030:	baa080e7          	jalr	-1110(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    80002034:	478d                	li	a5,3
    80002036:	cc9c                	sw	a5,24(s1)
  sched();
    80002038:	00000097          	auipc	ra,0x0
    8000203c:	f0a080e7          	jalr	-246(ra) # 80001f42 <sched>
  release(&p->lock);
    80002040:	8526                	mv	a0,s1
    80002042:	fffff097          	auipc	ra,0xfffff
    80002046:	c48080e7          	jalr	-952(ra) # 80000c8a <release>
}
    8000204a:	60e2                	ld	ra,24(sp)
    8000204c:	6442                	ld	s0,16(sp)
    8000204e:	64a2                	ld	s1,8(sp)
    80002050:	6105                	addi	sp,sp,32
    80002052:	8082                	ret

0000000080002054 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002054:	7179                	addi	sp,sp,-48
    80002056:	f406                	sd	ra,40(sp)
    80002058:	f022                	sd	s0,32(sp)
    8000205a:	ec26                	sd	s1,24(sp)
    8000205c:	e84a                	sd	s2,16(sp)
    8000205e:	e44e                	sd	s3,8(sp)
    80002060:	1800                	addi	s0,sp,48
    80002062:	89aa                	mv	s3,a0
    80002064:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002066:	00000097          	auipc	ra,0x0
    8000206a:	946080e7          	jalr	-1722(ra) # 800019ac <myproc>
    8000206e:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002070:	fffff097          	auipc	ra,0xfffff
    80002074:	b66080e7          	jalr	-1178(ra) # 80000bd6 <acquire>
  release(lk);
    80002078:	854a                	mv	a0,s2
    8000207a:	fffff097          	auipc	ra,0xfffff
    8000207e:	c10080e7          	jalr	-1008(ra) # 80000c8a <release>

  // Go to sleep.
  p->chan = chan;
    80002082:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002086:	4789                	li	a5,2
    80002088:	cc9c                	sw	a5,24(s1)

  sched();
    8000208a:	00000097          	auipc	ra,0x0
    8000208e:	eb8080e7          	jalr	-328(ra) # 80001f42 <sched>

  // Tidy up.
  p->chan = 0;
    80002092:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002096:	8526                	mv	a0,s1
    80002098:	fffff097          	auipc	ra,0xfffff
    8000209c:	bf2080e7          	jalr	-1038(ra) # 80000c8a <release>
  acquire(lk);
    800020a0:	854a                	mv	a0,s2
    800020a2:	fffff097          	auipc	ra,0xfffff
    800020a6:	b34080e7          	jalr	-1228(ra) # 80000bd6 <acquire>
}
    800020aa:	70a2                	ld	ra,40(sp)
    800020ac:	7402                	ld	s0,32(sp)
    800020ae:	64e2                	ld	s1,24(sp)
    800020b0:	6942                	ld	s2,16(sp)
    800020b2:	69a2                	ld	s3,8(sp)
    800020b4:	6145                	addi	sp,sp,48
    800020b6:	8082                	ret

00000000800020b8 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800020b8:	7139                	addi	sp,sp,-64
    800020ba:	fc06                	sd	ra,56(sp)
    800020bc:	f822                	sd	s0,48(sp)
    800020be:	f426                	sd	s1,40(sp)
    800020c0:	f04a                	sd	s2,32(sp)
    800020c2:	ec4e                	sd	s3,24(sp)
    800020c4:	e852                	sd	s4,16(sp)
    800020c6:	e456                	sd	s5,8(sp)
    800020c8:	0080                	addi	s0,sp,64
    800020ca:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800020cc:	0000f497          	auipc	s1,0xf
    800020d0:	f3448493          	addi	s1,s1,-204 # 80011000 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800020d4:	4989                	li	s3,2
        p->state = RUNNABLE;
    800020d6:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800020d8:	00015917          	auipc	s2,0x15
    800020dc:	92890913          	addi	s2,s2,-1752 # 80016a00 <tickslock>
    800020e0:	a811                	j	800020f4 <wakeup+0x3c>
      }
      release(&p->lock);
    800020e2:	8526                	mv	a0,s1
    800020e4:	fffff097          	auipc	ra,0xfffff
    800020e8:	ba6080e7          	jalr	-1114(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800020ec:	16848493          	addi	s1,s1,360
    800020f0:	03248663          	beq	s1,s2,8000211c <wakeup+0x64>
    if(p != myproc()){
    800020f4:	00000097          	auipc	ra,0x0
    800020f8:	8b8080e7          	jalr	-1864(ra) # 800019ac <myproc>
    800020fc:	fea488e3          	beq	s1,a0,800020ec <wakeup+0x34>
      acquire(&p->lock);
    80002100:	8526                	mv	a0,s1
    80002102:	fffff097          	auipc	ra,0xfffff
    80002106:	ad4080e7          	jalr	-1324(ra) # 80000bd6 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    8000210a:	4c9c                	lw	a5,24(s1)
    8000210c:	fd379be3          	bne	a5,s3,800020e2 <wakeup+0x2a>
    80002110:	709c                	ld	a5,32(s1)
    80002112:	fd4798e3          	bne	a5,s4,800020e2 <wakeup+0x2a>
        p->state = RUNNABLE;
    80002116:	0154ac23          	sw	s5,24(s1)
    8000211a:	b7e1                	j	800020e2 <wakeup+0x2a>
    }
  }
}
    8000211c:	70e2                	ld	ra,56(sp)
    8000211e:	7442                	ld	s0,48(sp)
    80002120:	74a2                	ld	s1,40(sp)
    80002122:	7902                	ld	s2,32(sp)
    80002124:	69e2                	ld	s3,24(sp)
    80002126:	6a42                	ld	s4,16(sp)
    80002128:	6aa2                	ld	s5,8(sp)
    8000212a:	6121                	addi	sp,sp,64
    8000212c:	8082                	ret

000000008000212e <reparent>:
{
    8000212e:	7179                	addi	sp,sp,-48
    80002130:	f406                	sd	ra,40(sp)
    80002132:	f022                	sd	s0,32(sp)
    80002134:	ec26                	sd	s1,24(sp)
    80002136:	e84a                	sd	s2,16(sp)
    80002138:	e44e                	sd	s3,8(sp)
    8000213a:	e052                	sd	s4,0(sp)
    8000213c:	1800                	addi	s0,sp,48
    8000213e:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002140:	0000f497          	auipc	s1,0xf
    80002144:	ec048493          	addi	s1,s1,-320 # 80011000 <proc>
      pp->parent = initproc;
    80002148:	00007a17          	auipc	s4,0x7
    8000214c:	810a0a13          	addi	s4,s4,-2032 # 80008958 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002150:	00015997          	auipc	s3,0x15
    80002154:	8b098993          	addi	s3,s3,-1872 # 80016a00 <tickslock>
    80002158:	a029                	j	80002162 <reparent+0x34>
    8000215a:	16848493          	addi	s1,s1,360
    8000215e:	01348d63          	beq	s1,s3,80002178 <reparent+0x4a>
    if(pp->parent == p){
    80002162:	7c9c                	ld	a5,56(s1)
    80002164:	ff279be3          	bne	a5,s2,8000215a <reparent+0x2c>
      pp->parent = initproc;
    80002168:	000a3503          	ld	a0,0(s4)
    8000216c:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000216e:	00000097          	auipc	ra,0x0
    80002172:	f4a080e7          	jalr	-182(ra) # 800020b8 <wakeup>
    80002176:	b7d5                	j	8000215a <reparent+0x2c>
}
    80002178:	70a2                	ld	ra,40(sp)
    8000217a:	7402                	ld	s0,32(sp)
    8000217c:	64e2                	ld	s1,24(sp)
    8000217e:	6942                	ld	s2,16(sp)
    80002180:	69a2                	ld	s3,8(sp)
    80002182:	6a02                	ld	s4,0(sp)
    80002184:	6145                	addi	sp,sp,48
    80002186:	8082                	ret

0000000080002188 <exit>:
{
    80002188:	7179                	addi	sp,sp,-48
    8000218a:	f406                	sd	ra,40(sp)
    8000218c:	f022                	sd	s0,32(sp)
    8000218e:	ec26                	sd	s1,24(sp)
    80002190:	e84a                	sd	s2,16(sp)
    80002192:	e44e                	sd	s3,8(sp)
    80002194:	e052                	sd	s4,0(sp)
    80002196:	1800                	addi	s0,sp,48
    80002198:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000219a:	00000097          	auipc	ra,0x0
    8000219e:	812080e7          	jalr	-2030(ra) # 800019ac <myproc>
    800021a2:	89aa                	mv	s3,a0
  if(p == initproc)
    800021a4:	00006797          	auipc	a5,0x6
    800021a8:	7b47b783          	ld	a5,1972(a5) # 80008958 <initproc>
    800021ac:	0d050493          	addi	s1,a0,208
    800021b0:	15050913          	addi	s2,a0,336
    800021b4:	02a79363          	bne	a5,a0,800021da <exit+0x52>
    panic("init exiting");
    800021b8:	00006517          	auipc	a0,0x6
    800021bc:	0a850513          	addi	a0,a0,168 # 80008260 <digits+0x220>
    800021c0:	ffffe097          	auipc	ra,0xffffe
    800021c4:	380080e7          	jalr	896(ra) # 80000540 <panic>
      fileclose(f);
    800021c8:	00002097          	auipc	ra,0x2
    800021cc:	3b2080e7          	jalr	946(ra) # 8000457a <fileclose>
      p->ofile[fd] = 0;
    800021d0:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800021d4:	04a1                	addi	s1,s1,8
    800021d6:	01248563          	beq	s1,s2,800021e0 <exit+0x58>
    if(p->ofile[fd]){
    800021da:	6088                	ld	a0,0(s1)
    800021dc:	f575                	bnez	a0,800021c8 <exit+0x40>
    800021de:	bfdd                	j	800021d4 <exit+0x4c>
  begin_op();
    800021e0:	00002097          	auipc	ra,0x2
    800021e4:	ed2080e7          	jalr	-302(ra) # 800040b2 <begin_op>
  iput(p->cwd);
    800021e8:	1509b503          	ld	a0,336(s3)
    800021ec:	00001097          	auipc	ra,0x1
    800021f0:	6b4080e7          	jalr	1716(ra) # 800038a0 <iput>
  end_op();
    800021f4:	00002097          	auipc	ra,0x2
    800021f8:	f3c080e7          	jalr	-196(ra) # 80004130 <end_op>
  p->cwd = 0;
    800021fc:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002200:	0000f497          	auipc	s1,0xf
    80002204:	9e848493          	addi	s1,s1,-1560 # 80010be8 <wait_lock>
    80002208:	8526                	mv	a0,s1
    8000220a:	fffff097          	auipc	ra,0xfffff
    8000220e:	9cc080e7          	jalr	-1588(ra) # 80000bd6 <acquire>
  reparent(p);
    80002212:	854e                	mv	a0,s3
    80002214:	00000097          	auipc	ra,0x0
    80002218:	f1a080e7          	jalr	-230(ra) # 8000212e <reparent>
  wakeup(p->parent);
    8000221c:	0389b503          	ld	a0,56(s3)
    80002220:	00000097          	auipc	ra,0x0
    80002224:	e98080e7          	jalr	-360(ra) # 800020b8 <wakeup>
  acquire(&p->lock);
    80002228:	854e                	mv	a0,s3
    8000222a:	fffff097          	auipc	ra,0xfffff
    8000222e:	9ac080e7          	jalr	-1620(ra) # 80000bd6 <acquire>
  p->xstate = status;
    80002232:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002236:	4795                	li	a5,5
    80002238:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    8000223c:	8526                	mv	a0,s1
    8000223e:	fffff097          	auipc	ra,0xfffff
    80002242:	a4c080e7          	jalr	-1460(ra) # 80000c8a <release>
  sched();
    80002246:	00000097          	auipc	ra,0x0
    8000224a:	cfc080e7          	jalr	-772(ra) # 80001f42 <sched>
  panic("zombie exit");
    8000224e:	00006517          	auipc	a0,0x6
    80002252:	02250513          	addi	a0,a0,34 # 80008270 <digits+0x230>
    80002256:	ffffe097          	auipc	ra,0xffffe
    8000225a:	2ea080e7          	jalr	746(ra) # 80000540 <panic>

000000008000225e <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000225e:	7179                	addi	sp,sp,-48
    80002260:	f406                	sd	ra,40(sp)
    80002262:	f022                	sd	s0,32(sp)
    80002264:	ec26                	sd	s1,24(sp)
    80002266:	e84a                	sd	s2,16(sp)
    80002268:	e44e                	sd	s3,8(sp)
    8000226a:	1800                	addi	s0,sp,48
    8000226c:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000226e:	0000f497          	auipc	s1,0xf
    80002272:	d9248493          	addi	s1,s1,-622 # 80011000 <proc>
    80002276:	00014997          	auipc	s3,0x14
    8000227a:	78a98993          	addi	s3,s3,1930 # 80016a00 <tickslock>
    acquire(&p->lock);
    8000227e:	8526                	mv	a0,s1
    80002280:	fffff097          	auipc	ra,0xfffff
    80002284:	956080e7          	jalr	-1706(ra) # 80000bd6 <acquire>
    if(p->pid == pid){
    80002288:	589c                	lw	a5,48(s1)
    8000228a:	01278d63          	beq	a5,s2,800022a4 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000228e:	8526                	mv	a0,s1
    80002290:	fffff097          	auipc	ra,0xfffff
    80002294:	9fa080e7          	jalr	-1542(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002298:	16848493          	addi	s1,s1,360
    8000229c:	ff3491e3          	bne	s1,s3,8000227e <kill+0x20>
  }
  return -1;
    800022a0:	557d                	li	a0,-1
    800022a2:	a829                	j	800022bc <kill+0x5e>
      p->killed = 1;
    800022a4:	4785                	li	a5,1
    800022a6:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800022a8:	4c98                	lw	a4,24(s1)
    800022aa:	4789                	li	a5,2
    800022ac:	00f70f63          	beq	a4,a5,800022ca <kill+0x6c>
      release(&p->lock);
    800022b0:	8526                	mv	a0,s1
    800022b2:	fffff097          	auipc	ra,0xfffff
    800022b6:	9d8080e7          	jalr	-1576(ra) # 80000c8a <release>
      return 0;
    800022ba:	4501                	li	a0,0
}
    800022bc:	70a2                	ld	ra,40(sp)
    800022be:	7402                	ld	s0,32(sp)
    800022c0:	64e2                	ld	s1,24(sp)
    800022c2:	6942                	ld	s2,16(sp)
    800022c4:	69a2                	ld	s3,8(sp)
    800022c6:	6145                	addi	sp,sp,48
    800022c8:	8082                	ret
        p->state = RUNNABLE;
    800022ca:	478d                	li	a5,3
    800022cc:	cc9c                	sw	a5,24(s1)
    800022ce:	b7cd                	j	800022b0 <kill+0x52>

00000000800022d0 <setkilled>:

void
setkilled(struct proc *p)
{
    800022d0:	1101                	addi	sp,sp,-32
    800022d2:	ec06                	sd	ra,24(sp)
    800022d4:	e822                	sd	s0,16(sp)
    800022d6:	e426                	sd	s1,8(sp)
    800022d8:	1000                	addi	s0,sp,32
    800022da:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800022dc:	fffff097          	auipc	ra,0xfffff
    800022e0:	8fa080e7          	jalr	-1798(ra) # 80000bd6 <acquire>
  p->killed = 1;
    800022e4:	4785                	li	a5,1
    800022e6:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    800022e8:	8526                	mv	a0,s1
    800022ea:	fffff097          	auipc	ra,0xfffff
    800022ee:	9a0080e7          	jalr	-1632(ra) # 80000c8a <release>
}
    800022f2:	60e2                	ld	ra,24(sp)
    800022f4:	6442                	ld	s0,16(sp)
    800022f6:	64a2                	ld	s1,8(sp)
    800022f8:	6105                	addi	sp,sp,32
    800022fa:	8082                	ret

00000000800022fc <killed>:

int
killed(struct proc *p)
{
    800022fc:	1101                	addi	sp,sp,-32
    800022fe:	ec06                	sd	ra,24(sp)
    80002300:	e822                	sd	s0,16(sp)
    80002302:	e426                	sd	s1,8(sp)
    80002304:	e04a                	sd	s2,0(sp)
    80002306:	1000                	addi	s0,sp,32
    80002308:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    8000230a:	fffff097          	auipc	ra,0xfffff
    8000230e:	8cc080e7          	jalr	-1844(ra) # 80000bd6 <acquire>
  k = p->killed;
    80002312:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002316:	8526                	mv	a0,s1
    80002318:	fffff097          	auipc	ra,0xfffff
    8000231c:	972080e7          	jalr	-1678(ra) # 80000c8a <release>
  return k;
}
    80002320:	854a                	mv	a0,s2
    80002322:	60e2                	ld	ra,24(sp)
    80002324:	6442                	ld	s0,16(sp)
    80002326:	64a2                	ld	s1,8(sp)
    80002328:	6902                	ld	s2,0(sp)
    8000232a:	6105                	addi	sp,sp,32
    8000232c:	8082                	ret

000000008000232e <wait>:
{
    8000232e:	715d                	addi	sp,sp,-80
    80002330:	e486                	sd	ra,72(sp)
    80002332:	e0a2                	sd	s0,64(sp)
    80002334:	fc26                	sd	s1,56(sp)
    80002336:	f84a                	sd	s2,48(sp)
    80002338:	f44e                	sd	s3,40(sp)
    8000233a:	f052                	sd	s4,32(sp)
    8000233c:	ec56                	sd	s5,24(sp)
    8000233e:	e85a                	sd	s6,16(sp)
    80002340:	e45e                	sd	s7,8(sp)
    80002342:	e062                	sd	s8,0(sp)
    80002344:	0880                	addi	s0,sp,80
    80002346:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002348:	fffff097          	auipc	ra,0xfffff
    8000234c:	664080e7          	jalr	1636(ra) # 800019ac <myproc>
    80002350:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002352:	0000f517          	auipc	a0,0xf
    80002356:	89650513          	addi	a0,a0,-1898 # 80010be8 <wait_lock>
    8000235a:	fffff097          	auipc	ra,0xfffff
    8000235e:	87c080e7          	jalr	-1924(ra) # 80000bd6 <acquire>
    havekids = 0;
    80002362:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    80002364:	4a15                	li	s4,5
        havekids = 1;
    80002366:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002368:	00014997          	auipc	s3,0x14
    8000236c:	69898993          	addi	s3,s3,1688 # 80016a00 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002370:	0000fc17          	auipc	s8,0xf
    80002374:	878c0c13          	addi	s8,s8,-1928 # 80010be8 <wait_lock>
    havekids = 0;
    80002378:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000237a:	0000f497          	auipc	s1,0xf
    8000237e:	c8648493          	addi	s1,s1,-890 # 80011000 <proc>
    80002382:	a0bd                	j	800023f0 <wait+0xc2>
          pid = pp->pid;
    80002384:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002388:	000b0e63          	beqz	s6,800023a4 <wait+0x76>
    8000238c:	4691                	li	a3,4
    8000238e:	02c48613          	addi	a2,s1,44
    80002392:	85da                	mv	a1,s6
    80002394:	05093503          	ld	a0,80(s2)
    80002398:	fffff097          	auipc	ra,0xfffff
    8000239c:	2d4080e7          	jalr	724(ra) # 8000166c <copyout>
    800023a0:	02054563          	bltz	a0,800023ca <wait+0x9c>
          freeproc(pp);
    800023a4:	8526                	mv	a0,s1
    800023a6:	fffff097          	auipc	ra,0xfffff
    800023aa:	7b8080e7          	jalr	1976(ra) # 80001b5e <freeproc>
          release(&pp->lock);
    800023ae:	8526                	mv	a0,s1
    800023b0:	fffff097          	auipc	ra,0xfffff
    800023b4:	8da080e7          	jalr	-1830(ra) # 80000c8a <release>
          release(&wait_lock);
    800023b8:	0000f517          	auipc	a0,0xf
    800023bc:	83050513          	addi	a0,a0,-2000 # 80010be8 <wait_lock>
    800023c0:	fffff097          	auipc	ra,0xfffff
    800023c4:	8ca080e7          	jalr	-1846(ra) # 80000c8a <release>
          return pid;
    800023c8:	a0b5                	j	80002434 <wait+0x106>
            release(&pp->lock);
    800023ca:	8526                	mv	a0,s1
    800023cc:	fffff097          	auipc	ra,0xfffff
    800023d0:	8be080e7          	jalr	-1858(ra) # 80000c8a <release>
            release(&wait_lock);
    800023d4:	0000f517          	auipc	a0,0xf
    800023d8:	81450513          	addi	a0,a0,-2028 # 80010be8 <wait_lock>
    800023dc:	fffff097          	auipc	ra,0xfffff
    800023e0:	8ae080e7          	jalr	-1874(ra) # 80000c8a <release>
            return -1;
    800023e4:	59fd                	li	s3,-1
    800023e6:	a0b9                	j	80002434 <wait+0x106>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800023e8:	16848493          	addi	s1,s1,360
    800023ec:	03348463          	beq	s1,s3,80002414 <wait+0xe6>
      if(pp->parent == p){
    800023f0:	7c9c                	ld	a5,56(s1)
    800023f2:	ff279be3          	bne	a5,s2,800023e8 <wait+0xba>
        acquire(&pp->lock);
    800023f6:	8526                	mv	a0,s1
    800023f8:	ffffe097          	auipc	ra,0xffffe
    800023fc:	7de080e7          	jalr	2014(ra) # 80000bd6 <acquire>
        if(pp->state == ZOMBIE){
    80002400:	4c9c                	lw	a5,24(s1)
    80002402:	f94781e3          	beq	a5,s4,80002384 <wait+0x56>
        release(&pp->lock);
    80002406:	8526                	mv	a0,s1
    80002408:	fffff097          	auipc	ra,0xfffff
    8000240c:	882080e7          	jalr	-1918(ra) # 80000c8a <release>
        havekids = 1;
    80002410:	8756                	mv	a4,s5
    80002412:	bfd9                	j	800023e8 <wait+0xba>
    if(!havekids || killed(p)){
    80002414:	c719                	beqz	a4,80002422 <wait+0xf4>
    80002416:	854a                	mv	a0,s2
    80002418:	00000097          	auipc	ra,0x0
    8000241c:	ee4080e7          	jalr	-284(ra) # 800022fc <killed>
    80002420:	c51d                	beqz	a0,8000244e <wait+0x120>
      release(&wait_lock);
    80002422:	0000e517          	auipc	a0,0xe
    80002426:	7c650513          	addi	a0,a0,1990 # 80010be8 <wait_lock>
    8000242a:	fffff097          	auipc	ra,0xfffff
    8000242e:	860080e7          	jalr	-1952(ra) # 80000c8a <release>
      return -1;
    80002432:	59fd                	li	s3,-1
}
    80002434:	854e                	mv	a0,s3
    80002436:	60a6                	ld	ra,72(sp)
    80002438:	6406                	ld	s0,64(sp)
    8000243a:	74e2                	ld	s1,56(sp)
    8000243c:	7942                	ld	s2,48(sp)
    8000243e:	79a2                	ld	s3,40(sp)
    80002440:	7a02                	ld	s4,32(sp)
    80002442:	6ae2                	ld	s5,24(sp)
    80002444:	6b42                	ld	s6,16(sp)
    80002446:	6ba2                	ld	s7,8(sp)
    80002448:	6c02                	ld	s8,0(sp)
    8000244a:	6161                	addi	sp,sp,80
    8000244c:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000244e:	85e2                	mv	a1,s8
    80002450:	854a                	mv	a0,s2
    80002452:	00000097          	auipc	ra,0x0
    80002456:	c02080e7          	jalr	-1022(ra) # 80002054 <sleep>
    havekids = 0;
    8000245a:	bf39                	j	80002378 <wait+0x4a>

000000008000245c <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000245c:	7179                	addi	sp,sp,-48
    8000245e:	f406                	sd	ra,40(sp)
    80002460:	f022                	sd	s0,32(sp)
    80002462:	ec26                	sd	s1,24(sp)
    80002464:	e84a                	sd	s2,16(sp)
    80002466:	e44e                	sd	s3,8(sp)
    80002468:	e052                	sd	s4,0(sp)
    8000246a:	1800                	addi	s0,sp,48
    8000246c:	84aa                	mv	s1,a0
    8000246e:	892e                	mv	s2,a1
    80002470:	89b2                	mv	s3,a2
    80002472:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002474:	fffff097          	auipc	ra,0xfffff
    80002478:	538080e7          	jalr	1336(ra) # 800019ac <myproc>
  if(user_dst){
    8000247c:	c08d                	beqz	s1,8000249e <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000247e:	86d2                	mv	a3,s4
    80002480:	864e                	mv	a2,s3
    80002482:	85ca                	mv	a1,s2
    80002484:	6928                	ld	a0,80(a0)
    80002486:	fffff097          	auipc	ra,0xfffff
    8000248a:	1e6080e7          	jalr	486(ra) # 8000166c <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000248e:	70a2                	ld	ra,40(sp)
    80002490:	7402                	ld	s0,32(sp)
    80002492:	64e2                	ld	s1,24(sp)
    80002494:	6942                	ld	s2,16(sp)
    80002496:	69a2                	ld	s3,8(sp)
    80002498:	6a02                	ld	s4,0(sp)
    8000249a:	6145                	addi	sp,sp,48
    8000249c:	8082                	ret
    memmove((char *)dst, src, len);
    8000249e:	000a061b          	sext.w	a2,s4
    800024a2:	85ce                	mv	a1,s3
    800024a4:	854a                	mv	a0,s2
    800024a6:	fffff097          	auipc	ra,0xfffff
    800024aa:	888080e7          	jalr	-1912(ra) # 80000d2e <memmove>
    return 0;
    800024ae:	8526                	mv	a0,s1
    800024b0:	bff9                	j	8000248e <either_copyout+0x32>

00000000800024b2 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024b2:	7179                	addi	sp,sp,-48
    800024b4:	f406                	sd	ra,40(sp)
    800024b6:	f022                	sd	s0,32(sp)
    800024b8:	ec26                	sd	s1,24(sp)
    800024ba:	e84a                	sd	s2,16(sp)
    800024bc:	e44e                	sd	s3,8(sp)
    800024be:	e052                	sd	s4,0(sp)
    800024c0:	1800                	addi	s0,sp,48
    800024c2:	892a                	mv	s2,a0
    800024c4:	84ae                	mv	s1,a1
    800024c6:	89b2                	mv	s3,a2
    800024c8:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024ca:	fffff097          	auipc	ra,0xfffff
    800024ce:	4e2080e7          	jalr	1250(ra) # 800019ac <myproc>
  if(user_src){
    800024d2:	c08d                	beqz	s1,800024f4 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800024d4:	86d2                	mv	a3,s4
    800024d6:	864e                	mv	a2,s3
    800024d8:	85ca                	mv	a1,s2
    800024da:	6928                	ld	a0,80(a0)
    800024dc:	fffff097          	auipc	ra,0xfffff
    800024e0:	21c080e7          	jalr	540(ra) # 800016f8 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800024e4:	70a2                	ld	ra,40(sp)
    800024e6:	7402                	ld	s0,32(sp)
    800024e8:	64e2                	ld	s1,24(sp)
    800024ea:	6942                	ld	s2,16(sp)
    800024ec:	69a2                	ld	s3,8(sp)
    800024ee:	6a02                	ld	s4,0(sp)
    800024f0:	6145                	addi	sp,sp,48
    800024f2:	8082                	ret
    memmove(dst, (char*)src, len);
    800024f4:	000a061b          	sext.w	a2,s4
    800024f8:	85ce                	mv	a1,s3
    800024fa:	854a                	mv	a0,s2
    800024fc:	fffff097          	auipc	ra,0xfffff
    80002500:	832080e7          	jalr	-1998(ra) # 80000d2e <memmove>
    return 0;
    80002504:	8526                	mv	a0,s1
    80002506:	bff9                	j	800024e4 <either_copyin+0x32>

0000000080002508 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002508:	715d                	addi	sp,sp,-80
    8000250a:	e486                	sd	ra,72(sp)
    8000250c:	e0a2                	sd	s0,64(sp)
    8000250e:	fc26                	sd	s1,56(sp)
    80002510:	f84a                	sd	s2,48(sp)
    80002512:	f44e                	sd	s3,40(sp)
    80002514:	f052                	sd	s4,32(sp)
    80002516:	ec56                	sd	s5,24(sp)
    80002518:	e85a                	sd	s6,16(sp)
    8000251a:	e45e                	sd	s7,8(sp)
    8000251c:	0880                	addi	s0,sp,80
  [ZOMBIE]    "ZOOMBIE"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000251e:	00006517          	auipc	a0,0x6
    80002522:	baa50513          	addi	a0,a0,-1110 # 800080c8 <digits+0x88>
    80002526:	ffffe097          	auipc	ra,0xffffe
    8000252a:	064080e7          	jalr	100(ra) # 8000058a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000252e:	0000f497          	auipc	s1,0xf
    80002532:	c2a48493          	addi	s1,s1,-982 # 80011158 <proc+0x158>
    80002536:	00014917          	auipc	s2,0x14
    8000253a:	62290913          	addi	s2,s2,1570 # 80016b58 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000253e:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002540:	00006997          	auipc	s3,0x6
    80002544:	d4098993          	addi	s3,s3,-704 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    80002548:	00006a97          	auipc	s5,0x6
    8000254c:	d40a8a93          	addi	s5,s5,-704 # 80008288 <digits+0x248>
    printf("\n");
    80002550:	00006a17          	auipc	s4,0x6
    80002554:	b78a0a13          	addi	s4,s4,-1160 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002558:	00006b97          	auipc	s7,0x6
    8000255c:	db8b8b93          	addi	s7,s7,-584 # 80008310 <states.1>
    80002560:	a00d                	j	80002582 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002562:	ed86a583          	lw	a1,-296(a3)
    80002566:	8556                	mv	a0,s5
    80002568:	ffffe097          	auipc	ra,0xffffe
    8000256c:	022080e7          	jalr	34(ra) # 8000058a <printf>
    printf("\n");
    80002570:	8552                	mv	a0,s4
    80002572:	ffffe097          	auipc	ra,0xffffe
    80002576:	018080e7          	jalr	24(ra) # 8000058a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000257a:	16848493          	addi	s1,s1,360
    8000257e:	03248263          	beq	s1,s2,800025a2 <procdump+0x9a>
    if(p->state == UNUSED)
    80002582:	86a6                	mv	a3,s1
    80002584:	ec04a783          	lw	a5,-320(s1)
    80002588:	dbed                	beqz	a5,8000257a <procdump+0x72>
      state = "???";
    8000258a:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000258c:	fcfb6be3          	bltu	s6,a5,80002562 <procdump+0x5a>
    80002590:	02079713          	slli	a4,a5,0x20
    80002594:	01d75793          	srli	a5,a4,0x1d
    80002598:	97de                	add	a5,a5,s7
    8000259a:	6390                	ld	a2,0(a5)
    8000259c:	f279                	bnez	a2,80002562 <procdump+0x5a>
      state = "???";
    8000259e:	864e                	mv	a2,s3
    800025a0:	b7c9                	j	80002562 <procdump+0x5a>
  }
}
    800025a2:	60a6                	ld	ra,72(sp)
    800025a4:	6406                	ld	s0,64(sp)
    800025a6:	74e2                	ld	s1,56(sp)
    800025a8:	7942                	ld	s2,48(sp)
    800025aa:	79a2                	ld	s3,40(sp)
    800025ac:	7a02                	ld	s4,32(sp)
    800025ae:	6ae2                	ld	s5,24(sp)
    800025b0:	6b42                	ld	s6,16(sp)
    800025b2:	6ba2                	ld	s7,8(sp)
    800025b4:	6161                	addi	sp,sp,80
    800025b6:	8082                	ret

00000000800025b8 <psProcDump>:

void
psProcDump(void)
{
    800025b8:	715d                	addi	sp,sp,-80
    800025ba:	e486                	sd	ra,72(sp)
    800025bc:	e0a2                	sd	s0,64(sp)
    800025be:	fc26                	sd	s1,56(sp)
    800025c0:	f84a                	sd	s2,48(sp)
    800025c2:	f44e                	sd	s3,40(sp)
    800025c4:	f052                	sd	s4,32(sp)
    800025c6:	ec56                	sd	s5,24(sp)
    800025c8:	e85a                	sd	s6,16(sp)
    800025ca:	e45e                	sd	s7,8(sp)
    800025cc:	0880                	addi	s0,sp,80
  };
  struct proc *p;
  char *state;

  //printf("\n");
  for(p = proc; p < &proc[NPROC]; p++){
    800025ce:	0000f497          	auipc	s1,0xf
    800025d2:	b8a48493          	addi	s1,s1,-1142 # 80011158 <proc+0x158>
    800025d6:	00014917          	auipc	s2,0x14
    800025da:	58290913          	addi	s2,s2,1410 # 80016b58 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025de:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800025e0:	00006997          	auipc	s3,0x6
    800025e4:	ca098993          	addi	s3,s3,-864 # 80008280 <digits+0x240>
    //printf("%d %s %s", p->pid, state, p->name);
    printf("%s (%d): %s", p->name, p->pid, state);
    800025e8:	00006a97          	auipc	s5,0x6
    800025ec:	cb0a8a93          	addi	s5,s5,-848 # 80008298 <digits+0x258>
    printf("\n");
    800025f0:	00006a17          	auipc	s4,0x6
    800025f4:	ad8a0a13          	addi	s4,s4,-1320 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025f8:	00006b97          	auipc	s7,0x6
    800025fc:	d18b8b93          	addi	s7,s7,-744 # 80008310 <states.1>
    80002600:	a00d                	j	80002622 <psProcDump+0x6a>
    printf("%s (%d): %s", p->name, p->pid, state);
    80002602:	ed85a603          	lw	a2,-296(a1)
    80002606:	8556                	mv	a0,s5
    80002608:	ffffe097          	auipc	ra,0xffffe
    8000260c:	f82080e7          	jalr	-126(ra) # 8000058a <printf>
    printf("\n");
    80002610:	8552                	mv	a0,s4
    80002612:	ffffe097          	auipc	ra,0xffffe
    80002616:	f78080e7          	jalr	-136(ra) # 8000058a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000261a:	16848493          	addi	s1,s1,360
    8000261e:	03248263          	beq	s1,s2,80002642 <psProcDump+0x8a>
    if(p->state == UNUSED)
    80002622:	85a6                	mv	a1,s1
    80002624:	ec04a783          	lw	a5,-320(s1)
    80002628:	dbed                	beqz	a5,8000261a <psProcDump+0x62>
      state = "???";
    8000262a:	86ce                	mv	a3,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000262c:	fcfb6be3          	bltu	s6,a5,80002602 <psProcDump+0x4a>
    80002630:	02079713          	slli	a4,a5,0x20
    80002634:	01d75793          	srli	a5,a4,0x1d
    80002638:	97de                	add	a5,a5,s7
    8000263a:	7b94                	ld	a3,48(a5)
    8000263c:	f2f9                	bnez	a3,80002602 <psProcDump+0x4a>
      state = "???";
    8000263e:	86ce                	mv	a3,s3
    80002640:	b7c9                	j	80002602 <psProcDump+0x4a>
  }
    80002642:	60a6                	ld	ra,72(sp)
    80002644:	6406                	ld	s0,64(sp)
    80002646:	74e2                	ld	s1,56(sp)
    80002648:	7942                	ld	s2,48(sp)
    8000264a:	79a2                	ld	s3,40(sp)
    8000264c:	7a02                	ld	s4,32(sp)
    8000264e:	6ae2                	ld	s5,24(sp)
    80002650:	6b42                	ld	s6,16(sp)
    80002652:	6ba2                	ld	s7,8(sp)
    80002654:	6161                	addi	sp,sp,80
    80002656:	8082                	ret

0000000080002658 <swtch>:
    80002658:	00153023          	sd	ra,0(a0)
    8000265c:	00253423          	sd	sp,8(a0)
    80002660:	e900                	sd	s0,16(a0)
    80002662:	ed04                	sd	s1,24(a0)
    80002664:	03253023          	sd	s2,32(a0)
    80002668:	03353423          	sd	s3,40(a0)
    8000266c:	03453823          	sd	s4,48(a0)
    80002670:	03553c23          	sd	s5,56(a0)
    80002674:	05653023          	sd	s6,64(a0)
    80002678:	05753423          	sd	s7,72(a0)
    8000267c:	05853823          	sd	s8,80(a0)
    80002680:	05953c23          	sd	s9,88(a0)
    80002684:	07a53023          	sd	s10,96(a0)
    80002688:	07b53423          	sd	s11,104(a0)
    8000268c:	0005b083          	ld	ra,0(a1)
    80002690:	0085b103          	ld	sp,8(a1)
    80002694:	6980                	ld	s0,16(a1)
    80002696:	6d84                	ld	s1,24(a1)
    80002698:	0205b903          	ld	s2,32(a1)
    8000269c:	0285b983          	ld	s3,40(a1)
    800026a0:	0305ba03          	ld	s4,48(a1)
    800026a4:	0385ba83          	ld	s5,56(a1)
    800026a8:	0405bb03          	ld	s6,64(a1)
    800026ac:	0485bb83          	ld	s7,72(a1)
    800026b0:	0505bc03          	ld	s8,80(a1)
    800026b4:	0585bc83          	ld	s9,88(a1)
    800026b8:	0605bd03          	ld	s10,96(a1)
    800026bc:	0685bd83          	ld	s11,104(a1)
    800026c0:	8082                	ret

00000000800026c2 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800026c2:	1141                	addi	sp,sp,-16
    800026c4:	e406                	sd	ra,8(sp)
    800026c6:	e022                	sd	s0,0(sp)
    800026c8:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800026ca:	00006597          	auipc	a1,0x6
    800026ce:	ca658593          	addi	a1,a1,-858 # 80008370 <states.0+0x30>
    800026d2:	00014517          	auipc	a0,0x14
    800026d6:	32e50513          	addi	a0,a0,814 # 80016a00 <tickslock>
    800026da:	ffffe097          	auipc	ra,0xffffe
    800026de:	46c080e7          	jalr	1132(ra) # 80000b46 <initlock>
}
    800026e2:	60a2                	ld	ra,8(sp)
    800026e4:	6402                	ld	s0,0(sp)
    800026e6:	0141                	addi	sp,sp,16
    800026e8:	8082                	ret

00000000800026ea <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800026ea:	1141                	addi	sp,sp,-16
    800026ec:	e422                	sd	s0,8(sp)
    800026ee:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026f0:	00003797          	auipc	a5,0x3
    800026f4:	4e078793          	addi	a5,a5,1248 # 80005bd0 <kernelvec>
    800026f8:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800026fc:	6422                	ld	s0,8(sp)
    800026fe:	0141                	addi	sp,sp,16
    80002700:	8082                	ret

0000000080002702 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002702:	1141                	addi	sp,sp,-16
    80002704:	e406                	sd	ra,8(sp)
    80002706:	e022                	sd	s0,0(sp)
    80002708:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000270a:	fffff097          	auipc	ra,0xfffff
    8000270e:	2a2080e7          	jalr	674(ra) # 800019ac <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002712:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002716:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002718:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    8000271c:	00005697          	auipc	a3,0x5
    80002720:	8e468693          	addi	a3,a3,-1820 # 80007000 <_trampoline>
    80002724:	00005717          	auipc	a4,0x5
    80002728:	8dc70713          	addi	a4,a4,-1828 # 80007000 <_trampoline>
    8000272c:	8f15                	sub	a4,a4,a3
    8000272e:	040007b7          	lui	a5,0x4000
    80002732:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002734:	07b2                	slli	a5,a5,0xc
    80002736:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002738:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000273c:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000273e:	18002673          	csrr	a2,satp
    80002742:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002744:	6d30                	ld	a2,88(a0)
    80002746:	6138                	ld	a4,64(a0)
    80002748:	6585                	lui	a1,0x1
    8000274a:	972e                	add	a4,a4,a1
    8000274c:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000274e:	6d38                	ld	a4,88(a0)
    80002750:	00000617          	auipc	a2,0x0
    80002754:	13060613          	addi	a2,a2,304 # 80002880 <usertrap>
    80002758:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000275a:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000275c:	8612                	mv	a2,tp
    8000275e:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002760:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002764:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002768:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000276c:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002770:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002772:	6f18                	ld	a4,24(a4)
    80002774:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002778:	6928                	ld	a0,80(a0)
    8000277a:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    8000277c:	00005717          	auipc	a4,0x5
    80002780:	92070713          	addi	a4,a4,-1760 # 8000709c <userret>
    80002784:	8f15                	sub	a4,a4,a3
    80002786:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002788:	577d                	li	a4,-1
    8000278a:	177e                	slli	a4,a4,0x3f
    8000278c:	8d59                	or	a0,a0,a4
    8000278e:	9782                	jalr	a5
}
    80002790:	60a2                	ld	ra,8(sp)
    80002792:	6402                	ld	s0,0(sp)
    80002794:	0141                	addi	sp,sp,16
    80002796:	8082                	ret

0000000080002798 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002798:	1101                	addi	sp,sp,-32
    8000279a:	ec06                	sd	ra,24(sp)
    8000279c:	e822                	sd	s0,16(sp)
    8000279e:	e426                	sd	s1,8(sp)
    800027a0:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800027a2:	00014497          	auipc	s1,0x14
    800027a6:	25e48493          	addi	s1,s1,606 # 80016a00 <tickslock>
    800027aa:	8526                	mv	a0,s1
    800027ac:	ffffe097          	auipc	ra,0xffffe
    800027b0:	42a080e7          	jalr	1066(ra) # 80000bd6 <acquire>
  ticks++;
    800027b4:	00006517          	auipc	a0,0x6
    800027b8:	1ac50513          	addi	a0,a0,428 # 80008960 <ticks>
    800027bc:	411c                	lw	a5,0(a0)
    800027be:	2785                	addiw	a5,a5,1
    800027c0:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800027c2:	00000097          	auipc	ra,0x0
    800027c6:	8f6080e7          	jalr	-1802(ra) # 800020b8 <wakeup>
  release(&tickslock);
    800027ca:	8526                	mv	a0,s1
    800027cc:	ffffe097          	auipc	ra,0xffffe
    800027d0:	4be080e7          	jalr	1214(ra) # 80000c8a <release>
}
    800027d4:	60e2                	ld	ra,24(sp)
    800027d6:	6442                	ld	s0,16(sp)
    800027d8:	64a2                	ld	s1,8(sp)
    800027da:	6105                	addi	sp,sp,32
    800027dc:	8082                	ret

00000000800027de <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800027de:	1101                	addi	sp,sp,-32
    800027e0:	ec06                	sd	ra,24(sp)
    800027e2:	e822                	sd	s0,16(sp)
    800027e4:	e426                	sd	s1,8(sp)
    800027e6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800027e8:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800027ec:	00074d63          	bltz	a4,80002806 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800027f0:	57fd                	li	a5,-1
    800027f2:	17fe                	slli	a5,a5,0x3f
    800027f4:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800027f6:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800027f8:	06f70363          	beq	a4,a5,8000285e <devintr+0x80>
  }
}
    800027fc:	60e2                	ld	ra,24(sp)
    800027fe:	6442                	ld	s0,16(sp)
    80002800:	64a2                	ld	s1,8(sp)
    80002802:	6105                	addi	sp,sp,32
    80002804:	8082                	ret
     (scause & 0xff) == 9){
    80002806:	0ff77793          	zext.b	a5,a4
  if((scause & 0x8000000000000000L) &&
    8000280a:	46a5                	li	a3,9
    8000280c:	fed792e3          	bne	a5,a3,800027f0 <devintr+0x12>
    int irq = plic_claim();
    80002810:	00003097          	auipc	ra,0x3
    80002814:	4c8080e7          	jalr	1224(ra) # 80005cd8 <plic_claim>
    80002818:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    8000281a:	47a9                	li	a5,10
    8000281c:	02f50763          	beq	a0,a5,8000284a <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002820:	4785                	li	a5,1
    80002822:	02f50963          	beq	a0,a5,80002854 <devintr+0x76>
    return 1;
    80002826:	4505                	li	a0,1
    } else if(irq){
    80002828:	d8f1                	beqz	s1,800027fc <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    8000282a:	85a6                	mv	a1,s1
    8000282c:	00006517          	auipc	a0,0x6
    80002830:	b4c50513          	addi	a0,a0,-1204 # 80008378 <states.0+0x38>
    80002834:	ffffe097          	auipc	ra,0xffffe
    80002838:	d56080e7          	jalr	-682(ra) # 8000058a <printf>
      plic_complete(irq);
    8000283c:	8526                	mv	a0,s1
    8000283e:	00003097          	auipc	ra,0x3
    80002842:	4be080e7          	jalr	1214(ra) # 80005cfc <plic_complete>
    return 1;
    80002846:	4505                	li	a0,1
    80002848:	bf55                	j	800027fc <devintr+0x1e>
      uartintr();
    8000284a:	ffffe097          	auipc	ra,0xffffe
    8000284e:	14e080e7          	jalr	334(ra) # 80000998 <uartintr>
    80002852:	b7ed                	j	8000283c <devintr+0x5e>
      virtio_disk_intr();
    80002854:	00004097          	auipc	ra,0x4
    80002858:	970080e7          	jalr	-1680(ra) # 800061c4 <virtio_disk_intr>
    8000285c:	b7c5                	j	8000283c <devintr+0x5e>
    if(cpuid() == 0){
    8000285e:	fffff097          	auipc	ra,0xfffff
    80002862:	122080e7          	jalr	290(ra) # 80001980 <cpuid>
    80002866:	c901                	beqz	a0,80002876 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002868:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    8000286c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    8000286e:	14479073          	csrw	sip,a5
    return 2;
    80002872:	4509                	li	a0,2
    80002874:	b761                	j	800027fc <devintr+0x1e>
      clockintr();
    80002876:	00000097          	auipc	ra,0x0
    8000287a:	f22080e7          	jalr	-222(ra) # 80002798 <clockintr>
    8000287e:	b7ed                	j	80002868 <devintr+0x8a>

0000000080002880 <usertrap>:
{
    80002880:	1101                	addi	sp,sp,-32
    80002882:	ec06                	sd	ra,24(sp)
    80002884:	e822                	sd	s0,16(sp)
    80002886:	e426                	sd	s1,8(sp)
    80002888:	e04a                	sd	s2,0(sp)
    8000288a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000288c:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002890:	1007f793          	andi	a5,a5,256
    80002894:	e3b1                	bnez	a5,800028d8 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002896:	00003797          	auipc	a5,0x3
    8000289a:	33a78793          	addi	a5,a5,826 # 80005bd0 <kernelvec>
    8000289e:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800028a2:	fffff097          	auipc	ra,0xfffff
    800028a6:	10a080e7          	jalr	266(ra) # 800019ac <myproc>
    800028aa:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800028ac:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028ae:	14102773          	csrr	a4,sepc
    800028b2:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028b4:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800028b8:	47a1                	li	a5,8
    800028ba:	02f70763          	beq	a4,a5,800028e8 <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    800028be:	00000097          	auipc	ra,0x0
    800028c2:	f20080e7          	jalr	-224(ra) # 800027de <devintr>
    800028c6:	892a                	mv	s2,a0
    800028c8:	c151                	beqz	a0,8000294c <usertrap+0xcc>
  if(killed(p))
    800028ca:	8526                	mv	a0,s1
    800028cc:	00000097          	auipc	ra,0x0
    800028d0:	a30080e7          	jalr	-1488(ra) # 800022fc <killed>
    800028d4:	c929                	beqz	a0,80002926 <usertrap+0xa6>
    800028d6:	a099                	j	8000291c <usertrap+0x9c>
    panic("usertrap: not from user mode");
    800028d8:	00006517          	auipc	a0,0x6
    800028dc:	ac050513          	addi	a0,a0,-1344 # 80008398 <states.0+0x58>
    800028e0:	ffffe097          	auipc	ra,0xffffe
    800028e4:	c60080e7          	jalr	-928(ra) # 80000540 <panic>
    if(killed(p))
    800028e8:	00000097          	auipc	ra,0x0
    800028ec:	a14080e7          	jalr	-1516(ra) # 800022fc <killed>
    800028f0:	e921                	bnez	a0,80002940 <usertrap+0xc0>
    p->trapframe->epc += 4;
    800028f2:	6cb8                	ld	a4,88(s1)
    800028f4:	6f1c                	ld	a5,24(a4)
    800028f6:	0791                	addi	a5,a5,4
    800028f8:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028fa:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800028fe:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002902:	10079073          	csrw	sstatus,a5
    syscall();
    80002906:	00000097          	auipc	ra,0x0
    8000290a:	2d4080e7          	jalr	724(ra) # 80002bda <syscall>
  if(killed(p))
    8000290e:	8526                	mv	a0,s1
    80002910:	00000097          	auipc	ra,0x0
    80002914:	9ec080e7          	jalr	-1556(ra) # 800022fc <killed>
    80002918:	c911                	beqz	a0,8000292c <usertrap+0xac>
    8000291a:	4901                	li	s2,0
    exit(-1);
    8000291c:	557d                	li	a0,-1
    8000291e:	00000097          	auipc	ra,0x0
    80002922:	86a080e7          	jalr	-1942(ra) # 80002188 <exit>
  if(which_dev == 2)
    80002926:	4789                	li	a5,2
    80002928:	04f90f63          	beq	s2,a5,80002986 <usertrap+0x106>
  usertrapret();
    8000292c:	00000097          	auipc	ra,0x0
    80002930:	dd6080e7          	jalr	-554(ra) # 80002702 <usertrapret>
}
    80002934:	60e2                	ld	ra,24(sp)
    80002936:	6442                	ld	s0,16(sp)
    80002938:	64a2                	ld	s1,8(sp)
    8000293a:	6902                	ld	s2,0(sp)
    8000293c:	6105                	addi	sp,sp,32
    8000293e:	8082                	ret
      exit(-1);
    80002940:	557d                	li	a0,-1
    80002942:	00000097          	auipc	ra,0x0
    80002946:	846080e7          	jalr	-1978(ra) # 80002188 <exit>
    8000294a:	b765                	j	800028f2 <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000294c:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002950:	5890                	lw	a2,48(s1)
    80002952:	00006517          	auipc	a0,0x6
    80002956:	a6650513          	addi	a0,a0,-1434 # 800083b8 <states.0+0x78>
    8000295a:	ffffe097          	auipc	ra,0xffffe
    8000295e:	c30080e7          	jalr	-976(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002962:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002966:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000296a:	00006517          	auipc	a0,0x6
    8000296e:	a7e50513          	addi	a0,a0,-1410 # 800083e8 <states.0+0xa8>
    80002972:	ffffe097          	auipc	ra,0xffffe
    80002976:	c18080e7          	jalr	-1000(ra) # 8000058a <printf>
    setkilled(p);
    8000297a:	8526                	mv	a0,s1
    8000297c:	00000097          	auipc	ra,0x0
    80002980:	954080e7          	jalr	-1708(ra) # 800022d0 <setkilled>
    80002984:	b769                	j	8000290e <usertrap+0x8e>
    yield();
    80002986:	fffff097          	auipc	ra,0xfffff
    8000298a:	692080e7          	jalr	1682(ra) # 80002018 <yield>
    8000298e:	bf79                	j	8000292c <usertrap+0xac>

0000000080002990 <kerneltrap>:
{
    80002990:	7179                	addi	sp,sp,-48
    80002992:	f406                	sd	ra,40(sp)
    80002994:	f022                	sd	s0,32(sp)
    80002996:	ec26                	sd	s1,24(sp)
    80002998:	e84a                	sd	s2,16(sp)
    8000299a:	e44e                	sd	s3,8(sp)
    8000299c:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000299e:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029a2:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029a6:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800029aa:	1004f793          	andi	a5,s1,256
    800029ae:	cb85                	beqz	a5,800029de <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029b0:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800029b4:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800029b6:	ef85                	bnez	a5,800029ee <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800029b8:	00000097          	auipc	ra,0x0
    800029bc:	e26080e7          	jalr	-474(ra) # 800027de <devintr>
    800029c0:	cd1d                	beqz	a0,800029fe <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029c2:	4789                	li	a5,2
    800029c4:	06f50a63          	beq	a0,a5,80002a38 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029c8:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029cc:	10049073          	csrw	sstatus,s1
}
    800029d0:	70a2                	ld	ra,40(sp)
    800029d2:	7402                	ld	s0,32(sp)
    800029d4:	64e2                	ld	s1,24(sp)
    800029d6:	6942                	ld	s2,16(sp)
    800029d8:	69a2                	ld	s3,8(sp)
    800029da:	6145                	addi	sp,sp,48
    800029dc:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800029de:	00006517          	auipc	a0,0x6
    800029e2:	a2a50513          	addi	a0,a0,-1494 # 80008408 <states.0+0xc8>
    800029e6:	ffffe097          	auipc	ra,0xffffe
    800029ea:	b5a080e7          	jalr	-1190(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    800029ee:	00006517          	auipc	a0,0x6
    800029f2:	a4250513          	addi	a0,a0,-1470 # 80008430 <states.0+0xf0>
    800029f6:	ffffe097          	auipc	ra,0xffffe
    800029fa:	b4a080e7          	jalr	-1206(ra) # 80000540 <panic>
    printf("scause %p\n", scause);
    800029fe:	85ce                	mv	a1,s3
    80002a00:	00006517          	auipc	a0,0x6
    80002a04:	a5050513          	addi	a0,a0,-1456 # 80008450 <states.0+0x110>
    80002a08:	ffffe097          	auipc	ra,0xffffe
    80002a0c:	b82080e7          	jalr	-1150(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a10:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a14:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a18:	00006517          	auipc	a0,0x6
    80002a1c:	a4850513          	addi	a0,a0,-1464 # 80008460 <states.0+0x120>
    80002a20:	ffffe097          	auipc	ra,0xffffe
    80002a24:	b6a080e7          	jalr	-1174(ra) # 8000058a <printf>
    panic("kerneltrap");
    80002a28:	00006517          	auipc	a0,0x6
    80002a2c:	a5050513          	addi	a0,a0,-1456 # 80008478 <states.0+0x138>
    80002a30:	ffffe097          	auipc	ra,0xffffe
    80002a34:	b10080e7          	jalr	-1264(ra) # 80000540 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a38:	fffff097          	auipc	ra,0xfffff
    80002a3c:	f74080e7          	jalr	-140(ra) # 800019ac <myproc>
    80002a40:	d541                	beqz	a0,800029c8 <kerneltrap+0x38>
    80002a42:	fffff097          	auipc	ra,0xfffff
    80002a46:	f6a080e7          	jalr	-150(ra) # 800019ac <myproc>
    80002a4a:	4d18                	lw	a4,24(a0)
    80002a4c:	4791                	li	a5,4
    80002a4e:	f6f71de3          	bne	a4,a5,800029c8 <kerneltrap+0x38>
    yield();
    80002a52:	fffff097          	auipc	ra,0xfffff
    80002a56:	5c6080e7          	jalr	1478(ra) # 80002018 <yield>
    80002a5a:	b7bd                	j	800029c8 <kerneltrap+0x38>

0000000080002a5c <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002a5c:	1101                	addi	sp,sp,-32
    80002a5e:	ec06                	sd	ra,24(sp)
    80002a60:	e822                	sd	s0,16(sp)
    80002a62:	e426                	sd	s1,8(sp)
    80002a64:	1000                	addi	s0,sp,32
    80002a66:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002a68:	fffff097          	auipc	ra,0xfffff
    80002a6c:	f44080e7          	jalr	-188(ra) # 800019ac <myproc>
  switch (n) {
    80002a70:	4795                	li	a5,5
    80002a72:	0497e163          	bltu	a5,s1,80002ab4 <argraw+0x58>
    80002a76:	048a                	slli	s1,s1,0x2
    80002a78:	00006717          	auipc	a4,0x6
    80002a7c:	a3870713          	addi	a4,a4,-1480 # 800084b0 <states.0+0x170>
    80002a80:	94ba                	add	s1,s1,a4
    80002a82:	409c                	lw	a5,0(s1)
    80002a84:	97ba                	add	a5,a5,a4
    80002a86:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002a88:	6d3c                	ld	a5,88(a0)
    80002a8a:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002a8c:	60e2                	ld	ra,24(sp)
    80002a8e:	6442                	ld	s0,16(sp)
    80002a90:	64a2                	ld	s1,8(sp)
    80002a92:	6105                	addi	sp,sp,32
    80002a94:	8082                	ret
    return p->trapframe->a1;
    80002a96:	6d3c                	ld	a5,88(a0)
    80002a98:	7fa8                	ld	a0,120(a5)
    80002a9a:	bfcd                	j	80002a8c <argraw+0x30>
    return p->trapframe->a2;
    80002a9c:	6d3c                	ld	a5,88(a0)
    80002a9e:	63c8                	ld	a0,128(a5)
    80002aa0:	b7f5                	j	80002a8c <argraw+0x30>
    return p->trapframe->a3;
    80002aa2:	6d3c                	ld	a5,88(a0)
    80002aa4:	67c8                	ld	a0,136(a5)
    80002aa6:	b7dd                	j	80002a8c <argraw+0x30>
    return p->trapframe->a4;
    80002aa8:	6d3c                	ld	a5,88(a0)
    80002aaa:	6bc8                	ld	a0,144(a5)
    80002aac:	b7c5                	j	80002a8c <argraw+0x30>
    return p->trapframe->a5;
    80002aae:	6d3c                	ld	a5,88(a0)
    80002ab0:	6fc8                	ld	a0,152(a5)
    80002ab2:	bfe9                	j	80002a8c <argraw+0x30>
  panic("argraw");
    80002ab4:	00006517          	auipc	a0,0x6
    80002ab8:	9d450513          	addi	a0,a0,-1580 # 80008488 <states.0+0x148>
    80002abc:	ffffe097          	auipc	ra,0xffffe
    80002ac0:	a84080e7          	jalr	-1404(ra) # 80000540 <panic>

0000000080002ac4 <fetchaddr>:
{
    80002ac4:	1101                	addi	sp,sp,-32
    80002ac6:	ec06                	sd	ra,24(sp)
    80002ac8:	e822                	sd	s0,16(sp)
    80002aca:	e426                	sd	s1,8(sp)
    80002acc:	e04a                	sd	s2,0(sp)
    80002ace:	1000                	addi	s0,sp,32
    80002ad0:	84aa                	mv	s1,a0
    80002ad2:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002ad4:	fffff097          	auipc	ra,0xfffff
    80002ad8:	ed8080e7          	jalr	-296(ra) # 800019ac <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002adc:	653c                	ld	a5,72(a0)
    80002ade:	02f4f863          	bgeu	s1,a5,80002b0e <fetchaddr+0x4a>
    80002ae2:	00848713          	addi	a4,s1,8
    80002ae6:	02e7e663          	bltu	a5,a4,80002b12 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002aea:	46a1                	li	a3,8
    80002aec:	8626                	mv	a2,s1
    80002aee:	85ca                	mv	a1,s2
    80002af0:	6928                	ld	a0,80(a0)
    80002af2:	fffff097          	auipc	ra,0xfffff
    80002af6:	c06080e7          	jalr	-1018(ra) # 800016f8 <copyin>
    80002afa:	00a03533          	snez	a0,a0
    80002afe:	40a00533          	neg	a0,a0
}
    80002b02:	60e2                	ld	ra,24(sp)
    80002b04:	6442                	ld	s0,16(sp)
    80002b06:	64a2                	ld	s1,8(sp)
    80002b08:	6902                	ld	s2,0(sp)
    80002b0a:	6105                	addi	sp,sp,32
    80002b0c:	8082                	ret
    return -1;
    80002b0e:	557d                	li	a0,-1
    80002b10:	bfcd                	j	80002b02 <fetchaddr+0x3e>
    80002b12:	557d                	li	a0,-1
    80002b14:	b7fd                	j	80002b02 <fetchaddr+0x3e>

0000000080002b16 <fetchstr>:
{
    80002b16:	7179                	addi	sp,sp,-48
    80002b18:	f406                	sd	ra,40(sp)
    80002b1a:	f022                	sd	s0,32(sp)
    80002b1c:	ec26                	sd	s1,24(sp)
    80002b1e:	e84a                	sd	s2,16(sp)
    80002b20:	e44e                	sd	s3,8(sp)
    80002b22:	1800                	addi	s0,sp,48
    80002b24:	892a                	mv	s2,a0
    80002b26:	84ae                	mv	s1,a1
    80002b28:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b2a:	fffff097          	auipc	ra,0xfffff
    80002b2e:	e82080e7          	jalr	-382(ra) # 800019ac <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002b32:	86ce                	mv	a3,s3
    80002b34:	864a                	mv	a2,s2
    80002b36:	85a6                	mv	a1,s1
    80002b38:	6928                	ld	a0,80(a0)
    80002b3a:	fffff097          	auipc	ra,0xfffff
    80002b3e:	c4c080e7          	jalr	-948(ra) # 80001786 <copyinstr>
    80002b42:	00054e63          	bltz	a0,80002b5e <fetchstr+0x48>
  return strlen(buf);
    80002b46:	8526                	mv	a0,s1
    80002b48:	ffffe097          	auipc	ra,0xffffe
    80002b4c:	306080e7          	jalr	774(ra) # 80000e4e <strlen>
}
    80002b50:	70a2                	ld	ra,40(sp)
    80002b52:	7402                	ld	s0,32(sp)
    80002b54:	64e2                	ld	s1,24(sp)
    80002b56:	6942                	ld	s2,16(sp)
    80002b58:	69a2                	ld	s3,8(sp)
    80002b5a:	6145                	addi	sp,sp,48
    80002b5c:	8082                	ret
    return -1;
    80002b5e:	557d                	li	a0,-1
    80002b60:	bfc5                	j	80002b50 <fetchstr+0x3a>

0000000080002b62 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002b62:	1101                	addi	sp,sp,-32
    80002b64:	ec06                	sd	ra,24(sp)
    80002b66:	e822                	sd	s0,16(sp)
    80002b68:	e426                	sd	s1,8(sp)
    80002b6a:	1000                	addi	s0,sp,32
    80002b6c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b6e:	00000097          	auipc	ra,0x0
    80002b72:	eee080e7          	jalr	-274(ra) # 80002a5c <argraw>
    80002b76:	c088                	sw	a0,0(s1)
}
    80002b78:	60e2                	ld	ra,24(sp)
    80002b7a:	6442                	ld	s0,16(sp)
    80002b7c:	64a2                	ld	s1,8(sp)
    80002b7e:	6105                	addi	sp,sp,32
    80002b80:	8082                	ret

0000000080002b82 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002b82:	1101                	addi	sp,sp,-32
    80002b84:	ec06                	sd	ra,24(sp)
    80002b86:	e822                	sd	s0,16(sp)
    80002b88:	e426                	sd	s1,8(sp)
    80002b8a:	1000                	addi	s0,sp,32
    80002b8c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b8e:	00000097          	auipc	ra,0x0
    80002b92:	ece080e7          	jalr	-306(ra) # 80002a5c <argraw>
    80002b96:	e088                	sd	a0,0(s1)
}
    80002b98:	60e2                	ld	ra,24(sp)
    80002b9a:	6442                	ld	s0,16(sp)
    80002b9c:	64a2                	ld	s1,8(sp)
    80002b9e:	6105                	addi	sp,sp,32
    80002ba0:	8082                	ret

0000000080002ba2 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002ba2:	7179                	addi	sp,sp,-48
    80002ba4:	f406                	sd	ra,40(sp)
    80002ba6:	f022                	sd	s0,32(sp)
    80002ba8:	ec26                	sd	s1,24(sp)
    80002baa:	e84a                	sd	s2,16(sp)
    80002bac:	1800                	addi	s0,sp,48
    80002bae:	84ae                	mv	s1,a1
    80002bb0:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002bb2:	fd840593          	addi	a1,s0,-40
    80002bb6:	00000097          	auipc	ra,0x0
    80002bba:	fcc080e7          	jalr	-52(ra) # 80002b82 <argaddr>
  return fetchstr(addr, buf, max);
    80002bbe:	864a                	mv	a2,s2
    80002bc0:	85a6                	mv	a1,s1
    80002bc2:	fd843503          	ld	a0,-40(s0)
    80002bc6:	00000097          	auipc	ra,0x0
    80002bca:	f50080e7          	jalr	-176(ra) # 80002b16 <fetchstr>
}
    80002bce:	70a2                	ld	ra,40(sp)
    80002bd0:	7402                	ld	s0,32(sp)
    80002bd2:	64e2                	ld	s1,24(sp)
    80002bd4:	6942                	ld	s2,16(sp)
    80002bd6:	6145                	addi	sp,sp,48
    80002bd8:	8082                	ret

0000000080002bda <syscall>:
[SYS_ps]   sys_ps,
};

void
syscall(void)
{
    80002bda:	1101                	addi	sp,sp,-32
    80002bdc:	ec06                	sd	ra,24(sp)
    80002bde:	e822                	sd	s0,16(sp)
    80002be0:	e426                	sd	s1,8(sp)
    80002be2:	e04a                	sd	s2,0(sp)
    80002be4:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002be6:	fffff097          	auipc	ra,0xfffff
    80002bea:	dc6080e7          	jalr	-570(ra) # 800019ac <myproc>
    80002bee:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002bf0:	05853903          	ld	s2,88(a0)
    80002bf4:	0a893783          	ld	a5,168(s2)
    80002bf8:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002bfc:	37fd                	addiw	a5,a5,-1
    80002bfe:	4755                	li	a4,21
    80002c00:	00f76f63          	bltu	a4,a5,80002c1e <syscall+0x44>
    80002c04:	00369713          	slli	a4,a3,0x3
    80002c08:	00006797          	auipc	a5,0x6
    80002c0c:	8c078793          	addi	a5,a5,-1856 # 800084c8 <syscalls>
    80002c10:	97ba                	add	a5,a5,a4
    80002c12:	639c                	ld	a5,0(a5)
    80002c14:	c789                	beqz	a5,80002c1e <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002c16:	9782                	jalr	a5
    80002c18:	06a93823          	sd	a0,112(s2)
    80002c1c:	a839                	j	80002c3a <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002c1e:	15848613          	addi	a2,s1,344
    80002c22:	588c                	lw	a1,48(s1)
    80002c24:	00006517          	auipc	a0,0x6
    80002c28:	86c50513          	addi	a0,a0,-1940 # 80008490 <states.0+0x150>
    80002c2c:	ffffe097          	auipc	ra,0xffffe
    80002c30:	95e080e7          	jalr	-1698(ra) # 8000058a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002c34:	6cbc                	ld	a5,88(s1)
    80002c36:	577d                	li	a4,-1
    80002c38:	fbb8                	sd	a4,112(a5)
  }
}
    80002c3a:	60e2                	ld	ra,24(sp)
    80002c3c:	6442                	ld	s0,16(sp)
    80002c3e:	64a2                	ld	s1,8(sp)
    80002c40:	6902                	ld	s2,0(sp)
    80002c42:	6105                	addi	sp,sp,32
    80002c44:	8082                	ret

0000000080002c46 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002c46:	1101                	addi	sp,sp,-32
    80002c48:	ec06                	sd	ra,24(sp)
    80002c4a:	e822                	sd	s0,16(sp)
    80002c4c:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002c4e:	fec40593          	addi	a1,s0,-20
    80002c52:	4501                	li	a0,0
    80002c54:	00000097          	auipc	ra,0x0
    80002c58:	f0e080e7          	jalr	-242(ra) # 80002b62 <argint>
  exit(n);
    80002c5c:	fec42503          	lw	a0,-20(s0)
    80002c60:	fffff097          	auipc	ra,0xfffff
    80002c64:	528080e7          	jalr	1320(ra) # 80002188 <exit>
  return 0;  // not reached
}
    80002c68:	4501                	li	a0,0
    80002c6a:	60e2                	ld	ra,24(sp)
    80002c6c:	6442                	ld	s0,16(sp)
    80002c6e:	6105                	addi	sp,sp,32
    80002c70:	8082                	ret

0000000080002c72 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002c72:	1141                	addi	sp,sp,-16
    80002c74:	e406                	sd	ra,8(sp)
    80002c76:	e022                	sd	s0,0(sp)
    80002c78:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002c7a:	fffff097          	auipc	ra,0xfffff
    80002c7e:	d32080e7          	jalr	-718(ra) # 800019ac <myproc>
}
    80002c82:	5908                	lw	a0,48(a0)
    80002c84:	60a2                	ld	ra,8(sp)
    80002c86:	6402                	ld	s0,0(sp)
    80002c88:	0141                	addi	sp,sp,16
    80002c8a:	8082                	ret

0000000080002c8c <sys_fork>:

uint64
sys_fork(void)
{
    80002c8c:	1141                	addi	sp,sp,-16
    80002c8e:	e406                	sd	ra,8(sp)
    80002c90:	e022                	sd	s0,0(sp)
    80002c92:	0800                	addi	s0,sp,16
  return fork();
    80002c94:	fffff097          	auipc	ra,0xfffff
    80002c98:	0ce080e7          	jalr	206(ra) # 80001d62 <fork>
}
    80002c9c:	60a2                	ld	ra,8(sp)
    80002c9e:	6402                	ld	s0,0(sp)
    80002ca0:	0141                	addi	sp,sp,16
    80002ca2:	8082                	ret

0000000080002ca4 <sys_wait>:

uint64
sys_wait(void)
{
    80002ca4:	1101                	addi	sp,sp,-32
    80002ca6:	ec06                	sd	ra,24(sp)
    80002ca8:	e822                	sd	s0,16(sp)
    80002caa:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002cac:	fe840593          	addi	a1,s0,-24
    80002cb0:	4501                	li	a0,0
    80002cb2:	00000097          	auipc	ra,0x0
    80002cb6:	ed0080e7          	jalr	-304(ra) # 80002b82 <argaddr>
  return wait(p);
    80002cba:	fe843503          	ld	a0,-24(s0)
    80002cbe:	fffff097          	auipc	ra,0xfffff
    80002cc2:	670080e7          	jalr	1648(ra) # 8000232e <wait>
}
    80002cc6:	60e2                	ld	ra,24(sp)
    80002cc8:	6442                	ld	s0,16(sp)
    80002cca:	6105                	addi	sp,sp,32
    80002ccc:	8082                	ret

0000000080002cce <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002cce:	7179                	addi	sp,sp,-48
    80002cd0:	f406                	sd	ra,40(sp)
    80002cd2:	f022                	sd	s0,32(sp)
    80002cd4:	ec26                	sd	s1,24(sp)
    80002cd6:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002cd8:	fdc40593          	addi	a1,s0,-36
    80002cdc:	4501                	li	a0,0
    80002cde:	00000097          	auipc	ra,0x0
    80002ce2:	e84080e7          	jalr	-380(ra) # 80002b62 <argint>
  addr = myproc()->sz;
    80002ce6:	fffff097          	auipc	ra,0xfffff
    80002cea:	cc6080e7          	jalr	-826(ra) # 800019ac <myproc>
    80002cee:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002cf0:	fdc42503          	lw	a0,-36(s0)
    80002cf4:	fffff097          	auipc	ra,0xfffff
    80002cf8:	012080e7          	jalr	18(ra) # 80001d06 <growproc>
    80002cfc:	00054863          	bltz	a0,80002d0c <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002d00:	8526                	mv	a0,s1
    80002d02:	70a2                	ld	ra,40(sp)
    80002d04:	7402                	ld	s0,32(sp)
    80002d06:	64e2                	ld	s1,24(sp)
    80002d08:	6145                	addi	sp,sp,48
    80002d0a:	8082                	ret
    return -1;
    80002d0c:	54fd                	li	s1,-1
    80002d0e:	bfcd                	j	80002d00 <sys_sbrk+0x32>

0000000080002d10 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002d10:	7139                	addi	sp,sp,-64
    80002d12:	fc06                	sd	ra,56(sp)
    80002d14:	f822                	sd	s0,48(sp)
    80002d16:	f426                	sd	s1,40(sp)
    80002d18:	f04a                	sd	s2,32(sp)
    80002d1a:	ec4e                	sd	s3,24(sp)
    80002d1c:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002d1e:	fcc40593          	addi	a1,s0,-52
    80002d22:	4501                	li	a0,0
    80002d24:	00000097          	auipc	ra,0x0
    80002d28:	e3e080e7          	jalr	-450(ra) # 80002b62 <argint>
  acquire(&tickslock);
    80002d2c:	00014517          	auipc	a0,0x14
    80002d30:	cd450513          	addi	a0,a0,-812 # 80016a00 <tickslock>
    80002d34:	ffffe097          	auipc	ra,0xffffe
    80002d38:	ea2080e7          	jalr	-350(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    80002d3c:	00006917          	auipc	s2,0x6
    80002d40:	c2492903          	lw	s2,-988(s2) # 80008960 <ticks>
  while(ticks - ticks0 < n){
    80002d44:	fcc42783          	lw	a5,-52(s0)
    80002d48:	cf9d                	beqz	a5,80002d86 <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002d4a:	00014997          	auipc	s3,0x14
    80002d4e:	cb698993          	addi	s3,s3,-842 # 80016a00 <tickslock>
    80002d52:	00006497          	auipc	s1,0x6
    80002d56:	c0e48493          	addi	s1,s1,-1010 # 80008960 <ticks>
    if(killed(myproc())){
    80002d5a:	fffff097          	auipc	ra,0xfffff
    80002d5e:	c52080e7          	jalr	-942(ra) # 800019ac <myproc>
    80002d62:	fffff097          	auipc	ra,0xfffff
    80002d66:	59a080e7          	jalr	1434(ra) # 800022fc <killed>
    80002d6a:	ed15                	bnez	a0,80002da6 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002d6c:	85ce                	mv	a1,s3
    80002d6e:	8526                	mv	a0,s1
    80002d70:	fffff097          	auipc	ra,0xfffff
    80002d74:	2e4080e7          	jalr	740(ra) # 80002054 <sleep>
  while(ticks - ticks0 < n){
    80002d78:	409c                	lw	a5,0(s1)
    80002d7a:	412787bb          	subw	a5,a5,s2
    80002d7e:	fcc42703          	lw	a4,-52(s0)
    80002d82:	fce7ece3          	bltu	a5,a4,80002d5a <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002d86:	00014517          	auipc	a0,0x14
    80002d8a:	c7a50513          	addi	a0,a0,-902 # 80016a00 <tickslock>
    80002d8e:	ffffe097          	auipc	ra,0xffffe
    80002d92:	efc080e7          	jalr	-260(ra) # 80000c8a <release>
  return 0;
    80002d96:	4501                	li	a0,0
}
    80002d98:	70e2                	ld	ra,56(sp)
    80002d9a:	7442                	ld	s0,48(sp)
    80002d9c:	74a2                	ld	s1,40(sp)
    80002d9e:	7902                	ld	s2,32(sp)
    80002da0:	69e2                	ld	s3,24(sp)
    80002da2:	6121                	addi	sp,sp,64
    80002da4:	8082                	ret
      release(&tickslock);
    80002da6:	00014517          	auipc	a0,0x14
    80002daa:	c5a50513          	addi	a0,a0,-934 # 80016a00 <tickslock>
    80002dae:	ffffe097          	auipc	ra,0xffffe
    80002db2:	edc080e7          	jalr	-292(ra) # 80000c8a <release>
      return -1;
    80002db6:	557d                	li	a0,-1
    80002db8:	b7c5                	j	80002d98 <sys_sleep+0x88>

0000000080002dba <sys_kill>:

uint64
sys_kill(void)
{
    80002dba:	1101                	addi	sp,sp,-32
    80002dbc:	ec06                	sd	ra,24(sp)
    80002dbe:	e822                	sd	s0,16(sp)
    80002dc0:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002dc2:	fec40593          	addi	a1,s0,-20
    80002dc6:	4501                	li	a0,0
    80002dc8:	00000097          	auipc	ra,0x0
    80002dcc:	d9a080e7          	jalr	-614(ra) # 80002b62 <argint>
  return kill(pid);
    80002dd0:	fec42503          	lw	a0,-20(s0)
    80002dd4:	fffff097          	auipc	ra,0xfffff
    80002dd8:	48a080e7          	jalr	1162(ra) # 8000225e <kill>
}
    80002ddc:	60e2                	ld	ra,24(sp)
    80002dde:	6442                	ld	s0,16(sp)
    80002de0:	6105                	addi	sp,sp,32
    80002de2:	8082                	ret

0000000080002de4 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002de4:	1101                	addi	sp,sp,-32
    80002de6:	ec06                	sd	ra,24(sp)
    80002de8:	e822                	sd	s0,16(sp)
    80002dea:	e426                	sd	s1,8(sp)
    80002dec:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002dee:	00014517          	auipc	a0,0x14
    80002df2:	c1250513          	addi	a0,a0,-1006 # 80016a00 <tickslock>
    80002df6:	ffffe097          	auipc	ra,0xffffe
    80002dfa:	de0080e7          	jalr	-544(ra) # 80000bd6 <acquire>
  xticks = ticks;
    80002dfe:	00006497          	auipc	s1,0x6
    80002e02:	b624a483          	lw	s1,-1182(s1) # 80008960 <ticks>
  release(&tickslock);
    80002e06:	00014517          	auipc	a0,0x14
    80002e0a:	bfa50513          	addi	a0,a0,-1030 # 80016a00 <tickslock>
    80002e0e:	ffffe097          	auipc	ra,0xffffe
    80002e12:	e7c080e7          	jalr	-388(ra) # 80000c8a <release>
  return xticks;
}
    80002e16:	02049513          	slli	a0,s1,0x20
    80002e1a:	9101                	srli	a0,a0,0x20
    80002e1c:	60e2                	ld	ra,24(sp)
    80002e1e:	6442                	ld	s0,16(sp)
    80002e20:	64a2                	ld	s1,8(sp)
    80002e22:	6105                	addi	sp,sp,32
    80002e24:	8082                	ret

0000000080002e26 <sys_ps>:

uint64
sys_ps(void)
{
    80002e26:	1141                	addi	sp,sp,-16
    80002e28:	e406                	sd	ra,8(sp)
    80002e2a:	e022                	sd	s0,0(sp)
    80002e2c:	0800                	addi	s0,sp,16
  psProcDump();
    80002e2e:	fffff097          	auipc	ra,0xfffff
    80002e32:	78a080e7          	jalr	1930(ra) # 800025b8 <psProcDump>
  //printf("halla");
  return 0;
    80002e36:	4501                	li	a0,0
    80002e38:	60a2                	ld	ra,8(sp)
    80002e3a:	6402                	ld	s0,0(sp)
    80002e3c:	0141                	addi	sp,sp,16
    80002e3e:	8082                	ret

0000000080002e40 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002e40:	7179                	addi	sp,sp,-48
    80002e42:	f406                	sd	ra,40(sp)
    80002e44:	f022                	sd	s0,32(sp)
    80002e46:	ec26                	sd	s1,24(sp)
    80002e48:	e84a                	sd	s2,16(sp)
    80002e4a:	e44e                	sd	s3,8(sp)
    80002e4c:	e052                	sd	s4,0(sp)
    80002e4e:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002e50:	00005597          	auipc	a1,0x5
    80002e54:	73058593          	addi	a1,a1,1840 # 80008580 <syscalls+0xb8>
    80002e58:	00014517          	auipc	a0,0x14
    80002e5c:	bc050513          	addi	a0,a0,-1088 # 80016a18 <bcache>
    80002e60:	ffffe097          	auipc	ra,0xffffe
    80002e64:	ce6080e7          	jalr	-794(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002e68:	0001c797          	auipc	a5,0x1c
    80002e6c:	bb078793          	addi	a5,a5,-1104 # 8001ea18 <bcache+0x8000>
    80002e70:	0001c717          	auipc	a4,0x1c
    80002e74:	e1070713          	addi	a4,a4,-496 # 8001ec80 <bcache+0x8268>
    80002e78:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002e7c:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002e80:	00014497          	auipc	s1,0x14
    80002e84:	bb048493          	addi	s1,s1,-1104 # 80016a30 <bcache+0x18>
    b->next = bcache.head.next;
    80002e88:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002e8a:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002e8c:	00005a17          	auipc	s4,0x5
    80002e90:	6fca0a13          	addi	s4,s4,1788 # 80008588 <syscalls+0xc0>
    b->next = bcache.head.next;
    80002e94:	2b893783          	ld	a5,696(s2)
    80002e98:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002e9a:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002e9e:	85d2                	mv	a1,s4
    80002ea0:	01048513          	addi	a0,s1,16
    80002ea4:	00001097          	auipc	ra,0x1
    80002ea8:	4c8080e7          	jalr	1224(ra) # 8000436c <initsleeplock>
    bcache.head.next->prev = b;
    80002eac:	2b893783          	ld	a5,696(s2)
    80002eb0:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002eb2:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002eb6:	45848493          	addi	s1,s1,1112
    80002eba:	fd349de3          	bne	s1,s3,80002e94 <binit+0x54>
  }
}
    80002ebe:	70a2                	ld	ra,40(sp)
    80002ec0:	7402                	ld	s0,32(sp)
    80002ec2:	64e2                	ld	s1,24(sp)
    80002ec4:	6942                	ld	s2,16(sp)
    80002ec6:	69a2                	ld	s3,8(sp)
    80002ec8:	6a02                	ld	s4,0(sp)
    80002eca:	6145                	addi	sp,sp,48
    80002ecc:	8082                	ret

0000000080002ece <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002ece:	7179                	addi	sp,sp,-48
    80002ed0:	f406                	sd	ra,40(sp)
    80002ed2:	f022                	sd	s0,32(sp)
    80002ed4:	ec26                	sd	s1,24(sp)
    80002ed6:	e84a                	sd	s2,16(sp)
    80002ed8:	e44e                	sd	s3,8(sp)
    80002eda:	1800                	addi	s0,sp,48
    80002edc:	892a                	mv	s2,a0
    80002ede:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002ee0:	00014517          	auipc	a0,0x14
    80002ee4:	b3850513          	addi	a0,a0,-1224 # 80016a18 <bcache>
    80002ee8:	ffffe097          	auipc	ra,0xffffe
    80002eec:	cee080e7          	jalr	-786(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002ef0:	0001c497          	auipc	s1,0x1c
    80002ef4:	de04b483          	ld	s1,-544(s1) # 8001ecd0 <bcache+0x82b8>
    80002ef8:	0001c797          	auipc	a5,0x1c
    80002efc:	d8878793          	addi	a5,a5,-632 # 8001ec80 <bcache+0x8268>
    80002f00:	02f48f63          	beq	s1,a5,80002f3e <bread+0x70>
    80002f04:	873e                	mv	a4,a5
    80002f06:	a021                	j	80002f0e <bread+0x40>
    80002f08:	68a4                	ld	s1,80(s1)
    80002f0a:	02e48a63          	beq	s1,a4,80002f3e <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002f0e:	449c                	lw	a5,8(s1)
    80002f10:	ff279ce3          	bne	a5,s2,80002f08 <bread+0x3a>
    80002f14:	44dc                	lw	a5,12(s1)
    80002f16:	ff3799e3          	bne	a5,s3,80002f08 <bread+0x3a>
      b->refcnt++;
    80002f1a:	40bc                	lw	a5,64(s1)
    80002f1c:	2785                	addiw	a5,a5,1
    80002f1e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f20:	00014517          	auipc	a0,0x14
    80002f24:	af850513          	addi	a0,a0,-1288 # 80016a18 <bcache>
    80002f28:	ffffe097          	auipc	ra,0xffffe
    80002f2c:	d62080e7          	jalr	-670(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80002f30:	01048513          	addi	a0,s1,16
    80002f34:	00001097          	auipc	ra,0x1
    80002f38:	472080e7          	jalr	1138(ra) # 800043a6 <acquiresleep>
      return b;
    80002f3c:	a8b9                	j	80002f9a <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f3e:	0001c497          	auipc	s1,0x1c
    80002f42:	d8a4b483          	ld	s1,-630(s1) # 8001ecc8 <bcache+0x82b0>
    80002f46:	0001c797          	auipc	a5,0x1c
    80002f4a:	d3a78793          	addi	a5,a5,-710 # 8001ec80 <bcache+0x8268>
    80002f4e:	00f48863          	beq	s1,a5,80002f5e <bread+0x90>
    80002f52:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002f54:	40bc                	lw	a5,64(s1)
    80002f56:	cf81                	beqz	a5,80002f6e <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f58:	64a4                	ld	s1,72(s1)
    80002f5a:	fee49de3          	bne	s1,a4,80002f54 <bread+0x86>
  panic("bget: no buffers");
    80002f5e:	00005517          	auipc	a0,0x5
    80002f62:	63250513          	addi	a0,a0,1586 # 80008590 <syscalls+0xc8>
    80002f66:	ffffd097          	auipc	ra,0xffffd
    80002f6a:	5da080e7          	jalr	1498(ra) # 80000540 <panic>
      b->dev = dev;
    80002f6e:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80002f72:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80002f76:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002f7a:	4785                	li	a5,1
    80002f7c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f7e:	00014517          	auipc	a0,0x14
    80002f82:	a9a50513          	addi	a0,a0,-1382 # 80016a18 <bcache>
    80002f86:	ffffe097          	auipc	ra,0xffffe
    80002f8a:	d04080e7          	jalr	-764(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80002f8e:	01048513          	addi	a0,s1,16
    80002f92:	00001097          	auipc	ra,0x1
    80002f96:	414080e7          	jalr	1044(ra) # 800043a6 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002f9a:	409c                	lw	a5,0(s1)
    80002f9c:	cb89                	beqz	a5,80002fae <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002f9e:	8526                	mv	a0,s1
    80002fa0:	70a2                	ld	ra,40(sp)
    80002fa2:	7402                	ld	s0,32(sp)
    80002fa4:	64e2                	ld	s1,24(sp)
    80002fa6:	6942                	ld	s2,16(sp)
    80002fa8:	69a2                	ld	s3,8(sp)
    80002faa:	6145                	addi	sp,sp,48
    80002fac:	8082                	ret
    virtio_disk_rw(b, 0);
    80002fae:	4581                	li	a1,0
    80002fb0:	8526                	mv	a0,s1
    80002fb2:	00003097          	auipc	ra,0x3
    80002fb6:	fe0080e7          	jalr	-32(ra) # 80005f92 <virtio_disk_rw>
    b->valid = 1;
    80002fba:	4785                	li	a5,1
    80002fbc:	c09c                	sw	a5,0(s1)
  return b;
    80002fbe:	b7c5                	j	80002f9e <bread+0xd0>

0000000080002fc0 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002fc0:	1101                	addi	sp,sp,-32
    80002fc2:	ec06                	sd	ra,24(sp)
    80002fc4:	e822                	sd	s0,16(sp)
    80002fc6:	e426                	sd	s1,8(sp)
    80002fc8:	1000                	addi	s0,sp,32
    80002fca:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002fcc:	0541                	addi	a0,a0,16
    80002fce:	00001097          	auipc	ra,0x1
    80002fd2:	472080e7          	jalr	1138(ra) # 80004440 <holdingsleep>
    80002fd6:	cd01                	beqz	a0,80002fee <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80002fd8:	4585                	li	a1,1
    80002fda:	8526                	mv	a0,s1
    80002fdc:	00003097          	auipc	ra,0x3
    80002fe0:	fb6080e7          	jalr	-74(ra) # 80005f92 <virtio_disk_rw>
}
    80002fe4:	60e2                	ld	ra,24(sp)
    80002fe6:	6442                	ld	s0,16(sp)
    80002fe8:	64a2                	ld	s1,8(sp)
    80002fea:	6105                	addi	sp,sp,32
    80002fec:	8082                	ret
    panic("bwrite");
    80002fee:	00005517          	auipc	a0,0x5
    80002ff2:	5ba50513          	addi	a0,a0,1466 # 800085a8 <syscalls+0xe0>
    80002ff6:	ffffd097          	auipc	ra,0xffffd
    80002ffa:	54a080e7          	jalr	1354(ra) # 80000540 <panic>

0000000080002ffe <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80002ffe:	1101                	addi	sp,sp,-32
    80003000:	ec06                	sd	ra,24(sp)
    80003002:	e822                	sd	s0,16(sp)
    80003004:	e426                	sd	s1,8(sp)
    80003006:	e04a                	sd	s2,0(sp)
    80003008:	1000                	addi	s0,sp,32
    8000300a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000300c:	01050913          	addi	s2,a0,16
    80003010:	854a                	mv	a0,s2
    80003012:	00001097          	auipc	ra,0x1
    80003016:	42e080e7          	jalr	1070(ra) # 80004440 <holdingsleep>
    8000301a:	c92d                	beqz	a0,8000308c <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000301c:	854a                	mv	a0,s2
    8000301e:	00001097          	auipc	ra,0x1
    80003022:	3de080e7          	jalr	990(ra) # 800043fc <releasesleep>

  acquire(&bcache.lock);
    80003026:	00014517          	auipc	a0,0x14
    8000302a:	9f250513          	addi	a0,a0,-1550 # 80016a18 <bcache>
    8000302e:	ffffe097          	auipc	ra,0xffffe
    80003032:	ba8080e7          	jalr	-1112(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80003036:	40bc                	lw	a5,64(s1)
    80003038:	37fd                	addiw	a5,a5,-1
    8000303a:	0007871b          	sext.w	a4,a5
    8000303e:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003040:	eb05                	bnez	a4,80003070 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003042:	68bc                	ld	a5,80(s1)
    80003044:	64b8                	ld	a4,72(s1)
    80003046:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003048:	64bc                	ld	a5,72(s1)
    8000304a:	68b8                	ld	a4,80(s1)
    8000304c:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000304e:	0001c797          	auipc	a5,0x1c
    80003052:	9ca78793          	addi	a5,a5,-1590 # 8001ea18 <bcache+0x8000>
    80003056:	2b87b703          	ld	a4,696(a5)
    8000305a:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000305c:	0001c717          	auipc	a4,0x1c
    80003060:	c2470713          	addi	a4,a4,-988 # 8001ec80 <bcache+0x8268>
    80003064:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003066:	2b87b703          	ld	a4,696(a5)
    8000306a:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000306c:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003070:	00014517          	auipc	a0,0x14
    80003074:	9a850513          	addi	a0,a0,-1624 # 80016a18 <bcache>
    80003078:	ffffe097          	auipc	ra,0xffffe
    8000307c:	c12080e7          	jalr	-1006(ra) # 80000c8a <release>
}
    80003080:	60e2                	ld	ra,24(sp)
    80003082:	6442                	ld	s0,16(sp)
    80003084:	64a2                	ld	s1,8(sp)
    80003086:	6902                	ld	s2,0(sp)
    80003088:	6105                	addi	sp,sp,32
    8000308a:	8082                	ret
    panic("brelse");
    8000308c:	00005517          	auipc	a0,0x5
    80003090:	52450513          	addi	a0,a0,1316 # 800085b0 <syscalls+0xe8>
    80003094:	ffffd097          	auipc	ra,0xffffd
    80003098:	4ac080e7          	jalr	1196(ra) # 80000540 <panic>

000000008000309c <bpin>:

void
bpin(struct buf *b) {
    8000309c:	1101                	addi	sp,sp,-32
    8000309e:	ec06                	sd	ra,24(sp)
    800030a0:	e822                	sd	s0,16(sp)
    800030a2:	e426                	sd	s1,8(sp)
    800030a4:	1000                	addi	s0,sp,32
    800030a6:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800030a8:	00014517          	auipc	a0,0x14
    800030ac:	97050513          	addi	a0,a0,-1680 # 80016a18 <bcache>
    800030b0:	ffffe097          	auipc	ra,0xffffe
    800030b4:	b26080e7          	jalr	-1242(ra) # 80000bd6 <acquire>
  b->refcnt++;
    800030b8:	40bc                	lw	a5,64(s1)
    800030ba:	2785                	addiw	a5,a5,1
    800030bc:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800030be:	00014517          	auipc	a0,0x14
    800030c2:	95a50513          	addi	a0,a0,-1702 # 80016a18 <bcache>
    800030c6:	ffffe097          	auipc	ra,0xffffe
    800030ca:	bc4080e7          	jalr	-1084(ra) # 80000c8a <release>
}
    800030ce:	60e2                	ld	ra,24(sp)
    800030d0:	6442                	ld	s0,16(sp)
    800030d2:	64a2                	ld	s1,8(sp)
    800030d4:	6105                	addi	sp,sp,32
    800030d6:	8082                	ret

00000000800030d8 <bunpin>:

void
bunpin(struct buf *b) {
    800030d8:	1101                	addi	sp,sp,-32
    800030da:	ec06                	sd	ra,24(sp)
    800030dc:	e822                	sd	s0,16(sp)
    800030de:	e426                	sd	s1,8(sp)
    800030e0:	1000                	addi	s0,sp,32
    800030e2:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800030e4:	00014517          	auipc	a0,0x14
    800030e8:	93450513          	addi	a0,a0,-1740 # 80016a18 <bcache>
    800030ec:	ffffe097          	auipc	ra,0xffffe
    800030f0:	aea080e7          	jalr	-1302(ra) # 80000bd6 <acquire>
  b->refcnt--;
    800030f4:	40bc                	lw	a5,64(s1)
    800030f6:	37fd                	addiw	a5,a5,-1
    800030f8:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800030fa:	00014517          	auipc	a0,0x14
    800030fe:	91e50513          	addi	a0,a0,-1762 # 80016a18 <bcache>
    80003102:	ffffe097          	auipc	ra,0xffffe
    80003106:	b88080e7          	jalr	-1144(ra) # 80000c8a <release>
}
    8000310a:	60e2                	ld	ra,24(sp)
    8000310c:	6442                	ld	s0,16(sp)
    8000310e:	64a2                	ld	s1,8(sp)
    80003110:	6105                	addi	sp,sp,32
    80003112:	8082                	ret

0000000080003114 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003114:	1101                	addi	sp,sp,-32
    80003116:	ec06                	sd	ra,24(sp)
    80003118:	e822                	sd	s0,16(sp)
    8000311a:	e426                	sd	s1,8(sp)
    8000311c:	e04a                	sd	s2,0(sp)
    8000311e:	1000                	addi	s0,sp,32
    80003120:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003122:	00d5d59b          	srliw	a1,a1,0xd
    80003126:	0001c797          	auipc	a5,0x1c
    8000312a:	fce7a783          	lw	a5,-50(a5) # 8001f0f4 <sb+0x1c>
    8000312e:	9dbd                	addw	a1,a1,a5
    80003130:	00000097          	auipc	ra,0x0
    80003134:	d9e080e7          	jalr	-610(ra) # 80002ece <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003138:	0074f713          	andi	a4,s1,7
    8000313c:	4785                	li	a5,1
    8000313e:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003142:	14ce                	slli	s1,s1,0x33
    80003144:	90d9                	srli	s1,s1,0x36
    80003146:	00950733          	add	a4,a0,s1
    8000314a:	05874703          	lbu	a4,88(a4)
    8000314e:	00e7f6b3          	and	a3,a5,a4
    80003152:	c69d                	beqz	a3,80003180 <bfree+0x6c>
    80003154:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003156:	94aa                	add	s1,s1,a0
    80003158:	fff7c793          	not	a5,a5
    8000315c:	8f7d                	and	a4,a4,a5
    8000315e:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80003162:	00001097          	auipc	ra,0x1
    80003166:	126080e7          	jalr	294(ra) # 80004288 <log_write>
  brelse(bp);
    8000316a:	854a                	mv	a0,s2
    8000316c:	00000097          	auipc	ra,0x0
    80003170:	e92080e7          	jalr	-366(ra) # 80002ffe <brelse>
}
    80003174:	60e2                	ld	ra,24(sp)
    80003176:	6442                	ld	s0,16(sp)
    80003178:	64a2                	ld	s1,8(sp)
    8000317a:	6902                	ld	s2,0(sp)
    8000317c:	6105                	addi	sp,sp,32
    8000317e:	8082                	ret
    panic("freeing free block");
    80003180:	00005517          	auipc	a0,0x5
    80003184:	43850513          	addi	a0,a0,1080 # 800085b8 <syscalls+0xf0>
    80003188:	ffffd097          	auipc	ra,0xffffd
    8000318c:	3b8080e7          	jalr	952(ra) # 80000540 <panic>

0000000080003190 <balloc>:
{
    80003190:	711d                	addi	sp,sp,-96
    80003192:	ec86                	sd	ra,88(sp)
    80003194:	e8a2                	sd	s0,80(sp)
    80003196:	e4a6                	sd	s1,72(sp)
    80003198:	e0ca                	sd	s2,64(sp)
    8000319a:	fc4e                	sd	s3,56(sp)
    8000319c:	f852                	sd	s4,48(sp)
    8000319e:	f456                	sd	s5,40(sp)
    800031a0:	f05a                	sd	s6,32(sp)
    800031a2:	ec5e                	sd	s7,24(sp)
    800031a4:	e862                	sd	s8,16(sp)
    800031a6:	e466                	sd	s9,8(sp)
    800031a8:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800031aa:	0001c797          	auipc	a5,0x1c
    800031ae:	f327a783          	lw	a5,-206(a5) # 8001f0dc <sb+0x4>
    800031b2:	cff5                	beqz	a5,800032ae <balloc+0x11e>
    800031b4:	8baa                	mv	s7,a0
    800031b6:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800031b8:	0001cb17          	auipc	s6,0x1c
    800031bc:	f20b0b13          	addi	s6,s6,-224 # 8001f0d8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031c0:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800031c2:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031c4:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800031c6:	6c89                	lui	s9,0x2
    800031c8:	a061                	j	80003250 <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    800031ca:	97ca                	add	a5,a5,s2
    800031cc:	8e55                	or	a2,a2,a3
    800031ce:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    800031d2:	854a                	mv	a0,s2
    800031d4:	00001097          	auipc	ra,0x1
    800031d8:	0b4080e7          	jalr	180(ra) # 80004288 <log_write>
        brelse(bp);
    800031dc:	854a                	mv	a0,s2
    800031de:	00000097          	auipc	ra,0x0
    800031e2:	e20080e7          	jalr	-480(ra) # 80002ffe <brelse>
  bp = bread(dev, bno);
    800031e6:	85a6                	mv	a1,s1
    800031e8:	855e                	mv	a0,s7
    800031ea:	00000097          	auipc	ra,0x0
    800031ee:	ce4080e7          	jalr	-796(ra) # 80002ece <bread>
    800031f2:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800031f4:	40000613          	li	a2,1024
    800031f8:	4581                	li	a1,0
    800031fa:	05850513          	addi	a0,a0,88
    800031fe:	ffffe097          	auipc	ra,0xffffe
    80003202:	ad4080e7          	jalr	-1324(ra) # 80000cd2 <memset>
  log_write(bp);
    80003206:	854a                	mv	a0,s2
    80003208:	00001097          	auipc	ra,0x1
    8000320c:	080080e7          	jalr	128(ra) # 80004288 <log_write>
  brelse(bp);
    80003210:	854a                	mv	a0,s2
    80003212:	00000097          	auipc	ra,0x0
    80003216:	dec080e7          	jalr	-532(ra) # 80002ffe <brelse>
}
    8000321a:	8526                	mv	a0,s1
    8000321c:	60e6                	ld	ra,88(sp)
    8000321e:	6446                	ld	s0,80(sp)
    80003220:	64a6                	ld	s1,72(sp)
    80003222:	6906                	ld	s2,64(sp)
    80003224:	79e2                	ld	s3,56(sp)
    80003226:	7a42                	ld	s4,48(sp)
    80003228:	7aa2                	ld	s5,40(sp)
    8000322a:	7b02                	ld	s6,32(sp)
    8000322c:	6be2                	ld	s7,24(sp)
    8000322e:	6c42                	ld	s8,16(sp)
    80003230:	6ca2                	ld	s9,8(sp)
    80003232:	6125                	addi	sp,sp,96
    80003234:	8082                	ret
    brelse(bp);
    80003236:	854a                	mv	a0,s2
    80003238:	00000097          	auipc	ra,0x0
    8000323c:	dc6080e7          	jalr	-570(ra) # 80002ffe <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003240:	015c87bb          	addw	a5,s9,s5
    80003244:	00078a9b          	sext.w	s5,a5
    80003248:	004b2703          	lw	a4,4(s6)
    8000324c:	06eaf163          	bgeu	s5,a4,800032ae <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    80003250:	41fad79b          	sraiw	a5,s5,0x1f
    80003254:	0137d79b          	srliw	a5,a5,0x13
    80003258:	015787bb          	addw	a5,a5,s5
    8000325c:	40d7d79b          	sraiw	a5,a5,0xd
    80003260:	01cb2583          	lw	a1,28(s6)
    80003264:	9dbd                	addw	a1,a1,a5
    80003266:	855e                	mv	a0,s7
    80003268:	00000097          	auipc	ra,0x0
    8000326c:	c66080e7          	jalr	-922(ra) # 80002ece <bread>
    80003270:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003272:	004b2503          	lw	a0,4(s6)
    80003276:	000a849b          	sext.w	s1,s5
    8000327a:	8762                	mv	a4,s8
    8000327c:	faa4fde3          	bgeu	s1,a0,80003236 <balloc+0xa6>
      m = 1 << (bi % 8);
    80003280:	00777693          	andi	a3,a4,7
    80003284:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003288:	41f7579b          	sraiw	a5,a4,0x1f
    8000328c:	01d7d79b          	srliw	a5,a5,0x1d
    80003290:	9fb9                	addw	a5,a5,a4
    80003292:	4037d79b          	sraiw	a5,a5,0x3
    80003296:	00f90633          	add	a2,s2,a5
    8000329a:	05864603          	lbu	a2,88(a2)
    8000329e:	00c6f5b3          	and	a1,a3,a2
    800032a2:	d585                	beqz	a1,800031ca <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032a4:	2705                	addiw	a4,a4,1
    800032a6:	2485                	addiw	s1,s1,1
    800032a8:	fd471ae3          	bne	a4,s4,8000327c <balloc+0xec>
    800032ac:	b769                	j	80003236 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    800032ae:	00005517          	auipc	a0,0x5
    800032b2:	32250513          	addi	a0,a0,802 # 800085d0 <syscalls+0x108>
    800032b6:	ffffd097          	auipc	ra,0xffffd
    800032ba:	2d4080e7          	jalr	724(ra) # 8000058a <printf>
  return 0;
    800032be:	4481                	li	s1,0
    800032c0:	bfa9                	j	8000321a <balloc+0x8a>

00000000800032c2 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    800032c2:	7179                	addi	sp,sp,-48
    800032c4:	f406                	sd	ra,40(sp)
    800032c6:	f022                	sd	s0,32(sp)
    800032c8:	ec26                	sd	s1,24(sp)
    800032ca:	e84a                	sd	s2,16(sp)
    800032cc:	e44e                	sd	s3,8(sp)
    800032ce:	e052                	sd	s4,0(sp)
    800032d0:	1800                	addi	s0,sp,48
    800032d2:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800032d4:	47ad                	li	a5,11
    800032d6:	02b7e863          	bltu	a5,a1,80003306 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    800032da:	02059793          	slli	a5,a1,0x20
    800032de:	01e7d593          	srli	a1,a5,0x1e
    800032e2:	00b504b3          	add	s1,a0,a1
    800032e6:	0504a903          	lw	s2,80(s1)
    800032ea:	06091e63          	bnez	s2,80003366 <bmap+0xa4>
      addr = balloc(ip->dev);
    800032ee:	4108                	lw	a0,0(a0)
    800032f0:	00000097          	auipc	ra,0x0
    800032f4:	ea0080e7          	jalr	-352(ra) # 80003190 <balloc>
    800032f8:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800032fc:	06090563          	beqz	s2,80003366 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    80003300:	0524a823          	sw	s2,80(s1)
    80003304:	a08d                	j	80003366 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003306:	ff45849b          	addiw	s1,a1,-12
    8000330a:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000330e:	0ff00793          	li	a5,255
    80003312:	08e7e563          	bltu	a5,a4,8000339c <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003316:	08052903          	lw	s2,128(a0)
    8000331a:	00091d63          	bnez	s2,80003334 <bmap+0x72>
      addr = balloc(ip->dev);
    8000331e:	4108                	lw	a0,0(a0)
    80003320:	00000097          	auipc	ra,0x0
    80003324:	e70080e7          	jalr	-400(ra) # 80003190 <balloc>
    80003328:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000332c:	02090d63          	beqz	s2,80003366 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003330:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003334:	85ca                	mv	a1,s2
    80003336:	0009a503          	lw	a0,0(s3)
    8000333a:	00000097          	auipc	ra,0x0
    8000333e:	b94080e7          	jalr	-1132(ra) # 80002ece <bread>
    80003342:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003344:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003348:	02049713          	slli	a4,s1,0x20
    8000334c:	01e75593          	srli	a1,a4,0x1e
    80003350:	00b784b3          	add	s1,a5,a1
    80003354:	0004a903          	lw	s2,0(s1)
    80003358:	02090063          	beqz	s2,80003378 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    8000335c:	8552                	mv	a0,s4
    8000335e:	00000097          	auipc	ra,0x0
    80003362:	ca0080e7          	jalr	-864(ra) # 80002ffe <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003366:	854a                	mv	a0,s2
    80003368:	70a2                	ld	ra,40(sp)
    8000336a:	7402                	ld	s0,32(sp)
    8000336c:	64e2                	ld	s1,24(sp)
    8000336e:	6942                	ld	s2,16(sp)
    80003370:	69a2                	ld	s3,8(sp)
    80003372:	6a02                	ld	s4,0(sp)
    80003374:	6145                	addi	sp,sp,48
    80003376:	8082                	ret
      addr = balloc(ip->dev);
    80003378:	0009a503          	lw	a0,0(s3)
    8000337c:	00000097          	auipc	ra,0x0
    80003380:	e14080e7          	jalr	-492(ra) # 80003190 <balloc>
    80003384:	0005091b          	sext.w	s2,a0
      if(addr){
    80003388:	fc090ae3          	beqz	s2,8000335c <bmap+0x9a>
        a[bn] = addr;
    8000338c:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003390:	8552                	mv	a0,s4
    80003392:	00001097          	auipc	ra,0x1
    80003396:	ef6080e7          	jalr	-266(ra) # 80004288 <log_write>
    8000339a:	b7c9                	j	8000335c <bmap+0x9a>
  panic("bmap: out of range");
    8000339c:	00005517          	auipc	a0,0x5
    800033a0:	24c50513          	addi	a0,a0,588 # 800085e8 <syscalls+0x120>
    800033a4:	ffffd097          	auipc	ra,0xffffd
    800033a8:	19c080e7          	jalr	412(ra) # 80000540 <panic>

00000000800033ac <iget>:
{
    800033ac:	7179                	addi	sp,sp,-48
    800033ae:	f406                	sd	ra,40(sp)
    800033b0:	f022                	sd	s0,32(sp)
    800033b2:	ec26                	sd	s1,24(sp)
    800033b4:	e84a                	sd	s2,16(sp)
    800033b6:	e44e                	sd	s3,8(sp)
    800033b8:	e052                	sd	s4,0(sp)
    800033ba:	1800                	addi	s0,sp,48
    800033bc:	89aa                	mv	s3,a0
    800033be:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800033c0:	0001c517          	auipc	a0,0x1c
    800033c4:	d3850513          	addi	a0,a0,-712 # 8001f0f8 <itable>
    800033c8:	ffffe097          	auipc	ra,0xffffe
    800033cc:	80e080e7          	jalr	-2034(ra) # 80000bd6 <acquire>
  empty = 0;
    800033d0:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800033d2:	0001c497          	auipc	s1,0x1c
    800033d6:	d3e48493          	addi	s1,s1,-706 # 8001f110 <itable+0x18>
    800033da:	0001d697          	auipc	a3,0x1d
    800033de:	7c668693          	addi	a3,a3,1990 # 80020ba0 <log>
    800033e2:	a039                	j	800033f0 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800033e4:	02090b63          	beqz	s2,8000341a <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800033e8:	08848493          	addi	s1,s1,136
    800033ec:	02d48a63          	beq	s1,a3,80003420 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800033f0:	449c                	lw	a5,8(s1)
    800033f2:	fef059e3          	blez	a5,800033e4 <iget+0x38>
    800033f6:	4098                	lw	a4,0(s1)
    800033f8:	ff3716e3          	bne	a4,s3,800033e4 <iget+0x38>
    800033fc:	40d8                	lw	a4,4(s1)
    800033fe:	ff4713e3          	bne	a4,s4,800033e4 <iget+0x38>
      ip->ref++;
    80003402:	2785                	addiw	a5,a5,1
    80003404:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003406:	0001c517          	auipc	a0,0x1c
    8000340a:	cf250513          	addi	a0,a0,-782 # 8001f0f8 <itable>
    8000340e:	ffffe097          	auipc	ra,0xffffe
    80003412:	87c080e7          	jalr	-1924(ra) # 80000c8a <release>
      return ip;
    80003416:	8926                	mv	s2,s1
    80003418:	a03d                	j	80003446 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000341a:	f7f9                	bnez	a5,800033e8 <iget+0x3c>
    8000341c:	8926                	mv	s2,s1
    8000341e:	b7e9                	j	800033e8 <iget+0x3c>
  if(empty == 0)
    80003420:	02090c63          	beqz	s2,80003458 <iget+0xac>
  ip->dev = dev;
    80003424:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003428:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000342c:	4785                	li	a5,1
    8000342e:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003432:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003436:	0001c517          	auipc	a0,0x1c
    8000343a:	cc250513          	addi	a0,a0,-830 # 8001f0f8 <itable>
    8000343e:	ffffe097          	auipc	ra,0xffffe
    80003442:	84c080e7          	jalr	-1972(ra) # 80000c8a <release>
}
    80003446:	854a                	mv	a0,s2
    80003448:	70a2                	ld	ra,40(sp)
    8000344a:	7402                	ld	s0,32(sp)
    8000344c:	64e2                	ld	s1,24(sp)
    8000344e:	6942                	ld	s2,16(sp)
    80003450:	69a2                	ld	s3,8(sp)
    80003452:	6a02                	ld	s4,0(sp)
    80003454:	6145                	addi	sp,sp,48
    80003456:	8082                	ret
    panic("iget: no inodes");
    80003458:	00005517          	auipc	a0,0x5
    8000345c:	1a850513          	addi	a0,a0,424 # 80008600 <syscalls+0x138>
    80003460:	ffffd097          	auipc	ra,0xffffd
    80003464:	0e0080e7          	jalr	224(ra) # 80000540 <panic>

0000000080003468 <fsinit>:
fsinit(int dev) {
    80003468:	7179                	addi	sp,sp,-48
    8000346a:	f406                	sd	ra,40(sp)
    8000346c:	f022                	sd	s0,32(sp)
    8000346e:	ec26                	sd	s1,24(sp)
    80003470:	e84a                	sd	s2,16(sp)
    80003472:	e44e                	sd	s3,8(sp)
    80003474:	1800                	addi	s0,sp,48
    80003476:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003478:	4585                	li	a1,1
    8000347a:	00000097          	auipc	ra,0x0
    8000347e:	a54080e7          	jalr	-1452(ra) # 80002ece <bread>
    80003482:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003484:	0001c997          	auipc	s3,0x1c
    80003488:	c5498993          	addi	s3,s3,-940 # 8001f0d8 <sb>
    8000348c:	02000613          	li	a2,32
    80003490:	05850593          	addi	a1,a0,88
    80003494:	854e                	mv	a0,s3
    80003496:	ffffe097          	auipc	ra,0xffffe
    8000349a:	898080e7          	jalr	-1896(ra) # 80000d2e <memmove>
  brelse(bp);
    8000349e:	8526                	mv	a0,s1
    800034a0:	00000097          	auipc	ra,0x0
    800034a4:	b5e080e7          	jalr	-1186(ra) # 80002ffe <brelse>
  if(sb.magic != FSMAGIC)
    800034a8:	0009a703          	lw	a4,0(s3)
    800034ac:	102037b7          	lui	a5,0x10203
    800034b0:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800034b4:	02f71263          	bne	a4,a5,800034d8 <fsinit+0x70>
  initlog(dev, &sb);
    800034b8:	0001c597          	auipc	a1,0x1c
    800034bc:	c2058593          	addi	a1,a1,-992 # 8001f0d8 <sb>
    800034c0:	854a                	mv	a0,s2
    800034c2:	00001097          	auipc	ra,0x1
    800034c6:	b4a080e7          	jalr	-1206(ra) # 8000400c <initlog>
}
    800034ca:	70a2                	ld	ra,40(sp)
    800034cc:	7402                	ld	s0,32(sp)
    800034ce:	64e2                	ld	s1,24(sp)
    800034d0:	6942                	ld	s2,16(sp)
    800034d2:	69a2                	ld	s3,8(sp)
    800034d4:	6145                	addi	sp,sp,48
    800034d6:	8082                	ret
    panic("invalid file system");
    800034d8:	00005517          	auipc	a0,0x5
    800034dc:	13850513          	addi	a0,a0,312 # 80008610 <syscalls+0x148>
    800034e0:	ffffd097          	auipc	ra,0xffffd
    800034e4:	060080e7          	jalr	96(ra) # 80000540 <panic>

00000000800034e8 <iinit>:
{
    800034e8:	7179                	addi	sp,sp,-48
    800034ea:	f406                	sd	ra,40(sp)
    800034ec:	f022                	sd	s0,32(sp)
    800034ee:	ec26                	sd	s1,24(sp)
    800034f0:	e84a                	sd	s2,16(sp)
    800034f2:	e44e                	sd	s3,8(sp)
    800034f4:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800034f6:	00005597          	auipc	a1,0x5
    800034fa:	13258593          	addi	a1,a1,306 # 80008628 <syscalls+0x160>
    800034fe:	0001c517          	auipc	a0,0x1c
    80003502:	bfa50513          	addi	a0,a0,-1030 # 8001f0f8 <itable>
    80003506:	ffffd097          	auipc	ra,0xffffd
    8000350a:	640080e7          	jalr	1600(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000350e:	0001c497          	auipc	s1,0x1c
    80003512:	c1248493          	addi	s1,s1,-1006 # 8001f120 <itable+0x28>
    80003516:	0001d997          	auipc	s3,0x1d
    8000351a:	69a98993          	addi	s3,s3,1690 # 80020bb0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000351e:	00005917          	auipc	s2,0x5
    80003522:	11290913          	addi	s2,s2,274 # 80008630 <syscalls+0x168>
    80003526:	85ca                	mv	a1,s2
    80003528:	8526                	mv	a0,s1
    8000352a:	00001097          	auipc	ra,0x1
    8000352e:	e42080e7          	jalr	-446(ra) # 8000436c <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003532:	08848493          	addi	s1,s1,136
    80003536:	ff3498e3          	bne	s1,s3,80003526 <iinit+0x3e>
}
    8000353a:	70a2                	ld	ra,40(sp)
    8000353c:	7402                	ld	s0,32(sp)
    8000353e:	64e2                	ld	s1,24(sp)
    80003540:	6942                	ld	s2,16(sp)
    80003542:	69a2                	ld	s3,8(sp)
    80003544:	6145                	addi	sp,sp,48
    80003546:	8082                	ret

0000000080003548 <ialloc>:
{
    80003548:	715d                	addi	sp,sp,-80
    8000354a:	e486                	sd	ra,72(sp)
    8000354c:	e0a2                	sd	s0,64(sp)
    8000354e:	fc26                	sd	s1,56(sp)
    80003550:	f84a                	sd	s2,48(sp)
    80003552:	f44e                	sd	s3,40(sp)
    80003554:	f052                	sd	s4,32(sp)
    80003556:	ec56                	sd	s5,24(sp)
    80003558:	e85a                	sd	s6,16(sp)
    8000355a:	e45e                	sd	s7,8(sp)
    8000355c:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000355e:	0001c717          	auipc	a4,0x1c
    80003562:	b8672703          	lw	a4,-1146(a4) # 8001f0e4 <sb+0xc>
    80003566:	4785                	li	a5,1
    80003568:	04e7fa63          	bgeu	a5,a4,800035bc <ialloc+0x74>
    8000356c:	8aaa                	mv	s5,a0
    8000356e:	8bae                	mv	s7,a1
    80003570:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003572:	0001ca17          	auipc	s4,0x1c
    80003576:	b66a0a13          	addi	s4,s4,-1178 # 8001f0d8 <sb>
    8000357a:	00048b1b          	sext.w	s6,s1
    8000357e:	0044d593          	srli	a1,s1,0x4
    80003582:	018a2783          	lw	a5,24(s4)
    80003586:	9dbd                	addw	a1,a1,a5
    80003588:	8556                	mv	a0,s5
    8000358a:	00000097          	auipc	ra,0x0
    8000358e:	944080e7          	jalr	-1724(ra) # 80002ece <bread>
    80003592:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003594:	05850993          	addi	s3,a0,88
    80003598:	00f4f793          	andi	a5,s1,15
    8000359c:	079a                	slli	a5,a5,0x6
    8000359e:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800035a0:	00099783          	lh	a5,0(s3)
    800035a4:	c3a1                	beqz	a5,800035e4 <ialloc+0x9c>
    brelse(bp);
    800035a6:	00000097          	auipc	ra,0x0
    800035aa:	a58080e7          	jalr	-1448(ra) # 80002ffe <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800035ae:	0485                	addi	s1,s1,1
    800035b0:	00ca2703          	lw	a4,12(s4)
    800035b4:	0004879b          	sext.w	a5,s1
    800035b8:	fce7e1e3          	bltu	a5,a4,8000357a <ialloc+0x32>
  printf("ialloc: no inodes\n");
    800035bc:	00005517          	auipc	a0,0x5
    800035c0:	07c50513          	addi	a0,a0,124 # 80008638 <syscalls+0x170>
    800035c4:	ffffd097          	auipc	ra,0xffffd
    800035c8:	fc6080e7          	jalr	-58(ra) # 8000058a <printf>
  return 0;
    800035cc:	4501                	li	a0,0
}
    800035ce:	60a6                	ld	ra,72(sp)
    800035d0:	6406                	ld	s0,64(sp)
    800035d2:	74e2                	ld	s1,56(sp)
    800035d4:	7942                	ld	s2,48(sp)
    800035d6:	79a2                	ld	s3,40(sp)
    800035d8:	7a02                	ld	s4,32(sp)
    800035da:	6ae2                	ld	s5,24(sp)
    800035dc:	6b42                	ld	s6,16(sp)
    800035de:	6ba2                	ld	s7,8(sp)
    800035e0:	6161                	addi	sp,sp,80
    800035e2:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    800035e4:	04000613          	li	a2,64
    800035e8:	4581                	li	a1,0
    800035ea:	854e                	mv	a0,s3
    800035ec:	ffffd097          	auipc	ra,0xffffd
    800035f0:	6e6080e7          	jalr	1766(ra) # 80000cd2 <memset>
      dip->type = type;
    800035f4:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800035f8:	854a                	mv	a0,s2
    800035fa:	00001097          	auipc	ra,0x1
    800035fe:	c8e080e7          	jalr	-882(ra) # 80004288 <log_write>
      brelse(bp);
    80003602:	854a                	mv	a0,s2
    80003604:	00000097          	auipc	ra,0x0
    80003608:	9fa080e7          	jalr	-1542(ra) # 80002ffe <brelse>
      return iget(dev, inum);
    8000360c:	85da                	mv	a1,s6
    8000360e:	8556                	mv	a0,s5
    80003610:	00000097          	auipc	ra,0x0
    80003614:	d9c080e7          	jalr	-612(ra) # 800033ac <iget>
    80003618:	bf5d                	j	800035ce <ialloc+0x86>

000000008000361a <iupdate>:
{
    8000361a:	1101                	addi	sp,sp,-32
    8000361c:	ec06                	sd	ra,24(sp)
    8000361e:	e822                	sd	s0,16(sp)
    80003620:	e426                	sd	s1,8(sp)
    80003622:	e04a                	sd	s2,0(sp)
    80003624:	1000                	addi	s0,sp,32
    80003626:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003628:	415c                	lw	a5,4(a0)
    8000362a:	0047d79b          	srliw	a5,a5,0x4
    8000362e:	0001c597          	auipc	a1,0x1c
    80003632:	ac25a583          	lw	a1,-1342(a1) # 8001f0f0 <sb+0x18>
    80003636:	9dbd                	addw	a1,a1,a5
    80003638:	4108                	lw	a0,0(a0)
    8000363a:	00000097          	auipc	ra,0x0
    8000363e:	894080e7          	jalr	-1900(ra) # 80002ece <bread>
    80003642:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003644:	05850793          	addi	a5,a0,88
    80003648:	40d8                	lw	a4,4(s1)
    8000364a:	8b3d                	andi	a4,a4,15
    8000364c:	071a                	slli	a4,a4,0x6
    8000364e:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003650:	04449703          	lh	a4,68(s1)
    80003654:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003658:	04649703          	lh	a4,70(s1)
    8000365c:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003660:	04849703          	lh	a4,72(s1)
    80003664:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003668:	04a49703          	lh	a4,74(s1)
    8000366c:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003670:	44f8                	lw	a4,76(s1)
    80003672:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003674:	03400613          	li	a2,52
    80003678:	05048593          	addi	a1,s1,80
    8000367c:	00c78513          	addi	a0,a5,12
    80003680:	ffffd097          	auipc	ra,0xffffd
    80003684:	6ae080e7          	jalr	1710(ra) # 80000d2e <memmove>
  log_write(bp);
    80003688:	854a                	mv	a0,s2
    8000368a:	00001097          	auipc	ra,0x1
    8000368e:	bfe080e7          	jalr	-1026(ra) # 80004288 <log_write>
  brelse(bp);
    80003692:	854a                	mv	a0,s2
    80003694:	00000097          	auipc	ra,0x0
    80003698:	96a080e7          	jalr	-1686(ra) # 80002ffe <brelse>
}
    8000369c:	60e2                	ld	ra,24(sp)
    8000369e:	6442                	ld	s0,16(sp)
    800036a0:	64a2                	ld	s1,8(sp)
    800036a2:	6902                	ld	s2,0(sp)
    800036a4:	6105                	addi	sp,sp,32
    800036a6:	8082                	ret

00000000800036a8 <idup>:
{
    800036a8:	1101                	addi	sp,sp,-32
    800036aa:	ec06                	sd	ra,24(sp)
    800036ac:	e822                	sd	s0,16(sp)
    800036ae:	e426                	sd	s1,8(sp)
    800036b0:	1000                	addi	s0,sp,32
    800036b2:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800036b4:	0001c517          	auipc	a0,0x1c
    800036b8:	a4450513          	addi	a0,a0,-1468 # 8001f0f8 <itable>
    800036bc:	ffffd097          	auipc	ra,0xffffd
    800036c0:	51a080e7          	jalr	1306(ra) # 80000bd6 <acquire>
  ip->ref++;
    800036c4:	449c                	lw	a5,8(s1)
    800036c6:	2785                	addiw	a5,a5,1
    800036c8:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800036ca:	0001c517          	auipc	a0,0x1c
    800036ce:	a2e50513          	addi	a0,a0,-1490 # 8001f0f8 <itable>
    800036d2:	ffffd097          	auipc	ra,0xffffd
    800036d6:	5b8080e7          	jalr	1464(ra) # 80000c8a <release>
}
    800036da:	8526                	mv	a0,s1
    800036dc:	60e2                	ld	ra,24(sp)
    800036de:	6442                	ld	s0,16(sp)
    800036e0:	64a2                	ld	s1,8(sp)
    800036e2:	6105                	addi	sp,sp,32
    800036e4:	8082                	ret

00000000800036e6 <ilock>:
{
    800036e6:	1101                	addi	sp,sp,-32
    800036e8:	ec06                	sd	ra,24(sp)
    800036ea:	e822                	sd	s0,16(sp)
    800036ec:	e426                	sd	s1,8(sp)
    800036ee:	e04a                	sd	s2,0(sp)
    800036f0:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800036f2:	c115                	beqz	a0,80003716 <ilock+0x30>
    800036f4:	84aa                	mv	s1,a0
    800036f6:	451c                	lw	a5,8(a0)
    800036f8:	00f05f63          	blez	a5,80003716 <ilock+0x30>
  acquiresleep(&ip->lock);
    800036fc:	0541                	addi	a0,a0,16
    800036fe:	00001097          	auipc	ra,0x1
    80003702:	ca8080e7          	jalr	-856(ra) # 800043a6 <acquiresleep>
  if(ip->valid == 0){
    80003706:	40bc                	lw	a5,64(s1)
    80003708:	cf99                	beqz	a5,80003726 <ilock+0x40>
}
    8000370a:	60e2                	ld	ra,24(sp)
    8000370c:	6442                	ld	s0,16(sp)
    8000370e:	64a2                	ld	s1,8(sp)
    80003710:	6902                	ld	s2,0(sp)
    80003712:	6105                	addi	sp,sp,32
    80003714:	8082                	ret
    panic("ilock");
    80003716:	00005517          	auipc	a0,0x5
    8000371a:	f3a50513          	addi	a0,a0,-198 # 80008650 <syscalls+0x188>
    8000371e:	ffffd097          	auipc	ra,0xffffd
    80003722:	e22080e7          	jalr	-478(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003726:	40dc                	lw	a5,4(s1)
    80003728:	0047d79b          	srliw	a5,a5,0x4
    8000372c:	0001c597          	auipc	a1,0x1c
    80003730:	9c45a583          	lw	a1,-1596(a1) # 8001f0f0 <sb+0x18>
    80003734:	9dbd                	addw	a1,a1,a5
    80003736:	4088                	lw	a0,0(s1)
    80003738:	fffff097          	auipc	ra,0xfffff
    8000373c:	796080e7          	jalr	1942(ra) # 80002ece <bread>
    80003740:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003742:	05850593          	addi	a1,a0,88
    80003746:	40dc                	lw	a5,4(s1)
    80003748:	8bbd                	andi	a5,a5,15
    8000374a:	079a                	slli	a5,a5,0x6
    8000374c:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000374e:	00059783          	lh	a5,0(a1)
    80003752:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003756:	00259783          	lh	a5,2(a1)
    8000375a:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000375e:	00459783          	lh	a5,4(a1)
    80003762:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003766:	00659783          	lh	a5,6(a1)
    8000376a:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000376e:	459c                	lw	a5,8(a1)
    80003770:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003772:	03400613          	li	a2,52
    80003776:	05b1                	addi	a1,a1,12
    80003778:	05048513          	addi	a0,s1,80
    8000377c:	ffffd097          	auipc	ra,0xffffd
    80003780:	5b2080e7          	jalr	1458(ra) # 80000d2e <memmove>
    brelse(bp);
    80003784:	854a                	mv	a0,s2
    80003786:	00000097          	auipc	ra,0x0
    8000378a:	878080e7          	jalr	-1928(ra) # 80002ffe <brelse>
    ip->valid = 1;
    8000378e:	4785                	li	a5,1
    80003790:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003792:	04449783          	lh	a5,68(s1)
    80003796:	fbb5                	bnez	a5,8000370a <ilock+0x24>
      panic("ilock: no type");
    80003798:	00005517          	auipc	a0,0x5
    8000379c:	ec050513          	addi	a0,a0,-320 # 80008658 <syscalls+0x190>
    800037a0:	ffffd097          	auipc	ra,0xffffd
    800037a4:	da0080e7          	jalr	-608(ra) # 80000540 <panic>

00000000800037a8 <iunlock>:
{
    800037a8:	1101                	addi	sp,sp,-32
    800037aa:	ec06                	sd	ra,24(sp)
    800037ac:	e822                	sd	s0,16(sp)
    800037ae:	e426                	sd	s1,8(sp)
    800037b0:	e04a                	sd	s2,0(sp)
    800037b2:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800037b4:	c905                	beqz	a0,800037e4 <iunlock+0x3c>
    800037b6:	84aa                	mv	s1,a0
    800037b8:	01050913          	addi	s2,a0,16
    800037bc:	854a                	mv	a0,s2
    800037be:	00001097          	auipc	ra,0x1
    800037c2:	c82080e7          	jalr	-894(ra) # 80004440 <holdingsleep>
    800037c6:	cd19                	beqz	a0,800037e4 <iunlock+0x3c>
    800037c8:	449c                	lw	a5,8(s1)
    800037ca:	00f05d63          	blez	a5,800037e4 <iunlock+0x3c>
  releasesleep(&ip->lock);
    800037ce:	854a                	mv	a0,s2
    800037d0:	00001097          	auipc	ra,0x1
    800037d4:	c2c080e7          	jalr	-980(ra) # 800043fc <releasesleep>
}
    800037d8:	60e2                	ld	ra,24(sp)
    800037da:	6442                	ld	s0,16(sp)
    800037dc:	64a2                	ld	s1,8(sp)
    800037de:	6902                	ld	s2,0(sp)
    800037e0:	6105                	addi	sp,sp,32
    800037e2:	8082                	ret
    panic("iunlock");
    800037e4:	00005517          	auipc	a0,0x5
    800037e8:	e8450513          	addi	a0,a0,-380 # 80008668 <syscalls+0x1a0>
    800037ec:	ffffd097          	auipc	ra,0xffffd
    800037f0:	d54080e7          	jalr	-684(ra) # 80000540 <panic>

00000000800037f4 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800037f4:	7179                	addi	sp,sp,-48
    800037f6:	f406                	sd	ra,40(sp)
    800037f8:	f022                	sd	s0,32(sp)
    800037fa:	ec26                	sd	s1,24(sp)
    800037fc:	e84a                	sd	s2,16(sp)
    800037fe:	e44e                	sd	s3,8(sp)
    80003800:	e052                	sd	s4,0(sp)
    80003802:	1800                	addi	s0,sp,48
    80003804:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003806:	05050493          	addi	s1,a0,80
    8000380a:	08050913          	addi	s2,a0,128
    8000380e:	a021                	j	80003816 <itrunc+0x22>
    80003810:	0491                	addi	s1,s1,4
    80003812:	01248d63          	beq	s1,s2,8000382c <itrunc+0x38>
    if(ip->addrs[i]){
    80003816:	408c                	lw	a1,0(s1)
    80003818:	dde5                	beqz	a1,80003810 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    8000381a:	0009a503          	lw	a0,0(s3)
    8000381e:	00000097          	auipc	ra,0x0
    80003822:	8f6080e7          	jalr	-1802(ra) # 80003114 <bfree>
      ip->addrs[i] = 0;
    80003826:	0004a023          	sw	zero,0(s1)
    8000382a:	b7dd                	j	80003810 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000382c:	0809a583          	lw	a1,128(s3)
    80003830:	e185                	bnez	a1,80003850 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003832:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003836:	854e                	mv	a0,s3
    80003838:	00000097          	auipc	ra,0x0
    8000383c:	de2080e7          	jalr	-542(ra) # 8000361a <iupdate>
}
    80003840:	70a2                	ld	ra,40(sp)
    80003842:	7402                	ld	s0,32(sp)
    80003844:	64e2                	ld	s1,24(sp)
    80003846:	6942                	ld	s2,16(sp)
    80003848:	69a2                	ld	s3,8(sp)
    8000384a:	6a02                	ld	s4,0(sp)
    8000384c:	6145                	addi	sp,sp,48
    8000384e:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003850:	0009a503          	lw	a0,0(s3)
    80003854:	fffff097          	auipc	ra,0xfffff
    80003858:	67a080e7          	jalr	1658(ra) # 80002ece <bread>
    8000385c:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    8000385e:	05850493          	addi	s1,a0,88
    80003862:	45850913          	addi	s2,a0,1112
    80003866:	a021                	j	8000386e <itrunc+0x7a>
    80003868:	0491                	addi	s1,s1,4
    8000386a:	01248b63          	beq	s1,s2,80003880 <itrunc+0x8c>
      if(a[j])
    8000386e:	408c                	lw	a1,0(s1)
    80003870:	dde5                	beqz	a1,80003868 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003872:	0009a503          	lw	a0,0(s3)
    80003876:	00000097          	auipc	ra,0x0
    8000387a:	89e080e7          	jalr	-1890(ra) # 80003114 <bfree>
    8000387e:	b7ed                	j	80003868 <itrunc+0x74>
    brelse(bp);
    80003880:	8552                	mv	a0,s4
    80003882:	fffff097          	auipc	ra,0xfffff
    80003886:	77c080e7          	jalr	1916(ra) # 80002ffe <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000388a:	0809a583          	lw	a1,128(s3)
    8000388e:	0009a503          	lw	a0,0(s3)
    80003892:	00000097          	auipc	ra,0x0
    80003896:	882080e7          	jalr	-1918(ra) # 80003114 <bfree>
    ip->addrs[NDIRECT] = 0;
    8000389a:	0809a023          	sw	zero,128(s3)
    8000389e:	bf51                	j	80003832 <itrunc+0x3e>

00000000800038a0 <iput>:
{
    800038a0:	1101                	addi	sp,sp,-32
    800038a2:	ec06                	sd	ra,24(sp)
    800038a4:	e822                	sd	s0,16(sp)
    800038a6:	e426                	sd	s1,8(sp)
    800038a8:	e04a                	sd	s2,0(sp)
    800038aa:	1000                	addi	s0,sp,32
    800038ac:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800038ae:	0001c517          	auipc	a0,0x1c
    800038b2:	84a50513          	addi	a0,a0,-1974 # 8001f0f8 <itable>
    800038b6:	ffffd097          	auipc	ra,0xffffd
    800038ba:	320080e7          	jalr	800(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800038be:	4498                	lw	a4,8(s1)
    800038c0:	4785                	li	a5,1
    800038c2:	02f70363          	beq	a4,a5,800038e8 <iput+0x48>
  ip->ref--;
    800038c6:	449c                	lw	a5,8(s1)
    800038c8:	37fd                	addiw	a5,a5,-1
    800038ca:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800038cc:	0001c517          	auipc	a0,0x1c
    800038d0:	82c50513          	addi	a0,a0,-2004 # 8001f0f8 <itable>
    800038d4:	ffffd097          	auipc	ra,0xffffd
    800038d8:	3b6080e7          	jalr	950(ra) # 80000c8a <release>
}
    800038dc:	60e2                	ld	ra,24(sp)
    800038de:	6442                	ld	s0,16(sp)
    800038e0:	64a2                	ld	s1,8(sp)
    800038e2:	6902                	ld	s2,0(sp)
    800038e4:	6105                	addi	sp,sp,32
    800038e6:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800038e8:	40bc                	lw	a5,64(s1)
    800038ea:	dff1                	beqz	a5,800038c6 <iput+0x26>
    800038ec:	04a49783          	lh	a5,74(s1)
    800038f0:	fbf9                	bnez	a5,800038c6 <iput+0x26>
    acquiresleep(&ip->lock);
    800038f2:	01048913          	addi	s2,s1,16
    800038f6:	854a                	mv	a0,s2
    800038f8:	00001097          	auipc	ra,0x1
    800038fc:	aae080e7          	jalr	-1362(ra) # 800043a6 <acquiresleep>
    release(&itable.lock);
    80003900:	0001b517          	auipc	a0,0x1b
    80003904:	7f850513          	addi	a0,a0,2040 # 8001f0f8 <itable>
    80003908:	ffffd097          	auipc	ra,0xffffd
    8000390c:	382080e7          	jalr	898(ra) # 80000c8a <release>
    itrunc(ip);
    80003910:	8526                	mv	a0,s1
    80003912:	00000097          	auipc	ra,0x0
    80003916:	ee2080e7          	jalr	-286(ra) # 800037f4 <itrunc>
    ip->type = 0;
    8000391a:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    8000391e:	8526                	mv	a0,s1
    80003920:	00000097          	auipc	ra,0x0
    80003924:	cfa080e7          	jalr	-774(ra) # 8000361a <iupdate>
    ip->valid = 0;
    80003928:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    8000392c:	854a                	mv	a0,s2
    8000392e:	00001097          	auipc	ra,0x1
    80003932:	ace080e7          	jalr	-1330(ra) # 800043fc <releasesleep>
    acquire(&itable.lock);
    80003936:	0001b517          	auipc	a0,0x1b
    8000393a:	7c250513          	addi	a0,a0,1986 # 8001f0f8 <itable>
    8000393e:	ffffd097          	auipc	ra,0xffffd
    80003942:	298080e7          	jalr	664(ra) # 80000bd6 <acquire>
    80003946:	b741                	j	800038c6 <iput+0x26>

0000000080003948 <iunlockput>:
{
    80003948:	1101                	addi	sp,sp,-32
    8000394a:	ec06                	sd	ra,24(sp)
    8000394c:	e822                	sd	s0,16(sp)
    8000394e:	e426                	sd	s1,8(sp)
    80003950:	1000                	addi	s0,sp,32
    80003952:	84aa                	mv	s1,a0
  iunlock(ip);
    80003954:	00000097          	auipc	ra,0x0
    80003958:	e54080e7          	jalr	-428(ra) # 800037a8 <iunlock>
  iput(ip);
    8000395c:	8526                	mv	a0,s1
    8000395e:	00000097          	auipc	ra,0x0
    80003962:	f42080e7          	jalr	-190(ra) # 800038a0 <iput>
}
    80003966:	60e2                	ld	ra,24(sp)
    80003968:	6442                	ld	s0,16(sp)
    8000396a:	64a2                	ld	s1,8(sp)
    8000396c:	6105                	addi	sp,sp,32
    8000396e:	8082                	ret

0000000080003970 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003970:	1141                	addi	sp,sp,-16
    80003972:	e422                	sd	s0,8(sp)
    80003974:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003976:	411c                	lw	a5,0(a0)
    80003978:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    8000397a:	415c                	lw	a5,4(a0)
    8000397c:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    8000397e:	04451783          	lh	a5,68(a0)
    80003982:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003986:	04a51783          	lh	a5,74(a0)
    8000398a:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    8000398e:	04c56783          	lwu	a5,76(a0)
    80003992:	e99c                	sd	a5,16(a1)
}
    80003994:	6422                	ld	s0,8(sp)
    80003996:	0141                	addi	sp,sp,16
    80003998:	8082                	ret

000000008000399a <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000399a:	457c                	lw	a5,76(a0)
    8000399c:	0ed7e963          	bltu	a5,a3,80003a8e <readi+0xf4>
{
    800039a0:	7159                	addi	sp,sp,-112
    800039a2:	f486                	sd	ra,104(sp)
    800039a4:	f0a2                	sd	s0,96(sp)
    800039a6:	eca6                	sd	s1,88(sp)
    800039a8:	e8ca                	sd	s2,80(sp)
    800039aa:	e4ce                	sd	s3,72(sp)
    800039ac:	e0d2                	sd	s4,64(sp)
    800039ae:	fc56                	sd	s5,56(sp)
    800039b0:	f85a                	sd	s6,48(sp)
    800039b2:	f45e                	sd	s7,40(sp)
    800039b4:	f062                	sd	s8,32(sp)
    800039b6:	ec66                	sd	s9,24(sp)
    800039b8:	e86a                	sd	s10,16(sp)
    800039ba:	e46e                	sd	s11,8(sp)
    800039bc:	1880                	addi	s0,sp,112
    800039be:	8b2a                	mv	s6,a0
    800039c0:	8bae                	mv	s7,a1
    800039c2:	8a32                	mv	s4,a2
    800039c4:	84b6                	mv	s1,a3
    800039c6:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    800039c8:	9f35                	addw	a4,a4,a3
    return 0;
    800039ca:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800039cc:	0ad76063          	bltu	a4,a3,80003a6c <readi+0xd2>
  if(off + n > ip->size)
    800039d0:	00e7f463          	bgeu	a5,a4,800039d8 <readi+0x3e>
    n = ip->size - off;
    800039d4:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800039d8:	0a0a8963          	beqz	s5,80003a8a <readi+0xf0>
    800039dc:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    800039de:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800039e2:	5c7d                	li	s8,-1
    800039e4:	a82d                	j	80003a1e <readi+0x84>
    800039e6:	020d1d93          	slli	s11,s10,0x20
    800039ea:	020ddd93          	srli	s11,s11,0x20
    800039ee:	05890613          	addi	a2,s2,88
    800039f2:	86ee                	mv	a3,s11
    800039f4:	963a                	add	a2,a2,a4
    800039f6:	85d2                	mv	a1,s4
    800039f8:	855e                	mv	a0,s7
    800039fa:	fffff097          	auipc	ra,0xfffff
    800039fe:	a62080e7          	jalr	-1438(ra) # 8000245c <either_copyout>
    80003a02:	05850d63          	beq	a0,s8,80003a5c <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003a06:	854a                	mv	a0,s2
    80003a08:	fffff097          	auipc	ra,0xfffff
    80003a0c:	5f6080e7          	jalr	1526(ra) # 80002ffe <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a10:	013d09bb          	addw	s3,s10,s3
    80003a14:	009d04bb          	addw	s1,s10,s1
    80003a18:	9a6e                	add	s4,s4,s11
    80003a1a:	0559f763          	bgeu	s3,s5,80003a68 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003a1e:	00a4d59b          	srliw	a1,s1,0xa
    80003a22:	855a                	mv	a0,s6
    80003a24:	00000097          	auipc	ra,0x0
    80003a28:	89e080e7          	jalr	-1890(ra) # 800032c2 <bmap>
    80003a2c:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003a30:	cd85                	beqz	a1,80003a68 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003a32:	000b2503          	lw	a0,0(s6)
    80003a36:	fffff097          	auipc	ra,0xfffff
    80003a3a:	498080e7          	jalr	1176(ra) # 80002ece <bread>
    80003a3e:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a40:	3ff4f713          	andi	a4,s1,1023
    80003a44:	40ec87bb          	subw	a5,s9,a4
    80003a48:	413a86bb          	subw	a3,s5,s3
    80003a4c:	8d3e                	mv	s10,a5
    80003a4e:	2781                	sext.w	a5,a5
    80003a50:	0006861b          	sext.w	a2,a3
    80003a54:	f8f679e3          	bgeu	a2,a5,800039e6 <readi+0x4c>
    80003a58:	8d36                	mv	s10,a3
    80003a5a:	b771                	j	800039e6 <readi+0x4c>
      brelse(bp);
    80003a5c:	854a                	mv	a0,s2
    80003a5e:	fffff097          	auipc	ra,0xfffff
    80003a62:	5a0080e7          	jalr	1440(ra) # 80002ffe <brelse>
      tot = -1;
    80003a66:	59fd                	li	s3,-1
  }
  return tot;
    80003a68:	0009851b          	sext.w	a0,s3
}
    80003a6c:	70a6                	ld	ra,104(sp)
    80003a6e:	7406                	ld	s0,96(sp)
    80003a70:	64e6                	ld	s1,88(sp)
    80003a72:	6946                	ld	s2,80(sp)
    80003a74:	69a6                	ld	s3,72(sp)
    80003a76:	6a06                	ld	s4,64(sp)
    80003a78:	7ae2                	ld	s5,56(sp)
    80003a7a:	7b42                	ld	s6,48(sp)
    80003a7c:	7ba2                	ld	s7,40(sp)
    80003a7e:	7c02                	ld	s8,32(sp)
    80003a80:	6ce2                	ld	s9,24(sp)
    80003a82:	6d42                	ld	s10,16(sp)
    80003a84:	6da2                	ld	s11,8(sp)
    80003a86:	6165                	addi	sp,sp,112
    80003a88:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a8a:	89d6                	mv	s3,s5
    80003a8c:	bff1                	j	80003a68 <readi+0xce>
    return 0;
    80003a8e:	4501                	li	a0,0
}
    80003a90:	8082                	ret

0000000080003a92 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a92:	457c                	lw	a5,76(a0)
    80003a94:	10d7e863          	bltu	a5,a3,80003ba4 <writei+0x112>
{
    80003a98:	7159                	addi	sp,sp,-112
    80003a9a:	f486                	sd	ra,104(sp)
    80003a9c:	f0a2                	sd	s0,96(sp)
    80003a9e:	eca6                	sd	s1,88(sp)
    80003aa0:	e8ca                	sd	s2,80(sp)
    80003aa2:	e4ce                	sd	s3,72(sp)
    80003aa4:	e0d2                	sd	s4,64(sp)
    80003aa6:	fc56                	sd	s5,56(sp)
    80003aa8:	f85a                	sd	s6,48(sp)
    80003aaa:	f45e                	sd	s7,40(sp)
    80003aac:	f062                	sd	s8,32(sp)
    80003aae:	ec66                	sd	s9,24(sp)
    80003ab0:	e86a                	sd	s10,16(sp)
    80003ab2:	e46e                	sd	s11,8(sp)
    80003ab4:	1880                	addi	s0,sp,112
    80003ab6:	8aaa                	mv	s5,a0
    80003ab8:	8bae                	mv	s7,a1
    80003aba:	8a32                	mv	s4,a2
    80003abc:	8936                	mv	s2,a3
    80003abe:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003ac0:	00e687bb          	addw	a5,a3,a4
    80003ac4:	0ed7e263          	bltu	a5,a3,80003ba8 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003ac8:	00043737          	lui	a4,0x43
    80003acc:	0ef76063          	bltu	a4,a5,80003bac <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ad0:	0c0b0863          	beqz	s6,80003ba0 <writei+0x10e>
    80003ad4:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ad6:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003ada:	5c7d                	li	s8,-1
    80003adc:	a091                	j	80003b20 <writei+0x8e>
    80003ade:	020d1d93          	slli	s11,s10,0x20
    80003ae2:	020ddd93          	srli	s11,s11,0x20
    80003ae6:	05848513          	addi	a0,s1,88
    80003aea:	86ee                	mv	a3,s11
    80003aec:	8652                	mv	a2,s4
    80003aee:	85de                	mv	a1,s7
    80003af0:	953a                	add	a0,a0,a4
    80003af2:	fffff097          	auipc	ra,0xfffff
    80003af6:	9c0080e7          	jalr	-1600(ra) # 800024b2 <either_copyin>
    80003afa:	07850263          	beq	a0,s8,80003b5e <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003afe:	8526                	mv	a0,s1
    80003b00:	00000097          	auipc	ra,0x0
    80003b04:	788080e7          	jalr	1928(ra) # 80004288 <log_write>
    brelse(bp);
    80003b08:	8526                	mv	a0,s1
    80003b0a:	fffff097          	auipc	ra,0xfffff
    80003b0e:	4f4080e7          	jalr	1268(ra) # 80002ffe <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b12:	013d09bb          	addw	s3,s10,s3
    80003b16:	012d093b          	addw	s2,s10,s2
    80003b1a:	9a6e                	add	s4,s4,s11
    80003b1c:	0569f663          	bgeu	s3,s6,80003b68 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003b20:	00a9559b          	srliw	a1,s2,0xa
    80003b24:	8556                	mv	a0,s5
    80003b26:	fffff097          	auipc	ra,0xfffff
    80003b2a:	79c080e7          	jalr	1948(ra) # 800032c2 <bmap>
    80003b2e:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003b32:	c99d                	beqz	a1,80003b68 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003b34:	000aa503          	lw	a0,0(s5)
    80003b38:	fffff097          	auipc	ra,0xfffff
    80003b3c:	396080e7          	jalr	918(ra) # 80002ece <bread>
    80003b40:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b42:	3ff97713          	andi	a4,s2,1023
    80003b46:	40ec87bb          	subw	a5,s9,a4
    80003b4a:	413b06bb          	subw	a3,s6,s3
    80003b4e:	8d3e                	mv	s10,a5
    80003b50:	2781                	sext.w	a5,a5
    80003b52:	0006861b          	sext.w	a2,a3
    80003b56:	f8f674e3          	bgeu	a2,a5,80003ade <writei+0x4c>
    80003b5a:	8d36                	mv	s10,a3
    80003b5c:	b749                	j	80003ade <writei+0x4c>
      brelse(bp);
    80003b5e:	8526                	mv	a0,s1
    80003b60:	fffff097          	auipc	ra,0xfffff
    80003b64:	49e080e7          	jalr	1182(ra) # 80002ffe <brelse>
  }

  if(off > ip->size)
    80003b68:	04caa783          	lw	a5,76(s5)
    80003b6c:	0127f463          	bgeu	a5,s2,80003b74 <writei+0xe2>
    ip->size = off;
    80003b70:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003b74:	8556                	mv	a0,s5
    80003b76:	00000097          	auipc	ra,0x0
    80003b7a:	aa4080e7          	jalr	-1372(ra) # 8000361a <iupdate>

  return tot;
    80003b7e:	0009851b          	sext.w	a0,s3
}
    80003b82:	70a6                	ld	ra,104(sp)
    80003b84:	7406                	ld	s0,96(sp)
    80003b86:	64e6                	ld	s1,88(sp)
    80003b88:	6946                	ld	s2,80(sp)
    80003b8a:	69a6                	ld	s3,72(sp)
    80003b8c:	6a06                	ld	s4,64(sp)
    80003b8e:	7ae2                	ld	s5,56(sp)
    80003b90:	7b42                	ld	s6,48(sp)
    80003b92:	7ba2                	ld	s7,40(sp)
    80003b94:	7c02                	ld	s8,32(sp)
    80003b96:	6ce2                	ld	s9,24(sp)
    80003b98:	6d42                	ld	s10,16(sp)
    80003b9a:	6da2                	ld	s11,8(sp)
    80003b9c:	6165                	addi	sp,sp,112
    80003b9e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ba0:	89da                	mv	s3,s6
    80003ba2:	bfc9                	j	80003b74 <writei+0xe2>
    return -1;
    80003ba4:	557d                	li	a0,-1
}
    80003ba6:	8082                	ret
    return -1;
    80003ba8:	557d                	li	a0,-1
    80003baa:	bfe1                	j	80003b82 <writei+0xf0>
    return -1;
    80003bac:	557d                	li	a0,-1
    80003bae:	bfd1                	j	80003b82 <writei+0xf0>

0000000080003bb0 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003bb0:	1141                	addi	sp,sp,-16
    80003bb2:	e406                	sd	ra,8(sp)
    80003bb4:	e022                	sd	s0,0(sp)
    80003bb6:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003bb8:	4639                	li	a2,14
    80003bba:	ffffd097          	auipc	ra,0xffffd
    80003bbe:	1e8080e7          	jalr	488(ra) # 80000da2 <strncmp>
}
    80003bc2:	60a2                	ld	ra,8(sp)
    80003bc4:	6402                	ld	s0,0(sp)
    80003bc6:	0141                	addi	sp,sp,16
    80003bc8:	8082                	ret

0000000080003bca <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003bca:	7139                	addi	sp,sp,-64
    80003bcc:	fc06                	sd	ra,56(sp)
    80003bce:	f822                	sd	s0,48(sp)
    80003bd0:	f426                	sd	s1,40(sp)
    80003bd2:	f04a                	sd	s2,32(sp)
    80003bd4:	ec4e                	sd	s3,24(sp)
    80003bd6:	e852                	sd	s4,16(sp)
    80003bd8:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003bda:	04451703          	lh	a4,68(a0)
    80003bde:	4785                	li	a5,1
    80003be0:	00f71a63          	bne	a4,a5,80003bf4 <dirlookup+0x2a>
    80003be4:	892a                	mv	s2,a0
    80003be6:	89ae                	mv	s3,a1
    80003be8:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003bea:	457c                	lw	a5,76(a0)
    80003bec:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003bee:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003bf0:	e79d                	bnez	a5,80003c1e <dirlookup+0x54>
    80003bf2:	a8a5                	j	80003c6a <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003bf4:	00005517          	auipc	a0,0x5
    80003bf8:	a7c50513          	addi	a0,a0,-1412 # 80008670 <syscalls+0x1a8>
    80003bfc:	ffffd097          	auipc	ra,0xffffd
    80003c00:	944080e7          	jalr	-1724(ra) # 80000540 <panic>
      panic("dirlookup read");
    80003c04:	00005517          	auipc	a0,0x5
    80003c08:	a8450513          	addi	a0,a0,-1404 # 80008688 <syscalls+0x1c0>
    80003c0c:	ffffd097          	auipc	ra,0xffffd
    80003c10:	934080e7          	jalr	-1740(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c14:	24c1                	addiw	s1,s1,16
    80003c16:	04c92783          	lw	a5,76(s2)
    80003c1a:	04f4f763          	bgeu	s1,a5,80003c68 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003c1e:	4741                	li	a4,16
    80003c20:	86a6                	mv	a3,s1
    80003c22:	fc040613          	addi	a2,s0,-64
    80003c26:	4581                	li	a1,0
    80003c28:	854a                	mv	a0,s2
    80003c2a:	00000097          	auipc	ra,0x0
    80003c2e:	d70080e7          	jalr	-656(ra) # 8000399a <readi>
    80003c32:	47c1                	li	a5,16
    80003c34:	fcf518e3          	bne	a0,a5,80003c04 <dirlookup+0x3a>
    if(de.inum == 0)
    80003c38:	fc045783          	lhu	a5,-64(s0)
    80003c3c:	dfe1                	beqz	a5,80003c14 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003c3e:	fc240593          	addi	a1,s0,-62
    80003c42:	854e                	mv	a0,s3
    80003c44:	00000097          	auipc	ra,0x0
    80003c48:	f6c080e7          	jalr	-148(ra) # 80003bb0 <namecmp>
    80003c4c:	f561                	bnez	a0,80003c14 <dirlookup+0x4a>
      if(poff)
    80003c4e:	000a0463          	beqz	s4,80003c56 <dirlookup+0x8c>
        *poff = off;
    80003c52:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003c56:	fc045583          	lhu	a1,-64(s0)
    80003c5a:	00092503          	lw	a0,0(s2)
    80003c5e:	fffff097          	auipc	ra,0xfffff
    80003c62:	74e080e7          	jalr	1870(ra) # 800033ac <iget>
    80003c66:	a011                	j	80003c6a <dirlookup+0xa0>
  return 0;
    80003c68:	4501                	li	a0,0
}
    80003c6a:	70e2                	ld	ra,56(sp)
    80003c6c:	7442                	ld	s0,48(sp)
    80003c6e:	74a2                	ld	s1,40(sp)
    80003c70:	7902                	ld	s2,32(sp)
    80003c72:	69e2                	ld	s3,24(sp)
    80003c74:	6a42                	ld	s4,16(sp)
    80003c76:	6121                	addi	sp,sp,64
    80003c78:	8082                	ret

0000000080003c7a <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003c7a:	711d                	addi	sp,sp,-96
    80003c7c:	ec86                	sd	ra,88(sp)
    80003c7e:	e8a2                	sd	s0,80(sp)
    80003c80:	e4a6                	sd	s1,72(sp)
    80003c82:	e0ca                	sd	s2,64(sp)
    80003c84:	fc4e                	sd	s3,56(sp)
    80003c86:	f852                	sd	s4,48(sp)
    80003c88:	f456                	sd	s5,40(sp)
    80003c8a:	f05a                	sd	s6,32(sp)
    80003c8c:	ec5e                	sd	s7,24(sp)
    80003c8e:	e862                	sd	s8,16(sp)
    80003c90:	e466                	sd	s9,8(sp)
    80003c92:	e06a                	sd	s10,0(sp)
    80003c94:	1080                	addi	s0,sp,96
    80003c96:	84aa                	mv	s1,a0
    80003c98:	8b2e                	mv	s6,a1
    80003c9a:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003c9c:	00054703          	lbu	a4,0(a0)
    80003ca0:	02f00793          	li	a5,47
    80003ca4:	02f70363          	beq	a4,a5,80003cca <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003ca8:	ffffe097          	auipc	ra,0xffffe
    80003cac:	d04080e7          	jalr	-764(ra) # 800019ac <myproc>
    80003cb0:	15053503          	ld	a0,336(a0)
    80003cb4:	00000097          	auipc	ra,0x0
    80003cb8:	9f4080e7          	jalr	-1548(ra) # 800036a8 <idup>
    80003cbc:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003cbe:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003cc2:	4cb5                	li	s9,13
  len = path - s;
    80003cc4:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003cc6:	4c05                	li	s8,1
    80003cc8:	a87d                	j	80003d86 <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    80003cca:	4585                	li	a1,1
    80003ccc:	4505                	li	a0,1
    80003cce:	fffff097          	auipc	ra,0xfffff
    80003cd2:	6de080e7          	jalr	1758(ra) # 800033ac <iget>
    80003cd6:	8a2a                	mv	s4,a0
    80003cd8:	b7dd                	j	80003cbe <namex+0x44>
      iunlockput(ip);
    80003cda:	8552                	mv	a0,s4
    80003cdc:	00000097          	auipc	ra,0x0
    80003ce0:	c6c080e7          	jalr	-916(ra) # 80003948 <iunlockput>
      return 0;
    80003ce4:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003ce6:	8552                	mv	a0,s4
    80003ce8:	60e6                	ld	ra,88(sp)
    80003cea:	6446                	ld	s0,80(sp)
    80003cec:	64a6                	ld	s1,72(sp)
    80003cee:	6906                	ld	s2,64(sp)
    80003cf0:	79e2                	ld	s3,56(sp)
    80003cf2:	7a42                	ld	s4,48(sp)
    80003cf4:	7aa2                	ld	s5,40(sp)
    80003cf6:	7b02                	ld	s6,32(sp)
    80003cf8:	6be2                	ld	s7,24(sp)
    80003cfa:	6c42                	ld	s8,16(sp)
    80003cfc:	6ca2                	ld	s9,8(sp)
    80003cfe:	6d02                	ld	s10,0(sp)
    80003d00:	6125                	addi	sp,sp,96
    80003d02:	8082                	ret
      iunlock(ip);
    80003d04:	8552                	mv	a0,s4
    80003d06:	00000097          	auipc	ra,0x0
    80003d0a:	aa2080e7          	jalr	-1374(ra) # 800037a8 <iunlock>
      return ip;
    80003d0e:	bfe1                	j	80003ce6 <namex+0x6c>
      iunlockput(ip);
    80003d10:	8552                	mv	a0,s4
    80003d12:	00000097          	auipc	ra,0x0
    80003d16:	c36080e7          	jalr	-970(ra) # 80003948 <iunlockput>
      return 0;
    80003d1a:	8a4e                	mv	s4,s3
    80003d1c:	b7e9                	j	80003ce6 <namex+0x6c>
  len = path - s;
    80003d1e:	40998633          	sub	a2,s3,s1
    80003d22:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80003d26:	09acd863          	bge	s9,s10,80003db6 <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80003d2a:	4639                	li	a2,14
    80003d2c:	85a6                	mv	a1,s1
    80003d2e:	8556                	mv	a0,s5
    80003d30:	ffffd097          	auipc	ra,0xffffd
    80003d34:	ffe080e7          	jalr	-2(ra) # 80000d2e <memmove>
    80003d38:	84ce                	mv	s1,s3
  while(*path == '/')
    80003d3a:	0004c783          	lbu	a5,0(s1)
    80003d3e:	01279763          	bne	a5,s2,80003d4c <namex+0xd2>
    path++;
    80003d42:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d44:	0004c783          	lbu	a5,0(s1)
    80003d48:	ff278de3          	beq	a5,s2,80003d42 <namex+0xc8>
    ilock(ip);
    80003d4c:	8552                	mv	a0,s4
    80003d4e:	00000097          	auipc	ra,0x0
    80003d52:	998080e7          	jalr	-1640(ra) # 800036e6 <ilock>
    if(ip->type != T_DIR){
    80003d56:	044a1783          	lh	a5,68(s4)
    80003d5a:	f98790e3          	bne	a5,s8,80003cda <namex+0x60>
    if(nameiparent && *path == '\0'){
    80003d5e:	000b0563          	beqz	s6,80003d68 <namex+0xee>
    80003d62:	0004c783          	lbu	a5,0(s1)
    80003d66:	dfd9                	beqz	a5,80003d04 <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003d68:	865e                	mv	a2,s7
    80003d6a:	85d6                	mv	a1,s5
    80003d6c:	8552                	mv	a0,s4
    80003d6e:	00000097          	auipc	ra,0x0
    80003d72:	e5c080e7          	jalr	-420(ra) # 80003bca <dirlookup>
    80003d76:	89aa                	mv	s3,a0
    80003d78:	dd41                	beqz	a0,80003d10 <namex+0x96>
    iunlockput(ip);
    80003d7a:	8552                	mv	a0,s4
    80003d7c:	00000097          	auipc	ra,0x0
    80003d80:	bcc080e7          	jalr	-1076(ra) # 80003948 <iunlockput>
    ip = next;
    80003d84:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003d86:	0004c783          	lbu	a5,0(s1)
    80003d8a:	01279763          	bne	a5,s2,80003d98 <namex+0x11e>
    path++;
    80003d8e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d90:	0004c783          	lbu	a5,0(s1)
    80003d94:	ff278de3          	beq	a5,s2,80003d8e <namex+0x114>
  if(*path == 0)
    80003d98:	cb9d                	beqz	a5,80003dce <namex+0x154>
  while(*path != '/' && *path != 0)
    80003d9a:	0004c783          	lbu	a5,0(s1)
    80003d9e:	89a6                	mv	s3,s1
  len = path - s;
    80003da0:	8d5e                	mv	s10,s7
    80003da2:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003da4:	01278963          	beq	a5,s2,80003db6 <namex+0x13c>
    80003da8:	dbbd                	beqz	a5,80003d1e <namex+0xa4>
    path++;
    80003daa:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80003dac:	0009c783          	lbu	a5,0(s3)
    80003db0:	ff279ce3          	bne	a5,s2,80003da8 <namex+0x12e>
    80003db4:	b7ad                	j	80003d1e <namex+0xa4>
    memmove(name, s, len);
    80003db6:	2601                	sext.w	a2,a2
    80003db8:	85a6                	mv	a1,s1
    80003dba:	8556                	mv	a0,s5
    80003dbc:	ffffd097          	auipc	ra,0xffffd
    80003dc0:	f72080e7          	jalr	-142(ra) # 80000d2e <memmove>
    name[len] = 0;
    80003dc4:	9d56                	add	s10,s10,s5
    80003dc6:	000d0023          	sb	zero,0(s10)
    80003dca:	84ce                	mv	s1,s3
    80003dcc:	b7bd                	j	80003d3a <namex+0xc0>
  if(nameiparent){
    80003dce:	f00b0ce3          	beqz	s6,80003ce6 <namex+0x6c>
    iput(ip);
    80003dd2:	8552                	mv	a0,s4
    80003dd4:	00000097          	auipc	ra,0x0
    80003dd8:	acc080e7          	jalr	-1332(ra) # 800038a0 <iput>
    return 0;
    80003ddc:	4a01                	li	s4,0
    80003dde:	b721                	j	80003ce6 <namex+0x6c>

0000000080003de0 <dirlink>:
{
    80003de0:	7139                	addi	sp,sp,-64
    80003de2:	fc06                	sd	ra,56(sp)
    80003de4:	f822                	sd	s0,48(sp)
    80003de6:	f426                	sd	s1,40(sp)
    80003de8:	f04a                	sd	s2,32(sp)
    80003dea:	ec4e                	sd	s3,24(sp)
    80003dec:	e852                	sd	s4,16(sp)
    80003dee:	0080                	addi	s0,sp,64
    80003df0:	892a                	mv	s2,a0
    80003df2:	8a2e                	mv	s4,a1
    80003df4:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003df6:	4601                	li	a2,0
    80003df8:	00000097          	auipc	ra,0x0
    80003dfc:	dd2080e7          	jalr	-558(ra) # 80003bca <dirlookup>
    80003e00:	e93d                	bnez	a0,80003e76 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e02:	04c92483          	lw	s1,76(s2)
    80003e06:	c49d                	beqz	s1,80003e34 <dirlink+0x54>
    80003e08:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e0a:	4741                	li	a4,16
    80003e0c:	86a6                	mv	a3,s1
    80003e0e:	fc040613          	addi	a2,s0,-64
    80003e12:	4581                	li	a1,0
    80003e14:	854a                	mv	a0,s2
    80003e16:	00000097          	auipc	ra,0x0
    80003e1a:	b84080e7          	jalr	-1148(ra) # 8000399a <readi>
    80003e1e:	47c1                	li	a5,16
    80003e20:	06f51163          	bne	a0,a5,80003e82 <dirlink+0xa2>
    if(de.inum == 0)
    80003e24:	fc045783          	lhu	a5,-64(s0)
    80003e28:	c791                	beqz	a5,80003e34 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e2a:	24c1                	addiw	s1,s1,16
    80003e2c:	04c92783          	lw	a5,76(s2)
    80003e30:	fcf4ede3          	bltu	s1,a5,80003e0a <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003e34:	4639                	li	a2,14
    80003e36:	85d2                	mv	a1,s4
    80003e38:	fc240513          	addi	a0,s0,-62
    80003e3c:	ffffd097          	auipc	ra,0xffffd
    80003e40:	fa2080e7          	jalr	-94(ra) # 80000dde <strncpy>
  de.inum = inum;
    80003e44:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e48:	4741                	li	a4,16
    80003e4a:	86a6                	mv	a3,s1
    80003e4c:	fc040613          	addi	a2,s0,-64
    80003e50:	4581                	li	a1,0
    80003e52:	854a                	mv	a0,s2
    80003e54:	00000097          	auipc	ra,0x0
    80003e58:	c3e080e7          	jalr	-962(ra) # 80003a92 <writei>
    80003e5c:	1541                	addi	a0,a0,-16
    80003e5e:	00a03533          	snez	a0,a0
    80003e62:	40a00533          	neg	a0,a0
}
    80003e66:	70e2                	ld	ra,56(sp)
    80003e68:	7442                	ld	s0,48(sp)
    80003e6a:	74a2                	ld	s1,40(sp)
    80003e6c:	7902                	ld	s2,32(sp)
    80003e6e:	69e2                	ld	s3,24(sp)
    80003e70:	6a42                	ld	s4,16(sp)
    80003e72:	6121                	addi	sp,sp,64
    80003e74:	8082                	ret
    iput(ip);
    80003e76:	00000097          	auipc	ra,0x0
    80003e7a:	a2a080e7          	jalr	-1494(ra) # 800038a0 <iput>
    return -1;
    80003e7e:	557d                	li	a0,-1
    80003e80:	b7dd                	j	80003e66 <dirlink+0x86>
      panic("dirlink read");
    80003e82:	00005517          	auipc	a0,0x5
    80003e86:	81650513          	addi	a0,a0,-2026 # 80008698 <syscalls+0x1d0>
    80003e8a:	ffffc097          	auipc	ra,0xffffc
    80003e8e:	6b6080e7          	jalr	1718(ra) # 80000540 <panic>

0000000080003e92 <namei>:

struct inode*
namei(char *path)
{
    80003e92:	1101                	addi	sp,sp,-32
    80003e94:	ec06                	sd	ra,24(sp)
    80003e96:	e822                	sd	s0,16(sp)
    80003e98:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003e9a:	fe040613          	addi	a2,s0,-32
    80003e9e:	4581                	li	a1,0
    80003ea0:	00000097          	auipc	ra,0x0
    80003ea4:	dda080e7          	jalr	-550(ra) # 80003c7a <namex>
}
    80003ea8:	60e2                	ld	ra,24(sp)
    80003eaa:	6442                	ld	s0,16(sp)
    80003eac:	6105                	addi	sp,sp,32
    80003eae:	8082                	ret

0000000080003eb0 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003eb0:	1141                	addi	sp,sp,-16
    80003eb2:	e406                	sd	ra,8(sp)
    80003eb4:	e022                	sd	s0,0(sp)
    80003eb6:	0800                	addi	s0,sp,16
    80003eb8:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003eba:	4585                	li	a1,1
    80003ebc:	00000097          	auipc	ra,0x0
    80003ec0:	dbe080e7          	jalr	-578(ra) # 80003c7a <namex>
}
    80003ec4:	60a2                	ld	ra,8(sp)
    80003ec6:	6402                	ld	s0,0(sp)
    80003ec8:	0141                	addi	sp,sp,16
    80003eca:	8082                	ret

0000000080003ecc <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003ecc:	1101                	addi	sp,sp,-32
    80003ece:	ec06                	sd	ra,24(sp)
    80003ed0:	e822                	sd	s0,16(sp)
    80003ed2:	e426                	sd	s1,8(sp)
    80003ed4:	e04a                	sd	s2,0(sp)
    80003ed6:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003ed8:	0001d917          	auipc	s2,0x1d
    80003edc:	cc890913          	addi	s2,s2,-824 # 80020ba0 <log>
    80003ee0:	01892583          	lw	a1,24(s2)
    80003ee4:	02892503          	lw	a0,40(s2)
    80003ee8:	fffff097          	auipc	ra,0xfffff
    80003eec:	fe6080e7          	jalr	-26(ra) # 80002ece <bread>
    80003ef0:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003ef2:	02c92683          	lw	a3,44(s2)
    80003ef6:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003ef8:	02d05863          	blez	a3,80003f28 <write_head+0x5c>
    80003efc:	0001d797          	auipc	a5,0x1d
    80003f00:	cd478793          	addi	a5,a5,-812 # 80020bd0 <log+0x30>
    80003f04:	05c50713          	addi	a4,a0,92
    80003f08:	36fd                	addiw	a3,a3,-1
    80003f0a:	02069613          	slli	a2,a3,0x20
    80003f0e:	01e65693          	srli	a3,a2,0x1e
    80003f12:	0001d617          	auipc	a2,0x1d
    80003f16:	cc260613          	addi	a2,a2,-830 # 80020bd4 <log+0x34>
    80003f1a:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003f1c:	4390                	lw	a2,0(a5)
    80003f1e:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003f20:	0791                	addi	a5,a5,4
    80003f22:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    80003f24:	fed79ce3          	bne	a5,a3,80003f1c <write_head+0x50>
  }
  bwrite(buf);
    80003f28:	8526                	mv	a0,s1
    80003f2a:	fffff097          	auipc	ra,0xfffff
    80003f2e:	096080e7          	jalr	150(ra) # 80002fc0 <bwrite>
  brelse(buf);
    80003f32:	8526                	mv	a0,s1
    80003f34:	fffff097          	auipc	ra,0xfffff
    80003f38:	0ca080e7          	jalr	202(ra) # 80002ffe <brelse>
}
    80003f3c:	60e2                	ld	ra,24(sp)
    80003f3e:	6442                	ld	s0,16(sp)
    80003f40:	64a2                	ld	s1,8(sp)
    80003f42:	6902                	ld	s2,0(sp)
    80003f44:	6105                	addi	sp,sp,32
    80003f46:	8082                	ret

0000000080003f48 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f48:	0001d797          	auipc	a5,0x1d
    80003f4c:	c847a783          	lw	a5,-892(a5) # 80020bcc <log+0x2c>
    80003f50:	0af05d63          	blez	a5,8000400a <install_trans+0xc2>
{
    80003f54:	7139                	addi	sp,sp,-64
    80003f56:	fc06                	sd	ra,56(sp)
    80003f58:	f822                	sd	s0,48(sp)
    80003f5a:	f426                	sd	s1,40(sp)
    80003f5c:	f04a                	sd	s2,32(sp)
    80003f5e:	ec4e                	sd	s3,24(sp)
    80003f60:	e852                	sd	s4,16(sp)
    80003f62:	e456                	sd	s5,8(sp)
    80003f64:	e05a                	sd	s6,0(sp)
    80003f66:	0080                	addi	s0,sp,64
    80003f68:	8b2a                	mv	s6,a0
    80003f6a:	0001da97          	auipc	s5,0x1d
    80003f6e:	c66a8a93          	addi	s5,s5,-922 # 80020bd0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f72:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003f74:	0001d997          	auipc	s3,0x1d
    80003f78:	c2c98993          	addi	s3,s3,-980 # 80020ba0 <log>
    80003f7c:	a00d                	j	80003f9e <install_trans+0x56>
    brelse(lbuf);
    80003f7e:	854a                	mv	a0,s2
    80003f80:	fffff097          	auipc	ra,0xfffff
    80003f84:	07e080e7          	jalr	126(ra) # 80002ffe <brelse>
    brelse(dbuf);
    80003f88:	8526                	mv	a0,s1
    80003f8a:	fffff097          	auipc	ra,0xfffff
    80003f8e:	074080e7          	jalr	116(ra) # 80002ffe <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f92:	2a05                	addiw	s4,s4,1
    80003f94:	0a91                	addi	s5,s5,4
    80003f96:	02c9a783          	lw	a5,44(s3)
    80003f9a:	04fa5e63          	bge	s4,a5,80003ff6 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003f9e:	0189a583          	lw	a1,24(s3)
    80003fa2:	014585bb          	addw	a1,a1,s4
    80003fa6:	2585                	addiw	a1,a1,1
    80003fa8:	0289a503          	lw	a0,40(s3)
    80003fac:	fffff097          	auipc	ra,0xfffff
    80003fb0:	f22080e7          	jalr	-222(ra) # 80002ece <bread>
    80003fb4:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003fb6:	000aa583          	lw	a1,0(s5)
    80003fba:	0289a503          	lw	a0,40(s3)
    80003fbe:	fffff097          	auipc	ra,0xfffff
    80003fc2:	f10080e7          	jalr	-240(ra) # 80002ece <bread>
    80003fc6:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003fc8:	40000613          	li	a2,1024
    80003fcc:	05890593          	addi	a1,s2,88
    80003fd0:	05850513          	addi	a0,a0,88
    80003fd4:	ffffd097          	auipc	ra,0xffffd
    80003fd8:	d5a080e7          	jalr	-678(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    80003fdc:	8526                	mv	a0,s1
    80003fde:	fffff097          	auipc	ra,0xfffff
    80003fe2:	fe2080e7          	jalr	-30(ra) # 80002fc0 <bwrite>
    if(recovering == 0)
    80003fe6:	f80b1ce3          	bnez	s6,80003f7e <install_trans+0x36>
      bunpin(dbuf);
    80003fea:	8526                	mv	a0,s1
    80003fec:	fffff097          	auipc	ra,0xfffff
    80003ff0:	0ec080e7          	jalr	236(ra) # 800030d8 <bunpin>
    80003ff4:	b769                	j	80003f7e <install_trans+0x36>
}
    80003ff6:	70e2                	ld	ra,56(sp)
    80003ff8:	7442                	ld	s0,48(sp)
    80003ffa:	74a2                	ld	s1,40(sp)
    80003ffc:	7902                	ld	s2,32(sp)
    80003ffe:	69e2                	ld	s3,24(sp)
    80004000:	6a42                	ld	s4,16(sp)
    80004002:	6aa2                	ld	s5,8(sp)
    80004004:	6b02                	ld	s6,0(sp)
    80004006:	6121                	addi	sp,sp,64
    80004008:	8082                	ret
    8000400a:	8082                	ret

000000008000400c <initlog>:
{
    8000400c:	7179                	addi	sp,sp,-48
    8000400e:	f406                	sd	ra,40(sp)
    80004010:	f022                	sd	s0,32(sp)
    80004012:	ec26                	sd	s1,24(sp)
    80004014:	e84a                	sd	s2,16(sp)
    80004016:	e44e                	sd	s3,8(sp)
    80004018:	1800                	addi	s0,sp,48
    8000401a:	892a                	mv	s2,a0
    8000401c:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000401e:	0001d497          	auipc	s1,0x1d
    80004022:	b8248493          	addi	s1,s1,-1150 # 80020ba0 <log>
    80004026:	00004597          	auipc	a1,0x4
    8000402a:	68258593          	addi	a1,a1,1666 # 800086a8 <syscalls+0x1e0>
    8000402e:	8526                	mv	a0,s1
    80004030:	ffffd097          	auipc	ra,0xffffd
    80004034:	b16080e7          	jalr	-1258(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    80004038:	0149a583          	lw	a1,20(s3)
    8000403c:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000403e:	0109a783          	lw	a5,16(s3)
    80004042:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004044:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004048:	854a                	mv	a0,s2
    8000404a:	fffff097          	auipc	ra,0xfffff
    8000404e:	e84080e7          	jalr	-380(ra) # 80002ece <bread>
  log.lh.n = lh->n;
    80004052:	4d34                	lw	a3,88(a0)
    80004054:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004056:	02d05663          	blez	a3,80004082 <initlog+0x76>
    8000405a:	05c50793          	addi	a5,a0,92
    8000405e:	0001d717          	auipc	a4,0x1d
    80004062:	b7270713          	addi	a4,a4,-1166 # 80020bd0 <log+0x30>
    80004066:	36fd                	addiw	a3,a3,-1
    80004068:	02069613          	slli	a2,a3,0x20
    8000406c:	01e65693          	srli	a3,a2,0x1e
    80004070:	06050613          	addi	a2,a0,96
    80004074:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004076:	4390                	lw	a2,0(a5)
    80004078:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000407a:	0791                	addi	a5,a5,4
    8000407c:	0711                	addi	a4,a4,4
    8000407e:	fed79ce3          	bne	a5,a3,80004076 <initlog+0x6a>
  brelse(buf);
    80004082:	fffff097          	auipc	ra,0xfffff
    80004086:	f7c080e7          	jalr	-132(ra) # 80002ffe <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000408a:	4505                	li	a0,1
    8000408c:	00000097          	auipc	ra,0x0
    80004090:	ebc080e7          	jalr	-324(ra) # 80003f48 <install_trans>
  log.lh.n = 0;
    80004094:	0001d797          	auipc	a5,0x1d
    80004098:	b207ac23          	sw	zero,-1224(a5) # 80020bcc <log+0x2c>
  write_head(); // clear the log
    8000409c:	00000097          	auipc	ra,0x0
    800040a0:	e30080e7          	jalr	-464(ra) # 80003ecc <write_head>
}
    800040a4:	70a2                	ld	ra,40(sp)
    800040a6:	7402                	ld	s0,32(sp)
    800040a8:	64e2                	ld	s1,24(sp)
    800040aa:	6942                	ld	s2,16(sp)
    800040ac:	69a2                	ld	s3,8(sp)
    800040ae:	6145                	addi	sp,sp,48
    800040b0:	8082                	ret

00000000800040b2 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800040b2:	1101                	addi	sp,sp,-32
    800040b4:	ec06                	sd	ra,24(sp)
    800040b6:	e822                	sd	s0,16(sp)
    800040b8:	e426                	sd	s1,8(sp)
    800040ba:	e04a                	sd	s2,0(sp)
    800040bc:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800040be:	0001d517          	auipc	a0,0x1d
    800040c2:	ae250513          	addi	a0,a0,-1310 # 80020ba0 <log>
    800040c6:	ffffd097          	auipc	ra,0xffffd
    800040ca:	b10080e7          	jalr	-1264(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    800040ce:	0001d497          	auipc	s1,0x1d
    800040d2:	ad248493          	addi	s1,s1,-1326 # 80020ba0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800040d6:	4979                	li	s2,30
    800040d8:	a039                	j	800040e6 <begin_op+0x34>
      sleep(&log, &log.lock);
    800040da:	85a6                	mv	a1,s1
    800040dc:	8526                	mv	a0,s1
    800040de:	ffffe097          	auipc	ra,0xffffe
    800040e2:	f76080e7          	jalr	-138(ra) # 80002054 <sleep>
    if(log.committing){
    800040e6:	50dc                	lw	a5,36(s1)
    800040e8:	fbed                	bnez	a5,800040da <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800040ea:	5098                	lw	a4,32(s1)
    800040ec:	2705                	addiw	a4,a4,1
    800040ee:	0007069b          	sext.w	a3,a4
    800040f2:	0027179b          	slliw	a5,a4,0x2
    800040f6:	9fb9                	addw	a5,a5,a4
    800040f8:	0017979b          	slliw	a5,a5,0x1
    800040fc:	54d8                	lw	a4,44(s1)
    800040fe:	9fb9                	addw	a5,a5,a4
    80004100:	00f95963          	bge	s2,a5,80004112 <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004104:	85a6                	mv	a1,s1
    80004106:	8526                	mv	a0,s1
    80004108:	ffffe097          	auipc	ra,0xffffe
    8000410c:	f4c080e7          	jalr	-180(ra) # 80002054 <sleep>
    80004110:	bfd9                	j	800040e6 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004112:	0001d517          	auipc	a0,0x1d
    80004116:	a8e50513          	addi	a0,a0,-1394 # 80020ba0 <log>
    8000411a:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000411c:	ffffd097          	auipc	ra,0xffffd
    80004120:	b6e080e7          	jalr	-1170(ra) # 80000c8a <release>
      break;
    }
  }
}
    80004124:	60e2                	ld	ra,24(sp)
    80004126:	6442                	ld	s0,16(sp)
    80004128:	64a2                	ld	s1,8(sp)
    8000412a:	6902                	ld	s2,0(sp)
    8000412c:	6105                	addi	sp,sp,32
    8000412e:	8082                	ret

0000000080004130 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004130:	7139                	addi	sp,sp,-64
    80004132:	fc06                	sd	ra,56(sp)
    80004134:	f822                	sd	s0,48(sp)
    80004136:	f426                	sd	s1,40(sp)
    80004138:	f04a                	sd	s2,32(sp)
    8000413a:	ec4e                	sd	s3,24(sp)
    8000413c:	e852                	sd	s4,16(sp)
    8000413e:	e456                	sd	s5,8(sp)
    80004140:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004142:	0001d497          	auipc	s1,0x1d
    80004146:	a5e48493          	addi	s1,s1,-1442 # 80020ba0 <log>
    8000414a:	8526                	mv	a0,s1
    8000414c:	ffffd097          	auipc	ra,0xffffd
    80004150:	a8a080e7          	jalr	-1398(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    80004154:	509c                	lw	a5,32(s1)
    80004156:	37fd                	addiw	a5,a5,-1
    80004158:	0007891b          	sext.w	s2,a5
    8000415c:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000415e:	50dc                	lw	a5,36(s1)
    80004160:	e7b9                	bnez	a5,800041ae <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004162:	04091e63          	bnez	s2,800041be <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004166:	0001d497          	auipc	s1,0x1d
    8000416a:	a3a48493          	addi	s1,s1,-1478 # 80020ba0 <log>
    8000416e:	4785                	li	a5,1
    80004170:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004172:	8526                	mv	a0,s1
    80004174:	ffffd097          	auipc	ra,0xffffd
    80004178:	b16080e7          	jalr	-1258(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000417c:	54dc                	lw	a5,44(s1)
    8000417e:	06f04763          	bgtz	a5,800041ec <end_op+0xbc>
    acquire(&log.lock);
    80004182:	0001d497          	auipc	s1,0x1d
    80004186:	a1e48493          	addi	s1,s1,-1506 # 80020ba0 <log>
    8000418a:	8526                	mv	a0,s1
    8000418c:	ffffd097          	auipc	ra,0xffffd
    80004190:	a4a080e7          	jalr	-1462(ra) # 80000bd6 <acquire>
    log.committing = 0;
    80004194:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004198:	8526                	mv	a0,s1
    8000419a:	ffffe097          	auipc	ra,0xffffe
    8000419e:	f1e080e7          	jalr	-226(ra) # 800020b8 <wakeup>
    release(&log.lock);
    800041a2:	8526                	mv	a0,s1
    800041a4:	ffffd097          	auipc	ra,0xffffd
    800041a8:	ae6080e7          	jalr	-1306(ra) # 80000c8a <release>
}
    800041ac:	a03d                	j	800041da <end_op+0xaa>
    panic("log.committing");
    800041ae:	00004517          	auipc	a0,0x4
    800041b2:	50250513          	addi	a0,a0,1282 # 800086b0 <syscalls+0x1e8>
    800041b6:	ffffc097          	auipc	ra,0xffffc
    800041ba:	38a080e7          	jalr	906(ra) # 80000540 <panic>
    wakeup(&log);
    800041be:	0001d497          	auipc	s1,0x1d
    800041c2:	9e248493          	addi	s1,s1,-1566 # 80020ba0 <log>
    800041c6:	8526                	mv	a0,s1
    800041c8:	ffffe097          	auipc	ra,0xffffe
    800041cc:	ef0080e7          	jalr	-272(ra) # 800020b8 <wakeup>
  release(&log.lock);
    800041d0:	8526                	mv	a0,s1
    800041d2:	ffffd097          	auipc	ra,0xffffd
    800041d6:	ab8080e7          	jalr	-1352(ra) # 80000c8a <release>
}
    800041da:	70e2                	ld	ra,56(sp)
    800041dc:	7442                	ld	s0,48(sp)
    800041de:	74a2                	ld	s1,40(sp)
    800041e0:	7902                	ld	s2,32(sp)
    800041e2:	69e2                	ld	s3,24(sp)
    800041e4:	6a42                	ld	s4,16(sp)
    800041e6:	6aa2                	ld	s5,8(sp)
    800041e8:	6121                	addi	sp,sp,64
    800041ea:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800041ec:	0001da97          	auipc	s5,0x1d
    800041f0:	9e4a8a93          	addi	s5,s5,-1564 # 80020bd0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800041f4:	0001da17          	auipc	s4,0x1d
    800041f8:	9aca0a13          	addi	s4,s4,-1620 # 80020ba0 <log>
    800041fc:	018a2583          	lw	a1,24(s4)
    80004200:	012585bb          	addw	a1,a1,s2
    80004204:	2585                	addiw	a1,a1,1
    80004206:	028a2503          	lw	a0,40(s4)
    8000420a:	fffff097          	auipc	ra,0xfffff
    8000420e:	cc4080e7          	jalr	-828(ra) # 80002ece <bread>
    80004212:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004214:	000aa583          	lw	a1,0(s5)
    80004218:	028a2503          	lw	a0,40(s4)
    8000421c:	fffff097          	auipc	ra,0xfffff
    80004220:	cb2080e7          	jalr	-846(ra) # 80002ece <bread>
    80004224:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004226:	40000613          	li	a2,1024
    8000422a:	05850593          	addi	a1,a0,88
    8000422e:	05848513          	addi	a0,s1,88
    80004232:	ffffd097          	auipc	ra,0xffffd
    80004236:	afc080e7          	jalr	-1284(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    8000423a:	8526                	mv	a0,s1
    8000423c:	fffff097          	auipc	ra,0xfffff
    80004240:	d84080e7          	jalr	-636(ra) # 80002fc0 <bwrite>
    brelse(from);
    80004244:	854e                	mv	a0,s3
    80004246:	fffff097          	auipc	ra,0xfffff
    8000424a:	db8080e7          	jalr	-584(ra) # 80002ffe <brelse>
    brelse(to);
    8000424e:	8526                	mv	a0,s1
    80004250:	fffff097          	auipc	ra,0xfffff
    80004254:	dae080e7          	jalr	-594(ra) # 80002ffe <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004258:	2905                	addiw	s2,s2,1
    8000425a:	0a91                	addi	s5,s5,4
    8000425c:	02ca2783          	lw	a5,44(s4)
    80004260:	f8f94ee3          	blt	s2,a5,800041fc <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004264:	00000097          	auipc	ra,0x0
    80004268:	c68080e7          	jalr	-920(ra) # 80003ecc <write_head>
    install_trans(0); // Now install writes to home locations
    8000426c:	4501                	li	a0,0
    8000426e:	00000097          	auipc	ra,0x0
    80004272:	cda080e7          	jalr	-806(ra) # 80003f48 <install_trans>
    log.lh.n = 0;
    80004276:	0001d797          	auipc	a5,0x1d
    8000427a:	9407ab23          	sw	zero,-1706(a5) # 80020bcc <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000427e:	00000097          	auipc	ra,0x0
    80004282:	c4e080e7          	jalr	-946(ra) # 80003ecc <write_head>
    80004286:	bdf5                	j	80004182 <end_op+0x52>

0000000080004288 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004288:	1101                	addi	sp,sp,-32
    8000428a:	ec06                	sd	ra,24(sp)
    8000428c:	e822                	sd	s0,16(sp)
    8000428e:	e426                	sd	s1,8(sp)
    80004290:	e04a                	sd	s2,0(sp)
    80004292:	1000                	addi	s0,sp,32
    80004294:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004296:	0001d917          	auipc	s2,0x1d
    8000429a:	90a90913          	addi	s2,s2,-1782 # 80020ba0 <log>
    8000429e:	854a                	mv	a0,s2
    800042a0:	ffffd097          	auipc	ra,0xffffd
    800042a4:	936080e7          	jalr	-1738(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800042a8:	02c92603          	lw	a2,44(s2)
    800042ac:	47f5                	li	a5,29
    800042ae:	06c7c563          	blt	a5,a2,80004318 <log_write+0x90>
    800042b2:	0001d797          	auipc	a5,0x1d
    800042b6:	90a7a783          	lw	a5,-1782(a5) # 80020bbc <log+0x1c>
    800042ba:	37fd                	addiw	a5,a5,-1
    800042bc:	04f65e63          	bge	a2,a5,80004318 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800042c0:	0001d797          	auipc	a5,0x1d
    800042c4:	9007a783          	lw	a5,-1792(a5) # 80020bc0 <log+0x20>
    800042c8:	06f05063          	blez	a5,80004328 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800042cc:	4781                	li	a5,0
    800042ce:	06c05563          	blez	a2,80004338 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800042d2:	44cc                	lw	a1,12(s1)
    800042d4:	0001d717          	auipc	a4,0x1d
    800042d8:	8fc70713          	addi	a4,a4,-1796 # 80020bd0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800042dc:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800042de:	4314                	lw	a3,0(a4)
    800042e0:	04b68c63          	beq	a3,a1,80004338 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800042e4:	2785                	addiw	a5,a5,1
    800042e6:	0711                	addi	a4,a4,4
    800042e8:	fef61be3          	bne	a2,a5,800042de <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800042ec:	0621                	addi	a2,a2,8
    800042ee:	060a                	slli	a2,a2,0x2
    800042f0:	0001d797          	auipc	a5,0x1d
    800042f4:	8b078793          	addi	a5,a5,-1872 # 80020ba0 <log>
    800042f8:	97b2                	add	a5,a5,a2
    800042fa:	44d8                	lw	a4,12(s1)
    800042fc:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800042fe:	8526                	mv	a0,s1
    80004300:	fffff097          	auipc	ra,0xfffff
    80004304:	d9c080e7          	jalr	-612(ra) # 8000309c <bpin>
    log.lh.n++;
    80004308:	0001d717          	auipc	a4,0x1d
    8000430c:	89870713          	addi	a4,a4,-1896 # 80020ba0 <log>
    80004310:	575c                	lw	a5,44(a4)
    80004312:	2785                	addiw	a5,a5,1
    80004314:	d75c                	sw	a5,44(a4)
    80004316:	a82d                	j	80004350 <log_write+0xc8>
    panic("too big a transaction");
    80004318:	00004517          	auipc	a0,0x4
    8000431c:	3a850513          	addi	a0,a0,936 # 800086c0 <syscalls+0x1f8>
    80004320:	ffffc097          	auipc	ra,0xffffc
    80004324:	220080e7          	jalr	544(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    80004328:	00004517          	auipc	a0,0x4
    8000432c:	3b050513          	addi	a0,a0,944 # 800086d8 <syscalls+0x210>
    80004330:	ffffc097          	auipc	ra,0xffffc
    80004334:	210080e7          	jalr	528(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    80004338:	00878693          	addi	a3,a5,8
    8000433c:	068a                	slli	a3,a3,0x2
    8000433e:	0001d717          	auipc	a4,0x1d
    80004342:	86270713          	addi	a4,a4,-1950 # 80020ba0 <log>
    80004346:	9736                	add	a4,a4,a3
    80004348:	44d4                	lw	a3,12(s1)
    8000434a:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000434c:	faf609e3          	beq	a2,a5,800042fe <log_write+0x76>
  }
  release(&log.lock);
    80004350:	0001d517          	auipc	a0,0x1d
    80004354:	85050513          	addi	a0,a0,-1968 # 80020ba0 <log>
    80004358:	ffffd097          	auipc	ra,0xffffd
    8000435c:	932080e7          	jalr	-1742(ra) # 80000c8a <release>
}
    80004360:	60e2                	ld	ra,24(sp)
    80004362:	6442                	ld	s0,16(sp)
    80004364:	64a2                	ld	s1,8(sp)
    80004366:	6902                	ld	s2,0(sp)
    80004368:	6105                	addi	sp,sp,32
    8000436a:	8082                	ret

000000008000436c <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000436c:	1101                	addi	sp,sp,-32
    8000436e:	ec06                	sd	ra,24(sp)
    80004370:	e822                	sd	s0,16(sp)
    80004372:	e426                	sd	s1,8(sp)
    80004374:	e04a                	sd	s2,0(sp)
    80004376:	1000                	addi	s0,sp,32
    80004378:	84aa                	mv	s1,a0
    8000437a:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000437c:	00004597          	auipc	a1,0x4
    80004380:	37c58593          	addi	a1,a1,892 # 800086f8 <syscalls+0x230>
    80004384:	0521                	addi	a0,a0,8
    80004386:	ffffc097          	auipc	ra,0xffffc
    8000438a:	7c0080e7          	jalr	1984(ra) # 80000b46 <initlock>
  lk->name = name;
    8000438e:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004392:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004396:	0204a423          	sw	zero,40(s1)
}
    8000439a:	60e2                	ld	ra,24(sp)
    8000439c:	6442                	ld	s0,16(sp)
    8000439e:	64a2                	ld	s1,8(sp)
    800043a0:	6902                	ld	s2,0(sp)
    800043a2:	6105                	addi	sp,sp,32
    800043a4:	8082                	ret

00000000800043a6 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800043a6:	1101                	addi	sp,sp,-32
    800043a8:	ec06                	sd	ra,24(sp)
    800043aa:	e822                	sd	s0,16(sp)
    800043ac:	e426                	sd	s1,8(sp)
    800043ae:	e04a                	sd	s2,0(sp)
    800043b0:	1000                	addi	s0,sp,32
    800043b2:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800043b4:	00850913          	addi	s2,a0,8
    800043b8:	854a                	mv	a0,s2
    800043ba:	ffffd097          	auipc	ra,0xffffd
    800043be:	81c080e7          	jalr	-2020(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    800043c2:	409c                	lw	a5,0(s1)
    800043c4:	cb89                	beqz	a5,800043d6 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800043c6:	85ca                	mv	a1,s2
    800043c8:	8526                	mv	a0,s1
    800043ca:	ffffe097          	auipc	ra,0xffffe
    800043ce:	c8a080e7          	jalr	-886(ra) # 80002054 <sleep>
  while (lk->locked) {
    800043d2:	409c                	lw	a5,0(s1)
    800043d4:	fbed                	bnez	a5,800043c6 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800043d6:	4785                	li	a5,1
    800043d8:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800043da:	ffffd097          	auipc	ra,0xffffd
    800043de:	5d2080e7          	jalr	1490(ra) # 800019ac <myproc>
    800043e2:	591c                	lw	a5,48(a0)
    800043e4:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800043e6:	854a                	mv	a0,s2
    800043e8:	ffffd097          	auipc	ra,0xffffd
    800043ec:	8a2080e7          	jalr	-1886(ra) # 80000c8a <release>
}
    800043f0:	60e2                	ld	ra,24(sp)
    800043f2:	6442                	ld	s0,16(sp)
    800043f4:	64a2                	ld	s1,8(sp)
    800043f6:	6902                	ld	s2,0(sp)
    800043f8:	6105                	addi	sp,sp,32
    800043fa:	8082                	ret

00000000800043fc <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800043fc:	1101                	addi	sp,sp,-32
    800043fe:	ec06                	sd	ra,24(sp)
    80004400:	e822                	sd	s0,16(sp)
    80004402:	e426                	sd	s1,8(sp)
    80004404:	e04a                	sd	s2,0(sp)
    80004406:	1000                	addi	s0,sp,32
    80004408:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000440a:	00850913          	addi	s2,a0,8
    8000440e:	854a                	mv	a0,s2
    80004410:	ffffc097          	auipc	ra,0xffffc
    80004414:	7c6080e7          	jalr	1990(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    80004418:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000441c:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004420:	8526                	mv	a0,s1
    80004422:	ffffe097          	auipc	ra,0xffffe
    80004426:	c96080e7          	jalr	-874(ra) # 800020b8 <wakeup>
  release(&lk->lk);
    8000442a:	854a                	mv	a0,s2
    8000442c:	ffffd097          	auipc	ra,0xffffd
    80004430:	85e080e7          	jalr	-1954(ra) # 80000c8a <release>
}
    80004434:	60e2                	ld	ra,24(sp)
    80004436:	6442                	ld	s0,16(sp)
    80004438:	64a2                	ld	s1,8(sp)
    8000443a:	6902                	ld	s2,0(sp)
    8000443c:	6105                	addi	sp,sp,32
    8000443e:	8082                	ret

0000000080004440 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004440:	7179                	addi	sp,sp,-48
    80004442:	f406                	sd	ra,40(sp)
    80004444:	f022                	sd	s0,32(sp)
    80004446:	ec26                	sd	s1,24(sp)
    80004448:	e84a                	sd	s2,16(sp)
    8000444a:	e44e                	sd	s3,8(sp)
    8000444c:	1800                	addi	s0,sp,48
    8000444e:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004450:	00850913          	addi	s2,a0,8
    80004454:	854a                	mv	a0,s2
    80004456:	ffffc097          	auipc	ra,0xffffc
    8000445a:	780080e7          	jalr	1920(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000445e:	409c                	lw	a5,0(s1)
    80004460:	ef99                	bnez	a5,8000447e <holdingsleep+0x3e>
    80004462:	4481                	li	s1,0
  release(&lk->lk);
    80004464:	854a                	mv	a0,s2
    80004466:	ffffd097          	auipc	ra,0xffffd
    8000446a:	824080e7          	jalr	-2012(ra) # 80000c8a <release>
  return r;
}
    8000446e:	8526                	mv	a0,s1
    80004470:	70a2                	ld	ra,40(sp)
    80004472:	7402                	ld	s0,32(sp)
    80004474:	64e2                	ld	s1,24(sp)
    80004476:	6942                	ld	s2,16(sp)
    80004478:	69a2                	ld	s3,8(sp)
    8000447a:	6145                	addi	sp,sp,48
    8000447c:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000447e:	0284a983          	lw	s3,40(s1)
    80004482:	ffffd097          	auipc	ra,0xffffd
    80004486:	52a080e7          	jalr	1322(ra) # 800019ac <myproc>
    8000448a:	5904                	lw	s1,48(a0)
    8000448c:	413484b3          	sub	s1,s1,s3
    80004490:	0014b493          	seqz	s1,s1
    80004494:	bfc1                	j	80004464 <holdingsleep+0x24>

0000000080004496 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004496:	1141                	addi	sp,sp,-16
    80004498:	e406                	sd	ra,8(sp)
    8000449a:	e022                	sd	s0,0(sp)
    8000449c:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000449e:	00004597          	auipc	a1,0x4
    800044a2:	26a58593          	addi	a1,a1,618 # 80008708 <syscalls+0x240>
    800044a6:	0001d517          	auipc	a0,0x1d
    800044aa:	84250513          	addi	a0,a0,-1982 # 80020ce8 <ftable>
    800044ae:	ffffc097          	auipc	ra,0xffffc
    800044b2:	698080e7          	jalr	1688(ra) # 80000b46 <initlock>
}
    800044b6:	60a2                	ld	ra,8(sp)
    800044b8:	6402                	ld	s0,0(sp)
    800044ba:	0141                	addi	sp,sp,16
    800044bc:	8082                	ret

00000000800044be <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800044be:	1101                	addi	sp,sp,-32
    800044c0:	ec06                	sd	ra,24(sp)
    800044c2:	e822                	sd	s0,16(sp)
    800044c4:	e426                	sd	s1,8(sp)
    800044c6:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800044c8:	0001d517          	auipc	a0,0x1d
    800044cc:	82050513          	addi	a0,a0,-2016 # 80020ce8 <ftable>
    800044d0:	ffffc097          	auipc	ra,0xffffc
    800044d4:	706080e7          	jalr	1798(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800044d8:	0001d497          	auipc	s1,0x1d
    800044dc:	82848493          	addi	s1,s1,-2008 # 80020d00 <ftable+0x18>
    800044e0:	0001d717          	auipc	a4,0x1d
    800044e4:	7c070713          	addi	a4,a4,1984 # 80021ca0 <disk>
    if(f->ref == 0){
    800044e8:	40dc                	lw	a5,4(s1)
    800044ea:	cf99                	beqz	a5,80004508 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800044ec:	02848493          	addi	s1,s1,40
    800044f0:	fee49ce3          	bne	s1,a4,800044e8 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800044f4:	0001c517          	auipc	a0,0x1c
    800044f8:	7f450513          	addi	a0,a0,2036 # 80020ce8 <ftable>
    800044fc:	ffffc097          	auipc	ra,0xffffc
    80004500:	78e080e7          	jalr	1934(ra) # 80000c8a <release>
  return 0;
    80004504:	4481                	li	s1,0
    80004506:	a819                	j	8000451c <filealloc+0x5e>
      f->ref = 1;
    80004508:	4785                	li	a5,1
    8000450a:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000450c:	0001c517          	auipc	a0,0x1c
    80004510:	7dc50513          	addi	a0,a0,2012 # 80020ce8 <ftable>
    80004514:	ffffc097          	auipc	ra,0xffffc
    80004518:	776080e7          	jalr	1910(ra) # 80000c8a <release>
}
    8000451c:	8526                	mv	a0,s1
    8000451e:	60e2                	ld	ra,24(sp)
    80004520:	6442                	ld	s0,16(sp)
    80004522:	64a2                	ld	s1,8(sp)
    80004524:	6105                	addi	sp,sp,32
    80004526:	8082                	ret

0000000080004528 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004528:	1101                	addi	sp,sp,-32
    8000452a:	ec06                	sd	ra,24(sp)
    8000452c:	e822                	sd	s0,16(sp)
    8000452e:	e426                	sd	s1,8(sp)
    80004530:	1000                	addi	s0,sp,32
    80004532:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004534:	0001c517          	auipc	a0,0x1c
    80004538:	7b450513          	addi	a0,a0,1972 # 80020ce8 <ftable>
    8000453c:	ffffc097          	auipc	ra,0xffffc
    80004540:	69a080e7          	jalr	1690(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004544:	40dc                	lw	a5,4(s1)
    80004546:	02f05263          	blez	a5,8000456a <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000454a:	2785                	addiw	a5,a5,1
    8000454c:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000454e:	0001c517          	auipc	a0,0x1c
    80004552:	79a50513          	addi	a0,a0,1946 # 80020ce8 <ftable>
    80004556:	ffffc097          	auipc	ra,0xffffc
    8000455a:	734080e7          	jalr	1844(ra) # 80000c8a <release>
  return f;
}
    8000455e:	8526                	mv	a0,s1
    80004560:	60e2                	ld	ra,24(sp)
    80004562:	6442                	ld	s0,16(sp)
    80004564:	64a2                	ld	s1,8(sp)
    80004566:	6105                	addi	sp,sp,32
    80004568:	8082                	ret
    panic("filedup");
    8000456a:	00004517          	auipc	a0,0x4
    8000456e:	1a650513          	addi	a0,a0,422 # 80008710 <syscalls+0x248>
    80004572:	ffffc097          	auipc	ra,0xffffc
    80004576:	fce080e7          	jalr	-50(ra) # 80000540 <panic>

000000008000457a <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000457a:	7139                	addi	sp,sp,-64
    8000457c:	fc06                	sd	ra,56(sp)
    8000457e:	f822                	sd	s0,48(sp)
    80004580:	f426                	sd	s1,40(sp)
    80004582:	f04a                	sd	s2,32(sp)
    80004584:	ec4e                	sd	s3,24(sp)
    80004586:	e852                	sd	s4,16(sp)
    80004588:	e456                	sd	s5,8(sp)
    8000458a:	0080                	addi	s0,sp,64
    8000458c:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000458e:	0001c517          	auipc	a0,0x1c
    80004592:	75a50513          	addi	a0,a0,1882 # 80020ce8 <ftable>
    80004596:	ffffc097          	auipc	ra,0xffffc
    8000459a:	640080e7          	jalr	1600(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    8000459e:	40dc                	lw	a5,4(s1)
    800045a0:	06f05163          	blez	a5,80004602 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800045a4:	37fd                	addiw	a5,a5,-1
    800045a6:	0007871b          	sext.w	a4,a5
    800045aa:	c0dc                	sw	a5,4(s1)
    800045ac:	06e04363          	bgtz	a4,80004612 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800045b0:	0004a903          	lw	s2,0(s1)
    800045b4:	0094ca83          	lbu	s5,9(s1)
    800045b8:	0104ba03          	ld	s4,16(s1)
    800045bc:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800045c0:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800045c4:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800045c8:	0001c517          	auipc	a0,0x1c
    800045cc:	72050513          	addi	a0,a0,1824 # 80020ce8 <ftable>
    800045d0:	ffffc097          	auipc	ra,0xffffc
    800045d4:	6ba080e7          	jalr	1722(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    800045d8:	4785                	li	a5,1
    800045da:	04f90d63          	beq	s2,a5,80004634 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800045de:	3979                	addiw	s2,s2,-2
    800045e0:	4785                	li	a5,1
    800045e2:	0527e063          	bltu	a5,s2,80004622 <fileclose+0xa8>
    begin_op();
    800045e6:	00000097          	auipc	ra,0x0
    800045ea:	acc080e7          	jalr	-1332(ra) # 800040b2 <begin_op>
    iput(ff.ip);
    800045ee:	854e                	mv	a0,s3
    800045f0:	fffff097          	auipc	ra,0xfffff
    800045f4:	2b0080e7          	jalr	688(ra) # 800038a0 <iput>
    end_op();
    800045f8:	00000097          	auipc	ra,0x0
    800045fc:	b38080e7          	jalr	-1224(ra) # 80004130 <end_op>
    80004600:	a00d                	j	80004622 <fileclose+0xa8>
    panic("fileclose");
    80004602:	00004517          	auipc	a0,0x4
    80004606:	11650513          	addi	a0,a0,278 # 80008718 <syscalls+0x250>
    8000460a:	ffffc097          	auipc	ra,0xffffc
    8000460e:	f36080e7          	jalr	-202(ra) # 80000540 <panic>
    release(&ftable.lock);
    80004612:	0001c517          	auipc	a0,0x1c
    80004616:	6d650513          	addi	a0,a0,1750 # 80020ce8 <ftable>
    8000461a:	ffffc097          	auipc	ra,0xffffc
    8000461e:	670080e7          	jalr	1648(ra) # 80000c8a <release>
  }
}
    80004622:	70e2                	ld	ra,56(sp)
    80004624:	7442                	ld	s0,48(sp)
    80004626:	74a2                	ld	s1,40(sp)
    80004628:	7902                	ld	s2,32(sp)
    8000462a:	69e2                	ld	s3,24(sp)
    8000462c:	6a42                	ld	s4,16(sp)
    8000462e:	6aa2                	ld	s5,8(sp)
    80004630:	6121                	addi	sp,sp,64
    80004632:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004634:	85d6                	mv	a1,s5
    80004636:	8552                	mv	a0,s4
    80004638:	00000097          	auipc	ra,0x0
    8000463c:	34c080e7          	jalr	844(ra) # 80004984 <pipeclose>
    80004640:	b7cd                	j	80004622 <fileclose+0xa8>

0000000080004642 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004642:	715d                	addi	sp,sp,-80
    80004644:	e486                	sd	ra,72(sp)
    80004646:	e0a2                	sd	s0,64(sp)
    80004648:	fc26                	sd	s1,56(sp)
    8000464a:	f84a                	sd	s2,48(sp)
    8000464c:	f44e                	sd	s3,40(sp)
    8000464e:	0880                	addi	s0,sp,80
    80004650:	84aa                	mv	s1,a0
    80004652:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004654:	ffffd097          	auipc	ra,0xffffd
    80004658:	358080e7          	jalr	856(ra) # 800019ac <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000465c:	409c                	lw	a5,0(s1)
    8000465e:	37f9                	addiw	a5,a5,-2
    80004660:	4705                	li	a4,1
    80004662:	04f76763          	bltu	a4,a5,800046b0 <filestat+0x6e>
    80004666:	892a                	mv	s2,a0
    ilock(f->ip);
    80004668:	6c88                	ld	a0,24(s1)
    8000466a:	fffff097          	auipc	ra,0xfffff
    8000466e:	07c080e7          	jalr	124(ra) # 800036e6 <ilock>
    stati(f->ip, &st);
    80004672:	fb840593          	addi	a1,s0,-72
    80004676:	6c88                	ld	a0,24(s1)
    80004678:	fffff097          	auipc	ra,0xfffff
    8000467c:	2f8080e7          	jalr	760(ra) # 80003970 <stati>
    iunlock(f->ip);
    80004680:	6c88                	ld	a0,24(s1)
    80004682:	fffff097          	auipc	ra,0xfffff
    80004686:	126080e7          	jalr	294(ra) # 800037a8 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000468a:	46e1                	li	a3,24
    8000468c:	fb840613          	addi	a2,s0,-72
    80004690:	85ce                	mv	a1,s3
    80004692:	05093503          	ld	a0,80(s2)
    80004696:	ffffd097          	auipc	ra,0xffffd
    8000469a:	fd6080e7          	jalr	-42(ra) # 8000166c <copyout>
    8000469e:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800046a2:	60a6                	ld	ra,72(sp)
    800046a4:	6406                	ld	s0,64(sp)
    800046a6:	74e2                	ld	s1,56(sp)
    800046a8:	7942                	ld	s2,48(sp)
    800046aa:	79a2                	ld	s3,40(sp)
    800046ac:	6161                	addi	sp,sp,80
    800046ae:	8082                	ret
  return -1;
    800046b0:	557d                	li	a0,-1
    800046b2:	bfc5                	j	800046a2 <filestat+0x60>

00000000800046b4 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800046b4:	7179                	addi	sp,sp,-48
    800046b6:	f406                	sd	ra,40(sp)
    800046b8:	f022                	sd	s0,32(sp)
    800046ba:	ec26                	sd	s1,24(sp)
    800046bc:	e84a                	sd	s2,16(sp)
    800046be:	e44e                	sd	s3,8(sp)
    800046c0:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800046c2:	00854783          	lbu	a5,8(a0)
    800046c6:	c3d5                	beqz	a5,8000476a <fileread+0xb6>
    800046c8:	84aa                	mv	s1,a0
    800046ca:	89ae                	mv	s3,a1
    800046cc:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800046ce:	411c                	lw	a5,0(a0)
    800046d0:	4705                	li	a4,1
    800046d2:	04e78963          	beq	a5,a4,80004724 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800046d6:	470d                	li	a4,3
    800046d8:	04e78d63          	beq	a5,a4,80004732 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800046dc:	4709                	li	a4,2
    800046de:	06e79e63          	bne	a5,a4,8000475a <fileread+0xa6>
    ilock(f->ip);
    800046e2:	6d08                	ld	a0,24(a0)
    800046e4:	fffff097          	auipc	ra,0xfffff
    800046e8:	002080e7          	jalr	2(ra) # 800036e6 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800046ec:	874a                	mv	a4,s2
    800046ee:	5094                	lw	a3,32(s1)
    800046f0:	864e                	mv	a2,s3
    800046f2:	4585                	li	a1,1
    800046f4:	6c88                	ld	a0,24(s1)
    800046f6:	fffff097          	auipc	ra,0xfffff
    800046fa:	2a4080e7          	jalr	676(ra) # 8000399a <readi>
    800046fe:	892a                	mv	s2,a0
    80004700:	00a05563          	blez	a0,8000470a <fileread+0x56>
      f->off += r;
    80004704:	509c                	lw	a5,32(s1)
    80004706:	9fa9                	addw	a5,a5,a0
    80004708:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000470a:	6c88                	ld	a0,24(s1)
    8000470c:	fffff097          	auipc	ra,0xfffff
    80004710:	09c080e7          	jalr	156(ra) # 800037a8 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004714:	854a                	mv	a0,s2
    80004716:	70a2                	ld	ra,40(sp)
    80004718:	7402                	ld	s0,32(sp)
    8000471a:	64e2                	ld	s1,24(sp)
    8000471c:	6942                	ld	s2,16(sp)
    8000471e:	69a2                	ld	s3,8(sp)
    80004720:	6145                	addi	sp,sp,48
    80004722:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004724:	6908                	ld	a0,16(a0)
    80004726:	00000097          	auipc	ra,0x0
    8000472a:	3c6080e7          	jalr	966(ra) # 80004aec <piperead>
    8000472e:	892a                	mv	s2,a0
    80004730:	b7d5                	j	80004714 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004732:	02451783          	lh	a5,36(a0)
    80004736:	03079693          	slli	a3,a5,0x30
    8000473a:	92c1                	srli	a3,a3,0x30
    8000473c:	4725                	li	a4,9
    8000473e:	02d76863          	bltu	a4,a3,8000476e <fileread+0xba>
    80004742:	0792                	slli	a5,a5,0x4
    80004744:	0001c717          	auipc	a4,0x1c
    80004748:	50470713          	addi	a4,a4,1284 # 80020c48 <devsw>
    8000474c:	97ba                	add	a5,a5,a4
    8000474e:	639c                	ld	a5,0(a5)
    80004750:	c38d                	beqz	a5,80004772 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004752:	4505                	li	a0,1
    80004754:	9782                	jalr	a5
    80004756:	892a                	mv	s2,a0
    80004758:	bf75                	j	80004714 <fileread+0x60>
    panic("fileread");
    8000475a:	00004517          	auipc	a0,0x4
    8000475e:	fce50513          	addi	a0,a0,-50 # 80008728 <syscalls+0x260>
    80004762:	ffffc097          	auipc	ra,0xffffc
    80004766:	dde080e7          	jalr	-546(ra) # 80000540 <panic>
    return -1;
    8000476a:	597d                	li	s2,-1
    8000476c:	b765                	j	80004714 <fileread+0x60>
      return -1;
    8000476e:	597d                	li	s2,-1
    80004770:	b755                	j	80004714 <fileread+0x60>
    80004772:	597d                	li	s2,-1
    80004774:	b745                	j	80004714 <fileread+0x60>

0000000080004776 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004776:	715d                	addi	sp,sp,-80
    80004778:	e486                	sd	ra,72(sp)
    8000477a:	e0a2                	sd	s0,64(sp)
    8000477c:	fc26                	sd	s1,56(sp)
    8000477e:	f84a                	sd	s2,48(sp)
    80004780:	f44e                	sd	s3,40(sp)
    80004782:	f052                	sd	s4,32(sp)
    80004784:	ec56                	sd	s5,24(sp)
    80004786:	e85a                	sd	s6,16(sp)
    80004788:	e45e                	sd	s7,8(sp)
    8000478a:	e062                	sd	s8,0(sp)
    8000478c:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    8000478e:	00954783          	lbu	a5,9(a0)
    80004792:	10078663          	beqz	a5,8000489e <filewrite+0x128>
    80004796:	892a                	mv	s2,a0
    80004798:	8b2e                	mv	s6,a1
    8000479a:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000479c:	411c                	lw	a5,0(a0)
    8000479e:	4705                	li	a4,1
    800047a0:	02e78263          	beq	a5,a4,800047c4 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800047a4:	470d                	li	a4,3
    800047a6:	02e78663          	beq	a5,a4,800047d2 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800047aa:	4709                	li	a4,2
    800047ac:	0ee79163          	bne	a5,a4,8000488e <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800047b0:	0ac05d63          	blez	a2,8000486a <filewrite+0xf4>
    int i = 0;
    800047b4:	4981                	li	s3,0
    800047b6:	6b85                	lui	s7,0x1
    800047b8:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    800047bc:	6c05                	lui	s8,0x1
    800047be:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    800047c2:	a861                	j	8000485a <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800047c4:	6908                	ld	a0,16(a0)
    800047c6:	00000097          	auipc	ra,0x0
    800047ca:	22e080e7          	jalr	558(ra) # 800049f4 <pipewrite>
    800047ce:	8a2a                	mv	s4,a0
    800047d0:	a045                	j	80004870 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800047d2:	02451783          	lh	a5,36(a0)
    800047d6:	03079693          	slli	a3,a5,0x30
    800047da:	92c1                	srli	a3,a3,0x30
    800047dc:	4725                	li	a4,9
    800047de:	0cd76263          	bltu	a4,a3,800048a2 <filewrite+0x12c>
    800047e2:	0792                	slli	a5,a5,0x4
    800047e4:	0001c717          	auipc	a4,0x1c
    800047e8:	46470713          	addi	a4,a4,1124 # 80020c48 <devsw>
    800047ec:	97ba                	add	a5,a5,a4
    800047ee:	679c                	ld	a5,8(a5)
    800047f0:	cbdd                	beqz	a5,800048a6 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800047f2:	4505                	li	a0,1
    800047f4:	9782                	jalr	a5
    800047f6:	8a2a                	mv	s4,a0
    800047f8:	a8a5                	j	80004870 <filewrite+0xfa>
    800047fa:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800047fe:	00000097          	auipc	ra,0x0
    80004802:	8b4080e7          	jalr	-1868(ra) # 800040b2 <begin_op>
      ilock(f->ip);
    80004806:	01893503          	ld	a0,24(s2)
    8000480a:	fffff097          	auipc	ra,0xfffff
    8000480e:	edc080e7          	jalr	-292(ra) # 800036e6 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004812:	8756                	mv	a4,s5
    80004814:	02092683          	lw	a3,32(s2)
    80004818:	01698633          	add	a2,s3,s6
    8000481c:	4585                	li	a1,1
    8000481e:	01893503          	ld	a0,24(s2)
    80004822:	fffff097          	auipc	ra,0xfffff
    80004826:	270080e7          	jalr	624(ra) # 80003a92 <writei>
    8000482a:	84aa                	mv	s1,a0
    8000482c:	00a05763          	blez	a0,8000483a <filewrite+0xc4>
        f->off += r;
    80004830:	02092783          	lw	a5,32(s2)
    80004834:	9fa9                	addw	a5,a5,a0
    80004836:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000483a:	01893503          	ld	a0,24(s2)
    8000483e:	fffff097          	auipc	ra,0xfffff
    80004842:	f6a080e7          	jalr	-150(ra) # 800037a8 <iunlock>
      end_op();
    80004846:	00000097          	auipc	ra,0x0
    8000484a:	8ea080e7          	jalr	-1814(ra) # 80004130 <end_op>

      if(r != n1){
    8000484e:	009a9f63          	bne	s5,s1,8000486c <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004852:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004856:	0149db63          	bge	s3,s4,8000486c <filewrite+0xf6>
      int n1 = n - i;
    8000485a:	413a04bb          	subw	s1,s4,s3
    8000485e:	0004879b          	sext.w	a5,s1
    80004862:	f8fbdce3          	bge	s7,a5,800047fa <filewrite+0x84>
    80004866:	84e2                	mv	s1,s8
    80004868:	bf49                	j	800047fa <filewrite+0x84>
    int i = 0;
    8000486a:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    8000486c:	013a1f63          	bne	s4,s3,8000488a <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004870:	8552                	mv	a0,s4
    80004872:	60a6                	ld	ra,72(sp)
    80004874:	6406                	ld	s0,64(sp)
    80004876:	74e2                	ld	s1,56(sp)
    80004878:	7942                	ld	s2,48(sp)
    8000487a:	79a2                	ld	s3,40(sp)
    8000487c:	7a02                	ld	s4,32(sp)
    8000487e:	6ae2                	ld	s5,24(sp)
    80004880:	6b42                	ld	s6,16(sp)
    80004882:	6ba2                	ld	s7,8(sp)
    80004884:	6c02                	ld	s8,0(sp)
    80004886:	6161                	addi	sp,sp,80
    80004888:	8082                	ret
    ret = (i == n ? n : -1);
    8000488a:	5a7d                	li	s4,-1
    8000488c:	b7d5                	j	80004870 <filewrite+0xfa>
    panic("filewrite");
    8000488e:	00004517          	auipc	a0,0x4
    80004892:	eaa50513          	addi	a0,a0,-342 # 80008738 <syscalls+0x270>
    80004896:	ffffc097          	auipc	ra,0xffffc
    8000489a:	caa080e7          	jalr	-854(ra) # 80000540 <panic>
    return -1;
    8000489e:	5a7d                	li	s4,-1
    800048a0:	bfc1                	j	80004870 <filewrite+0xfa>
      return -1;
    800048a2:	5a7d                	li	s4,-1
    800048a4:	b7f1                	j	80004870 <filewrite+0xfa>
    800048a6:	5a7d                	li	s4,-1
    800048a8:	b7e1                	j	80004870 <filewrite+0xfa>

00000000800048aa <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800048aa:	7179                	addi	sp,sp,-48
    800048ac:	f406                	sd	ra,40(sp)
    800048ae:	f022                	sd	s0,32(sp)
    800048b0:	ec26                	sd	s1,24(sp)
    800048b2:	e84a                	sd	s2,16(sp)
    800048b4:	e44e                	sd	s3,8(sp)
    800048b6:	e052                	sd	s4,0(sp)
    800048b8:	1800                	addi	s0,sp,48
    800048ba:	84aa                	mv	s1,a0
    800048bc:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800048be:	0005b023          	sd	zero,0(a1)
    800048c2:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800048c6:	00000097          	auipc	ra,0x0
    800048ca:	bf8080e7          	jalr	-1032(ra) # 800044be <filealloc>
    800048ce:	e088                	sd	a0,0(s1)
    800048d0:	c551                	beqz	a0,8000495c <pipealloc+0xb2>
    800048d2:	00000097          	auipc	ra,0x0
    800048d6:	bec080e7          	jalr	-1044(ra) # 800044be <filealloc>
    800048da:	00aa3023          	sd	a0,0(s4)
    800048de:	c92d                	beqz	a0,80004950 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800048e0:	ffffc097          	auipc	ra,0xffffc
    800048e4:	206080e7          	jalr	518(ra) # 80000ae6 <kalloc>
    800048e8:	892a                	mv	s2,a0
    800048ea:	c125                	beqz	a0,8000494a <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800048ec:	4985                	li	s3,1
    800048ee:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800048f2:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800048f6:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800048fa:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800048fe:	00004597          	auipc	a1,0x4
    80004902:	e4a58593          	addi	a1,a1,-438 # 80008748 <syscalls+0x280>
    80004906:	ffffc097          	auipc	ra,0xffffc
    8000490a:	240080e7          	jalr	576(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    8000490e:	609c                	ld	a5,0(s1)
    80004910:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004914:	609c                	ld	a5,0(s1)
    80004916:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    8000491a:	609c                	ld	a5,0(s1)
    8000491c:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004920:	609c                	ld	a5,0(s1)
    80004922:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004926:	000a3783          	ld	a5,0(s4)
    8000492a:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    8000492e:	000a3783          	ld	a5,0(s4)
    80004932:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004936:	000a3783          	ld	a5,0(s4)
    8000493a:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    8000493e:	000a3783          	ld	a5,0(s4)
    80004942:	0127b823          	sd	s2,16(a5)
  return 0;
    80004946:	4501                	li	a0,0
    80004948:	a025                	j	80004970 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    8000494a:	6088                	ld	a0,0(s1)
    8000494c:	e501                	bnez	a0,80004954 <pipealloc+0xaa>
    8000494e:	a039                	j	8000495c <pipealloc+0xb2>
    80004950:	6088                	ld	a0,0(s1)
    80004952:	c51d                	beqz	a0,80004980 <pipealloc+0xd6>
    fileclose(*f0);
    80004954:	00000097          	auipc	ra,0x0
    80004958:	c26080e7          	jalr	-986(ra) # 8000457a <fileclose>
  if(*f1)
    8000495c:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004960:	557d                	li	a0,-1
  if(*f1)
    80004962:	c799                	beqz	a5,80004970 <pipealloc+0xc6>
    fileclose(*f1);
    80004964:	853e                	mv	a0,a5
    80004966:	00000097          	auipc	ra,0x0
    8000496a:	c14080e7          	jalr	-1004(ra) # 8000457a <fileclose>
  return -1;
    8000496e:	557d                	li	a0,-1
}
    80004970:	70a2                	ld	ra,40(sp)
    80004972:	7402                	ld	s0,32(sp)
    80004974:	64e2                	ld	s1,24(sp)
    80004976:	6942                	ld	s2,16(sp)
    80004978:	69a2                	ld	s3,8(sp)
    8000497a:	6a02                	ld	s4,0(sp)
    8000497c:	6145                	addi	sp,sp,48
    8000497e:	8082                	ret
  return -1;
    80004980:	557d                	li	a0,-1
    80004982:	b7fd                	j	80004970 <pipealloc+0xc6>

0000000080004984 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004984:	1101                	addi	sp,sp,-32
    80004986:	ec06                	sd	ra,24(sp)
    80004988:	e822                	sd	s0,16(sp)
    8000498a:	e426                	sd	s1,8(sp)
    8000498c:	e04a                	sd	s2,0(sp)
    8000498e:	1000                	addi	s0,sp,32
    80004990:	84aa                	mv	s1,a0
    80004992:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004994:	ffffc097          	auipc	ra,0xffffc
    80004998:	242080e7          	jalr	578(ra) # 80000bd6 <acquire>
  if(writable){
    8000499c:	02090d63          	beqz	s2,800049d6 <pipeclose+0x52>
    pi->writeopen = 0;
    800049a0:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800049a4:	21848513          	addi	a0,s1,536
    800049a8:	ffffd097          	auipc	ra,0xffffd
    800049ac:	710080e7          	jalr	1808(ra) # 800020b8 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800049b0:	2204b783          	ld	a5,544(s1)
    800049b4:	eb95                	bnez	a5,800049e8 <pipeclose+0x64>
    release(&pi->lock);
    800049b6:	8526                	mv	a0,s1
    800049b8:	ffffc097          	auipc	ra,0xffffc
    800049bc:	2d2080e7          	jalr	722(ra) # 80000c8a <release>
    kfree((char*)pi);
    800049c0:	8526                	mv	a0,s1
    800049c2:	ffffc097          	auipc	ra,0xffffc
    800049c6:	026080e7          	jalr	38(ra) # 800009e8 <kfree>
  } else
    release(&pi->lock);
}
    800049ca:	60e2                	ld	ra,24(sp)
    800049cc:	6442                	ld	s0,16(sp)
    800049ce:	64a2                	ld	s1,8(sp)
    800049d0:	6902                	ld	s2,0(sp)
    800049d2:	6105                	addi	sp,sp,32
    800049d4:	8082                	ret
    pi->readopen = 0;
    800049d6:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800049da:	21c48513          	addi	a0,s1,540
    800049de:	ffffd097          	auipc	ra,0xffffd
    800049e2:	6da080e7          	jalr	1754(ra) # 800020b8 <wakeup>
    800049e6:	b7e9                	j	800049b0 <pipeclose+0x2c>
    release(&pi->lock);
    800049e8:	8526                	mv	a0,s1
    800049ea:	ffffc097          	auipc	ra,0xffffc
    800049ee:	2a0080e7          	jalr	672(ra) # 80000c8a <release>
}
    800049f2:	bfe1                	j	800049ca <pipeclose+0x46>

00000000800049f4 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800049f4:	711d                	addi	sp,sp,-96
    800049f6:	ec86                	sd	ra,88(sp)
    800049f8:	e8a2                	sd	s0,80(sp)
    800049fa:	e4a6                	sd	s1,72(sp)
    800049fc:	e0ca                	sd	s2,64(sp)
    800049fe:	fc4e                	sd	s3,56(sp)
    80004a00:	f852                	sd	s4,48(sp)
    80004a02:	f456                	sd	s5,40(sp)
    80004a04:	f05a                	sd	s6,32(sp)
    80004a06:	ec5e                	sd	s7,24(sp)
    80004a08:	e862                	sd	s8,16(sp)
    80004a0a:	1080                	addi	s0,sp,96
    80004a0c:	84aa                	mv	s1,a0
    80004a0e:	8aae                	mv	s5,a1
    80004a10:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004a12:	ffffd097          	auipc	ra,0xffffd
    80004a16:	f9a080e7          	jalr	-102(ra) # 800019ac <myproc>
    80004a1a:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004a1c:	8526                	mv	a0,s1
    80004a1e:	ffffc097          	auipc	ra,0xffffc
    80004a22:	1b8080e7          	jalr	440(ra) # 80000bd6 <acquire>
  while(i < n){
    80004a26:	0b405663          	blez	s4,80004ad2 <pipewrite+0xde>
  int i = 0;
    80004a2a:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a2c:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004a2e:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004a32:	21c48b93          	addi	s7,s1,540
    80004a36:	a089                	j	80004a78 <pipewrite+0x84>
      release(&pi->lock);
    80004a38:	8526                	mv	a0,s1
    80004a3a:	ffffc097          	auipc	ra,0xffffc
    80004a3e:	250080e7          	jalr	592(ra) # 80000c8a <release>
      return -1;
    80004a42:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004a44:	854a                	mv	a0,s2
    80004a46:	60e6                	ld	ra,88(sp)
    80004a48:	6446                	ld	s0,80(sp)
    80004a4a:	64a6                	ld	s1,72(sp)
    80004a4c:	6906                	ld	s2,64(sp)
    80004a4e:	79e2                	ld	s3,56(sp)
    80004a50:	7a42                	ld	s4,48(sp)
    80004a52:	7aa2                	ld	s5,40(sp)
    80004a54:	7b02                	ld	s6,32(sp)
    80004a56:	6be2                	ld	s7,24(sp)
    80004a58:	6c42                	ld	s8,16(sp)
    80004a5a:	6125                	addi	sp,sp,96
    80004a5c:	8082                	ret
      wakeup(&pi->nread);
    80004a5e:	8562                	mv	a0,s8
    80004a60:	ffffd097          	auipc	ra,0xffffd
    80004a64:	658080e7          	jalr	1624(ra) # 800020b8 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004a68:	85a6                	mv	a1,s1
    80004a6a:	855e                	mv	a0,s7
    80004a6c:	ffffd097          	auipc	ra,0xffffd
    80004a70:	5e8080e7          	jalr	1512(ra) # 80002054 <sleep>
  while(i < n){
    80004a74:	07495063          	bge	s2,s4,80004ad4 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004a78:	2204a783          	lw	a5,544(s1)
    80004a7c:	dfd5                	beqz	a5,80004a38 <pipewrite+0x44>
    80004a7e:	854e                	mv	a0,s3
    80004a80:	ffffe097          	auipc	ra,0xffffe
    80004a84:	87c080e7          	jalr	-1924(ra) # 800022fc <killed>
    80004a88:	f945                	bnez	a0,80004a38 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004a8a:	2184a783          	lw	a5,536(s1)
    80004a8e:	21c4a703          	lw	a4,540(s1)
    80004a92:	2007879b          	addiw	a5,a5,512
    80004a96:	fcf704e3          	beq	a4,a5,80004a5e <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a9a:	4685                	li	a3,1
    80004a9c:	01590633          	add	a2,s2,s5
    80004aa0:	faf40593          	addi	a1,s0,-81
    80004aa4:	0509b503          	ld	a0,80(s3)
    80004aa8:	ffffd097          	auipc	ra,0xffffd
    80004aac:	c50080e7          	jalr	-944(ra) # 800016f8 <copyin>
    80004ab0:	03650263          	beq	a0,s6,80004ad4 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004ab4:	21c4a783          	lw	a5,540(s1)
    80004ab8:	0017871b          	addiw	a4,a5,1
    80004abc:	20e4ae23          	sw	a4,540(s1)
    80004ac0:	1ff7f793          	andi	a5,a5,511
    80004ac4:	97a6                	add	a5,a5,s1
    80004ac6:	faf44703          	lbu	a4,-81(s0)
    80004aca:	00e78c23          	sb	a4,24(a5)
      i++;
    80004ace:	2905                	addiw	s2,s2,1
    80004ad0:	b755                	j	80004a74 <pipewrite+0x80>
  int i = 0;
    80004ad2:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004ad4:	21848513          	addi	a0,s1,536
    80004ad8:	ffffd097          	auipc	ra,0xffffd
    80004adc:	5e0080e7          	jalr	1504(ra) # 800020b8 <wakeup>
  release(&pi->lock);
    80004ae0:	8526                	mv	a0,s1
    80004ae2:	ffffc097          	auipc	ra,0xffffc
    80004ae6:	1a8080e7          	jalr	424(ra) # 80000c8a <release>
  return i;
    80004aea:	bfa9                	j	80004a44 <pipewrite+0x50>

0000000080004aec <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004aec:	715d                	addi	sp,sp,-80
    80004aee:	e486                	sd	ra,72(sp)
    80004af0:	e0a2                	sd	s0,64(sp)
    80004af2:	fc26                	sd	s1,56(sp)
    80004af4:	f84a                	sd	s2,48(sp)
    80004af6:	f44e                	sd	s3,40(sp)
    80004af8:	f052                	sd	s4,32(sp)
    80004afa:	ec56                	sd	s5,24(sp)
    80004afc:	e85a                	sd	s6,16(sp)
    80004afe:	0880                	addi	s0,sp,80
    80004b00:	84aa                	mv	s1,a0
    80004b02:	892e                	mv	s2,a1
    80004b04:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004b06:	ffffd097          	auipc	ra,0xffffd
    80004b0a:	ea6080e7          	jalr	-346(ra) # 800019ac <myproc>
    80004b0e:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004b10:	8526                	mv	a0,s1
    80004b12:	ffffc097          	auipc	ra,0xffffc
    80004b16:	0c4080e7          	jalr	196(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b1a:	2184a703          	lw	a4,536(s1)
    80004b1e:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b22:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b26:	02f71763          	bne	a4,a5,80004b54 <piperead+0x68>
    80004b2a:	2244a783          	lw	a5,548(s1)
    80004b2e:	c39d                	beqz	a5,80004b54 <piperead+0x68>
    if(killed(pr)){
    80004b30:	8552                	mv	a0,s4
    80004b32:	ffffd097          	auipc	ra,0xffffd
    80004b36:	7ca080e7          	jalr	1994(ra) # 800022fc <killed>
    80004b3a:	e949                	bnez	a0,80004bcc <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b3c:	85a6                	mv	a1,s1
    80004b3e:	854e                	mv	a0,s3
    80004b40:	ffffd097          	auipc	ra,0xffffd
    80004b44:	514080e7          	jalr	1300(ra) # 80002054 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b48:	2184a703          	lw	a4,536(s1)
    80004b4c:	21c4a783          	lw	a5,540(s1)
    80004b50:	fcf70de3          	beq	a4,a5,80004b2a <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b54:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b56:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b58:	05505463          	blez	s5,80004ba0 <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80004b5c:	2184a783          	lw	a5,536(s1)
    80004b60:	21c4a703          	lw	a4,540(s1)
    80004b64:	02f70e63          	beq	a4,a5,80004ba0 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004b68:	0017871b          	addiw	a4,a5,1
    80004b6c:	20e4ac23          	sw	a4,536(s1)
    80004b70:	1ff7f793          	andi	a5,a5,511
    80004b74:	97a6                	add	a5,a5,s1
    80004b76:	0187c783          	lbu	a5,24(a5)
    80004b7a:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b7e:	4685                	li	a3,1
    80004b80:	fbf40613          	addi	a2,s0,-65
    80004b84:	85ca                	mv	a1,s2
    80004b86:	050a3503          	ld	a0,80(s4)
    80004b8a:	ffffd097          	auipc	ra,0xffffd
    80004b8e:	ae2080e7          	jalr	-1310(ra) # 8000166c <copyout>
    80004b92:	01650763          	beq	a0,s6,80004ba0 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b96:	2985                	addiw	s3,s3,1
    80004b98:	0905                	addi	s2,s2,1
    80004b9a:	fd3a91e3          	bne	s5,s3,80004b5c <piperead+0x70>
    80004b9e:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004ba0:	21c48513          	addi	a0,s1,540
    80004ba4:	ffffd097          	auipc	ra,0xffffd
    80004ba8:	514080e7          	jalr	1300(ra) # 800020b8 <wakeup>
  release(&pi->lock);
    80004bac:	8526                	mv	a0,s1
    80004bae:	ffffc097          	auipc	ra,0xffffc
    80004bb2:	0dc080e7          	jalr	220(ra) # 80000c8a <release>
  return i;
}
    80004bb6:	854e                	mv	a0,s3
    80004bb8:	60a6                	ld	ra,72(sp)
    80004bba:	6406                	ld	s0,64(sp)
    80004bbc:	74e2                	ld	s1,56(sp)
    80004bbe:	7942                	ld	s2,48(sp)
    80004bc0:	79a2                	ld	s3,40(sp)
    80004bc2:	7a02                	ld	s4,32(sp)
    80004bc4:	6ae2                	ld	s5,24(sp)
    80004bc6:	6b42                	ld	s6,16(sp)
    80004bc8:	6161                	addi	sp,sp,80
    80004bca:	8082                	ret
      release(&pi->lock);
    80004bcc:	8526                	mv	a0,s1
    80004bce:	ffffc097          	auipc	ra,0xffffc
    80004bd2:	0bc080e7          	jalr	188(ra) # 80000c8a <release>
      return -1;
    80004bd6:	59fd                	li	s3,-1
    80004bd8:	bff9                	j	80004bb6 <piperead+0xca>

0000000080004bda <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004bda:	1141                	addi	sp,sp,-16
    80004bdc:	e422                	sd	s0,8(sp)
    80004bde:	0800                	addi	s0,sp,16
    80004be0:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004be2:	8905                	andi	a0,a0,1
    80004be4:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80004be6:	8b89                	andi	a5,a5,2
    80004be8:	c399                	beqz	a5,80004bee <flags2perm+0x14>
      perm |= PTE_W;
    80004bea:	00456513          	ori	a0,a0,4
    return perm;
}
    80004bee:	6422                	ld	s0,8(sp)
    80004bf0:	0141                	addi	sp,sp,16
    80004bf2:	8082                	ret

0000000080004bf4 <exec>:

int
exec(char *path, char **argv)
{
    80004bf4:	de010113          	addi	sp,sp,-544
    80004bf8:	20113c23          	sd	ra,536(sp)
    80004bfc:	20813823          	sd	s0,528(sp)
    80004c00:	20913423          	sd	s1,520(sp)
    80004c04:	21213023          	sd	s2,512(sp)
    80004c08:	ffce                	sd	s3,504(sp)
    80004c0a:	fbd2                	sd	s4,496(sp)
    80004c0c:	f7d6                	sd	s5,488(sp)
    80004c0e:	f3da                	sd	s6,480(sp)
    80004c10:	efde                	sd	s7,472(sp)
    80004c12:	ebe2                	sd	s8,464(sp)
    80004c14:	e7e6                	sd	s9,456(sp)
    80004c16:	e3ea                	sd	s10,448(sp)
    80004c18:	ff6e                	sd	s11,440(sp)
    80004c1a:	1400                	addi	s0,sp,544
    80004c1c:	892a                	mv	s2,a0
    80004c1e:	dea43423          	sd	a0,-536(s0)
    80004c22:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004c26:	ffffd097          	auipc	ra,0xffffd
    80004c2a:	d86080e7          	jalr	-634(ra) # 800019ac <myproc>
    80004c2e:	84aa                	mv	s1,a0

  begin_op();
    80004c30:	fffff097          	auipc	ra,0xfffff
    80004c34:	482080e7          	jalr	1154(ra) # 800040b2 <begin_op>

  if((ip = namei(path)) == 0){
    80004c38:	854a                	mv	a0,s2
    80004c3a:	fffff097          	auipc	ra,0xfffff
    80004c3e:	258080e7          	jalr	600(ra) # 80003e92 <namei>
    80004c42:	c93d                	beqz	a0,80004cb8 <exec+0xc4>
    80004c44:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004c46:	fffff097          	auipc	ra,0xfffff
    80004c4a:	aa0080e7          	jalr	-1376(ra) # 800036e6 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004c4e:	04000713          	li	a4,64
    80004c52:	4681                	li	a3,0
    80004c54:	e5040613          	addi	a2,s0,-432
    80004c58:	4581                	li	a1,0
    80004c5a:	8556                	mv	a0,s5
    80004c5c:	fffff097          	auipc	ra,0xfffff
    80004c60:	d3e080e7          	jalr	-706(ra) # 8000399a <readi>
    80004c64:	04000793          	li	a5,64
    80004c68:	00f51a63          	bne	a0,a5,80004c7c <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004c6c:	e5042703          	lw	a4,-432(s0)
    80004c70:	464c47b7          	lui	a5,0x464c4
    80004c74:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004c78:	04f70663          	beq	a4,a5,80004cc4 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004c7c:	8556                	mv	a0,s5
    80004c7e:	fffff097          	auipc	ra,0xfffff
    80004c82:	cca080e7          	jalr	-822(ra) # 80003948 <iunlockput>
    end_op();
    80004c86:	fffff097          	auipc	ra,0xfffff
    80004c8a:	4aa080e7          	jalr	1194(ra) # 80004130 <end_op>
  }
  return -1;
    80004c8e:	557d                	li	a0,-1
}
    80004c90:	21813083          	ld	ra,536(sp)
    80004c94:	21013403          	ld	s0,528(sp)
    80004c98:	20813483          	ld	s1,520(sp)
    80004c9c:	20013903          	ld	s2,512(sp)
    80004ca0:	79fe                	ld	s3,504(sp)
    80004ca2:	7a5e                	ld	s4,496(sp)
    80004ca4:	7abe                	ld	s5,488(sp)
    80004ca6:	7b1e                	ld	s6,480(sp)
    80004ca8:	6bfe                	ld	s7,472(sp)
    80004caa:	6c5e                	ld	s8,464(sp)
    80004cac:	6cbe                	ld	s9,456(sp)
    80004cae:	6d1e                	ld	s10,448(sp)
    80004cb0:	7dfa                	ld	s11,440(sp)
    80004cb2:	22010113          	addi	sp,sp,544
    80004cb6:	8082                	ret
    end_op();
    80004cb8:	fffff097          	auipc	ra,0xfffff
    80004cbc:	478080e7          	jalr	1144(ra) # 80004130 <end_op>
    return -1;
    80004cc0:	557d                	li	a0,-1
    80004cc2:	b7f9                	j	80004c90 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004cc4:	8526                	mv	a0,s1
    80004cc6:	ffffd097          	auipc	ra,0xffffd
    80004cca:	daa080e7          	jalr	-598(ra) # 80001a70 <proc_pagetable>
    80004cce:	8b2a                	mv	s6,a0
    80004cd0:	d555                	beqz	a0,80004c7c <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004cd2:	e7042783          	lw	a5,-400(s0)
    80004cd6:	e8845703          	lhu	a4,-376(s0)
    80004cda:	c735                	beqz	a4,80004d46 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004cdc:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004cde:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004ce2:	6a05                	lui	s4,0x1
    80004ce4:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004ce8:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80004cec:	6d85                	lui	s11,0x1
    80004cee:	7d7d                	lui	s10,0xfffff
    80004cf0:	ac3d                	j	80004f2e <exec+0x33a>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004cf2:	00004517          	auipc	a0,0x4
    80004cf6:	a5e50513          	addi	a0,a0,-1442 # 80008750 <syscalls+0x288>
    80004cfa:	ffffc097          	auipc	ra,0xffffc
    80004cfe:	846080e7          	jalr	-1978(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004d02:	874a                	mv	a4,s2
    80004d04:	009c86bb          	addw	a3,s9,s1
    80004d08:	4581                	li	a1,0
    80004d0a:	8556                	mv	a0,s5
    80004d0c:	fffff097          	auipc	ra,0xfffff
    80004d10:	c8e080e7          	jalr	-882(ra) # 8000399a <readi>
    80004d14:	2501                	sext.w	a0,a0
    80004d16:	1aa91963          	bne	s2,a0,80004ec8 <exec+0x2d4>
  for(i = 0; i < sz; i += PGSIZE){
    80004d1a:	009d84bb          	addw	s1,s11,s1
    80004d1e:	013d09bb          	addw	s3,s10,s3
    80004d22:	1f74f663          	bgeu	s1,s7,80004f0e <exec+0x31a>
    pa = walkaddr(pagetable, va + i);
    80004d26:	02049593          	slli	a1,s1,0x20
    80004d2a:	9181                	srli	a1,a1,0x20
    80004d2c:	95e2                	add	a1,a1,s8
    80004d2e:	855a                	mv	a0,s6
    80004d30:	ffffc097          	auipc	ra,0xffffc
    80004d34:	32c080e7          	jalr	812(ra) # 8000105c <walkaddr>
    80004d38:	862a                	mv	a2,a0
    if(pa == 0)
    80004d3a:	dd45                	beqz	a0,80004cf2 <exec+0xfe>
      n = PGSIZE;
    80004d3c:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004d3e:	fd49f2e3          	bgeu	s3,s4,80004d02 <exec+0x10e>
      n = sz - i;
    80004d42:	894e                	mv	s2,s3
    80004d44:	bf7d                	j	80004d02 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004d46:	4901                	li	s2,0
  iunlockput(ip);
    80004d48:	8556                	mv	a0,s5
    80004d4a:	fffff097          	auipc	ra,0xfffff
    80004d4e:	bfe080e7          	jalr	-1026(ra) # 80003948 <iunlockput>
  end_op();
    80004d52:	fffff097          	auipc	ra,0xfffff
    80004d56:	3de080e7          	jalr	990(ra) # 80004130 <end_op>
  p = myproc();
    80004d5a:	ffffd097          	auipc	ra,0xffffd
    80004d5e:	c52080e7          	jalr	-942(ra) # 800019ac <myproc>
    80004d62:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004d64:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004d68:	6785                	lui	a5,0x1
    80004d6a:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80004d6c:	97ca                	add	a5,a5,s2
    80004d6e:	777d                	lui	a4,0xfffff
    80004d70:	8ff9                	and	a5,a5,a4
    80004d72:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004d76:	4691                	li	a3,4
    80004d78:	6609                	lui	a2,0x2
    80004d7a:	963e                	add	a2,a2,a5
    80004d7c:	85be                	mv	a1,a5
    80004d7e:	855a                	mv	a0,s6
    80004d80:	ffffc097          	auipc	ra,0xffffc
    80004d84:	690080e7          	jalr	1680(ra) # 80001410 <uvmalloc>
    80004d88:	8c2a                	mv	s8,a0
  ip = 0;
    80004d8a:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004d8c:	12050e63          	beqz	a0,80004ec8 <exec+0x2d4>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004d90:	75f9                	lui	a1,0xffffe
    80004d92:	95aa                	add	a1,a1,a0
    80004d94:	855a                	mv	a0,s6
    80004d96:	ffffd097          	auipc	ra,0xffffd
    80004d9a:	8a4080e7          	jalr	-1884(ra) # 8000163a <uvmclear>
  stackbase = sp - PGSIZE;
    80004d9e:	7afd                	lui	s5,0xfffff
    80004da0:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004da2:	df043783          	ld	a5,-528(s0)
    80004da6:	6388                	ld	a0,0(a5)
    80004da8:	c925                	beqz	a0,80004e18 <exec+0x224>
    80004daa:	e9040993          	addi	s3,s0,-368
    80004dae:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004db2:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004db4:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004db6:	ffffc097          	auipc	ra,0xffffc
    80004dba:	098080e7          	jalr	152(ra) # 80000e4e <strlen>
    80004dbe:	0015079b          	addiw	a5,a0,1
    80004dc2:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004dc6:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80004dca:	13596663          	bltu	s2,s5,80004ef6 <exec+0x302>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004dce:	df043d83          	ld	s11,-528(s0)
    80004dd2:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004dd6:	8552                	mv	a0,s4
    80004dd8:	ffffc097          	auipc	ra,0xffffc
    80004ddc:	076080e7          	jalr	118(ra) # 80000e4e <strlen>
    80004de0:	0015069b          	addiw	a3,a0,1
    80004de4:	8652                	mv	a2,s4
    80004de6:	85ca                	mv	a1,s2
    80004de8:	855a                	mv	a0,s6
    80004dea:	ffffd097          	auipc	ra,0xffffd
    80004dee:	882080e7          	jalr	-1918(ra) # 8000166c <copyout>
    80004df2:	10054663          	bltz	a0,80004efe <exec+0x30a>
    ustack[argc] = sp;
    80004df6:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004dfa:	0485                	addi	s1,s1,1
    80004dfc:	008d8793          	addi	a5,s11,8
    80004e00:	def43823          	sd	a5,-528(s0)
    80004e04:	008db503          	ld	a0,8(s11)
    80004e08:	c911                	beqz	a0,80004e1c <exec+0x228>
    if(argc >= MAXARG)
    80004e0a:	09a1                	addi	s3,s3,8
    80004e0c:	fb3c95e3          	bne	s9,s3,80004db6 <exec+0x1c2>
  sz = sz1;
    80004e10:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004e14:	4a81                	li	s5,0
    80004e16:	a84d                	j	80004ec8 <exec+0x2d4>
  sp = sz;
    80004e18:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004e1a:	4481                	li	s1,0
  ustack[argc] = 0;
    80004e1c:	00349793          	slli	a5,s1,0x3
    80004e20:	f9078793          	addi	a5,a5,-112
    80004e24:	97a2                	add	a5,a5,s0
    80004e26:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80004e2a:	00148693          	addi	a3,s1,1
    80004e2e:	068e                	slli	a3,a3,0x3
    80004e30:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004e34:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004e38:	01597663          	bgeu	s2,s5,80004e44 <exec+0x250>
  sz = sz1;
    80004e3c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004e40:	4a81                	li	s5,0
    80004e42:	a059                	j	80004ec8 <exec+0x2d4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004e44:	e9040613          	addi	a2,s0,-368
    80004e48:	85ca                	mv	a1,s2
    80004e4a:	855a                	mv	a0,s6
    80004e4c:	ffffd097          	auipc	ra,0xffffd
    80004e50:	820080e7          	jalr	-2016(ra) # 8000166c <copyout>
    80004e54:	0a054963          	bltz	a0,80004f06 <exec+0x312>
  p->trapframe->a1 = sp;
    80004e58:	058bb783          	ld	a5,88(s7)
    80004e5c:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004e60:	de843783          	ld	a5,-536(s0)
    80004e64:	0007c703          	lbu	a4,0(a5)
    80004e68:	cf11                	beqz	a4,80004e84 <exec+0x290>
    80004e6a:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004e6c:	02f00693          	li	a3,47
    80004e70:	a039                	j	80004e7e <exec+0x28a>
      last = s+1;
    80004e72:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004e76:	0785                	addi	a5,a5,1
    80004e78:	fff7c703          	lbu	a4,-1(a5)
    80004e7c:	c701                	beqz	a4,80004e84 <exec+0x290>
    if(*s == '/')
    80004e7e:	fed71ce3          	bne	a4,a3,80004e76 <exec+0x282>
    80004e82:	bfc5                	j	80004e72 <exec+0x27e>
  safestrcpy(p->name, last, sizeof(p->name));
    80004e84:	4641                	li	a2,16
    80004e86:	de843583          	ld	a1,-536(s0)
    80004e8a:	158b8513          	addi	a0,s7,344
    80004e8e:	ffffc097          	auipc	ra,0xffffc
    80004e92:	f8e080e7          	jalr	-114(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    80004e96:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004e9a:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80004e9e:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004ea2:	058bb783          	ld	a5,88(s7)
    80004ea6:	e6843703          	ld	a4,-408(s0)
    80004eaa:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004eac:	058bb783          	ld	a5,88(s7)
    80004eb0:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004eb4:	85ea                	mv	a1,s10
    80004eb6:	ffffd097          	auipc	ra,0xffffd
    80004eba:	c56080e7          	jalr	-938(ra) # 80001b0c <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004ebe:	0004851b          	sext.w	a0,s1
    80004ec2:	b3f9                	j	80004c90 <exec+0x9c>
    80004ec4:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    80004ec8:	df843583          	ld	a1,-520(s0)
    80004ecc:	855a                	mv	a0,s6
    80004ece:	ffffd097          	auipc	ra,0xffffd
    80004ed2:	c3e080e7          	jalr	-962(ra) # 80001b0c <proc_freepagetable>
  if(ip){
    80004ed6:	da0a93e3          	bnez	s5,80004c7c <exec+0x88>
  return -1;
    80004eda:	557d                	li	a0,-1
    80004edc:	bb55                	j	80004c90 <exec+0x9c>
    80004ede:	df243c23          	sd	s2,-520(s0)
    80004ee2:	b7dd                	j	80004ec8 <exec+0x2d4>
    80004ee4:	df243c23          	sd	s2,-520(s0)
    80004ee8:	b7c5                	j	80004ec8 <exec+0x2d4>
    80004eea:	df243c23          	sd	s2,-520(s0)
    80004eee:	bfe9                	j	80004ec8 <exec+0x2d4>
    80004ef0:	df243c23          	sd	s2,-520(s0)
    80004ef4:	bfd1                	j	80004ec8 <exec+0x2d4>
  sz = sz1;
    80004ef6:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004efa:	4a81                	li	s5,0
    80004efc:	b7f1                	j	80004ec8 <exec+0x2d4>
  sz = sz1;
    80004efe:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f02:	4a81                	li	s5,0
    80004f04:	b7d1                	j	80004ec8 <exec+0x2d4>
  sz = sz1;
    80004f06:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f0a:	4a81                	li	s5,0
    80004f0c:	bf75                	j	80004ec8 <exec+0x2d4>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004f0e:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f12:	e0843783          	ld	a5,-504(s0)
    80004f16:	0017869b          	addiw	a3,a5,1
    80004f1a:	e0d43423          	sd	a3,-504(s0)
    80004f1e:	e0043783          	ld	a5,-512(s0)
    80004f22:	0387879b          	addiw	a5,a5,56
    80004f26:	e8845703          	lhu	a4,-376(s0)
    80004f2a:	e0e6dfe3          	bge	a3,a4,80004d48 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004f2e:	2781                	sext.w	a5,a5
    80004f30:	e0f43023          	sd	a5,-512(s0)
    80004f34:	03800713          	li	a4,56
    80004f38:	86be                	mv	a3,a5
    80004f3a:	e1840613          	addi	a2,s0,-488
    80004f3e:	4581                	li	a1,0
    80004f40:	8556                	mv	a0,s5
    80004f42:	fffff097          	auipc	ra,0xfffff
    80004f46:	a58080e7          	jalr	-1448(ra) # 8000399a <readi>
    80004f4a:	03800793          	li	a5,56
    80004f4e:	f6f51be3          	bne	a0,a5,80004ec4 <exec+0x2d0>
    if(ph.type != ELF_PROG_LOAD)
    80004f52:	e1842783          	lw	a5,-488(s0)
    80004f56:	4705                	li	a4,1
    80004f58:	fae79de3          	bne	a5,a4,80004f12 <exec+0x31e>
    if(ph.memsz < ph.filesz)
    80004f5c:	e4043483          	ld	s1,-448(s0)
    80004f60:	e3843783          	ld	a5,-456(s0)
    80004f64:	f6f4ede3          	bltu	s1,a5,80004ede <exec+0x2ea>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004f68:	e2843783          	ld	a5,-472(s0)
    80004f6c:	94be                	add	s1,s1,a5
    80004f6e:	f6f4ebe3          	bltu	s1,a5,80004ee4 <exec+0x2f0>
    if(ph.vaddr % PGSIZE != 0)
    80004f72:	de043703          	ld	a4,-544(s0)
    80004f76:	8ff9                	and	a5,a5,a4
    80004f78:	fbad                	bnez	a5,80004eea <exec+0x2f6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004f7a:	e1c42503          	lw	a0,-484(s0)
    80004f7e:	00000097          	auipc	ra,0x0
    80004f82:	c5c080e7          	jalr	-932(ra) # 80004bda <flags2perm>
    80004f86:	86aa                	mv	a3,a0
    80004f88:	8626                	mv	a2,s1
    80004f8a:	85ca                	mv	a1,s2
    80004f8c:	855a                	mv	a0,s6
    80004f8e:	ffffc097          	auipc	ra,0xffffc
    80004f92:	482080e7          	jalr	1154(ra) # 80001410 <uvmalloc>
    80004f96:	dea43c23          	sd	a0,-520(s0)
    80004f9a:	d939                	beqz	a0,80004ef0 <exec+0x2fc>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004f9c:	e2843c03          	ld	s8,-472(s0)
    80004fa0:	e2042c83          	lw	s9,-480(s0)
    80004fa4:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004fa8:	f60b83e3          	beqz	s7,80004f0e <exec+0x31a>
    80004fac:	89de                	mv	s3,s7
    80004fae:	4481                	li	s1,0
    80004fb0:	bb9d                	j	80004d26 <exec+0x132>

0000000080004fb2 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004fb2:	7179                	addi	sp,sp,-48
    80004fb4:	f406                	sd	ra,40(sp)
    80004fb6:	f022                	sd	s0,32(sp)
    80004fb8:	ec26                	sd	s1,24(sp)
    80004fba:	e84a                	sd	s2,16(sp)
    80004fbc:	1800                	addi	s0,sp,48
    80004fbe:	892e                	mv	s2,a1
    80004fc0:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80004fc2:	fdc40593          	addi	a1,s0,-36
    80004fc6:	ffffe097          	auipc	ra,0xffffe
    80004fca:	b9c080e7          	jalr	-1124(ra) # 80002b62 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004fce:	fdc42703          	lw	a4,-36(s0)
    80004fd2:	47bd                	li	a5,15
    80004fd4:	02e7eb63          	bltu	a5,a4,8000500a <argfd+0x58>
    80004fd8:	ffffd097          	auipc	ra,0xffffd
    80004fdc:	9d4080e7          	jalr	-1580(ra) # 800019ac <myproc>
    80004fe0:	fdc42703          	lw	a4,-36(s0)
    80004fe4:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffdd23a>
    80004fe8:	078e                	slli	a5,a5,0x3
    80004fea:	953e                	add	a0,a0,a5
    80004fec:	611c                	ld	a5,0(a0)
    80004fee:	c385                	beqz	a5,8000500e <argfd+0x5c>
    return -1;
  if(pfd)
    80004ff0:	00090463          	beqz	s2,80004ff8 <argfd+0x46>
    *pfd = fd;
    80004ff4:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80004ff8:	4501                	li	a0,0
  if(pf)
    80004ffa:	c091                	beqz	s1,80004ffe <argfd+0x4c>
    *pf = f;
    80004ffc:	e09c                	sd	a5,0(s1)
}
    80004ffe:	70a2                	ld	ra,40(sp)
    80005000:	7402                	ld	s0,32(sp)
    80005002:	64e2                	ld	s1,24(sp)
    80005004:	6942                	ld	s2,16(sp)
    80005006:	6145                	addi	sp,sp,48
    80005008:	8082                	ret
    return -1;
    8000500a:	557d                	li	a0,-1
    8000500c:	bfcd                	j	80004ffe <argfd+0x4c>
    8000500e:	557d                	li	a0,-1
    80005010:	b7fd                	j	80004ffe <argfd+0x4c>

0000000080005012 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005012:	1101                	addi	sp,sp,-32
    80005014:	ec06                	sd	ra,24(sp)
    80005016:	e822                	sd	s0,16(sp)
    80005018:	e426                	sd	s1,8(sp)
    8000501a:	1000                	addi	s0,sp,32
    8000501c:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000501e:	ffffd097          	auipc	ra,0xffffd
    80005022:	98e080e7          	jalr	-1650(ra) # 800019ac <myproc>
    80005026:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005028:	0d050793          	addi	a5,a0,208
    8000502c:	4501                	li	a0,0
    8000502e:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005030:	6398                	ld	a4,0(a5)
    80005032:	cb19                	beqz	a4,80005048 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005034:	2505                	addiw	a0,a0,1
    80005036:	07a1                	addi	a5,a5,8
    80005038:	fed51ce3          	bne	a0,a3,80005030 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000503c:	557d                	li	a0,-1
}
    8000503e:	60e2                	ld	ra,24(sp)
    80005040:	6442                	ld	s0,16(sp)
    80005042:	64a2                	ld	s1,8(sp)
    80005044:	6105                	addi	sp,sp,32
    80005046:	8082                	ret
      p->ofile[fd] = f;
    80005048:	01a50793          	addi	a5,a0,26
    8000504c:	078e                	slli	a5,a5,0x3
    8000504e:	963e                	add	a2,a2,a5
    80005050:	e204                	sd	s1,0(a2)
      return fd;
    80005052:	b7f5                	j	8000503e <fdalloc+0x2c>

0000000080005054 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005054:	715d                	addi	sp,sp,-80
    80005056:	e486                	sd	ra,72(sp)
    80005058:	e0a2                	sd	s0,64(sp)
    8000505a:	fc26                	sd	s1,56(sp)
    8000505c:	f84a                	sd	s2,48(sp)
    8000505e:	f44e                	sd	s3,40(sp)
    80005060:	f052                	sd	s4,32(sp)
    80005062:	ec56                	sd	s5,24(sp)
    80005064:	e85a                	sd	s6,16(sp)
    80005066:	0880                	addi	s0,sp,80
    80005068:	8b2e                	mv	s6,a1
    8000506a:	89b2                	mv	s3,a2
    8000506c:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000506e:	fb040593          	addi	a1,s0,-80
    80005072:	fffff097          	auipc	ra,0xfffff
    80005076:	e3e080e7          	jalr	-450(ra) # 80003eb0 <nameiparent>
    8000507a:	84aa                	mv	s1,a0
    8000507c:	14050f63          	beqz	a0,800051da <create+0x186>
    return 0;

  ilock(dp);
    80005080:	ffffe097          	auipc	ra,0xffffe
    80005084:	666080e7          	jalr	1638(ra) # 800036e6 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005088:	4601                	li	a2,0
    8000508a:	fb040593          	addi	a1,s0,-80
    8000508e:	8526                	mv	a0,s1
    80005090:	fffff097          	auipc	ra,0xfffff
    80005094:	b3a080e7          	jalr	-1222(ra) # 80003bca <dirlookup>
    80005098:	8aaa                	mv	s5,a0
    8000509a:	c931                	beqz	a0,800050ee <create+0x9a>
    iunlockput(dp);
    8000509c:	8526                	mv	a0,s1
    8000509e:	fffff097          	auipc	ra,0xfffff
    800050a2:	8aa080e7          	jalr	-1878(ra) # 80003948 <iunlockput>
    ilock(ip);
    800050a6:	8556                	mv	a0,s5
    800050a8:	ffffe097          	auipc	ra,0xffffe
    800050ac:	63e080e7          	jalr	1598(ra) # 800036e6 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800050b0:	000b059b          	sext.w	a1,s6
    800050b4:	4789                	li	a5,2
    800050b6:	02f59563          	bne	a1,a5,800050e0 <create+0x8c>
    800050ba:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffdd264>
    800050be:	37f9                	addiw	a5,a5,-2
    800050c0:	17c2                	slli	a5,a5,0x30
    800050c2:	93c1                	srli	a5,a5,0x30
    800050c4:	4705                	li	a4,1
    800050c6:	00f76d63          	bltu	a4,a5,800050e0 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    800050ca:	8556                	mv	a0,s5
    800050cc:	60a6                	ld	ra,72(sp)
    800050ce:	6406                	ld	s0,64(sp)
    800050d0:	74e2                	ld	s1,56(sp)
    800050d2:	7942                	ld	s2,48(sp)
    800050d4:	79a2                	ld	s3,40(sp)
    800050d6:	7a02                	ld	s4,32(sp)
    800050d8:	6ae2                	ld	s5,24(sp)
    800050da:	6b42                	ld	s6,16(sp)
    800050dc:	6161                	addi	sp,sp,80
    800050de:	8082                	ret
    iunlockput(ip);
    800050e0:	8556                	mv	a0,s5
    800050e2:	fffff097          	auipc	ra,0xfffff
    800050e6:	866080e7          	jalr	-1946(ra) # 80003948 <iunlockput>
    return 0;
    800050ea:	4a81                	li	s5,0
    800050ec:	bff9                	j	800050ca <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    800050ee:	85da                	mv	a1,s6
    800050f0:	4088                	lw	a0,0(s1)
    800050f2:	ffffe097          	auipc	ra,0xffffe
    800050f6:	456080e7          	jalr	1110(ra) # 80003548 <ialloc>
    800050fa:	8a2a                	mv	s4,a0
    800050fc:	c539                	beqz	a0,8000514a <create+0xf6>
  ilock(ip);
    800050fe:	ffffe097          	auipc	ra,0xffffe
    80005102:	5e8080e7          	jalr	1512(ra) # 800036e6 <ilock>
  ip->major = major;
    80005106:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    8000510a:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    8000510e:	4905                	li	s2,1
    80005110:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005114:	8552                	mv	a0,s4
    80005116:	ffffe097          	auipc	ra,0xffffe
    8000511a:	504080e7          	jalr	1284(ra) # 8000361a <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000511e:	000b059b          	sext.w	a1,s6
    80005122:	03258b63          	beq	a1,s2,80005158 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    80005126:	004a2603          	lw	a2,4(s4)
    8000512a:	fb040593          	addi	a1,s0,-80
    8000512e:	8526                	mv	a0,s1
    80005130:	fffff097          	auipc	ra,0xfffff
    80005134:	cb0080e7          	jalr	-848(ra) # 80003de0 <dirlink>
    80005138:	06054f63          	bltz	a0,800051b6 <create+0x162>
  iunlockput(dp);
    8000513c:	8526                	mv	a0,s1
    8000513e:	fffff097          	auipc	ra,0xfffff
    80005142:	80a080e7          	jalr	-2038(ra) # 80003948 <iunlockput>
  return ip;
    80005146:	8ad2                	mv	s5,s4
    80005148:	b749                	j	800050ca <create+0x76>
    iunlockput(dp);
    8000514a:	8526                	mv	a0,s1
    8000514c:	ffffe097          	auipc	ra,0xffffe
    80005150:	7fc080e7          	jalr	2044(ra) # 80003948 <iunlockput>
    return 0;
    80005154:	8ad2                	mv	s5,s4
    80005156:	bf95                	j	800050ca <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005158:	004a2603          	lw	a2,4(s4)
    8000515c:	00003597          	auipc	a1,0x3
    80005160:	61458593          	addi	a1,a1,1556 # 80008770 <syscalls+0x2a8>
    80005164:	8552                	mv	a0,s4
    80005166:	fffff097          	auipc	ra,0xfffff
    8000516a:	c7a080e7          	jalr	-902(ra) # 80003de0 <dirlink>
    8000516e:	04054463          	bltz	a0,800051b6 <create+0x162>
    80005172:	40d0                	lw	a2,4(s1)
    80005174:	00003597          	auipc	a1,0x3
    80005178:	60458593          	addi	a1,a1,1540 # 80008778 <syscalls+0x2b0>
    8000517c:	8552                	mv	a0,s4
    8000517e:	fffff097          	auipc	ra,0xfffff
    80005182:	c62080e7          	jalr	-926(ra) # 80003de0 <dirlink>
    80005186:	02054863          	bltz	a0,800051b6 <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    8000518a:	004a2603          	lw	a2,4(s4)
    8000518e:	fb040593          	addi	a1,s0,-80
    80005192:	8526                	mv	a0,s1
    80005194:	fffff097          	auipc	ra,0xfffff
    80005198:	c4c080e7          	jalr	-948(ra) # 80003de0 <dirlink>
    8000519c:	00054d63          	bltz	a0,800051b6 <create+0x162>
    dp->nlink++;  // for ".."
    800051a0:	04a4d783          	lhu	a5,74(s1)
    800051a4:	2785                	addiw	a5,a5,1
    800051a6:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800051aa:	8526                	mv	a0,s1
    800051ac:	ffffe097          	auipc	ra,0xffffe
    800051b0:	46e080e7          	jalr	1134(ra) # 8000361a <iupdate>
    800051b4:	b761                	j	8000513c <create+0xe8>
  ip->nlink = 0;
    800051b6:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800051ba:	8552                	mv	a0,s4
    800051bc:	ffffe097          	auipc	ra,0xffffe
    800051c0:	45e080e7          	jalr	1118(ra) # 8000361a <iupdate>
  iunlockput(ip);
    800051c4:	8552                	mv	a0,s4
    800051c6:	ffffe097          	auipc	ra,0xffffe
    800051ca:	782080e7          	jalr	1922(ra) # 80003948 <iunlockput>
  iunlockput(dp);
    800051ce:	8526                	mv	a0,s1
    800051d0:	ffffe097          	auipc	ra,0xffffe
    800051d4:	778080e7          	jalr	1912(ra) # 80003948 <iunlockput>
  return 0;
    800051d8:	bdcd                	j	800050ca <create+0x76>
    return 0;
    800051da:	8aaa                	mv	s5,a0
    800051dc:	b5fd                	j	800050ca <create+0x76>

00000000800051de <sys_dup>:
{
    800051de:	7179                	addi	sp,sp,-48
    800051e0:	f406                	sd	ra,40(sp)
    800051e2:	f022                	sd	s0,32(sp)
    800051e4:	ec26                	sd	s1,24(sp)
    800051e6:	e84a                	sd	s2,16(sp)
    800051e8:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800051ea:	fd840613          	addi	a2,s0,-40
    800051ee:	4581                	li	a1,0
    800051f0:	4501                	li	a0,0
    800051f2:	00000097          	auipc	ra,0x0
    800051f6:	dc0080e7          	jalr	-576(ra) # 80004fb2 <argfd>
    return -1;
    800051fa:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800051fc:	02054363          	bltz	a0,80005222 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    80005200:	fd843903          	ld	s2,-40(s0)
    80005204:	854a                	mv	a0,s2
    80005206:	00000097          	auipc	ra,0x0
    8000520a:	e0c080e7          	jalr	-500(ra) # 80005012 <fdalloc>
    8000520e:	84aa                	mv	s1,a0
    return -1;
    80005210:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005212:	00054863          	bltz	a0,80005222 <sys_dup+0x44>
  filedup(f);
    80005216:	854a                	mv	a0,s2
    80005218:	fffff097          	auipc	ra,0xfffff
    8000521c:	310080e7          	jalr	784(ra) # 80004528 <filedup>
  return fd;
    80005220:	87a6                	mv	a5,s1
}
    80005222:	853e                	mv	a0,a5
    80005224:	70a2                	ld	ra,40(sp)
    80005226:	7402                	ld	s0,32(sp)
    80005228:	64e2                	ld	s1,24(sp)
    8000522a:	6942                	ld	s2,16(sp)
    8000522c:	6145                	addi	sp,sp,48
    8000522e:	8082                	ret

0000000080005230 <sys_read>:
{
    80005230:	7179                	addi	sp,sp,-48
    80005232:	f406                	sd	ra,40(sp)
    80005234:	f022                	sd	s0,32(sp)
    80005236:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005238:	fd840593          	addi	a1,s0,-40
    8000523c:	4505                	li	a0,1
    8000523e:	ffffe097          	auipc	ra,0xffffe
    80005242:	944080e7          	jalr	-1724(ra) # 80002b82 <argaddr>
  argint(2, &n);
    80005246:	fe440593          	addi	a1,s0,-28
    8000524a:	4509                	li	a0,2
    8000524c:	ffffe097          	auipc	ra,0xffffe
    80005250:	916080e7          	jalr	-1770(ra) # 80002b62 <argint>
  if(argfd(0, 0, &f) < 0)
    80005254:	fe840613          	addi	a2,s0,-24
    80005258:	4581                	li	a1,0
    8000525a:	4501                	li	a0,0
    8000525c:	00000097          	auipc	ra,0x0
    80005260:	d56080e7          	jalr	-682(ra) # 80004fb2 <argfd>
    80005264:	87aa                	mv	a5,a0
    return -1;
    80005266:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005268:	0007cc63          	bltz	a5,80005280 <sys_read+0x50>
  return fileread(f, p, n);
    8000526c:	fe442603          	lw	a2,-28(s0)
    80005270:	fd843583          	ld	a1,-40(s0)
    80005274:	fe843503          	ld	a0,-24(s0)
    80005278:	fffff097          	auipc	ra,0xfffff
    8000527c:	43c080e7          	jalr	1084(ra) # 800046b4 <fileread>
}
    80005280:	70a2                	ld	ra,40(sp)
    80005282:	7402                	ld	s0,32(sp)
    80005284:	6145                	addi	sp,sp,48
    80005286:	8082                	ret

0000000080005288 <sys_write>:
{
    80005288:	7179                	addi	sp,sp,-48
    8000528a:	f406                	sd	ra,40(sp)
    8000528c:	f022                	sd	s0,32(sp)
    8000528e:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005290:	fd840593          	addi	a1,s0,-40
    80005294:	4505                	li	a0,1
    80005296:	ffffe097          	auipc	ra,0xffffe
    8000529a:	8ec080e7          	jalr	-1812(ra) # 80002b82 <argaddr>
  argint(2, &n);
    8000529e:	fe440593          	addi	a1,s0,-28
    800052a2:	4509                	li	a0,2
    800052a4:	ffffe097          	auipc	ra,0xffffe
    800052a8:	8be080e7          	jalr	-1858(ra) # 80002b62 <argint>
  if(argfd(0, 0, &f) < 0)
    800052ac:	fe840613          	addi	a2,s0,-24
    800052b0:	4581                	li	a1,0
    800052b2:	4501                	li	a0,0
    800052b4:	00000097          	auipc	ra,0x0
    800052b8:	cfe080e7          	jalr	-770(ra) # 80004fb2 <argfd>
    800052bc:	87aa                	mv	a5,a0
    return -1;
    800052be:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800052c0:	0007cc63          	bltz	a5,800052d8 <sys_write+0x50>
  return filewrite(f, p, n);
    800052c4:	fe442603          	lw	a2,-28(s0)
    800052c8:	fd843583          	ld	a1,-40(s0)
    800052cc:	fe843503          	ld	a0,-24(s0)
    800052d0:	fffff097          	auipc	ra,0xfffff
    800052d4:	4a6080e7          	jalr	1190(ra) # 80004776 <filewrite>
}
    800052d8:	70a2                	ld	ra,40(sp)
    800052da:	7402                	ld	s0,32(sp)
    800052dc:	6145                	addi	sp,sp,48
    800052de:	8082                	ret

00000000800052e0 <sys_close>:
{
    800052e0:	1101                	addi	sp,sp,-32
    800052e2:	ec06                	sd	ra,24(sp)
    800052e4:	e822                	sd	s0,16(sp)
    800052e6:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800052e8:	fe040613          	addi	a2,s0,-32
    800052ec:	fec40593          	addi	a1,s0,-20
    800052f0:	4501                	li	a0,0
    800052f2:	00000097          	auipc	ra,0x0
    800052f6:	cc0080e7          	jalr	-832(ra) # 80004fb2 <argfd>
    return -1;
    800052fa:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800052fc:	02054463          	bltz	a0,80005324 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005300:	ffffc097          	auipc	ra,0xffffc
    80005304:	6ac080e7          	jalr	1708(ra) # 800019ac <myproc>
    80005308:	fec42783          	lw	a5,-20(s0)
    8000530c:	07e9                	addi	a5,a5,26
    8000530e:	078e                	slli	a5,a5,0x3
    80005310:	953e                	add	a0,a0,a5
    80005312:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80005316:	fe043503          	ld	a0,-32(s0)
    8000531a:	fffff097          	auipc	ra,0xfffff
    8000531e:	260080e7          	jalr	608(ra) # 8000457a <fileclose>
  return 0;
    80005322:	4781                	li	a5,0
}
    80005324:	853e                	mv	a0,a5
    80005326:	60e2                	ld	ra,24(sp)
    80005328:	6442                	ld	s0,16(sp)
    8000532a:	6105                	addi	sp,sp,32
    8000532c:	8082                	ret

000000008000532e <sys_fstat>:
{
    8000532e:	1101                	addi	sp,sp,-32
    80005330:	ec06                	sd	ra,24(sp)
    80005332:	e822                	sd	s0,16(sp)
    80005334:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005336:	fe040593          	addi	a1,s0,-32
    8000533a:	4505                	li	a0,1
    8000533c:	ffffe097          	auipc	ra,0xffffe
    80005340:	846080e7          	jalr	-1978(ra) # 80002b82 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005344:	fe840613          	addi	a2,s0,-24
    80005348:	4581                	li	a1,0
    8000534a:	4501                	li	a0,0
    8000534c:	00000097          	auipc	ra,0x0
    80005350:	c66080e7          	jalr	-922(ra) # 80004fb2 <argfd>
    80005354:	87aa                	mv	a5,a0
    return -1;
    80005356:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005358:	0007ca63          	bltz	a5,8000536c <sys_fstat+0x3e>
  return filestat(f, st);
    8000535c:	fe043583          	ld	a1,-32(s0)
    80005360:	fe843503          	ld	a0,-24(s0)
    80005364:	fffff097          	auipc	ra,0xfffff
    80005368:	2de080e7          	jalr	734(ra) # 80004642 <filestat>
}
    8000536c:	60e2                	ld	ra,24(sp)
    8000536e:	6442                	ld	s0,16(sp)
    80005370:	6105                	addi	sp,sp,32
    80005372:	8082                	ret

0000000080005374 <sys_link>:
{
    80005374:	7169                	addi	sp,sp,-304
    80005376:	f606                	sd	ra,296(sp)
    80005378:	f222                	sd	s0,288(sp)
    8000537a:	ee26                	sd	s1,280(sp)
    8000537c:	ea4a                	sd	s2,272(sp)
    8000537e:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005380:	08000613          	li	a2,128
    80005384:	ed040593          	addi	a1,s0,-304
    80005388:	4501                	li	a0,0
    8000538a:	ffffe097          	auipc	ra,0xffffe
    8000538e:	818080e7          	jalr	-2024(ra) # 80002ba2 <argstr>
    return -1;
    80005392:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005394:	10054e63          	bltz	a0,800054b0 <sys_link+0x13c>
    80005398:	08000613          	li	a2,128
    8000539c:	f5040593          	addi	a1,s0,-176
    800053a0:	4505                	li	a0,1
    800053a2:	ffffe097          	auipc	ra,0xffffe
    800053a6:	800080e7          	jalr	-2048(ra) # 80002ba2 <argstr>
    return -1;
    800053aa:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053ac:	10054263          	bltz	a0,800054b0 <sys_link+0x13c>
  begin_op();
    800053b0:	fffff097          	auipc	ra,0xfffff
    800053b4:	d02080e7          	jalr	-766(ra) # 800040b2 <begin_op>
  if((ip = namei(old)) == 0){
    800053b8:	ed040513          	addi	a0,s0,-304
    800053bc:	fffff097          	auipc	ra,0xfffff
    800053c0:	ad6080e7          	jalr	-1322(ra) # 80003e92 <namei>
    800053c4:	84aa                	mv	s1,a0
    800053c6:	c551                	beqz	a0,80005452 <sys_link+0xde>
  ilock(ip);
    800053c8:	ffffe097          	auipc	ra,0xffffe
    800053cc:	31e080e7          	jalr	798(ra) # 800036e6 <ilock>
  if(ip->type == T_DIR){
    800053d0:	04449703          	lh	a4,68(s1)
    800053d4:	4785                	li	a5,1
    800053d6:	08f70463          	beq	a4,a5,8000545e <sys_link+0xea>
  ip->nlink++;
    800053da:	04a4d783          	lhu	a5,74(s1)
    800053de:	2785                	addiw	a5,a5,1
    800053e0:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800053e4:	8526                	mv	a0,s1
    800053e6:	ffffe097          	auipc	ra,0xffffe
    800053ea:	234080e7          	jalr	564(ra) # 8000361a <iupdate>
  iunlock(ip);
    800053ee:	8526                	mv	a0,s1
    800053f0:	ffffe097          	auipc	ra,0xffffe
    800053f4:	3b8080e7          	jalr	952(ra) # 800037a8 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800053f8:	fd040593          	addi	a1,s0,-48
    800053fc:	f5040513          	addi	a0,s0,-176
    80005400:	fffff097          	auipc	ra,0xfffff
    80005404:	ab0080e7          	jalr	-1360(ra) # 80003eb0 <nameiparent>
    80005408:	892a                	mv	s2,a0
    8000540a:	c935                	beqz	a0,8000547e <sys_link+0x10a>
  ilock(dp);
    8000540c:	ffffe097          	auipc	ra,0xffffe
    80005410:	2da080e7          	jalr	730(ra) # 800036e6 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005414:	00092703          	lw	a4,0(s2)
    80005418:	409c                	lw	a5,0(s1)
    8000541a:	04f71d63          	bne	a4,a5,80005474 <sys_link+0x100>
    8000541e:	40d0                	lw	a2,4(s1)
    80005420:	fd040593          	addi	a1,s0,-48
    80005424:	854a                	mv	a0,s2
    80005426:	fffff097          	auipc	ra,0xfffff
    8000542a:	9ba080e7          	jalr	-1606(ra) # 80003de0 <dirlink>
    8000542e:	04054363          	bltz	a0,80005474 <sys_link+0x100>
  iunlockput(dp);
    80005432:	854a                	mv	a0,s2
    80005434:	ffffe097          	auipc	ra,0xffffe
    80005438:	514080e7          	jalr	1300(ra) # 80003948 <iunlockput>
  iput(ip);
    8000543c:	8526                	mv	a0,s1
    8000543e:	ffffe097          	auipc	ra,0xffffe
    80005442:	462080e7          	jalr	1122(ra) # 800038a0 <iput>
  end_op();
    80005446:	fffff097          	auipc	ra,0xfffff
    8000544a:	cea080e7          	jalr	-790(ra) # 80004130 <end_op>
  return 0;
    8000544e:	4781                	li	a5,0
    80005450:	a085                	j	800054b0 <sys_link+0x13c>
    end_op();
    80005452:	fffff097          	auipc	ra,0xfffff
    80005456:	cde080e7          	jalr	-802(ra) # 80004130 <end_op>
    return -1;
    8000545a:	57fd                	li	a5,-1
    8000545c:	a891                	j	800054b0 <sys_link+0x13c>
    iunlockput(ip);
    8000545e:	8526                	mv	a0,s1
    80005460:	ffffe097          	auipc	ra,0xffffe
    80005464:	4e8080e7          	jalr	1256(ra) # 80003948 <iunlockput>
    end_op();
    80005468:	fffff097          	auipc	ra,0xfffff
    8000546c:	cc8080e7          	jalr	-824(ra) # 80004130 <end_op>
    return -1;
    80005470:	57fd                	li	a5,-1
    80005472:	a83d                	j	800054b0 <sys_link+0x13c>
    iunlockput(dp);
    80005474:	854a                	mv	a0,s2
    80005476:	ffffe097          	auipc	ra,0xffffe
    8000547a:	4d2080e7          	jalr	1234(ra) # 80003948 <iunlockput>
  ilock(ip);
    8000547e:	8526                	mv	a0,s1
    80005480:	ffffe097          	auipc	ra,0xffffe
    80005484:	266080e7          	jalr	614(ra) # 800036e6 <ilock>
  ip->nlink--;
    80005488:	04a4d783          	lhu	a5,74(s1)
    8000548c:	37fd                	addiw	a5,a5,-1
    8000548e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005492:	8526                	mv	a0,s1
    80005494:	ffffe097          	auipc	ra,0xffffe
    80005498:	186080e7          	jalr	390(ra) # 8000361a <iupdate>
  iunlockput(ip);
    8000549c:	8526                	mv	a0,s1
    8000549e:	ffffe097          	auipc	ra,0xffffe
    800054a2:	4aa080e7          	jalr	1194(ra) # 80003948 <iunlockput>
  end_op();
    800054a6:	fffff097          	auipc	ra,0xfffff
    800054aa:	c8a080e7          	jalr	-886(ra) # 80004130 <end_op>
  return -1;
    800054ae:	57fd                	li	a5,-1
}
    800054b0:	853e                	mv	a0,a5
    800054b2:	70b2                	ld	ra,296(sp)
    800054b4:	7412                	ld	s0,288(sp)
    800054b6:	64f2                	ld	s1,280(sp)
    800054b8:	6952                	ld	s2,272(sp)
    800054ba:	6155                	addi	sp,sp,304
    800054bc:	8082                	ret

00000000800054be <sys_unlink>:
{
    800054be:	7151                	addi	sp,sp,-240
    800054c0:	f586                	sd	ra,232(sp)
    800054c2:	f1a2                	sd	s0,224(sp)
    800054c4:	eda6                	sd	s1,216(sp)
    800054c6:	e9ca                	sd	s2,208(sp)
    800054c8:	e5ce                	sd	s3,200(sp)
    800054ca:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800054cc:	08000613          	li	a2,128
    800054d0:	f3040593          	addi	a1,s0,-208
    800054d4:	4501                	li	a0,0
    800054d6:	ffffd097          	auipc	ra,0xffffd
    800054da:	6cc080e7          	jalr	1740(ra) # 80002ba2 <argstr>
    800054de:	18054163          	bltz	a0,80005660 <sys_unlink+0x1a2>
  begin_op();
    800054e2:	fffff097          	auipc	ra,0xfffff
    800054e6:	bd0080e7          	jalr	-1072(ra) # 800040b2 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800054ea:	fb040593          	addi	a1,s0,-80
    800054ee:	f3040513          	addi	a0,s0,-208
    800054f2:	fffff097          	auipc	ra,0xfffff
    800054f6:	9be080e7          	jalr	-1602(ra) # 80003eb0 <nameiparent>
    800054fa:	84aa                	mv	s1,a0
    800054fc:	c979                	beqz	a0,800055d2 <sys_unlink+0x114>
  ilock(dp);
    800054fe:	ffffe097          	auipc	ra,0xffffe
    80005502:	1e8080e7          	jalr	488(ra) # 800036e6 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005506:	00003597          	auipc	a1,0x3
    8000550a:	26a58593          	addi	a1,a1,618 # 80008770 <syscalls+0x2a8>
    8000550e:	fb040513          	addi	a0,s0,-80
    80005512:	ffffe097          	auipc	ra,0xffffe
    80005516:	69e080e7          	jalr	1694(ra) # 80003bb0 <namecmp>
    8000551a:	14050a63          	beqz	a0,8000566e <sys_unlink+0x1b0>
    8000551e:	00003597          	auipc	a1,0x3
    80005522:	25a58593          	addi	a1,a1,602 # 80008778 <syscalls+0x2b0>
    80005526:	fb040513          	addi	a0,s0,-80
    8000552a:	ffffe097          	auipc	ra,0xffffe
    8000552e:	686080e7          	jalr	1670(ra) # 80003bb0 <namecmp>
    80005532:	12050e63          	beqz	a0,8000566e <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005536:	f2c40613          	addi	a2,s0,-212
    8000553a:	fb040593          	addi	a1,s0,-80
    8000553e:	8526                	mv	a0,s1
    80005540:	ffffe097          	auipc	ra,0xffffe
    80005544:	68a080e7          	jalr	1674(ra) # 80003bca <dirlookup>
    80005548:	892a                	mv	s2,a0
    8000554a:	12050263          	beqz	a0,8000566e <sys_unlink+0x1b0>
  ilock(ip);
    8000554e:	ffffe097          	auipc	ra,0xffffe
    80005552:	198080e7          	jalr	408(ra) # 800036e6 <ilock>
  if(ip->nlink < 1)
    80005556:	04a91783          	lh	a5,74(s2)
    8000555a:	08f05263          	blez	a5,800055de <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000555e:	04491703          	lh	a4,68(s2)
    80005562:	4785                	li	a5,1
    80005564:	08f70563          	beq	a4,a5,800055ee <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005568:	4641                	li	a2,16
    8000556a:	4581                	li	a1,0
    8000556c:	fc040513          	addi	a0,s0,-64
    80005570:	ffffb097          	auipc	ra,0xffffb
    80005574:	762080e7          	jalr	1890(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005578:	4741                	li	a4,16
    8000557a:	f2c42683          	lw	a3,-212(s0)
    8000557e:	fc040613          	addi	a2,s0,-64
    80005582:	4581                	li	a1,0
    80005584:	8526                	mv	a0,s1
    80005586:	ffffe097          	auipc	ra,0xffffe
    8000558a:	50c080e7          	jalr	1292(ra) # 80003a92 <writei>
    8000558e:	47c1                	li	a5,16
    80005590:	0af51563          	bne	a0,a5,8000563a <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005594:	04491703          	lh	a4,68(s2)
    80005598:	4785                	li	a5,1
    8000559a:	0af70863          	beq	a4,a5,8000564a <sys_unlink+0x18c>
  iunlockput(dp);
    8000559e:	8526                	mv	a0,s1
    800055a0:	ffffe097          	auipc	ra,0xffffe
    800055a4:	3a8080e7          	jalr	936(ra) # 80003948 <iunlockput>
  ip->nlink--;
    800055a8:	04a95783          	lhu	a5,74(s2)
    800055ac:	37fd                	addiw	a5,a5,-1
    800055ae:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800055b2:	854a                	mv	a0,s2
    800055b4:	ffffe097          	auipc	ra,0xffffe
    800055b8:	066080e7          	jalr	102(ra) # 8000361a <iupdate>
  iunlockput(ip);
    800055bc:	854a                	mv	a0,s2
    800055be:	ffffe097          	auipc	ra,0xffffe
    800055c2:	38a080e7          	jalr	906(ra) # 80003948 <iunlockput>
  end_op();
    800055c6:	fffff097          	auipc	ra,0xfffff
    800055ca:	b6a080e7          	jalr	-1174(ra) # 80004130 <end_op>
  return 0;
    800055ce:	4501                	li	a0,0
    800055d0:	a84d                	j	80005682 <sys_unlink+0x1c4>
    end_op();
    800055d2:	fffff097          	auipc	ra,0xfffff
    800055d6:	b5e080e7          	jalr	-1186(ra) # 80004130 <end_op>
    return -1;
    800055da:	557d                	li	a0,-1
    800055dc:	a05d                	j	80005682 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800055de:	00003517          	auipc	a0,0x3
    800055e2:	1a250513          	addi	a0,a0,418 # 80008780 <syscalls+0x2b8>
    800055e6:	ffffb097          	auipc	ra,0xffffb
    800055ea:	f5a080e7          	jalr	-166(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800055ee:	04c92703          	lw	a4,76(s2)
    800055f2:	02000793          	li	a5,32
    800055f6:	f6e7f9e3          	bgeu	a5,a4,80005568 <sys_unlink+0xaa>
    800055fa:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800055fe:	4741                	li	a4,16
    80005600:	86ce                	mv	a3,s3
    80005602:	f1840613          	addi	a2,s0,-232
    80005606:	4581                	li	a1,0
    80005608:	854a                	mv	a0,s2
    8000560a:	ffffe097          	auipc	ra,0xffffe
    8000560e:	390080e7          	jalr	912(ra) # 8000399a <readi>
    80005612:	47c1                	li	a5,16
    80005614:	00f51b63          	bne	a0,a5,8000562a <sys_unlink+0x16c>
    if(de.inum != 0)
    80005618:	f1845783          	lhu	a5,-232(s0)
    8000561c:	e7a1                	bnez	a5,80005664 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000561e:	29c1                	addiw	s3,s3,16
    80005620:	04c92783          	lw	a5,76(s2)
    80005624:	fcf9ede3          	bltu	s3,a5,800055fe <sys_unlink+0x140>
    80005628:	b781                	j	80005568 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000562a:	00003517          	auipc	a0,0x3
    8000562e:	16e50513          	addi	a0,a0,366 # 80008798 <syscalls+0x2d0>
    80005632:	ffffb097          	auipc	ra,0xffffb
    80005636:	f0e080e7          	jalr	-242(ra) # 80000540 <panic>
    panic("unlink: writei");
    8000563a:	00003517          	auipc	a0,0x3
    8000563e:	17650513          	addi	a0,a0,374 # 800087b0 <syscalls+0x2e8>
    80005642:	ffffb097          	auipc	ra,0xffffb
    80005646:	efe080e7          	jalr	-258(ra) # 80000540 <panic>
    dp->nlink--;
    8000564a:	04a4d783          	lhu	a5,74(s1)
    8000564e:	37fd                	addiw	a5,a5,-1
    80005650:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005654:	8526                	mv	a0,s1
    80005656:	ffffe097          	auipc	ra,0xffffe
    8000565a:	fc4080e7          	jalr	-60(ra) # 8000361a <iupdate>
    8000565e:	b781                	j	8000559e <sys_unlink+0xe0>
    return -1;
    80005660:	557d                	li	a0,-1
    80005662:	a005                	j	80005682 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005664:	854a                	mv	a0,s2
    80005666:	ffffe097          	auipc	ra,0xffffe
    8000566a:	2e2080e7          	jalr	738(ra) # 80003948 <iunlockput>
  iunlockput(dp);
    8000566e:	8526                	mv	a0,s1
    80005670:	ffffe097          	auipc	ra,0xffffe
    80005674:	2d8080e7          	jalr	728(ra) # 80003948 <iunlockput>
  end_op();
    80005678:	fffff097          	auipc	ra,0xfffff
    8000567c:	ab8080e7          	jalr	-1352(ra) # 80004130 <end_op>
  return -1;
    80005680:	557d                	li	a0,-1
}
    80005682:	70ae                	ld	ra,232(sp)
    80005684:	740e                	ld	s0,224(sp)
    80005686:	64ee                	ld	s1,216(sp)
    80005688:	694e                	ld	s2,208(sp)
    8000568a:	69ae                	ld	s3,200(sp)
    8000568c:	616d                	addi	sp,sp,240
    8000568e:	8082                	ret

0000000080005690 <sys_open>:

uint64
sys_open(void)
{
    80005690:	7131                	addi	sp,sp,-192
    80005692:	fd06                	sd	ra,184(sp)
    80005694:	f922                	sd	s0,176(sp)
    80005696:	f526                	sd	s1,168(sp)
    80005698:	f14a                	sd	s2,160(sp)
    8000569a:	ed4e                	sd	s3,152(sp)
    8000569c:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    8000569e:	f4c40593          	addi	a1,s0,-180
    800056a2:	4505                	li	a0,1
    800056a4:	ffffd097          	auipc	ra,0xffffd
    800056a8:	4be080e7          	jalr	1214(ra) # 80002b62 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    800056ac:	08000613          	li	a2,128
    800056b0:	f5040593          	addi	a1,s0,-176
    800056b4:	4501                	li	a0,0
    800056b6:	ffffd097          	auipc	ra,0xffffd
    800056ba:	4ec080e7          	jalr	1260(ra) # 80002ba2 <argstr>
    800056be:	87aa                	mv	a5,a0
    return -1;
    800056c0:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    800056c2:	0a07c963          	bltz	a5,80005774 <sys_open+0xe4>

  begin_op();
    800056c6:	fffff097          	auipc	ra,0xfffff
    800056ca:	9ec080e7          	jalr	-1556(ra) # 800040b2 <begin_op>

  if(omode & O_CREATE){
    800056ce:	f4c42783          	lw	a5,-180(s0)
    800056d2:	2007f793          	andi	a5,a5,512
    800056d6:	cfc5                	beqz	a5,8000578e <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800056d8:	4681                	li	a3,0
    800056da:	4601                	li	a2,0
    800056dc:	4589                	li	a1,2
    800056de:	f5040513          	addi	a0,s0,-176
    800056e2:	00000097          	auipc	ra,0x0
    800056e6:	972080e7          	jalr	-1678(ra) # 80005054 <create>
    800056ea:	84aa                	mv	s1,a0
    if(ip == 0){
    800056ec:	c959                	beqz	a0,80005782 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800056ee:	04449703          	lh	a4,68(s1)
    800056f2:	478d                	li	a5,3
    800056f4:	00f71763          	bne	a4,a5,80005702 <sys_open+0x72>
    800056f8:	0464d703          	lhu	a4,70(s1)
    800056fc:	47a5                	li	a5,9
    800056fe:	0ce7ed63          	bltu	a5,a4,800057d8 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005702:	fffff097          	auipc	ra,0xfffff
    80005706:	dbc080e7          	jalr	-580(ra) # 800044be <filealloc>
    8000570a:	89aa                	mv	s3,a0
    8000570c:	10050363          	beqz	a0,80005812 <sys_open+0x182>
    80005710:	00000097          	auipc	ra,0x0
    80005714:	902080e7          	jalr	-1790(ra) # 80005012 <fdalloc>
    80005718:	892a                	mv	s2,a0
    8000571a:	0e054763          	bltz	a0,80005808 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    8000571e:	04449703          	lh	a4,68(s1)
    80005722:	478d                	li	a5,3
    80005724:	0cf70563          	beq	a4,a5,800057ee <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005728:	4789                	li	a5,2
    8000572a:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    8000572e:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005732:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005736:	f4c42783          	lw	a5,-180(s0)
    8000573a:	0017c713          	xori	a4,a5,1
    8000573e:	8b05                	andi	a4,a4,1
    80005740:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005744:	0037f713          	andi	a4,a5,3
    80005748:	00e03733          	snez	a4,a4
    8000574c:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005750:	4007f793          	andi	a5,a5,1024
    80005754:	c791                	beqz	a5,80005760 <sys_open+0xd0>
    80005756:	04449703          	lh	a4,68(s1)
    8000575a:	4789                	li	a5,2
    8000575c:	0af70063          	beq	a4,a5,800057fc <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005760:	8526                	mv	a0,s1
    80005762:	ffffe097          	auipc	ra,0xffffe
    80005766:	046080e7          	jalr	70(ra) # 800037a8 <iunlock>
  end_op();
    8000576a:	fffff097          	auipc	ra,0xfffff
    8000576e:	9c6080e7          	jalr	-1594(ra) # 80004130 <end_op>

  return fd;
    80005772:	854a                	mv	a0,s2
}
    80005774:	70ea                	ld	ra,184(sp)
    80005776:	744a                	ld	s0,176(sp)
    80005778:	74aa                	ld	s1,168(sp)
    8000577a:	790a                	ld	s2,160(sp)
    8000577c:	69ea                	ld	s3,152(sp)
    8000577e:	6129                	addi	sp,sp,192
    80005780:	8082                	ret
      end_op();
    80005782:	fffff097          	auipc	ra,0xfffff
    80005786:	9ae080e7          	jalr	-1618(ra) # 80004130 <end_op>
      return -1;
    8000578a:	557d                	li	a0,-1
    8000578c:	b7e5                	j	80005774 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000578e:	f5040513          	addi	a0,s0,-176
    80005792:	ffffe097          	auipc	ra,0xffffe
    80005796:	700080e7          	jalr	1792(ra) # 80003e92 <namei>
    8000579a:	84aa                	mv	s1,a0
    8000579c:	c905                	beqz	a0,800057cc <sys_open+0x13c>
    ilock(ip);
    8000579e:	ffffe097          	auipc	ra,0xffffe
    800057a2:	f48080e7          	jalr	-184(ra) # 800036e6 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800057a6:	04449703          	lh	a4,68(s1)
    800057aa:	4785                	li	a5,1
    800057ac:	f4f711e3          	bne	a4,a5,800056ee <sys_open+0x5e>
    800057b0:	f4c42783          	lw	a5,-180(s0)
    800057b4:	d7b9                	beqz	a5,80005702 <sys_open+0x72>
      iunlockput(ip);
    800057b6:	8526                	mv	a0,s1
    800057b8:	ffffe097          	auipc	ra,0xffffe
    800057bc:	190080e7          	jalr	400(ra) # 80003948 <iunlockput>
      end_op();
    800057c0:	fffff097          	auipc	ra,0xfffff
    800057c4:	970080e7          	jalr	-1680(ra) # 80004130 <end_op>
      return -1;
    800057c8:	557d                	li	a0,-1
    800057ca:	b76d                	j	80005774 <sys_open+0xe4>
      end_op();
    800057cc:	fffff097          	auipc	ra,0xfffff
    800057d0:	964080e7          	jalr	-1692(ra) # 80004130 <end_op>
      return -1;
    800057d4:	557d                	li	a0,-1
    800057d6:	bf79                	j	80005774 <sys_open+0xe4>
    iunlockput(ip);
    800057d8:	8526                	mv	a0,s1
    800057da:	ffffe097          	auipc	ra,0xffffe
    800057de:	16e080e7          	jalr	366(ra) # 80003948 <iunlockput>
    end_op();
    800057e2:	fffff097          	auipc	ra,0xfffff
    800057e6:	94e080e7          	jalr	-1714(ra) # 80004130 <end_op>
    return -1;
    800057ea:	557d                	li	a0,-1
    800057ec:	b761                	j	80005774 <sys_open+0xe4>
    f->type = FD_DEVICE;
    800057ee:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800057f2:	04649783          	lh	a5,70(s1)
    800057f6:	02f99223          	sh	a5,36(s3)
    800057fa:	bf25                	j	80005732 <sys_open+0xa2>
    itrunc(ip);
    800057fc:	8526                	mv	a0,s1
    800057fe:	ffffe097          	auipc	ra,0xffffe
    80005802:	ff6080e7          	jalr	-10(ra) # 800037f4 <itrunc>
    80005806:	bfa9                	j	80005760 <sys_open+0xd0>
      fileclose(f);
    80005808:	854e                	mv	a0,s3
    8000580a:	fffff097          	auipc	ra,0xfffff
    8000580e:	d70080e7          	jalr	-656(ra) # 8000457a <fileclose>
    iunlockput(ip);
    80005812:	8526                	mv	a0,s1
    80005814:	ffffe097          	auipc	ra,0xffffe
    80005818:	134080e7          	jalr	308(ra) # 80003948 <iunlockput>
    end_op();
    8000581c:	fffff097          	auipc	ra,0xfffff
    80005820:	914080e7          	jalr	-1772(ra) # 80004130 <end_op>
    return -1;
    80005824:	557d                	li	a0,-1
    80005826:	b7b9                	j	80005774 <sys_open+0xe4>

0000000080005828 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005828:	7175                	addi	sp,sp,-144
    8000582a:	e506                	sd	ra,136(sp)
    8000582c:	e122                	sd	s0,128(sp)
    8000582e:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005830:	fffff097          	auipc	ra,0xfffff
    80005834:	882080e7          	jalr	-1918(ra) # 800040b2 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005838:	08000613          	li	a2,128
    8000583c:	f7040593          	addi	a1,s0,-144
    80005840:	4501                	li	a0,0
    80005842:	ffffd097          	auipc	ra,0xffffd
    80005846:	360080e7          	jalr	864(ra) # 80002ba2 <argstr>
    8000584a:	02054963          	bltz	a0,8000587c <sys_mkdir+0x54>
    8000584e:	4681                	li	a3,0
    80005850:	4601                	li	a2,0
    80005852:	4585                	li	a1,1
    80005854:	f7040513          	addi	a0,s0,-144
    80005858:	fffff097          	auipc	ra,0xfffff
    8000585c:	7fc080e7          	jalr	2044(ra) # 80005054 <create>
    80005860:	cd11                	beqz	a0,8000587c <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005862:	ffffe097          	auipc	ra,0xffffe
    80005866:	0e6080e7          	jalr	230(ra) # 80003948 <iunlockput>
  end_op();
    8000586a:	fffff097          	auipc	ra,0xfffff
    8000586e:	8c6080e7          	jalr	-1850(ra) # 80004130 <end_op>
  return 0;
    80005872:	4501                	li	a0,0
}
    80005874:	60aa                	ld	ra,136(sp)
    80005876:	640a                	ld	s0,128(sp)
    80005878:	6149                	addi	sp,sp,144
    8000587a:	8082                	ret
    end_op();
    8000587c:	fffff097          	auipc	ra,0xfffff
    80005880:	8b4080e7          	jalr	-1868(ra) # 80004130 <end_op>
    return -1;
    80005884:	557d                	li	a0,-1
    80005886:	b7fd                	j	80005874 <sys_mkdir+0x4c>

0000000080005888 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005888:	7135                	addi	sp,sp,-160
    8000588a:	ed06                	sd	ra,152(sp)
    8000588c:	e922                	sd	s0,144(sp)
    8000588e:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005890:	fffff097          	auipc	ra,0xfffff
    80005894:	822080e7          	jalr	-2014(ra) # 800040b2 <begin_op>
  argint(1, &major);
    80005898:	f6c40593          	addi	a1,s0,-148
    8000589c:	4505                	li	a0,1
    8000589e:	ffffd097          	auipc	ra,0xffffd
    800058a2:	2c4080e7          	jalr	708(ra) # 80002b62 <argint>
  argint(2, &minor);
    800058a6:	f6840593          	addi	a1,s0,-152
    800058aa:	4509                	li	a0,2
    800058ac:	ffffd097          	auipc	ra,0xffffd
    800058b0:	2b6080e7          	jalr	694(ra) # 80002b62 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800058b4:	08000613          	li	a2,128
    800058b8:	f7040593          	addi	a1,s0,-144
    800058bc:	4501                	li	a0,0
    800058be:	ffffd097          	auipc	ra,0xffffd
    800058c2:	2e4080e7          	jalr	740(ra) # 80002ba2 <argstr>
    800058c6:	02054b63          	bltz	a0,800058fc <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800058ca:	f6841683          	lh	a3,-152(s0)
    800058ce:	f6c41603          	lh	a2,-148(s0)
    800058d2:	458d                	li	a1,3
    800058d4:	f7040513          	addi	a0,s0,-144
    800058d8:	fffff097          	auipc	ra,0xfffff
    800058dc:	77c080e7          	jalr	1916(ra) # 80005054 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800058e0:	cd11                	beqz	a0,800058fc <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800058e2:	ffffe097          	auipc	ra,0xffffe
    800058e6:	066080e7          	jalr	102(ra) # 80003948 <iunlockput>
  end_op();
    800058ea:	fffff097          	auipc	ra,0xfffff
    800058ee:	846080e7          	jalr	-1978(ra) # 80004130 <end_op>
  return 0;
    800058f2:	4501                	li	a0,0
}
    800058f4:	60ea                	ld	ra,152(sp)
    800058f6:	644a                	ld	s0,144(sp)
    800058f8:	610d                	addi	sp,sp,160
    800058fa:	8082                	ret
    end_op();
    800058fc:	fffff097          	auipc	ra,0xfffff
    80005900:	834080e7          	jalr	-1996(ra) # 80004130 <end_op>
    return -1;
    80005904:	557d                	li	a0,-1
    80005906:	b7fd                	j	800058f4 <sys_mknod+0x6c>

0000000080005908 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005908:	7135                	addi	sp,sp,-160
    8000590a:	ed06                	sd	ra,152(sp)
    8000590c:	e922                	sd	s0,144(sp)
    8000590e:	e526                	sd	s1,136(sp)
    80005910:	e14a                	sd	s2,128(sp)
    80005912:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005914:	ffffc097          	auipc	ra,0xffffc
    80005918:	098080e7          	jalr	152(ra) # 800019ac <myproc>
    8000591c:	892a                	mv	s2,a0
  
  begin_op();
    8000591e:	ffffe097          	auipc	ra,0xffffe
    80005922:	794080e7          	jalr	1940(ra) # 800040b2 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005926:	08000613          	li	a2,128
    8000592a:	f6040593          	addi	a1,s0,-160
    8000592e:	4501                	li	a0,0
    80005930:	ffffd097          	auipc	ra,0xffffd
    80005934:	272080e7          	jalr	626(ra) # 80002ba2 <argstr>
    80005938:	04054b63          	bltz	a0,8000598e <sys_chdir+0x86>
    8000593c:	f6040513          	addi	a0,s0,-160
    80005940:	ffffe097          	auipc	ra,0xffffe
    80005944:	552080e7          	jalr	1362(ra) # 80003e92 <namei>
    80005948:	84aa                	mv	s1,a0
    8000594a:	c131                	beqz	a0,8000598e <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    8000594c:	ffffe097          	auipc	ra,0xffffe
    80005950:	d9a080e7          	jalr	-614(ra) # 800036e6 <ilock>
  if(ip->type != T_DIR){
    80005954:	04449703          	lh	a4,68(s1)
    80005958:	4785                	li	a5,1
    8000595a:	04f71063          	bne	a4,a5,8000599a <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    8000595e:	8526                	mv	a0,s1
    80005960:	ffffe097          	auipc	ra,0xffffe
    80005964:	e48080e7          	jalr	-440(ra) # 800037a8 <iunlock>
  iput(p->cwd);
    80005968:	15093503          	ld	a0,336(s2)
    8000596c:	ffffe097          	auipc	ra,0xffffe
    80005970:	f34080e7          	jalr	-204(ra) # 800038a0 <iput>
  end_op();
    80005974:	ffffe097          	auipc	ra,0xffffe
    80005978:	7bc080e7          	jalr	1980(ra) # 80004130 <end_op>
  p->cwd = ip;
    8000597c:	14993823          	sd	s1,336(s2)
  return 0;
    80005980:	4501                	li	a0,0
}
    80005982:	60ea                	ld	ra,152(sp)
    80005984:	644a                	ld	s0,144(sp)
    80005986:	64aa                	ld	s1,136(sp)
    80005988:	690a                	ld	s2,128(sp)
    8000598a:	610d                	addi	sp,sp,160
    8000598c:	8082                	ret
    end_op();
    8000598e:	ffffe097          	auipc	ra,0xffffe
    80005992:	7a2080e7          	jalr	1954(ra) # 80004130 <end_op>
    return -1;
    80005996:	557d                	li	a0,-1
    80005998:	b7ed                	j	80005982 <sys_chdir+0x7a>
    iunlockput(ip);
    8000599a:	8526                	mv	a0,s1
    8000599c:	ffffe097          	auipc	ra,0xffffe
    800059a0:	fac080e7          	jalr	-84(ra) # 80003948 <iunlockput>
    end_op();
    800059a4:	ffffe097          	auipc	ra,0xffffe
    800059a8:	78c080e7          	jalr	1932(ra) # 80004130 <end_op>
    return -1;
    800059ac:	557d                	li	a0,-1
    800059ae:	bfd1                	j	80005982 <sys_chdir+0x7a>

00000000800059b0 <sys_exec>:

uint64
sys_exec(void)
{
    800059b0:	7145                	addi	sp,sp,-464
    800059b2:	e786                	sd	ra,456(sp)
    800059b4:	e3a2                	sd	s0,448(sp)
    800059b6:	ff26                	sd	s1,440(sp)
    800059b8:	fb4a                	sd	s2,432(sp)
    800059ba:	f74e                	sd	s3,424(sp)
    800059bc:	f352                	sd	s4,416(sp)
    800059be:	ef56                	sd	s5,408(sp)
    800059c0:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    800059c2:	e3840593          	addi	a1,s0,-456
    800059c6:	4505                	li	a0,1
    800059c8:	ffffd097          	auipc	ra,0xffffd
    800059cc:	1ba080e7          	jalr	442(ra) # 80002b82 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    800059d0:	08000613          	li	a2,128
    800059d4:	f4040593          	addi	a1,s0,-192
    800059d8:	4501                	li	a0,0
    800059da:	ffffd097          	auipc	ra,0xffffd
    800059de:	1c8080e7          	jalr	456(ra) # 80002ba2 <argstr>
    800059e2:	87aa                	mv	a5,a0
    return -1;
    800059e4:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    800059e6:	0c07c363          	bltz	a5,80005aac <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    800059ea:	10000613          	li	a2,256
    800059ee:	4581                	li	a1,0
    800059f0:	e4040513          	addi	a0,s0,-448
    800059f4:	ffffb097          	auipc	ra,0xffffb
    800059f8:	2de080e7          	jalr	734(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800059fc:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005a00:	89a6                	mv	s3,s1
    80005a02:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005a04:	02000a13          	li	s4,32
    80005a08:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005a0c:	00391513          	slli	a0,s2,0x3
    80005a10:	e3040593          	addi	a1,s0,-464
    80005a14:	e3843783          	ld	a5,-456(s0)
    80005a18:	953e                	add	a0,a0,a5
    80005a1a:	ffffd097          	auipc	ra,0xffffd
    80005a1e:	0aa080e7          	jalr	170(ra) # 80002ac4 <fetchaddr>
    80005a22:	02054a63          	bltz	a0,80005a56 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005a26:	e3043783          	ld	a5,-464(s0)
    80005a2a:	c3b9                	beqz	a5,80005a70 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005a2c:	ffffb097          	auipc	ra,0xffffb
    80005a30:	0ba080e7          	jalr	186(ra) # 80000ae6 <kalloc>
    80005a34:	85aa                	mv	a1,a0
    80005a36:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005a3a:	cd11                	beqz	a0,80005a56 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005a3c:	6605                	lui	a2,0x1
    80005a3e:	e3043503          	ld	a0,-464(s0)
    80005a42:	ffffd097          	auipc	ra,0xffffd
    80005a46:	0d4080e7          	jalr	212(ra) # 80002b16 <fetchstr>
    80005a4a:	00054663          	bltz	a0,80005a56 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005a4e:	0905                	addi	s2,s2,1
    80005a50:	09a1                	addi	s3,s3,8
    80005a52:	fb491be3          	bne	s2,s4,80005a08 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a56:	f4040913          	addi	s2,s0,-192
    80005a5a:	6088                	ld	a0,0(s1)
    80005a5c:	c539                	beqz	a0,80005aaa <sys_exec+0xfa>
    kfree(argv[i]);
    80005a5e:	ffffb097          	auipc	ra,0xffffb
    80005a62:	f8a080e7          	jalr	-118(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a66:	04a1                	addi	s1,s1,8
    80005a68:	ff2499e3          	bne	s1,s2,80005a5a <sys_exec+0xaa>
  return -1;
    80005a6c:	557d                	li	a0,-1
    80005a6e:	a83d                	j	80005aac <sys_exec+0xfc>
      argv[i] = 0;
    80005a70:	0a8e                	slli	s5,s5,0x3
    80005a72:	fc0a8793          	addi	a5,s5,-64
    80005a76:	00878ab3          	add	s5,a5,s0
    80005a7a:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005a7e:	e4040593          	addi	a1,s0,-448
    80005a82:	f4040513          	addi	a0,s0,-192
    80005a86:	fffff097          	auipc	ra,0xfffff
    80005a8a:	16e080e7          	jalr	366(ra) # 80004bf4 <exec>
    80005a8e:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a90:	f4040993          	addi	s3,s0,-192
    80005a94:	6088                	ld	a0,0(s1)
    80005a96:	c901                	beqz	a0,80005aa6 <sys_exec+0xf6>
    kfree(argv[i]);
    80005a98:	ffffb097          	auipc	ra,0xffffb
    80005a9c:	f50080e7          	jalr	-176(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005aa0:	04a1                	addi	s1,s1,8
    80005aa2:	ff3499e3          	bne	s1,s3,80005a94 <sys_exec+0xe4>
  return ret;
    80005aa6:	854a                	mv	a0,s2
    80005aa8:	a011                	j	80005aac <sys_exec+0xfc>
  return -1;
    80005aaa:	557d                	li	a0,-1
}
    80005aac:	60be                	ld	ra,456(sp)
    80005aae:	641e                	ld	s0,448(sp)
    80005ab0:	74fa                	ld	s1,440(sp)
    80005ab2:	795a                	ld	s2,432(sp)
    80005ab4:	79ba                	ld	s3,424(sp)
    80005ab6:	7a1a                	ld	s4,416(sp)
    80005ab8:	6afa                	ld	s5,408(sp)
    80005aba:	6179                	addi	sp,sp,464
    80005abc:	8082                	ret

0000000080005abe <sys_pipe>:

uint64
sys_pipe(void)
{
    80005abe:	7139                	addi	sp,sp,-64
    80005ac0:	fc06                	sd	ra,56(sp)
    80005ac2:	f822                	sd	s0,48(sp)
    80005ac4:	f426                	sd	s1,40(sp)
    80005ac6:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005ac8:	ffffc097          	auipc	ra,0xffffc
    80005acc:	ee4080e7          	jalr	-284(ra) # 800019ac <myproc>
    80005ad0:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005ad2:	fd840593          	addi	a1,s0,-40
    80005ad6:	4501                	li	a0,0
    80005ad8:	ffffd097          	auipc	ra,0xffffd
    80005adc:	0aa080e7          	jalr	170(ra) # 80002b82 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005ae0:	fc840593          	addi	a1,s0,-56
    80005ae4:	fd040513          	addi	a0,s0,-48
    80005ae8:	fffff097          	auipc	ra,0xfffff
    80005aec:	dc2080e7          	jalr	-574(ra) # 800048aa <pipealloc>
    return -1;
    80005af0:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005af2:	0c054463          	bltz	a0,80005bba <sys_pipe+0xfc>
  fd0 = -1;
    80005af6:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005afa:	fd043503          	ld	a0,-48(s0)
    80005afe:	fffff097          	auipc	ra,0xfffff
    80005b02:	514080e7          	jalr	1300(ra) # 80005012 <fdalloc>
    80005b06:	fca42223          	sw	a0,-60(s0)
    80005b0a:	08054b63          	bltz	a0,80005ba0 <sys_pipe+0xe2>
    80005b0e:	fc843503          	ld	a0,-56(s0)
    80005b12:	fffff097          	auipc	ra,0xfffff
    80005b16:	500080e7          	jalr	1280(ra) # 80005012 <fdalloc>
    80005b1a:	fca42023          	sw	a0,-64(s0)
    80005b1e:	06054863          	bltz	a0,80005b8e <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b22:	4691                	li	a3,4
    80005b24:	fc440613          	addi	a2,s0,-60
    80005b28:	fd843583          	ld	a1,-40(s0)
    80005b2c:	68a8                	ld	a0,80(s1)
    80005b2e:	ffffc097          	auipc	ra,0xffffc
    80005b32:	b3e080e7          	jalr	-1218(ra) # 8000166c <copyout>
    80005b36:	02054063          	bltz	a0,80005b56 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005b3a:	4691                	li	a3,4
    80005b3c:	fc040613          	addi	a2,s0,-64
    80005b40:	fd843583          	ld	a1,-40(s0)
    80005b44:	0591                	addi	a1,a1,4
    80005b46:	68a8                	ld	a0,80(s1)
    80005b48:	ffffc097          	auipc	ra,0xffffc
    80005b4c:	b24080e7          	jalr	-1244(ra) # 8000166c <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005b50:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b52:	06055463          	bgez	a0,80005bba <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005b56:	fc442783          	lw	a5,-60(s0)
    80005b5a:	07e9                	addi	a5,a5,26
    80005b5c:	078e                	slli	a5,a5,0x3
    80005b5e:	97a6                	add	a5,a5,s1
    80005b60:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005b64:	fc042783          	lw	a5,-64(s0)
    80005b68:	07e9                	addi	a5,a5,26
    80005b6a:	078e                	slli	a5,a5,0x3
    80005b6c:	94be                	add	s1,s1,a5
    80005b6e:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005b72:	fd043503          	ld	a0,-48(s0)
    80005b76:	fffff097          	auipc	ra,0xfffff
    80005b7a:	a04080e7          	jalr	-1532(ra) # 8000457a <fileclose>
    fileclose(wf);
    80005b7e:	fc843503          	ld	a0,-56(s0)
    80005b82:	fffff097          	auipc	ra,0xfffff
    80005b86:	9f8080e7          	jalr	-1544(ra) # 8000457a <fileclose>
    return -1;
    80005b8a:	57fd                	li	a5,-1
    80005b8c:	a03d                	j	80005bba <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005b8e:	fc442783          	lw	a5,-60(s0)
    80005b92:	0007c763          	bltz	a5,80005ba0 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005b96:	07e9                	addi	a5,a5,26
    80005b98:	078e                	slli	a5,a5,0x3
    80005b9a:	97a6                	add	a5,a5,s1
    80005b9c:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005ba0:	fd043503          	ld	a0,-48(s0)
    80005ba4:	fffff097          	auipc	ra,0xfffff
    80005ba8:	9d6080e7          	jalr	-1578(ra) # 8000457a <fileclose>
    fileclose(wf);
    80005bac:	fc843503          	ld	a0,-56(s0)
    80005bb0:	fffff097          	auipc	ra,0xfffff
    80005bb4:	9ca080e7          	jalr	-1590(ra) # 8000457a <fileclose>
    return -1;
    80005bb8:	57fd                	li	a5,-1
}
    80005bba:	853e                	mv	a0,a5
    80005bbc:	70e2                	ld	ra,56(sp)
    80005bbe:	7442                	ld	s0,48(sp)
    80005bc0:	74a2                	ld	s1,40(sp)
    80005bc2:	6121                	addi	sp,sp,64
    80005bc4:	8082                	ret
	...

0000000080005bd0 <kernelvec>:
    80005bd0:	7111                	addi	sp,sp,-256
    80005bd2:	e006                	sd	ra,0(sp)
    80005bd4:	e40a                	sd	sp,8(sp)
    80005bd6:	e80e                	sd	gp,16(sp)
    80005bd8:	ec12                	sd	tp,24(sp)
    80005bda:	f016                	sd	t0,32(sp)
    80005bdc:	f41a                	sd	t1,40(sp)
    80005bde:	f81e                	sd	t2,48(sp)
    80005be0:	fc22                	sd	s0,56(sp)
    80005be2:	e0a6                	sd	s1,64(sp)
    80005be4:	e4aa                	sd	a0,72(sp)
    80005be6:	e8ae                	sd	a1,80(sp)
    80005be8:	ecb2                	sd	a2,88(sp)
    80005bea:	f0b6                	sd	a3,96(sp)
    80005bec:	f4ba                	sd	a4,104(sp)
    80005bee:	f8be                	sd	a5,112(sp)
    80005bf0:	fcc2                	sd	a6,120(sp)
    80005bf2:	e146                	sd	a7,128(sp)
    80005bf4:	e54a                	sd	s2,136(sp)
    80005bf6:	e94e                	sd	s3,144(sp)
    80005bf8:	ed52                	sd	s4,152(sp)
    80005bfa:	f156                	sd	s5,160(sp)
    80005bfc:	f55a                	sd	s6,168(sp)
    80005bfe:	f95e                	sd	s7,176(sp)
    80005c00:	fd62                	sd	s8,184(sp)
    80005c02:	e1e6                	sd	s9,192(sp)
    80005c04:	e5ea                	sd	s10,200(sp)
    80005c06:	e9ee                	sd	s11,208(sp)
    80005c08:	edf2                	sd	t3,216(sp)
    80005c0a:	f1f6                	sd	t4,224(sp)
    80005c0c:	f5fa                	sd	t5,232(sp)
    80005c0e:	f9fe                	sd	t6,240(sp)
    80005c10:	d81fc0ef          	jal	ra,80002990 <kerneltrap>
    80005c14:	6082                	ld	ra,0(sp)
    80005c16:	6122                	ld	sp,8(sp)
    80005c18:	61c2                	ld	gp,16(sp)
    80005c1a:	7282                	ld	t0,32(sp)
    80005c1c:	7322                	ld	t1,40(sp)
    80005c1e:	73c2                	ld	t2,48(sp)
    80005c20:	7462                	ld	s0,56(sp)
    80005c22:	6486                	ld	s1,64(sp)
    80005c24:	6526                	ld	a0,72(sp)
    80005c26:	65c6                	ld	a1,80(sp)
    80005c28:	6666                	ld	a2,88(sp)
    80005c2a:	7686                	ld	a3,96(sp)
    80005c2c:	7726                	ld	a4,104(sp)
    80005c2e:	77c6                	ld	a5,112(sp)
    80005c30:	7866                	ld	a6,120(sp)
    80005c32:	688a                	ld	a7,128(sp)
    80005c34:	692a                	ld	s2,136(sp)
    80005c36:	69ca                	ld	s3,144(sp)
    80005c38:	6a6a                	ld	s4,152(sp)
    80005c3a:	7a8a                	ld	s5,160(sp)
    80005c3c:	7b2a                	ld	s6,168(sp)
    80005c3e:	7bca                	ld	s7,176(sp)
    80005c40:	7c6a                	ld	s8,184(sp)
    80005c42:	6c8e                	ld	s9,192(sp)
    80005c44:	6d2e                	ld	s10,200(sp)
    80005c46:	6dce                	ld	s11,208(sp)
    80005c48:	6e6e                	ld	t3,216(sp)
    80005c4a:	7e8e                	ld	t4,224(sp)
    80005c4c:	7f2e                	ld	t5,232(sp)
    80005c4e:	7fce                	ld	t6,240(sp)
    80005c50:	6111                	addi	sp,sp,256
    80005c52:	10200073          	sret
    80005c56:	00000013          	nop
    80005c5a:	00000013          	nop
    80005c5e:	0001                	nop

0000000080005c60 <timervec>:
    80005c60:	34051573          	csrrw	a0,mscratch,a0
    80005c64:	e10c                	sd	a1,0(a0)
    80005c66:	e510                	sd	a2,8(a0)
    80005c68:	e914                	sd	a3,16(a0)
    80005c6a:	6d0c                	ld	a1,24(a0)
    80005c6c:	7110                	ld	a2,32(a0)
    80005c6e:	6194                	ld	a3,0(a1)
    80005c70:	96b2                	add	a3,a3,a2
    80005c72:	e194                	sd	a3,0(a1)
    80005c74:	4589                	li	a1,2
    80005c76:	14459073          	csrw	sip,a1
    80005c7a:	6914                	ld	a3,16(a0)
    80005c7c:	6510                	ld	a2,8(a0)
    80005c7e:	610c                	ld	a1,0(a0)
    80005c80:	34051573          	csrrw	a0,mscratch,a0
    80005c84:	30200073          	mret
	...

0000000080005c8a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005c8a:	1141                	addi	sp,sp,-16
    80005c8c:	e422                	sd	s0,8(sp)
    80005c8e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005c90:	0c0007b7          	lui	a5,0xc000
    80005c94:	4705                	li	a4,1
    80005c96:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005c98:	c3d8                	sw	a4,4(a5)
}
    80005c9a:	6422                	ld	s0,8(sp)
    80005c9c:	0141                	addi	sp,sp,16
    80005c9e:	8082                	ret

0000000080005ca0 <plicinithart>:

void
plicinithart(void)
{
    80005ca0:	1141                	addi	sp,sp,-16
    80005ca2:	e406                	sd	ra,8(sp)
    80005ca4:	e022                	sd	s0,0(sp)
    80005ca6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005ca8:	ffffc097          	auipc	ra,0xffffc
    80005cac:	cd8080e7          	jalr	-808(ra) # 80001980 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005cb0:	0085171b          	slliw	a4,a0,0x8
    80005cb4:	0c0027b7          	lui	a5,0xc002
    80005cb8:	97ba                	add	a5,a5,a4
    80005cba:	40200713          	li	a4,1026
    80005cbe:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005cc2:	00d5151b          	slliw	a0,a0,0xd
    80005cc6:	0c2017b7          	lui	a5,0xc201
    80005cca:	97aa                	add	a5,a5,a0
    80005ccc:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005cd0:	60a2                	ld	ra,8(sp)
    80005cd2:	6402                	ld	s0,0(sp)
    80005cd4:	0141                	addi	sp,sp,16
    80005cd6:	8082                	ret

0000000080005cd8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005cd8:	1141                	addi	sp,sp,-16
    80005cda:	e406                	sd	ra,8(sp)
    80005cdc:	e022                	sd	s0,0(sp)
    80005cde:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005ce0:	ffffc097          	auipc	ra,0xffffc
    80005ce4:	ca0080e7          	jalr	-864(ra) # 80001980 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005ce8:	00d5151b          	slliw	a0,a0,0xd
    80005cec:	0c2017b7          	lui	a5,0xc201
    80005cf0:	97aa                	add	a5,a5,a0
  return irq;
}
    80005cf2:	43c8                	lw	a0,4(a5)
    80005cf4:	60a2                	ld	ra,8(sp)
    80005cf6:	6402                	ld	s0,0(sp)
    80005cf8:	0141                	addi	sp,sp,16
    80005cfa:	8082                	ret

0000000080005cfc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005cfc:	1101                	addi	sp,sp,-32
    80005cfe:	ec06                	sd	ra,24(sp)
    80005d00:	e822                	sd	s0,16(sp)
    80005d02:	e426                	sd	s1,8(sp)
    80005d04:	1000                	addi	s0,sp,32
    80005d06:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005d08:	ffffc097          	auipc	ra,0xffffc
    80005d0c:	c78080e7          	jalr	-904(ra) # 80001980 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005d10:	00d5151b          	slliw	a0,a0,0xd
    80005d14:	0c2017b7          	lui	a5,0xc201
    80005d18:	97aa                	add	a5,a5,a0
    80005d1a:	c3c4                	sw	s1,4(a5)
}
    80005d1c:	60e2                	ld	ra,24(sp)
    80005d1e:	6442                	ld	s0,16(sp)
    80005d20:	64a2                	ld	s1,8(sp)
    80005d22:	6105                	addi	sp,sp,32
    80005d24:	8082                	ret

0000000080005d26 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005d26:	1141                	addi	sp,sp,-16
    80005d28:	e406                	sd	ra,8(sp)
    80005d2a:	e022                	sd	s0,0(sp)
    80005d2c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005d2e:	479d                	li	a5,7
    80005d30:	04a7cc63          	blt	a5,a0,80005d88 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005d34:	0001c797          	auipc	a5,0x1c
    80005d38:	f6c78793          	addi	a5,a5,-148 # 80021ca0 <disk>
    80005d3c:	97aa                	add	a5,a5,a0
    80005d3e:	0187c783          	lbu	a5,24(a5)
    80005d42:	ebb9                	bnez	a5,80005d98 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005d44:	00451693          	slli	a3,a0,0x4
    80005d48:	0001c797          	auipc	a5,0x1c
    80005d4c:	f5878793          	addi	a5,a5,-168 # 80021ca0 <disk>
    80005d50:	6398                	ld	a4,0(a5)
    80005d52:	9736                	add	a4,a4,a3
    80005d54:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80005d58:	6398                	ld	a4,0(a5)
    80005d5a:	9736                	add	a4,a4,a3
    80005d5c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005d60:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005d64:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005d68:	97aa                	add	a5,a5,a0
    80005d6a:	4705                	li	a4,1
    80005d6c:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80005d70:	0001c517          	auipc	a0,0x1c
    80005d74:	f4850513          	addi	a0,a0,-184 # 80021cb8 <disk+0x18>
    80005d78:	ffffc097          	auipc	ra,0xffffc
    80005d7c:	340080e7          	jalr	832(ra) # 800020b8 <wakeup>
}
    80005d80:	60a2                	ld	ra,8(sp)
    80005d82:	6402                	ld	s0,0(sp)
    80005d84:	0141                	addi	sp,sp,16
    80005d86:	8082                	ret
    panic("free_desc 1");
    80005d88:	00003517          	auipc	a0,0x3
    80005d8c:	a3850513          	addi	a0,a0,-1480 # 800087c0 <syscalls+0x2f8>
    80005d90:	ffffa097          	auipc	ra,0xffffa
    80005d94:	7b0080e7          	jalr	1968(ra) # 80000540 <panic>
    panic("free_desc 2");
    80005d98:	00003517          	auipc	a0,0x3
    80005d9c:	a3850513          	addi	a0,a0,-1480 # 800087d0 <syscalls+0x308>
    80005da0:	ffffa097          	auipc	ra,0xffffa
    80005da4:	7a0080e7          	jalr	1952(ra) # 80000540 <panic>

0000000080005da8 <virtio_disk_init>:
{
    80005da8:	1101                	addi	sp,sp,-32
    80005daa:	ec06                	sd	ra,24(sp)
    80005dac:	e822                	sd	s0,16(sp)
    80005dae:	e426                	sd	s1,8(sp)
    80005db0:	e04a                	sd	s2,0(sp)
    80005db2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005db4:	00003597          	auipc	a1,0x3
    80005db8:	a2c58593          	addi	a1,a1,-1492 # 800087e0 <syscalls+0x318>
    80005dbc:	0001c517          	auipc	a0,0x1c
    80005dc0:	00c50513          	addi	a0,a0,12 # 80021dc8 <disk+0x128>
    80005dc4:	ffffb097          	auipc	ra,0xffffb
    80005dc8:	d82080e7          	jalr	-638(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005dcc:	100017b7          	lui	a5,0x10001
    80005dd0:	4398                	lw	a4,0(a5)
    80005dd2:	2701                	sext.w	a4,a4
    80005dd4:	747277b7          	lui	a5,0x74727
    80005dd8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005ddc:	14f71b63          	bne	a4,a5,80005f32 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005de0:	100017b7          	lui	a5,0x10001
    80005de4:	43dc                	lw	a5,4(a5)
    80005de6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005de8:	4709                	li	a4,2
    80005dea:	14e79463          	bne	a5,a4,80005f32 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005dee:	100017b7          	lui	a5,0x10001
    80005df2:	479c                	lw	a5,8(a5)
    80005df4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005df6:	12e79e63          	bne	a5,a4,80005f32 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005dfa:	100017b7          	lui	a5,0x10001
    80005dfe:	47d8                	lw	a4,12(a5)
    80005e00:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e02:	554d47b7          	lui	a5,0x554d4
    80005e06:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005e0a:	12f71463          	bne	a4,a5,80005f32 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e0e:	100017b7          	lui	a5,0x10001
    80005e12:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e16:	4705                	li	a4,1
    80005e18:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e1a:	470d                	li	a4,3
    80005e1c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005e1e:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005e20:	c7ffe6b7          	lui	a3,0xc7ffe
    80005e24:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fdc97f>
    80005e28:	8f75                	and	a4,a4,a3
    80005e2a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e2c:	472d                	li	a4,11
    80005e2e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80005e30:	5bbc                	lw	a5,112(a5)
    80005e32:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005e36:	8ba1                	andi	a5,a5,8
    80005e38:	10078563          	beqz	a5,80005f42 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005e3c:	100017b7          	lui	a5,0x10001
    80005e40:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80005e44:	43fc                	lw	a5,68(a5)
    80005e46:	2781                	sext.w	a5,a5
    80005e48:	10079563          	bnez	a5,80005f52 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005e4c:	100017b7          	lui	a5,0x10001
    80005e50:	5bdc                	lw	a5,52(a5)
    80005e52:	2781                	sext.w	a5,a5
  if(max == 0)
    80005e54:	10078763          	beqz	a5,80005f62 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80005e58:	471d                	li	a4,7
    80005e5a:	10f77c63          	bgeu	a4,a5,80005f72 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    80005e5e:	ffffb097          	auipc	ra,0xffffb
    80005e62:	c88080e7          	jalr	-888(ra) # 80000ae6 <kalloc>
    80005e66:	0001c497          	auipc	s1,0x1c
    80005e6a:	e3a48493          	addi	s1,s1,-454 # 80021ca0 <disk>
    80005e6e:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80005e70:	ffffb097          	auipc	ra,0xffffb
    80005e74:	c76080e7          	jalr	-906(ra) # 80000ae6 <kalloc>
    80005e78:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    80005e7a:	ffffb097          	auipc	ra,0xffffb
    80005e7e:	c6c080e7          	jalr	-916(ra) # 80000ae6 <kalloc>
    80005e82:	87aa                	mv	a5,a0
    80005e84:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80005e86:	6088                	ld	a0,0(s1)
    80005e88:	cd6d                	beqz	a0,80005f82 <virtio_disk_init+0x1da>
    80005e8a:	0001c717          	auipc	a4,0x1c
    80005e8e:	e1e73703          	ld	a4,-482(a4) # 80021ca8 <disk+0x8>
    80005e92:	cb65                	beqz	a4,80005f82 <virtio_disk_init+0x1da>
    80005e94:	c7fd                	beqz	a5,80005f82 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80005e96:	6605                	lui	a2,0x1
    80005e98:	4581                	li	a1,0
    80005e9a:	ffffb097          	auipc	ra,0xffffb
    80005e9e:	e38080e7          	jalr	-456(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    80005ea2:	0001c497          	auipc	s1,0x1c
    80005ea6:	dfe48493          	addi	s1,s1,-514 # 80021ca0 <disk>
    80005eaa:	6605                	lui	a2,0x1
    80005eac:	4581                	li	a1,0
    80005eae:	6488                	ld	a0,8(s1)
    80005eb0:	ffffb097          	auipc	ra,0xffffb
    80005eb4:	e22080e7          	jalr	-478(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    80005eb8:	6605                	lui	a2,0x1
    80005eba:	4581                	li	a1,0
    80005ebc:	6888                	ld	a0,16(s1)
    80005ebe:	ffffb097          	auipc	ra,0xffffb
    80005ec2:	e14080e7          	jalr	-492(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005ec6:	100017b7          	lui	a5,0x10001
    80005eca:	4721                	li	a4,8
    80005ecc:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80005ece:	4098                	lw	a4,0(s1)
    80005ed0:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80005ed4:	40d8                	lw	a4,4(s1)
    80005ed6:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80005eda:	6498                	ld	a4,8(s1)
    80005edc:	0007069b          	sext.w	a3,a4
    80005ee0:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80005ee4:	9701                	srai	a4,a4,0x20
    80005ee6:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80005eea:	6898                	ld	a4,16(s1)
    80005eec:	0007069b          	sext.w	a3,a4
    80005ef0:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80005ef4:	9701                	srai	a4,a4,0x20
    80005ef6:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80005efa:	4705                	li	a4,1
    80005efc:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80005efe:	00e48c23          	sb	a4,24(s1)
    80005f02:	00e48ca3          	sb	a4,25(s1)
    80005f06:	00e48d23          	sb	a4,26(s1)
    80005f0a:	00e48da3          	sb	a4,27(s1)
    80005f0e:	00e48e23          	sb	a4,28(s1)
    80005f12:	00e48ea3          	sb	a4,29(s1)
    80005f16:	00e48f23          	sb	a4,30(s1)
    80005f1a:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80005f1e:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f22:	0727a823          	sw	s2,112(a5)
}
    80005f26:	60e2                	ld	ra,24(sp)
    80005f28:	6442                	ld	s0,16(sp)
    80005f2a:	64a2                	ld	s1,8(sp)
    80005f2c:	6902                	ld	s2,0(sp)
    80005f2e:	6105                	addi	sp,sp,32
    80005f30:	8082                	ret
    panic("could not find virtio disk");
    80005f32:	00003517          	auipc	a0,0x3
    80005f36:	8be50513          	addi	a0,a0,-1858 # 800087f0 <syscalls+0x328>
    80005f3a:	ffffa097          	auipc	ra,0xffffa
    80005f3e:	606080e7          	jalr	1542(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    80005f42:	00003517          	auipc	a0,0x3
    80005f46:	8ce50513          	addi	a0,a0,-1842 # 80008810 <syscalls+0x348>
    80005f4a:	ffffa097          	auipc	ra,0xffffa
    80005f4e:	5f6080e7          	jalr	1526(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    80005f52:	00003517          	auipc	a0,0x3
    80005f56:	8de50513          	addi	a0,a0,-1826 # 80008830 <syscalls+0x368>
    80005f5a:	ffffa097          	auipc	ra,0xffffa
    80005f5e:	5e6080e7          	jalr	1510(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    80005f62:	00003517          	auipc	a0,0x3
    80005f66:	8ee50513          	addi	a0,a0,-1810 # 80008850 <syscalls+0x388>
    80005f6a:	ffffa097          	auipc	ra,0xffffa
    80005f6e:	5d6080e7          	jalr	1494(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    80005f72:	00003517          	auipc	a0,0x3
    80005f76:	8fe50513          	addi	a0,a0,-1794 # 80008870 <syscalls+0x3a8>
    80005f7a:	ffffa097          	auipc	ra,0xffffa
    80005f7e:	5c6080e7          	jalr	1478(ra) # 80000540 <panic>
    panic("virtio disk kalloc");
    80005f82:	00003517          	auipc	a0,0x3
    80005f86:	90e50513          	addi	a0,a0,-1778 # 80008890 <syscalls+0x3c8>
    80005f8a:	ffffa097          	auipc	ra,0xffffa
    80005f8e:	5b6080e7          	jalr	1462(ra) # 80000540 <panic>

0000000080005f92 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005f92:	7119                	addi	sp,sp,-128
    80005f94:	fc86                	sd	ra,120(sp)
    80005f96:	f8a2                	sd	s0,112(sp)
    80005f98:	f4a6                	sd	s1,104(sp)
    80005f9a:	f0ca                	sd	s2,96(sp)
    80005f9c:	ecce                	sd	s3,88(sp)
    80005f9e:	e8d2                	sd	s4,80(sp)
    80005fa0:	e4d6                	sd	s5,72(sp)
    80005fa2:	e0da                	sd	s6,64(sp)
    80005fa4:	fc5e                	sd	s7,56(sp)
    80005fa6:	f862                	sd	s8,48(sp)
    80005fa8:	f466                	sd	s9,40(sp)
    80005faa:	f06a                	sd	s10,32(sp)
    80005fac:	ec6e                	sd	s11,24(sp)
    80005fae:	0100                	addi	s0,sp,128
    80005fb0:	8aaa                	mv	s5,a0
    80005fb2:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005fb4:	00c52d03          	lw	s10,12(a0)
    80005fb8:	001d1d1b          	slliw	s10,s10,0x1
    80005fbc:	1d02                	slli	s10,s10,0x20
    80005fbe:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80005fc2:	0001c517          	auipc	a0,0x1c
    80005fc6:	e0650513          	addi	a0,a0,-506 # 80021dc8 <disk+0x128>
    80005fca:	ffffb097          	auipc	ra,0xffffb
    80005fce:	c0c080e7          	jalr	-1012(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    80005fd2:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005fd4:	44a1                	li	s1,8
      disk.free[i] = 0;
    80005fd6:	0001cb97          	auipc	s7,0x1c
    80005fda:	ccab8b93          	addi	s7,s7,-822 # 80021ca0 <disk>
  for(int i = 0; i < 3; i++){
    80005fde:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005fe0:	0001cc97          	auipc	s9,0x1c
    80005fe4:	de8c8c93          	addi	s9,s9,-536 # 80021dc8 <disk+0x128>
    80005fe8:	a08d                	j	8000604a <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    80005fea:	00fb8733          	add	a4,s7,a5
    80005fee:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80005ff2:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80005ff4:	0207c563          	bltz	a5,8000601e <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    80005ff8:	2905                	addiw	s2,s2,1
    80005ffa:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    80005ffc:	05690c63          	beq	s2,s6,80006054 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006000:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006002:	0001c717          	auipc	a4,0x1c
    80006006:	c9e70713          	addi	a4,a4,-866 # 80021ca0 <disk>
    8000600a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000600c:	01874683          	lbu	a3,24(a4)
    80006010:	fee9                	bnez	a3,80005fea <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006012:	2785                	addiw	a5,a5,1
    80006014:	0705                	addi	a4,a4,1
    80006016:	fe979be3          	bne	a5,s1,8000600c <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    8000601a:	57fd                	li	a5,-1
    8000601c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000601e:	01205d63          	blez	s2,80006038 <virtio_disk_rw+0xa6>
    80006022:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006024:	000a2503          	lw	a0,0(s4)
    80006028:	00000097          	auipc	ra,0x0
    8000602c:	cfe080e7          	jalr	-770(ra) # 80005d26 <free_desc>
      for(int j = 0; j < i; j++)
    80006030:	2d85                	addiw	s11,s11,1
    80006032:	0a11                	addi	s4,s4,4
    80006034:	ff2d98e3          	bne	s11,s2,80006024 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006038:	85e6                	mv	a1,s9
    8000603a:	0001c517          	auipc	a0,0x1c
    8000603e:	c7e50513          	addi	a0,a0,-898 # 80021cb8 <disk+0x18>
    80006042:	ffffc097          	auipc	ra,0xffffc
    80006046:	012080e7          	jalr	18(ra) # 80002054 <sleep>
  for(int i = 0; i < 3; i++){
    8000604a:	f8040a13          	addi	s4,s0,-128
{
    8000604e:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006050:	894e                	mv	s2,s3
    80006052:	b77d                	j	80006000 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006054:	f8042503          	lw	a0,-128(s0)
    80006058:	00a50713          	addi	a4,a0,10
    8000605c:	0712                	slli	a4,a4,0x4

  if(write)
    8000605e:	0001c797          	auipc	a5,0x1c
    80006062:	c4278793          	addi	a5,a5,-958 # 80021ca0 <disk>
    80006066:	00e786b3          	add	a3,a5,a4
    8000606a:	01803633          	snez	a2,s8
    8000606e:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006070:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80006074:	01a6b823          	sd	s10,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006078:	f6070613          	addi	a2,a4,-160
    8000607c:	6394                	ld	a3,0(a5)
    8000607e:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006080:	00870593          	addi	a1,a4,8
    80006084:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006086:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006088:	0007b803          	ld	a6,0(a5)
    8000608c:	9642                	add	a2,a2,a6
    8000608e:	46c1                	li	a3,16
    80006090:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006092:	4585                	li	a1,1
    80006094:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    80006098:	f8442683          	lw	a3,-124(s0)
    8000609c:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800060a0:	0692                	slli	a3,a3,0x4
    800060a2:	9836                	add	a6,a6,a3
    800060a4:	058a8613          	addi	a2,s5,88
    800060a8:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    800060ac:	0007b803          	ld	a6,0(a5)
    800060b0:	96c2                	add	a3,a3,a6
    800060b2:	40000613          	li	a2,1024
    800060b6:	c690                	sw	a2,8(a3)
  if(write)
    800060b8:	001c3613          	seqz	a2,s8
    800060bc:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800060c0:	00166613          	ori	a2,a2,1
    800060c4:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800060c8:	f8842603          	lw	a2,-120(s0)
    800060cc:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800060d0:	00250693          	addi	a3,a0,2
    800060d4:	0692                	slli	a3,a3,0x4
    800060d6:	96be                	add	a3,a3,a5
    800060d8:	58fd                	li	a7,-1
    800060da:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800060de:	0612                	slli	a2,a2,0x4
    800060e0:	9832                	add	a6,a6,a2
    800060e2:	f9070713          	addi	a4,a4,-112
    800060e6:	973e                	add	a4,a4,a5
    800060e8:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    800060ec:	6398                	ld	a4,0(a5)
    800060ee:	9732                	add	a4,a4,a2
    800060f0:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800060f2:	4609                	li	a2,2
    800060f4:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    800060f8:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800060fc:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    80006100:	0156b423          	sd	s5,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006104:	6794                	ld	a3,8(a5)
    80006106:	0026d703          	lhu	a4,2(a3)
    8000610a:	8b1d                	andi	a4,a4,7
    8000610c:	0706                	slli	a4,a4,0x1
    8000610e:	96ba                	add	a3,a3,a4
    80006110:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006114:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006118:	6798                	ld	a4,8(a5)
    8000611a:	00275783          	lhu	a5,2(a4)
    8000611e:	2785                	addiw	a5,a5,1
    80006120:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006124:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006128:	100017b7          	lui	a5,0x10001
    8000612c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006130:	004aa783          	lw	a5,4(s5)
    sleep(b, &disk.vdisk_lock);
    80006134:	0001c917          	auipc	s2,0x1c
    80006138:	c9490913          	addi	s2,s2,-876 # 80021dc8 <disk+0x128>
  while(b->disk == 1) {
    8000613c:	4485                	li	s1,1
    8000613e:	00b79c63          	bne	a5,a1,80006156 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006142:	85ca                	mv	a1,s2
    80006144:	8556                	mv	a0,s5
    80006146:	ffffc097          	auipc	ra,0xffffc
    8000614a:	f0e080e7          	jalr	-242(ra) # 80002054 <sleep>
  while(b->disk == 1) {
    8000614e:	004aa783          	lw	a5,4(s5)
    80006152:	fe9788e3          	beq	a5,s1,80006142 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006156:	f8042903          	lw	s2,-128(s0)
    8000615a:	00290713          	addi	a4,s2,2
    8000615e:	0712                	slli	a4,a4,0x4
    80006160:	0001c797          	auipc	a5,0x1c
    80006164:	b4078793          	addi	a5,a5,-1216 # 80021ca0 <disk>
    80006168:	97ba                	add	a5,a5,a4
    8000616a:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000616e:	0001c997          	auipc	s3,0x1c
    80006172:	b3298993          	addi	s3,s3,-1230 # 80021ca0 <disk>
    80006176:	00491713          	slli	a4,s2,0x4
    8000617a:	0009b783          	ld	a5,0(s3)
    8000617e:	97ba                	add	a5,a5,a4
    80006180:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006184:	854a                	mv	a0,s2
    80006186:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000618a:	00000097          	auipc	ra,0x0
    8000618e:	b9c080e7          	jalr	-1124(ra) # 80005d26 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006192:	8885                	andi	s1,s1,1
    80006194:	f0ed                	bnez	s1,80006176 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006196:	0001c517          	auipc	a0,0x1c
    8000619a:	c3250513          	addi	a0,a0,-974 # 80021dc8 <disk+0x128>
    8000619e:	ffffb097          	auipc	ra,0xffffb
    800061a2:	aec080e7          	jalr	-1300(ra) # 80000c8a <release>
}
    800061a6:	70e6                	ld	ra,120(sp)
    800061a8:	7446                	ld	s0,112(sp)
    800061aa:	74a6                	ld	s1,104(sp)
    800061ac:	7906                	ld	s2,96(sp)
    800061ae:	69e6                	ld	s3,88(sp)
    800061b0:	6a46                	ld	s4,80(sp)
    800061b2:	6aa6                	ld	s5,72(sp)
    800061b4:	6b06                	ld	s6,64(sp)
    800061b6:	7be2                	ld	s7,56(sp)
    800061b8:	7c42                	ld	s8,48(sp)
    800061ba:	7ca2                	ld	s9,40(sp)
    800061bc:	7d02                	ld	s10,32(sp)
    800061be:	6de2                	ld	s11,24(sp)
    800061c0:	6109                	addi	sp,sp,128
    800061c2:	8082                	ret

00000000800061c4 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800061c4:	1101                	addi	sp,sp,-32
    800061c6:	ec06                	sd	ra,24(sp)
    800061c8:	e822                	sd	s0,16(sp)
    800061ca:	e426                	sd	s1,8(sp)
    800061cc:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800061ce:	0001c497          	auipc	s1,0x1c
    800061d2:	ad248493          	addi	s1,s1,-1326 # 80021ca0 <disk>
    800061d6:	0001c517          	auipc	a0,0x1c
    800061da:	bf250513          	addi	a0,a0,-1038 # 80021dc8 <disk+0x128>
    800061de:	ffffb097          	auipc	ra,0xffffb
    800061e2:	9f8080e7          	jalr	-1544(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800061e6:	10001737          	lui	a4,0x10001
    800061ea:	533c                	lw	a5,96(a4)
    800061ec:	8b8d                	andi	a5,a5,3
    800061ee:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800061f0:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800061f4:	689c                	ld	a5,16(s1)
    800061f6:	0204d703          	lhu	a4,32(s1)
    800061fa:	0027d783          	lhu	a5,2(a5)
    800061fe:	04f70863          	beq	a4,a5,8000624e <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006202:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006206:	6898                	ld	a4,16(s1)
    80006208:	0204d783          	lhu	a5,32(s1)
    8000620c:	8b9d                	andi	a5,a5,7
    8000620e:	078e                	slli	a5,a5,0x3
    80006210:	97ba                	add	a5,a5,a4
    80006212:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006214:	00278713          	addi	a4,a5,2
    80006218:	0712                	slli	a4,a4,0x4
    8000621a:	9726                	add	a4,a4,s1
    8000621c:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006220:	e721                	bnez	a4,80006268 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006222:	0789                	addi	a5,a5,2
    80006224:	0792                	slli	a5,a5,0x4
    80006226:	97a6                	add	a5,a5,s1
    80006228:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000622a:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000622e:	ffffc097          	auipc	ra,0xffffc
    80006232:	e8a080e7          	jalr	-374(ra) # 800020b8 <wakeup>

    disk.used_idx += 1;
    80006236:	0204d783          	lhu	a5,32(s1)
    8000623a:	2785                	addiw	a5,a5,1
    8000623c:	17c2                	slli	a5,a5,0x30
    8000623e:	93c1                	srli	a5,a5,0x30
    80006240:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006244:	6898                	ld	a4,16(s1)
    80006246:	00275703          	lhu	a4,2(a4)
    8000624a:	faf71ce3          	bne	a4,a5,80006202 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    8000624e:	0001c517          	auipc	a0,0x1c
    80006252:	b7a50513          	addi	a0,a0,-1158 # 80021dc8 <disk+0x128>
    80006256:	ffffb097          	auipc	ra,0xffffb
    8000625a:	a34080e7          	jalr	-1484(ra) # 80000c8a <release>
}
    8000625e:	60e2                	ld	ra,24(sp)
    80006260:	6442                	ld	s0,16(sp)
    80006262:	64a2                	ld	s1,8(sp)
    80006264:	6105                	addi	sp,sp,32
    80006266:	8082                	ret
      panic("virtio_disk_intr status");
    80006268:	00002517          	auipc	a0,0x2
    8000626c:	64050513          	addi	a0,a0,1600 # 800088a8 <syscalls+0x3e0>
    80006270:	ffffa097          	auipc	ra,0xffffa
    80006274:	2d0080e7          	jalr	720(ra) # 80000540 <panic>
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
