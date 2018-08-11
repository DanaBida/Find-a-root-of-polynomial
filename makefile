#format is target-name: target dependencies
#{-tab-}actions

# All Targets
all: main

# Tool invocations
# Executable "hello" depends on the files hello.o and run.o.
main:main.o 
	gcc -g -Wall -o root main.o 

main.o: main.s
	nasm -g -f elf64 main.s -o main.o
	
#tell make that "clean" is not a file name!
.PHONY: clean

#Clean the build directory
clean: 
	rm -f main.o  root

