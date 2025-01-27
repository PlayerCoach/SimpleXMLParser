%{
    #include "defs.h"
    #include "x.tab.h"
    #include "string.h"
    #include "stdio.h"

    int process_token(const char* text, const char* TokenType, 
                      const char* tokenVal, const int TokenID)

    int start_line;


%}

 /* DECLARATION SECTION */

IDENT [a-zA-Z_:][a-zA-Z0-9_:-]* 

/*States of the lexer analyzer ( INITIAL is the default state) */

/* coomment contents*/
%x ST_COMMNET
/* processing instruction contents */
%x ST_PI 
/* tag contents */
%x ST_TAG 

/* include line number tracking */
%option yylineno

%%

 /*  COMMENTS HANDLING */

<INITIAL>"<!--" {
    BEGIN(ST_COMMNET); start_line = yylineno;
}
<INITIAL>"-->" {
    fprintf(stderr, "Error: Comment closed on line %d when not opened\n", start_line);
}
    /* Detect valid closing tag and change back to default state */
<ST_COMMENT>"-->" {
    BEGIN(INITIAL);
}

    /* Detect invalid closing tag */
<ST_COMMENT> --+> {
    fprintf(stderr, "Error: Invalid closing tag of comment  in line\n", yylineno);
}
 /* Ignore the content of the comment */
<ST_COMMENT> . | \n


    /*  PROCESSING INSTRUCTION HANDLING */

<INITIAL>"<?"{IDENT} {
    BEGIN(ST_PI); 
    process_token(yytext, "PI_TAG_BEG", yytext + 2, PI_TAG_BEG);
}

<ST_PI>"?>" {
    BEGIN(INITIAL);
    process_token(yytext, "PI_TAG_END", "", PI_TAG_END);
}

<INITIAL>"?>" {
    fprintf(stderr, "Error: Processing instruction closed on line %d when not opened\n", yylineno);
    process_token(yytext, "PI_TAG_END", "", PI_TAG_END);
}

<ST_PI> . | \n

    /*  TAG HANDLING */




%% 

int yywrap(void)
{
    if(YY_START == ST_COMMENT)
    {
        fprintf(stderr, "Error: Comment opened on line %d when not closed\n", start_line);
    }
    else if(YY_START == ST_PI)
    {
        fprintf(stderr, "Error: Processing instruction opened on line %d when not closed\n", start_line);
    }
    
    return 1;
}

char* stringcpy(char* dest, const char* src, int len)
{
    strncpy(dest, src, len);
    dest[len] = '\0';
    return dest;
}

int process_token(const char *text, const char *TokenType,
                  const char *TokenVal, const int TokenID)
{
    int l;
    printf("%-20.20s%-15s %s\n", text, TokenType, TokenVal);
    switch (TokenID) 
    {
    case IDENT:
    l = strlen(TokenVal);
    strncpy(yylval.s, TokenVal, l <= MAXSTRLEN ? l : MAXSTRLEN);
    }
    
    return(TokenID);
}




