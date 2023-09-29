
user/_timeBenchmark:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
#include "kernel/types.h"
#include "user/user.h"

int main(int argc, char *argv[])
{
   0:	7139                	addi	sp,sp,-64
   2:	fc06                	sd	ra,56(sp)
   4:	f822                	sd	s0,48(sp)
   6:	f426                	sd	s1,40(sp)
   8:	f04a                	sd	s2,32(sp)
   a:	ec4e                	sd	s3,24(sp)
   c:	e852                	sd	s4,16(sp)
   e:	e456                	sd	s5,8(sp)
  10:	e05a                	sd	s6,0(sp)
  12:	0080                	addi	s0,sp,64
  14:	89ae                	mv	s3,a1
  16:	4929                	li	s2,10
    int totalTicks = 0;
  18:	4a01                	li	s4,0
            // we are the timer process
            // wait for the uut to finish
            wait(0);
            int endticks = uptime();
            totalTicks += endticks - startticks;
            printf("Executing %s took %d ticks\n", argv[1], endticks - startticks);
  1a:	00001b17          	auipc	s6,0x1
  1e:	88eb0b13          	addi	s6,s6,-1906 # 8a8 <malloc+0x11a>
            exec(argv[1], argv + 1); // pass rest of the command line to the executable as args
  22:	00858a93          	addi	s5,a1,8
  26:	a881                	j	76 <main+0x76>
            printf("fork failed... couldn't start %s", argv[1]);
  28:	0089b583          	ld	a1,8(s3)
  2c:	00001517          	auipc	a0,0x1
  30:	85450513          	addi	a0,a0,-1964 # 880 <malloc+0xf2>
  34:	00000097          	auipc	ra,0x0
  38:	6a2080e7          	jalr	1698(ra) # 6d6 <printf>
            exit(1);
  3c:	4505                	li	a0,1
  3e:	00000097          	auipc	ra,0x0
  42:	318080e7          	jalr	792(ra) # 356 <exit>
            wait(0);
  46:	4501                	li	a0,0
  48:	00000097          	auipc	ra,0x0
  4c:	316080e7          	jalr	790(ra) # 35e <wait>
            int endticks = uptime();
  50:	00000097          	auipc	ra,0x0
  54:	39e080e7          	jalr	926(ra) # 3ee <uptime>
            totalTicks += endticks - startticks;
  58:	4095063b          	subw	a2,a0,s1
  5c:	01460a3b          	addw	s4,a2,s4
            printf("Executing %s took %d ticks\n", argv[1], endticks - startticks);
  60:	2601                	sext.w	a2,a2
  62:	0089b583          	ld	a1,8(s3)
  66:	855a                	mv	a0,s6
  68:	00000097          	auipc	ra,0x0
  6c:	66e080e7          	jalr	1646(ra) # 6d6 <printf>
    for (i = 0; i < 10; i++) {
  70:	397d                	addiw	s2,s2,-1
  72:	02090663          	beqz	s2,9e <main+0x9e>
        int startticks = uptime();
  76:	00000097          	auipc	ra,0x0
  7a:	378080e7          	jalr	888(ra) # 3ee <uptime>
  7e:	84aa                	mv	s1,a0
        int uutPid = fork();
  80:	00000097          	auipc	ra,0x0
  84:	2ce080e7          	jalr	718(ra) # 34e <fork>
        if (uutPid < 0)
  88:	fa0540e3          	bltz	a0,28 <main+0x28>
        if (uutPid == 0)
  8c:	fd4d                	bnez	a0,46 <main+0x46>
            exec(argv[1], argv + 1); // pass rest of the command line to the executable as args
  8e:	85d6                	mv	a1,s5
  90:	0089b503          	ld	a0,8(s3)
  94:	00000097          	auipc	ra,0x0
  98:	2fa080e7          	jalr	762(ra) # 38e <exec>
  9c:	bfd1                	j	70 <main+0x70>
        }
    }
    printf("Executing took a total of %d ticks\n", totalTicks);
  9e:	85d2                	mv	a1,s4
  a0:	00001517          	auipc	a0,0x1
  a4:	82850513          	addi	a0,a0,-2008 # 8c8 <malloc+0x13a>
  a8:	00000097          	auipc	ra,0x0
  ac:	62e080e7          	jalr	1582(ra) # 6d6 <printf>
    printf("Average execution time was %d ticks\n", totalTicks / 10);
  b0:	45a9                	li	a1,10
  b2:	02ba45bb          	divw	a1,s4,a1
  b6:	00001517          	auipc	a0,0x1
  ba:	83a50513          	addi	a0,a0,-1990 # 8f0 <malloc+0x162>
  be:	00000097          	auipc	ra,0x0
  c2:	618080e7          	jalr	1560(ra) # 6d6 <printf>
    exit(0);
  c6:	4501                	li	a0,0
  c8:	00000097          	auipc	ra,0x0
  cc:	28e080e7          	jalr	654(ra) # 356 <exit>

00000000000000d0 <_main>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
_main()
{
  d0:	1141                	addi	sp,sp,-16
  d2:	e406                	sd	ra,8(sp)
  d4:	e022                	sd	s0,0(sp)
  d6:	0800                	addi	s0,sp,16
  extern int main();
  main();
  d8:	00000097          	auipc	ra,0x0
  dc:	f28080e7          	jalr	-216(ra) # 0 <main>
  exit(0);
  e0:	4501                	li	a0,0
  e2:	00000097          	auipc	ra,0x0
  e6:	274080e7          	jalr	628(ra) # 356 <exit>

00000000000000ea <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
  ea:	1141                	addi	sp,sp,-16
  ec:	e422                	sd	s0,8(sp)
  ee:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  f0:	87aa                	mv	a5,a0
  f2:	0585                	addi	a1,a1,1
  f4:	0785                	addi	a5,a5,1
  f6:	fff5c703          	lbu	a4,-1(a1)
  fa:	fee78fa3          	sb	a4,-1(a5)
  fe:	fb75                	bnez	a4,f2 <strcpy+0x8>
    ;
  return os;
}
 100:	6422                	ld	s0,8(sp)
 102:	0141                	addi	sp,sp,16
 104:	8082                	ret

0000000000000106 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 106:	1141                	addi	sp,sp,-16
 108:	e422                	sd	s0,8(sp)
 10a:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 10c:	00054783          	lbu	a5,0(a0)
 110:	cb91                	beqz	a5,124 <strcmp+0x1e>
 112:	0005c703          	lbu	a4,0(a1)
 116:	00f71763          	bne	a4,a5,124 <strcmp+0x1e>
    p++, q++;
 11a:	0505                	addi	a0,a0,1
 11c:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 11e:	00054783          	lbu	a5,0(a0)
 122:	fbe5                	bnez	a5,112 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 124:	0005c503          	lbu	a0,0(a1)
}
 128:	40a7853b          	subw	a0,a5,a0
 12c:	6422                	ld	s0,8(sp)
 12e:	0141                	addi	sp,sp,16
 130:	8082                	ret

0000000000000132 <strlen>:

uint
strlen(const char *s)
{
 132:	1141                	addi	sp,sp,-16
 134:	e422                	sd	s0,8(sp)
 136:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 138:	00054783          	lbu	a5,0(a0)
 13c:	cf91                	beqz	a5,158 <strlen+0x26>
 13e:	0505                	addi	a0,a0,1
 140:	87aa                	mv	a5,a0
 142:	86be                	mv	a3,a5
 144:	0785                	addi	a5,a5,1
 146:	fff7c703          	lbu	a4,-1(a5)
 14a:	ff65                	bnez	a4,142 <strlen+0x10>
 14c:	40a6853b          	subw	a0,a3,a0
 150:	2505                	addiw	a0,a0,1
    ;
  return n;
}
 152:	6422                	ld	s0,8(sp)
 154:	0141                	addi	sp,sp,16
 156:	8082                	ret
  for(n = 0; s[n]; n++)
 158:	4501                	li	a0,0
 15a:	bfe5                	j	152 <strlen+0x20>

000000000000015c <memset>:

void*
memset(void *dst, int c, uint n)
{
 15c:	1141                	addi	sp,sp,-16
 15e:	e422                	sd	s0,8(sp)
 160:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 162:	ca19                	beqz	a2,178 <memset+0x1c>
 164:	87aa                	mv	a5,a0
 166:	1602                	slli	a2,a2,0x20
 168:	9201                	srli	a2,a2,0x20
 16a:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 16e:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 172:	0785                	addi	a5,a5,1
 174:	fee79de3          	bne	a5,a4,16e <memset+0x12>
  }
  return dst;
}
 178:	6422                	ld	s0,8(sp)
 17a:	0141                	addi	sp,sp,16
 17c:	8082                	ret

000000000000017e <strchr>:

char*
strchr(const char *s, char c)
{
 17e:	1141                	addi	sp,sp,-16
 180:	e422                	sd	s0,8(sp)
 182:	0800                	addi	s0,sp,16
  for(; *s; s++)
 184:	00054783          	lbu	a5,0(a0)
 188:	cb99                	beqz	a5,19e <strchr+0x20>
    if(*s == c)
 18a:	00f58763          	beq	a1,a5,198 <strchr+0x1a>
  for(; *s; s++)
 18e:	0505                	addi	a0,a0,1
 190:	00054783          	lbu	a5,0(a0)
 194:	fbfd                	bnez	a5,18a <strchr+0xc>
      return (char*)s;
  return 0;
 196:	4501                	li	a0,0
}
 198:	6422                	ld	s0,8(sp)
 19a:	0141                	addi	sp,sp,16
 19c:	8082                	ret
  return 0;
 19e:	4501                	li	a0,0
 1a0:	bfe5                	j	198 <strchr+0x1a>

00000000000001a2 <gets>:

char*
gets(char *buf, int max)
{
 1a2:	711d                	addi	sp,sp,-96
 1a4:	ec86                	sd	ra,88(sp)
 1a6:	e8a2                	sd	s0,80(sp)
 1a8:	e4a6                	sd	s1,72(sp)
 1aa:	e0ca                	sd	s2,64(sp)
 1ac:	fc4e                	sd	s3,56(sp)
 1ae:	f852                	sd	s4,48(sp)
 1b0:	f456                	sd	s5,40(sp)
 1b2:	f05a                	sd	s6,32(sp)
 1b4:	ec5e                	sd	s7,24(sp)
 1b6:	1080                	addi	s0,sp,96
 1b8:	8baa                	mv	s7,a0
 1ba:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 1bc:	892a                	mv	s2,a0
 1be:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 1c0:	4aa9                	li	s5,10
 1c2:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 1c4:	89a6                	mv	s3,s1
 1c6:	2485                	addiw	s1,s1,1
 1c8:	0344d863          	bge	s1,s4,1f8 <gets+0x56>
    cc = read(0, &c, 1);
 1cc:	4605                	li	a2,1
 1ce:	faf40593          	addi	a1,s0,-81
 1d2:	4501                	li	a0,0
 1d4:	00000097          	auipc	ra,0x0
 1d8:	19a080e7          	jalr	410(ra) # 36e <read>
    if(cc < 1)
 1dc:	00a05e63          	blez	a0,1f8 <gets+0x56>
    buf[i++] = c;
 1e0:	faf44783          	lbu	a5,-81(s0)
 1e4:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 1e8:	01578763          	beq	a5,s5,1f6 <gets+0x54>
 1ec:	0905                	addi	s2,s2,1
 1ee:	fd679be3          	bne	a5,s6,1c4 <gets+0x22>
  for(i=0; i+1 < max; ){
 1f2:	89a6                	mv	s3,s1
 1f4:	a011                	j	1f8 <gets+0x56>
 1f6:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 1f8:	99de                	add	s3,s3,s7
 1fa:	00098023          	sb	zero,0(s3)
  return buf;
}
 1fe:	855e                	mv	a0,s7
 200:	60e6                	ld	ra,88(sp)
 202:	6446                	ld	s0,80(sp)
 204:	64a6                	ld	s1,72(sp)
 206:	6906                	ld	s2,64(sp)
 208:	79e2                	ld	s3,56(sp)
 20a:	7a42                	ld	s4,48(sp)
 20c:	7aa2                	ld	s5,40(sp)
 20e:	7b02                	ld	s6,32(sp)
 210:	6be2                	ld	s7,24(sp)
 212:	6125                	addi	sp,sp,96
 214:	8082                	ret

0000000000000216 <stat>:

int
stat(const char *n, struct stat *st)
{
 216:	1101                	addi	sp,sp,-32
 218:	ec06                	sd	ra,24(sp)
 21a:	e822                	sd	s0,16(sp)
 21c:	e426                	sd	s1,8(sp)
 21e:	e04a                	sd	s2,0(sp)
 220:	1000                	addi	s0,sp,32
 222:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 224:	4581                	li	a1,0
 226:	00000097          	auipc	ra,0x0
 22a:	170080e7          	jalr	368(ra) # 396 <open>
  if(fd < 0)
 22e:	02054563          	bltz	a0,258 <stat+0x42>
 232:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 234:	85ca                	mv	a1,s2
 236:	00000097          	auipc	ra,0x0
 23a:	178080e7          	jalr	376(ra) # 3ae <fstat>
 23e:	892a                	mv	s2,a0
  close(fd);
 240:	8526                	mv	a0,s1
 242:	00000097          	auipc	ra,0x0
 246:	13c080e7          	jalr	316(ra) # 37e <close>
  return r;
}
 24a:	854a                	mv	a0,s2
 24c:	60e2                	ld	ra,24(sp)
 24e:	6442                	ld	s0,16(sp)
 250:	64a2                	ld	s1,8(sp)
 252:	6902                	ld	s2,0(sp)
 254:	6105                	addi	sp,sp,32
 256:	8082                	ret
    return -1;
 258:	597d                	li	s2,-1
 25a:	bfc5                	j	24a <stat+0x34>

000000000000025c <atoi>:

int
atoi(const char *s)
{
 25c:	1141                	addi	sp,sp,-16
 25e:	e422                	sd	s0,8(sp)
 260:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 262:	00054683          	lbu	a3,0(a0)
 266:	fd06879b          	addiw	a5,a3,-48
 26a:	0ff7f793          	zext.b	a5,a5
 26e:	4625                	li	a2,9
 270:	02f66863          	bltu	a2,a5,2a0 <atoi+0x44>
 274:	872a                	mv	a4,a0
  n = 0;
 276:	4501                	li	a0,0
    n = n*10 + *s++ - '0';
 278:	0705                	addi	a4,a4,1
 27a:	0025179b          	slliw	a5,a0,0x2
 27e:	9fa9                	addw	a5,a5,a0
 280:	0017979b          	slliw	a5,a5,0x1
 284:	9fb5                	addw	a5,a5,a3
 286:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 28a:	00074683          	lbu	a3,0(a4)
 28e:	fd06879b          	addiw	a5,a3,-48
 292:	0ff7f793          	zext.b	a5,a5
 296:	fef671e3          	bgeu	a2,a5,278 <atoi+0x1c>
  return n;
}
 29a:	6422                	ld	s0,8(sp)
 29c:	0141                	addi	sp,sp,16
 29e:	8082                	ret
  n = 0;
 2a0:	4501                	li	a0,0
 2a2:	bfe5                	j	29a <atoi+0x3e>

00000000000002a4 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 2a4:	1141                	addi	sp,sp,-16
 2a6:	e422                	sd	s0,8(sp)
 2a8:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 2aa:	02b57463          	bgeu	a0,a1,2d2 <memmove+0x2e>
    while(n-- > 0)
 2ae:	00c05f63          	blez	a2,2cc <memmove+0x28>
 2b2:	1602                	slli	a2,a2,0x20
 2b4:	9201                	srli	a2,a2,0x20
 2b6:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 2ba:	872a                	mv	a4,a0
      *dst++ = *src++;
 2bc:	0585                	addi	a1,a1,1
 2be:	0705                	addi	a4,a4,1
 2c0:	fff5c683          	lbu	a3,-1(a1)
 2c4:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 2c8:	fee79ae3          	bne	a5,a4,2bc <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 2cc:	6422                	ld	s0,8(sp)
 2ce:	0141                	addi	sp,sp,16
 2d0:	8082                	ret
    dst += n;
 2d2:	00c50733          	add	a4,a0,a2
    src += n;
 2d6:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 2d8:	fec05ae3          	blez	a2,2cc <memmove+0x28>
 2dc:	fff6079b          	addiw	a5,a2,-1
 2e0:	1782                	slli	a5,a5,0x20
 2e2:	9381                	srli	a5,a5,0x20
 2e4:	fff7c793          	not	a5,a5
 2e8:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 2ea:	15fd                	addi	a1,a1,-1
 2ec:	177d                	addi	a4,a4,-1
 2ee:	0005c683          	lbu	a3,0(a1)
 2f2:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 2f6:	fee79ae3          	bne	a5,a4,2ea <memmove+0x46>
 2fa:	bfc9                	j	2cc <memmove+0x28>

00000000000002fc <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 2fc:	1141                	addi	sp,sp,-16
 2fe:	e422                	sd	s0,8(sp)
 300:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 302:	ca05                	beqz	a2,332 <memcmp+0x36>
 304:	fff6069b          	addiw	a3,a2,-1
 308:	1682                	slli	a3,a3,0x20
 30a:	9281                	srli	a3,a3,0x20
 30c:	0685                	addi	a3,a3,1
 30e:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 310:	00054783          	lbu	a5,0(a0)
 314:	0005c703          	lbu	a4,0(a1)
 318:	00e79863          	bne	a5,a4,328 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 31c:	0505                	addi	a0,a0,1
    p2++;
 31e:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 320:	fed518e3          	bne	a0,a3,310 <memcmp+0x14>
  }
  return 0;
 324:	4501                	li	a0,0
 326:	a019                	j	32c <memcmp+0x30>
      return *p1 - *p2;
 328:	40e7853b          	subw	a0,a5,a4
}
 32c:	6422                	ld	s0,8(sp)
 32e:	0141                	addi	sp,sp,16
 330:	8082                	ret
  return 0;
 332:	4501                	li	a0,0
 334:	bfe5                	j	32c <memcmp+0x30>

0000000000000336 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 336:	1141                	addi	sp,sp,-16
 338:	e406                	sd	ra,8(sp)
 33a:	e022                	sd	s0,0(sp)
 33c:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 33e:	00000097          	auipc	ra,0x0
 342:	f66080e7          	jalr	-154(ra) # 2a4 <memmove>
}
 346:	60a2                	ld	ra,8(sp)
 348:	6402                	ld	s0,0(sp)
 34a:	0141                	addi	sp,sp,16
 34c:	8082                	ret

000000000000034e <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 34e:	4885                	li	a7,1
 ecall
 350:	00000073          	ecall
 ret
 354:	8082                	ret

0000000000000356 <exit>:
.global exit
exit:
 li a7, SYS_exit
 356:	4889                	li	a7,2
 ecall
 358:	00000073          	ecall
 ret
 35c:	8082                	ret

000000000000035e <wait>:
.global wait
wait:
 li a7, SYS_wait
 35e:	488d                	li	a7,3
 ecall
 360:	00000073          	ecall
 ret
 364:	8082                	ret

0000000000000366 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 366:	4891                	li	a7,4
 ecall
 368:	00000073          	ecall
 ret
 36c:	8082                	ret

000000000000036e <read>:
.global read
read:
 li a7, SYS_read
 36e:	4895                	li	a7,5
 ecall
 370:	00000073          	ecall
 ret
 374:	8082                	ret

0000000000000376 <write>:
.global write
write:
 li a7, SYS_write
 376:	48c1                	li	a7,16
 ecall
 378:	00000073          	ecall
 ret
 37c:	8082                	ret

000000000000037e <close>:
.global close
close:
 li a7, SYS_close
 37e:	48d5                	li	a7,21
 ecall
 380:	00000073          	ecall
 ret
 384:	8082                	ret

0000000000000386 <kill>:
.global kill
kill:
 li a7, SYS_kill
 386:	4899                	li	a7,6
 ecall
 388:	00000073          	ecall
 ret
 38c:	8082                	ret

000000000000038e <exec>:
.global exec
exec:
 li a7, SYS_exec
 38e:	489d                	li	a7,7
 ecall
 390:	00000073          	ecall
 ret
 394:	8082                	ret

0000000000000396 <open>:
.global open
open:
 li a7, SYS_open
 396:	48bd                	li	a7,15
 ecall
 398:	00000073          	ecall
 ret
 39c:	8082                	ret

000000000000039e <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 39e:	48c5                	li	a7,17
 ecall
 3a0:	00000073          	ecall
 ret
 3a4:	8082                	ret

00000000000003a6 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 3a6:	48c9                	li	a7,18
 ecall
 3a8:	00000073          	ecall
 ret
 3ac:	8082                	ret

00000000000003ae <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 3ae:	48a1                	li	a7,8
 ecall
 3b0:	00000073          	ecall
 ret
 3b4:	8082                	ret

00000000000003b6 <link>:
.global link
link:
 li a7, SYS_link
 3b6:	48cd                	li	a7,19
 ecall
 3b8:	00000073          	ecall
 ret
 3bc:	8082                	ret

00000000000003be <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 3be:	48d1                	li	a7,20
 ecall
 3c0:	00000073          	ecall
 ret
 3c4:	8082                	ret

00000000000003c6 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 3c6:	48a5                	li	a7,9
 ecall
 3c8:	00000073          	ecall
 ret
 3cc:	8082                	ret

00000000000003ce <dup>:
.global dup
dup:
 li a7, SYS_dup
 3ce:	48a9                	li	a7,10
 ecall
 3d0:	00000073          	ecall
 ret
 3d4:	8082                	ret

00000000000003d6 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 3d6:	48ad                	li	a7,11
 ecall
 3d8:	00000073          	ecall
 ret
 3dc:	8082                	ret

00000000000003de <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 3de:	48b1                	li	a7,12
 ecall
 3e0:	00000073          	ecall
 ret
 3e4:	8082                	ret

00000000000003e6 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 3e6:	48b5                	li	a7,13
 ecall
 3e8:	00000073          	ecall
 ret
 3ec:	8082                	ret

00000000000003ee <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 3ee:	48b9                	li	a7,14
 ecall
 3f0:	00000073          	ecall
 ret
 3f4:	8082                	ret

00000000000003f6 <ps>:
.global ps
ps:
 li a7, SYS_ps
 3f6:	48d9                	li	a7,22
 ecall
 3f8:	00000073          	ecall
 ret
 3fc:	8082                	ret

00000000000003fe <schedls>:
.global schedls
schedls:
 li a7, SYS_schedls
 3fe:	48dd                	li	a7,23
 ecall
 400:	00000073          	ecall
 ret
 404:	8082                	ret

0000000000000406 <schedset>:
.global schedset
schedset:
 li a7, SYS_schedset
 406:	48e1                	li	a7,24
 ecall
 408:	00000073          	ecall
 ret
 40c:	8082                	ret

000000000000040e <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 40e:	1101                	addi	sp,sp,-32
 410:	ec06                	sd	ra,24(sp)
 412:	e822                	sd	s0,16(sp)
 414:	1000                	addi	s0,sp,32
 416:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 41a:	4605                	li	a2,1
 41c:	fef40593          	addi	a1,s0,-17
 420:	00000097          	auipc	ra,0x0
 424:	f56080e7          	jalr	-170(ra) # 376 <write>
}
 428:	60e2                	ld	ra,24(sp)
 42a:	6442                	ld	s0,16(sp)
 42c:	6105                	addi	sp,sp,32
 42e:	8082                	ret

0000000000000430 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 430:	7139                	addi	sp,sp,-64
 432:	fc06                	sd	ra,56(sp)
 434:	f822                	sd	s0,48(sp)
 436:	f426                	sd	s1,40(sp)
 438:	f04a                	sd	s2,32(sp)
 43a:	ec4e                	sd	s3,24(sp)
 43c:	0080                	addi	s0,sp,64
 43e:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 440:	c299                	beqz	a3,446 <printint+0x16>
 442:	0805c963          	bltz	a1,4d4 <printint+0xa4>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 446:	2581                	sext.w	a1,a1
  neg = 0;
 448:	4881                	li	a7,0
 44a:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 44e:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 450:	2601                	sext.w	a2,a2
 452:	00000517          	auipc	a0,0x0
 456:	52650513          	addi	a0,a0,1318 # 978 <digits>
 45a:	883a                	mv	a6,a4
 45c:	2705                	addiw	a4,a4,1
 45e:	02c5f7bb          	remuw	a5,a1,a2
 462:	1782                	slli	a5,a5,0x20
 464:	9381                	srli	a5,a5,0x20
 466:	97aa                	add	a5,a5,a0
 468:	0007c783          	lbu	a5,0(a5)
 46c:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 470:	0005879b          	sext.w	a5,a1
 474:	02c5d5bb          	divuw	a1,a1,a2
 478:	0685                	addi	a3,a3,1
 47a:	fec7f0e3          	bgeu	a5,a2,45a <printint+0x2a>
  if(neg)
 47e:	00088c63          	beqz	a7,496 <printint+0x66>
    buf[i++] = '-';
 482:	fd070793          	addi	a5,a4,-48
 486:	00878733          	add	a4,a5,s0
 48a:	02d00793          	li	a5,45
 48e:	fef70823          	sb	a5,-16(a4)
 492:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 496:	02e05863          	blez	a4,4c6 <printint+0x96>
 49a:	fc040793          	addi	a5,s0,-64
 49e:	00e78933          	add	s2,a5,a4
 4a2:	fff78993          	addi	s3,a5,-1
 4a6:	99ba                	add	s3,s3,a4
 4a8:	377d                	addiw	a4,a4,-1
 4aa:	1702                	slli	a4,a4,0x20
 4ac:	9301                	srli	a4,a4,0x20
 4ae:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 4b2:	fff94583          	lbu	a1,-1(s2)
 4b6:	8526                	mv	a0,s1
 4b8:	00000097          	auipc	ra,0x0
 4bc:	f56080e7          	jalr	-170(ra) # 40e <putc>
  while(--i >= 0)
 4c0:	197d                	addi	s2,s2,-1
 4c2:	ff3918e3          	bne	s2,s3,4b2 <printint+0x82>
}
 4c6:	70e2                	ld	ra,56(sp)
 4c8:	7442                	ld	s0,48(sp)
 4ca:	74a2                	ld	s1,40(sp)
 4cc:	7902                	ld	s2,32(sp)
 4ce:	69e2                	ld	s3,24(sp)
 4d0:	6121                	addi	sp,sp,64
 4d2:	8082                	ret
    x = -xx;
 4d4:	40b005bb          	negw	a1,a1
    neg = 1;
 4d8:	4885                	li	a7,1
    x = -xx;
 4da:	bf85                	j	44a <printint+0x1a>

00000000000004dc <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 4dc:	715d                	addi	sp,sp,-80
 4de:	e486                	sd	ra,72(sp)
 4e0:	e0a2                	sd	s0,64(sp)
 4e2:	fc26                	sd	s1,56(sp)
 4e4:	f84a                	sd	s2,48(sp)
 4e6:	f44e                	sd	s3,40(sp)
 4e8:	f052                	sd	s4,32(sp)
 4ea:	ec56                	sd	s5,24(sp)
 4ec:	e85a                	sd	s6,16(sp)
 4ee:	e45e                	sd	s7,8(sp)
 4f0:	e062                	sd	s8,0(sp)
 4f2:	0880                	addi	s0,sp,80
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 4f4:	0005c903          	lbu	s2,0(a1)
 4f8:	18090c63          	beqz	s2,690 <vprintf+0x1b4>
 4fc:	8aaa                	mv	s5,a0
 4fe:	8bb2                	mv	s7,a2
 500:	00158493          	addi	s1,a1,1
  state = 0;
 504:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 506:	02500a13          	li	s4,37
 50a:	4b55                	li	s6,21
 50c:	a839                	j	52a <vprintf+0x4e>
        putc(fd, c);
 50e:	85ca                	mv	a1,s2
 510:	8556                	mv	a0,s5
 512:	00000097          	auipc	ra,0x0
 516:	efc080e7          	jalr	-260(ra) # 40e <putc>
 51a:	a019                	j	520 <vprintf+0x44>
    } else if(state == '%'){
 51c:	01498d63          	beq	s3,s4,536 <vprintf+0x5a>
  for(i = 0; fmt[i]; i++){
 520:	0485                	addi	s1,s1,1
 522:	fff4c903          	lbu	s2,-1(s1)
 526:	16090563          	beqz	s2,690 <vprintf+0x1b4>
    if(state == 0){
 52a:	fe0999e3          	bnez	s3,51c <vprintf+0x40>
      if(c == '%'){
 52e:	ff4910e3          	bne	s2,s4,50e <vprintf+0x32>
        state = '%';
 532:	89d2                	mv	s3,s4
 534:	b7f5                	j	520 <vprintf+0x44>
      if(c == 'd'){
 536:	13490263          	beq	s2,s4,65a <vprintf+0x17e>
 53a:	f9d9079b          	addiw	a5,s2,-99
 53e:	0ff7f793          	zext.b	a5,a5
 542:	12fb6563          	bltu	s6,a5,66c <vprintf+0x190>
 546:	f9d9079b          	addiw	a5,s2,-99
 54a:	0ff7f713          	zext.b	a4,a5
 54e:	10eb6f63          	bltu	s6,a4,66c <vprintf+0x190>
 552:	00271793          	slli	a5,a4,0x2
 556:	00000717          	auipc	a4,0x0
 55a:	3ca70713          	addi	a4,a4,970 # 920 <malloc+0x192>
 55e:	97ba                	add	a5,a5,a4
 560:	439c                	lw	a5,0(a5)
 562:	97ba                	add	a5,a5,a4
 564:	8782                	jr	a5
        printint(fd, va_arg(ap, int), 10, 1);
 566:	008b8913          	addi	s2,s7,8
 56a:	4685                	li	a3,1
 56c:	4629                	li	a2,10
 56e:	000ba583          	lw	a1,0(s7)
 572:	8556                	mv	a0,s5
 574:	00000097          	auipc	ra,0x0
 578:	ebc080e7          	jalr	-324(ra) # 430 <printint>
 57c:	8bca                	mv	s7,s2
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c);
      }
      state = 0;
 57e:	4981                	li	s3,0
 580:	b745                	j	520 <vprintf+0x44>
        printint(fd, va_arg(ap, uint64), 10, 0);
 582:	008b8913          	addi	s2,s7,8
 586:	4681                	li	a3,0
 588:	4629                	li	a2,10
 58a:	000ba583          	lw	a1,0(s7)
 58e:	8556                	mv	a0,s5
 590:	00000097          	auipc	ra,0x0
 594:	ea0080e7          	jalr	-352(ra) # 430 <printint>
 598:	8bca                	mv	s7,s2
      state = 0;
 59a:	4981                	li	s3,0
 59c:	b751                	j	520 <vprintf+0x44>
        printint(fd, va_arg(ap, int), 16, 0);
 59e:	008b8913          	addi	s2,s7,8
 5a2:	4681                	li	a3,0
 5a4:	4641                	li	a2,16
 5a6:	000ba583          	lw	a1,0(s7)
 5aa:	8556                	mv	a0,s5
 5ac:	00000097          	auipc	ra,0x0
 5b0:	e84080e7          	jalr	-380(ra) # 430 <printint>
 5b4:	8bca                	mv	s7,s2
      state = 0;
 5b6:	4981                	li	s3,0
 5b8:	b7a5                	j	520 <vprintf+0x44>
        printptr(fd, va_arg(ap, uint64));
 5ba:	008b8c13          	addi	s8,s7,8
 5be:	000bb983          	ld	s3,0(s7)
  putc(fd, '0');
 5c2:	03000593          	li	a1,48
 5c6:	8556                	mv	a0,s5
 5c8:	00000097          	auipc	ra,0x0
 5cc:	e46080e7          	jalr	-442(ra) # 40e <putc>
  putc(fd, 'x');
 5d0:	07800593          	li	a1,120
 5d4:	8556                	mv	a0,s5
 5d6:	00000097          	auipc	ra,0x0
 5da:	e38080e7          	jalr	-456(ra) # 40e <putc>
 5de:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 5e0:	00000b97          	auipc	s7,0x0
 5e4:	398b8b93          	addi	s7,s7,920 # 978 <digits>
 5e8:	03c9d793          	srli	a5,s3,0x3c
 5ec:	97de                	add	a5,a5,s7
 5ee:	0007c583          	lbu	a1,0(a5)
 5f2:	8556                	mv	a0,s5
 5f4:	00000097          	auipc	ra,0x0
 5f8:	e1a080e7          	jalr	-486(ra) # 40e <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 5fc:	0992                	slli	s3,s3,0x4
 5fe:	397d                	addiw	s2,s2,-1
 600:	fe0914e3          	bnez	s2,5e8 <vprintf+0x10c>
        printptr(fd, va_arg(ap, uint64));
 604:	8be2                	mv	s7,s8
      state = 0;
 606:	4981                	li	s3,0
 608:	bf21                	j	520 <vprintf+0x44>
        s = va_arg(ap, char*);
 60a:	008b8993          	addi	s3,s7,8
 60e:	000bb903          	ld	s2,0(s7)
        if(s == 0)
 612:	02090163          	beqz	s2,634 <vprintf+0x158>
        while(*s != 0){
 616:	00094583          	lbu	a1,0(s2)
 61a:	c9a5                	beqz	a1,68a <vprintf+0x1ae>
          putc(fd, *s);
 61c:	8556                	mv	a0,s5
 61e:	00000097          	auipc	ra,0x0
 622:	df0080e7          	jalr	-528(ra) # 40e <putc>
          s++;
 626:	0905                	addi	s2,s2,1
        while(*s != 0){
 628:	00094583          	lbu	a1,0(s2)
 62c:	f9e5                	bnez	a1,61c <vprintf+0x140>
        s = va_arg(ap, char*);
 62e:	8bce                	mv	s7,s3
      state = 0;
 630:	4981                	li	s3,0
 632:	b5fd                	j	520 <vprintf+0x44>
          s = "(null)";
 634:	00000917          	auipc	s2,0x0
 638:	2e490913          	addi	s2,s2,740 # 918 <malloc+0x18a>
        while(*s != 0){
 63c:	02800593          	li	a1,40
 640:	bff1                	j	61c <vprintf+0x140>
        putc(fd, va_arg(ap, uint));
 642:	008b8913          	addi	s2,s7,8
 646:	000bc583          	lbu	a1,0(s7)
 64a:	8556                	mv	a0,s5
 64c:	00000097          	auipc	ra,0x0
 650:	dc2080e7          	jalr	-574(ra) # 40e <putc>
 654:	8bca                	mv	s7,s2
      state = 0;
 656:	4981                	li	s3,0
 658:	b5e1                	j	520 <vprintf+0x44>
        putc(fd, c);
 65a:	02500593          	li	a1,37
 65e:	8556                	mv	a0,s5
 660:	00000097          	auipc	ra,0x0
 664:	dae080e7          	jalr	-594(ra) # 40e <putc>
      state = 0;
 668:	4981                	li	s3,0
 66a:	bd5d                	j	520 <vprintf+0x44>
        putc(fd, '%');
 66c:	02500593          	li	a1,37
 670:	8556                	mv	a0,s5
 672:	00000097          	auipc	ra,0x0
 676:	d9c080e7          	jalr	-612(ra) # 40e <putc>
        putc(fd, c);
 67a:	85ca                	mv	a1,s2
 67c:	8556                	mv	a0,s5
 67e:	00000097          	auipc	ra,0x0
 682:	d90080e7          	jalr	-624(ra) # 40e <putc>
      state = 0;
 686:	4981                	li	s3,0
 688:	bd61                	j	520 <vprintf+0x44>
        s = va_arg(ap, char*);
 68a:	8bce                	mv	s7,s3
      state = 0;
 68c:	4981                	li	s3,0
 68e:	bd49                	j	520 <vprintf+0x44>
    }
  }
}
 690:	60a6                	ld	ra,72(sp)
 692:	6406                	ld	s0,64(sp)
 694:	74e2                	ld	s1,56(sp)
 696:	7942                	ld	s2,48(sp)
 698:	79a2                	ld	s3,40(sp)
 69a:	7a02                	ld	s4,32(sp)
 69c:	6ae2                	ld	s5,24(sp)
 69e:	6b42                	ld	s6,16(sp)
 6a0:	6ba2                	ld	s7,8(sp)
 6a2:	6c02                	ld	s8,0(sp)
 6a4:	6161                	addi	sp,sp,80
 6a6:	8082                	ret

00000000000006a8 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 6a8:	715d                	addi	sp,sp,-80
 6aa:	ec06                	sd	ra,24(sp)
 6ac:	e822                	sd	s0,16(sp)
 6ae:	1000                	addi	s0,sp,32
 6b0:	e010                	sd	a2,0(s0)
 6b2:	e414                	sd	a3,8(s0)
 6b4:	e818                	sd	a4,16(s0)
 6b6:	ec1c                	sd	a5,24(s0)
 6b8:	03043023          	sd	a6,32(s0)
 6bc:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 6c0:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 6c4:	8622                	mv	a2,s0
 6c6:	00000097          	auipc	ra,0x0
 6ca:	e16080e7          	jalr	-490(ra) # 4dc <vprintf>
}
 6ce:	60e2                	ld	ra,24(sp)
 6d0:	6442                	ld	s0,16(sp)
 6d2:	6161                	addi	sp,sp,80
 6d4:	8082                	ret

00000000000006d6 <printf>:

void
printf(const char *fmt, ...)
{
 6d6:	711d                	addi	sp,sp,-96
 6d8:	ec06                	sd	ra,24(sp)
 6da:	e822                	sd	s0,16(sp)
 6dc:	1000                	addi	s0,sp,32
 6de:	e40c                	sd	a1,8(s0)
 6e0:	e810                	sd	a2,16(s0)
 6e2:	ec14                	sd	a3,24(s0)
 6e4:	f018                	sd	a4,32(s0)
 6e6:	f41c                	sd	a5,40(s0)
 6e8:	03043823          	sd	a6,48(s0)
 6ec:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 6f0:	00840613          	addi	a2,s0,8
 6f4:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 6f8:	85aa                	mv	a1,a0
 6fa:	4505                	li	a0,1
 6fc:	00000097          	auipc	ra,0x0
 700:	de0080e7          	jalr	-544(ra) # 4dc <vprintf>
}
 704:	60e2                	ld	ra,24(sp)
 706:	6442                	ld	s0,16(sp)
 708:	6125                	addi	sp,sp,96
 70a:	8082                	ret

000000000000070c <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 70c:	1141                	addi	sp,sp,-16
 70e:	e422                	sd	s0,8(sp)
 710:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 712:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 716:	00001797          	auipc	a5,0x1
 71a:	8ea7b783          	ld	a5,-1814(a5) # 1000 <freep>
 71e:	a02d                	j	748 <free+0x3c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 720:	4618                	lw	a4,8(a2)
 722:	9f2d                	addw	a4,a4,a1
 724:	fee52c23          	sw	a4,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 728:	6398                	ld	a4,0(a5)
 72a:	6310                	ld	a2,0(a4)
 72c:	a83d                	j	76a <free+0x5e>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 72e:	ff852703          	lw	a4,-8(a0)
 732:	9f31                	addw	a4,a4,a2
 734:	c798                	sw	a4,8(a5)
    p->s.ptr = bp->s.ptr;
 736:	ff053683          	ld	a3,-16(a0)
 73a:	a091                	j	77e <free+0x72>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 73c:	6398                	ld	a4,0(a5)
 73e:	00e7e463          	bltu	a5,a4,746 <free+0x3a>
 742:	00e6ea63          	bltu	a3,a4,756 <free+0x4a>
{
 746:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 748:	fed7fae3          	bgeu	a5,a3,73c <free+0x30>
 74c:	6398                	ld	a4,0(a5)
 74e:	00e6e463          	bltu	a3,a4,756 <free+0x4a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 752:	fee7eae3          	bltu	a5,a4,746 <free+0x3a>
  if(bp + bp->s.size == p->s.ptr){
 756:	ff852583          	lw	a1,-8(a0)
 75a:	6390                	ld	a2,0(a5)
 75c:	02059813          	slli	a6,a1,0x20
 760:	01c85713          	srli	a4,a6,0x1c
 764:	9736                	add	a4,a4,a3
 766:	fae60de3          	beq	a2,a4,720 <free+0x14>
    bp->s.ptr = p->s.ptr->s.ptr;
 76a:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 76e:	4790                	lw	a2,8(a5)
 770:	02061593          	slli	a1,a2,0x20
 774:	01c5d713          	srli	a4,a1,0x1c
 778:	973e                	add	a4,a4,a5
 77a:	fae68ae3          	beq	a3,a4,72e <free+0x22>
    p->s.ptr = bp->s.ptr;
 77e:	e394                	sd	a3,0(a5)
  } else
    p->s.ptr = bp;
  freep = p;
 780:	00001717          	auipc	a4,0x1
 784:	88f73023          	sd	a5,-1920(a4) # 1000 <freep>
}
 788:	6422                	ld	s0,8(sp)
 78a:	0141                	addi	sp,sp,16
 78c:	8082                	ret

000000000000078e <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 78e:	7139                	addi	sp,sp,-64
 790:	fc06                	sd	ra,56(sp)
 792:	f822                	sd	s0,48(sp)
 794:	f426                	sd	s1,40(sp)
 796:	f04a                	sd	s2,32(sp)
 798:	ec4e                	sd	s3,24(sp)
 79a:	e852                	sd	s4,16(sp)
 79c:	e456                	sd	s5,8(sp)
 79e:	e05a                	sd	s6,0(sp)
 7a0:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 7a2:	02051493          	slli	s1,a0,0x20
 7a6:	9081                	srli	s1,s1,0x20
 7a8:	04bd                	addi	s1,s1,15
 7aa:	8091                	srli	s1,s1,0x4
 7ac:	0014899b          	addiw	s3,s1,1
 7b0:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 7b2:	00001517          	auipc	a0,0x1
 7b6:	84e53503          	ld	a0,-1970(a0) # 1000 <freep>
 7ba:	c515                	beqz	a0,7e6 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 7bc:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 7be:	4798                	lw	a4,8(a5)
 7c0:	02977f63          	bgeu	a4,s1,7fe <malloc+0x70>
  if(nu < 4096)
 7c4:	8a4e                	mv	s4,s3
 7c6:	0009871b          	sext.w	a4,s3
 7ca:	6685                	lui	a3,0x1
 7cc:	00d77363          	bgeu	a4,a3,7d2 <malloc+0x44>
 7d0:	6a05                	lui	s4,0x1
 7d2:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 7d6:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 7da:	00001917          	auipc	s2,0x1
 7de:	82690913          	addi	s2,s2,-2010 # 1000 <freep>
  if(p == (char*)-1)
 7e2:	5afd                	li	s5,-1
 7e4:	a895                	j	858 <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 7e6:	00001797          	auipc	a5,0x1
 7ea:	82a78793          	addi	a5,a5,-2006 # 1010 <base>
 7ee:	00001717          	auipc	a4,0x1
 7f2:	80f73923          	sd	a5,-2030(a4) # 1000 <freep>
 7f6:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 7f8:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 7fc:	b7e1                	j	7c4 <malloc+0x36>
      if(p->s.size == nunits)
 7fe:	02e48c63          	beq	s1,a4,836 <malloc+0xa8>
        p->s.size -= nunits;
 802:	4137073b          	subw	a4,a4,s3
 806:	c798                	sw	a4,8(a5)
        p += p->s.size;
 808:	02071693          	slli	a3,a4,0x20
 80c:	01c6d713          	srli	a4,a3,0x1c
 810:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 812:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 816:	00000717          	auipc	a4,0x0
 81a:	7ea73523          	sd	a0,2026(a4) # 1000 <freep>
      return (void*)(p + 1);
 81e:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 822:	70e2                	ld	ra,56(sp)
 824:	7442                	ld	s0,48(sp)
 826:	74a2                	ld	s1,40(sp)
 828:	7902                	ld	s2,32(sp)
 82a:	69e2                	ld	s3,24(sp)
 82c:	6a42                	ld	s4,16(sp)
 82e:	6aa2                	ld	s5,8(sp)
 830:	6b02                	ld	s6,0(sp)
 832:	6121                	addi	sp,sp,64
 834:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 836:	6398                	ld	a4,0(a5)
 838:	e118                	sd	a4,0(a0)
 83a:	bff1                	j	816 <malloc+0x88>
  hp->s.size = nu;
 83c:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 840:	0541                	addi	a0,a0,16
 842:	00000097          	auipc	ra,0x0
 846:	eca080e7          	jalr	-310(ra) # 70c <free>
  return freep;
 84a:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 84e:	d971                	beqz	a0,822 <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 850:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 852:	4798                	lw	a4,8(a5)
 854:	fa9775e3          	bgeu	a4,s1,7fe <malloc+0x70>
    if(p == freep)
 858:	00093703          	ld	a4,0(s2)
 85c:	853e                	mv	a0,a5
 85e:	fef719e3          	bne	a4,a5,850 <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 862:	8552                	mv	a0,s4
 864:	00000097          	auipc	ra,0x0
 868:	b7a080e7          	jalr	-1158(ra) # 3de <sbrk>
  if(p == (char*)-1)
 86c:	fd5518e3          	bne	a0,s5,83c <malloc+0xae>
        return 0;
 870:	4501                	li	a0,0
 872:	bf45                	j	822 <malloc+0x94>
