CC = gcc
CFLAGS = -std=c11 -Wall -Wextra

micro: micro.tab.c lex.yy.c
	$(CC) $(CFLAGS) micro.tab.c lex.yy.c -o micro

micro.tab.c micro.tab.h &: micro.y
	bison -Wall -d -o micro.tab.c micro.y

lex.yy.c: micro.l micro.tab.h
	flex -o lex.yy.c micro.l

.PHONY: clean
clean:
	rm -f micro micro.tab.c micro.tab.h lex.yy.c
