/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

/* indicates which line in the source text is currently being scanned */
extern int curr_lineno;
extern int verbose_flag;
extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */
/*
 * Function to convert from bool literal to ineger
 */
int bool_to_int(const char *b);
int str_len;
int comment_depth;


#define VALID_STRING_LEN(str_len) {\
  if (str_len >= MAX_STR_CONST) { \
    BEGIN(ILLEGAL_STRING); \
    SET_LINE(); \
    cool_yylval.error_msg = "String constant too long"; \
    return (ERROR); \
  }\
}

#define PUSH_ESCAPE_CHAR(escape)\
      str_len += 1; \
      VALID_STRING_LEN(str_len) \
      *string_buf_ptr++ = escape;

#define SET_LINE() \
      curr_lineno = yylineno;

%}


%option   yylineno
%x S_STRING UNTERMINATED_STRING ILLEGAL_STRING COMMENT

/*
 * Define names for regular expressions here.
 */

/*
 * Keywords.
 * Keywords are case insensitive.
 */

IF  (?i:if)
CLASS (?i:class)
ELSE (?i:else)
FI  (?i:fi)
IN (?i:in)
INHERITS (?i:inherits)
ISVOID (?i:isvoid)
LET (?i:let)
LOOP (?i:loop)
POOL (?i:pool)
THEN (?i:then)
WHILE (?i:while)
CASE (?i:case)
ESAC (?i:esac)
NEW (?i:new)
OF (?i:of)
NOT (?i:not)

/*
 * Built-in types
 */ 
BOOLEAN         t(?i:rue)|f(?i:alse)
/*
 * Integers are non-empty strings of digits 0-9
 */
DIGIT           [0-9]
INTEGER         {DIGIT}+
/*
 * true and false must be lowercase; the trailing letters may be upper or lower case.
 */
STRING_SYMB             [^\"\\\n\0]*
STRING_START            \"{STRING_SYMB}
STRING_WITHOUT_ESCAPE   \"{STRING_SYMB}\"
NULL_STRING             \"\0\"

/*
 * Identifiers
 * Identifiers are strings (other than keywords) consisting of letters, 
 * digits, and the underscore character.
 * Type identifiers begin with a capital letter; 
 * object identifiers begin with a lower case letter.
 */
IDCHARS              [A-z0-9_]
TYPEID               [A-Z]{IDCHARS}*
OBJECTID             [a-z]{IDCHARS}*




/*
 * Operators
 */
EQUAL           "="
PLUS            "+"
STAR            "*"
MINUS           "-"
DIVISION        "/"
DARROW          "=>"
LT              "<"
LE              "<="
NEGATION        "~"
AT              "@"
DOT             "."
COMMA           ","
SEMICOLON       ";"
COLON           ":"
ASSIGN          "<-"


 /*
  * Special characters
  */
OPENPAREN     "("
CLOSEDPAREN   ")"
OPENBRACKET   "{"
CLOSEDBRACKET "}"
OPENCOMMENT   "(*"
CLOSEDCOMMENT  "*)"
NOT_ALLOWED   [!#$%^&_\>\?`\[\]\\\|\x00-\x07]
%option yylineno
%%
\n            { SET_LINE(); }
 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */

{IF}          { return (IF);}
{CLASS}       { return (CLASS);}
{ELSE}        { return (ELSE);}
{FI}          { return (FI);}
{IN}          { return (IN);}
{INHERITS}    { return (INHERITS);}
{ISVOID}      { return (ISVOID);}
{LET}         { return (LET);}
{LOOP}        { return (LOOP);}
{POOL}        { return (POOL);}
{THEN}        { return (THEN);}
{WHILE}       { return (WHILE);}
{CASE}        { return (CASE);}
{ESAC}        { return (ESAC);}
{NEW}         { return (NEW);}
{OF}          { return (OF);}
{NOT}         { return (NOT);}
{BOOLEAN} {
    cool_yylval.boolean = bool_to_int(yytext);
    return (BOOL_CONST);
}
 /*
  * Identifiers
  */

{TYPEID} {
    cool_yylval.symbol = idtable.add_string(yytext);
    return (TYPEID);
}

{OBJECTID} {
    cool_yylval.symbol = idtable.add_string(yytext);
    return (OBJECTID);
}

 /*
  *  Nested comments
  */

{OPENCOMMENT} {
    comment_depth = 1;
    BEGIN(COMMENT);
}

<COMMENT>{
  {OPENCOMMENT} {
    comment_depth++;
  }

  {CLOSEDCOMMENT} {
    comment_depth--;
    if (comment_depth == 0){
      BEGIN(INITIAL);
    }
  }
  
  /*
   * For now have no better idea how
   * to handle strings of * or columns
   */ 
  [\*\)\(] {}
  [^\(\)\*]?\n?[^\(\)\*]? {}
  <<EOF>>  { 
      BEGIN(INITIAL);
      cool_yylval.error_msg = "EOF in comment";
      return (ERROR);
    }

}

{CLOSEDCOMMENT}   {
    cool_yylval.error_msg = "Unmatched *)";
    return (ERROR); 
}
{PLUS}            { return ('+'); }
{STAR}            { return ('*'); }
{MINUS}           { return ('-'); }
{DIVISION}        { return ('/'); }
{LT}              { return ('<'); }
{NEGATION}        { return ('~'); }
{AT}              { return ('@'); }
{DOT}             { return ('.'); }
{COLON}           { return (':'); }
{SEMICOLON}       { return (';'); }
{OPENPAREN}       { return ('('); }
{CLOSEDPAREN}     { return (')'); }
{OPENBRACKET}     { return ('{'); }
{CLOSEDBRACKET}   { return ('}'); }
{EQUAL}           { return ('='); }
{COMMA}           { return (','); }


 /*
  *  The multiple-character operators.
  */
{DARROW}	{ return (DARROW); }
{LE}        { return (LE); }
{ASSIGN}    { return (ASSIGN); }

 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */



{NULL_STRING} {
    cool_yylval.symbol = stringtable.add_string("0");
    return (STR_CONST);
}

{STRING_WITHOUT_ESCAPE} {
    SET_LINE();
    /* do not count opening and closing quores */
    str_len = yyleng - 2; 
    VALID_STRING_LEN(str_len);  
    cool_yylval.symbol = stringtable.add_string(yytext + 1, str_len);
    return (STR_CONST);
}

{STRING_START} {
    string_buf_ptr = string_buf;
    char *yptr = yytext;
    /* ignore openning quote */
    str_len = yyleng - 1;
    VALID_STRING_LEN(str_len);  
    /* increment pointer to second character */
    *yptr++;
    while (*yptr){
        *string_buf_ptr++ = *yptr++;
    }
    BEGIN(S_STRING);
}



<S_STRING>{
  
  \0 {
      BEGIN(ILLEGAL_STRING);
      cool_yylval.error_msg = "String contains null character";
      return (ERROR);
  }

  \\\0 {
      BEGIN(ILLEGAL_STRING);
      cool_yylval.error_msg = "String contains escaped null character";
      return (ERROR);
  }


  {STRING_SYMB}+ {
      char *yptr = yytext;
      str_len += yyleng;
      VALID_STRING_LEN(str_len);
      while (*yptr){
          *string_buf_ptr++ = *yptr++;
      }
  }

 \\|\n {
    str_len = 0;
    BEGIN(INITIAL);
    SET_LINE();
    cool_yylval.error_msg = "Unterminated string constant";
    return (ERROR);
  }

  \\n  { PUSH_ESCAPE_CHAR('\n') }
  \\b  { PUSH_ESCAPE_CHAR('\b') }
  \\f  { PUSH_ESCAPE_CHAR('\f') }
  \\t  { PUSH_ESCAPE_CHAR('\t') }

   \\[^ntbf] {
      str_len += 1;
      char *yptr = yytext;
      VALID_STRING_LEN(str_len);  
      *yptr++;
      while (*yptr){
          *string_buf_ptr++ = *yptr++;
      }   
    }

   \" { 
     BEGIN(INITIAL);
     cool_yylval.symbol = stringtable.add_string(string_buf_ptr - str_len, str_len); 
     return (STR_CONST); 
    }

  <<EOF>>  { 
      SET_LINE();
      BEGIN(ILLEGAL_STRING);
      cool_yylval.error_msg = "EOF in string constant";
      return (ERROR);
    }

}


<ILLEGAL_STRING>{
  /* 
   * Must match until string termination or unescaped newline since 
   * we assume the programmer simply forgot the close-quote
   * when newline encountered therefore treating it as string termination 
   */
   
  .*(\"|\n) {BEGIN(INITIAL);}
}

{INTEGER} {
    SET_LINE();
    cool_yylval.symbol = inttable.add_string(yytext);
    return (INT_CONST);
}


{NOT_ALLOWED} {
  SET_LINE();
  cool_yylval.error_msg = yytext;
  return (ERROR);
}

--.* {}
[[:space:]]+ {}
%%


int bool_to_int(const char *b)
{
  if (b[0] == 'f') {
    return 0;
  }
  return 1;
}