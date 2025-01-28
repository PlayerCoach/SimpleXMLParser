%{
    #include "stdio.h"
    #include "string.h"
    #include "defs.h"

    #define INDENT_LENGTH 5
    #define LINE_WIDTH 78

    int level = 0;

    char word [MAXSTRLEN + 1];
    int current_line_length = 0;

    void indent(int level);
    int yylex(void);
    void yyerror(const char *s);

    void append(char* src);
    void print_word();
    
%}
%debug


%union {
    char s[MAXSTRLEN +1];
}

%start GRAMMAR

%token<s> PI_TAG_BEG PI_TAG_END STAG_BEG ETAG_BEG NAME EQ VALUE
%token<s> TAG_END ETAG_END CHAR S 

%type<s> start_tag end_tag word attributes

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
    PI_TAG_BEG attributes PI_TAG_END
    {
        indent(level);
        printf("<? %s %s ?>\n", $1, $2);
        current_line_length = 0;
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
        current_line_length = 0;
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
        current_line_length = 0;
        level++;
    }
    ;

end_tag :
    ETAG_BEG TAG_END
    {
        level--;
        indent(level);
        printf("</%s>\n", $1);
        current_line_length = 0;
    }
    ;

content :
    %empty
    | element content
    | S content
    {
        printf("%s", $1);
        current_line_length += strlen($1);
        print_word();
    }
    | word content
    | '\n' content
    {
        printf("\n");
        print_word();
        current_line_length = 0;
    }
    ;


word :
    CHAR
    {
        append($1);
    }
    | CHAR word
    {
        append($1);
    }

    
attributes :
    %empty
    {
        $$[0] = '\0'; 
    }
    | attributes NAME EQ VALUE 
    {
        strncat($$, " ", MAXSTRLEN);
        strncat($$, $2, MAXSTRLEN);
        strncat($$, "=", MAXSTRLEN);
        strncat($$, $4, MAXSTRLEN);
    }
    ;
    


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

void append(char* src) {
    int len = strlen(word);
    strcpy(word + len, src);
    word[len + 1] = '\0';

    current_line_length++;

    if (current_line_length >= LINE_WIDTH) {
        printf("\n");
        current_line_length = 0;
    }
}

void print_word() {
    printf("%s", word);
    current_line_length += strlen(word);
    word[0] = '\0';
}
    
    




