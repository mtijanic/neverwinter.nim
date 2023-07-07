{.passL: "-lstdc++".}
const cppFlags = "-std=c++14"
when defined(linux) or defined(mingw):
  {.passL: "-static".}
{.compile("native/exostring.cpp", cppFlags).}
{.compile("native/scriptcompcore.cpp", cppFlags).}
{.compile("native/scriptcomplexical.cpp", cppFlags).}
{.compile("native/scriptcompparsetree.cpp", cppFlags).}
{.compile("native/scriptcompidentspec.cpp", cppFlags).}
{.compile("native/scriptcompfinalcode.cpp", cppFlags).}
{.compile("compilerapi.cpp", cppFlags).}

import std/[tables, strutils]

import neverwinter/restype

type
  CScriptCompiler* = distinct pointer

  LangSpec* = tuple
    lang: string
    src, bin, dbg: ResType

  CompilerError* = object of Defect

  ResManWriteToFile* = proc (fn: cstring, resType: uint16, pData: ptr uint8, size: csize_t, bin: bool): int32 {.cdecl.}
  ResManLoadScriptSourceFile* = proc (fn: cstring, resType: uint16): cstring {.cdecl.}
  TlkResolve* = proc (r: uint32): cstring {.cdecl.}

const CompileErrorTlk* = {
  560: "ERROR: UNEXPECTED CHARACTER",
  561: "ERROR: FATAL COMPILER ERROR",
  562: "ERROR: PROGRAM COMPOUND STATEMENT AT START",
  563: "ERROR: UNEXPECTED END COMPOUND STATEMENT",
  564: "ERROR: AFTER COMPOUND STATEMENT AT END",
  565: "ERROR: PARSING VARIABLE LIST",
  566: "ERROR: UNKNOWN STATE IN COMPILER",
  567: "ERROR: INVALID DECLARATION TYPE",
  568: "ERROR: NO LEFT BRACKET ON EXPRESSION",
  569: "ERROR: NO RIGHT BRACKET ON EXPRESSION",
  570: "ERROR: BAD START OF STATEMENT",
  571: "ERROR: NO LEFT BRACKET ON ARG LIST",
  572: "ERROR: NO RIGHT BRACKET ON ARG LIST",
  573: "ERROR: NO SEMICOLON AFTER EXPRESSION",
  574: "ERROR: PARSING ASSIGNMENT STATEMENT",
  575: "ERROR: BAD LVALUE",
  576: "ERROR: BAD CONSTANT TYPE",
  577: "ERROR: IDENTIFIER LIST FULL",
  578: "ERROR: NON INTEGER ID FOR INTEGER CONSTANT",
  579: "ERROR: NON FLOAT ID FOR FLOAT CONSTANT",
  580: "ERROR: NON STRING ID FOR STRING CONSTANT",
  581: "ERROR: VARIABLE ALREADY USED WITHIN SCOPE",
  582: "ERROR: VARIABLE DEFINED WITHOUT TYPE",
  583: "ERROR: INCORRECT VARIABLE STATE LEFT ON STACK",
  584: "ERROR: NON INTEGER EXPRESSION WHERE INTEGER REQUIRED",
  585: "ERROR: VOID EXPRESSION WHERE NON VOID REQUIRED",
  586: "ERROR: INVALID PARAMETERS FOR ASSIGNMENT",
  587: "ERROR: DECLARATION DOES NOT MATCH PARAMETERS",
  588: "ERROR: LOGICAL OPERATION HAS INVALID OPERANDS",
  589: "ERROR: EQUALITY TEST HAS INVALID OPERANDS",
  590: "ERROR: COMPARISON TEST HAS INVALID OPERANDS",
  591: "ERROR: SHIFT OPERATION HAS INVALID OPERANDS",
  592: "ERROR: ARITHMETIC OPERATION HAS INVALID OPERANDS",
  593: "ERROR: UNKNOWN OPERATION IN SEMANTIC CHECK",
  594: "ERROR: SCRIPT TOO LARGE",
  595: "ERROR: RETURN STATEMENT HAS NO PARAMETERS",
  596: "ERROR: NO WHILE AFTER DO KEYWORD",
  597: "ERROR: FUNCTION DEFINITION MISSING NAME",
  598: "ERROR: FUNCTION DEFINITION MISSING PARAMETER LIST",
  599: "ERROR: MALFORMED PARAMETER LIST",
  600: "ERROR: BAD TYPE SPECIFIER",
  601: "ERROR: NO SEMICOLON AFTER STRUCTURE",
  602: "ERROR: ELLIPSIS IN IDENTIFIER",
  603: "ERROR: FILE NOT FOUND",
  604: "ERROR: INCLUDE RECURSIVE",
  605: "ERROR: INCLUDE TOO MANY LEVELS",
  606: "ERROR: PARSING RETURN STATEMENT",
  607: "ERROR: PARSING IDENTIFIER LIST",
  608: "ERROR: PARSING FUNCTION DECLARATION",
  609: "ERROR: DUPLICATE FUNCTION IMPLEMENTATION",
  610: "ERROR: TOKEN TOO LONG",
  611: "ERROR: UNDEFINED STRUCTURE",
  612: "ERROR: LEFT OF STRUCTURE PART NOT STRUCTURE",
  613: "ERROR: RIGHT OF STRUCTURE PART NOT FIELD IN STRUCTURE",
  614: "ERROR: UNDEFINED FIELD IN STRUCTURE",
  615: "ERROR: STRUCTURE REDEFINED",
  616: "ERROR: VARIABLE USED TWICE IN SAME STRUCTURE",
  617: "ERROR: FUNCTION IMPLEMENTATION AND DEFINITION DIFFER",
  618: "ERROR: MISMATCHED TYPES",
  619: "ERROR: INTEGER NOT AT TOP OF STACK",
  620: "ERROR: RETURN TYPE AND FUNCTION TYPE MISMATCHED",
  621: "ERROR: NOT ALL CONTROL PATHS RETURN A VALUE",
  622: "ERROR: UNDEFINED IDENTIFIER",
  623: "ERROR: NO FUNCTION MAIN IN SCRIPT",
  624: "ERROR: FUNCTION MAIN MUST HAVE VOID RETURN VALUE",
  625: "ERROR: FUNCTION MAIN MUST HAVE NO PARAMETERS",
  626: "ERROR: NON VOID FUNCTION CANNOT BE A STATEMENT",
  627: "ERROR: BAD VARIABLE NAME",
  628: "ERROR: NON OPTIONAL PARAMETER CANNOT FOLLOW OPTIONAL PARAMETER",
  629: "ERROR: TYPE DOES NOT HAVE AN OPTIONAL PARAMETER",
  630: "ERROR: NON CONSTANT IN FUNCTION DECLARATION",
  631: "ERROR: PARSING CONSTANT VECTOR",
  1594: "ERROR: OPERAND MUST BE AN INTEGER LVALUE",
  1595: "ERROR: CONDITIONAL REQUIRES SECOND EXPRESSION",
  1596: "ERROR: CONDITIONAL MUST HAVE MATCHING RETURN TYPES",
  1597: "ERROR: MULTIPLE DEFAULT STATEMENTS WITHIN SWITCH",
  1598: "ERROR: MULTIPLE CASE CONSTANT STATEMENTS WITHIN SWITCH",
  1599: "ERROR: CASE PARAMETER NOT A CONSTANT INTEGER",
  1600: "ERROR: SWITCH MUST EVALUATE TO AN INTEGER",
  1601: "ERROR: NO COLON AFTER DEFAULT LABEL",
  1602: "ERROR: NO COLON AFTER CASE LABEL",
  1603: "ERROR: NO SEMICOLON AFTER STATEMENT",
  4834: "ERROR: BREAK OUTSIDE OF LOOP OR CASE STATEMENT",
  4835: "ERROR: TOO MANY PARAMETERS ON FUNCTION",
  4836: "ERROR: UNABLE TO OPEN FILE FOR WRITING",
  4855: "ERROR: UNTERMINATED STRING CONSTANT",
  5182: "ERROR: NO FUNCTION INTSC IN SCRIPT",
  5183: "ERROR: FUNCTION INTSC MUST HAVE VOID RETURN VALUE",
  5184: "ERROR: FUNCTION INTSC MUST HAVE NO PARAMETERS",
  6804: "ERROR: JUMPING OVER DECLARATION STATEMENTS CASE DISALLOWED",
  6805: "ERROR: JUMPING OVER DECLARATION STATEMENTS DEFAULT DISALLOWED",
  6823: "ERROR: ELSE WITHOUT CORRESPONDING IF",
  10407: "ERROR: IF CONDITION CANNOT BE FOLLOWED BY A NULL STATEMENT",
  3741: "ERROR: INVALID TYPE FOR CONST KEYWORD",
  3742: "ERROR: CONST KEYWORD CANNOT BE USED ON NON GLOBAL VARIABLES",
  3752: "ERROR: INVALID VALUE ASSIGNED TO CONSTANT",
  9081: "ERROR: SWITCH CONDITION CANNOT BE FOLLOWED BY A NULL STATEMENT",
  9082: "ERROR: WHILE CONDITION CANNOT BE FOLLOWED BY A NULL STATEMENT",
  9083: "ERROR: FOR STATEMENT CANNOT BE FOLLOWED BY A NULL STATEMENT",
  9155: "ERROR: CANNOT INCLUDE THIS FILE TWICE",
  40104: "ERROR: ELSE CANNOT BE FOLLOWED BY A NULL STATEMENT"
}.toTable

proc resolveTlk(r: uint32): cstring {.cdecl.} =
  var buf {.threadvar.}: string
  if CompileErrorTlk.contains(r.int):
    buf = CompileErrorTlk[r.int]
  else:
    buf = "[unresolved tlk: " & $r & "]"
  buf.cstring

proc scriptCompApiNewCompiler(
  lang: cstring, src, bin, dbt: cint,
  writer: ResManWriteToFile,
  resolver: ResManLoadScriptSourceFile,
  tlk: TlkResolve = resolveTlk,
  writeDebug: bool
): CScriptCompiler {.importc.}

proc newCompiler*(
    lang: LangSpec,
    writeDebug: bool,
    writer: ResManWriteToFile,
    resolver: ResManLoadScriptSourceFile,
    tlk: TlkResolve = resolveTlk
): CScriptCompiler =
  scriptCompApiNewCompiler(
    lang.lang.cstring, lang.src.cint, lang.bin.cint, lang.dbg.cint,
    writer,
    resolver,
    tlk,
    writeDebug
  )

type CompileResult* = tuple
  code: int32
  str: string

proc scriptCompApiCompileFile(instance: CScriptCompiler, fn: cstring): tuple[code: int32, str: cstring] {.importc.}

proc compileFile*(instance: CScriptCompiler, fn: string): CompileResult =
  let q = scriptCompApiCompileFile(instance, fn.cstring)
  result.code = q.code * -1
  result.str  = strip $(q.str)
