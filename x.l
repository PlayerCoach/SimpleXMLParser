%{
#include "defs.h"
#include "x.tab.h"
#include "string.h"
#include "stdio.h"
#include "stdlib.h"


int start_line;

%}

    /* DECLARATION SECTION */

IDENT [a-zA-Z_:][a-zA-Z0-9_:-]* 

 /*States of the lexer analyzer ( INITIAL is the default state) */

%option yylineno
%x ST_COMMENT
%x ST_PI 
%x ST_TAG 


%%

    /*  COMMENTS HANDLING */

<INITIAL>"<!--" {
    BEGIN(ST_COMMENT); start_line = yylineno;
}
    /* Detect valid closing tag and change back to default state */
<ST_COMMENT>"-->" {
    BEGIN(INITIAL);
}

 /* Ignore everything else in the comment state */
<ST_COMMENT>[^-]+ ;
<ST_COMMENT>"-"[^-]* ;
<ST_COMMENT>\n ;
    /*  PROCESSING INSTRUCTION HANDLING */

<INITIAL>"<?"{IDENT} {
    BEGIN(ST_PI); 
    int l = strlen(yytext)-2;
    strncpy(yylval.s, yytext + 2, MAXSTRLEN);
    return PI_TAG_BEG;
}

<ST_PI>"?>" {
    BEGIN(INITIAL);
    return PI_TAG_END;
}

<INITIAL>"?>" {
    fprintf(stderr, "Error: Processing instruction closed on line %d when not opened\n", yylineno);
    return PI_TAG_END;
}

<ST_PI>.|\n {
    strncpy(yylval.s, yytext, MAXSTRLEN);
    return CHAR; }

    /*  TAG HANDLING */

<INITIAL>"<"{IDENT} {
    BEGIN(ST_TAG);
    int l = strlen(yytext)-1;
    strncpy(yylval.s, yytext + 1, MAXSTRLEN);
    return STAG_BEG;
    start_line = yylineno;
}

<INITIAL>"</"{IDENT} {
    BEGIN(ST_TAG);
    int l = strlen(yytext)-2;
    strncpy(yylval.s, yytext + 2, MAXSTRLEN);
    return ETAG_BEG;
}

<ST_TAG>"/>" {
    BEGIN(INITIAL);
    return ETAG_END;
}

<ST_TAG>">" {
    BEGIN(INITIAL);
    return TAG_END;
}

<ST_TAG>.|\n;

 /* handling of closing tag without opening tag */

<INITIAL>">" {
    fprintf(stderr, "Error: Tag closed on line %d when not opened\n", yylineno);
    return TAG_END;
}

<INITIAL>"/>" {
    fprintf(stderr, "Error: Tag closed on line %d when not opened\n", yylineno);
    return ETAG_END;
}

<ST_TAG>.|\n ;

 /* STRINGS HANDLING */

"&lt;" { strncpy(yylval.s, "<", MAXSTRLEN); return CHAR; }
"&gt;" { strncpy(yylval.s, ">", MAXSTRLEN); return CHAR; }
"&amp;" { strncpy(yylval.s, "&", MAXSTRLEN); return CHAR; }
"&quot;" { strncpy(yylval.s, "\"", MAXSTRLEN); return CHAR; }
"&apos;" { strncpy(yylval.s, "'", MAXSTRLEN); return CHAR; }

    /* IGNORE WHITESPACES AT THE BEGINNING OF THE LINE */

^[ \t]+ ;

    /*  RETURN NEW LINE FEED AS ITSELF */

\n { return '\n'; }

    /* IGNORE THE CARRIAGE RETURN */

\r ;

    /* RETURN WHITE SPACES AS S TOKEN */

[ \t] { strncpy (yylval.s, yytext, MAXSTRLEN); return S; }

    /* DEFAULT */

. { strncpy(yylval.s, yytext, MAXSTRLEN); return CHAR; }


%% 

int yywrap(void){
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





