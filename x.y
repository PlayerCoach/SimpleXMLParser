%{
    #include "stdio.h"
    #include "string.h"
    #include "defs.h"

    #define INDENT_LENGTH 2
    #define LINE_WIDTH 78

    int level = 0;

    void indent(int level);
    int yylex(void);
    int yyerror(const char *s);

%}

%union {
    char s[MAXSTRLEN +1];
}

%token<s> PI_TAG_BEG PI_TAG_END STAG_BEG ETAG_BEG
%token<s> TAG_END ETAG_END CHAR S

%type<s> start_tag end_tag word

%%

document :
    introduction element
    ;

introduction :
    %empty
    | processing_instruction "\n" introduction
    ;

processing_instruction :
    PI_TAG_BEG PI_TAG_END
    ;

element :
    empty_tag
    | pair_of_elements
    ;

empty_tag :
    STAG_BEG ETAG_END
    ;

pair_of_elements :
    start_tag content end_tag
    ;

start_tag :
    STAG_BEG TAG_END
    ;

end_tag :
    ETAG_BEG TAG_END
    ;

content :
    %empty
    | element content
    | S content
    | word content
    | "\n" content
    ;

word :
    CHAR
    ;

%%

int main(void) {
    yyparse();
    return 0;
}

int yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
    return 0;
}

void indent(int level) {
    int i;
    for (i = 0; i < level * INDENT_LENGTH; i++) {
        putchar(' ');
    }
}
    
    




