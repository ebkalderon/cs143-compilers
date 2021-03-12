/*
 * The scanner definition for COOL.
 *
 * Comments in this file are unfortunately sparse due to JLex not supporting
 * inline comments between rules/macros, so I will have to document notes here.
 *
 * This file is broken up into three (3) sections:
 *
 *   User code, copied verbatim into file
 *   %%
 *   JLex directives: lexer class init, EOF handling, macros (<name> = <regex>), lexer states
 *   %%
 *   JLex rules ([<state>] <regex> { <code> })
 *
 * JLex doesn't support case-insensitive rules, so case-insensitive per-letter
 * macros are used to achieve the same effect.
 */

import java_cup.runtime.Symbol;

%%

%{
    /*  Stuff enclosed in %{ %} is copied verbatim to the lexer class
     *  definition, all the extra variables/functions you want to use in the
     *  lexer actions should go here.  Don't remove or modify anything that
     *  was there initially.  */

    // Max size of string constants
    static int MAX_STR_CONST = 1025;

    // For assembling string constants
    StringBuffer string_buf = new StringBuffer();

    // Used to avoid emitting repeated ERROR tokens if EOF was already seen once
    private boolean eof_error_emitted = false;

    // Depth of nested block comments
    private int nested_comment_level = 0;

    private int curr_lineno = 1;
    int get_curr_lineno() {
        return curr_lineno;
    }

    private AbstractSymbol filename;

    void set_filename(String fname) {
        filename = AbstractTable.stringtable.addString(fname);
    }

    AbstractSymbol curr_filename() {
        return filename;
    }
%}

%init{
    /*  Stuff enclosed in %init{ %init} is copied verbatim to the lexer
     *  class constructor, all the extra initialization you want to do should
     *  go here.  Don't remove or modify anything that was there initially. */

    // empty for now
%init}

%eofval{
    /*  Stuff enclosed in %eofval{ %eofval} specifies java code that is
     *  executed when end-of-file is reached.  If you use multiple lexical
     *  states and want to do something special if an EOF is encountered in
     *  one of those states, place your code in the switch statement.
     *  Ultimately, you should return the EOF symbol, or your lexer won't
     *  work.  */

    if (eof_error_emitted)
        return new Symbol(TokenConstants.EOF);

    switch(yy_lexical_state) {
    case YYINITIAL:
        /* nothing special to do in the initial state */
        break;
    case STRING:
        eof_error_emitted = true;
        if (string_buf.indexOf("\0") != -1) {
            return new Symbol(TokenConstants.ERROR, "String contains null character");
        } else {
            return new Symbol(TokenConstants.ERROR, "EOF in string constant");
        }
    case BLOCK_COMMENT:
        eof_error_emitted = true;
        return new Symbol(TokenConstants.ERROR, "EOF in block comment");
    }

    return new Symbol(TokenConstants.EOF);
%eofval}

%class CoolLexer
%cup

LineTerminator = \n|\r|\r\n
Whitespace = {LineTerminator}|[ \t\f\013]

A = [Aa]
C = [Cc]
D = [Dd]
E = [Ee]
F = [Ff]
H = [Hh]
I = [Ii]
L = [Ll]
N = [Nn]
O = [Oo]
P = [Pp]
R = [Rr]
S = [Ss]
T = [Tt]
U = [Uu]
V = [Vv]
W = [Ww]

True       = t{R}{U}{E}
False      = f{A}{L}{S}{E}
Integer    = [0-9]+
ObjectId   = [a-z][A-Za-z0-9_]*
TypeId     = [A-Z][A-Za-z0-9_]*

%state STRING
%state BLOCK_COMMENT

%%

<YYINITIAL> \n            { curr_lineno++; }
<YYINITIAL> {Whitespace}  { /* Ignore whitespace tokens */ }

<YYINITIAL> "(*"          { yybegin(BLOCK_COMMENT); }
<YYINITIAL> "*)"          { return new Symbol(TokenConstants.ERROR, "Mismatched '*)'"); }

<BLOCK_COMMENT> [^\n*\(\)]+ { /* Ignore block comment tokens */ }
<BLOCK_COMMENT> [\(\)*]     { /* Skip extra parentheses/asterisks in comments */ }
<BLOCK_COMMENT> \n          { curr_lineno++; }
<BLOCK_COMMENT> "(*"        { nested_comment_level++; }
<BLOCK_COMMENT> "*)"        {
                                if (nested_comment_level != 0) {
                                    nested_comment_level--;
                                } else {
                                    yybegin(YYINITIAL);
                                }
                            }

<YYINITIAL> {C}{A}{S}{E}             { return new Symbol(TokenConstants.CASE); }
<YYINITIAL> {C}{L}{A}{S}{S}          { return new Symbol(TokenConstants.CLASS); }
<YYINITIAL> {E}{L}{S}{E}             { return new Symbol(TokenConstants.ELSE); }
<YYINITIAL> {E}{S}{A}{C}             { return new Symbol(TokenConstants.ESAC); }
<YYINITIAL> {F}{I}                   { return new Symbol(TokenConstants.FI); }
<YYINITIAL> {I}{F}                   { return new Symbol(TokenConstants.IF); }
<YYINITIAL> {I}{N}                   { return new Symbol(TokenConstants.IN); }
<YYINITIAL> {I}{N}{H}{E}{R}{I}{T}{S} { return new Symbol(TokenConstants.INHERITS); }
<YYINITIAL> {I}{S}{V}{O}{I}{D}       { return new Symbol(TokenConstants.ISVOID); }
<YYINITIAL> {L}{E}{T}                { return new Symbol(TokenConstants.LET); }
<YYINITIAL> {L}{O}{O}{P}             { return new Symbol(TokenConstants.LOOP); }
<YYINITIAL> {N}{E}{W}                { return new Symbol(TokenConstants.NEW); }
<YYINITIAL> {N}{O}{T}                { return new Symbol(TokenConstants.NOT); }
<YYINITIAL> {O}{F}                   { return new Symbol(TokenConstants.OF); }
<YYINITIAL> {P}{O}{O}{L}             { return new Symbol(TokenConstants.POOL); }
<YYINITIAL> {T}{H}{E}{N}             { return new Symbol(TokenConstants.THEN); }
<YYINITIAL> {W}{H}{I}{L}{E}          { return new Symbol(TokenConstants.WHILE); }

<YYINITIAL> "=>"       { return new Symbol(TokenConstants.DARROW); }
<YYINITIAL> "<="       { return new Symbol(TokenConstants.LE); }
<YYINITIAL> "<-"       { return new Symbol(TokenConstants.ASSIGN); }
<YYINITIAL> "+"        { return new Symbol(TokenConstants.PLUS); }
<YYINITIAL> "/"        { return new Symbol(TokenConstants.DIV); }
<YYINITIAL> "-"        { return new Symbol(TokenConstants.MINUS); }
<YYINITIAL> "*"        { return new Symbol(TokenConstants.MULT); }
<YYINITIAL> "="        { return new Symbol(TokenConstants.EQ); }
<YYINITIAL> "<"        { return new Symbol(TokenConstants.LT); }
<YYINITIAL> "."        { return new Symbol(TokenConstants.DOT); }
<YYINITIAL> "~"        { return new Symbol(TokenConstants.NEG); }
<YYINITIAL> ","        { return new Symbol(TokenConstants.COMMA); }
<YYINITIAL> ";"        { return new Symbol(TokenConstants.SEMI); }
<YYINITIAL> ":"        { return new Symbol(TokenConstants.COLON); }
<YYINITIAL> "("        { return new Symbol(TokenConstants.LPAREN); }
<YYINITIAL> ")"        { return new Symbol(TokenConstants.RPAREN); }
<YYINITIAL> "@"        { return new Symbol(TokenConstants.AT); }
<YYINITIAL> "{"        { return new Symbol(TokenConstants.LBRACE); }
<YYINITIAL> "}"        { return new Symbol(TokenConstants.RBRACE); }
<YYINITIAL> "--".*     { /* Ignore end-of-line comments */ }

<YYINITIAL> {True}     { return new Symbol(TokenConstants.BOOL_CONST, new Boolean(true)); }
<YYINITIAL> {False}    { return new Symbol(TokenConstants.BOOL_CONST, new Boolean(false)); }
<YYINITIAL> {Integer}  { return new Symbol(TokenConstants.INT_CONST, AbstractTable.inttable.addString(yytext())); }
<YYINITIAL> {ObjectId} { return new Symbol(TokenConstants.OBJECTID, AbstractTable.idtable.addString(yytext())); }
<YYINITIAL> {TypeId}   { return new Symbol(TokenConstants.TYPEID, AbstractTable.idtable.addString(yytext())); }

<YYINITIAL> \"      {
                        yybegin(STRING);
                        string_buf.delete(0, string_buf.length());
                    }

<STRING> \"         {
                        yybegin(YYINITIAL);

                        if (string_buf.length() >= MAX_STR_CONST) {
                            return new Symbol(TokenConstants.ERROR, "String constant too long");
                        }

                        final String value = string_buf.toString();
                        if (value.contains("\0")) {
                            eof_error_emitted = true;
                            return new Symbol(TokenConstants.ERROR, "String contains null character");
                        } else {
                            return new Symbol(TokenConstants.STR_CONST, AbstractTable.stringtable.addString(value));
                        }
                    }

<STRING> [^\n\"\\]+ { string_buf.append(yytext()); }

<STRING> \\?\n      {
                        curr_lineno++;
                        if (yytext().startsWith("\\")) {
                            string_buf.append('\n');
                        } else {
                            yybegin(YYINITIAL);
                            return new Symbol(TokenConstants.ERROR, "Unterminated string constant");
                        }
                    }

<STRING> (\\.)+     {
                        final String text = yytext();
                        for (int i = 1; i < text.length(); i += 2) {
                            switch (text.charAt(i)) {
                            case 'b':
                                string_buf.append('\b');
                                break;
                            case 'n':
                                string_buf.append('\n');
                                break;
                            case 'f':
                                string_buf.append('\f');
                                break;
                            case 't':
                                string_buf.append('\t');
                                break;
                            default:
                                string_buf.append(text.charAt(i));
                                break;
                            }
                        }
                    }

<YYINITIAL> [^\n]   { return new Symbol(TokenConstants.ERROR, yytext()); }

.                   { /* This rule should be the very last
                         in your lexical specification and
                         will match match everything not
                         matched by other lexical rules. */
                      System.err.println("LEXER BUG - UNMATCHED: " + yytext()); }
