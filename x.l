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
    return process_token(yytext, "PI_TAG_BEG", yytext + 2, PI_TAG_BEG);
}

<ST_PI>"?>" {
    BEGIN(INITIAL);
    return process_token(yytext, "PI_TAG_END", "", PI_TAG_END);
}

<INITIAL>"?>" {
    fprintf(stderr, "Error: Processing instruction closed on line %d when not opened\n", yylineno);
    return process_token(yytext, "PI_TAG_END", "", PI_TAG_END);
}

<ST_PI> . | \n

    /*  TAG HANDLING */

<INITIAL>"<"{IDENT} {
    BEGIN(ST_TAG);
    return process_token(yytext, "STAG_BEG", yytext + 1, STAG_BEG);
    start_line = yylineno;
}

<INITIAL>"</"{IDENT} {
    BEGIN(ST_TAG);
    return process_token(yytext, "ETAG_BEG", yytext+2, ETAG_END);
}

<ST_TAG>"/>"
{
    BEGIN(INITIAL);
    process_token(yytext, "ETAG_END", "", ETAG_END);
}

<ST_TAG>">" {
    BEGIN(INITIAL);
    return process_token(yytext, "TAG_END", "", TAG_END);
}

<ST_TAG> . | \n

 /* handling of closing tag without opening tag */

<INITIAL>">" {
    fprintf(stderr, "Error: Tag closed on line %d when not opened\n", yylineno);
    return process_token(yytext, "TAG_END", "", TAG_END);
}

<INITIAL>"/>" {
    fprintf(stderr, "Error: Tag closed on line %d when not opened\n", yylineno);
    return process_token(yytext, "ETAG_END", "", ETAG_END);
}

  <ST_TAG> . | \n

 /* STRINGS HANDLING */

"&lt;" { return process_token(yytext, "CHAR", "<", CHAR); }
"&gt;" { return process_token(yytext, "CHAR", ">", CHAR); }
"&amp;" { return process_token(yytext, "CHAR", "&", CHAR); }
"&quot;" { return process_token(yytext, "CHAR", "\"", CHAR); }
"&apos;" { return process_token(yytext, "CHAR", "'", CHAR); }

/* IGNORE WHITESPACES AT THE BEGINNING OF THE LINE */

^[ \t]+

/*  RETURN NEW LINE FEED AS ITSELF */

\n return "\n";

/* IGNORE THE CARRIAGE RETURN */

\r

/* RETURN WHITE SPACES AS S TOKEN */

[ \t] { return process_token(yytext, "S", yytext, S); }

/* DEFAULT */

. { return process_token(yytext, "CHAR", yytext, CHAR); }


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
    else  if(YY_START == ST_TAG)
    {
        fprintf(stderr, "Error: Tag opened on line %d when not closed\n", start_line);
    }
    
    return 1;
}


int process_token(const char *text, const char *TokenType,
                  const char *TokenVal, const int TokenID)
{
    int l;
    printf("%-20.20s%-15s %s\n", text, TokenType, TokenVal);

    l = strlen(TokenVal);
    strncpy(yylval.s, TokenVal, l <= MAXSTRLEN ? l : MAXSTRLEN);
    
    return(TokenID);
}




