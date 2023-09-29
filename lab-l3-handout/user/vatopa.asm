
user/_vatopa:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
#include "kernel/types.h"
#include "user.h"

int main(int argc, char *argv[])
{
   0:	1101                	addi	sp,sp,-32
   2:	ec06                	sd	ra,24(sp)
   4:	e822                	sd	s0,16(sp)
   6:	e426                	sd	s1,8(sp)
   8:	e04a                	sd	s2,0(sp)
   a:	1000                	addi	s0,sp,32
    uint64 pa = 0;
    if (argc > 3 || argc < 2)
   c:	ffe5071b          	addiw	a4,a0,-2
  10:	4785                	li	a5,1
  12:	02e7e463          	bltu	a5,a4,3a <main+0x3a>
  16:	84ae                	mv	s1,a1
    {
        printf("Usage: vatopa virtual_address [pid]\n");
        exit(1);
    }
    else if (argc == 3)
  18:	478d                	li	a5,3
  1a:	02f50d63          	beq	a0,a5,54 <main+0x54>
        int pid = (*argv[2]) - '0';
        pa = va2pa(atoi(argv[1]), pid);
    } 
    else if (argc == 2)
    {
        int pid = getpid();
  1e:	00000097          	auipc	ra,0x0
  22:	37e080e7          	jalr	894(ra) # 39c <getpid>
  26:	85aa                	mv	a1,a0
        pa = va2pa(*argv[1], pid);
  28:	649c                	ld	a5,8(s1)
  2a:	0007c503          	lbu	a0,0(a5)
  2e:	00000097          	auipc	ra,0x0
  32:	3a6080e7          	jalr	934(ra) # 3d4 <va2pa>
  36:	84aa                	mv	s1,a0
  38:	a835                	j	74 <main+0x74>
        printf("Usage: vatopa virtual_address [pid]\n");
  3a:	00001517          	auipc	a0,0x1
  3e:	81650513          	addi	a0,a0,-2026 # 850 <malloc+0xec>
  42:	00000097          	auipc	ra,0x0
  46:	66a080e7          	jalr	1642(ra) # 6ac <printf>
        exit(1);
  4a:	4505                	li	a0,1
  4c:	00000097          	auipc	ra,0x0
  50:	2d0080e7          	jalr	720(ra) # 31c <exit>
        int pid = (*argv[2]) - '0';
  54:	699c                	ld	a5,16(a1)
  56:	0007c903          	lbu	s2,0(a5)
  5a:	fd09091b          	addiw	s2,s2,-48
        pa = va2pa(atoi(argv[1]), pid);
  5e:	6588                	ld	a0,8(a1)
  60:	00000097          	auipc	ra,0x0
  64:	1c2080e7          	jalr	450(ra) # 222 <atoi>
  68:	85ca                	mv	a1,s2
  6a:	00000097          	auipc	ra,0x0
  6e:	36a080e7          	jalr	874(ra) # 3d4 <va2pa>
  72:	84aa                	mv	s1,a0
    }
    printf("0x%x\n", pa);
  74:	85a6                	mv	a1,s1
  76:	00001517          	auipc	a0,0x1
  7a:	80250513          	addi	a0,a0,-2046 # 878 <malloc+0x114>
  7e:	00000097          	auipc	ra,0x0
  82:	62e080e7          	jalr	1582(ra) # 6ac <printf>
    return pa;
}
  86:	0004851b          	sext.w	a0,s1
  8a:	60e2                	ld	ra,24(sp)
  8c:	6442                	ld	s0,16(sp)
  8e:	64a2                	ld	s1,8(sp)
  90:	6902                	ld	s2,0(sp)
  92:	6105                	addi	sp,sp,32
  94:	8082                	ret

0000000000000096 <_main>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
_main()
{
  96:	1141                	addi	sp,sp,-16
  98:	e406                	sd	ra,8(sp)
  9a:	e022                	sd	s0,0(sp)
  9c:	0800                	addi	s0,sp,16
  extern int main();
  main();
  9e:	00000097          	auipc	ra,0x0
  a2:	f62080e7          	jalr	-158(ra) # 0 <main>
  exit(0);
  a6:	4501                	li	a0,0
  a8:	00000097          	auipc	ra,0x0
  ac:	274080e7          	jalr	628(ra) # 31c <exit>

00000000000000b0 <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
  b0:	1141                	addi	sp,sp,-16
  b2:	e422                	sd	s0,8(sp)
  b4:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  b6:	87aa                	mv	a5,a0
  b8:	0585                	addi	a1,a1,1
  ba:	0785                	addi	a5,a5,1
  bc:	fff5c703          	lbu	a4,-1(a1)
  c0:	fee78fa3          	sb	a4,-1(a5)
  c4:	fb75                	bnez	a4,b8 <strcpy+0x8>
    ;
  return os;
}
  c6:	6422                	ld	s0,8(sp)
  c8:	0141                	addi	sp,sp,16
  ca:	8082                	ret

00000000000000cc <strcmp>:

int
strcmp(const char *p, const char *q)
{
  cc:	1141                	addi	sp,sp,-16
  ce:	e422                	sd	s0,8(sp)
  d0:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
  d2:	00054783          	lbu	a5,0(a0)
  d6:	cb91                	beqz	a5,ea <strcmp+0x1e>
  d8:	0005c703          	lbu	a4,0(a1)
  dc:	00f71763          	bne	a4,a5,ea <strcmp+0x1e>
    p++, q++;
  e0:	0505                	addi	a0,a0,1
  e2:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
  e4:	00054783          	lbu	a5,0(a0)
  e8:	fbe5                	bnez	a5,d8 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
  ea:	0005c503          	lbu	a0,0(a1)
}
  ee:	40a7853b          	subw	a0,a5,a0
  f2:	6422                	ld	s0,8(sp)
  f4:	0141                	addi	sp,sp,16
  f6:	8082                	ret

00000000000000f8 <strlen>:

uint
strlen(const char *s)
{
  f8:	1141                	addi	sp,sp,-16
  fa:	e422                	sd	s0,8(sp)
  fc:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
  fe:	00054783          	lbu	a5,0(a0)
 102:	cf91                	beqz	a5,11e <strlen+0x26>
 104:	0505                	addi	a0,a0,1
 106:	87aa                	mv	a5,a0
 108:	86be                	mv	a3,a5
 10a:	0785                	addi	a5,a5,1
 10c:	fff7c703          	lbu	a4,-1(a5)
 110:	ff65                	bnez	a4,108 <strlen+0x10>
 112:	40a6853b          	subw	a0,a3,a0
 116:	2505                	addiw	a0,a0,1
    ;
  return n;
}
 118:	6422                	ld	s0,8(sp)
 11a:	0141                	addi	sp,sp,16
 11c:	8082                	ret
  for(n = 0; s[n]; n++)
 11e:	4501                	li	a0,0
 120:	bfe5                	j	118 <strlen+0x20>

0000000000000122 <memset>:

void*
memset(void *dst, int c, uint n)
{
 122:	1141                	addi	sp,sp,-16
 124:	e422                	sd	s0,8(sp)
 126:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 128:	ca19                	beqz	a2,13e <memset+0x1c>
 12a:	87aa                	mv	a5,a0
 12c:	1602                	slli	a2,a2,0x20
 12e:	9201                	srli	a2,a2,0x20
 130:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 134:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 138:	0785                	addi	a5,a5,1
 13a:	fee79de3          	bne	a5,a4,134 <memset+0x12>
  }
  return dst;
}
 13e:	6422                	ld	s0,8(sp)
 140:	0141                	addi	sp,sp,16
 142:	8082                	ret

0000000000000144 <strchr>:

char*
strchr(const char *s, char c)
{
 144:	1141                	addi	sp,sp,-16
 146:	e422                	sd	s0,8(sp)
 148:	0800                	addi	s0,sp,16
  for(; *s; s++)
 14a:	00054783          	lbu	a5,0(a0)
 14e:	cb99                	beqz	a5,164 <strchr+0x20>
    if(*s == c)
 150:	00f58763          	beq	a1,a5,15e <strchr+0x1a>
  for(; *s; s++)
 154:	0505                	addi	a0,a0,1
 156:	00054783          	lbu	a5,0(a0)
 15a:	fbfd                	bnez	a5,150 <strchr+0xc>
      return (char*)s;
  return 0;
 15c:	4501                	li	a0,0
}
 15e:	6422                	ld	s0,8(sp)
 160:	0141                	addi	sp,sp,16
 162:	8082                	ret
  return 0;
 164:	4501                	li	a0,0
 166:	bfe5                	j	15e <strchr+0x1a>

0000000000000168 <gets>:

char*
gets(char *buf, int max)
{
 168:	711d                	addi	sp,sp,-96
 16a:	ec86                	sd	ra,88(sp)
 16c:	e8a2                	sd	s0,80(sp)
 16e:	e4a6                	sd	s1,72(sp)
 170:	e0ca                	sd	s2,64(sp)
 172:	fc4e                	sd	s3,56(sp)
 174:	f852                	sd	s4,48(sp)
 176:	f456                	sd	s5,40(sp)
 178:	f05a                	sd	s6,32(sp)
 17a:	ec5e                	sd	s7,24(sp)
 17c:	1080                	addi	s0,sp,96
 17e:	8baa                	mv	s7,a0
 180:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 182:	892a                	mv	s2,a0
 184:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 186:	4aa9                	li	s5,10
 188:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 18a:	89a6                	mv	s3,s1
 18c:	2485                	addiw	s1,s1,1
 18e:	0344d863          	bge	s1,s4,1be <gets+0x56>
    cc = read(0, &c, 1);
 192:	4605                	li	a2,1
 194:	faf40593          	addi	a1,s0,-81
 198:	4501                	li	a0,0
 19a:	00000097          	auipc	ra,0x0
 19e:	19a080e7          	jalr	410(ra) # 334 <read>
    if(cc < 1)
 1a2:	00a05e63          	blez	a0,1be <gets+0x56>
    buf[i++] = c;
 1a6:	faf44783          	lbu	a5,-81(s0)
 1aa:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 1ae:	01578763          	beq	a5,s5,1bc <gets+0x54>
 1b2:	0905                	addi	s2,s2,1
 1b4:	fd679be3          	bne	a5,s6,18a <gets+0x22>
  for(i=0; i+1 < max; ){
 1b8:	89a6                	mv	s3,s1
 1ba:	a011                	j	1be <gets+0x56>
 1bc:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 1be:	99de                	add	s3,s3,s7
 1c0:	00098023          	sb	zero,0(s3)
  return buf;
}
 1c4:	855e                	mv	a0,s7
 1c6:	60e6                	ld	ra,88(sp)
 1c8:	6446                	ld	s0,80(sp)
 1ca:	64a6                	ld	s1,72(sp)
 1cc:	6906                	ld	s2,64(sp)
 1ce:	79e2                	ld	s3,56(sp)
 1d0:	7a42                	ld	s4,48(sp)
 1d2:	7aa2                	ld	s5,40(sp)
 1d4:	7b02                	ld	s6,32(sp)
 1d6:	6be2                	ld	s7,24(sp)
 1d8:	6125                	addi	sp,sp,96
 1da:	8082                	ret

00000000000001dc <stat>:

int
stat(const char *n, struct stat *st)
{
 1dc:	1101                	addi	sp,sp,-32
 1de:	ec06                	sd	ra,24(sp)
 1e0:	e822                	sd	s0,16(sp)
 1e2:	e426                	sd	s1,8(sp)
 1e4:	e04a                	sd	s2,0(sp)
 1e6:	1000                	addi	s0,sp,32
 1e8:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 1ea:	4581                	li	a1,0
 1ec:	00000097          	auipc	ra,0x0
 1f0:	170080e7          	jalr	368(ra) # 35c <open>
  if(fd < 0)
 1f4:	02054563          	bltz	a0,21e <stat+0x42>
 1f8:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 1fa:	85ca                	mv	a1,s2
 1fc:	00000097          	auipc	ra,0x0
 200:	178080e7          	jalr	376(ra) # 374 <fstat>
 204:	892a                	mv	s2,a0
  close(fd);
 206:	8526                	mv	a0,s1
 208:	00000097          	auipc	ra,0x0
 20c:	13c080e7          	jalr	316(ra) # 344 <close>
  return r;
}
 210:	854a                	mv	a0,s2
 212:	60e2                	ld	ra,24(sp)
 214:	6442                	ld	s0,16(sp)
 216:	64a2                	ld	s1,8(sp)
 218:	6902                	ld	s2,0(sp)
 21a:	6105                	addi	sp,sp,32
 21c:	8082                	ret
    return -1;
 21e:	597d                	li	s2,-1
 220:	bfc5                	j	210 <stat+0x34>

0000000000000222 <atoi>:

int
atoi(const char *s)
{
 222:	1141                	addi	sp,sp,-16
 224:	e422                	sd	s0,8(sp)
 226:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 228:	00054683          	lbu	a3,0(a0)
 22c:	fd06879b          	addiw	a5,a3,-48
 230:	0ff7f793          	zext.b	a5,a5
 234:	4625                	li	a2,9
 236:	02f66863          	bltu	a2,a5,266 <atoi+0x44>
 23a:	872a                	mv	a4,a0
  n = 0;
 23c:	4501                	li	a0,0
    n = n*10 + *s++ - '0';
 23e:	0705                	addi	a4,a4,1
 240:	0025179b          	slliw	a5,a0,0x2
 244:	9fa9                	addw	a5,a5,a0
 246:	0017979b          	slliw	a5,a5,0x1
 24a:	9fb5                	addw	a5,a5,a3
 24c:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 250:	00074683          	lbu	a3,0(a4)
 254:	fd06879b          	addiw	a5,a3,-48
 258:	0ff7f793          	zext.b	a5,a5
 25c:	fef671e3          	bgeu	a2,a5,23e <atoi+0x1c>
  return n;
}
 260:	6422                	ld	s0,8(sp)
 262:	0141                	addi	sp,sp,16
 264:	8082                	ret
  n = 0;
 266:	4501                	li	a0,0
 268:	bfe5                	j	260 <atoi+0x3e>

000000000000026a <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 26a:	1141                	addi	sp,sp,-16
 26c:	e422                	sd	s0,8(sp)
 26e:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 270:	02b57463          	bgeu	a0,a1,298 <memmove+0x2e>
    while(n-- > 0)
 274:	00c05f63          	blez	a2,292 <memmove+0x28>
 278:	1602                	slli	a2,a2,0x20
 27a:	9201                	srli	a2,a2,0x20
 27c:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 280:	872a                	mv	a4,a0
      *dst++ = *src++;
 282:	0585                	addi	a1,a1,1
 284:	0705                	addi	a4,a4,1
 286:	fff5c683          	lbu	a3,-1(a1)
 28a:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 28e:	fee79ae3          	bne	a5,a4,282 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 292:	6422                	ld	s0,8(sp)
 294:	0141                	addi	sp,sp,16
 296:	8082                	ret
    dst += n;
 298:	00c50733          	add	a4,a0,a2
    src += n;
 29c:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 29e:	fec05ae3          	blez	a2,292 <memmove+0x28>
 2a2:	fff6079b          	addiw	a5,a2,-1
 2a6:	1782                	slli	a5,a5,0x20
 2a8:	9381                	srli	a5,a5,0x20
 2aa:	fff7c793          	not	a5,a5
 2ae:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 2b0:	15fd                	addi	a1,a1,-1
 2b2:	177d                	addi	a4,a4,-1
 2b4:	0005c683          	lbu	a3,0(a1)
 2b8:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 2bc:	fee79ae3          	bne	a5,a4,2b0 <memmove+0x46>
 2c0:	bfc9                	j	292 <memmove+0x28>

00000000000002c2 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 2c2:	1141                	addi	sp,sp,-16
 2c4:	e422                	sd	s0,8(sp)
 2c6:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 2c8:	ca05                	beqz	a2,2f8 <memcmp+0x36>
 2ca:	fff6069b          	addiw	a3,a2,-1
 2ce:	1682                	slli	a3,a3,0x20
 2d0:	9281                	srli	a3,a3,0x20
 2d2:	0685                	addi	a3,a3,1
 2d4:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 2d6:	00054783          	lbu	a5,0(a0)
 2da:	0005c703          	lbu	a4,0(a1)
 2de:	00e79863          	bne	a5,a4,2ee <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 2e2:	0505                	addi	a0,a0,1
    p2++;
 2e4:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 2e6:	fed518e3          	bne	a0,a3,2d6 <memcmp+0x14>
  }
  return 0;
 2ea:	4501                	li	a0,0
 2ec:	a019                	j	2f2 <memcmp+0x30>
      return *p1 - *p2;
 2ee:	40e7853b          	subw	a0,a5,a4
}
 2f2:	6422                	ld	s0,8(sp)
 2f4:	0141                	addi	sp,sp,16
 2f6:	8082                	ret
  return 0;
 2f8:	4501                	li	a0,0
 2fa:	bfe5                	j	2f2 <memcmp+0x30>

00000000000002fc <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 2fc:	1141                	addi	sp,sp,-16
 2fe:	e406                	sd	ra,8(sp)
 300:	e022                	sd	s0,0(sp)
 302:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 304:	00000097          	auipc	ra,0x0
 308:	f66080e7          	jalr	-154(ra) # 26a <memmove>
}
 30c:	60a2                	ld	ra,8(sp)
 30e:	6402                	ld	s0,0(sp)
 310:	0141                	addi	sp,sp,16
 312:	8082                	ret

0000000000000314 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 314:	4885                	li	a7,1
 ecall
 316:	00000073          	ecall
 ret
 31a:	8082                	ret

000000000000031c <exit>:
.global exit
exit:
 li a7, SYS_exit
 31c:	4889                	li	a7,2
 ecall
 31e:	00000073          	ecall
 ret
 322:	8082                	ret

0000000000000324 <wait>:
.global wait
wait:
 li a7, SYS_wait
 324:	488d                	li	a7,3
 ecall
 326:	00000073          	ecall
 ret
 32a:	8082                	ret

000000000000032c <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 32c:	4891                	li	a7,4
 ecall
 32e:	00000073          	ecall
 ret
 332:	8082                	ret

0000000000000334 <read>:
.global read
read:
 li a7, SYS_read
 334:	4895                	li	a7,5
 ecall
 336:	00000073          	ecall
 ret
 33a:	8082                	ret

000000000000033c <write>:
.global write
write:
 li a7, SYS_write
 33c:	48c1                	li	a7,16
 ecall
 33e:	00000073          	ecall
 ret
 342:	8082                	ret

0000000000000344 <close>:
.global close
close:
 li a7, SYS_close
 344:	48d5                	li	a7,21
 ecall
 346:	00000073          	ecall
 ret
 34a:	8082                	ret

000000000000034c <kill>:
.global kill
kill:
 li a7, SYS_kill
 34c:	4899                	li	a7,6
 ecall
 34e:	00000073          	ecall
 ret
 352:	8082                	ret

0000000000000354 <exec>:
.global exec
exec:
 li a7, SYS_exec
 354:	489d                	li	a7,7
 ecall
 356:	00000073          	ecall
 ret
 35a:	8082                	ret

000000000000035c <open>:
.global open
open:
 li a7, SYS_open
 35c:	48bd                	li	a7,15
 ecall
 35e:	00000073          	ecall
 ret
 362:	8082                	ret

0000000000000364 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 364:	48c5                	li	a7,17
 ecall
 366:	00000073          	ecall
 ret
 36a:	8082                	ret

000000000000036c <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 36c:	48c9                	li	a7,18
 ecall
 36e:	00000073          	ecall
 ret
 372:	8082                	ret

0000000000000374 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 374:	48a1                	li	a7,8
 ecall
 376:	00000073          	ecall
 ret
 37a:	8082                	ret

000000000000037c <link>:
.global link
link:
 li a7, SYS_link
 37c:	48cd                	li	a7,19
 ecall
 37e:	00000073          	ecall
 ret
 382:	8082                	ret

0000000000000384 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 384:	48d1                	li	a7,20
 ecall
 386:	00000073          	ecall
 ret
 38a:	8082                	ret

000000000000038c <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 38c:	48a5                	li	a7,9
 ecall
 38e:	00000073          	ecall
 ret
 392:	8082                	ret

0000000000000394 <dup>:
.global dup
dup:
 li a7, SYS_dup
 394:	48a9                	li	a7,10
 ecall
 396:	00000073          	ecall
 ret
 39a:	8082                	ret

000000000000039c <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 39c:	48ad                	li	a7,11
 ecall
 39e:	00000073          	ecall
 ret
 3a2:	8082                	ret

00000000000003a4 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 3a4:	48b1                	li	a7,12
 ecall
 3a6:	00000073          	ecall
 ret
 3aa:	8082                	ret

00000000000003ac <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 3ac:	48b5                	li	a7,13
 ecall
 3ae:	00000073          	ecall
 ret
 3b2:	8082                	ret

00000000000003b4 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 3b4:	48b9                	li	a7,14
 ecall
 3b6:	00000073          	ecall
 ret
 3ba:	8082                	ret

00000000000003bc <ps>:
.global ps
ps:
 li a7, SYS_ps
 3bc:	48d9                	li	a7,22
 ecall
 3be:	00000073          	ecall
 ret
 3c2:	8082                	ret

00000000000003c4 <schedls>:
.global schedls
schedls:
 li a7, SYS_schedls
 3c4:	48dd                	li	a7,23
 ecall
 3c6:	00000073          	ecall
 ret
 3ca:	8082                	ret

00000000000003cc <schedset>:
.global schedset
schedset:
 li a7, SYS_schedset
 3cc:	48e1                	li	a7,24
 ecall
 3ce:	00000073          	ecall
 ret
 3d2:	8082                	ret

00000000000003d4 <va2pa>:
.global va2pa
va2pa:
 li a7, SYS_va2pa
 3d4:	48e9                	li	a7,26
 ecall
 3d6:	00000073          	ecall
 ret
 3da:	8082                	ret

00000000000003dc <pfreepages>:
.global pfreepages
pfreepages:
 li a7, SYS_pfreepages
 3dc:	48e5                	li	a7,25
 ecall
 3de:	00000073          	ecall
 ret
 3e2:	8082                	ret

00000000000003e4 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 3e4:	1101                	addi	sp,sp,-32
 3e6:	ec06                	sd	ra,24(sp)
 3e8:	e822                	sd	s0,16(sp)
 3ea:	1000                	addi	s0,sp,32
 3ec:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 3f0:	4605                	li	a2,1
 3f2:	fef40593          	addi	a1,s0,-17
 3f6:	00000097          	auipc	ra,0x0
 3fa:	f46080e7          	jalr	-186(ra) # 33c <write>
}
 3fe:	60e2                	ld	ra,24(sp)
 400:	6442                	ld	s0,16(sp)
 402:	6105                	addi	sp,sp,32
 404:	8082                	ret

0000000000000406 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 406:	7139                	addi	sp,sp,-64
 408:	fc06                	sd	ra,56(sp)
 40a:	f822                	sd	s0,48(sp)
 40c:	f426                	sd	s1,40(sp)
 40e:	f04a                	sd	s2,32(sp)
 410:	ec4e                	sd	s3,24(sp)
 412:	0080                	addi	s0,sp,64
 414:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 416:	c299                	beqz	a3,41c <printint+0x16>
 418:	0805c963          	bltz	a1,4aa <printint+0xa4>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 41c:	2581                	sext.w	a1,a1
  neg = 0;
 41e:	4881                	li	a7,0
 420:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 424:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 426:	2601                	sext.w	a2,a2
 428:	00000517          	auipc	a0,0x0
 42c:	4b850513          	addi	a0,a0,1208 # 8e0 <digits>
 430:	883a                	mv	a6,a4
 432:	2705                	addiw	a4,a4,1
 434:	02c5f7bb          	remuw	a5,a1,a2
 438:	1782                	slli	a5,a5,0x20
 43a:	9381                	srli	a5,a5,0x20
 43c:	97aa                	add	a5,a5,a0
 43e:	0007c783          	lbu	a5,0(a5)
 442:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 446:	0005879b          	sext.w	a5,a1
 44a:	02c5d5bb          	divuw	a1,a1,a2
 44e:	0685                	addi	a3,a3,1
 450:	fec7f0e3          	bgeu	a5,a2,430 <printint+0x2a>
  if(neg)
 454:	00088c63          	beqz	a7,46c <printint+0x66>
    buf[i++] = '-';
 458:	fd070793          	addi	a5,a4,-48
 45c:	00878733          	add	a4,a5,s0
 460:	02d00793          	li	a5,45
 464:	fef70823          	sb	a5,-16(a4)
 468:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 46c:	02e05863          	blez	a4,49c <printint+0x96>
 470:	fc040793          	addi	a5,s0,-64
 474:	00e78933          	add	s2,a5,a4
 478:	fff78993          	addi	s3,a5,-1
 47c:	99ba                	add	s3,s3,a4
 47e:	377d                	addiw	a4,a4,-1
 480:	1702                	slli	a4,a4,0x20
 482:	9301                	srli	a4,a4,0x20
 484:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 488:	fff94583          	lbu	a1,-1(s2)
 48c:	8526                	mv	a0,s1
 48e:	00000097          	auipc	ra,0x0
 492:	f56080e7          	jalr	-170(ra) # 3e4 <putc>
  while(--i >= 0)
 496:	197d                	addi	s2,s2,-1
 498:	ff3918e3          	bne	s2,s3,488 <printint+0x82>
}
 49c:	70e2                	ld	ra,56(sp)
 49e:	7442                	ld	s0,48(sp)
 4a0:	74a2                	ld	s1,40(sp)
 4a2:	7902                	ld	s2,32(sp)
 4a4:	69e2                	ld	s3,24(sp)
 4a6:	6121                	addi	sp,sp,64
 4a8:	8082                	ret
    x = -xx;
 4aa:	40b005bb          	negw	a1,a1
    neg = 1;
 4ae:	4885                	li	a7,1
    x = -xx;
 4b0:	bf85                	j	420 <printint+0x1a>

00000000000004b2 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 4b2:	715d                	addi	sp,sp,-80
 4b4:	e486                	sd	ra,72(sp)
 4b6:	e0a2                	sd	s0,64(sp)
 4b8:	fc26                	sd	s1,56(sp)
 4ba:	f84a                	sd	s2,48(sp)
 4bc:	f44e                	sd	s3,40(sp)
 4be:	f052                	sd	s4,32(sp)
 4c0:	ec56                	sd	s5,24(sp)
 4c2:	e85a                	sd	s6,16(sp)
 4c4:	e45e                	sd	s7,8(sp)
 4c6:	e062                	sd	s8,0(sp)
 4c8:	0880                	addi	s0,sp,80
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 4ca:	0005c903          	lbu	s2,0(a1)
 4ce:	18090c63          	beqz	s2,666 <vprintf+0x1b4>
 4d2:	8aaa                	mv	s5,a0
 4d4:	8bb2                	mv	s7,a2
 4d6:	00158493          	addi	s1,a1,1
  state = 0;
 4da:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 4dc:	02500a13          	li	s4,37
 4e0:	4b55                	li	s6,21
 4e2:	a839                	j	500 <vprintf+0x4e>
        putc(fd, c);
 4e4:	85ca                	mv	a1,s2
 4e6:	8556                	mv	a0,s5
 4e8:	00000097          	auipc	ra,0x0
 4ec:	efc080e7          	jalr	-260(ra) # 3e4 <putc>
 4f0:	a019                	j	4f6 <vprintf+0x44>
    } else if(state == '%'){
 4f2:	01498d63          	beq	s3,s4,50c <vprintf+0x5a>
  for(i = 0; fmt[i]; i++){
 4f6:	0485                	addi	s1,s1,1
 4f8:	fff4c903          	lbu	s2,-1(s1)
 4fc:	16090563          	beqz	s2,666 <vprintf+0x1b4>
    if(state == 0){
 500:	fe0999e3          	bnez	s3,4f2 <vprintf+0x40>
      if(c == '%'){
 504:	ff4910e3          	bne	s2,s4,4e4 <vprintf+0x32>
        state = '%';
 508:	89d2                	mv	s3,s4
 50a:	b7f5                	j	4f6 <vprintf+0x44>
      if(c == 'd'){
 50c:	13490263          	beq	s2,s4,630 <vprintf+0x17e>
 510:	f9d9079b          	addiw	a5,s2,-99
 514:	0ff7f793          	zext.b	a5,a5
 518:	12fb6563          	bltu	s6,a5,642 <vprintf+0x190>
 51c:	f9d9079b          	addiw	a5,s2,-99
 520:	0ff7f713          	zext.b	a4,a5
 524:	10eb6f63          	bltu	s6,a4,642 <vprintf+0x190>
 528:	00271793          	slli	a5,a4,0x2
 52c:	00000717          	auipc	a4,0x0
 530:	35c70713          	addi	a4,a4,860 # 888 <malloc+0x124>
 534:	97ba                	add	a5,a5,a4
 536:	439c                	lw	a5,0(a5)
 538:	97ba                	add	a5,a5,a4
 53a:	8782                	jr	a5
        printint(fd, va_arg(ap, int), 10, 1);
 53c:	008b8913          	addi	s2,s7,8
 540:	4685                	li	a3,1
 542:	4629                	li	a2,10
 544:	000ba583          	lw	a1,0(s7)
 548:	8556                	mv	a0,s5
 54a:	00000097          	auipc	ra,0x0
 54e:	ebc080e7          	jalr	-324(ra) # 406 <printint>
 552:	8bca                	mv	s7,s2
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c);
      }
      state = 0;
 554:	4981                	li	s3,0
 556:	b745                	j	4f6 <vprintf+0x44>
        printint(fd, va_arg(ap, uint64), 10, 0);
 558:	008b8913          	addi	s2,s7,8
 55c:	4681                	li	a3,0
 55e:	4629                	li	a2,10
 560:	000ba583          	lw	a1,0(s7)
 564:	8556                	mv	a0,s5
 566:	00000097          	auipc	ra,0x0
 56a:	ea0080e7          	jalr	-352(ra) # 406 <printint>
 56e:	8bca                	mv	s7,s2
      state = 0;
 570:	4981                	li	s3,0
 572:	b751                	j	4f6 <vprintf+0x44>
        printint(fd, va_arg(ap, int), 16, 0);
 574:	008b8913          	addi	s2,s7,8
 578:	4681                	li	a3,0
 57a:	4641                	li	a2,16
 57c:	000ba583          	lw	a1,0(s7)
 580:	8556                	mv	a0,s5
 582:	00000097          	auipc	ra,0x0
 586:	e84080e7          	jalr	-380(ra) # 406 <printint>
 58a:	8bca                	mv	s7,s2
      state = 0;
 58c:	4981                	li	s3,0
 58e:	b7a5                	j	4f6 <vprintf+0x44>
        printptr(fd, va_arg(ap, uint64));
 590:	008b8c13          	addi	s8,s7,8
 594:	000bb983          	ld	s3,0(s7)
  putc(fd, '0');
 598:	03000593          	li	a1,48
 59c:	8556                	mv	a0,s5
 59e:	00000097          	auipc	ra,0x0
 5a2:	e46080e7          	jalr	-442(ra) # 3e4 <putc>
  putc(fd, 'x');
 5a6:	07800593          	li	a1,120
 5aa:	8556                	mv	a0,s5
 5ac:	00000097          	auipc	ra,0x0
 5b0:	e38080e7          	jalr	-456(ra) # 3e4 <putc>
 5b4:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 5b6:	00000b97          	auipc	s7,0x0
 5ba:	32ab8b93          	addi	s7,s7,810 # 8e0 <digits>
 5be:	03c9d793          	srli	a5,s3,0x3c
 5c2:	97de                	add	a5,a5,s7
 5c4:	0007c583          	lbu	a1,0(a5)
 5c8:	8556                	mv	a0,s5
 5ca:	00000097          	auipc	ra,0x0
 5ce:	e1a080e7          	jalr	-486(ra) # 3e4 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 5d2:	0992                	slli	s3,s3,0x4
 5d4:	397d                	addiw	s2,s2,-1
 5d6:	fe0914e3          	bnez	s2,5be <vprintf+0x10c>
        printptr(fd, va_arg(ap, uint64));
 5da:	8be2                	mv	s7,s8
      state = 0;
 5dc:	4981                	li	s3,0
 5de:	bf21                	j	4f6 <vprintf+0x44>
        s = va_arg(ap, char*);
 5e0:	008b8993          	addi	s3,s7,8
 5e4:	000bb903          	ld	s2,0(s7)
        if(s == 0)
 5e8:	02090163          	beqz	s2,60a <vprintf+0x158>
        while(*s != 0){
 5ec:	00094583          	lbu	a1,0(s2)
 5f0:	c9a5                	beqz	a1,660 <vprintf+0x1ae>
          putc(fd, *s);
 5f2:	8556                	mv	a0,s5
 5f4:	00000097          	auipc	ra,0x0
 5f8:	df0080e7          	jalr	-528(ra) # 3e4 <putc>
          s++;
 5fc:	0905                	addi	s2,s2,1
        while(*s != 0){
 5fe:	00094583          	lbu	a1,0(s2)
 602:	f9e5                	bnez	a1,5f2 <vprintf+0x140>
        s = va_arg(ap, char*);
 604:	8bce                	mv	s7,s3
      state = 0;
 606:	4981                	li	s3,0
 608:	b5fd                	j	4f6 <vprintf+0x44>
          s = "(null)";
 60a:	00000917          	auipc	s2,0x0
 60e:	27690913          	addi	s2,s2,630 # 880 <malloc+0x11c>
        while(*s != 0){
 612:	02800593          	li	a1,40
 616:	bff1                	j	5f2 <vprintf+0x140>
        putc(fd, va_arg(ap, uint));
 618:	008b8913          	addi	s2,s7,8
 61c:	000bc583          	lbu	a1,0(s7)
 620:	8556                	mv	a0,s5
 622:	00000097          	auipc	ra,0x0
 626:	dc2080e7          	jalr	-574(ra) # 3e4 <putc>
 62a:	8bca                	mv	s7,s2
      state = 0;
 62c:	4981                	li	s3,0
 62e:	b5e1                	j	4f6 <vprintf+0x44>
        putc(fd, c);
 630:	02500593          	li	a1,37
 634:	8556                	mv	a0,s5
 636:	00000097          	auipc	ra,0x0
 63a:	dae080e7          	jalr	-594(ra) # 3e4 <putc>
      state = 0;
 63e:	4981                	li	s3,0
 640:	bd5d                	j	4f6 <vprintf+0x44>
        putc(fd, '%');
 642:	02500593          	li	a1,37
 646:	8556                	mv	a0,s5
 648:	00000097          	auipc	ra,0x0
 64c:	d9c080e7          	jalr	-612(ra) # 3e4 <putc>
        putc(fd, c);
 650:	85ca                	mv	a1,s2
 652:	8556                	mv	a0,s5
 654:	00000097          	auipc	ra,0x0
 658:	d90080e7          	jalr	-624(ra) # 3e4 <putc>
      state = 0;
 65c:	4981                	li	s3,0
 65e:	bd61                	j	4f6 <vprintf+0x44>
        s = va_arg(ap, char*);
 660:	8bce                	mv	s7,s3
      state = 0;
 662:	4981                	li	s3,0
 664:	bd49                	j	4f6 <vprintf+0x44>
    }
  }
}
 666:	60a6                	ld	ra,72(sp)
 668:	6406                	ld	s0,64(sp)
 66a:	74e2                	ld	s1,56(sp)
 66c:	7942                	ld	s2,48(sp)
 66e:	79a2                	ld	s3,40(sp)
 670:	7a02                	ld	s4,32(sp)
 672:	6ae2                	ld	s5,24(sp)
 674:	6b42                	ld	s6,16(sp)
 676:	6ba2                	ld	s7,8(sp)
 678:	6c02                	ld	s8,0(sp)
 67a:	6161                	addi	sp,sp,80
 67c:	8082                	ret

000000000000067e <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 67e:	715d                	addi	sp,sp,-80
 680:	ec06                	sd	ra,24(sp)
 682:	e822                	sd	s0,16(sp)
 684:	1000                	addi	s0,sp,32
 686:	e010                	sd	a2,0(s0)
 688:	e414                	sd	a3,8(s0)
 68a:	e818                	sd	a4,16(s0)
 68c:	ec1c                	sd	a5,24(s0)
 68e:	03043023          	sd	a6,32(s0)
 692:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 696:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 69a:	8622                	mv	a2,s0
 69c:	00000097          	auipc	ra,0x0
 6a0:	e16080e7          	jalr	-490(ra) # 4b2 <vprintf>
}
 6a4:	60e2                	ld	ra,24(sp)
 6a6:	6442                	ld	s0,16(sp)
 6a8:	6161                	addi	sp,sp,80
 6aa:	8082                	ret

00000000000006ac <printf>:

void
printf(const char *fmt, ...)
{
 6ac:	711d                	addi	sp,sp,-96
 6ae:	ec06                	sd	ra,24(sp)
 6b0:	e822                	sd	s0,16(sp)
 6b2:	1000                	addi	s0,sp,32
 6b4:	e40c                	sd	a1,8(s0)
 6b6:	e810                	sd	a2,16(s0)
 6b8:	ec14                	sd	a3,24(s0)
 6ba:	f018                	sd	a4,32(s0)
 6bc:	f41c                	sd	a5,40(s0)
 6be:	03043823          	sd	a6,48(s0)
 6c2:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 6c6:	00840613          	addi	a2,s0,8
 6ca:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 6ce:	85aa                	mv	a1,a0
 6d0:	4505                	li	a0,1
 6d2:	00000097          	auipc	ra,0x0
 6d6:	de0080e7          	jalr	-544(ra) # 4b2 <vprintf>
}
 6da:	60e2                	ld	ra,24(sp)
 6dc:	6442                	ld	s0,16(sp)
 6de:	6125                	addi	sp,sp,96
 6e0:	8082                	ret

00000000000006e2 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 6e2:	1141                	addi	sp,sp,-16
 6e4:	e422                	sd	s0,8(sp)
 6e6:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 6e8:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 6ec:	00001797          	auipc	a5,0x1
 6f0:	9147b783          	ld	a5,-1772(a5) # 1000 <freep>
 6f4:	a02d                	j	71e <free+0x3c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 6f6:	4618                	lw	a4,8(a2)
 6f8:	9f2d                	addw	a4,a4,a1
 6fa:	fee52c23          	sw	a4,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 6fe:	6398                	ld	a4,0(a5)
 700:	6310                	ld	a2,0(a4)
 702:	a83d                	j	740 <free+0x5e>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 704:	ff852703          	lw	a4,-8(a0)
 708:	9f31                	addw	a4,a4,a2
 70a:	c798                	sw	a4,8(a5)
    p->s.ptr = bp->s.ptr;
 70c:	ff053683          	ld	a3,-16(a0)
 710:	a091                	j	754 <free+0x72>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 712:	6398                	ld	a4,0(a5)
 714:	00e7e463          	bltu	a5,a4,71c <free+0x3a>
 718:	00e6ea63          	bltu	a3,a4,72c <free+0x4a>
{
 71c:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 71e:	fed7fae3          	bgeu	a5,a3,712 <free+0x30>
 722:	6398                	ld	a4,0(a5)
 724:	00e6e463          	bltu	a3,a4,72c <free+0x4a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 728:	fee7eae3          	bltu	a5,a4,71c <free+0x3a>
  if(bp + bp->s.size == p->s.ptr){
 72c:	ff852583          	lw	a1,-8(a0)
 730:	6390                	ld	a2,0(a5)
 732:	02059813          	slli	a6,a1,0x20
 736:	01c85713          	srli	a4,a6,0x1c
 73a:	9736                	add	a4,a4,a3
 73c:	fae60de3          	beq	a2,a4,6f6 <free+0x14>
    bp->s.ptr = p->s.ptr->s.ptr;
 740:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 744:	4790                	lw	a2,8(a5)
 746:	02061593          	slli	a1,a2,0x20
 74a:	01c5d713          	srli	a4,a1,0x1c
 74e:	973e                	add	a4,a4,a5
 750:	fae68ae3          	beq	a3,a4,704 <free+0x22>
    p->s.ptr = bp->s.ptr;
 754:	e394                	sd	a3,0(a5)
  } else
    p->s.ptr = bp;
  freep = p;
 756:	00001717          	auipc	a4,0x1
 75a:	8af73523          	sd	a5,-1878(a4) # 1000 <freep>
}
 75e:	6422                	ld	s0,8(sp)
 760:	0141                	addi	sp,sp,16
 762:	8082                	ret

0000000000000764 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 764:	7139                	addi	sp,sp,-64
 766:	fc06                	sd	ra,56(sp)
 768:	f822                	sd	s0,48(sp)
 76a:	f426                	sd	s1,40(sp)
 76c:	f04a                	sd	s2,32(sp)
 76e:	ec4e                	sd	s3,24(sp)
 770:	e852                	sd	s4,16(sp)
 772:	e456                	sd	s5,8(sp)
 774:	e05a                	sd	s6,0(sp)
 776:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 778:	02051493          	slli	s1,a0,0x20
 77c:	9081                	srli	s1,s1,0x20
 77e:	04bd                	addi	s1,s1,15
 780:	8091                	srli	s1,s1,0x4
 782:	0014899b          	addiw	s3,s1,1
 786:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 788:	00001517          	auipc	a0,0x1
 78c:	87853503          	ld	a0,-1928(a0) # 1000 <freep>
 790:	c515                	beqz	a0,7bc <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 792:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 794:	4798                	lw	a4,8(a5)
 796:	02977f63          	bgeu	a4,s1,7d4 <malloc+0x70>
  if(nu < 4096)
 79a:	8a4e                	mv	s4,s3
 79c:	0009871b          	sext.w	a4,s3
 7a0:	6685                	lui	a3,0x1
 7a2:	00d77363          	bgeu	a4,a3,7a8 <malloc+0x44>
 7a6:	6a05                	lui	s4,0x1
 7a8:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 7ac:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 7b0:	00001917          	auipc	s2,0x1
 7b4:	85090913          	addi	s2,s2,-1968 # 1000 <freep>
  if(p == (char*)-1)
 7b8:	5afd                	li	s5,-1
 7ba:	a895                	j	82e <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 7bc:	00001797          	auipc	a5,0x1
 7c0:	85478793          	addi	a5,a5,-1964 # 1010 <base>
 7c4:	00001717          	auipc	a4,0x1
 7c8:	82f73e23          	sd	a5,-1988(a4) # 1000 <freep>
 7cc:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 7ce:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 7d2:	b7e1                	j	79a <malloc+0x36>
      if(p->s.size == nunits)
 7d4:	02e48c63          	beq	s1,a4,80c <malloc+0xa8>
        p->s.size -= nunits;
 7d8:	4137073b          	subw	a4,a4,s3
 7dc:	c798                	sw	a4,8(a5)
        p += p->s.size;
 7de:	02071693          	slli	a3,a4,0x20
 7e2:	01c6d713          	srli	a4,a3,0x1c
 7e6:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 7e8:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 7ec:	00001717          	auipc	a4,0x1
 7f0:	80a73a23          	sd	a0,-2028(a4) # 1000 <freep>
      return (void*)(p + 1);
 7f4:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 7f8:	70e2                	ld	ra,56(sp)
 7fa:	7442                	ld	s0,48(sp)
 7fc:	74a2                	ld	s1,40(sp)
 7fe:	7902                	ld	s2,32(sp)
 800:	69e2                	ld	s3,24(sp)
 802:	6a42                	ld	s4,16(sp)
 804:	6aa2                	ld	s5,8(sp)
 806:	6b02                	ld	s6,0(sp)
 808:	6121                	addi	sp,sp,64
 80a:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 80c:	6398                	ld	a4,0(a5)
 80e:	e118                	sd	a4,0(a0)
 810:	bff1                	j	7ec <malloc+0x88>
  hp->s.size = nu;
 812:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 816:	0541                	addi	a0,a0,16
 818:	00000097          	auipc	ra,0x0
 81c:	eca080e7          	jalr	-310(ra) # 6e2 <free>
  return freep;
 820:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 824:	d971                	beqz	a0,7f8 <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 826:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 828:	4798                	lw	a4,8(a5)
 82a:	fa9775e3          	bgeu	a4,s1,7d4 <malloc+0x70>
    if(p == freep)
 82e:	00093703          	ld	a4,0(s2)
 832:	853e                	mv	a0,a5
 834:	fef719e3          	bne	a4,a5,826 <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 838:	8552                	mv	a0,s4
 83a:	00000097          	auipc	ra,0x0
 83e:	b6a080e7          	jalr	-1174(ra) # 3a4 <sbrk>
  if(p == (char*)-1)
 842:	fd5518e3          	bne	a0,s5,812 <malloc+0xae>
        return 0;
 846:	4501                	li	a0,0
 848:	bf45                	j	7f8 <malloc+0x94>
