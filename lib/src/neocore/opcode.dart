// since some items have the same value, so they cannot be organized by using an enum
class OpCode {
  // An empty array of bytes is pushed onto the stack.
  static int push0 = 0x00;
  static int pushf = 0x00;
  // 0x01-0x4b the next bytes is data to be pushed onto the stack
  static int pushbytes1 = 0x01;
  static int pushbytes75 = 0x4b;
  // the next byte contains the number of bytes to be pushed onto the stack.
  static int pushdata1 = 0x4c;
  // the next two bytes contain the number of bytes to be pushed onto the stack.
  static int pushdata2 = 0x4d;
  // the next four bytes contain the number of bytes to be pushed onto the stack.
  static int pushdata4 = 0x4e;
  static int pushm1 = 0x4f; // the number -1 is pushed onto the stack.
  static int push1 = 0x51; // the number 1 is pushed onto the stack.
  static int pusht = 0x01;
  static int push2 = 0x52; // the number 2 is pushed onto the stack.
  static int push3 = 0x53; // the number 3 is pushed onto the stack.
  static int push4 = 0x54; // the number 4 is pushed onto the stack.
  static int push5 = 0x55; // the number 5 is pushed onto the stack.
  static int push6 = 0x56; // the number 6 is pushed onto the stack.
  static int push7 = 0x57; // the number 7 is pushed onto the stack.
  static int push8 = 0x58; // the number 8 is pushed onto the stack.
  static int push9 = 0x59; // the number 9 is pushed onto the stack.
  static int push10 = 0x5a; // the number 10 is pushed onto the stack.
  static int push11 = 0x5b; // the number 11 is pushed onto the stack.
  static int push12 = 0x5c; // the number 12 is pushed onto the stack.
  static int push13 = 0x5d; // the number 13 is pushed onto the stack.
  static int push14 = 0x5e; // the number 14 is pushed onto the stack.
  static int push15 = 0x5f; // the number 15 is pushed onto the stack.
  static int push16 = 0x60; // the number 16 is pushed onto the stack.

  // flow control
  static int nop = 0x61; // does nothing.
  static int jmp = 0x62;
  static int jmpif = 0x63;
  static int jmpifnot = 0x64;
  static int call = 0x65;
  static int ret = 0x66;
  static int appcall = 0x67;
  static int syscall = 0x68;
  static int tailcall = 0x69;
  static int dupfromaltstack = 0x6a;

  // stack
  //
  // puts the input onto the top of the alt stack. removes it from the main stack.
  static int toaltstack = 0x6b;
  // puts the input onto the top of the main stack. removes it from the alt stack.
  static int fromaltstack = 0x6c;
  static int xdrop = 0x6d;
  static int xswap = 0x72;
  static int xtuck = 0x73;
  static int depth = 0x74; // puts the number of stack items onto the stack.
  static int drop = 0x75; // removes the top stack item.
  static int dup = 0x76; // duplicates the top stack item.
  static int nip = 0x77; // removes the second-to-top stack item.
  static int over = 0x78; // copies the second-to-top stack item to the top.
  static int pick = 0x79; // the item n back in the stack is copied to the top.
  static int roll = 0x7a; // the item n back in the stack is moved to the top.
  // the top three items on the stack are rotated to the left.
  static int rot = 0x7b;
  static int swap = 0x7c; // the top two items on the stack are swapped.
  // the item at the top of the stack is copied and inserted before the second-to-top item.
  static int tuck = 0x7d;

  // splice
  static int cat = 0x7e; // concatenates two strings.
  static int substr = 0x7f; // returns a section of a string.
  // keeps only characters left of the specified point in a string.
  static int left = 0x80;
  // keeps only characters right of the specified point in a string.
  static int right = 0x81;
  static int size = 0x82; // returns the length of the input string.

  // bitwise logic
  static int invert = 0x83; // flips all of the bits in the input.
  static int and = 0x84; // boolean and between each bit in the inputs.
  static int or = 0x85; // boolean or between each bit in the inputs.
  static int xor = 0x86; // boolean exclusive or between each bit in the inputs.
  // returns 1 if the inputs are exactly equal 0 otherwise.
  static int equal = 0x87;
  // equalverify :int = 0x88; // same as equal but runs verify afterward.
  // reserved1 :int = 0x89; // transaction is invalid unless occuring in an unexecuted if branch
  // reserved2 :int = 0x8a; // transaction is invalid unless occuring in an unexecuted if branch

  // arithmetic
  // arithmetic noteinputs are limited to signed 32-bit integers but may overflow their output.
  static int inc = 0x8b; // 1 is added to the input.
  static int dec = 0x8c; // 1 is subtracted from the input.
  // sal           :int = 0x8d; // the input is multiplied by 2.
  // sar           :int = 0x8e; // the input is divided by 2.
  static int negate = 0x8f; // the sign of the input is flipped.
  static int abs = 0x90; // the input is made positive.
  // if the input is 0 or 1 it is flipped. otherwise the output will be 0.
  static int not = 0x91;
  static int nz = 0x92; // returns 0 if the input is 0. 1 otherwise.
  static int add = 0x93; // a is added to b.
  static int sub = 0x94; // b is subtracted from a.
  static int mul = 0x95; // a is multiplied by b.
  static int div = 0x96; // a is divided by b.
  static int mod = 0x97; // returns the remainder after dividing a by b.
  static int shl = 0x98; // shifts a left b bits preserving sign.
  static int shr = 0x99; // shifts a right b bits preserving sign.
  // if both a and b are not 0 the output is 1. otherwise 0.
  static int booland = 0x9a;
  static int boolor = 0x9b; // if a or b is not 0 the output is 1. otherwise 0.
  static int numequal = 0x9c; // returns 1 if the numbers are equal 0 otherwise.
  // returns 1 if the numbers are not equal 0 otherwise.
  static int numnotequal = 0x9e;
  static int lt = 0x9f; // returns 1 if a is less than b 0 otherwise.
  static int gt = 0xa0; // returns 1 if a is greater than b 0 otherwise.
  // returns 1 if a is less than or equal to b 0 otherwise.
  static int lte = 0xa1;
  // returns 1 if a is greater than or equal to b 0 otherwise.
  static int gte = 0xa2;
  static int min = 0xa3; // returns the smaller of a and b.
  static int max = 0xa4; // returns the larger of a and b.
  // returns 1 if x is within the specified range (left-inclusive) 0 otherwise.
  static int within = 0xa5;

  // crypto
  // ripemd160 :int = 0xa6; // the input is hashed using ripemd-160.
  static int sha1 = 0xa7; // the input is hashed using sha-1.
  static int sha256 = 0xa8; // the input is hashed using sha-256.
  static int hash160 = 0xa9;
  static int hash256 = 0xaa;
  // the entire transaction's outputs inputs and script (from the most recently-executed codeseparator to the end) are hashed. the signature used by checksig must be a valid signature for this hash and  key. if it is 1 is returned 0 otherwise.
  static int checksig = 0xac;
  // for each signature and  key pair checksig is executed. if more  keys than signatures are listed some key/sig pairs can fail. all signatures need to match a  key. if all signatures are valid 1 is returned 0 otherwise. due to a bug one extra unused value is removed from the stack.
  static int checkmultisig = 0xae;

  // array
  static int arraysize = 0xc0;
  static int pack = 0xc1;
  static int unpack = 0xc2;
  static int pickitem = 0xc3;
  static int setitem = 0xc4;
  static int newarray = 0xc5;
  static int newstruct = 0xc6;
  static int newmap = 0xc7;
  static int append = 0xc8;
  static int reverse = 0xc9;
  static int remove = 0xca;
  static int haskey = 0xcb;
  static int keys = 0xcc;
  static int values = 0xcd;

  // exceptionthrow :int = 0xf0
  static int throwifnot = 0xf1;
}
