import java.io.*;
import java.util.StringTokenizer;

class AssemblyLine {
    public static final int NULL_FORM       = 0;
    public static final int RRR_FORM        = 1;
    public static final int RRI_FORM        = 2;
    public static final int RI_FORM         = 3;
    //public static final int PRD_FORM        = 4;// prd, pwr instructions
    public static final int LABEL_FORM      = 5; 
    public static final int CONSTANT_FORM   = 6;
    public static final int JUMP_FORM       = 7;
    public static final int NOP_FORM        = 8;
    public static final int ZERO_FORM       = 9;
    public static final int DATA_FORM       = 10;

    public static final int BOGUS_IMM       = (1 << 14);

    public String srcLine;
    public int type;
    public int src1;
    public int src2;
    public int dst;
    public int immediateVal;
    public boolean hexVal;
    public String label;
    public String immediateRef;
    public int lineNum;
    public int opcode;
    public boolean relative;


    AssemblyLine(String s, int lineID) {
        srcLine = s;
        immediateRef = null;
        immediateVal = BOGUS_IMM;  // guaranteed to be wrong.
        hexVal = false;
        lineNum = -1;
        opcode = -1;
        relative = false;


        if (s == null) {
            type = NULL_FORM;
            return;
        }

        StringTokenizer st = new StringTokenizer(s, " ,\t\n\r", false);
        if (!st.hasMoreTokens()) {
            type = NULL_FORM;
            return;
        }

        String token = st.nextToken();

        if (token.startsWith("//") || 
            token.startsWith("!")) {
            // it's a comment
            type = NULL_FORM;
            return;
        }

        lineNum = lineID;

        if (token.startsWith(".")) {
            // it's a label or a constant
            label = new String(token);
            if (!st.hasMoreTokens()) {
                if (!label.endsWith(":")) {
                    type = NULL_FORM;
                    PrintErr("Labels must end with a colon (:)");
                }
                label = label.substring(0, label.length()-1);
                type = LABEL_FORM;
                return;
            }
            // constant
            token = st.nextToken();
            if (token.startsWith("0x")) {
                token = token.substring(2);
                try {
                    // converting the next token from hex
                    immediateVal = Integer.parseInt(token, 16);
                    hexVal = true;
                } catch (NumberFormatException nfe) {
                    PrintErr("Bad hex number " + token);
                    type = NULL_FORM;
                    return;
                }
            } else {
                try {
                    // converting the next token from base-10
                    immediateVal = Integer.parseInt(token);
                    hexVal = false;
                } catch (NumberFormatException nfe) {
                    PrintErr("Unknown opcode: " + token);
                    type = NULL_FORM;
                    return;
                }
            }
            type = CONSTANT_FORM;
            if (st.hasMoreTokens()) {
                String ntk = st.nextToken();
                if (!(ntk.startsWith("//") ||
                      ntk.startsWith("!"))) {
                    PrintErr("Ignoring extra input past constant");
                }
            }
            return;
        }

        src1 = -1;
        src2 = -1;
        dst = -1;

        // parse opcode and set type
        opcode = convertOpcode(token);
        if (opcode < 0) {
            type = NULL_FORM;
            return;
        }

        switch (type) {
        case NOP_FORM:
            break;

        case RRI_FORM:
            if (0 > parseReg(st,false)) {
                type = NULL_FORM; 
                return; 
            }
            if (0 > parseReg(st,false)) {
                type = NULL_FORM; 
                return; 
            }
            if (!parseImm(st)) {
                type = NULL_FORM; 
                return; 
            }
            break;

        case RRR_FORM:
            if (0 > parseReg(st,false)) {
                type = NULL_FORM; 
                return; 
            }
            if (0 > parseReg(st,false)) {
                type = NULL_FORM; 
                return; 
            }
            if (src2 >= 0) break; // no more registers needed
            if (0 > parseReg(st,false)) {
                type = NULL_FORM; 
                return; 
            }
            break;

        case RI_FORM:
            if (0 > parseReg(st,true)) {
                type = NULL_FORM; 
                return; 
            }
            if (immediateVal == BOGUS_IMM) {  // SIIC already set imm field
                if (!parseImm(st)) {
                    type = NULL_FORM; 
                    return; 
                }
            }
            break;
            //case PRD_FORM:
            //int regnum = parseReg(st,false);
            //// for pwr instr's Rp reg comes 1st and is in [0 1]
            //if (regnum < 0 || (opcode == 7  && regnum > 1)) {
            //PrintErr("Pwr specified monitor register " + regnum);
            //type = NULL_FORM; 
            //return; 
            //}
            //regnum = parseReg(st,false);
            //// for prd instr's Rp reg comes 2nd and is in [0 1]
            //if (regnum < 0 || (opcode == 19  && regnum > 1)) {
            //PrintErr("Prd specified monitor register " + regnum);
            //type = NULL_FORM; 
            //return; 
            //}
            //break;

        case JUMP_FORM:
            if (!parseImm(st)) {
                type = NULL_FORM; 
                return; 
            }
            break;

        case DATA_FORM:
            if (!parseImm(st)) {
                type = NULL_FORM; 
                return; 
            }
            break;

        case ZERO_FORM:
            if (!parseImm(st)) {
                type = NULL_FORM; 
                return; 
            }
            break;


        default:
            // can't be returned
            System.err.println("Fatal error!\n");
            break;
        }
        if (st.hasMoreTokens()) {
            String ntok = st.nextToken();
            if (!(ntok.startsWith("//") ||
                  ntok.startsWith("!"))) {
                PrintErr("Ignoring extra input");
            }
        }
        return;
    }

    private boolean parseImm(StringTokenizer st) {
        if (!st.hasMoreTokens()) return false;
        String token = st.nextToken();
        if ((token.startsWith(".")) ||
            (token.startsWith("L.")) ||    // Lower byte only
            (token.startsWith("U."))) {    // Upper byte only
            // it's a label
            immediateRef = token;
        } else if (token.startsWith("0x")) {
            token = token.substring(2);
            try {
                // converting the next token from hex
                immediateVal = Integer.parseInt(token, 16);
                hexVal = true;
            } catch (NumberFormatException nfe) {
                PrintErr("Bad hex number " + token);
                type = NULL_FORM;
                return false;
            }
        } else {
            try {
                // converting the next token from base-10
                immediateVal = Integer.parseInt(token);
                hexVal = false;
            } catch (NumberFormatException nfe) {
                PrintErr("Couldn't parse immediate value " + token);
                type = NULL_FORM;
                return false; 
            }
        }
        return true;
    }    


    private int parseReg(StringTokenizer st, boolean useRs) {
        if (!st.hasMoreTokens()) return -1;
        String token = st.nextToken();
        if (!token.startsWith("r") &&
            !token.startsWith("%r")) {
            PrintErr("Unknown register specifier " + token);
            type = NULL_FORM;
            return -1;
        }
        if (token.length() > 3) {
            PrintErr("Unknown register specifier " + token);
            type = NULL_FORM;
            return -1;
        }

        int temp = (int) (token.charAt(token.length()-1) - '0');
        if (temp > 7 || temp < 0) {
            type = NULL_FORM;
            PrintErr("Unknown register specifier " + token);
            return -1;
        }

        if (dst < 0 && useRs == false) {
            dst = temp;
        } else if (src1 < 0) {
            src1 = temp;
        } else if (src2 < 0) {
            src2 = temp;
        } else {
            PrintErr("Error assigning register specifier\n");
            type = NULL_FORM;
            return -1;
        }
        return temp;
    }


    // parses opcode and sets type, returns opcode index
    private int convertOpcode(String Opcode) {
        switch (Opcode.charAt(0)) {
        case 'A':
        case 'a':
            if (Opcode.equalsIgnoreCase("add")) {
                type = RRR_FORM;
                return 0x1b;
            } else if (Opcode.equalsIgnoreCase("addi")) {
                type = RRI_FORM;
                return 8;
            } else if (Opcode.equalsIgnoreCase("andni")) {
                type = RRI_FORM;
                return 0xb;
            } else if (Opcode.equalsIgnoreCase("andn")) {
                type = RRR_FORM;
                return 0x7b;
                /* defunct
                   } else if (Opcode.equalsIgnoreCase("addu")) {
                   type = RRR_FORM;
                   return 14;
                   } else if (Opcode.equalsIgnoreCase("addc")) {
                   type = RRR_FORM;
                   return 30;
                */
            } else {
                PrintErr("Unknown opcode: " + Opcode);
                return -1;
            }


        case 'B':
        case 'b':
            if (Opcode.equalsIgnoreCase("btr")) {
                type = RRR_FORM;
                src2 = 0;  // no third register needed
                return 0x19;
            } else if (Opcode.equalsIgnoreCase("beqz")) {
                type = RI_FORM;
                relative = true;
                return 12;
            } else if (Opcode.equalsIgnoreCase("bnez")) {
                type = RI_FORM;
                relative = true;
                return 13;
            } else if (Opcode.equalsIgnoreCase("bltz")) {
                type = RI_FORM;
                relative = true;
                return 14;
            } else if (Opcode.equalsIgnoreCase("bgez")) {
                type = RI_FORM;
                relative = true;
                return 15;
            } else {
                PrintErr("Unknown opcode: " + Opcode);
                return -1;
            }

        case 'D':
        case 'd':
            if (Opcode.equalsIgnoreCase("data")) {
                type = DATA_FORM;
                relative = false;
                return 0;
            } else {
                PrintErr("Unknown opcode: " + Opcode);
                return -1;
            }

        case 'H':
        case 'h':
            if (Opcode.equalsIgnoreCase("halt")) {
                type = NOP_FORM;
                return 0;
            } else {
                PrintErr("Unknown opcode: " + Opcode);
                return -1;
            }


        case 'J':
        case 'j':
            if (Opcode.equalsIgnoreCase("j")) {
                type = JUMP_FORM;
                relative = true;
                return 4;
            } else if (Opcode.equalsIgnoreCase("jal")) {
                type = JUMP_FORM;
                relative = true;
                return 6;
            } else if (Opcode.equalsIgnoreCase("jalr")) {
                type = RI_FORM;
                return 7;
            } else if (Opcode.equalsIgnoreCase("jr")) {
                type = RI_FORM;
                return 5;
            } else {
                PrintErr("Unknown opcode: " + Opcode);
                return -1;
            }


        case 'L':
        case 'l':
            if (Opcode.equalsIgnoreCase("ld")) {
                type = RRI_FORM;
                return 17;
            } else if (Opcode.equalsIgnoreCase("lbi")) {
                type = RI_FORM;
                return 24;
            } else if (Opcode.equalsIgnoreCase("lli")) {
                type = RI_FORM;
                return 18;   // use SLBI; this works for the sequence lui/lli
            } else if (Opcode.equalsIgnoreCase("lui")) {
                type = RI_FORM;
                return 18;   // use SLBI; this works for the sequence lui/lli
            } else {
                PrintErr("Unknown opcode: " + Opcode);
                return -1;
            }


        case 'N':
        case 'n':
            if (Opcode.equalsIgnoreCase("nop")) {
                type = NOP_FORM;
                return 1;
                //} else if (Opcode.equalsIgnoreCase("nandi")) {
                //type = RRI_FORM;
                //return 10;
                //} else if (Opcode.equalsIgnoreCase("nand")) {
                //type = RRR_FORM;
                //return 11;
            } else {
                PrintErr("Unknown opcode: " + Opcode);
                return -1;
            }

        case 'P':
        case 'p':
            //if (Opcode.equalsIgnoreCase("pwr")) {
            //type = PRD_FORM;
            //return 7;
            //} else if (Opcode.equalsIgnoreCase("prd")) {
            //type = PRD_FORM;
            //return 19;
            //} else {
            PrintErr("Unknown opcode: " + Opcode);
            return -1;
            //}

        case 'R':
        case 'r':
            if (Opcode.equalsIgnoreCase("rol")) {
                type = RRR_FORM;
                return 0x1a;
            } else if (Opcode.equalsIgnoreCase("roli")) {
                type = RRI_FORM;
                return 0x14;
            } else if (Opcode.equalsIgnoreCase("ror")) {
                type = RRR_FORM;
                return 0x5a;
            } else if (Opcode.equalsIgnoreCase("rori")) {
                type = RRI_FORM;
                return 0x16;
            } else if (Opcode.equalsIgnoreCase("rti")) {
                type = NOP_FORM;
                return 3;
            } else {
                PrintErr("Unknown opcode: " + Opcode);
                return -1;
            }

        case 'S':
        case 's':
            if (Opcode.equalsIgnoreCase("sub")) {
                type = RRR_FORM;
                return 0x3b;
            } else if (Opcode.equalsIgnoreCase("sll")) {
                type = RRR_FORM;
                return 0x3a;
            } else if (Opcode.equalsIgnoreCase("srl")) {
                type = RRR_FORM;
                return 0x7a;
            } else if (Opcode.equalsIgnoreCase("seq")) {
                type = RRR_FORM;
                return 0x1c;
            } else if (Opcode.equalsIgnoreCase("slt")) {
                type = RRR_FORM;
                return 0x1d;
            } else if (Opcode.equalsIgnoreCase("sle")) {
                type = RRR_FORM;
                return 0x1e;
            } else if (Opcode.equalsIgnoreCase("sco")) {
                type = RRR_FORM;
                return 0x1f;
            } else if (Opcode.equalsIgnoreCase("subi")) {
                type = RRI_FORM;
                return 9;
            } else if (Opcode.equalsIgnoreCase("slli")) {
                type = RRI_FORM;
                return 0x15;
            } else if (Opcode.equalsIgnoreCase("srli")) {
                type = RRI_FORM;
                return 0x17;
            } else if (Opcode.equalsIgnoreCase("st")) {
                type = RRI_FORM;
                return 0x10;
            } else if (Opcode.equalsIgnoreCase("stu")) {
                type = RRI_FORM;
                return 0x13;
            } else if (Opcode.equalsIgnoreCase("slbi")) {
                type = RI_FORM;
                return 0x12;
            } else if (Opcode.equalsIgnoreCase("siic")) {
                immediateVal = 0;  // no explicit immediate needed
                type = RI_FORM;
                return 2;
            } else {
                PrintErr("Unknown opcode: " + Opcode);
                return -1;
            }


        case 'X':
        case 'x':
            if (Opcode.equalsIgnoreCase("xor")) {
                type = RRR_FORM;
                return 0x5b;
            } else if (Opcode.equalsIgnoreCase("xori")) {
                type = RRI_FORM;
                return 0x0a;
            } else {
                PrintErr("Unknown opcode: " + Opcode);
                return -1;
            }

        case 'Z':
        case 'z':
            if (Opcode.equalsIgnoreCase("zerofill")) {
                type = ZERO_FORM;
                return 0;
            } else {
                PrintErr("Unknown opcode: " + Opcode);
                return -1;
            }

        }
        PrintErr("Unknown opcode: " + Opcode);
        return -1;
    }

    void PrintErr(String err) {
        System.err.println(lineNum + ": " + srcLine);
        System.err.println("\t" + err);
    }

    public void checkImmediateRange() {
        int shiftAmt = 0;

        switch (type) {
        case JUMP_FORM:
            shiftAmt = Assemble.JUMP_DISP_LEN;
            break;
        case RRI_FORM:
            shiftAmt = Assemble.IMMEDIATE_LEN;
            break;
        case RI_FORM:
            shiftAmt = Assemble.LOAD_IMMEDIATE_LEN;
            break;
        case DATA_FORM:
            shiftAmt = Assemble.DATA_IMMEDIATE_LEN;
            break;
        default:
            return;
        }

        // There are several cases we consider OK:
        //    immediateVal is positive and < limit.
        //    immediateVal is negative and >= -limit.
        //    immediateVal is positive and < (2*limit); this is
        //        ok if the literal is *not* sign extended, but
        //        don't know that here so we call it ok.
        //    immediateVal was entered in hex, and it looks
        //        positive but is meant to be negative,
        //        like 0xfe intending to mean -2.

        int limit = 1 << (shiftAmt - 1);
        int limit2 = 1 << shiftAmt;

        if ((immediateVal >= limit2) && hexVal) {
            // Allow the form 0x80 - 0xff as negative
            if (immediateVal < 256 && immediateVal >= 128)
                immediateVal -= 256;
            // Allow the form 0x800 - 0xfff as negative
            else if (immediateVal < 4096 && immediateVal >= 2048)
                immediateVal -= 4096;
            // Allow the form 0x8000 - 0xffff as negative
            else if (immediateVal < 65536 && immediateVal >= 32768)
                immediateVal -= 65536;
        }

        if (immediateVal < -limit) {
            PrintErr("Could not fit negative integer " + immediateVal + 
                     " into instruction.");
            type = NULL_FORM;
            return;
        }

        if (immediateVal >= limit2) {
            PrintErr("Could not fit positive integer " + immediateVal + 
                     " into instruction.");
            type = NULL_FORM;
            return;
        }

        // Truncate to make sure it fits in its field
        // (this is important for negative numbers)
        int mask = -1 << shiftAmt;
        mask = ~mask;
        immediateVal &= mask;
        return;
    }

} // class AssemblyLine