/***** ANTLRv4  grammar for OpenQASM3.0. *****/

grammar qasm3;

/**** Parser grammar ****/

program
    : header (globalStatement | statement)*
    ;

header
    : version? include*
    ;

version
    : 'OPENQASM' ( Integer | RealNumber ) SEMICOLON
    ;

include
    : 'include' StringLiteral SEMICOLON
    ;

globalStatement
    : subroutineDefinition
    | kernelDeclaration
    | quantumGateDefinition
    | calibration
    | quantumDeclarationStatement  // qubits are declared globally
    | pragma
    ;

statement
    : expressionStatement
    | assignmentStatement
    | classicalDeclarationStatement
    | branchingStatement
    | loopStatement
    | endStatement
    | aliasStatement
    | quantumStatement
    ;

quantumDeclarationStatement : quantumDeclaration SEMICOLON ;

classicalDeclarationStatement
    : ( classicalDeclaration | constantDeclaration ) SEMICOLON
    ;

classicalAssignment
    : Identifier designator? ( assignmentOperator expression )?
    ;

assignmentStatement : ( classicalAssignment | quantumMeasurementAssignment ) SEMICOLON ;

returnSignature
    : ARROW classicalType
    ;

/*** Types and Casting ***/

designator
    : LBRACKET expression RBRACKET
    ;

doubleDesignator
    : LBRACKET expression COMMA expression RBRACKET
    ;

identifierList
    : ( Identifier COMMA )* Identifier
    ;

/** Quantum Types **/
quantumDeclaration
    : 'qreg' Identifier designator? | 'qubit' designator? Identifier
    ;

quantumArgument
    : 'qreg' Identifier designator? | 'qubit' designator? Identifier
    ;

quantumArgumentList
    : ( quantumArgument COMMA )* quantumArgument
    ;

/** Classical Types **/
bitType
    : 'bit'
    | 'creg'
    ;

singleDesignatorType
    : 'int'
    | 'uint'
    | 'float'
    | 'angle'
    ;

doubleDesignatorType
    : 'fixed'
    ;

noDesignatorType
    : 'bool'
    | timingType
    ;

classicalType
    : singleDesignatorType designator
    | doubleDesignatorType doubleDesignator
    | noDesignatorType
    | bitType designator?
    ;

constantDeclaration
    : 'const' Identifier equalsExpression?
    ;

// if multiple variables declared at once, either none are assigned or all are assigned
// prevents ambiguity w/ qubit arguments in subroutine calls
singleDesignatorDeclaration
    : singleDesignatorType designator Identifier equalsExpression?
    ;

doubleDesignatorDeclaration
    : doubleDesignatorType doubleDesignator Identifier equalsExpression?
    ;

noDesignatorDeclaration
    : noDesignatorType Identifier equalsExpression?
    ;

bitDeclaration
    : ( 'creg' Identifier designator? | 'bit' designator? Identifier ) equalsExpression?
    ;

classicalDeclaration
    : singleDesignatorDeclaration
    | doubleDesignatorDeclaration
    | noDesignatorDeclaration
    | bitDeclaration
    ;

classicalTypeList
    : ( classicalType COMMA )* classicalType
    ;

classicalArgument
    :
    (
        singleDesignatorType designator |
        doubleDesignatorType doubleDesignator |
        noDesignatorType
    ) Identifier
    | 'creg' Identifier designator?
    | 'bit' designator? Identifier
    ;

classicalArgumentList
    : ( classicalArgument COMMA )* classicalArgument
    ;

/** Aliasing **/
aliasStatement
    : 'let' Identifier EQUALS indexIdentifier SEMICOLON
    ;

/** Register Concatenation and Slicing **/

indexIdentifier
    : Identifier rangeDefinition
    | Identifier ( LBRACKET expressionList RBRACKET )?
    | indexIdentifier '||' indexIdentifier
    ;

indexIdentifierList
    : ( indexIdentifier COMMA )* indexIdentifier
    ;

rangeDefinition
    : LBRACKET expression? COLON expression? ( COLON expression )? RBRACKET
    ;

/*** Gates and Built-in Quantum Instructions ***/

quantumGateDefinition
    : 'gate' quantumGateSignature quantumBlock
    ;

quantumGateSignature
    : quantumGateName ( LPAREN identifierList? RPAREN )? identifierList
    ;

quantumGateName
    : 'U'
    | 'CX'
    | Identifier
    ;

quantumBlock
    : LBRACE ( quantumStatement | quantumLoop )* RBRACE
    ;

// loops containing only quantum statements allowed in gates
quantumLoop
    : loopSignature quantumLoopBlock
    ;

quantumLoopBlock
    : quantumStatement
    | LBRACE quantumStatement* RBRACE
    ;

quantumStatement
    : quantumInstruction SEMICOLON
    | timingStatement
    ;

quantumInstruction
    : quantumGateCall
    | quantumPhase
    | quantumMeasurement
    | quantumReset
    | quantumBarrier
    ;

quantumPhase
    : 'gphase' LPAREN expression RPAREN
    ;

quantumReset
    : 'reset' indexIdentifierList
    ;

quantumMeasurement
    : 'measure' indexIdentifierList
    ;

quantumMeasurementAssignment
    : quantumMeasurement ( ARROW indexIdentifierList)?
    | indexIdentifierList EQUALS quantumMeasurement
    ;

quantumBarrier
    : 'barrier' indexIdentifierList?
    ;

quantumGateModifier
    : ( 'inv' | 'pow' LPAREN expression RPAREN | 'ctrl' ) '@'
    ;

quantumGateCall
    : quantumGateModifier* quantumGateName ( LPAREN expressionList? RPAREN )? indexIdentifierList
    ;

/*** Classical Instructions ***/

unaryOperator
    : '~' | '!'
    ;

relationalOperator
    : '>'
    | '<'
    | '>='
    | '<='
    | '=='
    | '!='
    ;

logicalOperator
    : '&&'
    | '||'
    ;

expressionStatement
    : expression SEMICOLON
    ;

expression
    // include terminator/unary as base cases to simplify parsing
    : expressionTerminator
    | unaryExpression
    // expression hierarchy
    | xOrExpression
    | expression '|' xOrExpression
    ;

/**  Expression hierarchy for non-terminators. Adapted from ANTLR4 C
  *  grammar: https://github.com/antlr/grammars-v4/blob/master/c/C.g4
  * Order (first to last evaluation):
    Terminator (including Parens),
    Unary Op,
    Multiplicative
    Additive
    Bit Shift
    Bit And
    Exlusive Or (xOr)
    Bit Or
**/
xOrExpression
    : bitAndExpression
    | xOrExpression '^' bitAndExpression
    ;

bitAndExpression
    : bitShiftExpression
    | bitAndExpression '&' bitShiftExpression
    ;

bitShiftExpression
    : additiveExpression
    | bitShiftExpression ( '<<' | '>>' ) additiveExpression
    ;

additiveExpression
    : multiplicativeExpression
    | additiveExpression ( PLUS | MINUS ) multiplicativeExpression
    ;

multiplicativeExpression
    // base case either terminator or unary
    : expressionTerminator
    | unaryExpression
    | multiplicativeExpression ( MUL | DIV | MOD ) ( expressionTerminator | unaryExpression )
    ;

unaryExpression
    : unaryOperator expressionTerminator
    ;

expressionTerminator
    : Constant
    | Integer
    | RealNumber
    | booleanLiteral
    | Identifier
    | StringLiteral
    | builtInCall
    | kernelCall
    | subroutineCall
    | timingTerminator
    | MINUS expressionTerminator
    | LPAREN expression RPAREN
    | expressionTerminator LBRACKET expression RBRACKET
    | expressionTerminator incrementor
    ;
/** End expression hierarchy **/

booleanLiteral
    : 'true' | 'false'
    ;

incrementor
    : '++'
    | '--'
    ;

builtInCall
    : ( builtInMath | castOperator ) LPAREN expressionList RPAREN
    ;

builtInMath
    : 'sin' | 'cos' | 'tan' | 'exp' | 'ln' | 'sqrt' | 'rotl' | 'rotr' | 'popcount' | 'lengthof'
    ;

castOperator
    : classicalType
    ;

expressionList
    : ( expression COMMA )* expression
    ;

/** Boolean expression hierarchy **/
booleanExpression
    : membershipTest
    | comparisonExpression
    | booleanExpression logicalOperator comparisonExpression
    ;

comparisonExpression
    : expression  // if (expression)
    | expression relationalOperator expression
    ;
/** End boolean expression hierarchy **/

equalsExpression
    : EQUALS expression
    ;

assignmentOperator
    : EQUALS
    | '+=' | '-=' | '*=' | '/=' | '&=' | '|=' | '~=' | '^=' | '<<=' | '>>='
    ;

membershipTest
    : Identifier 'in' setDeclaration
    ;

setDeclaration
    : LBRACE expressionList RBRACE
    | rangeDefinition
    | Identifier
    ;

programBlock
    : statement | controlDirective
    | LBRACE ( statement | controlDirective )* RBRACE
    ;

branchingStatement
    : 'if' LPAREN booleanExpression RPAREN programBlock ( 'else' programBlock )?
    ;

loopSignature
    : 'for' membershipTest
    | 'while' LPAREN booleanExpression RPAREN
    ;

loopStatement: loopSignature programBlock ;

endStatement
    : 'end' SEMICOLON
    ;

returnStatement
    : 'return' ( expression | quantumMeasurement )? SEMICOLON;

controlDirective
    : ('break' | 'continue') SEMICOLON
    | endStatement
    | returnStatement
    ;

kernelDeclaration
    : 'kernel' Identifier ( LPAREN classicalTypeList? RPAREN )? returnSignature? SEMICOLON
    ;

// if have kernel w/ out args, is ambiguous; may get matched as identifier
kernelCall
    : Identifier LPAREN expressionList? RPAREN
    ;

/*** Subroutines ***/

subroutineDefinition
    : 'def' Identifier ( LPAREN classicalArgumentList? RPAREN )? quantumArgumentList?
    returnSignature? subroutineBlock
    ;

subroutineBlock
    : LBRACE statement* returnStatement? RBRACE
    ;

// if have subroutine w/ out args, is ambiguous; may get matched as identifier
subroutineCall
    : Identifier ( LPAREN expressionList? RPAREN )? indexIdentifierList
    ;

/*** Directives ***/

pragma
    : '#pragma' LBRACE statement* RBRACE  // match any valid openqasm statement
    ;

/*** Circuit Timing ***/

timingType
    : 'length'
    | StretchN
    ;

timingBox
    : 'boxas' Identifier quantumBlock
    | 'boxto' TimingLiteral quantumBlock
    ;

timingTerminator
    : timingIdentifier | 'stretchinf'
    ;

timingIdentifier
    : TimingLiteral
    | 'lengthof' LPAREN ( Identifier | quantumBlock ) RPAREN
    ;

timingInstructionName
    : 'delay'
    | 'rotary'
    ;

timingInstruction
    : timingInstructionName ( LPAREN expressionList? RPAREN )? designator indexIdentifierList
    ;

timingStatement
    : timingInstruction SEMICOLON
    | timingBox
    ;

/*** Pulse Level Descriptions of Gates and Measurement ***/
// TODO: Update when pulse grammar is formalized

calibration
    : calibrationGrammarDeclaration
    | calibrationDefinition
    ;

calibrationGrammarDeclaration
    : 'defcalgrammar' calibrationGrammar SEMICOLON
    ;

calibrationDefinition
    : 'defcal' Identifier
    ( LPAREN calibrationArgumentList? RPAREN )? identifierList
    returnSignature? LBRACE .*? RBRACE  // for now, match anything inside body
    ;

calibrationGrammar
    : '"openpulse"' | StringLiteral  // currently: pulse grammar string can be anything
    ;

calibrationArgumentList
    : classicalArgumentList | expressionList
    ;

/**** Lexer grammar ****/

LBRACKET : '[' ;
RBRACKET : ']' ;

LBRACE : '{' ;
RBRACE : '}' ;

LPAREN : '(' ;
RPAREN : ')' ;

COLON: ':' ;
SEMICOLON : ';' ;

DOT : '.' ;
COMMA : ',' ;

EQUALS : '=' ;
ARROW : '->' ;

PLUS : '+';
MINUS : '-' ;
MUL : '*';
DIV : '/';
MOD : '%';


Constant : ( 'pi' | 'π' | 'tau' | '𝜏' | 'euler' | 'ℇ' );

Whitespace : [ \t]+ -> skip ;
Newline : [\r\n]+ -> skip ;

fragment Digit : [0-9] ;
Integer : Digit+ ;

fragment ValidUnicode : [\p{Lu}\p{Ll}\p{Lt}\p{Lm}\p{Lo}\p{Nl}] ; // valid unicode chars
fragment Letter : [A-Za-z] ;
fragment FirstIdCharacter : '_' | '$' | ValidUnicode | Letter ;
fragment GeneralIdCharacter : FirstIdCharacter | Integer;

StretchN : 'stretch' Digit* ;
Identifier : FirstIdCharacter GeneralIdCharacter* ;

fragment SciNotation : [eE] ;
fragment PlusMinus : PLUS | MINUS ;
fragment Float : Digit+ DOT Digit* ;
RealNumber : Float (SciNotation PlusMinus? Integer )? ;

fragment TimeUnit : 'dt' | 'ns' | 'us' | 'µs' | 'ms' | 's' ;
// represents explicit time value in SI or backend units
TimingLiteral : (Integer | RealNumber ) TimeUnit ;

// allow ``"str"`` and ``'str'``
StringLiteral
    : '"' ~["\r\t\n]+? '"'
    | '\'' ~['\r\t\n]+? '\''
    ;

// skip comments
LineComment : '//' ~[\r\n]* -> skip;
BlockComment : '/*' .*? '*/' -> skip;
