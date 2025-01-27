%{
    #include "defs.h"
    #include "x.tab.h"

    int start_line;


%}

 /* DECLARATION SECTION */

INDETIFIER [a-zA-Z_:][a-zA-Z0-9_:-]* 

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

 /* Removal of the comments */
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



%% 

int yywrap(void)
{
    if(YY_START == ST_COMMENT)
    {
        fprintf(stderr, "Error: Comment opened on line %d when not closed\n", start_line);
    }
    return 1;
}




