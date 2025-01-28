%{
    #include "stdio.h"
    #include "string.h"
    #include "defs.h"

    #define INDENT_LENGTH 5
    #define LINE_WIDTH 78

    int level = 0;

    void indent(int level);
    int yylex(void);
    void yyerror(const char *s);
    
%}
%debug


%union {
    char s[MAXSTRLEN +1];
}

%start GRAMMAR

%token<s> PI_TAG_BEG PI_TAG_END STAG_BEG ETAG_BEG
%token<s> TAG_END ETAG_END CHAR S 

%type<s> start_tag end_tag word processing_instruction content

%%

GRAMMAR : {yyerror( "Empty input source is not valid!"); }
    %empty
    | error 
    | document
;

document :
    optional_white_space introduction element optional_white_space
    ;

introduction :
    %empty
    | processing_sequence '\n'
    ;

processing_sequence:
    %empty
    | processing_instruction processing_sequence
    ;


processing_instruction :
    PI_TAG_BEG content PI_TAG_END
    {
        indent(level);
        printf("<?%s %s ?>\n", $1, $2);
    }
    ;

element :
    empty_tag
    | pair_of_elements
    ;

empty_tag :
    STAG_BEG ETAG_END
    {
        indent(level);
        printf("<%s/>\n", $1);
    }
    ;

pair_of_elements :
    start_tag content end_tag
    {
        if(strncmp($1, $3, MAXSTRLEN) != 0) {
            fprintf(stderr, "Error: Opening tag %s does not match closing tag %s\n", $1, $3);
        }
    }
    ;

start_tag :
    STAG_BEG TAG_END
    {
        indent(level);
        printf("<%s>\n", $1);
        level++;
    }
    ;

end_tag :
    ETAG_BEG TAG_END
    {
        level--;
        indent(level);
        printf("</%s>\n", $1);
    }
    ;

content :
    %empty
    | element content
    {
        $$ = $1;
    }
    | S content
    {
        $$ = $1;
    }
    | word content
    {
        $$ = $1;
    }
    | '\n' content
    {
        $$ = $1;
    }
    ;


word :
    CHAR
    {
        strcpy($$, $1);
    }
    | CHAR word
    {
        strcpy($$, $1);
        strcat($$, $2); 
    }
    


white_space :
    S
    | '\n'
    ;

optional_white_space :
    %empty
    | white_space optional_white_space
    ;
%%

int main(void) {

    //yydebug = 1;
    yyparse();
    return 0;
}

void yyerror(const char *s) {
    printf("Error: %s\n", s);
    
}

void indent(int level) {
    int i;
    for (i = 0; i < level * INDENT_LENGTH; i++) {
        putchar(' ');
    }
}
    
    




